#!/usr/bin/env ruby
# frozen_string_literal: true

# Extract dependency names from a project for security feed matching.

require "json"
require "rexml/document"
require "optparse"
require "pathname"

MAVEN_NS = "http://maven.apache.org/POM/4.0.0"
EXCLUDE_DIRS = %w[node_modules .git target build dist .next generated].to_set

def find_files(root, pattern)
  Dir.glob(File.join(root, "**", pattern)).reject do |p|
    Pathname.new(p).each_filename.any? { |part| EXCLUDE_DIRS.include?(part) }
  end
end

def extract_maven(root)
  deps = Set.new

  find_files(root, "pom.xml").each do |pom_path|
    begin
      doc = REXML::Document.new(File.read(pom_path))
    rescue REXML::ParseException
      next
    end

    r = doc.root
    next if r.nil?

    ns = r.namespace == MAVEN_NS ? "xmlns:" : ""

    r.each_element(".//#{ns}dependency") do |dep|
      aid = dep.elements["#{ns}artifactId"]&.text
      deps << aid if aid
    end

    parent = r.elements["#{ns}parent"]
    if parent
      aid = parent.elements["#{ns}artifactId"]&.text
      deps << aid if aid
    end

    r.each_element(".//#{ns}plugin") do |plugin|
      aid = plugin.elements["#{ns}artifactId"]&.text
      deps << aid if aid
    end
  end

  deps.sort
end

def extract_npm(root)
  deps = Set.new

  find_files(root, "package.json").each do |pkg_path|
    begin
      data = JSON.parse(File.read(pkg_path))
    rescue JSON::ParserError, Errno::ENOENT
      next
    end

    %w[dependencies devDependencies peerDependencies].each do |key|
      deps.merge(data[key].keys) if data[key].is_a?(Hash)
    end
  end

  deps.sort
end

def extract_github_actions(root)
  actions = Set.new
  workflows_dir = File.join(root, ".github", "workflows")
  return [] unless Dir.exist?(workflows_dir)

  uses_pattern = /uses:\s*([^@\s]+)/

  Dir.glob(File.join(workflows_dir, "*.yml")).each do |wf|
    content = File.read(wf) rescue next
    content.scan(uses_pattern).each do |match|
      action = match[0]
      actions << action unless action.start_with?(".")
    end
  end

  actions.sort
end

def extract_docker(root)
  images = Set.new
  image_pattern = /image:\s*['"]?([^\s'"]+)/

  (find_files(root, "compose*.yaml") + find_files(root, "compose*.yml")).each do |compose|
    content = File.read(compose) rescue next
    content.scan(image_pattern).each do |match|
      img = match[0]
      images << img unless img.start_with?("$")
    end
  end

  from_pattern = /^FROM\s+(\S+)/
  find_files(root, "Dockerfile*").each do |dockerfile|
    content = File.read(dockerfile) rescue next
    content.scan(from_pattern).each do |match|
      img = match[0]
      images << img unless img == "scratch"
    end
  end

  images.sort
end

def extract_cli_tools(root)
  tools = Set.new
  install_patterns = [
    /apt-get\s+install\s+[\w-]*\s+([\w-]+)/,
    /brew\s+install\s+([\w-]+)/,
    /pip\s+install\s+([\w-]+)/,
  ]

  workflows_dir = File.join(root, ".github", "workflows")
  return [] unless Dir.exist?(workflows_dir)

  Dir.glob(File.join(workflows_dir, "*.yml")).each do |wf|
    content = File.read(wf) rescue next
    install_patterns.each do |pattern|
      content.scan(pattern).each { |match| tools << match[0] }
    end
  end

  tools.sort
end

def make_flat_list(deps)
  flat = Set.new

  (deps["maven"] || []).each do |name|
    flat << name
    if name.start_with?("spring-boot-starter-")
      flat << name.sub("spring-boot-starter-", "")
    end
    parts = name.split("-")
    flat << parts[0] if parts.size > 1
  end

  (deps["npm"] || []).each do |name|
    flat << name
    flat << name.split("/").last if name.start_with?("@")
  end

  (deps["github-actions"] || []).each do |name|
    flat << name
    parts = name.split("/")
    flat << parts[1] if parts.size >= 2
  end

  (deps["docker"] || []).each do |name|
    next if name.start_with?("$")
    base = name.split(":")[0]
    flat << base.split("/").last if base.include?("/")
    flat << base
  end

  (deps["cli-tools"] || []).each { |name| flat << name }

  flat.sort
end

def extract_from_root(root)
  {
    "maven" => extract_maven(root),
    "npm" => extract_npm(root),
    "github-actions" => extract_github_actions(root),
    "docker" => extract_docker(root),
    "cli-tools" => extract_cli_tools(root),
  }
end

def merge_deps(all_deps)
  merged = { "maven" => [], "npm" => [], "github-actions" => [], "docker" => [], "cli-tools" => [] }
  all_deps.each do |deps|
    merged.each_key do |key|
      merged[key] = (merged[key] + (deps[key] || [])).uniq.sort
    end
  end
  merged
end

# --- main ---

options = { root: nil, scan: nil }

OptionParser.new do |opts|
  opts.banner = "Usage: extract-deps.rb [options]"
  opts.on("--root DIR", "Single project root directory") { |v| options[:root] = v }
  opts.on("--scan DIR", "Parent directory to scan for projects") { |v| options[:scan] = v }
end.parse!

if options[:scan]
  scan_dir = File.expand_path(options[:scan])
  unless Dir.exist?(scan_dir)
    puts JSON.generate({ "error" => "Scan directory not found: #{scan_dir}" })
    exit 1
  end

  projects = {}
  all_deps = []

  Dir.children(scan_dir).sort.each do |child|
    child_path = File.join(scan_dir, child)
    next unless File.directory?(child_path)
    next if child.start_with?(".")

    deps = extract_from_root(child_path)
    if deps.values.any? { |v| !v.empty? }
      projects[child] = deps
      all_deps << deps
    end
  end

  merged = all_deps.empty? ? { "maven" => [], "npm" => [], "github-actions" => [], "docker" => [], "cli-tools" => [] } : merge_deps(all_deps)

  result = {
    "scan_root" => scan_dir,
    "projects" => projects,
    "dependencies" => merged,
    "flat" => make_flat_list(merged),
  }
else
  root = File.expand_path(options[:root] || ".")
  unless Dir.exist?(root)
    puts JSON.generate({ "error" => "Root not found: #{root}" })
    exit 1
  end

  deps = extract_from_root(root)
  result = {
    "project_root" => root,
    "dependencies" => deps,
    "flat" => make_flat_list(deps),
  }
end

puts JSON.pretty_generate(result)

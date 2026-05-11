#!/usr/bin/env ruby
# frozen_string_literal: true

# Fetch RSS/Atom feeds filtered by category and time window.

require "json"
require "net/http"
require "uri"
require "rexml/document"
require "time"
require "optparse"
require "fileutils"

ATOM_NS = "http://www.w3.org/2005/Atom"
DEFAULT_CACHE_DIR = File.join(Dir.home, ".cache", "feed")
DEFAULT_MAX_ITEMS = 20
FETCH_TIMEOUT = 10
SUMMARY_MAX_LEN = 500
DEFAULT_LOOKBACK_HOURS = 72
USER_AGENT = "feed-skill/1.0"

def load_feeds(config_path, category)
  feeds = []
  current = {}

  File.readlines(config_path).each do |line|
    line = line.rstrip
    next if line.empty? || line.start_with?("#") || line.strip == "feeds:"

    stripped = line.lstrip

    if stripped.start_with?("- url:")
      feeds << current unless current.empty?
      current = { "url" => stripped.split(":", 2)[1].strip }
    elsif stripped.start_with?("categories:")
      cats_str = stripped.split(":", 2)[1].strip.gsub(/[\[\]]/, "")
      current["categories"] = cats_str.split(",").map(&:strip)
    elsif stripped.start_with?("label:")
      current["label"] = stripped.split(":", 2)[1].strip
    end
  end
  feeds << current unless current.empty?

  if category && category != "all"
    feeds.select! { |f| (f["categories"] || []).include?(category) }
  end

  feeds
end

def read_last_run(cache_dir)
  last_run_file = File.join(cache_dir, "last-run")
  if File.exist?(last_run_file)
    ts = File.read(last_run_file).strip
    begin
      return Time.parse(ts)
    rescue ArgumentError
      # fall through
    end
  end
  Time.now.utc - (DEFAULT_LOOKBACK_HOURS * 3600)
end

def write_last_run(cache_dir, ts)
  FileUtils.mkdir_p(cache_dir)
  File.write(File.join(cache_dir, "last-run"), ts.iso8601)
end

def parse_date(date_str)
  return nil if date_str.nil? || date_str.strip.empty?
  begin
    Time.parse(date_str.strip)
  rescue ArgumentError
    nil
  end
end

def fetch_feed(feed, since)
  url = feed["url"]
  label = feed["label"] || url
  items = []

  begin
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = FETCH_TIMEOUT
    http.read_timeout = FETCH_TIMEOUT

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = USER_AGENT

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      return [[], "HTTP #{response.code}"]
    end
    data = response.body
  rescue StandardError => e
    return [[], e.message]
  end

  begin
    doc = REXML::Document.new(data)
    root = doc.root
  rescue REXML::ParseException => e
    return [[], "XML parse error: #{e.message}"]
  end

  return [[], "Empty feed"] if root.nil?

  root_name = root.name
  root_ns = root.namespace

  if root_name == "rss" || root_name == "RDF"
    # RSS 2.0
    channel = root.elements["channel"] || root
    (channel.elements.to_a("item") + root.elements.to_a("item")).uniq.each do |item|
      title = (item.elements["title"]&.text || "").strip
      link = (item.elements["link"]&.text || "").strip
      pub_date = item.elements["pubDate"]&.text || item.elements["dc:date"]&.text || ""
      desc = (item.elements["description"]&.text || "").strip

      published = parse_date(pub_date)
      next if published && published < since

      items << {
        "title" => title,
        "link" => link,
        "published" => published&.iso8601,
        "summary" => desc[0, SUMMARY_MAX_LEN],
        "source" => label,
      }
    end
  elsif root_ns == ATOM_NS || root_name == "feed"
    root.elements.each("entry") do |entry|
      title = (entry.elements["title"]&.text || "").strip

      link_el = entry.elements["link[@rel='alternate']"] || entry.elements["link"]
      link = link_el&.attributes&.[]("href") || ""

      pub = entry.elements["published"]&.text || entry.elements["updated"]&.text || ""
      summary = (entry.elements["summary"]&.text || entry.elements["content"]&.text || "").strip

      published = parse_date(pub)
      next if published && published < since

      items << {
        "title" => title,
        "link" => link,
        "published" => published&.iso8601,
        "summary" => summary[0, SUMMARY_MAX_LEN],
        "source" => label,
      }
    end
  else
    return [[], "Unknown feed format: #{root_name}"]
  end

  [items.first(DEFAULT_MAX_ITEMS), nil]
end

# --- main ---

options = { category: "all", config: nil, since: nil, cache_dir: nil }

OptionParser.new do |opts|
  opts.banner = "Usage: fetch-feeds.rb [options]"
  opts.on("--category CAT", "Feed category filter") { |v| options[:category] = v }
  opts.on("--config PATH", "Path to feeds.yaml") { |v| options[:config] = v }
  opts.on("--since TS", "Override since timestamp (ISO-8601)") { |v| options[:since] = v }
  opts.on("--cache-dir DIR", "Cache directory") { |v| options[:cache_dir] = v }
end.parse!

script_dir = File.dirname(__FILE__)
config_path = options[:config] || File.join(script_dir, "..", "feeds.yaml")
cache_dir = options[:cache_dir] || DEFAULT_CACHE_DIR

unless File.exist?(config_path)
  puts JSON.generate({ "error" => "Config not found: #{config_path}" })
  exit 1
end

feeds = load_feeds(config_path, options[:category])

since = if options[:since]
  Time.parse(options[:since])
else
  read_last_run(cache_dir)
end

now = Time.now.utc
all_items = []
errors = []

feeds.each do |feed|
  items, error = fetch_feed(feed, since)
  all_items.concat(items)
  if error
    errors << {
      "label" => feed["label"] || feed["url"],
      "url" => feed["url"],
      "error" => error,
    }
  end
end

all_items.sort_by! { |x| x["published"] || "" }.reverse!

result = {
  "since" => since.iso8601,
  "fetched_at" => now.iso8601,
  "category" => options[:category],
  "total_feeds" => feeds.size,
  "total_items" => all_items.size,
  "items" => all_items,
  "errors" => errors,
}

puts JSON.pretty_generate(result)

write_last_run(cache_dir, now)

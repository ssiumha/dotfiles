# frozen_string_literal: true

require 'fileutils'
require 'json'

DOT_DIR = File.dirname(__FILE__)
DOT_ZSHRC = "#{Dir.home}/.zshrc"
DOT_VIMRC = "#{Dir.home}/.vimrc"
DOT_CONFIG = "#{Dir.home}/.config"
DOT_CACHE = "#{Dir.home}/.cache"
DOT_MISE = "#{Dir.home}/.local/share/mise"
DOT_CLAUDE = "#{Dir.home}/.claude"

# defaults write -g ApplePressAndHoldEnabled -bool false
# defaults -currentHost write -g AppleFontSmoothing -int 1
#   - defaults write -g CGFontRenderingFontSmoothingDisabled -bool YES

OS_TYPE = case `uname -s`.chop.to_s
          when 'Darwin' then :osx
          when 'Linux' then :linux
          else :unknown
          end

task :default do
  sh 'rake -T'
end

task :console do
  binding.irb
end

desc 'install all process'
task 'install:all' => [
  'install:xcode',
  'install:homebrew',
  'install:mise',
  'install:rc',
  'install:config',
  'install:zprofile',
  'install:brew:core',
  'install:brew:dev',
  'install:brew:extra',
  'install:vim_plugins',
  'install:claude',
  'install:macos'
] do
end

desc 'install zshrc, vimrc'
task 'install:rc' do
  File.write(DOT_ZSHRC, "source #{DOT_DIR}/zshrc").tap { puts 'created .zshrc' } unless File.exist?(DOT_ZSHRC)
  File.write(DOT_VIMRC, "source #{DOT_DIR}/vimrc").tap { puts 'created .vimrc' } unless File.exist?(DOT_VIMRC)

  FileUtils.mkdir_p File.join(DOT_CACHE, 'vim/undo')
  FileUtils.mkdir_p File.join(DOT_CACHE, 'vim/swap')
  FileUtils.mkdir_p File.join(DOT_CACHE, 'vim/backup')

  # XDG directories (defined in zshrc)
  %w[.local/share .local/state .local/run].each do |dir|
    path = File.join(Dir.home, dir)
    FileUtils.mkdir_p(path)
    puts "created #{dir}" unless Dir.exist?(path)
  end
end

desc 'symlink configs'
task 'install:config' do
  FileUtils.mkdir_p DOT_CONFIG
  Dir.glob('config/*').each do |config_path|
    name = File.basename(config_path)
    src_path = File.join(DOT_DIR, config_path)
    dest_path = File.join(DOT_CONFIG, name)

    pname = name.ljust(10)

    if File.symlink? dest_path
      puts "#{pname} : already linked"
    elsif Dir.exist? dest_path
      puts "#{pname} : link failed. already exist file"
    else
      FileUtils.ln_s src_path, dest_path
      puts "#{pname} : now linked"
    end
  end
end

desc 'remove symlinked configs'
task 'uninstall:config' do
  Dir.glob('config/*').each do |config_path|
    name = File.basename(config_path)
    dest_path = File.join(DOT_CONFIG, name)

    pname = name.ljust(10)

    if File.symlink? dest_path
      FileUtils.rm dest_path
      puts "#{pname} : removed"
    else
      puts "#{pname} : not linked"
    end
  end
end

desc 'install xcode command line tools'
task 'install:xcode' do
  next if OS_TYPE != :osx
  if system('xcode-select', '-p', out: File::NULL, err: File::NULL)
    puts 'Xcode CLI Tools: already installed'
  else
    sh 'xcode-select --install'
  end
end

desc 'generate SSH key and show public key'
task 'install:ssh_key' do
  ssh_key_path = File.join(Dir.home, '.ssh/id_ed25519')
  if File.exist?(ssh_key_path)
    puts 'SSH key: already exists'
  else
    sh %(ssh-keygen -t ed25519 -C "#{`whoami`.chomp}@#{`hostname`.chomp}" -f #{ssh_key_path} -N "")
  end
  puts "\n=== Public Key (add to GitHub) ==="
  puts File.read("#{ssh_key_path}.pub")
end

desc 'install homebrew'
task 'install:homebrew' do
  next if OS_TYPE != :osx
  if system('which brew', out: File::NULL, err: File::NULL)
    puts 'Homebrew: already installed'
  else
    sh %{ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" }
  end
end

desc 'setup zprofile for mise'
task 'install:zprofile' do
  zprofile_path = File.join(Dir.home, '.zprofile')
  mise_line = 'eval "$($HOME/.local/bin/mise activate zsh --shims)"'

  if File.exist?(zprofile_path) && File.read(zprofile_path).include?('mise activate')
    puts '.zprofile: mise already configured'
  else
    File.open(zprofile_path, 'a') { |f| f.puts mise_line }
    puts '.zprofile: mise PATH added'
  end
end

desc 'install vim plugins'
task 'install:vim_plugins' do
  plug_path = File.join(Dir.home, '.vim/autoload/plug.vim')
  unless File.exist?(plug_path)
    sh 'curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  end
  sh 'vim +PlugInstall +qall'
end

desc 'install core brew packages'
task 'install:brew:core' do
  next if OS_TYPE != :osx
  sh 'brew bundle --file=brew/core.Brewfile'
end

desc 'install dev brew packages'
task 'install:brew:dev' do
  next if OS_TYPE != :osx
  sh 'brew bundle --file=brew/dev.Brewfile'
end

desc 'install extra brew packages'
task 'install:brew:extra' do
  next if OS_TYPE != :osx
  sh 'brew bundle --file=brew/extra.Brewfile'
end

desc 'configure macOS settings'
task 'install:macos' do
  next if OS_TYPE != :osx

  # 키 반복 활성화 (press and hold 비활성화)
  sh 'defaults write -g ApplePressAndHoldEnabled -bool false'

  # Spotlight 단축키 비활성화 (Raycast 사용)
  sh 'defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "<dict><key>enabled</key><false/></dict>"'

  puts 'macOS settings configured. Logout may be required.'
end

desc 'init brew (deprecated: use install:homebrew + install:brew:*)'
task 'install:brew' => ['install:homebrew', 'install:brew:extra'] do
end

desc 'install mise'
task 'install:mise' do
  return puts 'already installed mise' if File.exist?(DOT_MISE)

  sh 'curl https://mise.run | sh'
end

desc 'install vscode settings'
task 'install:vscode' do
  VSCODE_SETTINGS_PATH = "#{Dir.home}/Library/Application Support/Code/User/settings.json"
  VSCODE_KEYBINDING_PATH = "#{Dir.home}/Library/Application Support/Code/User/keybindings.json"

  if File.symlink? VSCODE_SETTINGS_PATH
    puts "vscode settings.json : already linked"
  elsif File.exist? VSCODE_SETTINGS_PATH
    puts "vscode settings.json : link failed. already exist file"
    puts "should execute `rm '#{VSCODE_SETTINGS_PATH}'`"
  else
    FileUtils.ln_s File.join(DOT_CONFIG, 'vscode/settings.json'), VSCODE_SETTINGS_PATH
    FileUtils.ln_s File.join(DOT_CONFIG, 'vscode/keybindings.json'), VSCODE_KEYBINDING_PATH
    puts "vscode settings.json : now linked"
    puts "vscode keybindings.json : now linked"
  end

  # TODO
  # code --list-extensions > code_extensions
  # code --install-extension vscodevim.vim
  #   aykutsarac.jsoncrack-vscode
  #   vscodevim.vim
  #   github.copilot
  #   github.copilot-chat
end

desc 'install claude code settings'
task 'install:claude' do
  FileUtils.mkdir_p DOT_CLAUDE

  symlinks = {
    'prompts/agents' => 'agents',
    'prompts/AGENTS.md' => 'CLAUDE.md',
    'prompts/commands' => 'commands',
    'prompts/hooks' => 'hooks',
    'prompts/rules' => 'rules',
    'prompts/skills' => 'skills',
  }

  symlinks.each do |src, dest|
    src_path = File.join(DOT_DIR, src)
    dest_path = File.join(DOT_CLAUDE, dest)
    pname = dest.ljust(15)

    if File.symlink?(dest_path)
      puts "#{pname} : already linked"
    elsif File.exist?(dest_path)
      puts "#{pname} : link failed. already exists"
    else
      FileUtils.ln_s src_path, dest_path
      puts "#{pname} : now linked"
    end
  end

  # settings.json에 statusLine 설정 추가
  settings_path = File.join(DOT_CLAUDE, 'settings.json')
  statusline_path = File.join(DOT_DIR, 'prompts/statusline.sh')

  if File.exist?(settings_path)
    begin
      settings_content = JSON.parse(File.read(settings_path))
    rescue JSON::ParserError => e
      puts "settings.json  : invalid JSON, skipping (#{e.message})"
      settings_content = nil
    end

    if settings_content
      if settings_content.dig('statusLine', 'command') == statusline_path
        puts "settings.json  : statusLine already configured"
      else
        settings_content['statusLine'] = {
          'type' => 'command',
          'command' => statusline_path
        }
        File.write(settings_path, JSON.pretty_generate(settings_content))
        puts "settings.json  : statusLine updated"
      end
    end
  else
    puts "settings.json  : not found, skipping"
  end

  # marketplace plugins 설치
  plugins = {
    'ast-grep/claude-skill' => 'ast-grep',
  }

  # 공식 마켓플레이스 플러그인 (anthropics/claude-plugins-official)
  official_plugins = %w[typescript-lsp pyright-lsp]

  installed_plugins_path = File.join(DOT_CLAUDE, 'plugins/installed_plugins.json')
  installed_plugins = begin
                        data = JSON.parse(File.read(installed_plugins_path))
                        data['plugins']&.keys || []
                      rescue JSON::ParserError, Errno::ENOENT => e
                        puts "plugins        : failed to read installed_plugins.json (#{e.message})"
                        []
                      end

  plugins.each do |marketplace, plugin|
    marketplace_name = marketplace.split('/').last.sub('-', '-marketplace')
    plugin_key = "#{plugin}@#{marketplace_name}"

    if installed_plugins.any? { |k| k.start_with?("#{plugin}@") }
      puts "plugin         : #{plugin} already installed"
      next
    end

    marketplace_list = `claude plugin marketplace list 2>/dev/null`
    unless marketplace_list.include?(marketplace_name)
      puts "marketplace    : adding #{marketplace}"
      unless system("claude plugin marketplace add #{marketplace}")
        puts "marketplace    : failed to add #{marketplace}, skipping"
        next
      end
    end

    puts "plugin         : installing #{plugin}"
    unless system("claude plugin install #{plugin}")
      puts "plugin         : failed to install #{plugin}"
    end
  end

  # 공식 마켓플레이스 플러그인 설치
  official_plugins.each do |plugin|
    if installed_plugins.any? { |k| k.start_with?("#{plugin}@") }
      puts "plugin         : #{plugin} already installed"
      next
    end

    puts "plugin         : installing #{plugin} (official)"
    unless system("claude plugin install #{plugin}")
      puts "plugin         : failed to install #{plugin}"
    end
  end
end

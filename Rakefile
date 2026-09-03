# frozen_string_literal: true

require 'fileutils'
require 'json'

DOT_DIR = File.dirname(__FILE__)
DOT_ZSHRC = "#{Dir.home}/.zshrc"
DOT_VIMRC = "#{Dir.home}/.vimrc"
DOT_CONFIG = "#{Dir.home}/.config"
DOT_CACHE = "#{Dir.home}/.cache"
DOT_MISE = "#{Dir.home}/.local/share/mise"

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
  'install:macos'
] do
end

desc 'install zshrc, vimrc'
task 'install:rc' do
  File.write(DOT_ZSHRC, "source #{DOT_DIR}/zshrc").tap { puts 'created .zshrc' } unless File.exist?(DOT_ZSHRC)
  File.write(DOT_VIMRC, "source #{DOT_DIR}/vimrc").tap { puts 'created .vimrc' } unless File.exist?(DOT_VIMRC)

  ignore_src = File.join(DOT_DIR, 'ignore')
  ignore_dest = File.join(Dir.home, '.ignore')
  FileUtils.ln_sf(ignore_src, ignore_dest).tap { puts 'linked .ignore' } unless File.symlink?(ignore_dest)

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

desc 'install tools using nix'
task 'install:nix' do
  # created flake.lock
  sh "nix run github:nix-community/home-manager/release-25.11 -- switch --impure --flake #{Dir.home}/dots/config/nix"
end


desc 'install mise'
task 'install:mise' do
  return puts 'already installed mise' if File.exist?(DOT_MISE)

  sh 'curl https://mise.run | sh'
end

desc 'install devops tools into ~/.mise.toml'
task 'install:mise:devops' do
  tools = %w[terraform nova kubectl awscli github-cli krew helm k9s cargo:kdash]
  sh "mise use -C #{Dir.home} --yes #{tools.join(' ')}"
end

desc 'install ruby build dependencies'
task 'install:ruby:deps' do
  case OS_TYPE
  when :osx then sh 'brew install openssl readline zlib'
  when :linux then sh 'sudo apt-get install -y libssl-dev libreadline-dev zlib1g-dev'
  else puts "unsupported OS: #{OS_TYPE}"
  end
end

desc 'setup ir search index for obsidian vault'
task 'install:ir' do
  vault = File.join(Dir.home, 'Documents/obsidian')

  puts '# obsidian 등록'
  system("ir collection add obsidian #{vault}", err: File::NULL) || puts('  already registered')

  puts '# 한국어 전처리기 설치'
  sh 'ir preprocessor install ko'
  sh 'ir preprocessor bind ko obsidian'

  puts '# BM25 인덱싱'
  sh 'ir update obsidian'

  puts '# 벡터 임베딩'
  sh 'ir embed obsidian'

  puts '# 데몬 시작'
  sh 'ir daemon start'
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

if [[ $OSTYPE == darwin* ]]; then
  autoload -Uz compaudit && compaudit | xargs chmod g-w
else
fi
autoload -Uz compinit && compinit -C -d "$HOME/.local/zcompdump"

unsetopt menu_complete   # do not autoselect the first completion entry
unsetopt flowcontrol
setopt auto_menu         # show completion menu on succesive tab press
setopt complete_in_word
setopt always_to_end

WORDCHARS=''

zmodload -i zsh/complist

bindkey -M menuselect '^o' accept-and-infer-next-history

## case-insensitive (all),partial-word and then substring completion
#zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'  # CASE_SENSITIVE
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'  # HYPHEN_INSENSITIVE
#zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

zstyle '*' single-ignored show
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' menu select

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

zstyle ':completion:*' list-separator '-->'
zstyle ':completion:*:manuals' separate-sections true

# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Use caching so that commands like apt and dpkg complete are useable
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $ZSH_CACHE_DIR

# Don't complete uninteresting users
zstyle ':completion:*:*:*:users' ignored-patterns \
        adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna \
        clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm \
        gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm \
        ldap lp mail mailman mailnull man messagebus  mldonkey mysql nagios \
        named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
        operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
        rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
        usbmux uucp vcsa wwwrun xfs '_*'

zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"


compdef _ssh ssh
_ssh() {
  _ssh_keys() {
    if [[ -r "$HOME/.ssh" ]]; then
      compadd -M 'm:{a-zA-Z}={A-Za-z} r:|.=* r:|=*' \
        ${(@M)$(ls "$HOME/.ssh"):#(id_*[^p][^u][^b]|*.pem)}
    fi
  }

  _ssh_hosts() {
    if [[ -r "$HOME/.ssh/config" ]]; then
      compadd -M 'm:{a-zA-Z}={A-Za-z} r:|.=* r:|=*' \
        $( while IFS=$'=\t ' read -r key hosts; do
            if [[ "$key" == Host ]]; then
              echo ${(z)hosts:gs/*//:gs/?//};
            fi
          done < "$HOME/.ssh/config"
        )
    fi
  }

  _arguments -C -s \
    '-i: :_ssh_keys' \
    '*: :_ssh_hosts'

  return 0
}


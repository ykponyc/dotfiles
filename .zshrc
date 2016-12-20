# .zshrc
# Author: Piotr Karbowski <piotr.karbowski@gmail.com>
# License: beerware.

# Basic zsh config.
ZDOTDIR=${ZDOTDIR:-${HOME}}
ZSHDDIR="${HOME}/.config/zsh.d"
HISTFILE="${ZDOTDIR}/.zsh_history"
HISTSIZE='10000'
SAVEHIST="${HISTSIZE}"
# env
export EDITOR=/usr/bin/vim
export PAGER=less
export PATH="$PATH:/usr/local/bin;/usr/bin/jre1.6.0_30/bin;~/.composer/vendor/bin"
export BROWSER=/usr/bin/google-chrome-stable
#AndroidDev PATH
export PATH=${PATH}:~/Projects/Android/tools
export PATH=${PATH}:~/Projects/Android/platform-tools
export PATH=${PATH}:/usr/lib/x86_64-linux-gnu
export TMP="$HOME/tmp"
export TEMP="$TMP"
export TMPDIR="$TMP"
fpath=(path/to/zsh-completions $fpath)
export LANG="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export WINEPREFIX=$HOME/.config/wine/
export WINEARCH=win32
setopt NO_HUP
setopt IGNORE_EOF
setopt NO_CASE_GLOB
setopt NUMERIC_GLOB_SORT
setopt EXTENDED_GLOB

# Colors.
red='\e[0;31m'
RED='\e[1;31m'
green='\e[0;32m'
GREEN='\e[1;32m'
yellow='\e[0;33m'
YELLOW='\e[1;33m'
blue='\e[0;34m'
BLUE='\e[1;34m'
purple='\e[0;35m'
PURPLE='\e[1;35m'
cyan='\e[0;36m'
CYAN='\e[1;36m'
NC='\e[0m'

# Functions
if [ -f '/etc/profile.d/prll.sh' ]; then
. "/etc/profile.d/prll.sh"
fi

ewarn() { echo -e "\033[1;33m>>> \033[0m$@"; }

over_ssh() {
if [ -n "${SSH_CLIENT}" ]; then
return 0
else
return 1
fi
}

confirm() {
local answer
echo -ne "zsh: Ты точно хочешь выполнить '${YELLOW}$@${NC}' [yN]? "
read -q answer
echo
if [[ "${answer}" =~ ^[Yy]$ ]]; then
command "${=1}" "${=@:2}"
else
return 1
fi
}

confirm_wrapper() {
if [ "$1" = '--root' ]; then
local as_root='true'
shift
fi

local runcommand="$1"; shift

if [ "${as_root}" = 'true' ] && [ "${USER}" != 'root' ]; then
runcommand="sudo ${runcommand}"
fi
confirm "${runcommand}" "$@"
}

poweroff() { confirm_wrapper --root $0 "$@"; }
reboot() { confirm_wrapper --root $0 "$@"; }
hibernate() { confirm_wrapper --root $0 "$@"; }

detox() {
if [ "$#" -ge 1 ]; then
confirm detox "$@"
else
command detox "$@"
fi
}

has() {
local string="${1}"
shift
local element=''
for element in "$@"; do
if [ "${string}" = "${element}" ]; then
return 0
fi
done
return 1
}

begin_with() {
local string="${1}"
shift
local element=''
for element in "$@"; do
if [[ "${string}" =~ "^${element}" ]]; then
return 0
fi
done
return 1

}

termtitle() {
case "$TERM" in
rxvt*|xterm|nxterm|gnome|screen|screen-*)
case "$1" in
precmd)
print -Pn "\e]0;%n@%m: %~\a"
;;
preexec)
zsh_cmd_title="$2"
# Escape '\' char.
zsh_cmd_title="${zsh_cmd_title//\\/\\\\}"
# Escape '$' char.
zsh_cmd_title="${zsh_cmd_title//\$/\\\\\$}"
# Escape '%' char.
#zsh_cmd_title="${zsh_cmd_title//%/\%\%}"
# As I am unable to deal with all %, especialy
# the nasted one, I will just strip this char.
zsh_cmd_title="${zsh_cmd_title//\%/<percent>}"
print -Pn "\e]0;${zsh_cmd_title} [%n@%m: %~]\a"
;;
esac
;;
esac
}



git_check_if_worktree() {
# This function intend to be only executed in chpwd().
# Check if the current path is in git repo.

# We would want stop this function, on some big git repos it can take some time to cd into.
if [ -n "${skip_zsh_git}" ]; then
git_pwd_is_worktree='false'
return 1
fi
# The : separated list of paths where we will run check for git repo.
# If not set, then we will do it only for /root and /home.
if [ "${UID}" = '0' ]; then
# running 'git' in repo changes owner of git's index files to root, skip prompt git magic if CWD=/home/*
git_check_if_workdir_path="${git_check_if_workdir_path:-/root}"
else
git_check_if_workdir_path="${git_check_if_workdir_path:-/home}"
git_check_if_workdir_path_exclude="${git_check_if_workdir_path_exclude:-${HOME}/_sshfs}"
fi

if begin_with "${PWD}" ${=git_check_if_workdir_path//:/ }; then
if ! begin_with "${PWD}" ${=git_check_if_workdir_path_exclude//:/ }; then
local git_pwd_is_worktree_match='true'
else
local git_pwd_is_worktree_match='false'
fi
fi

if ! [ "${git_pwd_is_worktree_match}" = 'true' ]; then
git_pwd_is_worktree='false'
return 1
fi

# todo: Prevent checking for /.git or /home/.git, if PWD=/home or PWD=/ maybe...
# damn annoying RBAC messages about Access denied there.
if [ -d '.git' ] || [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = 'true' ]; then
git_pwd_is_worktree='true'
git_worktree_is_bare="$(git config core.bare)"
else
unset git_branch git_worktree_is_bare
git_pwd_is_worktree='false'
fi
}

git_branch() {
git_branch="$(git symbolic-ref HEAD 2>/dev/null)"
git_branch="${git_branch##*/}"
git_branch="${git_branch:-no branch}"
}

git_dirty() {
if [ "${git_worktree_is_bare}" = 'false' ] && [ -n "$(git status --untracked-files='no' --porcelain)" ]; then
git_dirty='%F{green}*'
else
unset git_dirty
fi
}

precmd() {
# Set terminal title.
termtitle precmd

if [ "${git_pwd_is_worktree}" = 'true' ]; then
git_branch
git_dirty

git_prompt=" %F{blue}[%F{253}${git_branch}${git_dirty}%F{blue}]"
else
unset git_prompt
fi
}

preexec() {
# Set terminal title along with current executed command pass as second argument
termtitle preexec "${(V)1}"
}

chpwd() {
git_check_if_worktree
}

# Are we running under grsecurity's RBAC?
rbac_auth() {
local auth_to_role='admin'
if [ "${USER}" = 'root' ]; then
if ! grep -qE '^RBAC:' "/proc/self/status" && command -v gradm > /dev/null 2>&1; then
echo -e "\n${BLUE}*${NC} ${GREEN}RBAC${NC} Authorize to '${auth_to_role}' RBAC role."
gradm -a "${auth_to_role}"
fi
fi
}
#rbac_auth

# ФИШКИ
# Включение/выключение proxy для НВМУ (в консоли ввести setproxy для включения и unsetproxy для выключения)
# Set Proxy
function setproxy () {
  export {http,https,ftp}_proxy="http://10.152.112.76:8080"
}

#Unset Proxy
function unsetproxy () {
  unset {http,https,ftp}_proxy
}


# extended globbing
setopt extendedGlob

# zmv - a command for renaming files by means of shell patterns.
autoload -U zmv

# zargs, as an alternative to find -exec and xargs.
autoload -U zargs

# Turn on command substitution in the prompt (and parameter expansion and arithmetic expansion).
setopt promptsubst

# Include user-specified configs.
if [ ! -d "${ZSHDDIR}" ]; then
mkdir -p "${ZSHDDIR}" && echo "# Put your user-specified config here." > "${ZSHDDIR}/example.zsh"
fi

#for zshd in $(ls -A ${HOME}/.config/zsh.d/^*.(z)sh$); do
#. "${zshd}"
#done

# Completion.
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' menu select=2
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion:*:descriptions' format '%U%F{cyan}%d%f%u'

# If running as root and nice >0, renice to 0.
if [ "$USER" = 'root' ] && [ "$(cut -d ' ' -f 19 /proc/$$/stat)" -gt 0 ]; then
renice -n 0 -p "$$" && echo "# Adjusted nice level for current shell to 0."
fi

# Fancy prompt.
if over_ssh && [ -z "${TMUX}" ]; then
prompt_is_ssh='%F{blue}[%F{red}SSH%F{blue}] '
elif over_ssh; then
prompt_is_ssh='%F{blue}[%F{253}SSH%F{blue}] '
else
unset prompt_is_ssh
fi

case $USER in
root)
PROMPT='%B%F{cyan}%m%k %(?..%F{blue}[%F{253}%?%F{blue}] )${prompt_is_ssh}%B%F{blue}%1~${git_prompt}%F{blue} %# %b%f%k'
;;

*)
PROMPT='%B%F{blue}%n@%m%k %(?..%F{blue}[%F{253}%?%F{blue}] )${prompt_is_ssh}%B%F{cyan}%1~${git_prompt}%F{cyan} %# %b%f%k'

;;
esac

# Ignore duplicate in history.
setopt hist_ignore_dups

# Prevent record in history entry if preceding them with at least one space
setopt hist_ignore_space

# Nobody need flow control anymore. Troublesome feature.
#stty -ixon
setopt noflowcontrol

# Shell config.
umask 077
if ! [[ "${PATH}" =~ "^${HOME}/bin" ]]; then
export PATH="${HOME}/bin:${PATH}"
fi

# Not all servers have terminfo for rxvt-256color. :<
if [ "${TERM}" = 'rxvt-256color' ] && ! [ -f '/usr/share/terminfo/r/rxvt-256color' ] && ! [ -f '/lib/terminfo/r/rxvt-256color' ]; then
export TERM='rxvt-unicode'
fi



if [ ! -d "${TMP}" ]; then mkdir "${TMP}"; fi

if command -v colordiff > /dev/null 2>&1; then
alias diff="colordiff -Nuar"
else
alias diff="diff -Nuar"
fi

alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias ls='ls --color=auto --human-readable --group-directories-first --classify'


### FUNCTIONS

cdl() {builtin cd $@; ls }

# Easy extract
extract () {
  if [ -f $1 ] ; then
      case $1 in
            *.tar.bz2)      tar xvjf $1   ;;
            *.tar.gz)       tar xvzf $1   ;;
	    *.tar.xz)       tar xvJf $1   ;;
            *.bz2)          bunzip2 $1    ;;
            *.rar)          unrar x $1    ;;
            *.gz)           gunzip $1     ;;
            *.tar)          tar xvf $1    ;;
            *.tbz2)         tar xvjf $1   ;;
            *.tgz)          tar xvzf $1   ;;
	    *.txz)          tar xvJf $1   ;;
            *.rar)          unrar $1      ;;
            *.zip)          unzip $1      ;;
            *.Z)            uncompress $1 ;;
            *.7z)           7z e $1       ;;
          *)           echo "don't know how to extract '$1'..." ;;
      esac
  else
      echo "'$1' is not a valid file!"
  fi
}

# Get weather (replace the 71822 in the url with your own zipcode, call it by typing weather)
 weather ()
 {
 declare -a WEATHERARRAY
 WEATHERARRAY=( `elinks -dump "http://www.google.com/search?hl=en&lr=&client=firefox-a&rls=org.mozilla%3Aru-RU%3Aofficial&q=weather+СПб&btnG=Search" | grep -A 5 -m 1 "Weather for" | grep -v "Add to "`)
 echo ${WEATHERARRAY[@]}
 }
# Makes directory then moves into it
function mkcdr {
    mkdir -p -v $1
    cd $1
}

# Creates an archive from given directory
mktar() { tar cvf  "${1%%/}.tar"     "${1%%/}/"; }
mktgz() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }
mktbz() { tar cvjf "${1%%/}.tar.bz2" "${1%%/}/"; }

upinfo ()
{
echo -ne "\t ";uptime | awk /'up/ {print $3,$4,$5,$6,$7,$8,$9,$10}'
}

# list files only
lf () { ls -1p $@ | grep -v '\/$' }


# define words with wordnet
ddefine () { curl dict://slovari.yandex.ru/${1}/правописание/; }


## Aliases

alias sshnu='ssh vm17411@178.250.240.242'

alias ls='ls --color=auto' # color is useful.
alias l='ls -lFh'
alias la='ls -lAFh'
alias lr='ls -tRFh'
alias lt='ls -ltFh'
alias cp='cp -i'
alias mv='mv -i'
#Остановился здесь
alias mkdir='mkdir -p -v'
alias df='df -h'
alias du='du -h -c'
alias reload='source ~/.zshrc'
alias biggest='BLOCKSIZE=1048576; du -x | sort -nr | head -10'
alias remdir='"rm" -rf'
#alias trashman='"rm" -rf ~/.local/share/Trash/files/*'
alias scrott='"scrot" -d 7 -c'
alias zshrc="$EDITOR ~/.zshrc"
alias mountiso="sudo mount -t iso9660 -o loop"
alias blank="sleep 1 && xset dpms force off"
alias lesslast="less !:*"
alias mine="sudo chown ro"
alias apacman="~/ansipacman.sh"
alias atank="~/ansitanks.sh"
alias invaders="~/colors.sh"
alias rvundle="vim +BundleInstall +qall"
alias -g G="| grep"
alias -g L="| less"
alias xcolors='xrdb -l ~/.Xresources'
## changing dirs with just dots.
alias .='cd ../'
alias ..='cd ../../'
alias ...='cd ../../../'
alias ....='cd ../../../../'

## these are the dirs i use most commonly.
alias home='cd ~/'
alias documents='cd ~/Documents'
alias downloads='cd ~/Downloads'
alias books='cd ~/ebooks'
alias pictures='cd ~/Images'
alias packages='cd ~/Packages'
alias torrents='cd ~/Torrents'
alias videos='cd ~/Videos'
alias wallpaper='cd ~/Images/wallpapers'
alias screenshots='cd ~/Images/screenshots'
alias music='cd ~/Music'
alias gitdir='cd ~/git'
alias projects='cd ~/Projects'

## MORE aliases that i use a lot.
alias ports='netstat -nape --inet'
alias ping='ping -c 4'
alias ns='netstat -alnp --protocol=inet'
# alias top="sudo htop d 1"
alias    ps="ps aux"
alias today='date "+%d %h %y"'
alias now='date "+%A, %d %B, %G%t%H:%M %Z(%z)"'
alias msgs='tail -f /var/log/messages'
alias nautilus='nautilus --no-desktop'
alias grep="egrep --color=auto"  # color grep output
alias cls="clear;fortune"     # another quickie
alias k=kill                     # QUICKKEY - kill process
alias e=$EDITOR                  # QUICKKEY - edit quickly
alias m=more                     # QUICKKEY - yeah
alias q=exit                     # QUICKKEY - like vim

## Package Manager - Uncomment for your distro
#  Distributions Included: Debian and Debian-based Distributions like Ubuntu and Mint
#                          Fedora, and other Yum-based Distros like OpenSUSE and Fuduntu
#                          Sayabon, Gentoo, Archlinux.

## Debian/Debian-based.  Ubuntu, Mint, Crunchbang, etc

#alias ainstall='sudo apt-get install'
#alias aremove='sudo apt-get remove'
#alias system_update='sudo aptitude safe-upgrade'
#alias afind='aptitude search'
#alias affind='apt-file search'
#alias afupdate='sudo apt-file update'
#alias aupdate='sudo aptitude update'
#alias addppa='add-apt-repository'
#alias orphand='sudo deborphan | xargs sudo apt-get -y remove --purge'
#alias cleanup='sudo apt-get autoclean && sudo apt-get autoremove && sudo apt-get clean && sudo apt-get remove && orphand'
#alias updatedb='updatedb'
#alias lessswap="sysctl vm.swappiness=10"
#alias moreswap="sysctl vm.swappiness=100"

## Fedora/Fuduntu/etc

#alias yinstall='sudo yum install'
#alias yremove='sudo yum remove'
#alias system_update='sudo yum update'
#alias yfind='sudo yum search'
#alias yginstall='sudo yum groupinstall'

## Sabayon

#alias einstall='sudo equo install'
#alias efind='equo search'
#alias eremove='sudo equo remove'
#alias eupdate='sudo equo update'
#alias eupgrade='sudo equo upgrade --ask'

## Gentoo

#alias einstall='sudo emerge -a'
#alias eremove='sudo emerge -ac'
#alias system_update='sudo emerge -aev world'
#alias efind='sudo emerge -S'
#alias eupdate='sudo emerge --sync'
#alias depclean='sudo emerge --depclean'

## Archlinux

alias aurinst='sudo yaourt -S'
alias aurpkg='sudo pacman -U'
alias pinstall='sudo pacman -S'
alias premove='sudo pacman -R'
alias system_update='sudo pacman -Syu'
alias aurfind='sudo yaourt -Ss'
alias pfind='sudo pacman -Ss'
alias pinfo='sudo pacman -Si'
alias installedby='sudo pacman -Ql'
alias whatfrom='sudo pacman -Qo'
alias showorphan='sudo pacman -Qdt'
alias removeuseless='sudo pacman -Rsnc $(pacman -Qdqt)'
alias pacupgrade='sh ~/.mirrorfix'
alias giveswhat='sudo pkgfile --list'
## Misc
alias edit='atom'


# key binding
bindkey "\e[1~" beginning-of-line # Home
bindkey "\e[4~" end-of-line # End
bindkey "\e[5~" beginning-of-history # PageUp
bindkey "\e[6~" end-of-history # PageDown
bindkey "\e[2~" quoted-insert # Ins
bindkey "\e[3~" delete-char # Del
bindkey "\e[5C" forward-word
bindkey "\eOc" emacs-forward-word
bindkey "\e[5D" backward-word
bindkey "\eOd" emacs-backward-word
bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word
bindkey "\e[Z" reverse-menu-complete # Shift+Tab
# for rxvt
bindkey "\e[7~" beginning-of-line # Home
bindkey "\e[8~" end-of-line # End
# for non RH/Debian xterm, can't hurt for RH/Debian xterm
bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line
# for freebsd console
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line
# for guake
bindkey "\eOF" end-of-line
bindkey "\eOH" beginning-of-line
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
bindkey "\e[3~" delete-char # Del
# History
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward


if [ -f ~/.alert ]; then cat ~/.alert; fi

#------------------------------------------////
# System Information:
#------------------------------------------////
clear
echo -ne "${blue}Сегодня:\t\t${darkgray}" `date`; echo ""
echo -e "${blue}Kernel Information: \t${darkgray}" `uname -smr`
echo -ne "${purple}";upinfo;echo ""
#echo -e "${blue}"; cal -3


# Proxy

# Proxy

assignProxy(){
  PROXY_ENV="http_proxy ftp_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY"
  for envar in $PROXY_ENV
  do
    export $envar=$1
  done
  for envar in "no_proxy NO_PROXY"
  do
    export $envar=$2
  done
}

clrProxy (){
  assignProxy "" # This is what 'unset' does.
}

nvmu() {
  user=a0678
  read -p "Password: " -s pass && echo -e ""
  proxy_value="http://$user:$pass@10.152.112.76:8080"
  no_proxy_value="localhost,127.0.0.1"
  assignProxy $proxy_value $no_proxy_value
}

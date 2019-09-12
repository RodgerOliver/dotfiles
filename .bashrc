#!/bin/bash

# .bashrc is read by login and subshells
# .bash_profile is read by login shells
# .profile is for all shells
# backup files are in /etc/skel
# general config files are in /etc
# ===== GENERAL
# sudo completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
# start tmux session scratchpad
if tmux has-session -t scratchpad 2> /dev/null; then
	# tmux attach -t scratchpad
	echo "continue" &> /dev/null
else
	tmux new -d -s scratchpad
fi
# Start graphical server if i3 not already running.
[ "$(tty)" = "/dev/tty1" ] && ! pgrep -x i3 >/dev/null && exec startx
set -o vi # vi mode
stty -ixon # Disable ctrl-s and ctrl-q.
# Append to the Bash history file, rather than overwriting it
shopt -s histappend
HISTSIZE=2000
HISTFILESIZE=2000
# swap esc with caps
setxkbmap -option caps:swapescape
# add local bin to PATH
if [ -d "$HOME/.local/bin" ] ; then
	# export recursively
	export PATH="$PATH:$(du "$HOME/.local/bin/" | cut -f2 | tr '\n' ':' | sed 's/:*$//')"
fi

# source files
for file in ~/.bash_{aliases,prompt,completion}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# ===== EXPORTS
export EDITOR=vim
export TERM=xterm-256color
export BROWSER=firefox
export READER=zathura
export FILE=ranger

# ===== ALIASES
alias up='sudo apt update && sudo apt upgrade -y'
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias c='clear'
alias q='exit'
alias mkdir='mkdir -pv'
alias ip='ip -c'
alias grep='grep --color=auto'
alias v='vim'
alias vv='vim ~/notes/vimwiki/index.md'
alias g='git'
alias glog='git log --all --graph --pretty=format:"%C(yellow)%h %C(green)%an %C(reset)%s %C(blue)%ar %C(auto)%d"'
alias r='ranger'
alias t='tmux'

# push branch to deploy with git
gpud() {
    branch=$1;
    if [ -z $branch ]; then
        branch=HEAD;
    fi
    git push -f deploy $branch:master
}

# ===== COMPLETE
complete -F _complete_alias g
complete -F _complete_alias glog
complete -F _complete_alias gpud

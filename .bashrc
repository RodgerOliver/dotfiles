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
# Start graphical server if i3 not already running.
[ "$(tty)" = "/dev/tty1" ] && ! pgrep -x i3 >/dev/null && exec startx
set -o vi # vi mode
[[ $- == *i* ]] && stty -ixon # Disable ctrl-s and ctrl-q.
# Append to the Bash history file, rather than overwriting it
shopt -s histappend
HISTSIZE=2000
HISTFILESIZE=2000
# swap esc with caps
if command -v setxkbmap >/dev/null 2>&1; then
	setxkbmap -option caps:swapescape
fi
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
# bind C-L to clear screen
bind -m vi-insert "\C-l":clear-screen

# ===== EXPORTS
export EDITOR=vim
export TERM=xterm-256color
export BROWSER=firefox
export NOTES_PATH=~/.notes
export SUDO_ASKPASS=~/.local/bin/zenity_pass
export TERMINAL=terminator
export TERMINAL_CLASS=Terminator

# ===== ALIASES
alias up='sudo apt update && sudo apt upgrade -y && sudo apt install -f && sudo apt autoremove -y'
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias c='clear'
alias q='exit'
alias mkdir='mkdir -pv'
alias ip='ip -c'
alias grep='grep --color=auto'
alias v='vim'
alias nv='nvim'
alias vv="vim $NOTES_PATH/remote/index.md"
alias g='git'
alias r='ranger'
alias t='tmux'
alias sudo='sudo '

# ===== COMPLETE
complete -F _complete_alias g

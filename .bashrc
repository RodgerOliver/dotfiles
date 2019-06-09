# .bashrc is read by login and subshells
# .bash_profile is read by login shells
# .profile is for all shells
# backup files are in /etc/skel
# general config files are in /etc
# ===== GENERAL =====
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
    PATH="$HOME/.local/bin:$PATH"
fi

# source files
for file in ~/.bash_{aliases,prompt}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# ===== EXPORTS =====
export EDITOR=vim
export TERM=xterm-256color
export BROWSER=firefox
export READER=zathura
export FILE=ranger

# ===== ALIASES =====
if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias v='vim'
alias g='git'

# ===== GENERAL =====
set -o vi # vi mode
stty -ixon # Disable ctrl-s and ctrl-q.
shopt -s autocd #Allows you to cd into directory merely by typing the directory name.
HISTSIZE=2000
HISTFILESIZE=2000

# ===== COLORS =====
yellow=$(tput setaf 226)
green=$(tput setaf 34)
light_green=$(tput setaf 46)
blue=$(tput setaf 27)
white=$(tput setaf 255)
bold=$(tput bold)
reset_colors=$(tput sgr0)

# ===== PS1 =====
PS1="\[${bold}\]\n"
PS1+="\[${yellow}\]\u"
PS1+="\[${green}\]@"
PS1+="\[${blue}\]\h"
PS1+="\[${white}\]:"
PS1+="\[${light_green}\]\w"
PS1+="\n$ \[${reset_colors}\]"
export PS1

# ===== ALIASES =====
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias v='vim'
alias g='git'

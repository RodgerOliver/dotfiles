# ===== GENERAL =====
set -o vi # vi mode
stty -ixon # Disable ctrl-s and ctrl-q.
shopt -s autocd #Allows you to cd into directory merely by typing the directory name.
HISTSIZE= HISTFILESIZE= # Infinite history.

# ===== PS1 =====
yellow=$(tput setaf 226)
green=$(tput setaf 34)
blue=$(tput setaf 27)
white=$(tput setaf 255)
bold=$(tput bold)
reset_colors=$(tput sgr0)
PS1="\n\[${bold}\]"
PS1+="\[${yellow}\]\u"
PS1+="\[${green}\]@"
PS1+="\[${blue}\]\h"
PS1+="\[${white}\]:"
PS1+="\W"
PS1+="\n$ \[${reset_colors}\]"
export PS1


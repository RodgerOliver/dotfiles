# Bash login shell initialization

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

if [[ $- == *i* ]] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

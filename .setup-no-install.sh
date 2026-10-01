#!/bin/bash

export XDG_CONFIG_HOME="$HOME"/.config
mkdir -p "$XDG_CONFIG_HOME"

# Symlink $1 to $2, backing up an existing real file/dir instead of nesting the link inside it
link() {
    if [ -e "$2" ] && [ ! -L "$2" ]; then
        mv "$2" "$2.bak.$(date +%Y%m%d%H%M%S)"
    fi
    ln -sfn "$1" "$2"
}

# Create symlinks for existing configurations
link "$PWD/.bashrc" "$HOME"/.bashrc
link "$PWD/.zshrc" "$HOME"/.zshrc
link "$PWD/.config/nvim" "$XDG_CONFIG_HOME"/nvim
link "$PWD/.config/fish" "$XDG_CONFIG_HOME"/fish
link "$PWD/.config/tmux" "$XDG_CONFIG_HOME"/tmux
link "$PWD/.tmux.conf" "$HOME"/.tmux.conf
link "$PWD/.config/starship" "$XDG_CONFIG_HOME"/starship
link "$PWD/.config/starship/starship.toml" "$XDG_CONFIG_HOME"/starship.toml
link "$PWD/.config/fzf" "$XDG_CONFIG_HOME"/fzf

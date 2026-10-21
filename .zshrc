# Initialize Homebrew environment (prioritize user installation)
# Done first so brew-installed tools (starship, zoxide, fzf, kubectl, eza) are on PATH
if [ -d "$HOME/.linuxbrew" ]; then
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
elif [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -d "/opt/homebrew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d "/usr/local/Homebrew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Fix term issue (fall back when the terminal's terminfo isn't installed, e.g. over SSH)
case "$TERM" in
    xterm-ghostty|xterm-kitty|alacritty)
        infocmp "$TERM" &>/dev/null || export TERM=xterm-256color
        ;;
esac

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- set to "" since prompt is managed by Starship
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git z zsh-autosuggestions zsh-nvm)

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=241'

source $ZSH/oh-my-zsh.sh

# Setup kubectl completion if kubectl is available
# Kubectl completion must be loaded AFTER 'source $ZSH/oh-my-zsh.sh' runs
if command -v kubectl &>/dev/null; then
    source <(kubectl completion zsh)
fi

# ------------------------------------------------------------------------------
# Vi mode (must come after OMZ, which sets bindkey -e; and before Starship,
# which wraps zle-keymap-select to redraw its ❮ vimcmd prompt symbol)
# ------------------------------------------------------------------------------
bindkey -v
export KEYTIMEOUT=1   # Esc switches to normal mode in 10ms instead of 400ms

# Cursor shape: beam in insert mode, block in normal mode
_vi_cursor() {
    case $KEYMAP in
        vicmd)      print -n '\e[2 q' ;;   # steady block
        viins|main) print -n '\e[6 q' ;;   # steady beam
    esac
}
_vi_cursor_reset() { print -n '\e[2 q' }   # restore block cursor for programs (nvim, less...)
zle-keymap-select() { _vi_cursor }
zle-line-init()     { zle -K viins; _vi_cursor }
zle -N zle-keymap-select
zle -N zle-line-init
preexec_functions+=(_vi_cursor_reset)

# Insert mode: keep familiar emacs-style editing (vim's own insert mode allows these)
bindkey -M viins '^?' backward-delete-char     # Backspace past the insert start point
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^P' up-line-or-search
bindkey -M viins '^N' down-line-or-search

# Normal mode: history search on prefix with k/j, edit full command in $EDITOR with v
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search
bindkey -M vicmd 'v' edit-command-line
bindkey -M vicmd '/' history-incremental-search-backward
bindkey -M vicmd '?' history-incremental-search-forward

# Vim text objects: ciw, di", ya(, ci{ ...
autoload -Uz select-bracketed select-quoted
zle -N select-bracketed
zle -N select-quoted
for km in visual viopp; do
    bindkey -M $km -- '-' vi-up-line-or-history
    for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do bindkey -M $km $c select-bracketed; done
    for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do bindkey -M $km $c select-quoted; done
done
unset km c

# Vim surround: cs"' (change), ds" (delete), ys{motion}" (add), S" in visual
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -M vicmd 'cs' change-surround
bindkey -M vicmd 'ds' delete-surround
bindkey -M vicmd 'ys' add-surround
bindkey -M visual 'S' add-surround

# Yank to system clipboard in normal mode: Y copies the whole line
_vi_yank_clipboard() {
    if command -v wl-copy &>/dev/null; then print -rn -- "$BUFFER" | wl-copy
    elif command -v xclip &>/dev/null; then print -rn -- "$BUFFER" | xclip -selection clipboard
    elif command -v pbcopy &>/dev/null; then print -rn -- "$BUFFER" | pbcopy
    fi
}
zle -N _vi_yank_clipboard
bindkey -M vicmd 'Y' _vi_yank_clipboard

# Ctrl+F accepts zsh-autosuggestions suggestion (vi insert + emacs)
bindkey -M viins '^F' autosuggest-accept
bindkey -M emacs '^F' autosuggest-accept

# ------------------------------------------------------------------------------
# Home / End / Delete keys (bound in every keymap; OMZ only binds the terminfo variants)
# ------------------------------------------------------------------------------
for keymap in emacs viins vicmd; do
    bindkey -M $keymap '^[[H'  beginning-of-line   # Home (normal mode)
    bindkey -M $keymap '^[OH'  beginning-of-line   # Home (application mode)
    bindkey -M $keymap '^[[1~' beginning-of-line   # Home (tmux/screen/linux console)
    bindkey -M $keymap '^[[7~' beginning-of-line   # Home (rxvt)
    bindkey -M $keymap '^[[F'  end-of-line         # End (normal mode)
    bindkey -M $keymap '^[OF'  end-of-line         # End (application mode)
    bindkey -M $keymap '^[[4~' end-of-line         # End (tmux/screen/linux console)
    bindkey -M $keymap '^[[8~' end-of-line         # End (rxvt)
    bindkey -M $keymap '^[[3~' delete-char         # Delete
done
unset keymap

# ------------------------------------------------------------------------------
# Prompt - Starship (Replacing Powerlevel10k / p10k prompt)
# ------------------------------------------------------------------------------
export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# ------------------------------------------------------------------------------
# Plugins & Tool Integrations (zoxide, fzf)
# ------------------------------------------------------------------------------

# Plugin: z (autojump/directory navigation)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# Plugin: fzf (Fuzzy Finder - https://junegunn.github.io/fzf/shell-integration/)
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzf.zsh" ]; then
    . "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzf.zsh"
elif [ -f "$HOME/.fzf.zsh" ]; then
    . "$HOME/.fzf.zsh"
elif command -v fzf &>/dev/null; then
    eval "$(fzf --zsh)"
fi

# User configuration
export EDITOR='nvim'
export VISUAL='nvim'

# Input method (Fcitx5 - Vietnamese Unikey)
export XMODIFIERS=@im=fcitx
export QT_IM_MODULE=fcitx
export GTK_IM_MODULE=fcitx

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
if [ -f /usr/share/ca-certificates/azure_cli_cert.pem ]; then
    export REQUESTS_CA_BUNDLE=/usr/share/ca-certificates/azure_cli_cert.pem
elif [ -f /etc/ssl/certs/ca-certificates.crt ]; then
    export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
fi

alias vim='nvim'
# Changing "ls" to "exa"
alias ls='eza -al --color=always --group-directories-first' # my preferred listing
alias la='eza -a --color=always --group-directories-first' # all files and dirs
alias ll='eza -l --color=always --group-directories-first' # long format
alias lt='eza -aT --color=always --group-directories-first' # tree listing
alias l.='eza -a | egrep "^\."'

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

# git
alias g="git"
alias gbr="git branch -a"
alias gst="git status"
alias gcp="git add . && git commit --amend --no-edit && git push -f"
alias grc="git rebase --continue"
alias grs="git rebase --skip"
alias grhh="git reset --hard HEAD"
# gcof [query]: fuzzy-pick a branch (local + remote, most recent first, git log preview) and check it out.
# Remote-only branches get a local tracking branch via `git switch`.
gcof() {
    local branch
    branch=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads refs/remotes \
        | grep -v -e '/HEAD$' -e '^origin$' \
        | sed 's#^origin/##' | awk '!seen[$0]++' \
        | fzf --query="$*" --select-1 --exit-0 --height=50% --reverse \
            --preview 'git log --oneline --graph --color=always -20 {} 2>/dev/null || git log --oneline --graph --color=always -20 origin/{}') \
        || return
    git switch "$branch"
}

# kubectl
alias k="kubectl"
alias kgp="k get po "
alias kgpo="k get po -owide "
alias kgn="k get node "
alias kgs="k get svc "
alias kgd="k get deploy "
alias ke="k edit "
alias kd="k describe "
alias kn="kubectl config set-context --current --namespace "
alias kr="k run --dry-run=client -oyaml --image "
alias ka="k apply -f "
alias krep="k replace --force -f "
alias kgpon="k get po -owide -n "
alias kg="k get "
do=(--dry-run=client -o yaml)

# terraform
alias tri="terraform init"
alias trp="terraform plan"
alias trv="terraform validate"
alias tra="terraform apply --auto-approve"
alias trd="terraform apply -destroy --auto-approve"

# terragrunt
alias tg="terragrunt"
alias tgi="tg init"
alias tgp="tg plan"
alias tgv="tg validate"
alias tga="tg apply --auto-approve"
alias tgd="tg apply -destroy --auto-approve"

# docker
alias dcd="docker compose down"
alias dcu="docker compose up -d"
alias dcb="docker compose build"
alias dcr="docker compose down && docker compose up -d"

# devpod
alias ducode="devpod up --devcontainer-path .devpod/devcontainer.json --ide vscode --dotfiles https://github.com/khanhcao-saritasa/dotfiles --dotfiles-script .setup-no-install.sh ."
alias ducodenc="devpod up --devcontainer-path .devpod/devcontainer.json --ide vscode --dotfiles https://github.com/khanhcao-saritasa/dotfiles --dotfiles-script .setup-no-install.sh . --recreate"
alias duvimnc="devpod up --devcontainer-path .devpod/devcontainer.json --ide none --dotfiles https://github.com/khanhcao-saritasa/dotfiles --dotfiles-script .setup-no-install.sh . --recreate"
alias duvim="devpod up --devcontainer-path .devpod/devcontainer.json --ide none --dotfiles https://github.com/khanhcao-saritasa/dotfiles --dotfiles-script .setup-no-install.sh ."
alias ds="devpod ssh"
alias drm="devpod delete"

zstyle ':bracketed-paste-magic' active-widgets '.self-*'


if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

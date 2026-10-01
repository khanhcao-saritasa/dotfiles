# ==============================================================================
#  ~/.config/fzf/fzf.bash - FZF Shell Integration for Bash
#  Reference: https://junegunn.github.io/fzf/shell-integration/
#  Themed in Catppuccin Mocha | Optimized for Sway / Wayland / Ghostty
# ==============================================================================

# Return early if not running interactively
case $- in
    *i*) ;;
      *) return 2>/dev/null || exit 0 ;;
esac

# ------------------------------------------------------------------------------
# 1. Catppuccin Mocha Palette & Global Defaults
# ------------------------------------------------------------------------------
export FZF_DEFAULT_OPTS=" \
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
    --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
    --color=selected-bg:#45475a \
    --height 60% \
    --layout=reverse \
    --border=rounded \
    --inline-info \
    --prompt='❯ ' \
    --pointer='◆ ' \
    --marker='✓ '"

# ------------------------------------------------------------------------------
# 2. Key Bindings Configuration (Refer: https://junegunn.github.io/fzf/shell-integration/)
# ------------------------------------------------------------------------------

# CTRL-R: Paste the selected command from history onto the command-line
# - Press CTRL-R again to toggle chronological vs relevance sorting
# - Press CTRL-/ to toggle line wrapping and see the whole command
# - CTRL-Y to copy the command into clipboard using wl-copy (Wayland) / xclip (X11)
_fzf_clip_cmd="wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null"
export FZF_CTRL_R_OPTS=" \
    --bind 'ctrl-y:execute-silent(echo -n {2..} | ($_fzf_clip_cmd))+abort' \
    --color header:italic \
    --header 'Press CTRL-Y to copy command into clipboard'"
unset _fzf_clip_cmd

# CTRL-T: Paste the selected files and directories onto the command-line
# - The list is generated using `--walker file,dir,follow,hidden` option
# - Skip .git, node_modules, target
# - Preview file content using bat / batcat (with fallback to head)
# - Press CTRL-/ to toggle / change preview window
export FZF_CTRL_T_OPTS=" \
    --walker-skip .git,node_modules,target \
    --preview 'bat -n --color=always {} 2>/dev/null || batcat -n --color=always {} 2>/dev/null || head -n 200 {}' \
    --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# ALT-C: cd into the selected directory
# - The list is generated using `--walker dir,follow,hidden` option
# - Skip .git, node_modules, target
# - Preview directory tree using tree / eza
export FZF_ALT_C_OPTS=" \
    --walker-skip .git,node_modules,target \
    --preview 'tree -C {} 2>/dev/null || eza --tree --level=2 --color=always {} 2>/dev/null || ls -la {}'"

# ------------------------------------------------------------------------------
# 3. Setting Up Shell Integration (eval "$(fzf --bash)")
# ------------------------------------------------------------------------------
# As documented in https://junegunn.github.io/fzf/shell-integration/
# `eval "$(fzf --bash)"` automatically configures key bindings (CTRL-T, CTRL-R,
# ALT-C) for both emacs and vi modes (vi-insert, vi-command) as well as fuzzy completion.
if command -v fzf &>/dev/null; then
    if ! eval "$(fzf --bash 2>/dev/null)"; then
        # Fallback for fzf versions < 0.48.0
        for _f in /usr/share/doc/fzf/examples/key-bindings.bash \
                  /usr/share/fzf/key-bindings.bash \
                  /etc/profile.d/fzf-key-bindings.bash \
                  "$HOME/.fzf/shell/key-bindings.bash"; do
            if [[ -f "$_f" ]]; then
                . "$_f"
                break
            fi
        done

        for _f in /usr/share/doc/fzf/examples/completion.bash \
                  /usr/share/fzf/completion.bash \
                  /usr/share/bash-completion/completions/fzf \
                  /etc/bash_completion.d/fzf \
                  "$HOME/.fzf/shell/completion.bash"; do
            if [[ -f "$_f" ]]; then
                . "$_f"
                break
            fi
        done
        unset _f
    fi
fi

# ------------------------------------------------------------------------------
# 4. Helper Functions & Aliases
# ------------------------------------------------------------------------------

# fe [query] - Fuzzy edit file(s) in $EDITOR
fe() {
    local files=()
    mapfile -t files < <(
        fzf --query="$1" \
            --multi \
            --select-1 \
            --exit-0 \
            --preview 'bat -n --color=always {} 2>/dev/null || batcat -n --color=always {} 2>/dev/null || tree -C {} 2>/dev/null || head -n 200 {}'
    )
    [[ ${#files[@]} -gt 0 ]] && "${EDITOR:-nvim}" "${files[@]}"
}

# fif [query] - Interactive ripgrep live search with syntax preview and jump to line
fif() {
    if ! command -v rg &>/dev/null; then
        echo "fif error: ripgrep (rg) is not installed." >&2
        return 1
    fi

    local editor="${EDITOR:-nvim}"
    local initial_query="${*:-}"
    local rg_prefix="rg --column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git'"
    local preview_script="bat --color=always --style=numbers --highlight-line {2} {1} 2>/dev/null || batcat --color=always --style=numbers --highlight-line {2} {1} 2>/dev/null || head -n 200 {1}"

    local selection
    selection=$(
        FZF_DEFAULT_COMMAND="$rg_prefix ''" \
        fzf --ansi \
            --disabled \
            --query "$initial_query" \
            --bind "start:reload:$rg_prefix {q} || true" \
            --bind "change:reload:$rg_prefix {q} || true" \
            --delimiter : \
            --preview "$preview_script" \
            --preview-window=right:60%:wrap \
            --header 'Type to search text | Enter: Open in editor | Esc: Cancel'
    )

    if [[ -n "$selection" ]]; then
        local file line
        file=$(cut -d: -f1 <<< "$selection")
        line=$(cut -d: -f2 <<< "$selection")
        "$editor" "+$line" "$file"
    fi
}

# fcd [path] - Fuzzy cd into any directory
fcd() {
    local target_dir
    target_dir=$(
        fzf --walker=dir,follow,hidden \
            --walker-skip=.git,node_modules,target \
            +m \
            --preview 'tree -C {} 2>/dev/null || eza --tree --level=2 --color=always {} 2>/dev/null || ls -la {}' \
            --header 'Select directory to cd'
    )
    if [[ -n "$target_dir" ]]; then
        cd "$target_dir" || return 1
    fi
}

# fkill [signal] - Fuzzy process killer with detailed process tree preview
fkill() {
    local signal="${1:-15}"
    local pids=()

    mapfile -t pids < <(
        ps -u "$USER" -o pid,%cpu,%mem,stat,start,time,comm,command | \
        sed 1d | \
        fzf --multi \
            --header "Select process(es) to kill (Signal: SIG${signal}) | Tab: Multi-select" \
            --preview 'ps -fp {1} 2>/dev/null' \
            --preview-window=down:30%:wrap | \
        awk '{print $1}'
    )

    if [[ ${#pids[@]} -gt 0 ]]; then
        echo "Sending SIG${signal} to PID(s): ${pids[*]}"
        kill -"$signal" "${pids[@]}"
    fi
}

# fgb - Fuzzy git branch switcher with commit log preview
fgb() {
    git rev-parse --is-inside-work-tree &>/dev/null || { echo "Not a git repository" >&2; return 1; }
    local branch
    branch=$(
        git for-each-ref --format='%(refname:short) | %(contents:subject) | %(authorname)' refs/heads refs/remotes | \
        fzf --header 'Select branch to checkout | Enter: Switch' \
            --preview 'git log --oneline --graph --date=short --color=always $(cut -d" " -f1 <<< {})' \
            --preview-window=right:60%:wrap | \
        awk '{print $1}'
    )
    if [[ -n "$branch" ]]; then
        local local_branch="${branch#origin/}"
        git checkout "$local_branch" 2>/dev/null || git checkout "$branch"
    fi
}

# fgl - Fuzzy git commit viewer with commit diff preview & commit hash copy
fgl() {
    git rev-parse --is-inside-work-tree &>/dev/null || { echo "Not a git repository" >&2; return 1; }
    local commit
    commit=$(
        git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" | \
        fzf --ansi --no-sort --reverse --tiebreak=index \
            --header 'Enter: View full commit | CTRL-Y: Copy commit SHA' \
            --bind 'ctrl-y:execute-silent(grep -o "[a-f0-9]\{7,\}" <<< {} | head -n1 | (wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null))+abort' \
            --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | head -n1 | xargs git show --color=always' \
            --preview-window=right:60%:wrap
    )
    if [[ -n "$commit" ]]; then
        local sha
        sha=$(grep -o "[a-f0-9]\{7,\}" <<< "$commit" | head -n1)
        [[ -n "$sha" ]] && git show "$sha"
    fi
}

# fgst - Fuzzy git status viewer with diff preview and interactive staging
fgst() {
    git rev-parse --is-inside-work-tree &>/dev/null || { echo "Not a git repository" >&2; return 1; }
    local selected
    selected=$(
        git -c color.status=always status --short | \
        fzf --ansi \
            --multi \
            --header 'Enter: Open in editor | CTRL-S: Stage/Unstage file' \
            --preview 'git diff --color=always -- {2} 2>/dev/null | head -n 300' \
            --preview-window=right:60%:wrap \
            --bind 'ctrl-s:execute(git add {2} 2>/dev/null || git restore --staged {2} 2>/dev/null)+reload(git -c color.status=always status --short)'
    )
    if [[ -n "$selected" ]]; then
        local files=()
        while IFS= read -r line; do
            local f
            f=$(awk '{print $2}' <<< "$line")
            [[ -n "$f" ]] && files+=("$f")
        done <<< "$selected"
        [[ ${#files[@]} -gt 0 ]] && "${EDITOR:-nvim}" "${files[@]}"
    fi
}

# Ergonomic aliases
alias fzf-edit="fe"
alias fzf-grep="fif"
alias fzf-cd="fcd"
alias fzf-kill="fkill"
alias fzf-branch="fgb"
alias fzf-log="fgl"
alias fzf-status="fgst"

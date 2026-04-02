# =============================================================================
#  ZINIT
# =============================================================================
# Set the directory for Zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if not installed
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Load Zinit
source "${ZINIT_HOME}/zinit.zsh"

# =============================================================================
#  PLUGINS
# =============================================================================
# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light Aloxaf/fzf-tab

# Oh My Zsh snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::command-not-found

# =============================================================================
#  COMPLETIONS
# =============================================================================
autoload -U compinit && compinit
zinit cdreplay -q

# =============================================================================
#  HISTORY
# =============================================================================
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# =============================================================================
#  KEYBINDS
# =============================================================================
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# =============================================================================
#  COMPLETION STYLING
# =============================================================================
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'lsd $realpath'

# =============================================================================
#  ALIASES
# =============================================================================
alias ls='lsd'
alias ll='lsd -la'
alias la='lsd -a'
alias tree='lsd --tree'
alias c='clear'
alias cat='bat --style=plain'
alias grep='rg'
alias vim='nvim'
alias vi='nvim'
alias ..='cd ..'
alias ...='cd ../..'

# =============================================================================
#  ENVIRONMENT
# =============================================================================
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANRWIDTH=80

# =============================================================================
#  INTEGRATIONS
# =============================================================================
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(oh-my-posh init zsh --config "${HOME}/.config/oh-my-posh/config.toml")"

# =============================================================================
#  WELCOME
# =============================================================================
[[ -z "$TMUX" && "$SHLVL" -eq 1 ]] && clear && fastfetch

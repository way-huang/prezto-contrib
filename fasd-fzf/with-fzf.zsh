#
# fasd + fzf integration.
# Source this AFTER prezto init so that fasd_cd and fasd completion are defined.
#

(( $+commands[fzf] )) || return 0

#
# Core: fzf-powered fasd_cd
#

function fasd_cd {
  local -a query=()
  for arg in "$@"; do
    [[ "$arg" == -* ]] && continue
    query+=("$arg")
  done

  # Exact path from tab completion — just cd, no second fzf pass
  if (( ${#query} == 1 )) && [[ -d "${query[1]}" ]]; then
    cd "${query[1]}"
    return
  fi

  local selected
  if (( ${#query} == 0 )); then
    selected="$(fasd -d -l -R | fzf --no-sort --height=40% --reverse)"
  else
    selected="$(fasd -d -l -R "${query[@]}" | \
      fzf --no-sort --height=40% --reverse --select-1 --exit-0)"
  fi

  [[ -n "$selected" && -d "$selected" ]] && cd "$selected" || return 1
}

#
# Helpers: directory / file selection (print path, don't cd)
#

function fasd_fzf_d {
  fasd -d -l -R "$@" | fzf --no-sort --height=40% --reverse --select-1 --exit-0
}

function fasd_fzf_f {
  fasd -f -l -R "$@" | fzf --no-sort --height=40% --reverse --select-1 --exit-0
}

#
# Tab completion: override fasd's word-completion functions to use fzf.
# The original completer chain (triggered by TAB) stays intact — we only
# replace what runs when a comma-trigger is detected.
#

_fasd_zsh_word_complete() {
  [ "$2" ] && local _fasd_cur="$2"
  [ -z "$_fasd_cur" ] && local _fasd_cur="${words[CURRENT]}"
  local fnd="${_fasd_cur//,/ }"
  local typ=${1:-e}
  local selected
  selected="$(fasd --query $typ "$fnd" 2>/dev/null | \
    sort -gr | sed 's/^[^ ]*[ ]*//' | \
    fzf --height=40% --reverse --select-1 --exit-0)"
  if [[ -n "$selected" ]]; then
    compadd -U -V fasd "$selected"
    compstate[insert]=menu
  fi
} 

#
# ZLE widgets: direct fzf pickers bound to Ctrl-X shortcuts
#

_fasd_fzf_cd_widget() {
  local selected
  selected="$(fasd -d -l -R | fzf --no-sort --height=40% --reverse)"
  if [[ -n "$selected" && -d "$selected" ]]; then
    BUFFER="cd ${(q)selected}"
    zle accept-line
  fi
  zle reset-prompt
}

zle -N _fasd_fzf_cd_widget
bindkey '^X^D' _fasd_fzf_cd_widget

_fasd_fzf_file_widget() {
  local selected
  selected="$(fasd -f -l -R | fzf --no-sort --height=40% --reverse)"
  if [[ -n "$selected" ]]; then
    LBUFFER+="${(q)selected}"
  fi
  zle reset-prompt
}

zle -N _fasd_fzf_file_widget
bindkey '^X^F' _fasd_fzf_file_widget

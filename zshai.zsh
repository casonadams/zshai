0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

typeset -g ZSHAI_HOME="${0:A:h}"
typeset -gU fpath path
fpath=("${ZSHAI_HOME}/functions" $fpath)
path=("${ZSHAI_HOME}/bin" $path)
autoload -Uz zshai _zshai _zshai_adapters _zshai_config _zshai_context _zshai_engine _zshai_hook _zshai_provider _zshai_prune _zshai_tools _zshai_truncate _zshai_widget
_zshai_config_get() { _zshai_config get "$@"; }

if [[ -o interactive ]]; then
  zle -N zshai-widget _zshai_widget 2>/dev/null || true
  if [[ "${ZSHAI_BIND_DEFAULT:-0}" == "1" ]] || [[ "$(bindkey '^G' 2>/dev/null)" == *undefined-key* ]]; then
    bindkey '^G' zshai-widget
  fi
fi

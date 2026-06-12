#!/bin/bash
# Find the pane that is NOT running nvim — assume it's claude
claude_pane=""
while IFS=: read -r pane_id pane_tty; do
  if ! ps -o state= -o comm= -t "$pane_tty" 2>/dev/null | grep -qiE '^[^TXZ ]+ +(\S+\/)?g?(view|l?n?vim?x?)(diff)?$'; then
    claude_pane="$pane_id"
    break
  fi
done < <(tmux list-panes -F '#{pane_id}:#{pane_tty}')

if [ -n "$claude_pane" ]; then
  tmux break-pane -d -s "$claude_pane" -n __claude__
elif tmux list-windows -F '#{window_name}' | grep -q '^__claude__$'; then
  tmux join-pane -h -s __claude__
else
  tmux split-window -h \
    -e ENABLE_IDE_INTEGRATION=true \
    -e FORCE_CODE_TERMINAL=true \
    "$HOME/.local/bin/claude"
fi

#!/bin/sh

export THEME='theme={"background": "#'${TTYD_BG_COLOR}'"}'

ttyd -T xterm-24bit -t "$THEME" -t disableResizeOverlay=1 -p 4001 \
  tmux -f /config/tmux.conf new-session -A -s scsc \
  emacs -q -l /config/init.el -f start-scsc
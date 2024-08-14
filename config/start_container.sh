#!/bin/sh

if ! [[ "$MODE" =~ "(both|sclang|tidal)" ]]; then
  echo 'Environment variable `MODE` must be one of: sclang, tidal, both'
  exit 1
fi

if ! [[ "$TTYD_BG_COLOR" =~ "[A-Fa-f0-9]{6}" ]]; then
  echo 'Environment variable `TTYD_BG_COLOR` must be a 6-digit, hexadecimal color code'
  exit 1
fi

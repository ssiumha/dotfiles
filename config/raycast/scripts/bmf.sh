#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Bookmarks
# @raycast.mode silent
# @raycast.icon 🔖
# @raycast.description Search bookmarks from ~/org markdown files

wezterm cli spawn -- "$HOME/.local/bin/mise" x -- "$HOME/dots/bin/bmf"
open -a WezTerm

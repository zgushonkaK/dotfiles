#!/bin/bash

set -e

mkdir -p ~/.emacs.d
mkdir -p ~/.config/tmux

echo "copying Emacs..."
cp ./.emacs ~/.emacs 2>/dev/null || echo ".emacs failed"
cp ./.emacs.d/init.el ~/.emacs.d/init.el 2>/dev/null || echo "init.el failed"

echo "copying Tmux..."
cp ./tmux.conf ~/.config/tmux/tmux.conf 2>/dev/null || echo "tmux.conf failed"

#!/bin/bash

DROPBOX_HOME=$HOME/Dropbox

cp "$DROPBOX_HOME/Dokumenty/HomeBank.xhb" \
  "$DROPBOX_HOME/Dokumenty/HomeBank Backup/HomeBank-`date '+%Y.%m.%d.%H_%M'`.xhb"

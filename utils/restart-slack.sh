#!/bin/sh
name="slack"
#title='Slack( \|.*)?'
title='.* - Slack'

if [ ! "$(_window-id "$title")" ]; then
    fkill "$name"
    start-closed "$name" "$title"
fi

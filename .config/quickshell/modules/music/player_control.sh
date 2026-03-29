#!/usr/bin/env bash

SEEK_FILE="/tmp/quickshell_music_seek_data"

command=$1
arg=$2
len_sec=$3
player_name=$4

if [ -z "$player_name" ]; then
    player_name=$(playerctl status -f "{{playerName}}" 2>/dev/null | head -n 1)
fi
if [ -z "$player_name" ]; then exit 0; fi

case $command in
    "seek")
        echo "$arg $len_sec $player_name" > "$SEEK_FILE"

        lock_file="/tmp/quickshell_music_seek_lock"

        if [ -f "$lock_file" ]; then
            exit 0
        fi

        touch "$lock_file"

        (
            sleep 0.05

            read -r final_arg final_len final_player < "$SEEK_FILE"

            if [ -n "$final_len" ] && [ "$final_len" != "0" ]; then
                target_sec=$(awk -v len="$final_len" -v perc="$final_arg" 'BEGIN { printf "%.2f", (len * perc) / 100 }')
                playerctl -p "$final_player" position "$target_sec"
            fi

            rm "$lock_file"
        ) &

        exit 0
        ;;

    "next")
        playerctl -p "$player_name" next ;;

    "prev")
        playerctl -p "$player_name" previous ;;

    "play-pause")
        playerctl -p "$player_name" play-pause ;;
esac

#!/usr/bin/env bash

TAB=$'\t'
RESULT_ID="${1%%$TAB*}"  # Keep up to the tab
THUMB_PATH="${CACHE_DIR}/$RESULT_ID.jpg"
TMP_THUMB_PATH="$THUMB_PATH.$$.tmp"
METHOD="${PREVIEW_METHOD:-text}"

# If thumbnail is still unavailable, download or wait
if [ ! -f "$THUMB_PATH" ]; then
    if [ ${#RESULT_ID} -eq 11 ]; then  # video
        # List of thumbnail URLs in order of quality
        urls=(
            "https://i.ytimg.com/vi/$RESULT_ID/maxresdefault.jpg"
            "https://i.ytimg.com/vi/$RESULT_ID/sddefault.jpg"
            "https://i.ytimg.com/vi/$RESULT_ID/hqdefault.jpg"
            "https://i.ytimg.com/vi/$RESULT_ID/mqdefault.jpg"
            "https://i.ytimg.com/vi/$RESULT_ID/default.jpg"
        )

        for url in "${urls[@]}"; do
            if curl -fs -o "$TMP_THUMB_PATH" "$url"; then
                mv "$TMP_THUMB_PATH" "$THUMB_PATH"
                break
            else
                rm -f "$TMP_THUMB_PATH"
            fi
        done
    else  # channel
        # Wait for thumbnail
        for _ in {1..1000}; do
            sleep 0.2
            [ -f "$THUMB_PATH" ] && break
        done
    fi
fi

# Show thumbnail
if [ -f "$THUMB_PATH" ]; then
    case "$METHOD" in
        "ueberzug")
            if [ -p "$UEBERZUG_FIFO" ]; then
                echo '{"action": "add", "identifier": "fzf", "x": '$FZF_PREVIEW_LEFT', "y": '$FZF_PREVIEW_TOP', "max_width": '$FZF_PREVIEW_COLUMNS', "max_height": '$FZF_PREVIEW_LINES', "path": "'$THUMB_PATH'"}' >> "$UEBERZUG_FIFO"
            fi
            ;;
        "kitten")
            # This is what Ghostty and Kitty will use
            kitten icat --clear --stdin=no --transfer-mode=memory \
                --unicode-placeholder --scale-up \
                --place="$((FZF_PREVIEW_COLUMNS))x$((FZF_PREVIEW_LINES))@0x0" \
                "$THUMB_PATH"
            ;;
        "chafa")
            chafa -s "$((FZF_PREVIEW_COLUMNS))x$((FZF_PREVIEW_LINES))" "$THUMB_PATH"
            ;;
        "catimg")
            catimg -w "$((2 * FZF_PREVIEW_COLUMNS))" "$THUMB_PATH"
            ;;
        *)
            echo "Thumbnail available at: $THUMB_PATH"
            echo "Install ueberzug, chafa, or catimg to view thumbnails in terminal"
			# echo "Debug: Method=$METHOD, Term=$TERM, Program=$TERM_PROGRAM"
            ;;
    esac
fi

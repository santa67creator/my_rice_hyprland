#!/usr/bin/env bash

CONFIG="$1/config.json"

wallpaper_path=$(jq -r '.wallpaper_path' "$CONFIG")
cache_path=$(jq -r '.cache_path' "$CONFIG")
cache_batch_size=$(jq -r '.cache_batch_size' "$CONFIG")

mkdir -p "$cache_path"

find "$wallpaper_path" \
    -type f \
    \( \
        -iname "*.jpg" \
        -o -iname "*.jpeg" \
        -o -iname "*.png" \
        -o -iname "*.webp" \
    \) \
    -print0 |

while IFS= read -r -d '' img; do

    filename=$(basename "$img")

    out="$cache_path/$filename"

    if [[ -f "$out" ]]; then
        continue
    fi

    echo "Creating thumbnail: $filename"

    magick "$img" \
        -thumbnail x500 \
        -strip \
        -quality 85 \
        "$out" &


    if (( cache_batch_size > 0 )); then

        while (( $(jobs -rp | wc -l) >= cache_batch_size )); do

            wait -n

        done
    fi

done

wait

echo "Wallpaper thumbnails ready."

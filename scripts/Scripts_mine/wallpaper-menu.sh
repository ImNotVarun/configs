#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# 🐱 Wallfetcher — Set random wallpapers (static or video trailers)
# -----------------------------------------------------------------------------

API_KEY="YpSEegTLnMhjNk3hsYAT6ObN6VT6CU8P22WoaqE24Gcry1S2mGASjvwN"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRAILER_JSON="$SCRIPT_DIR/trailers.json"
WALL_DIR="$HOME/Pictures/wallpapers"
mkdir -p "$WALL_DIR"

# -----------------------------------------------------------------------------
# 📚 Categories
# -----------------------------------------------------------------------------
pexels_categories=(
  "nature" "waves" "animals" "landscape" "mountains" "quote" "city"
  "abstract" "beach" "trees" "sunset" "flowers" "space" "underwater"
  "minimalist" "cars" "sports" "night sky" "forests"
)
nsfw_subs=(
  "NSFW_Wallpapers"
  "Sexy4KWallpaper"
  "gmbwallpapers"
  "wallpapers"
  "wallpaper"
  "minimalistphotography"
)
video_category="nsvideo"
update_category="nsvideo-update"
all_categories=( "${pexels_categories[@]}" "random" "${nsfw_subs[@]}" "$video_category" "$update_category" )

# Rofi theme
theme_path="/home/notvarun/rofi-themes-collection/themes"
theme_file="$theme_path/rounded-nord-dark.rasi"

chosen=$(printf "%s\n" "${all_categories[@]}" | rofi -dmenu \
    -theme "$theme_file" -p "Category:")
[[ -z "$chosen" ]] && exit 0

# Handle "random"
if [[ "${chosen,,}" == "random" ]]; then
  pool=( "${pexels_categories[@]}" "${nsfw_subs[@]}" )
  chosen="${pool[RANDOM % ${#pool[@]}]}"
fi

# -----------------------------------------------------------------------------
# 📽️ Update trailer list (nsvideo-update)
# -----------------------------------------------------------------------------
if [[ "$chosen" == "$update_category" ]]; then
  echo "🔁 Updating trailer list using fetch_trailers.py..."
  python3 "$SCRIPT_DIR/fetch_trailers.py" "$TRAILER_JSON"
  notify-send "Wallfetcher" "Trailer list updated."
  exit 0
fi

# -----------------------------------------------------------------------------
# 📽️ NS Video: Play a random trailer from trailers.json
# -----------------------------------------------------------------------------
if [[ "$chosen" == "$video_category" ]]; then
  echo "🎞 Playing a trailer from trailers.json..."

  [[ ! -f "$TRAILER_JSON" ]] && notify-send "Wallfetcher" "No trailers.json found. Run 'nsvideo-update' first." && exit 1

  url=$(jq -r '.[]' "$TRAILER_JSON" | shuf -n1)
  [[ -z "$url" ]] && notify-send "Wallfetcher" "Trailer list is empty." && exit 1

  out="$WALL_DIR/trailer.mp4"
  curl -s -L "$url" -o "$out"

  # 🎥 Stop existing and play the video
  pkill mpvpaper || true
  mpvpaper '*' "$out" -- --no-audio &
  mpv_pid=$!

  sleep 1
  if kill -0 "$mpv_pid" 2>/dev/null; then
    (
      sleep 90
      if kill -0 "$mpv_pid" 2>/dev/null; then
        kill "$mpv_pid"
        notify-send "Wallfetcher" "Stopped mpvpaper after 90s"
        # Optional: Restart swww-daemon
        # killall swww-daemon && swww-daemon & disown
      fi
    ) &
  else
    notify-send "Wallfetcher" "mpvpaper failed to start or exited early"
  fi

  notify-send "Wallfetcher" "Played trailer: ${url##*/}"
  exit 0
fi

# -----------------------------------------------------------------------------
# 🔞 NSFW subs => Fetch a static NSFW image from Reddit
# -----------------------------------------------------------------------------
if printf "%s\n" "${nsfw_subs[@]}" | grep -qx "$chosen"; then
  subreddit="$chosen"
  echo "Fetching NSFW image from Reddit: r/$subreddit…"

  sort_choice=$(shuf -e best hot new rising top -n1)
  case "$sort_choice" in
    best) endpoint="best.json?limit=10";;
    hot) endpoint="hot.json?limit=10";;
    new) endpoint="new.json?limit=10";;
    rising) endpoint="rising.json?limit=10";;
    top) endpoint="top.json?limit=10&t=all";;
  esac

  url="https://www.reddit.com/r/${subreddit}/${endpoint}"
  img_url=$(curl -s -A "linux:wallfetcher:v1.0" "$url" \
    | jq -r '.data.children[].data.url_overridden_by_dest' \
    | grep -E '\.(jpe?g|png)$' | shuf -n1)

  [[ -z "$img_url" ]] && notify-send "Wallfetcher" "No image in r/$subreddit ($sort_choice)" && exit 1

  curl -s -L "$img_url" -o "$WALL_DIR/wall.jpg"
  swww img "$WALL_DIR/wall.jpg" --transition-type grow --transition-fps 60
  notify-send "Wallfetcher" "Wallpaper set from r/$subreddit ($sort_choice)"
  exit 0
fi

# -----------------------------------------------------------------------------
# 🖼 Otherwise, Pexels static image
# -----------------------------------------------------------------------------
echo "Fetching from Pexels: '$chosen'…"
page=$(( RANDOM % 10 + 1 ))
response=$(curl -s -H "Authorization: $API_KEY" \
  "https://api.pexels.com/v1/search?query=${chosen// /%20}&page=$page&per_page=20")

mapfile -t img_urls < <(
  echo "$response" | jq -r \
    '.photos[] | select(.width > .height) | .src.original'
)

if [[ ${#img_urls[@]} -eq 0 ]]; then
  notify-send "Wallfetcher" "No landscape images for '$chosen'"
  exit 1
fi

img_url="${img_urls[RANDOM % ${#img_urls[@]}]}"
curl -s -L "$img_url" -o "$WALL_DIR/wall.jpg"
swww img "$WALL_DIR/wall.jpg" --transition-type grow --transition-fps 60
notify-send "Wallfetcher" "Wallpaper set from '$chosen'"

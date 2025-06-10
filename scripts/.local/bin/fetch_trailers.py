import requests
import re
import json
import time

# Pattern to match the exact trailer URLs you showed:
MP4_REGEX = re.compile(
    r'https://nsnetworktour\.newsensations\.com/trailers/mini-bites/[^\s"<>]+\.mp4[^\s"<>]*'
)

# Tell the server you’re a real browser
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    )
}

BASE_URL = "https://www.newsensations.com/tour_ns/categories/movies_{}_d.html"
MAX_PAGES = 1   # ← adjust upwards if you want more pages

all_links = set()

for page in range(1, MAX_PAGES + 1):
    url = BASE_URL.format(page)
    print(f"→ Fetching page {page}: {url}")
    resp = requests.get(url, headers=HEADERS)
    if resp.status_code != 200:
        print(f"  ! failed to load (status {resp.status_code})")
        break

    text = resp.text
    # findall will pick up even if there's a leading space inside the quotes
    matches = MP4_REGEX.findall(text)
    if matches:
        print(f"  • Found {len(matches)} matches")
        for m in matches:
            all_links.add(m.strip())   # strip off any stray whitespace
    else:
        print("  • No matches on this page")
    time.sleep(1)

# Write them out to JSON
output = sorted(all_links)
with open("trailers.json", "w", encoding="utf-8") as f:
    json.dump(output, f, indent=2)

print(f"\n✅ {len(output)} unique trailer URLs saved to trailers.json")

---
name: yad2-scrape
description: >-
  Scrape listings from Yad2 (yad2.co.il) reliably, bypassing its
  ShieldSquare/PerimeterX bot wall. Works for ANY Yad2 vertical — real estate
  (rent/sale), vehicles, second-hand/marketplace (יד שנייה), pets, jobs, etc.
  Use for any task that pulls Yad2 data: searching/filtering listings, getting
  item photos+attributes+coords, building a shortlist, or scheduling a recurring
  crawl. Covers the general method (why headless is blocked and headed Chrome
  works, the internal gw.yad2.co.il gateway feed, how to discover a vertical's
  feed path + filter params, dedupe by token) plus a confirmed real-estate
  worked example. Triggers — "scrape yad2", "search yad2", "yad2 listings",
  "yad2 feed", "find X on yad2", any yad2.co.il URL.
---

# Scraping Yad2 (any vertical)

Yad2 sits behind a **ShieldSquare/PerimeterX bot wall**. The whole method exists
to get past it. The approach below is the same for every Yad2 category; only the
feed path and filter params change per vertical. Real estate is confirmed working
(2026-06-10); treat other verticals' exact endpoints as "discover, then verify."

## Step 1 — Headed real Chrome only (the one hard rule)

- **Headless = blocked.** The `HeadlessChrome` UA is the tell; you get a captcha/
  challenge page, not data.
- **Headed real Chrome passes.** Use the `playwright-cli` skill:
  ```
  playwright-cli -s=$SESS open --browser=chrome --headed --persistent --profile=/tmp/pw-yad2-profile about:blank
  ```
  This is the working free engine and it **cannot** run headless. Any scheduling
  must therefore be **local launchd on an awake Mac** — cloud/headless runners are
  blocked.

## Step 2 — Warm the session, then use the internal feed API (don't scrape HTML)

Once a real Chrome page is **warmed on the vertical's base URL**, the internal
gateway `gw.yad2.co.il` is reachable from inside the page (it carries the warmed
cookies). Drive everything via `fetch` **from inside the page** — never a second
hard `goto`.

> **Caveat:** a hard `goto` to a new filter URL can re-fire the ShieldSquare
> challenge. Warm the session **once** on the base URL, then do all filtering
> through the feed API. Pace requests (don't hammer). Detail/item pages are also
> ShieldSquare-blocked even via in-page fetch — prefer the feed, which usually
> carries everything you need.

## Step 3 — Discover the vertical's feed path + params (do this once per category)

The gateway exposes a JSON feed per vertical at:
```
https://gw.yad2.co.il/<feed-path>?<filter params>&page=<n>
```
To find `<feed-path>` and the param names for a new vertical: on the warmed,
headed page, open DevTools → Network → filter `gw.yad2.co.il`, run the search/
filters in the UI, and copy the `feed` request. The UI's own filter clicks
generate the exact query string — read it off the wire rather than guessing.

Two shared helpers across verticals:
- **Autocomplete / id lookup** (locations, models, etc.):
  `https://gw.yad2.co.il/<vertical>-autocomplete/...?text=<query>` — resolves
  human names (a neighborhood, a car model) to the numeric ids the feed wants.
- **Dedupe by `token`** — every item has a stable `token` (its id). Item page URL
  is `https://www.yad2.co.il/<vertical>/item/<token>`.

## Worked example — real estate (confirmed)

Feed: `https://gw.yad2.co.il/realestate-feed/rent/feed?<params>`
(for sale: `/realestate-feed/forsale/feed`; a `/map` variant exists but needs a
bbox — use the list feed).

Params: `region=3&area=1&city=5000&minRooms=3&maxRooms=4&maxPrice=10000`
`&neighborhood=<ONE id>&page=<n>`

- **`neighborhood` takes a SINGLE id only.** Comma-lists silently return 0;
  `multiNeighborhood=<list>` is ignored and returns the whole city. So:
  **one query per neighborhood, then merge + dedupe by `token`.** (This
  "one-value-per-filter, loop + merge" pattern recurs on other verticals too.)
- Response buckets: **`private` + `agency`** = genuinely-filtered results — use
  these. `platinum / booster / yad1 / ...` = out-of-area promos — **skip them**.
- Page with `pagination.totalPages` / `.total`.
- Item fields in the feed: `token`, `price`, `additionalDetails.roomsCount`,
  `.squareMeter`, `additionalDetails.propertyCondition.id`,
  `address.{neighborhood,street,house,coords}`, `tags[]`,
  `metaData.coverImage`, `metaData.images[]`. **Photos + tags + coords are all in
  the feed** → no per-item detail fetch for scoring. Description *text* is the one
  thing absent from the feed.
- **Tel Aviv neighborhood IDs (city `5000`):** Old North `1483`+`1461`, New North
  `204`+`1519`, Kikar Hamedina `1516`, Lev Ha'ir `1520`. Resolve others via
  `https://gw.yad2.co.il/address-autocomplete/realestate/v2?text=<hood name>`.

A working pull script (loops hoods × pages, dedupes by token, returns rich
listings) lives at `~/Claude/new_home/scripts/pull_feed.js`, run via
`playwright-cli -s=$SESS run-code "$(cat pull_feed.js)"`. Same project has the
full pipeline — `process.py` (clean+score+new-only via `seen_tokens.json`),
`montage.py`, `RUNBOOK.md`. See memory `project-apartment-search`.

## Optional — vision / soft-criteria pass (reusable across verticals)

When the feed carries photo URLs and you need a visual judgment (apartment light,
a car's condition, item wear): download images (urllib + a browser UA), build a
montage grid with Pillow, and `Read` **one montage per item** instead of N
separate images. No system-wide Pillow — use a project `.venv`.

## Not handled here

Facebook Marketplace / groups (different source; playwright is **banned** on FB —
ban risk — use a passive Chrome-extension reader or manual paste).

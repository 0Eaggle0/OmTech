"""
Dev script: scrape omgtu.ru news list + individual articles.
Saves results to news_dev.sqlite (same schema as the Flutter app's news_cache.db).

Usage:
  pip install -r requirements.txt
  python fetch_news.py              # fetch list only (20 items)
  python fetch_news.py --limit 5   # fetch list + full text for first 5 articles
  python fetch_news.py --json       # print JSON to stdout instead of saving to DB
"""

import argparse
import json
import sqlite3
import time
from datetime import datetime
from pathlib import Path

import requests
from bs4 import BeautifulSoup

BASE_URL = "https://www.omgtu.ru"
NEWS_URL = f"{BASE_URL}/news/"
DB_PATH = Path(__file__).parent / "news_dev.sqlite"

HEADERS = {
    "Accept": "text/html,application/xhtml+xml",
    "Accept-Language": "ru-RU,ru;q=0.9",
    "User-Agent": (
        "Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
    ),
}

AWARD_KEYWORDS = ["приз", "серебр", "золот", "победа", "победи", "место",
                  "чемпион", "лауреат", "награда"]


def is_award(title: str) -> bool:
    t = title.lower()
    return any(kw in t for kw in AWARD_KEYWORDS)


def abs_url(href: str) -> str:
    if not href:
        return ""
    return href if href.startswith("http") else BASE_URL + (href if href.startswith("/") else "/" + href)


def fetch_html(url: str) -> BeautifulSoup | None:
    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        r.raise_for_status()
        r.encoding = "utf-8"
        return BeautifulSoup(r.text, "lxml")
    except Exception as e:
        print(f"  [error] {url}: {e}")
        return None


def parse_list(soup: BeautifulSoup) -> list[dict]:
    items = []

    # Bitrix CMS selectors — same priority order as Dart code
    elements = (
        soup.select(".news-list .news-item, .news-list-section .section-item, "
                    ".catItem, .bx-newslist .bx-newsitem, "
                    ".news__list .news__item, section.news article")
    )
    if not elements:
        elements = soup.select("li:has(a[href*='/news/'])")
    if not elements:
        elements = soup.select("div:has(a[href*='/?ID=']), article:has(a)")

    for el in elements[:20]:
        title_el = el.select_one(
            "h1, h2, h3, h4, .item-title, .news-title, .news__title, "
            ".section-item-title a, a.name"
        )
        title = title_el.get_text(strip=True) if title_el else ""
        if not title or len(title) < 5:
            continue

        link_el = el.select_one("a[href]")
        url = abs_url(link_el["href"]) if link_el else ""

        img_el = el.select_one("img")
        image_url = ""
        if img_el:
            image_url = abs_url(
                img_el.get("src") or img_el.get("data-src") or img_el.get("data-lazy-src") or ""
            )

        date_el = el.select_one(
            "time, [datetime], .date, .item-date, .news-date, .news__date, .section-item-date"
        )
        date_str = ""
        if date_el:
            date_str = date_el.get("datetime") or date_el.get_text(strip=True)
        date = parse_date(date_str)

        summary_el = el.select_one(
            "p, .preview-text, .introtext, .item-intro, .news__intro, .section-item-text"
        )
        summary = summary_el.get_text(strip=True) if summary_el else ""

        items.append({
            "url": url or NEWS_URL,
            "title": title,
            "summary": summary,
            "full_text": "",
            "date_ms": int(date.timestamp() * 1000),
            "image_url": image_url,
            "extra_images": [],
            "is_award": is_award(title),
            "full_fetched": False,
        })

    # Fallback: plain links
    if not items:
        seen = set()
        for a in soup.select("a[href]"):
            href = a.get("href", "")
            if "/news/" not in href and "/?ID=" not in href:
                continue
            title = a.get_text(strip=True)
            if len(title) < 10 or title in seen:
                continue
            seen.add(title)
            items.append({
                "url": abs_url(href),
                "title": title,
                "summary": "",
                "full_text": "",
                "date_ms": int(datetime.now().timestamp() * 1000),
                "image_url": "",
                "extra_images": [],
                "is_award": is_award(title),
                "full_fetched": False,
            })
            if len(items) >= 10:
                break

    return items


def parse_article(url: str, soup: BeautifulSoup, existing: dict) -> dict | None:
    content_selectors = [
        ".news-detail-text", ".news-detail__text",
        ".article__body", ".article-body",
        "[data-entity='detail-text']", "#article-body",
        ".bx-news-detail", ".detail_text",
        ".news-detail",
    ]
    content_el = None
    for sel in content_selectors:
        content_el = soup.select_one(sel)
        if content_el:
            break
    if content_el is None:
        content_el = soup.select_one("article")
    if content_el is None:
        return None

    paragraphs = [
        el.get_text(strip=True)
        for el in content_el.select("p, h2, h3, h4")
        if len(el.get_text(strip=True)) >= 20
    ]
    if not paragraphs:
        return None

    full_text = "\n\n".join(paragraphs)
    main_image = existing.get("image_url", "")
    extra_images = list({
        abs_url(img.get("src") or img.get("data-src") or "")
        for img in content_el.select("img")
        if abs_url(img.get("src") or img.get("data-src") or "") not in ("", main_image)
    })

    return {**existing, "full_text": full_text, "extra_images": extra_images, "full_fetched": True}


def parse_date(raw: str) -> datetime:
    if not raw:
        return datetime.now()
    try:
        return datetime.fromisoformat(raw)
    except ValueError:
        pass
    import re
    m = re.search(r"(\d{1,2})\.(\d{1,2})\.(\d{4})", raw)
    if m:
        return datetime(int(m.group(3)), int(m.group(2)), int(m.group(1)))
    return datetime.now()


def init_db(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS news_articles (
            url TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            summary TEXT,
            full_text TEXT,
            date_ms INTEGER,
            image_url TEXT,
            extra_images TEXT,
            is_award INTEGER,
            cached_at INTEGER,
            full_fetched INTEGER
        )
    """)
    conn.commit()
    return conn


def save_items(conn: sqlite3.Connection, items: list[dict]) -> None:
    now = int(datetime.now().timestamp() * 1000)
    for item in items:
        conn.execute("""
            INSERT OR IGNORE INTO news_articles
              (url, title, summary, full_text, date_ms, image_url, extra_images,
               is_award, cached_at, full_fetched)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            item["url"], item["title"], item["summary"],
            item.get("full_text") or None,
            item["date_ms"], item["image_url"],
            json.dumps(item["extra_images"], ensure_ascii=False),
            1 if item["is_award"] else 0, now,
            1 if item.get("full_fetched") else 0,
        ))
        if item.get("full_fetched"):
            conn.execute("""
                UPDATE news_articles SET full_text=?, extra_images=?,
                  full_fetched=1, cached_at=?
                WHERE url=?
            """, (
                item["full_text"],
                json.dumps(item["extra_images"], ensure_ascii=False),
                now, item["url"],
            ))
    conn.commit()


def main() -> None:
    parser = argparse.ArgumentParser(description="Scrape omgtu.ru news")
    parser.add_argument("--limit", type=int, default=0,
                        help="Fetch full article text for first N items (0 = list only)")
    parser.add_argument("--json", action="store_true",
                        help="Print JSON to stdout instead of saving to DB")
    args = parser.parse_args()

    print(f"Fetching news list from {NEWS_URL} …")
    soup = fetch_html(NEWS_URL)
    if soup is None:
        print("Failed to fetch news list.")
        return

    items = parse_list(soup)
    print(f"  Parsed {len(items)} articles from list page")

    if args.limit > 0:
        for i, item in enumerate(items[: args.limit]):
            print(f"  [{i+1}/{args.limit}] Fetching full text: {item['url']}")
            art_soup = fetch_html(item["url"])
            if art_soup:
                result = parse_article(item["url"], art_soup, item)
                if result:
                    items[i] = result
                    print(f"    → {len(result['full_text'])} chars, {len(result['extra_images'])} extra images")
                else:
                    print("    → content block not found")
            time.sleep(0.5)  # be polite

    if args.json:
        print(json.dumps(items, ensure_ascii=False, indent=2))
    else:
        conn = init_db(DB_PATH)
        save_items(conn, items)
        conn.close()
        print(f"\nSaved {len(items)} articles to {DB_PATH}")
        print("Tip: open with 'sqlite3 news_dev.sqlite' or DB Browser for SQLite")


if __name__ == "__main__":
    main()

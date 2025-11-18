import json
import time
import sys
import re
from pathlib import Path
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

# ------------------------------
# Config
# ------------------------------

BASE_URL = "https://gymvisual.com"
SEARCH_URL = f"{BASE_URL}/search"

REQUEST_DELAY_SECONDS = 1.0      # be nice to their servers
GLOBAL_THRESHOLD = 0.5           # below this, we'll flag possible mismatch
MAX_PAGES_PER_TERM = 3           # how many pages of search results to scan per term
MIN_ACCEPTABLE_SCORE = 0.35      # if best match < this, treat as NO IMAGE FOUND

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    )
}

SCRIPT_DIR = Path(__file__).resolve().parent
EXERCISES_PATH = SCRIPT_DIR / "exercises.json"
OUTPUT_PATH = SCRIPT_DIR / "gymvisual_images.txt"

LOG_FILE = None  # set in main()


# ------------------------------
# Logging
# ------------------------------

def log(msg: str = ""):
    """Print to console AND mirror into the output file."""
    print(msg)
    global LOG_FILE
    if LOG_FILE is not None:
        LOG_FILE.write(msg + "\n")
        LOG_FILE.flush()


# ------------------------------
# Similarity helpers
# ------------------------------

def normalize_for_chars(s: str) -> str:
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "", s)
    return s


def levenshtein_distance(a: str, b: str) -> int:
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    if len(a) < len(b):
        a, b = b, a

    previous_row = list(range(len(b) + 1))
    for i, ca in enumerate(a, start=1):
        current_row = [i]
        for j, cb in enumerate(b, start=1):
            insert_cost = current_row[j - 1] + 1
            delete_cost = previous_row[j] + 1
            replace_cost = previous_row[j - 1] + (ca != cb)
            current_row.append(min(insert_cost, delete_cost, replace_cost))
        previous_row = current_row

    return previous_row[-1]


def char_similarity(target_label: str, candidate_label: str) -> float:
    """
    similarity = 1 - (edit_distance / max_len)
    1.0 -> identical, 0.0 -> completely different
    """
    t = normalize_for_chars(target_label)
    c = normalize_for_chars(candidate_label)
    if not t or not c:
        return 0.0

    dist = levenshtein_distance(t, c)
    max_len = max(len(t), len(c))
    if max_len == 0:
        return 1.0

    score = 1.0 - dist / max_len
    return max(score, 0.0)


def tokenize_words(s: str) -> list[str]:
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", " ", s)
    return [w for w in s.split() if w]


# ------------------------------
# HTML helpers
# ------------------------------

def fetch_search_page(term: str, page: int) -> str | None:
    """
    Fetch a single search page for a term, e.g. p=1,2,3.
    """
    params = {
        "near": "All categories",
        "controller": "search",
        "orderby": "position",
        "orderway": "desc",
        "search_query": term,
        "submit_search": "",
        "p": page,
    }

    try:
        resp = requests.get(SEARCH_URL, params=params, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        return resp.text
    except Exception as e:
        log(f"⚠️  Request failed for term '{term}' on page {page}: {e}")
        return None


def candidate_semantic_label(img) -> str | None:
    """
    Try to infer a human-readable label from markup:
    - img.alt
    - img.title
    - parent <a>.title
    - parent <a>'s text
    """
    for attr in ("alt", "title"):
        val = img.get(attr)
        if val and val.strip():
            return val.strip()

    link = img.find_parent("a")
    if link:
        title = link.get("title")
        if title and title.strip():
            return title.strip()
        txt = link.get_text(" ", strip=True)
        if txt:
            return txt

    return None


def slug_label_from_src(src: str) -> str | None:
    """
    Derive a label from filename:
    /img/p/.../barbell-bench-press.gif -> "Barbell Bench Press"
    """
    if not src:
        return None
    fname = src.split("/")[-1]
    fname = fname.split("?")[0]
    fname = fname.split(".")[0]
    if not fname:
        return None
    label = fname.replace("-", " ").replace("_", " ").strip()
    if not label:
        return None
    return " ".join(w.capitalize() for w in label.split())


def gather_candidates_for_target(term: str, target_label: str, exercise_tokens: set[str]):
    """
    Fetch up to MAX_PAGES_PER_TERM result pages for this term and
    return a list of candidate dicts:
      {url, label, score, is_gif}

    Scoring:
      - base_score = char_similarity(target_label, best_label_for_image)
      - tokens:
          label_tokens = tokens(best_label)
      - penalties:
          extra_tokens = label_tokens - exercise_tokens

        score = base_score - EXTRA_PENALTY_PER_WORD * len(extra_tokens)
    """
    candidates = []
    seen_src = set()
    EXTRA_PENALTY_PER_WORD = 0.12  # heavy penalty for words not in this exercise

    for page in range(1, MAX_PAGES_PER_TERM + 1):
        html = fetch_search_page(term, page)
        if not html:
            break  # stop if we hit an error

        soup = BeautifulSoup(html, "html.parser")

        selectors = [
            ".product_list .product-container img",
            "ul.product_list img",
            ".products img",
            "img"
        ]

        page_found_any = False

        for sel in selectors:
            for img in soup.select(sel):
                src = img.get("src")
                if not src:
                    continue
                src = src.strip()

                # 🚫 Skip obvious non-exercise CMS images (banners, payment logos, etc.)
                if "/img/cms/" in src:
                    continue

                if src in seen_src:
                    continue
                seen_src.add(src)
                page_found_any = True

                semantic_label = candidate_semantic_label(img)
                slug_label = slug_label_from_src(src)

                best_label = None
                base_score = 0.0

                # Compare using semantic label
                if semantic_label:
                    s_sem = char_similarity(target_label, semantic_label)
                    best_label = semantic_label
                    base_score = s_sem

                # Compare using slug label
                if slug_label:
                    s_slug = char_similarity(target_label, slug_label)
                    if s_slug > base_score:
                        best_label = slug_label
                        base_score = s_slug

                if best_label is None:
                    continue

                # ---- Penalize label tokens that don't appear anywhere in this exercise ----
                label_tokens = set(tokenize_words(best_label))
                extra_tokens = label_tokens - exercise_tokens
                penalty = EXTRA_PENALTY_PER_WORD * len(extra_tokens)
                score = max(base_score - penalty, 0.0)
                # -------------------------------------------------------------------------- 

                is_gif = ".gif" in src.lower()

                candidates.append({
                    "url": urljoin(BASE_URL, src),
                    "label": best_label,
                    "score": score,
                    "is_gif": is_gif,
                })

        # If this page had no product images at all, stop scanning further pages
        if not page_found_any:
            break

    return candidates


def extract_best_image_for_target(term: str, target_label: str, exercise_tokens: set[str]):
    """
    For a given search term / target label, scan multiple pages
    and pick the single best image candidate.
      -> (url, label, score, is_gif)
    """
    candidates = gather_candidates_for_target(term, target_label, exercise_tokens)
    if not candidates:
        return None, None, 0.0, False

    best_score = max(c["score"] for c in candidates)

    # If even the best match is terrible, treat as "no image found"
    if best_score < MIN_ACCEPTABLE_SCORE:
        return None, None, 0.0, False

    SCORE_EPSILON = 0.02

    def sort_key(c):
        near_best = (best_score - c["score"]) <= SCORE_EPSILON
        gif_bump = near_best and c["is_gif"]
        return (c["score"], gif_bump)

    candidates.sort(key=sort_key, reverse=True)
    best = candidates[0]
    return best["url"], best["label"], best["score"], best["is_gif"]


# ------------------------------
# Search per term + global selection
# ------------------------------

def search_and_select(term: str, target_label: str, exercise_tokens: set[str]):
    """
    Run a search for 'term', score candidates against 'target_label'.
    Returns per-term best candidate:
       (url, label, score, is_gif, low_conf)
    """
    log(f"🔎 Searching for '{term}'...")
    img_url, img_label, score, is_gif = extract_best_image_for_target(term, target_label, exercise_tokens)

    if not img_url:
        log(f"❌ No image found for '{term}'")
        time.sleep(REQUEST_DELAY_SECONDS)
        return None, None, 0.0, False, False

    label_info = img_label or "<unknown name>"
    media_type = "GIF" if is_gif else "image"
    log(f"✅ Found {media_type} for '{term}': {img_url}")
    log(f"   ↳ Best match name: '{label_info}' (similarity: {score:.2f})")

    low_conf = score < GLOBAL_THRESHOLD
    time.sleep(REQUEST_DELAY_SECONDS)
    return img_url, img_label, score, is_gif, low_conf


def reordered_term(term: str) -> str | None:
    words = [w for w in term.split() if w.strip()]
    if len(words) < 2:
        return None
    reordered = " ".join(sorted(words, key=lambda w: w.lower()))
    if reordered.lower() == term.lower():
        return None
    return reordered


def pick_better_candidate(current: dict | None, new: dict, source: str) -> dict:
    """
    Decide whether `new` is better than `current`.

    Priority (with tolerance in BOTH directions):
    1. Source type: alias (3) > name (2) > equipment+name (1)
       - A higher-ranked source can win even if its score is noticeably lower.
       - A lower-ranked source must be significantly better in score to dethrone
         a higher-ranked one.
    2. Higher similarity score.
    3. If still equal and same source rank: prefer GIF over non-GIF.
    """
    SOURCE_RANK = {"alias": 3, "name": 2, "equipment+name": 1}
    HIGHER_RANK_TOL = 0.25  # how much worse a higher-rank source can be and still win
    LOWER_RANK_MARGIN = 0.10  # how much better a lower-rank source must be to win

    if current is None:
        new["source"] = source
        return new

    cur_source = current.get("source", "equipment+name")
    cur_rank = SOURCE_RANK.get(cur_source, 0)
    new_rank = SOURCE_RANK.get(source, 0)

    cur_score = current["score"]
    new_score = new["score"]

    # Different source ranks
    if cur_rank != new_rank:
        # New is higher rank (e.g. alias beating name/equipment+name)
        if new_rank > cur_rank:
            # Let higher-rank new win if it's not *much* worse
            if new_score + HIGHER_RANK_TOL >= cur_score:
                new["source"] = source
                return new
            else:
                return current
        else:
            # New is lower rank; only let it win if it's clearly superior
            if new_score >= cur_score + LOWER_RANK_MARGIN:
                new["source"] = source
                return new
            else:
                return current

    # Same rank: compare score directly
    if new_score > cur_score + 1e-6:
        new["source"] = source
        return new

    # If scores effectively equal and same rank, prefer GIF.
    if abs(new_score - cur_score) <= 1e-6:
        if new["is_gif"] and not current["is_gif"]:
            new["source"] = source
            return new

    return current


def find_best_image_for_exercise(name: str, aliases: list[str], equipment_required: list[str]):
    """
    For this exercise, try:
      - name
      - aliases
      - '<equipment> <name>' combos
    For each, search & get the best image.
    Then pick the single best candidate overall.
    If we ever find a perfect match (similarity ≈ 1.0), return it immediately.
    """
    term_entries: list[tuple[str, str]] = []  # (term, source_type)
    seen_terms: set[str] = set()

    # Build exercise-wide token set for penalties
    exercise_tokens: set[str] = set()
    for s in [name] + (aliases or []) + (equipment_required or []):
        exercise_tokens.update(tokenize_words(s))

    def add_term(term: str, source: str):
        t = term.strip()
        if not t:
            return
        key = t.lower()
        if key in seen_terms:
            return
        seen_terms.add(key)
        term_entries.append((t, source))

    # Base name
    if name:
        add_term(name, "name")

    # Aliases
    for alias in aliases or []:
        add_term(alias, "alias")

    # Equipment + name
    for eq in equipment_required or []:
        add_term(f"{eq} {name}", "equipment+name")

    best_candidate: dict | None = None
    PERFECT_MATCH = 0.999  # treat >= 0.999 as "1.0" for safety

    for term, source in term_entries:
        # First attempt: this term, score vs this term
        img_url, img_label, score, is_gif, low_conf = search_and_select(term, term, exercise_tokens)

        if img_url:
            cand = {
                "url": img_url,
                "used_term": term,
                "label": img_label,
                "score": score,
                "is_gif": is_gif,
            }
            best_candidate = pick_better_candidate(best_candidate, cand, source)

            # 🔥 Perfect match – just return immediately
            if best_candidate["score"] >= PERFECT_MATCH:
                return (
                    best_candidate["url"],
                    best_candidate["used_term"],
                    best_candidate["label"],
                    False,  # not low confidence
                )

        # If nothing or weak match, try reordered term once
        if (not img_url or low_conf):
            alt_term = reordered_term(term)
            if alt_term:
                log(f"   ↪ Weak match ({score:.2f}), trying reordered search term: '{alt_term}'")
                img_url2, img_label2, score2, is_gif2, low_conf2 = search_and_select(alt_term, term, exercise_tokens)
                if img_url2:
                    cand2 = {
                        "url": img_url2,
                        "used_term": alt_term,
                        "label": img_label2,
                        "score": score2,
                        "is_gif": is_gif2,
                    }
                    best_candidate = pick_better_candidate(best_candidate, cand2, source)

                    if best_candidate["score"] >= PERFECT_MATCH:
                        return (
                            best_candidate["url"],
                            best_candidate["used_term"],
                            best_candidate["label"],
                            False,
                        )

    # No perfect match; fall back to best we found
    if best_candidate is None:
        return None, None, None, False

    low_conf_global = best_candidate["score"] < GLOBAL_THRESHOLD
    if low_conf_global:
        label_display = best_candidate["label"] or "<unknown name>"
        log(
            f"⚠️  Warning: best match name '{label_display}' may not be correct "
            f"for exercise '{name}' (similarity: {best_candidate['score']:.2f})"
        )

    return (
        best_candidate["url"],
        best_candidate["used_term"],
        best_candidate["label"],
        low_conf_global,
    )


# ------------------------------
# Main
# ------------------------------

def load_exercises(path: Path) -> list[dict]:
    try:
        with path.open("r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        print(f"❌ Failed to read {path}: {e}", file=sys.stderr)
        sys.exit(1)

    if not isinstance(data, list):
        print(f"❌ Expected top-level JSON to be a list of exercises, got {type(data)}", file=sys.stderr)
        sys.exit(1)

    return data


def main():
    if not EXERCISES_PATH.exists():
        print(f"❌ {EXERCISES_PATH} not found.")
        print("   Files in this folder:")
        for p in SCRIPT_DIR.iterdir():
            print("   -", p.name)
        sys.exit(1)

    exercises = load_exercises(EXERCISES_PATH)
    total = len(exercises)
    print(f"📄 Loaded {total} exercises from {EXERCISES_PATH.name}")

    global LOG_FILE
    with OUTPUT_PATH.open("w", encoding="utf-8") as outf:
        LOG_FILE = outf
        log(f"📄 Loaded {total} exercises from {EXERCISES_PATH.name}")

        for idx, ex in enumerate(exercises, start=1):
            name = (ex.get("name") or "").strip()
            aliases = ex.get("aliases") or []
            equipment_required = ex.get("equipmentRequired") or []

            if not isinstance(aliases, list):
                aliases = []
            if not isinstance(equipment_required, list):
                equipment_required = []

            if not name:
                log(f"\n[{idx}/{total}] Skipping exercise with missing 'name'")
                continue

            log("")
            log(f"[{idx}/{total}] Processing: {name}")

            img_url, used_term, img_label, low_conf = find_best_image_for_exercise(
                name,
                aliases,
                equipment_required
            )

            if img_url:
                line = f"📝 {name}: {img_url}"
                if used_term and used_term != name:
                    line += f"  # matched on '{used_term}'"
                if low_conf:
                    line += "  [POSSIBLE MISMATCH]"
            else:
                line = f"📝 {name}: NO IMAGE FOUND"

            log(line)

        LOG_FILE = None


if __name__ == "__main__":
    main()

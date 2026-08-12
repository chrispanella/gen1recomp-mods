#!/usr/bin/env python3
"""Build the mod-index feed for gen1recomp.

Scans each mod folder (a dir with manifest.json), zips it into
site/mods/<id>.zip (mod files at the archive root, the shape the game's
"Import mod .zip" accepts), and writes site/data/index.json (schema_version 1)
listing every mod. The feed is served by GitHub Pages at
  https://<owner>.github.io/<repo>/data/index.json
and, until Pages is enabled, via the raw fallback the engine uses:
  https://raw.githubusercontent.com/<owner>/<repo>/main/site/data/index.json

Run from the repo root:  python tools/build_index.py
"""
import json, os, re, zipfile, sys

OWNER_REPO = "chrispanella/gen1recomp-mods"
RAW_BASE = f"https://raw.githubusercontent.com/{OWNER_REPO}/main/site/mods"
REPO_URL = f"https://github.com/{OWNER_REPO}"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = os.path.join(ROOT, "site")
MODS_OUT = os.path.join(SITE, "mods")
DATA_OUT = os.path.join(SITE, "data")

SKIP_DIRS = {".git", "site", "tools", ".github"}


def find_mods():
    for name in sorted(os.listdir(ROOT)):
        d = os.path.join(ROOT, name)
        if name in SKIP_DIRS or not os.path.isdir(d):
            continue
        if os.path.exists(os.path.join(d, "manifest.json")):
            yield name, d


def read_card(path):
    """Best-effort extract summary + tags from a Lua mod.card."""
    summary, tags = None, []
    if os.path.exists(path):
        text = open(path, encoding="utf-8").read()
        m = re.search(r'summary\s*=\s*"((?:[^"\\]|\\.)*)"', text)
        if m:
            summary = m.group(1)
        tm = re.search(r'tags\s*=\s*\{(.*?)\}', text, re.S)
        if tm:
            tags = re.findall(r'"([^"]+)"', tm.group(1))
    return summary, tags


def zip_mod(mod_dir, out_zip):
    """Zip the mod's files at the archive root (deterministic order)."""
    os.makedirs(os.path.dirname(out_zip), exist_ok=True)
    files = []
    for base, _, names in os.walk(mod_dir):
        for n in names:
            full = os.path.join(base, n)
            rel = os.path.relpath(full, mod_dir).replace("\\", "/")
            files.append((full, rel))
    files.sort(key=lambda t: t[1])
    with zipfile.ZipFile(out_zip, "w", zipfile.ZIP_DEFLATED) as z:
        for full, rel in files:
            # fixed timestamp for reproducible archives
            info = zipfile.ZipInfo(rel, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            with open(full, "rb") as fh:
                z.writestr(info, fh.read())


def main():
    os.makedirs(MODS_OUT, exist_ok=True)
    os.makedirs(DATA_OUT, exist_ok=True)
    mods, categories = [], set()
    for name, d in find_mods():
        manifest = json.load(open(os.path.join(d, "manifest.json"), encoding="utf-8"))
        mod_id = manifest["id"]
        summary, tags = read_card(os.path.join(d, "mod.card"))
        summary = summary or manifest.get("description", "")
        cat = manifest.get("category")
        if cat:
            categories.add(cat)
        zip_mod(d, os.path.join(MODS_OUT, f"{mod_id}.zip"))
        mods.append({
            "id": mod_id,
            "title": manifest.get("name", mod_id),
            "author": "chrispanella",
            "version": str(manifest.get("version", "0.0.0")),
            "summary": summary,
            "categories": [cat] if cat else [],
            "tags": tags,
            "api": manifest.get("api"),
            "game_version": manifest.get("game_version"),
            "profile": manifest.get("profile"),
            "permissions": manifest.get("permissions", []),
            "dependencies": manifest.get("dependencies", []),
            "github": OWNER_REPO,
            "repo": REPO_URL,
            "downloadURL": f"{RAW_BASE}/{mod_id}.zip",
        })
        print(f"packed {mod_id} v{manifest.get('version')}")

    feed = {
        "schema_version": 1,
        "generated_at": os.environ.get("BUILD_STAMP", "static"),
        "categories": sorted(categories),
        "mods": mods,
    }
    with open(os.path.join(DATA_OUT, "index.json"), "w", encoding="utf-8") as fh:
        json.dump(feed, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    print(f"wrote site/data/index.json ({len(mods)} mods)")


if __name__ == "__main__":
    sys.exit(main())

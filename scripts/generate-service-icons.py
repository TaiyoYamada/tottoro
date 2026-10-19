#!/usr/bin/env python3
"""Generates the service icons that Tottoro shows for accounts, such as GitHub or Google.

The icons come from Simple Icons (CC0). Only services that the 2FA Directory lists as supporting
TOTP are kept, so that the app does not carry thousands of icons nobody uses for codes.
Icons that Simple Icons marks with a license other than CC0 are left out.

Writes Tottoro/Resources/ServiceIcons.xcassets and Tottoro/Resources/ServiceIcons.json.
Do not edit those by hand. Run this script again to update them:

    python3 scripts/generate-service-icons.py
"""

import io
import json
import re
import shutil
import tarfile
import urllib.request
from pathlib import Path

SIMPLE_ICONS_VERSION = "16.35.0"
SIMPLE_ICONS_URL = f"https://registry.npmjs.org/simple-icons/-/simple-icons-{SIMPLE_ICONS_VERSION}.tgz"
TWO_FA_DIRECTORY_URL = "https://api.2fa.directory/v3/totp.json"

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Tottoro/Resources/ServiceIcons.xcassets"
INDEX = ROOT / "Tottoro/Resources/ServiceIcons.json"


def normalized(name):
    """Matches names the same way as ServiceIconCatalog in TottoroCore."""
    return re.sub(r"[^0-9a-z]", "", name.lower())


def download(url):
    # The 2FA Directory API refuses Python's default User-Agent
    request = urllib.request.Request(url, headers={"User-Agent": "tottoro-service-icons"})
    with urllib.request.urlopen(request) as response:
        return response.read()


def main():
    package = tarfile.open(fileobj=io.BytesIO(download(SIMPLE_ICONS_URL)))
    icons = json.load(package.extractfile("package/data/simple-icons.json"))
    services = json.loads(download(TWO_FA_DIRECTORY_URL))

    # 2FA Directory: normalized service name -> domains, and the main part of a domain
    # (google for chat.google.com) -> domains. The directory lists "Google Chat" and "Google Drive", not "Google".
    # A label only counts when the service's name starts with it, so that osu.edu (Ohio State) does not get osu!'s logo
    domains_by_name = {}
    domains_by_label = {}
    for name, info in services:
        domains = [info["domain"], *info.get("additional-domains", [])]
        domains_by_name.setdefault(normalized(name), set()).update(domains)
        for domain in domains:
            labels = domain.split(".")
            label = normalized(labels[-2]) if len(labels) >= 2 else ""
            if label and normalized(name).startswith(label):
                domains_by_label.setdefault(label, set()).add(domain)

    entries = []
    for icon in icons:
        if icon.get("license", {"type": "CC0-1.0"})["type"] != "CC0-1.0":
            continue
        aliases = icon.get("aliases", {})
        names = {icon["title"], *aliases.get("aka", []), *(dup["title"] for dup in aliases.get("dup", []))}
        domains = set()
        for name in names:
            domains |= domains_by_name.get(normalized(name), set())
        for key in (icon["slug"], normalized(icon["title"])):
            domains |= domains_by_label.get(key, set())
        if not domains:
            continue
        svg = package.extractfile(f"package/icons/{icon['slug']}.svg").read()
        entries.append({
            "slug": icon["slug"],
            "title": icon["title"],
            "names": sorted(names),
            "domains": sorted(domains),
            "svg": svg,
        })

    shutil.rmtree(CATALOG, ignore_errors=True)
    CATALOG.mkdir(parents=True)
    write_json(CATALOG / "Contents.json", {"info": {"author": "xcode", "version": 1}})
    # The folder gives the images a namespace, so they are named "ServiceIcons/github"
    folder = CATALOG / "ServiceIcons"
    folder.mkdir()
    write_json(folder / "Contents.json", {
        "info": {"author": "xcode", "version": 1},
        "properties": {"provides-namespace": True},
    })
    for entry in entries:
        imageset = folder / f"{entry['slug']}.imageset"
        imageset.mkdir()
        (imageset / f"{entry['slug']}.svg").write_bytes(entry["svg"])
        write_json(imageset / "Contents.json", {
            "images": [{"filename": f"{entry['slug']}.svg", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1},
            # Drawn in the account's text color, like an SF Symbol
            "properties": {"preserves-vector-representation": True, "template-rendering-intent": "template"},
        })

    index = [{key: entry[key] for key in ("slug", "title", "names", "domains")} for entry in entries]
    index.sort(key=lambda entry: entry["title"].lower())
    write_json(INDEX, {"simpleIconsVersion": SIMPLE_ICONS_VERSION, "icons": index})
    print(f"Wrote {len(entries)} icons")


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()

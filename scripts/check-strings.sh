#!/bin/sh
# Fails when a String Catalog has a string without a translation, or a string that is no longer used.
set -eu

python3 - $(git ls-files --cached --others --exclude-standard '*.xcstrings') <<'PYTHON'
import json
import sys

LANGUAGES = ["ja"]


def translated(localization):
    if "stringUnit" in localization:
        return localization["stringUnit"]["state"] == "translated"
    return all(translated(case) for variation in localization["variations"].values() for case in variation.values())


problems = []
for path in sys.argv[1:]:
    with open(path, encoding="utf-8") as file:
        catalog = json.load(file)
    for key, string in catalog["strings"].items():
        if string.get("extractionState") == "stale":
            problems.append(f"{path}: \"{key}\" is no longer used. Remove it.")
            continue
        if not string.get("shouldTranslate", True):
            continue
        for language in LANGUAGES:
            localization = string.get("localizations", {}).get(language)
            if localization is None or not translated(localization):
                problems.append(f"{path}: \"{key}\" has no {language} translation.")

print("\n".join(problems))
sys.exit(1 if problems else 0)
PYTHON

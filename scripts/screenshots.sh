#!/bin/sh
# Takes the App Store screenshots in English and Japanese, and writes the PNG files to build/screenshots/.
# Set XCODEBUILD to use another command with the same arguments as xcodebuild.
set -eu

xcodebuild=${XCODEBUILD:-xcodebuild}

shoot() {
    name="$1"
    destination="$2"
    result="build/Screenshots-$name.xcresult"
    rm -rf "$result" "build/screenshots/$name"
    $xcodebuild test -project Tottoro.xcodeproj -scheme Tottoro -testPlan Screenshots \
        -destination "$destination" -resultBundlePath "$result" \
        -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO
    xcrun xcresulttool export attachments --path "$result" --output-path "build/screenshots/$name"
    # The exported files are named with UUIDs. Rename them to the attachment names, such as "ja-1-codes.png".
    python3 - "build/screenshots/$name" <<'PYTHON'
import json
import pathlib
import re
import sys

folder = pathlib.Path(sys.argv[1])
for test in json.loads((folder / "manifest.json").read_text()):
    for attachment in test["attachments"]:
        name = re.sub(r"_\d+_[0-9A-F-]+(?=\.png$)", "", attachment["suggestedHumanReadableName"])
        (folder / attachment["exportedFileName"]).rename(folder / name)
PYTHON
}

shoot iPhone "platform=iOS Simulator,name=iPhone 18 Pro Max"
shoot iPad "platform=iOS Simulator,name=iPad Pro 13-inch (M5)"
shoot Mac "platform=macOS,arch=arm64"

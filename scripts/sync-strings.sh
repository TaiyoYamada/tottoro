#!/bin/sh
# Updates the String Catalogs from the strings that the compiler found in the source code.
# Build for both iOS and macOS into the same DerivedData first, so that strings used only on one platform are kept.
#
#   scripts/sync-strings.sh <DerivedData path>
set -eu

# With a sanitizer on (the Unit test plan uses Thread Sanitizer), Xcode puts the build under Variant-TSan/ or similar
intermediates="$1/Build/Intermediates.noindex"

sync() {
    target="$1"
    catalogs="$2"
    stringsdata=$(find "$intermediates" -path "*/Tottoro.build/*/$target.build/*" -name '*.stringsdata' -not -name 'ExtractedAppShortcutsMetadata.stringsdata')
    if [ -z "$stringsdata" ]; then
        echo "No .stringsdata for $target under $intermediates. Build the app first." >&2
        exit 1
    fi
    # shellcheck disable=SC2086
    xcrun xcstringstool sync $catalogs --stringsdata $stringsdata
}

sync Tottoro Tottoro/Resources/Localizable.xcstrings
sync TottoroAutoFill TottoroAutoFill/Localizable.xcstrings

#!/bin/sh
# Xcode Cloud runs this right after cloning. The Xcode project is not in Git, so generate it here.
# Set TOTTORO_DEVELOPMENT_TEAM in the Xcode Cloud workflow's environment variables.
set -eu

cd "$CI_PRIMARY_REPOSITORY_PATH"

brew install mise
mise trust
mise install xcodegen

printf 'DEVELOPMENT_TEAM = %s\n' "${TOTTORO_DEVELOPMENT_TEAM:?Set TOTTORO_DEVELOPMENT_TEAM in the Xcode Cloud workflow}" > Local.xcconfig
mise exec -- xcodegen generate

# The swift-protobuf build plugin has to be trusted without the prompt in Xcode
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

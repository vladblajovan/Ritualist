#!/bin/sh
# SwiftLint (scan all files, print to Xcode build log)

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH/"

# Run from the project root so SwiftLint finds .swiftlint.yml automatically
cd "$SRCROOT/Ritualist"

echo "SwiftLint: running in $PWD"
if command -v swiftlint >/dev/null 2>&1; then
  # Use your config if present; otherwise lint with defaults
  if [ -f ".swiftlint.yml" ]; then
    swiftlint lint --config .swiftlint.yml --reporter xcode
  else
    swiftlint lint --reporter xcode
  fi
else
  echo "warning: SwiftLint not installed (brew install swiftlint)"
fi


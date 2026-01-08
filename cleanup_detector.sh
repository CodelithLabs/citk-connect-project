#!/bin/bash
# cleanup_detector.sh: Detects wasteful files in a project
# - Empty files
# - Duplicate files between root and lib/
# - Files outside standard structure
set -e

echo "== Checking for empty files =="
find . -type f -empty \
    ! -path "./.git/*" \
    ! -name ".git" \
    -exec du -h {} \; | awk '{print "EMPTY: "$2" (size: "$1")"}'

echo "\n== Checking for duplicate files in root and lib/ =="
for f in *; do
  if [[ -f "$f" && -f "lib/$f" ]]; then
    echo "DUPLICATE: ./$f and ./lib/$f (sizes: $(du -h "$f" | cut -f1), $(du -h "lib/$f" | cut -f1))"
  fi
done

echo "\n== Checking for files outside standard project structure =="
STANDARD_DIRS="src lib test docs .github"
EXCEPTIONS="README.md .gitignore cleanup_detector.sh"
find . -maxdepth 1 -type f | while read fp; do
  base=$(basename "$fp")
  skip=0
  for exc in $EXCEPTIONS; do
    [[ "$base" == "$exc" ]] && skip=1
  done
  [[ $skip -eq 1 ]] && continue
  echo "OUTSIDE STRUCTURE: $fp (size: $(du -h "$fp" | cut -f1))"
done

echo "\nDone."

#!/usr/bin/env bash
set -euo pipefail

# Fetch the latest OpenAPI JSON from the live documentation site
# and replace the local copy used by mobile clients & CI.
#
# Run this before pushing any backend changes that update the API
# or whenever the docs at https://shamelagpt.com/docs change.
# The GitHub CI workflow `openapi-contract-drift.yml` already
depends on `docs/api/openapi_latest.json`.

REMOTE_URL="https://shamelagpt.com/openapi.json"
DEST="docs/api/openapi_latest.json"

printf "Downloading spec from %s\n" "$REMOTE_URL"
if curl -sSL "$REMOTE_URL" -o "$DEST.tmp"; then
    if [[ -s "$DEST.tmp" ]]; then
        mv "$DEST.tmp" "$DEST"
        printf "Replaced %s with the new spec\n" "$DEST"
    else
        printf "error: downloaded file is empty\n" >&2
        rm -f "$DEST.tmp"
        exit 1
    fi
else
    printf "error: failed to fetch spec\n" >&2
    exit 1
fi

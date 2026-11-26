#!/usr/bin/env bash
# Writes data/snapshot.json: the fallback the site renders when the live GitHub API is unreachable.
# Needs the gh CLI (authenticated locally, or GH_TOKEN in GitHub Actions).
set -euo pipefail
ORG=AutoGeoAI4Sci
cd "$(dirname "$0")/.."
repos=$(gh api "orgs/$ORG/repos?per_page=100&type=public" --paginate \
  --jq '[.[] | {name, description, html_url, homepage, fork, archived, stargazers_count, language, pushed_at, topics}]' | jq -s 'add')
org=$(gh api "orgs/$ORG" --jq '{public_repos, followers}')
members=$(gh api "orgs/$ORG/public_members" --jq '[.[] | {login, avatar_url, html_url}]')
jq -n --argjson repos "$repos" --argjson org "$org" --argjson members "$members" \
  '{generated: (now | todate), org: $org, members: $members, repos: $repos}' > data/snapshot.json
echo "wrote data/snapshot.json ($(jq '.repos | length' data/snapshot.json) repos)"

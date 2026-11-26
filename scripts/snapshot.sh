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
# Awesome-list entries per "## " section, counted with the same rules as renderAwesome() in index.html
awesome=$(gh api "repos/$ORG/awesome-autonomous-geoai/readme" --jq .content | base64 -d | python3 -c '
import json, re, sys
secs, cur = [], None
for line in sys.stdin.read().split("\n"):
    m = re.match(r"^##\s+(.+?)\s*$", line)
    if m:
        t = re.sub(r"<[^>]+>", "", re.sub(r"[*_`]", "", m.group(1))).strip()
        cur = None if re.match(r"^(contents|table of contents|contributing|license)$", t, re.I) else {"title": t, "n": 0}
        if cur: secs.append(cur)
        continue
    if cur and (re.match(r"^\s*[-*+]\s+\S", line) or (line.startswith("|") and not re.match(r"^\|[\s:|-]+\|?\s*$", line))):
        cur["n"] += 1
print(json.dumps([s for s in secs if s["n"]]))')
jq -n --argjson repos "$repos" --argjson org "$org" --argjson members "$members" --argjson awesome "$awesome" \
  '{generated: (now | todate), org: $org, members: $members, awesome: $awesome, repos: $repos}' > data/snapshot.json
echo "wrote data/snapshot.json ($(jq '.repos | length' data/snapshot.json) repos, $(jq '[.awesome[].n] | add' data/snapshot.json) awesome entries)"

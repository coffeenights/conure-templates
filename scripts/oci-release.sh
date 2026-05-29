#!/usr/bin/env bash
# Build & push OCI packages for this repo's components.
#
# Helm vs Timoni is auto-detected from the target folder:
#   - contains Chart.yaml  -> Helm chart  (helm package + helm push)
#   - contains cue.mod/    -> Timoni module (timoni mod push)
#
# The source of truth for a component's version is a `VERSION` file inside
# its folder. `push`/`bump` rewrite it; for Helm, Chart.yaml is kept in sync.
#
# Usage:
#   scripts/oci-release.sh version <dir>
#   scripts/oci-release.sh bump    <dir>
#   scripts/oci-release.sh push    <dir>
#
# Env knobs (all optional):
#   BUMP=patch|minor|major   bump this part before pushing (push only bumps
#                            when BUMP or VERSION is set; `bump` defaults to patch)
#   VERSION=x.y.z            pin an exact version instead of bumping
#   DRY_RUN=1                print actions, change/push nothing
#   FORCE=1                  bypass safety checks (downgrade, big major jump)
#   REGISTRY=...             OCI base (default ghcr.io/coffeenights/conure-templates)
set -euo pipefail

REGISTRY="${REGISTRY:-ghcr.io/coffeenights/conure-templates}"
TIMONI_BASE="${TIMONI_BASE:-oci://${REGISTRY}/components}"
HELM_BASE="${HELM_BASE:-oci://${REGISTRY}/helm/components}"
BUMP="${BUMP:-}"
VERSION="${VERSION:-}"
DRY_RUN="${DRY_RUN:-}"
FORCE="${FORCE:-}"

die() { echo "ERROR: $*" >&2; exit 1; }

require_dir() {
  [ -n "${1:-}" ] || die "directory argument is required, e.g. $0 push timoni/components/webservice"
  [ -d "$1" ] || die "directory '$1' does not exist"
}

current_version() {
  local d="$1"
  if [ -f "$d/VERSION" ]; then
    tr -d ' \t\n\r' < "$d/VERSION"; echo
  elif [ -f "$d/Chart.yaml" ]; then
    awk '/^version:/ {gsub(/"/,"",$2); print $2; exit}' "$d/Chart.yaml"
  else
    echo "0.1.0"
  fi
}

# strict semver check (no pre-release / build metadata for this repo's tooling)
is_semver() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# guard against silent corruption from stray env vars and typos.
# - rejects new < cur (downgrade)
# - rejects new.major > cur.major + 1 (huge jump, usually a stray VERSION=...)
# bypass with FORCE=1.
sanity_check_version() {
  local cur="$1" new="$2"
  [ -n "$FORCE" ] && return 0
  local cma cmi cpa nma nmi npa
  IFS='.' read -r cma cmi cpa <<< "$cur"
  IFS='.' read -r nma nmi npa <<< "$new"
  # downgrade?
  if [ "$nma" -lt "$cma" ] \
     || { [ "$nma" -eq "$cma" ] && [ "$nmi" -lt "$cmi" ]; } \
     || { [ "$nma" -eq "$cma" ] && [ "$nmi" -eq "$cmi" ] && [ "$npa" -lt "$cpa" ]; }; then
    die "refusing to downgrade $cur -> $new (set FORCE=1 to override)"
  fi
  # big major jump?
  if [ $((nma - cma)) -gt 1 ]; then
    die "refusing huge major jump $cur -> $new (set FORCE=1 to override; check for a stray VERSION=... in your env)"
  fi
}

# echoes the next version (does not write anything)
next_version() {
  local cur="$1"
  if [ -n "$VERSION" ]; then
    local v="${VERSION#v}"
    is_semver "$v" || die "VERSION must be x.y.z (got '$VERSION')"
    echo "$v"
    return
  fi
  local ma mi pa
  IFS='.' read -r ma mi pa <<< "$cur"
  ma="${ma:-0}"; mi="${mi:-0}"; pa="${pa:-0}"
  case "${BUMP:-patch}" in
    major) ma=$((ma + 1)); mi=0; pa=0 ;;
    minor) mi=$((mi + 1)); pa=0 ;;
    patch) pa=$((pa + 1)) ;;
    *) die "BUMP must be patch|minor|major (got '$BUMP')" ;;
  esac
  echo "${ma}.${mi}.${pa}"
}

do_bump() {
  local d="$1" cur new mode past pres
  cur="$(current_version "$d")"
  is_semver "$cur" || die "current $d/VERSION '$cur' is not semver x.y.z"
  new="$(next_version "$cur")"
  sanity_check_version "$cur" "$new"
  if [ -n "$VERSION" ]; then
    mode="pinned"; past="pinned"; pres="pin"
  else
    mode="${BUMP:-patch} bump"; past="bumped"; pres="bump"
  fi
  if [ -n "$DRY_RUN" ]; then
    echo "[dry-run] would $pres $d/VERSION: $cur -> $new ($mode)"
  else
    echo "$new" > "$d/VERSION"
    echo "$past $d/VERSION: $cur -> $new ($mode)"
  fi
  echo "$new" > /tmp/.oci-release-version
}

do_push() {
  local d="${1%/}" new
  # Only change the version when explicitly asked (BUMP or VERSION set).
  # Otherwise push the current VERSION as-is.
  if [ -n "$BUMP" ] || [ -n "$VERSION" ]; then
    do_bump "$d"
    new="$(cat /tmp/.oci-release-version)"
  else
    new="$(current_version "$d")"
    echo "using current version $d/VERSION: $new (set BUMP or VERSION to change it)"
  fi

  if [ -f "$d/Chart.yaml" ]; then
    echo ">> Helm chart in $d -> $HELM_BASE (v$new)"
    if [ -n "$DRY_RUN" ]; then
      echo "[dry-run] helm package $d --version $new --app-version $new"
      echo "[dry-run] helm push <pkg>.tgz $HELM_BASE"
      return
    fi
    command -v helm >/dev/null || die "helm not found in PATH"
    # keep Chart.yaml in sync with the VERSION file
    perl -0pi -e "s/^version:.*/version: $new/m; s/^appVersion:.*/appVersion: \"$new\"/m" "$d/Chart.yaml"
    local tmp pkg chart
    tmp="$(mktemp -d)"
    helm package "$d" --version "$new" --app-version "$new" --destination "$tmp"
    pkg="$(ls "$tmp"/*.tgz)"
    helm push "$pkg" "$HELM_BASE"
    rm -rf "$tmp"
    chart="$(awk '/^name:/ {print $2; exit}' "$d/Chart.yaml")"
    echo ">> pushed $HELM_BASE/$chart:$new"

  elif [ -d "$d/cue.mod" ]; then
    local name target
    name="$(basename "$d")"
    target="$TIMONI_BASE/$name"
    echo ">> Timoni module in $d -> $target (v$new)"
    if [ -n "$DRY_RUN" ]; then
      echo "[dry-run] (cd $d && timoni mod push ./ $target --version $new)"
      return
    fi
    command -v timoni >/dev/null || die "timoni not found in PATH"
    ( cd "$d" && timoni mod push ./ "$target" --version "$new" )
    echo ">> pushed $target:$new"

  else
    die "'$d' is neither a Helm chart (Chart.yaml) nor a Timoni module (cue.mod/)"
  fi
}

cmd="${1:-}"
dir="${2:-}"
case "$cmd" in
  version) require_dir "$dir"; current_version "$dir" ;;
  bump)    require_dir "$dir"; do_bump "$dir" ;;
  push)    require_dir "$dir"; do_push "$dir" ;;
  *) die "usage: $0 {version|bump|push} <dir>" ;;
esac

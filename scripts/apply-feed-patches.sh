#!/bin/sh
set -eu

die() {
	printf '%s\n' "apply-feed-patches: $*" >&2
	exit 1
}

[ "$#" -le 1 ] || die "usage: $0 [luci-feed-directory]"
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
patch_dir="$repo_root/patches/feeds/luci"
feed_dir=${1:-"$repo_root/feeds/luci"}
[ -d "$feed_dir" ] || die "LuCI feed is missing; run ./scripts/feeds update -a first"
feed_dir=$(CDPATH= cd -- "$feed_dir" && pwd -P)
feed_root=$(git -C "$feed_dir" rev-parse --show-toplevel 2>/dev/null) || die "LuCI feed is not a Git checkout"
[ "$feed_root" = "$feed_dir" ] || die "expected a separate Git checkout at $feed_dir"
feed_head=$(git -C "$feed_dir" rev-parse HEAD)

set -- "$patch_dir"/*.patch
[ -f "$1" ] || die "no LuCI patches found in $patch_dir"
if git -C "$feed_dir" apply --check --whitespace=error-all "$@" 2>/dev/null; then
	git -C "$feed_dir" apply --whitespace=error-all "$@"
	printf '%s\n' "LuCI patches applied at $feed_head"
elif git -C "$feed_dir" apply --reverse --check --whitespace=error-all "$@" 2>/dev/null; then
	printf '%s\n' "LuCI patches are already applied at $feed_head"
else
	git -C "$feed_dir" apply --check --whitespace=error-all "$@" >&2 || :
	die "patches conflict or are only partly applied; inspect the feed changes (nothing was reset or discarded)"
fi

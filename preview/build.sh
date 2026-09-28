#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
stage_dir="$(mktemp -d "$root_dir/preview/.build.XXXXXXXX")"
trap 'rm -rf "$stage_dir"' EXIT

mkdir -p "$stage_dir/KayliiHelper/Media" "$stage_dir/KayliiSurvivalHelper/Media"
cp "$root_dir/KayliiHelper.toc" "$root_dir/Hub.lua" \
   "$root_dir/MinimapButton.lua" "$stage_dir/KayliiHelper/"
cp "$root_dir"/Media/KayliiIcon.* "$stage_dir/KayliiHelper/Media/"
cp "$root_dir/preview/KayliiSurvivalHelper"/{KayliiSurvivalHelper.toc,Bootstrap.lua,SurvivalHelper.lua,Options.lua} \
   "$stage_dir/KayliiSurvivalHelper/"
cp "$root_dir"/Media/KayliiIcon.* "$stage_dir/KayliiSurvivalHelper/Media/"
cp -a "$root_dir/Media/SurvivalSounds" "$stage_dir/KayliiSurvivalHelper/Media/"

output_path="${1:-$root_dir/KayliiHelper-2.0-alpha-preview.zip}"
rm -f "$output_path"
(cd "$stage_dir" && zip -q -r "$output_path" KayliiHelper KayliiSurvivalHelper)
echo "$output_path"

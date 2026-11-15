#!/usr/bin/env bash
# 用法:
#   bash ghdl.sh <owner/repo 或 GitHub链接> [分支名] [输出目录]
# 例:
#   bash ghdl.sh torvalds/linux            # 下载默认分支 zip
#   bash ghdl.sh https://github.com/xxx/yyy main
#   bash ghdl.sh xxx/yyy main/clone        # 第2参数写 clone 则用 git clone --depth 1

set -u

MIRRORS=(
  "https://gh-proxy.com/"
  "https://ghfast.top/"
  "https://ghproxy.net/"
)

input="${1:-}"
branch_or_mode="${2:-}"
outdir="${3:-}"

if [ -z "$input" ]; then
  echo "用法: bash ghdl.sh <owner/repo 或 GitHub链接> [分支名|clone] [输出目录]"
  exit 1
fi

# 归一化成 owner/repo
repo="$input"
repo="${repo#https://github.com/}"
repo="${repo#http://github.com/}"
repo="${repo#github.com/}"
repo="${repo%%/tree/*}"
repo="${repo%%/blob/*}"
repo="${repo%.git}"
repo="${repo%/}"
repo="$(echo "$repo" | cut -d/ -f1-2)"

if ! echo "$repo" | grep -qE '^[^/]+/[^/]+$'; then
  echo "无法识别的仓库: $input （应形如 owner/repo）"
  exit 1
fi

mode="zip"
if [ "$branch_or_mode" = "clone" ]; then
  mode="clone"
fi
outdir="${outdir:-./$(basename "$repo")}"

echo "仓库: $repo"
echo "模式: $mode"

try_mirror() {
  local base="$1"
  if [ "$mode" = "clone" ]; then
    rm -rf "$outdir"
    git clone --depth 1 -q "${base}https://github.com/${repo}.git" "$outdir"
  else
    local url branch tmp
    if [ -n "$branch_or_mode" ] && [ "$branch_or_mode" != "clone" ]; then
      branch="$branch_or_mode"
    else
      # 探测默认分支
      branch=$(curl -s -m 15 "${base}https://api.github.com/repos/${repo}" \
        | sed -n 's/.*"default_branch": *"\([^"]*\)".*/\1/p')
      [ -z "$branch" ] && branch="main"
    fi
    tmp="$(mktemp -d)/${repo##*/}.zip"
    url="${base}https://github.com/${repo}/archive/refs/heads/${branch}.zip"
    echo "  下载: $url"
    if curl -fL -m 300 --retry 2 -o "$tmp" "$url"; then
      mkdir -p "$(dirname "$outdir")"
      rm -rf "$outdir"
      mkdir -p "$outdir"
      unzip -q "$tmp" -d "$outdir" 2>/dev/null || { command -v 7z >/dev/null && 7z x -y -o"$outdir" "$tmp" >/dev/null; }
      # zip 内通常有一层 owner-repo-branch 目录，拍平
      local inner
      inner="$(ls -d "$outdir"/*/ 2>/dev/null | head -1)"
      if [ -n "$inner" ] && [ "$(ls -A "$outdir" | wc -l)" -eq 1 ]; then
        mv "$inner"* "$inner".* "$outdir"/ 2>/dev/null
        rmdir "$inner" 2>/dev/null
      fi
    else
      return 1
    fi
  fi
}

ok=0
for m in "${MIRRORS[@]}"; do
  echo "尝试镜像: $m"
  if try_mirror "$m"; then ok=1; break; fi
  echo "  失败，换下一个…"
done

if [ "$ok" = "1" ]; then
  echo "完成 -> $outdir"
  ls "$outdir" | head -20
else
  echo "全部镜像失败。可尝试配置代理后直连 GitHub。"
  exit 1
fi

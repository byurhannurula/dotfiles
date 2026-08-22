#!/bin/sh
# Claude Code status line — two-line layout
# Line 1: model (ctx window) (effort) | path git:(branch*)  | worktree | session time
# Line 2: context: [bar] xx% | usage (5h): [bar] xx% (reset in Xm) | usage (7d): [bar] xx% (reset in Xh)

input=$(cat)

cwd=$(echo "$input"        | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input"      | jq -r '.model.display_name // ""')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
effort=$(echo "$input"     | jq -r '.effortLevel // empty')
# Fallback: read effortLevel from settings.json files (project → user)
if [ -z "$effort" ]; then
  for f in "$cwd/.claude/settings.local.json" "$cwd/.claude/settings.json" "$HOME/.claude/settings.json"; do
    if [ -f "$f" ]; then
      val=$(jq -r '.effortLevel // empty' "$f" 2>/dev/null)
      if [ -n "$val" ]; then
        effort="$val"
        break
      fi
    fi
  done
fi
used_pct=$(echo "$input"   | jq -r '.context_window.used_percentage // empty')
five_h=$(echo "$input"     | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_d=$(echo "$input"    | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
worktree=$(echo "$input"   | jq -r '.worktree.name // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')

# Shorten home directory to ~
home="$HOME"
short_dir="${cwd/#$home/~}"

# Git branch + dirty flag (skip optional locks)
git_label=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    dirty=""
    if ! git -C "$cwd" -c core.hooksPath=/dev/null diff --quiet HEAD 2>/dev/null; then
      dirty="*"
    fi
    git_label=" git:(${branch}${dirty})"
  fi
fi

# Context window label: 1m / 200k / Xk
ctx_label=""
if [ "$context_size" -ge 900000 ] 2>/dev/null; then
  ctx_label="1m"
elif [ "$context_size" -ge 150000 ] 2>/dev/null; then
  ctx_label="200k"
elif [ "$context_size" -gt 0 ] 2>/dev/null; then
  ctx_label="$(( context_size / 1000 ))k"
fi

# Session elapsed time — derived from transcript file mtime as proxy for start
session_time=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  # mtime of the transcript as session start approximation
  start_epoch=$(stat -f "%B" "$transcript" 2>/dev/null || stat -c "%W" "$transcript" 2>/dev/null)
  if [ -z "$start_epoch" ] || [ "$start_epoch" = "0" ]; then
    start_epoch=$(stat -f "%m" "$transcript" 2>/dev/null || stat -c "%Y" "$transcript" 2>/dev/null)
  fi
  if [ -n "$start_epoch" ]; then
    now_epoch=$(date +%s)
    elapsed=$(( now_epoch - start_epoch ))
    if [ "$elapsed" -ge 0 ]; then
      mins=$(( elapsed / 60 ))
      hrs=$(( mins / 60 ))
      mins=$(( mins % 60 ))
      if [ "$hrs" -gt 0 ]; then
        session_time="$(printf '%dh %02dm' "$hrs" "$mins")"
      else
        session_time="$(printf '%dm' "$mins")"
      fi
    fi
  fi
fi

# Build a colored progress bar: 10 blocks, colored by the ANSI code passed in
make_bar() {
  pct="$1"
  color="$2"   # ANSI color code for filled blocks (e.g. 32 for green)
  total=10
  filled=$(echo "$pct $total" | awk '{f=int($1*$2/100+0.5); if(f>'"$total"') f='"$total"'; print f}')
  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do
    bar="${bar}█"
    i=$(( i + 1 ))
  done
  fill_part="$bar"
  empty_part=""
  while [ "$i" -lt "$total" ]; do
    empty_part="${empty_part}░"
    i=$(( i + 1 ))
  done
  printf '\033[%sm%s\033[2m%s\033[0m' "$color" "$fill_part" "$empty_part"
}

# Human-readable time until reset
reset_in() {
  reset_epoch="$1"
  now_epoch=$(date +%s)
  diff=$(( reset_epoch - now_epoch ))
  if [ "$diff" -le 0 ]; then
    printf 'now'
    return
  fi
  hrs=$(( diff / 3600 ))
  mins=$(( (diff % 3600) / 60 ))
  if [ "$hrs" -gt 0 ]; then
    printf '%dh %02dm' "$hrs" "$mins"
  else
    printf '%dm' "$mins"
  fi
}

# ── LINE 1 ────────────────────────────────────────────────────────────────────
# model (ctx window) (effort) | path git:(branch*)  | worktree | session time

line1=""

# model + context size + effort
model_label="$model"
if [ -n "$ctx_label" ]; then
  model_label="${model} (${ctx_label})"
fi
if [ -n "$effort" ]; then
  model_label="${model_label} (${effort})"
fi
line1="$model_label"

# path + git
line1="${line1} | ${short_dir}${git_label}"

# worktree
if [ -n "$worktree" ]; then
  line1="${line1}  | worktree: ${worktree}"
fi

# session time (right section)
right1=""
if [ -n "$session_time" ]; then
  right1="⏱ ${session_time}"
fi
if [ -n "$right1" ]; then
  line1="${line1}   ${right1}"
fi

# ── LINE 2 ────────────────────────────────────────────────────────────────────
# context: [bar] xx% | usage (5h): [bar] xx% (reset in Xm) | usage (7d): ...

# Pick bar color based on percentage: green < 60, yellow < 85, red otherwise
pct_color() {
  awk -v p="$1" -v base="$2" 'BEGIN{
    if (p+0 >= 85) print "31";       # red
    else if (p+0 >= 60) print "33";  # yellow
    else print base;                 # base color when healthy
  }'
}

line2=""

# context bar — cyan when healthy
if [ -n "$used_pct" ]; then
  c=$(pct_color "$used_pct" 36)
  bar=$(make_bar "$used_pct" "$c")
  line2="$(printf '\033[2mcontext:\033[0m %s \033[0m%s%%' "$bar" "$(printf '%.0f' "$used_pct")")"
fi

# 5h rate limit — magenta when healthy
if [ -n "$five_h" ]; then
  c=$(pct_color "$five_h" 35)
  bar=$(make_bar "$five_h" "$c")
  pct_str="$(printf '%.0f' "$five_h")%"
  reset_str=""
  if [ -n "$five_h_reset" ]; then
    reset_str=" ($(reset_in "$five_h_reset"))"
  fi
  seg="$(printf '\033[2musage (5h):\033[0m %s \033[0m%s%s' "$bar" "$pct_str" "$reset_str")"
  if [ -n "$line2" ]; then
    line2="${line2}$(printf ' \033[2m|\033[0m ')${seg}"
  else
    line2="$seg"
  fi
fi

# 7d rate limit — green when healthy
if [ -n "$seven_d" ]; then
  c=$(pct_color "$seven_d" 32)
  bar=$(make_bar "$seven_d" "$c")
  pct_str="$(printf '%.0f' "$seven_d")%"
  reset_str=""
  if [ -n "$seven_d_reset" ]; then
    reset_str=" ($(reset_in "$seven_d_reset"))"
  fi
  seg="$(printf '\033[2musage (7d):\033[0m %s \033[0m%s%s' "$bar" "$pct_str" "$reset_str")"
  if [ -n "$line2" ]; then
    line2="${line2}$(printf ' \033[2m|\033[0m ')${seg}"
  else
    line2="$seg"
  fi
fi

# ── OUTPUT ────────────────────────────────────────────────────────────────────
# Line 1: cyan model | blue path + green git | yellow worktree | right section
sep=$(printf ' \033[2m|\033[0m ')

printf "\033[36m%s\033[0m%s\033[34m%s\033[0m\033[32m%s\033[0m" \
  "${model_label}" \
  "$sep" \
  "${short_dir}" \
  "$git_label"

if [ -n "$worktree" ]; then
  printf "%s\033[33mworktree: %s\033[0m" "$sep" "$worktree"
fi

if [ -n "$right1" ]; then
  printf "%s%s" "$sep" "$right1"
fi

if [ -n "$line2" ]; then
  printf "\n%s" "$line2"
fi

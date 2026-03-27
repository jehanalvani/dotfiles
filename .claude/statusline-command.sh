#!/usr/bin/env bash
input=$(cat)

# Model: shorten to e.g. "Sonnet4.6" from "claude-sonnet-4-6" or "Claude 3.5 Sonnet"
model_id=$(echo "$input" | jq -r '.model.id // empty')
if [ -n "$model_id" ]; then
  # Detect extended thinking variant (e.g. "claude-sonnet-4-6-20251031:thinking")
  if echo "$model_id" | grep -q ':thinking'; then
    thinking_suffix="+"
  else
    thinking_suffix=""
  fi
  # Strip leading "claude-", any date suffix like "-20251031", and ":thinking" tag
  # Then capitalise the model family name and join version digits with a dot
  # e.g. "claude-sonnet-4-6-20251031:thinking" → "Sonnet4.6+"
  model_short=$(echo "$model_id" \
    | sed -E \
        -e 's/:thinking$//' \
        -e 's/^claude-//' \
        -e 's/-[0-9]{8}$//' \
        -e 's/-([0-9]+)-([0-9]+)$/|\1.\2/' \
    | awk -F'|' '{
        name=$1; ver=$2;
        # Capitalise first letter of name, drop remaining hyphens
        n=toupper(substr(name,1,1)) substr(name,2);
        gsub(/-/,"",n);
        printf "%s%s", n, ver
      }')
  model_short="${model_short}${thinking_suffix}"
else
  model_short=$(echo "$input" | jq -r '.model.display_name // empty' | sed -E \
    -e 's/Claude //' \
    -e 's/ //')
fi

# Context usage percentage
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  used_fmt=$(printf '%.0f' "$used")
  if [ "$used_fmt" -ge 80 ]; then
    # Orangered — 256-color 202 (~#FF4500)
    ctx_str=$(printf '\033[38;5;202m%s%%\033[0m' "$used_fmt")
  elif [ "$used_fmt" -ge 65 ]; then
    # Saturated burnt orange — 256-color 208 (~#FF8700), distinct from Claude's pale spinner
    ctx_str=$(printf '\033[38;5;208m%s%%\033[0m' "$used_fmt")
  else
    ctx_str="${used_fmt}%"
  fi
else
  ctx_str=""
fi

# Git branch from cwd
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# Working directory basename
dir_name=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty' | xargs basename 2>/dev/null)

# Assemble
parts="$model_short"
[ -n "$ctx_str" ] && parts="$parts $ctx_str"
[ -n "$branch" ] && parts="$parts ⎇ $branch"
[ -n "$dir_name" ] && parts="$parts $dir_name"

printf '%s' "$parts"

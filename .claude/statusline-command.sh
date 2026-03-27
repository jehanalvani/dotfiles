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

# Account/org: match cwd against ~/.claude/api-accounts.json dirs
# Shows workspace if set, falls back to name (e.g. "personal", "work")
account_str=""
accounts_file="$HOME/.claude/api-accounts.json"
if [ -f "$accounts_file" ] && [ -n "$cwd" ]; then
  account_label=$(jq -r --arg cwd "$cwd" '
    .accounts[]
    | select(.dirs[] as $d | $cwd | startswith($d))
    | if .workspace != "" then .workspace else .name end
  ' "$accounts_file" 2>/dev/null | head -1)
  if [ -n "$account_label" ]; then
    # Account color lookup — default no-op, overridden by ~/.claude/statusline-colors.sh
    # Define _account_color() there to return a 256-color code for a given label.
    _account_color() { echo ""; }
    [[ -f "$HOME/.claude/statusline-colors.sh" ]] && source "$HOME/.claude/statusline-colors.sh"
    color=$(_account_color "$(tr '[:upper:]' '[:lower:]' <<< "$account_label")")
    if [ -n "$color" ]; then
      account_str=$(printf '\033[38;5;%sm%s\033[0m' "$color" "$account_label")
    else
      account_str="$account_label"
    fi
  fi
fi

# Session cost
cost_str=""
cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost_raw" ]; then
  cost_str=$(printf '$%.2f' "$cost_raw")
fi

# Assemble: model ctx% account ⎇ branch dir $cost
parts="$model_short"
[ -n "$ctx_str" ] && parts="$parts $ctx_str"
[ -n "$account_str" ] && parts="$parts $account_str"
[ -n "$branch" ] && parts="$parts ⎇ $branch"
[ -n "$dir_name" ] && parts="$parts $dir_name"
[ -n "$cost_str" ] && parts="$parts $cost_str"

printf '%s' "$parts"

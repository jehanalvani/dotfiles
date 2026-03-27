#!/bin/bash
# Claude Code credential helper
# Reads ~/.claude/api-accounts.json and returns the API key for the current directory.
# Key values may be raw strings or 1Password secret references (op://...).
# If no account matches, exits 1 to fall back to Claude Pro OAuth.
#
# Per-project override: add .claude/auth-keys.json to any project directory:
#   { "key": "op://Vault/Item/credential", "op_account": "account.1password.com" }
#
# Usage:
#   credential-helper.sh          — return key for current directory (used by Claude Code)
#   credential-helper.sh --test   — resolve and validate the key against the Anthropic API

CONFIG="$HOME/.claude/api-accounts.json"
CWD=$(pwd)
LOCAL_CONFIG="$CWD/.claude/auth-keys.json"

MATCH=$(python3 - <<EOF
import json, sys, os

cwd = "$CWD"
local_config = "$LOCAL_CONFIG"

# Check for local .claude/auth-keys.json first
if os.path.exists(local_config):
    with open(local_config) as f:
        local = json.load(f)
    key = local.get("key", "")
    if not key:
        sys.exit(1)
    print(key)
    print(local.get("op_account", ""))
    sys.exit(0)

# Fall back to global api-accounts.json
config_path = os.path.expanduser("$CONFIG")
with open(config_path) as f:
    config = json.load(f)

for account in config["accounts"]:
    for d in account["dirs"]:
        if cwd == d or cwd.startswith(d + "/"):
            key = account.get("key", "")
            if not key:
                sys.exit(1)
            print(key)
            print(account.get("op_account", ""))
            sys.exit(0)

sys.exit(1)
EOF
)

[ $? -ne 0 ] && exit 1

KEY=$(echo "$MATCH" | sed -n '1p')
OP_ACCOUNT=$(echo "$MATCH" | sed -n '2p')

# Resolve 1Password secret references
if [[ "$KEY" == op://* ]]; then
  if [[ -n "$OP_ACCOUNT" ]]; then
    RESOLVED=$(op read --account "$OP_ACCOUNT" "$KEY")
  else
    RESOLVED=$(op read "$KEY")
  fi
else
  RESOLVED="$KEY"
fi

if [[ "$1" == "--test" ]]; then
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "x-api-key: $RESOLVED" \
    -H "anthropic-version: 2023-06-01" \
    https://api.anthropic.com/v1/models)
  if [[ "$RESPONSE" == "200" ]]; then
    echo "OK (HTTP 200)"
  else
    echo "FAILED (HTTP $RESPONSE)"
    exit 1
  fi
else
  echo "$RESOLVED"
fi

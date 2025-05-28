#!/bin/bash

# VALIDATE TOKEN: verify one and only one token is set

# Count how many of the four variables are set (non-empty)
echo "===> CHECK GIT TOKENS..."
count=0

[[ -n "$GITHUB_TOKEN" ]] && ((count++))
[[ -n "$GITLAB_TOKEN" ]] && ((count++))
[[ -n "$BITBUCKET_TOKEN" ]] && ((count++))
[[ -n "$GIT_CREDENTIALS" ]] && ((count++))

# Exit if more than one is set
if [ "$count" -gt 1 ]; then
  echo "Error: More than one Git credential variable is set."
  echo "Only one of GITHUB_TOKEN, GITLAB_TOKEN, BITBUCKET_TOKEN, or GIT_CREDENTIALS may be set."
  exit 1
elif [ "$count" -eq 0 ]; then
  echo "Error: No Git credential variables were set."
  echo "One of GITHUB_TOKEN, GITLAB_TOKEN, BITBUCKET_TOKEN, or GIT_CREDENTIALS must be set."
#   exit 1
fi

# Optional: Success message
echo "Validation passed. Only one (or none) of the credential variables is set."

# https://$USERNAME:$TOKEN@git.harness.io/$ACCOUNT_ID/$ORG_ID/first-repo.git

# If HARNESS_TOKEN is set, check HARNESS_USERNAME is also set
if [[ -n "$HARNESS_TOKEN" && -z "$HARNESS_USERNAME" ]]; then
    echo "Error: Harness Code username is not set"
    echo "If HARNESS_TOKEN is set, HARNESS_USERNAME must also be set"
else
    echo "No catch token check"
fi

# ENCODING URL CREDENTIALS
UNENCODED_USERNAME_AND_TOKEN="${HARNESS_USERNAME}:${HARNESS_TOKEN}"
echo "Unencoded username: $UNENCODED_USERNAME_AND_TOKEN"

RAW_CREDENTIALS=$UNENCODED_USERNAME_AND_TOKEN

# URL encode function using jq
urlencode() {
  local raw="$1"
  jq -nr --arg v "$raw" '$v|@uri'
}

RAW_USERNAME=$HARNESS_USERNAME
RAW_TOKEN=$HARNESS_TOKEN
ENCODED_USERNAME=""
ENCODED_TOKEN=""

# Encode and display RAW_USERNAME if set
if [[ -n "$RAW_USERNAME" ]]; then
  echo "Original credentials: $RAW_USERNAME"
  ENCODED_USERNAME=$(urlencode "$RAW_USERNAME")
  echo "URL-encoded credentials: $ENCODED_USERNAME"
else
  echo "No RAW_CREDENTIALS variable set to encode."
fi

# Encode and display RAW_USERNAME if set
if [[ -n "$RAW_TOKEN" ]]; then
  echo "Original credentials: $RAW_TOKEN"
  ENCODED_TOKEN=$(urlencode "$RAW_TOKEN")
  echo "URL-encoded credentials: $ENCODED_TOKEN"
else
  echo "No RAW_CREDENTIALS variable set to encode."
fi

ENCODED_USERNAME_AND_TOKEN="${ENCODED_USERNAME}:${ENCODED_TOKEN}"
echo "Unencoded username: $ENCODED_USERNAME_AND_TOKEN"

echo "Validation passed."
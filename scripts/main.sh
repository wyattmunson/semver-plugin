#!/bin/bash

echo "SEMANTIC RELEASE PLUGIN"
echo 

echo " ▗▄▄▖▗▄▄▄▖▗▖  ▗▖▗▖  ▗▖▗▄▄▄▖▗▄▄▖ "
echo "▐▌   ▐▌   ▐▛▚▞▜▌▐▌  ▐▌▐▌   ▐▌ ▐▌"
echo " ▝▀▚▖▐▛▀▀▘▐▌  ▐▌▐▌  ▐▌▐▛▀▀▘▐▛▀▚▖"
echo "▗▄▄▞▘▐▙▄▄▖▐▌  ▐▌ ▝▚▞▘ ▐▙▄▄▖▐▌ ▐▌"
echo "Read the fine docs: https://github.com/wyattmunson/semver-plugin"

echo "===> PREFLIGHT CHECKS"
echo "Performing preflight checks to validate configuration and variables before invoking semantic-release"

# ==== CONVERT PLUGIN VARIABLE TO ENV VARIABLES ====
# See: https://developer.harness.io/docs/continuous-integration/use-ci/use-drone-plugins/custom_plugins/#variables-in-plugin-scripts
# GITHUB_TOKEN=$PLUGIN_GITHUB_TOKEN
# GITLAB_TOKEN=$PLUGIN_GITLAB_TOKEN
# BITBUCKET_TOKEN=$PLUGIN_BITBUCKET_TOKEN
# GIT_CREDENTIALS=$PLUGIN_GIT_CREDENTIALS
HARNESS_TOKEN=$PLUGIN_HARNESS_TOKEN
HARNESS_USERNAME=$PLUGIN_HARNESS_USERNAME
REPO_DIR=$PLUGIN_REPO_DIR

# OTHER SETUP VARIABLES
ORIGINAL_DIR=$(pwd)

# ==== VALIDATE TOKEN IS SET ====
# Verify one and only one token is set

# Count how many of the four variables are set (non-empty)
echo "===> CHECK GIT TOKENS..."
count=0

[[ -n "$PLUGIN_GITHUB_TOKEN" ]] && ((count++))
[[ -n "$PLUGIN_GITLAB_TOKEN" ]] && ((count++))
[[ -n "$PLUGIN_BITBUCKET_TOKEN" ]] && ((count++))
[[ -n "$PLUGIN_GIT_CREDENTIALS" ]] && ((count++))
[[ -n "$PLUGIN_HARNESS_TOKEN" ]] && ((count++))

# Exit if more than one is set
if [ "$count" -gt 1 ]; then
  echo "==> ERROR: More than one Git credential variable is set. Exiting."
  echo "Only one of GITHUB_TOKEN, GITLAB_TOKEN, BITBUCKET_TOKEN, GIT_CREDENTIALS, or HARNESS_TOKEN may be set."
  # exit 1
elif [ "$count" -eq 0 ]; then
  echo "==> ERROR: No Git credential variables were set. Exiting."
  echo "One of GITHUB_TOKEN, GITLAB_TOKEN, BITBUCKET_TOKEN, GIT_CREDENTIALS, or HARNESS_TOKEN must be set."
  # exit 1
fi

# https://$USERNAME:$TOKEN@git.harness.io/$ACCOUNT_ID/$ORG_ID/first-repo.git

############################
# FORMAT HARNESS VARIABLES #
############################

# TODO: This code should only run when HARNESS_TOKEN is set

# If HARNESS_TOKEN is set, check HARNESS_USERNAME is also set
if [[ -n "$HARNESS_TOKEN" && -z "$HARNESS_USERNAME" ]]; then
    echo "Error: Harness Code username is not set"
    echo "If HARNESS_TOKEN is set, HARNESS_USERNAME must also be set"
else
    echo "No catch token check"
fi

# ENCODING URL CREDENTIALS
# UNENCODED_USERNAME_AND_TOKEN="${HARNESS_USERNAME}:${HARNESS_TOKEN}"
# echo "Unencoded username: $UNENCODED_USERNAME_AND_TOKEN"

# RAW_CREDENTIALS=$UNENCODED_USERNAME_AND_TOKEN

# ==== URL ENCODING FUNCTION ====
urlencode() {
  local raw="$1"
  jq -nr --arg v "$raw" '$v|@uri'
}

RAW_USERNAME=$HARNESS_USERNAME
RAW_TOKEN=$HARNESS_TOKEN
ENCODED_USERNAME=""
ENCODED_TOKEN=""

# Encode RAW_USERNAME if set
# TODO: Remove this valiation check, it already happens above
if [[ -n "$HARNESS_USERNAME" ]]; then
  ENCODED_USERNAME=$(urlencode "$HARNESS_USERNAME")
else
  echo "No RAW_CREDENTIALS variable set to encode."
fi

# Encode and display RAW_USERNAME if set
if [[ -n "$HARNESS_TOKEN" ]]; then
  ENCODED_TOKEN=$(urlencode "$HARNESS_TOKEN")
else
  echo "No RAW_CREDENTIALS variable set to encode."
fi

ENCODED_USERNAME_AND_TOKEN="${ENCODED_USERNAME}:${ENCODED_TOKEN}"
# echo "Unencoded username: $ENCODED_USERNAME_AND_TOKEN"

# SET VARIABLE FOR SEMANTIC-RELEASE
# After formatting Harness credentials, set it to the variable semantic-release is expecting.
export GIT_CREDENTIALS=$ENCODED_USERNAME_AND_TOKEN
echo "Git creds are" $GIT_CREDENTIALS

echo "===> Preflight validation passed."
echo "The current working directory is: $(pwd)"

#########################
# CALL SEMANTIC RELEASE #
#########################

echo "====> INVOKING SEMANTIC-RELEASE..."
# npx semantic-release
DATE_STAMP=$(date +"%Y-%m-%d_%H-%M-%S")
# npx semantic-release
npx semantic-release 2>&1 | tee ${DATE_STAMP}_semver.log

NPX_STATUS=$?

echo "====> END OF semantic-release LOGS"
echo "====> SEMVER-PLUGIN LOGS BELOW:"
echo "=> semantic-release status: $(if [[ "$NPX_STATUS" == "0" ]]; then echo "✅ SUCCESS"; else echo "❌ FAILED"; fi)" 
echo "=> semantic-release exit code: $NPX_STATUS" 
echo "=> original directory: $ORIGINAL_DIR" 
echo "=> changed to directory: $FULL_REPO_DIR" 
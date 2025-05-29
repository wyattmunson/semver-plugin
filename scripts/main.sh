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
DEBUG_MODE=false
DEBUG_SEMREL=false

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

#########################
# SET COMMITTER DETAILS #
#########################

GIT_AUTHOR_NAME="${PLUGIN_GIT_AUTHOR_NAME:-wyatt}"
GIT_AUTHOR_EMAIL="${PLUGIN_GIT_AUTHOR_EMAIL:-wyatt.munson@exmaple.com}"
GIT_COMMITTER_NAME="${PLUGIN_GIT_COMMITTER_NAME:-wyatt}"
GIT_COMMITTER_EMAIL="${PLUGIN_GIT_COMMITTER_EMAIL:-wyatt.munson@example.com}"

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
    echo "Both Harness variables supplied."
fi

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
  echo "ERROR: No HARNESS_USERNAME variable set to encode."
  echo "Supply HARNESS_USERNAME as an environment variable."
fi

# Encode and display RAW_USERNAME if set
if [[ -n "$HARNESS_TOKEN" ]]; then
  ENCODED_TOKEN=$(urlencode "$HARNESS_TOKEN")
else
  echo "ERROR: No HARNESS_TOKEN variable set to encode."
  echo "Supply HARNESS_TOKEN as an environment variable."
fi

ENCODED_USERNAME_AND_TOKEN="${ENCODED_USERNAME}:${ENCODED_TOKEN}"

# SET VARIABLE FOR SEMANTIC-RELEASE
# After formatting Harness credentials, set it to the variable semantic-release is expecting.
export GIT_CREDENTIALS=$ENCODED_USERNAME_AND_TOKEN
# echo "Git creds are" $GIT_CREDENTIALS

echo "===> Preflight validation passed."
echo "The current working directory is: $(pwd)"

#########################
# CALL SEMANTIC RELEASE #
#########################

echo "====> INVOKING SEMANTIC-RELEASE..."
# create timestamp for log file name
DATE_STAMP=$(date +"%Y-%m-%d_%H-%M-%S")
# npx semantic-release
# npx semantic-release 2>&1 | tee ${DATE_STAMP}_semver.log
# npx semantic-release 2>&1 | tee semver.log

# BUILD NPX COMMAND
build_command() {
  local CMD=("npx" "semantic-release")

  # Add semantic-release flags based on plugin input (env vars)
  [ "$DEBUG_SEMREL" = "true" ] && CMD+=("--debug")
  [ "$DRY_RUN" = "true" ] && CMD+=("--dry-run")
  [ "$SKIP_CI" = "true" ] && CMD+=("--no-ci")
  [[ -n "$REPO_URL" ]] && CMD+=("-r $REPO_URL")
  [[ -n "$TAG_FORMAT" ]] && CMD+=("-t $TAG_FORMAT")
  [[ -n "$SEMREL_PLUGINS" ]] && CMD+=("-p $SEMREL_PLUGINS")
  [[ -n "$BRANCHES" ]] && CMD+=("--branches $BRANCHES")
  [[ -n "$EXTENDS" ]] && CMD+=("--extends $EXTENDS")

  echo "${CMD[@]}"
}

# RUN NPX COMMAND
eval "$(build_command)" 2>&1 | tee semver.log

# CAPTURE NPX COMMAND EXIT CODE
NPX_STATUS=$?

echo "====> semantic-release LOGS ABOVE <===="
echo "====> SEMVER-PLUGIN LOGS BELOW:"

NEXT_VERSION=""
EXISTING_VERSION=""
VERSION_STATUS="No changes detected"
NEXT_VERSION="None"

FIRST_RELEASE=false
if grep -q "No previous release found, retrieving all commits" semver.log; then
  FIRST_RELEASE=true
  NEXT_VERSION=$(cat semver.log | grep -oE "the next release version is ([0-9]+\.[0-9]+\.[0-9]+)" | awk '{print $6}')
  EXISTING_VERSION="None"
  VERSION_STATUS="First run (no previous version)"
fi

UPGRADE_RELEASE=false
if grep -q "The next release version is" semver.log; then
  UPGRADE_RELEASE=true
  NEXT_VERSION=$(cat semver.log | grep -oE "The next release version is ([0-9]+\.[0-9]+\.[0-9]+)" | awk '{print $6}')
  EXISTING_VERSION=$(cat semver.log | grep -oE "associated with version [0-9]+\.[0-9]+\.[0-9]+" | awk '{print $4}')
  VERSION_STATUS="Upgraded version"
fi

NO_RELEASE=false
if grep -q "Found 0 commits since last release" semver.log; then
  NO_RELEASE=true
  EXISTING_VERSION=$(cat semver.log | grep -oE "associated with version [0-9]+\.[0-9]+\.[0-9]+" | awk '{print $4}')
  NEXT_VERSION="No version change detected"
  # NEXT_VERSIONv=$(cat semver.log | grep -oE "The next release version is ([0-9]+\.[0-9]+\.[0-9]+)" | awk '{print $6}')
fi

# ==== PRINT SUMMARY VARIABLES ====
echo -e "=> semantic-release: \t$(if [[ "$NPX_STATUS" == "0" ]]; then echo "✅ SUCCESS"; else echo "❌ FAILED"; fi)" 
echo -e "=> exit code: \t\t$NPX_STATUS" 
echo -e "=> Directory: \t\t$ORIGINAL_DIR" 
echo -e "=> Version Status: \t$VERSION_STATUS" 
echo -e "=> Existing Version: \t$EXISTING_VERSION" 
echo -e "=> Next Version: \t$NEXT_VERSION" 

# ==== SAVE VERSION NUMBER IN FILE ====
echo "====> SAVING VERSION AS FILE..."
echo $NEXT_VERSION > .next-version.txt
echo "==> Saved next version as .next-version.txt"

# ENV FILE VARIABLES: to be accessed when the script is called as a Drone/Harness Plugin

echo "====> SETTING DRONE_OUTPUT.env FILE"
DRONE_OUTPUT="DRONE_OUTPUT.env"
echo "ENV_VAR_NAME=somevalue" >> $DRONE_OUTPUT
echo "ORIGINAL_DIR=$ORIGINAL_DIR" >> $DRONE_OUTPUT
echo "VERSION_STATUS=$VERSION_STATUS" >> $DRONE_OUTPUT
echo "EXISTING_VERSION=$EXISTING_VERSION" >> $DRONE_OUTPUT
echo "NEXT_VERSION=$NEXT_VERSION" >> $DRONE_OUTPUT

# EXPORT VARIABLES: to be accessed when the script is called with source
echo "====> SETTING OUTPUT VARIABLES"
export ORIGINAL_DIR=$ORIGINAL_DIR
export VERSION_STATUS=$VERSION_STATUS
export EXISTING_VERSION=$EXISTING_VERSION
export NEXT_VERSION=$NEXT_VERSION

# ECHO EXPORTS: to be accessed when this script is called with eval
echo "export ORIGINAL_DIR=\"$ORIGINAL_DIR\""
echo "export VERSION_STATUS=\"$VERSION_STATUS\""
echo "export EXISTING_VERSION=\"$EXISTING_VERSION\""
echo "export NEXT_VERSION=\"$NEXT_VERSION\""
echo 'export TEST_EVAL_EXPORT="filled"'

echo "====> SCRIPT COMPLETE"
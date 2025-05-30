#!/bin/bash

echo "====> START: SEMANTIC RELEASE PLUGIN"
echo 

echo "+=== SEMANTIC VERSIONING ==========+"
echo "|  ▗▄▄▖▗▄▄▄▖▗▖  ▗▖▗▖  ▗▖▗▄▄▄▖▗▄▄▖  |"
echo "| ▐▌   ▐▌   ▐▛▚▞▜▌▐▌  ▐▌▐▌   ▐▌ ▐▌ |"
echo "|  ▝▀▚▖▐▛▀▀▘▐▌  ▐▌▐▌  ▐▌▐▛▀▀▘▐▛▀▚▖ |"
echo "| ▗▄▄▞▘▐▙▄▄▖▐▌  ▐▌ ▝▚▞▘ ▐▙▄▄▖▐▌ ▐▌ |"
echo "+====================== \/\/\/\ ===+"
echo "Read the fine docs: https://github.com/wyattmunson/semver-plugin"

echo "===> PREFLIGHT CHECKS"
echo "Performing preflight checks to validate configuration and variables before invoking semantic-release"

# ==== CONVERT PLUGIN VARIABLE TO ENV VARIABLES ====
# Harness injects env variables with `PLUGIN_` prefix for plugin steps
# Allow this container to accept variables with or without the prefix
# See: https://developer.harness.io/docs/continuous-integration/use-ci/use-drone-plugins/custom_plugins/#variables-in-plugin-scripts
GITHUB_TOKEN=${PLUGIN_GITHUB_TOKEN:-${GITHUB_TOKEN}}
GITLAB_TOKEN=${PLUGIN_GITLAB_TOKEN:-${GITLAB_TOKEN}}
BITBUCKET_TOKEN=${PLUGIN_BITBUCKET_TOKEN:-${BITBUCKET_TOKEN}}
GIT_CREDENTIALS=${PLUGIN_GIT_CREDENTIALS:-${GIT_CREDENTIALS}}
GIT_AUTHOR_NAME=${PLUGIN_GIT_AUTHOR_NAME:-${GIT_AUTHOR_NAME}}
GIT_AUTHOR_EMAIL=${PLUGIN_GIT_AUTHOR_EMAIL:-${GIT_AUTHOR_EMAIL}}
GIT_COMMITTER_NAME=${PLUGIN_GIT_COMMITTER_NAME:-${GIT_COMMITTER_NAME}}
GIT_COMMITTER_EMAIL=${PLUGIN_GIT_COMMITTER_EMAIL:-${GIT_COMMITTER_EMAIL}}

# SET SCRIPT VARIABLES
# Harness Plugins inject variables with a `PLUGIN_` prefix
# Use the `PLUGIN_` variables if they exist, else fall back on non-prefixed variables
HARNESS_TOKEN=${PLUGIN_HARNESS_TOKEN:-${HARNESS_TOKEN}}
HARNESS_USERNAME=${PLUGIN_HARNESS_USERNAME:-${HARNESS_USERNAME}}
REPO_DIR=${PLUGIN_REPO_DIR:-${REPO_DIR}}

# ====  ==== 
# ==== EXPORT VARIABLES FOR SEMANTIC RELEASE ==== 
export DEBUG_SEMREL=${PLUGIN_DEBUG_SEMREL:-${DEBUG_SEMREL}}
export DRY_RUN=${PLUGIN_DRY_RUN:-${DRY_RUN}}
export SKIP_CI=${PLUGIN_SKIP_CI:-${SKIP_CI}}
export REPO_URL=${PLUGIN_REPO_URL:-${REPO_URL}}
export TAG_FORMAT=${PLUGIN_TAG_FORMAT:-${TAG_FORMAT}}
export SEMREL_PLUGINS=${PLUGIN_SEMREL_PLUGINS:-${SEMREL_PLUGINS}}
export BRANCHES=${PLUGIN_BRANCHES:-${BRANCHES}}
export EXTENDS=${PLUGIN_EXTENDS:-${EXTENDS}}

export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-wyatt}"
export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-wyatt.munson@exmaple.com}"
export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-wyatt}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-wyatt.munson@example.com}"


# OTHER SETUP VARIABLES
# DEBUG_SEMREL=false
ORIGINAL_DIR=$(pwd)
DEBUG_MODE=false

echo "Working directory is:" $(pwd)
# ==== CHANGE DIRECTORY ==== 
if [[ -n "$REPO_DIR" ]]; then
  echo "===> Changing directory to: $REPO_DIR"
  cd $REPO_DIR
  echo "==> Current directory is now:" $(pwd)
fi

# ==== VALIDATE TOKEN IS SET ====
# Verify one and only one token is set

# Count how many of the four token variables are set (non-empty)
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

##########################
# FORMAT GIT CREDENTIALS #
##########################

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

ENCODED_USERNAME=""
ENCODED_TOKEN=""
ENCODED_USERNAME=$(urlencode "$HARNESS_USERNAME")
ENCODED_TOKEN=$(urlencode "$HARNESS_TOKEN")

if [[ "$ENCODED_USERNAME" || -z "$ENCODED_TOKEN" ]]; then
  echo "ERROR: Username or token failed to encode. Exiting."
  echo "Ensure HARNESS_USERNAME and HARNESS_TOKEN are both set to a plaintext value."
  exit 1
fi

# SET VARIABLE FOR SEMANTIC-RELEASE
# After formatting Harness credentials, set it to the variable semantic-release is expecting.
ENCODED_USERNAME_AND_TOKEN="${ENCODED_USERNAME}:${ENCODED_TOKEN}"
export GIT_CREDENTIALS=$ENCODED_USERNAME_AND_TOKEN

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

echo "===> REPO_URL is" $REPO_URL

# BUILD NPX COMMAND
build_command() {
  local CMD=("npx" "semantic-release")

  # Add semantic-release flags based on plugin input (env vars)
  [ "$DEBUG_SEMREL" = "true" ] && CMD+=("--debug")
  [ "$DRY_RUN" = "true" ] && CMD+=("--dry-run")
  [ "$SKIP_CI" = "true" ] && CMD+=("--no-ci")
  # TODO: get these working correctly
  [[ -n "$REPO_URL" ]] && CMD+=("-r" "$REPO_URL")
  [[ -n "$TAG_FORMAT" ]] && CMD+=("-t" "$TAG_FORMAT")
  [[ -n "$SEMREL_PLUGINS" ]] && CMD+=("-p $SEMREL_PLUGINS")
  [[ -n "$BRANCHES" ]] && CMD+=("--branches $BRANCHES")
  [[ -n "$EXTENDS" ]] && CMD+=("--extends $EXTENDS")

  echo "${CMD[@]}"
}

echo "COMMAND IS:" $(build_command)
NPX_COMMAND=$(build_command)

# RUN NPX COMMAND
eval "$(build_command)" 2>&1 | tee semver.log

# CAPTURE NPX COMMAND EXIT CODE
NPX_STATUS=$?

echo "====> semantic-release LOGS ABOVE <===="
echo "====> SEMVER-PLUGIN LOGS BELOW:"

NEXT_VERSION=""
EXISTING_VERSION=""
VERSION_STATUS="No changes detected"
NEXT_VERSION=""

FIRST_RELEASE=false
if grep -q "No previous release found, retrieving all commits" semver.log; then
  FIRST_RELEASE=true
  NEXT_VERSION=$(cat semver.log | grep -oE "the next release version is ([0-9]+\.[0-9]+\.[0-9]+)" | awk '{print $6}')
  EXISTING_VERSION=""
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

echo "====> SETTING OUTPUT: DRONE_OUTPUT.env FILE"
# DRONE_OUTPUT="DRONE_OUTPUT.env"
echo "ORIGINAL_DIR=$ORIGINAL_DIR" >> $DRONE_OUTPUT
echo "VERSION_STATUS=$VERSION_STATUS" >> $DRONE_OUTPUT
echo "EXISTING_VERSION=$EXISTING_VERSION" >> $DRONE_OUTPUT
echo "NEXT_VERSION=$NEXT_VERSION" >> $DRONE_OUTPUT
echo "REPO_DIR=$REPO_DIR" >> $DRONE_OUTPUT
echo "NPX_COMMAND=$NPX_COMMAND" >> $DRONE_OUTPUT

# EXPORT VARIABLES: to be accessed when the script is called with source
echo "====> SETTING OUTPUT: EXPORT VARIABLES"
export ORIGINAL_DIR=$ORIGINAL_DIR
export VERSION_STATUS=$VERSION_STATUS
export EXISTING_VERSION=$EXISTING_VERSION
export NEXT_VERSION=$NEXT_VERSION
export REPO_DIR=$REPO_DIR
export NPX_COMMAND=$NPX_COMMAND

# ECHO EXPORTS: to be accessed when this script is called with eval
echo "====> SETTING OUTPUT: EVAL COMPATIBLE EXPORT VARIABLES"
echo "export ORIGINAL_DIR=\"$ORIGINAL_DIR\""
echo "export VERSION_STATUS=\"$VERSION_STATUS\""
echo "export EXISTING_VERSION=\"$EXISTING_VERSION\""
echo "export NEXT_VERSION=\"$NEXT_VERSION\""
echo "export REPO_DIR=\"$REPO_DIR\""
echo "export NPX_COMMAND=\"$NPX_COMMAND\""

echo "====> SCRIPT COMPLETE"
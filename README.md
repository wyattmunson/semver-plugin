# semver-plugin

semver-plugin is tool to use semantic-release in a Harness pipeline. Semantic versioning in the pipeline.

## About Seamntic Release

This tool uses conventional commits to detect and trigger version changes using semantic versioning (1.2.3).

### Conventional Commits

Semantic release uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) prefixes like `fix:` in commit messages to detect when to bump the version.

```bash
# Update patch versions (x.x.1)
fix: updated alignment issue with profile icon
# Update minor versions (x.1.x)
feat: add new payment provider
# Update major versions (1.x.x)
BREAKING CHANGE: migrating to API version 2
```

## Variables

### Git Tokens

One (and only one) of the following token variables can be set: `GITHUB_TOKEN`, `GITLAB_TOKEN`, `BITBUCKET_TOKEN`, `GIT_CREDENTIALS`, or `HARNESS_TOKEN`. If none of the variables are set or multiple are set, the script will fail and exit.

**Use Secrets**:

Use the expression `<+secrets.getValue("secret_name")>` to reference a secret in Harness.

### Variable List

| Variable              | Use                                             | Notes                                     |
| --------------------- | ----------------------------------------------- | ----------------------------------------- |
| `HARNESS_USERNAME`    | Harness username.                               | Harness user or service account username. |
| `HARNESS_TOKEN`       | Harness PAT or SAT.                             |                                           |
| `GIT_CREDENTIALS`     | Generic git credentials.                        | Use URL encoding                          |
| `GITHUB_TOKEN`        | GitHub PAT credentials.                         |                                           |
| `GITLAB_TOKEN`        | GitLab PAT credentials.                         |                                           |
| `BITBUCKET_TOKEN`     | BitBucket PAT credentials.                      |                                           |
| `GIT_AUTHOR_NAME`     | Author of name associated with git release tag  |                                           |
| `GIT_AUTHOR_EMAIL`    | Author of email associated with git release tag |                                           |
| `GIT_COMMITTER_NAME`  | Committer name associated with git release tag  |                                           |
| `GIT_COMMITTER_EMAIL` | Committer email associated with git release tag |                                           |

### Variable Descriptions

#### `HARNESS_TOKEN`

This is a Harness PAT or SAT Token.

- **SET TO**: Harness PAT or SAT in plaintext. The script will URL encode the values for you.
- If this is provided, no other `_TOKEN` or `GITHUB_CREDENTIALS` variable should be set
- Use when Harness Code is the SCM Provider

#### `HARNESS_USERNAME`

The Harness username for the user or service account.

- **SET TO**: Harness username plaintext. The script will URL encode the values for you.
- If `HARNESS_TOKEN` is used, this variable must be set.
- Use when Harness Code is the SCM Provider

#### `GIT_CREDENTIALS`

Generic git credentials provided in the format `USERNAME:PASSWORD`.

- **SET TO**: a partially URL encoded string (`<url_encoded_username>:<url_encoded_password>`).
  - The username and password should each individually be URL encoded, meaning the `:` separating the two is not URL encoded.
  - The script will **not** make the URL encoding for you.
- If this is provided, no other `_TOKEN` variable should be set

#### `GITHUB_TOKEN`, `GITLAB_TOKEN`, `BITBUCKET_TOKEN`

This is a PAT token for the specific SCM provider.

- **SET TO**: GitHub, GitLab, or BitBucket PAT in plaintext (not URL encoded).
- If this is provided, no other `_TOKEN` or `GITHUB_CREDENTIALS` variable should be set

### Plugin Variables

This plugin is intended to be used as a Harness Plugin step. If it's run in any other step type, or in another build tool (not Harness), modify the environment variables for compatibility.

> **⚠️ ATTENTION** \
> Prefix variables with `PLUGIN_` when **not** using a Harness Plugin step.

If a Harness Plugin step is used, use the variable names as normal.

If a Harness Run step, or another build tool is used, prefix the variable names with `PLUGIN_`. For example the variable `REPO_URL` becomes `PLUGIN_REPO_URL`.

test

| Test \
| Test

## Preflight Check

- Format variables
- Target correct repo

## Harness Pipeline Usage

### As a Plugin Step

Use a Plugin step in Harness to maximize simplicity.

- No commands needed. The logic is baked into the container.
- Does not support output variables. Use as a run step to capture output variables.

```bash
              - step:
                  type: Plugin
                  name: semantic version
                  identifier: semantic_version
                  spec:
                    connectorRef: account.MyDockerConnector
                    image: wyattmunson/semver-plugin:1.0.22
                    settings:
                      HARNESS_TOKEN: <+secrets.getValue("MyTokenValue")>
                      HARNESS_USERNAME: MyUsername@example.com
```

```
<+pipeline.stages.build.spec.execution.steps.sem_ver_run_step.output.outputVariables.NEXT_VERSION>
```

### As a Run Step

Use a Run step in Harness to capture the output variables.

- Prefix environment variables with `PLUGIN_` (e.g., `PLUGIN_HARNESS_TOKEN`).
- Harness overrides the entrypoint, meaning the script must be invoked in the `command` block. Do not modify this command.
- Update your Docker connector git username and password.

```
              - step:
                  type: Run
                  name: run_semver
                  identifier: run_semver
                  spec:
                    connectorRef: account.MY_DOCKER_CONNECTOR
                    image: wyattmunson/semver-plugin:1.0.23
                    shell: Bash
                    command: |-
                      eval "$("/opt/winc/semver/scripts/main.sh" | tee /dev/stderr | grep '^export ')"
                    envVariables:
                      PLUGIN_HARNESS_TOKEN: <+secrets.getValue("MY_PAT")>
                      PLUGIN_HARNESS_USERNAME: "MY_USERNAME"
                    outputVariables:
                      - name: NEXT_VERSION
                        type: String
                        value: NEXT_VERSION
                      - name: VERSION_STATUS
                        type: String
                        value: VERSION_STATUS
                      - name: EXISTING_VERSION
                        type: String
                        value: EXISTING_VERSION
```

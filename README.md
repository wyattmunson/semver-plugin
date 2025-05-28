# semver-plugin

semver-plugin is tool to use semantic-release in a Harness pipeline. Semantic versioning in the pipeline.

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

## Preflight Check

- Format variables
- Target correct repo

## Harness Pipeline Usage

### As a Plugin Step

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

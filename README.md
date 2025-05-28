# semver-plugin

semver-plugin is tool to use semantic-release in a Harness pipeline. Semantic versioning in the pipeline.

## Variables

### Git Tokens

One (and only one) of the following token variables can be set: `GITHUB_TOKEN`, `GITLAB_TOKEN`, `BITBUCKET_TOKEN`, `GIT_CREDENTIALS`, or `HARNESS_TOKEN`. If none of the variables are set or multiple are set, the script will fail and exit.

### Variable List

| Variable           | Use                                     | Notes                                     |
| ------------------ | --------------------------------------- | ----------------------------------------- |
| `REPO_DIR`         | Relative or absolute path to code repo. | Should be set to repo name.               |
| `HARNESS_USERNAME` | Harness username.                       | Harness user or service account username. |
| `HARNESS_TOKEN`    | Harness PAT or SAT.                     |                                           |

### Variable Descriptions

#### HARNESS_TOKEN

This is a Harness PAT or SAT Token.

- Provide the value in plaintext. The script will URL encode the values for you.

#### HARNESS_USERNAME

The Harness username for the user or service account.

- Provide the value in plaintext. The script will URL encode the values for you.

#### GITHUB_CREDENTIALS

Generic git credentials provided in the format `USERNAME:PASSWORD`.

- Provide the value in partially URL encoded text. The username and password should each individually be URL encoded, meaning the `:` separating the two is not URL encoded. The script will **not** make the URL encoding for you.

#### GITHUB_TOKEN

## Preflight Check

- Format variables
- Target correct repo

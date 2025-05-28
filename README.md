# semver-plugin

semver-plugin is tool to use semantic-release in a Harness pipeline. Semantic versioning in the pipeline.

## Variables

### Git Tokens

One (and only one) of the following token variables can be set: `GITHUB_TOKEN`, `GITLAB_TOKEN`, `BITBUCKET_TOKEN`, `GIT_CREDENTIALS`, or `HARNESS_TOKEN`. If none of the variables are set or multiple are set, the script will fail and exit.

| Variable           | Use                                     | Notes                                     |
| ------------------ | --------------------------------------- | ----------------------------------------- |
| `REPO_DIR`         | Relative or absolute path to code repo. | Should be set to repo name.               |
| `HARNESS_USERNAME` | Harness username.                       | Harness user or service account username. |
| `HARNESS_TOKEN`    | Harness PAT or SAT.                     |                                           |

## Preflight Check

- Format variables
- Target correct repo

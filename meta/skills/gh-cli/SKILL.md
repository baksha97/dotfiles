---
name: gh-cli
description: Use this skill whenever working with GitHub from the command line—creating repositories, managing issues and pull requests, running workflows, reviewing code, managing releases, or any GitHub CLI operation. Essential for gh pr, gh issue, gh repo, gh run, gh workflow, gh release commands. Trigger on mentions of 'gh', 'GitHub CLI', 'github command line', or when the user needs to interact with GitHub but wants to avoid the browser.
---

# GitHub CLI (gh)

Work seamlessly with GitHub from the command line. This skill provides comprehensive guidance for the `gh` CLI tool.

## Quick Start

### Authentication

```bash
# Interactive login
gh auth login

# Check status
gh auth status

# Setup git credential helper
gh auth setup-git
```

### Essential Commands

| Task | Command |
| --- | --- |
| Create repo | `gh repo create name --private` |
| Clone repo | `gh repo clone owner/repo` |
| Create issue | `gh issue create --title "Bug" --body "..."` |
| Create PR | `gh pr create --title "Feature" --body "..."` |
| View PR | `gh pr view 123` |
| Merge PR | `gh pr merge 123 --squash --delete-branch` |
| Run workflow | `gh workflow run ci.yml` |
| Watch run | `gh run watch` |
| Create release | `gh release create v1.0.0 --notes "..."` |

## Common Workflows

### Create PR from Issue

```bash
# Create branch from issue
gh issue develop 123 --branch feature/issue-123

# Make changes, commit, push
git add . && git commit -m "Fix issue #123" && git push

# Create PR linking to issue
gh pr create --title "Fix #123" --body "Closes #123"
```

### PR Review Flow

```bash
# List PRs needing review
gh pr list --search "review:required" --json number,title,author

# View PR details
gh pr view 123 --comments

# Checkout PR locally
gh pr checkout 123

# Approve PR
gh pr review 123 --approve --body "LGTM!"

# Merge and clean up
gh pr merge 123 --squash --delete-branch
```

### Repository Setup

```bash
# Create and configure new repo
gh repo create my-project --public --clone --license mit --gitignore node

cd my-project
gh label create bug --color "d73a4a"
gh label create enhancement --color "a2eeef"
```

### CI/CD Operations

```bash
# Trigger workflow and watch
gh workflow run ci.yml
gh run watch

# Download artifacts
gh run download --dir ./artifacts

# Check workflow status
gh run list --branch main --limit 10
```

### Release Management

```bash
# Create release with assets
gh release create v1.0.0 --title "v1.0.0" --notes-file CHANGELOG.md
gh release upload v1.0.0 ./dist/*

# Download release
gh release download v1.0.0 --archive zip
```

### Bulk Operations

```bash
# Close stale issues
gh issue list --search "label:stale" --json number \
  --jq '.[].number' | xargs -I {} gh issue close {} --comment "Closing as stale"

# Add label to multiple PRs
gh pr list --search "review:required" --json number \
  --jq '.[].number' | xargs -I {} gh pr edit {} --add-label needs-review
```

## Detailed Command Reference

For comprehensive command syntax, read the domain-specific reference files:

| Domain | File | Commands |
| --- | --- | --- |
| Authentication | `references/auth.md` | login, status, token, refresh, switch |
| Repositories | `references/repos.md` | create, clone, fork, edit, delete, sync |
| Issues | `references/issues.md` | create, list, view, edit, close, comment |
| Pull Requests | `references/prs.md` | create, list, view, checkout, merge, review |
| Actions | `references/actions.md` | runs, workflows, caches, secrets, variables |
| Releases | `references/releases.md` | create, upload, download, verify |
| Gists | `references/gists.md` | create, list, view, clone |
| Codespaces | `references/codespaces.md` | create, ssh, code, logs |
| Search | `references/search.md` | code, commits, issues, prs, repos |
| Misc | `references/misc.md` | projects, orgs, labels, api, aliases, extensions |

## Output Formatting

### JSON with jq

```bash
# Extract fields
gh pr list --json number,title,author --jq '.[] | "\(.number): \(.title)"'

# Filter results
gh issue list --json number,title,labels \
  --jq '.[] | select(.labels[].name == "bug") | .number'

# Complex queries
gh pr view 123 --json title,state,commits --jq '{title, state, commits: .commits | length}'
```

### Templates

```bash
gh pr view 123 --template 'Title: {{.title}}
Author: {{.author.login}}
State: {{.state}}
'
```

## Environment Variables

```bash
export GH_TOKEN=ghp_xxx          # Auth token for automation
export GH_HOST=github.com         # Default hostname
export GH_PROMPT_DISABLED=true   # Non-interactive mode
export GH_REPO=owner/repo        # Default repository
export GH_TIMEOUT=30            # Request timeout
```

## Shell Integration

```bash
# Add completion to shell config
eval "$(gh completion -s zsh)"  # or bash/fish

# Useful aliases
alias gpr='gh pr view --web'
alias gir='gh issue view --web'
alias gco='gh pr checkout'
alias gs='gh status'
```

## Global Flags

| Flag | Purpose |
| --- | --- |
| `--repo OWNER/REPO` | Operate on different repo |
| `--json FIELDS` | JSON output with fields |
| `--jq EXPR` | Filter JSON output |
| `--web` | Open in browser |
| `--paginate` | Fetch all pages |
| `--verbose` / `--debug` | Verbose output |

## Getting Help

```bash
gh --help              # General help
gh pr --help          # Command help
gh pr create --help   # Subcommand help
gh help formatting   # Help topics
gh help environment
gh help exit-codes
```

## Best Practices

1. **Set default repo**: `gh repo set-default owner/repo` — avoids repetition
2. **Use JSON for scripts**: `--json` + `--jq` for reliable parsing
3. **Paginate large results**: `--paginate` for complete data
4. **Auth for automation**: `GH_TOKEN` environment variable
5. **View before merge**: `gh pr view 123 --comments` + `gh pr diff 123`

## References

- Official Manual: https://cli.github.com/manual/
- GitHub Docs: https://docs.github.com/en/github-cli
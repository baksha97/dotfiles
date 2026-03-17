# Miscellaneous Commands

## Browse (gh browse)

```bash
# Open repository in browser
gh browse

# Open specific path
gh browse script/
gh browse main.go:312

# Open issue or PR
gh browse 123

# Open commit
gh browse 77507cd94ccafcf568f8560cfecde965fcfa63

# Open with specific branch
gh browse main.go --branch bug-fix

# Open different repository
gh browse --repo owner/repo

# Open specific pages
gh browse --actions       # Actions tab
gh browse --projects      # Projects tab
gh browse --releases      # Releases tab
gh browse --settings      # Settings page
gh browse --wiki          # Wiki page

# Print URL instead of opening
gh browse --no-browser
```

## Projects (gh project)

```bash
# List projects
gh project list

# List for owner
gh project list --owner owner

# Open projects
gh project list --open

# View project
gh project view 123

# View project items
gh project view 123 --format json

# Create project
gh project create --title "My Project"

# Create in organization
gh project create --title "Project" --org orgname

# Create with readme
gh project create --title "Project" --readme "Description here"

# Edit project
gh project edit 123 --title "New Title"

# Delete project
gh project delete 123

# Close project
gh project close 123

# Copy project
gh project copy 123 --owner target-owner --title "Copy"

# Mark template
gh project mark-template 123

# List fields
gh project field-list 123

# Create field
gh project field-create 123 --title "Status" --datatype single_select

# Delete field
gh project field-delete 123 --id 456

# List items
gh project item-list 123

# Create item
gh project item-create 123 --title "New item"

# Add item to project
gh project item-add 123 --owner-owner --repo repo --issue 456

# Edit item
gh project item-edit 123 --id 456 --title "Updated title"

# Delete item
gh project item-delete 123 --id 456

# Archive item
gh project item-archive 123 --id 456

# Link items
gh project link 123 --id 456 --link-id 789

# Unlink items
gh project unlink 123 --id 456 --link-id 789

# View project in browser
gh project view 123 --web
```

## Organizations (gh org)

```bash
# List organizations
gh org list

# List for user
gh org list --user username

# JSON output
gh org list --json login,name,description

# View organization
gh org view orgname

# View organization members
gh org view orgname --json members --jq '.members[] | .login'
```

## Labels (gh label)

```bash
# List labels
gh label list

# Create label
gh label create bug --color "d73a4a" --description "Something isn't working"

# Create with hex color
gh label create enhancement --color "#a2eeef"

# Edit label
gh label edit bug --name "bug-report" --color "ff0000"

# Delete label
gh label delete bug

# Clone labels from repository
gh label clone owner/repo

# Clone to specific repository
gh label clone owner/repo --repo target/repo
```

## SSH Keys (gh ssh-key)

```bash
# List SSH keys
gh ssh-key list

# Add SSH key
gh ssh-key add ~/.ssh/id_rsa.pub --title "My laptop"

# Add key with type
gh ssh-key add ~/.ssh/id_ed25519.pub --type "authentication"

# Delete SSH key
gh ssh-key delete 12345

# Delete by title
gh ssh-key delete --title "My laptop"
```

## GPG Keys (gh gpg-key)

```bash
# List GPG keys
gh gpg-key list

# Add GPG key
gh gpg-key add ~/.ssh/id_rsa.pub

# Delete GPG key
gh gpg-key delete 12345

# Delete by key ID
gh gpg-key delete ABCD1234
```

## Status (gh status)

```bash
# Show status overview
gh status

# Status for specific repositories
gh status --repo owner/repo

# JSON output
gh status --json
```

## Configuration (gh config)

```bash
# List all config
gh config list

# Get specific value
gh config get editor

# Set value
gh config set editor vim

# Set git protocol
gh config set git_protocol ssh

# Clear cache
gh config clear-cache

# Set prompt behavior
gh config set prompt disabled
gh config set prompt enabled
```

## Extensions (gh extension)

```bash
# List installed extensions
gh extension list

# Search extensions
gh extension search github

# Install extension
gh extension install owner/extension-repo

# Install from branch
gh extension install owner/extension-repo --branch develop

# Upgrade extension
gh extension upgrade extension-name

# Remove extension
gh extension remove extension-name

# Create new extension
gh extension create my-extension

# Browse extensions
gh extension browse

# Execute extension command
gh extension exec my-extension --arg value
```

## Aliases (gh alias)

```bash
# List aliases
gh alias list

# Set alias
gh alias set prview 'pr view --web'

# Set shell alias
gh alias set co 'pr checkout' --shell

# Delete alias
gh alias delete prview

# Import aliases
gh alias import ./aliases.sh
```

## API Requests (gh api)

```bash
# Make API request
gh api /user

# Request with method
gh api --method POST /repos/owner/repo/issues \
  --field title="Issue title" \
  --field body="Issue body"

# Request with headers
gh api /user \
  --header "Accept: application/vnd.github.v3+json"

# Request with pagination
gh api /user/repos --paginate

# Raw output (no formatting)
gh api /user --raw

# Include headers in output
gh api /user --include

# Silent mode (no progress output)
gh api /user --silent

# Input from file
gh api --input request.json

# jq query on response
gh api /user --jq '.login'

# Field from response
gh api /repos/owner/repo --jq '.stargazers_count'

# GitHub Enterprise
gh api /user --hostname enterprise.internal

# GraphQL query
gh api graphql \
  -f query='
  {
    viewer {
      login
      repositories(first: 5) {
        nodes {
          name
        }
      }
    }
  }'
```

## Rulesets (gh ruleset)

```bash
# List rulesets
gh ruleset list

# View ruleset
gh ruleset view 123

# Check ruleset
gh ruleset check --branch feature

# Check specific repository
gh ruleset check --repo owner/repo --branch main
```

## Attestations (gh attestation)

```bash
# Download attestation
gh attestation download owner/repo \
  --artifact-id 123456

# Verify attestation
gh attestation verify owner/repo

# Get trusted root
gh attestation trusted-root
```

## Completion (gh completion)

```bash
# Generate shell completion
gh completion -s bash > ~/.gh-complete.bash
gh completion -s zsh > ~/.gh-complete.zsh
gh completion -s fish > ~/.gh-complete.fish
gh completion -s powershell > ~/.gh-complete.ps1

# Shell-specific instructions
gh completion --shell=bash
gh completion --shell=zsh
```

## Preview (gh preview)

```bash
# List preview features
gh preview

# Run preview script
gh preview prompter
```

## Agent Tasks (gh agent-task)

```bash
# List agent tasks
gh agent-task list

# View agent task
gh agent-task view 123

# Create agent task
gh agent-task create --description "My task"
```

## Global Flags

| Flag | Description |
| --- | --- |
| `--help` / `-h` | Show help for command |
| `--version` | Show gh version |
| `--repo [HOST/]OWNER/REPO` | Select another repository |
| `--hostname HOST` | GitHub hostname |
| `--jq EXPRESSION` | Filter JSON output |
| `--json FIELDS` | Output JSON with specified fields |
| `--template STRING` | Format JSON using Go template |
| `--web` | Open in browser |
| `--paginate` | Make additional API calls |
| `--verbose` | Show verbose output |
| `--debug` | Show debug output |
| `--timeout SECONDS` | Maximum API request duration |
| `--cache CACHE` | Cache control (default, force, bypass) |

## Output Formatting

### JSON Output

```bash
# Basic JSON
gh repo view --json name,description

# Nested fields
gh repo view --json owner,name --jq '.owner.login + "/" + .name'

# Array operations
gh pr list --json number,title --jq '.[] | select(.number > 100)'

# Complex queries
gh issue list --json number,title,labels \
  --jq '.[] | {number, title: .title, tags: [.labels[].name]}'
```

### Template Output

```bash
# Custom template
gh repo view \
  --template '{{.name}}: {{.description}}'

# Multiline template
gh pr view 123 \
  --template 'Title: {{.title}}
Author: {{.author.login}}
State: {{.state}}
'
```

## Environment Variables

```bash
# GitHub token (for automation)
export GH_TOKEN=ghp_xxxxxxxxxxxx

# GitHub hostname
export GH_HOST=github.com

# Disable prompts
export GH_PROMPT_DISABLED=true

# Custom editor
export GH_EDITOR=vim

# Custom pager
export GH_PAGER=less

# HTTP timeout
export GH_TIMEOUT=30

# Custom repository (override default)
export GH_REPO=owner/repo

# Custom git protocol
export GH_ENTERPRISE_HOSTNAME=hostname
```

## Shell Integration

```bash
# Add to ~/.bashrc or ~/.zshrc
eval "$(gh completion -s bash)"  # or zsh/fish

# Create useful aliases
alias gs='gh status'
alias gpr='gh pr view --web'
alias gir='gh issue view --web'
alias gco='gh pr checkout'
```

## Git Configuration

```bash
# Use gh as credential helper
gh auth setup-git

# Set gh as default for repo operations
git config --global credential.helper 'gh !gh auth setup-git'

# Or manually
git config --global credential.helper github
```
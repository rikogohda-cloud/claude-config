# Claude Code Configuration

Riko Gohda's personal Claude Code configuration and automation tools.

## 📁 Structure

```
claude-config/
├── CLAUDE.md               # Global instructions and rules
├── settings.json           # Claude Code settings
├── commands/               # Custom commands (skills) - 29 commands
│   ├── daily.md           # Daily report v1
│   ├── daily-v2.md        # Daily report v2 (token optimized)
│   ├── check-mail.md      # Gmail triage automation
│   ├── check-slack.md     # Slack triage automation
│   ├── morning.md         # Morning briefing
│   ├── prep.md            # Meeting preparation
│   └── ...                # Other automation commands
├── scripts/               # Helper scripts - 24 scripts
│   ├── auto-commit-private.sh
│   ├── daily-report.bat
│   └── ...                # Other utility scripts
├── workflows/             # Workflow documentation
├── daily-worker.md        # Daily report worker v1
└── daily-worker-v2.md     # Daily report worker v2
```

## 🚀 Installation

### Prerequisites

Before installing this configuration, ensure you have:

| Tool | Purpose | Installation |
|------|---------|--------------|
| **Claude Code** | AI assistant CLI | [Download from claude.ai](https://claude.ai/download) |
| **Git** | Version control | [git-scm.com](https://git-scm.com/) |
| **GitHub CLI (`gh`)** | GitHub integration | [cli.github.com](https://cli.github.com/) |
| **gog** (optional) | Gmail/Calendar CLI | Internal UPSIDER tool |
| **Python 3** (optional) | Helper scripts | [python.org](https://www.python.org/) |

### Quick Setup (New PC)

#### Step 1: Install Claude Code
```bash
# Mac (Homebrew)
brew install claude

# Windows (via installer)
# Download from https://claude.ai/download

# Linux
curl -fsSL https://claude.ai/install.sh | sh
```

#### Step 2: Authenticate GitHub
```bash
gh auth login
```

#### Step 3: Clone and Setup
```bash
# Clone this repository
cd ~
git clone https://github.com/rikogohda-cloud/claude-config.git

# Backup existing config (if any)
mv ~/.claude ~/.claude.backup.$(date +%Y%m%d) 2>/dev/null || true

# Copy new config
cp -r claude-config ~/.claude

# Setup git remote
cd ~/.claude
git remote set-url origin https://github.com/rikogohda-cloud/claude-config.git
```

#### Step 4: Verify Installation
```bash
# Restart Claude Code (close and reopen terminal)

# Check if commands are loaded
claude --version

# Test a command (in Claude Code session)
/commands
```

### OS-Specific Adjustments

#### Windows
Some commands may need path adjustments:
```bash
# Example: Update paths in commands that use ZONEINFO
# C:/Users/rikogohda/.local/lib/zoneinfo.zip
```

Tools use `.exe` extension:
- `gog.exe` instead of `gog`
- `claude.exe` instead of `claude`

#### Mac/Linux
Paths use standard Unix format:
```bash
# Example: ~/.local/lib/zoneinfo.zip
```

### Optional Tools Setup

#### gog (Gmail/Calendar CLI)
Required for: `/check-mail`, `/morning`, `/weekly-finance`

```bash
# Install (internal UPSIDER tool)
# Contact IT for installation instructions

# Authenticate
gog auth login
```

#### Python Scripts
Required for: Some helper scripts in `scripts/`

```bash
# Install dependencies (if needed)
pip install google-auth google-auth-oauthlib google-api-python-client
```

### Customization

This configuration is pre-configured for Riko with:
- ✅ Email: riko.gohda@up-sider.com
- ✅ Slack User ID: U07E74J2GEM
- ✅ Slack Channel IDs: Pre-configured
- ✅ Notion Database IDs: Pre-configured

**Most settings work out of the box on any PC once authenticated.**

## 📝 Available Commands

All commands in `commands/` directory are available as `/command-name`:

| Command | Description | Token Usage |
|---------|-------------|-------------|
| `/daily` | Daily report v1 | ~87k |
| `/daily-v2` | Daily report v2 (optimized) | ~25k |
| `/check-mail` | Gmail unread triage | ~10k |
| `/check-slack` | Slack unread triage | ~8k |
| `/morning` | Morning briefing | ~15k |
| `/prep` | Meeting preparation | ~12k |
| `/1on1` | 1-on-1 support | ~10k |
| `/deal-review` | Deal review automation | ~15k |
| `/weekly-slack-summary` | Weekly Slack summary | ~20k |
| ... | See `commands/` for full list | - |

## 🔧 Troubleshooting

### Commands not showing up
```bash
# Restart Claude Code (close terminal and reopen)

# Check if files exist
ls -la ~/.claude/commands/

# Verify frontmatter in command files
head -10 ~/.claude/commands/daily.md
```

### Permission errors
```bash
# Fix file permissions
chmod -R 755 ~/.claude/
chmod 644 ~/.claude/commands/*.md
```

### Git sync issues
```bash
# Reset to remote
cd ~/.claude
git fetch origin
git reset --hard origin/main
```

## 🔄 Syncing Changes Across PCs

### On PC A (after making changes):
```bash
cd ~/.claude
git add -A
git commit -m "Update: description of changes"
git push origin main
```

### On PC B (to get updates):
```bash
cd ~/.claude
git pull origin main
```

### Auto-sync setup (optional):
Add to `~/.zshrc` or `~/.bashrc`:
```bash
alias claude-sync='cd ~/.claude && git pull origin main && git add -A && git commit -m "auto: update config $(date +%Y-%m-%d_%H:%M)" && git push origin main'
```

Then run `claude-sync` periodically.

## 📊 Token Usage Optimization

For cost-effective automation with Team Premium (10M tokens/month):

| Usage Pattern | Monthly Tokens | Usage % |
|---------------|----------------|---------|
| `/daily-v2` × 20 | 500k | 5.0% |
| `/check-mail` × 40 | 400k | 4.0% |
| `/morning` × 20 | 300k | 3.0% |
| `/check-slack` × 20 | 160k | 1.6% |
| Other commands | ~640k | 6.4% |
| **Total** | **~2M** | **20%** |

**Recommendation:**
- Use `/daily-v2` instead of `/daily` (71% reduction)
- Limit automation frequency
- Monitor usage in Claude.ai dashboard

## 🔒 Security

The following directories/files are excluded from version control:
- `private/` - Personal/confidential information
- `cache/` - Cache data
- `*.token` - Authentication tokens
- `.env*` - Environment variables
- `*.pem`, `*.key` - Private keys

**Never commit sensitive information to this repository.**

## 🤝 Contributing

This is a personal configuration repository, but feel free to:
- Fork for your own use
- Submit issues for bugs
- Suggest improvements via pull requests

## 📄 License

MIT License

## 👤 Author

Riko Gohda ([@rikogohda-cloud](https://github.com/rikogohda-cloud))

## 🔗 Related Repositories

- [daily-report-automation](https://github.com/rikogohda-cloud/daily-report-automation) - Daily report generation tool (standalone)

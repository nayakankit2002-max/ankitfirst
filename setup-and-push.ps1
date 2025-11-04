# setup-and-push.ps1
# Usage: Run from repo root. Example:
#   cd 'C:\Users\HP\OneDrive\Desktop\realtime-code-editor-main'
#   .\setup-and-push.ps1

$ErrorActionPreference = "Stop"

# === CONFIGURE THESE BEFORE RUNNING (or script will prompt) ===
$gitUserName = "ankitnayak22-max"
$gitUserEmail = "nayakankit2002@gmail.com"
# If you already created a Github repo, set this to its HTTPS or SSH URL (or leave blank to be prompted)
$remoteUrl = ""

Write-Host "1) Checking Git installation..."
try {
  git --version > $null 2>&1
  Write-Host "Git is already installed."
} catch {
  Write-Host "Git not found. Attempting to install via winget (requires Windows 10/11 and winget)..."
  try {
    winget install --id Git.Git -e --source winget -h
    Write-Host "Installed Git via winget. Restart your terminal after this script finishes if required."
  } catch {
    Write-Host "winget install failed or winget is unavailable. Please install Git manually from https://git-scm.com/download/win and re-run this script."
    exit 1
  }
}

Write-Host "2) Setting Git global user (only if not set)..."
# Set only if not already set
$currentName = & git config --global user.name 2>$null
if (-not $currentName) {
  git config --global user.name $gitUserName
  Write-Host "Set git user.name = $gitUserName"
} else {
  Write-Host "git user.name already set to '$currentName' (will not change)"
}

$currentEmail = & git config --global user.email 2>$null
if (-not $currentEmail) {
  git config --global user.email $gitUserEmail
  Write-Host "Set git user.email = $gitUserEmail"
} else {
  Write-Host "git user.email already set to '$currentEmail' (will not change)"
}

# 3) Initialize repo if needed
if (-not (Test-Path ".git")) {
  Write-Host "3) Initializing git repository..."
  git init
} else {
  Write-Host "3) .git exists; skipping git init"
}

# 4) Add a sensible .gitignore if missing
if (-not (Test-Path ".gitignore")) {
  Write-Host "Adding default .gitignore for Node projects..."
  @"
node_modules/
build/
.env
.DS_Store
npm-debug.log*
yarn-debug.log*
yarn-error.log*
*.local
"@ | Out-File -Encoding UTF8 .gitignore
  git add .gitignore
}

# 5) Stage & commit
Write-Host "4) Staging changes..."
git add .

# Check whether there's anything to commit
$changes = git status --porcelain
if (-not [string]::IsNullOrWhiteSpace($changes)) {
  Write-Host "Committing changes..."
  git commit -m "Fix Home.js anchor href and create-new-room link"
} else {
  Write-Host "No changes to commit."
}

# 6) Remote handling
if (-not $remoteUrl) {
  # If gh is installed we can optionally create a repo and push
  try {
    gh --version > $null 2>&1
    $hasGh = $true
  } catch {
    $hasGh = $false
  }

  if ($hasGh) {
    Write-Host "GitHub CLI (gh) detected. Creating a new GitHub repo interactively..."
    Write-Host "When prompted by gh, choose a name and visibility. This will also add origin and push."
    gh repo create --public -y --source=. --remote=origin --push
  } else {
    Write-Host "No remote URL provided and 'gh' not available. Please create a repo on GitHub and provide its URL."
    $remoteUrl = Read-Host "Enter remote URL (HTTPS or SSH), or leave blank to skip pushing"
    if ($remoteUrl) {
      git remote add origin $remoteUrl
      Write-Host "Pushing to remote origin..."
      git push -u origin HEAD
    } else {
      Write-Host "No remote configured. Skipping push."
    }
  }
} else {
  # remote URL provided in script variables
  Write-Host "Adding provided remote and pushing..."
  git remote add origin $remoteUrl
  git push -u origin HEAD
}

# 7) Quick sanity check: install deps and build (optional)
Write-Host "5) Quick sanity check: checking for npm..."
try {
  npm --version > $null 2>&1
  $hasNpm = $true
} catch {
  $hasNpm = $false
}

if ($hasNpm) {
  Write-Host "Running npm install (may take a while)..."
  npm install
  # Run build if script exists in package.json
  $pkg = Get-Content package.json -Raw | ConvertFrom-Json
  if ($pkg.scripts -and $pkg.scripts.build) {
    Write-Host "Running npm run build..."
    npm run build
  } else {
    Write-Host "No build script defined in package.json, skipping build."
  }
} else {
  Write-Host "npm not found; skipping dependency install and build."
}

Write-Host "All done. Check output above for any prompts/errors. If push failed due to authorization, follow notes below."

# Notes printed to user
Write-Host ""
Write-Host "If Git push fails with authentication errors:"
Write-Host "- For HTTPS: create a Personal Access Token (PAT) and use it instead of your password when prompted."
Write-Host "- For SSH: set up an SSH key and add it to GitHub; use the SSH remote URL (git@github.com:username/repo.git)."

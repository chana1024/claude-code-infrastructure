#!/bin/bash

################################################################################
# Claude Code Infrastructure Installer (Project-Level)
#
# Usage:
#   cd your-project
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-infrastructure-showcase/main/install.sh | bash
#
#   Or:
#   git clone https://github.com/YOUR_USERNAME/claude-code-infrastructure-showcase.git
#   cd your-project
#   bash /path/to/showcase/install.sh
#
# What it installs (interactive):
#   ✅ Essential hooks (skill activation + file tracking)
#   ✅ Universal agents (code review, refactoring, documentation)
#   ✅ skill-developer (meta-skill)
#   ✅ Backend skills (optional, for Node.js/Express projects)
#   ✅ Frontend skills (optional, for React/MUI projects)
#   ✅ Other domain skills (optional)
#   ✅ Project-specific configuration
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Repository
REPO_URL="https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-infrastructure-showcase/main"
REPO_GIT="https://github.com/YOUR_USERNAME/claude-code-infrastructure-showcase.git"

# Project directory
PROJECT_DIR=$(pwd)
CLAUDE_DIR="$PROJECT_DIR/.claude"

# Temp directory for cloned repo
TEMP_REPO=""

################################################################################
# Helper Functions
################################################################################

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${GREEN}▶${NC} $1"
}

cleanup() {
    if [ -n "$TEMP_REPO" ] && [ -d "$TEMP_REPO" ]; then
        print_info "Cleaning up temporary files..."
        rm -rf "$TEMP_REPO"
    fi
}

trap cleanup EXIT

################################################################################
# Pre-flight Checks
################################################################################

check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check if in a directory that looks like a project
    if [ ! -w "$PROJECT_DIR" ]; then
        print_error "Current directory is not writable"
        exit 1
    fi

    # Check for git
    if ! command -v git &> /dev/null; then
        print_error "git is required but not found"
        exit 1
    fi

    # Check for node/npm (warn only)
    if ! command -v node &> /dev/null; then
        print_warning "Node.js not found. Hooks may not work."
    fi

    if ! command -v npm &> /dev/null; then
        print_warning "npm not found. Will skip hook dependencies."
    fi

    print_success "Prerequisites check passed"
}

detect_project_type() {
    print_header "Detecting Project Type"

    local has_package_json=false
    local has_tsconfig=false
    local has_backend=false
    local has_frontend=false
    local tech_stack=""

    [ -f "package.json" ] && has_package_json=true
    [ -f "tsconfig.json" ] && has_tsconfig=true

    # Detect backend
    if [ -d "src" ] || [ -d "api" ] || [ -d "server" ] || [ -d "backend" ]; then
        if [ -f "package.json" ]; then
            if grep -q "express" package.json 2>/dev/null; then
                has_backend=true
                tech_stack="Node.js/Express"
            fi
        fi
    fi

    # Detect frontend
    if [ -f "package.json" ]; then
        if grep -q "react" package.json 2>/dev/null; then
            has_frontend=true
            tech_stack="${tech_stack:+$tech_stack + }React"
        fi
        if grep -q "@mui/material" package.json 2>/dev/null; then
            tech_stack="${tech_stack:+$tech_stack + }MUI"
        fi
    fi

    print_info "Detected: $tech_stack"

    if [ "$has_backend" = true ]; then
        print_success "Backend project detected"
    fi

    if [ "$has_frontend" = true ]; then
        print_success "Frontend project detected"
    fi

    if [ "$has_backend" = false ] && [ "$has_frontend" = false ]; then
        print_warning "Could not auto-detect project type"
        print_info "You'll be prompted to choose components manually"
    fi

    echo "$has_backend|$has_frontend"
}

################################################################################
# Clone Repository
################################################################################

clone_repo() {
    print_header "Downloading Infrastructure"

    TEMP_REPO=$(mktemp -d)
    print_info "Cloning repository..."

    if git clone --depth 1 "$REPO_GIT" "$TEMP_REPO" 2>/dev/null; then
        print_success "Repository downloaded"
    else
        print_error "Failed to clone repository: $REPO_GIT"
        exit 1
    fi
}

################################################################################
# Installation Functions
################################################################################

create_directory_structure() {
    print_header "Creating Directory Structure"

    mkdir -p "$CLAUDE_DIR"/{skills,agents,hooks,commands}
    print_success "Created .claude directory structure"
}

install_hooks() {
    print_step "Installing Essential Hooks"

    local source_dir="$TEMP_REPO/.claude/hooks"
    local dest_dir="$CLAUDE_DIR/hooks"

    # Copy hook files
    cp "$source_dir/skill-activation-prompt.sh" "$dest_dir/" 2>/dev/null || true
    cp "$source_dir/skill-activation-prompt.ts" "$dest_dir/" 2>/dev/null || true
    cp "$source_dir/post-tool-use-tracker.sh" "$dest_dir/" 2>/dev/null || true
    cp "$source_dir/package.json" "$dest_dir/" 2>/dev/null || true
    cp "$source_dir/tsconfig.json" "$dest_dir/" 2>/dev/null || true

    # Make executable
    chmod +x "$dest_dir"/*.sh 2>/dev/null || true

    # Install npm dependencies
    if command -v npm &> /dev/null; then
        print_info "Installing hook dependencies..."
        (cd "$dest_dir" && npm install --silent 2>/dev/null) || print_warning "npm install failed"
    fi

    print_success "Hooks installed"
}

install_agents() {
    print_step "Installing Universal Agents"

    local source_dir="$TEMP_REPO/.claude/agents"
    local dest_dir="$CLAUDE_DIR/agents"

    local agents=(
        "code-architecture-reviewer.md"
        "refactor-planner.md"
        "documentation-architect.md"
        "plan-reviewer.md"
        "web-research-specialist.md"
        "code-refactor-master.md"
    )

    for agent in "${agents[@]}"; do
        cp "$source_dir/$agent" "$dest_dir/" 2>/dev/null || true
    done

    print_success "Installed ${#agents[@]} agents"
}

install_skill_developer() {
    print_step "Installing skill-developer"

    local source_dir="$TEMP_REPO/.claude/skills/skill-developer"
    local dest_dir="$CLAUDE_DIR/skills/skill-developer"

    cp -r "$source_dir" "$dest_dir" 2>/dev/null || true
    print_success "skill-developer installed"
}

install_backend_skill() {
    print_step "Installing backend-dev-guidelines"

    local source_dir="$TEMP_REPO/.claude/skills/backend-dev-guidelines"
    local dest_dir="$CLAUDE_DIR/skills/backend-dev-guidelines"

    cp -r "$source_dir" "$dest_dir" 2>/dev/null || true
    print_success "backend-dev-guidelines installed"
}

install_frontend_skill() {
    print_step "Installing frontend-dev-guidelines"

    local source_dir="$TEMP_REPO/.claude/skills/frontend-dev-guidelines"
    local dest_dir="$CLAUDE_DIR/skills/frontend-dev-guidelines"

    cp -r "$source_dir" "$dest_dir" 2>/dev/null || true
    print_success "frontend-dev-guidelines installed"
}

install_other_skills() {
    print_step "Installing additional skills"

    local source_dir="$TEMP_REPO/.claude/skills"
    local dest_dir="$CLAUDE_DIR/skills"

    # route-tester
    if [ "$1" = "true" ]; then
        cp -r "$source_dir/route-tester" "$dest_dir/" 2>/dev/null || true
        print_success "route-tester installed"
    fi

    # error-tracking
    if [ "$2" = "true" ]; then
        cp -r "$source_dir/error-tracking" "$dest_dir/" 2>/dev/null || true
        print_success "error-tracking installed"
    fi
}

install_commands() {
    print_step "Installing commands"

    local source_dir="$TEMP_REPO/.claude/commands"
    local dest_dir="$CLAUDE_DIR/commands"

    cp "$source_dir/dev-docs.md" "$dest_dir/" 2>/dev/null || true
    print_success "dev-docs command installed"
}

################################################################################
# Configuration
################################################################################

detect_project_paths() {
    local path_type="$1"
    local paths=()

    if [ "$path_type" = "backend" ]; then
        [ -d "src" ] && paths+=("src/**/*.ts")
        [ -d "api" ] && paths+=("api/**/*.ts")
        [ -d "server" ] && paths+=("server/**/*.ts")
        [ -d "backend" ] && paths+=("backend/**/*.ts")
        [ -d "services" ] && paths+=("services/**/*.ts")
    elif [ "$path_type" = "frontend" ]; then
        [ -d "src" ] && paths+=("src/**/*.tsx" "src/**/*.ts")
        [ -d "frontend" ] && paths+=("frontend/**/*.tsx" "frontend/**/*.ts")
        [ -d "client" ] && paths+=("client/**/*.tsx" "client/**/*.ts")
        [ -d "web" ] && paths+=("web/**/*.tsx" "web/**/*.ts")
    fi

    # Default fallback
    if [ ${#paths[@]} -eq 0 ]; then
        if [ "$path_type" = "backend" ]; then
            paths=("src/**/*.ts" "**/*.ts")
        else
            paths=("src/**/*.tsx" "**/*.tsx")
        fi
    fi

    # Return as JSON array
    printf '%s\n' "${paths[@]}" | jq -R . | jq -s .
}

create_skill_rules() {
    print_header "Creating Configuration"

    local skill_rules_file="$CLAUDE_DIR/skills/skill-rules.json"
    local has_backend="$1"
    local has_frontend="$2"
    local has_route_tester="$3"
    local has_error_tracking="$4"

    print_info "Detecting project structure..."

    local backend_paths=$(detect_project_paths "backend")
    local frontend_paths=$(detect_project_paths "frontend")

    cat > "$skill_rules_file" << EOF
{
  "version": "1.0",
  "description": "Skill activation rules for this project",
  "skills": {
    "skill-developer": {
      "type": "domain",
      "enforcement": "suggest",
      "priority": "medium",
      "promptTriggers": {
        "keywords": ["skill", "create skill", "hook", "skill activation"],
        "intentPatterns": [
          "如何.*创建.*skill",
          "how.*create.*skill",
          "skill.*不.*激活"
        ]
      },
      "fileTriggers": {
        "pathPatterns": [
          ".claude/skills/**/*.md",
          ".claude/hooks/**/*"
        ]
      }
    }
EOF

    if [ "$has_backend" = "true" ]; then
        cat >> "$skill_rules_file" << EOF
,
    "backend-dev-guidelines": {
      "type": "domain",
      "enforcement": "suggest",
      "priority": "high",
      "promptTriggers": {
        "keywords": ["route", "controller", "service", "api", "endpoint", "middleware"],
        "intentPatterns": [
          "(create|add|implement).*?(route|endpoint|API|controller|service)",
          "(fix|handle).*?(error|exception)"
        ]
      },
      "fileTriggers": {
        "pathPatterns": $backend_paths,
        "contentPatterns": [
          "router\\\\.",
          "app\\\\.(get|post|put|delete)",
          "export.*Controller",
          "export.*Service"
        ]
      }
    }
EOF
    fi

    if [ "$has_frontend" = "true" ]; then
        cat >> "$skill_rules_file" << EOF
,
    "frontend-dev-guidelines": {
      "type": "guardrail",
      "enforcement": "suggest",
      "priority": "high",
      "promptTriggers": {
        "keywords": ["component", "react", "UI", "MUI", "form", "modal"],
        "intentPatterns": [
          "(create|add|build).*?(component|UI|page)",
          "(style|design).*?(component|UI)"
        ]
      },
      "fileTriggers": {
        "pathPatterns": $frontend_paths,
        "contentPatterns": [
          "from '@mui/material'",
          "import.*Grid.*from.*@mui"
        ]
      }
    }
EOF
    fi

    if [ "$has_route_tester" = "true" ]; then
        cat >> "$skill_rules_file" << EOF
,
    "route-tester": {
      "type": "domain",
      "enforcement": "suggest",
      "priority": "high",
      "promptTriggers": {
        "keywords": ["test route", "test API", "API testing"],
        "intentPatterns": [
          "(test|debug).*?(route|endpoint|API)"
        ]
      }
    }
EOF
    fi

    if [ "$has_error_tracking" = "true" ]; then
        cat >> "$skill_rules_file" << EOF
,
    "error-tracking": {
      "type": "domain",
      "enforcement": "suggest",
      "priority": "high",
      "promptTriggers": {
        "keywords": ["sentry", "error tracking", "monitoring"],
        "intentPatterns": [
          "(add|implement).*?(sentry|error tracking)"
        ]
      }
    }
EOF
    fi

    cat >> "$skill_rules_file" << 'EOF'
  }
}
EOF

    print_success "Created skill-rules.json"
    print_info "Auto-detected paths based on project structure"
}

create_settings() {
    local settings_file="$CLAUDE_DIR/settings.json"

    if [ -f "$settings_file" ]; then
        print_warning "settings.json already exists"
        cp "$settings_file" "$settings_file.backup"
        print_info "Created backup: settings.json.backup"
    fi

    cat > "$settings_file" << 'EOF'
{
  "hooks": {
    "UserPromptSubmit": ".claude/hooks/skill-activation-prompt.sh",
    "PostToolUse": ".claude/hooks/post-tool-use-tracker.sh"
  },
  "permissions": [
    "Edit:*",
    "Write:*",
    "Bash:*"
  ]
}
EOF

    print_success "Created settings.json"
}

create_readme() {
    local readme_file="$CLAUDE_DIR/README.md"

    cat > "$readme_file" << 'EOF'
# Claude Code Infrastructure

This directory contains Claude Code infrastructure for this project.

## Installed Components

### Skills
- **skill-developer/** - Meta-skill for creating/managing skills
- **backend-dev-guidelines/** - Node.js/Express patterns (if installed)
- **frontend-dev-guidelines/** - React/MUI patterns (if installed)

### Agents
- **code-architecture-reviewer.md** - Code review
- **refactor-planner.md** - Refactoring strategies
- **documentation-architect.md** - Documentation generation
- And more...

### Hooks
- **skill-activation-prompt.*** - Auto-activates skills
- **post-tool-use-tracker.sh** - Tracks file changes

### Configuration
- **settings.json** - Hook configuration
- **skills/skill-rules.json** - Skill trigger rules

## Usage

Skills will auto-activate based on:
1. File paths you edit
2. Keywords in your prompts
3. Content patterns in files

## Customization

Edit `skills/skill-rules.json` to:
- Adjust path patterns for your project structure
- Add custom keywords
- Change enforcement levels

## Documentation

See the showcase repository for full documentation:
https://github.com/YOUR_USERNAME/claude-code-infrastructure-showcase
EOF

    print_success "Created README.md"
}

################################################################################
# Interactive Setup
################################################################################

interactive_setup() {
    print_header "Interactive Setup"

    local detection_result=$(detect_project_type)
    local auto_backend=$(echo "$detection_result" | cut -d'|' -f1)
    local auto_frontend=$(echo "$detection_result" | cut -d'|' -f2)

    # Backend skill
    local install_backend="false"
    if [ "$auto_backend" = "true" ]; then
        echo -e "${CYAN}Backend (Node.js/Express) detected.${NC}"
        read -p "Install backend-dev-guidelines? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_backend="true"
        fi
    else
        read -p "Install backend-dev-guidelines (Node.js/Express)? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_backend="true"
        fi
    fi

    # Frontend skill
    local install_frontend="false"
    if [ "$auto_frontend" = "true" ]; then
        echo -e "${CYAN}Frontend (React) detected.${NC}"
        read -p "Install frontend-dev-guidelines? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_frontend="true"
        fi
    else
        read -p "Install frontend-dev-guidelines (React/MUI)? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_frontend="true"
        fi
    fi

    # Additional skills
    local install_route_tester="false"
    read -p "Install route-tester (API testing)? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_route_tester="true"
    fi

    local install_error_tracking="false"
    read -p "Install error-tracking (Sentry)? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_error_tracking="true"
    fi

    echo "$install_backend|$install_frontend|$install_route_tester|$install_error_tracking"
}

################################################################################
# Main Installation
################################################################################

main() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   Claude Code Infrastructure Installer                       ║
║   Project-Level Installation                                 ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    print_info "Installation directory: $PROJECT_DIR/.claude"
    echo

    # Confirm
    read -p "Install Claude Code infrastructure to this project? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi

    # Run installation
    check_prerequisites
    clone_repo

    # Interactive setup
    local choices=$(interactive_setup)
    local install_backend=$(echo "$choices" | cut -d'|' -f1)
    local install_frontend=$(echo "$choices" | cut -d'|' -f2)
    local install_route_tester=$(echo "$choices" | cut -d'|' -f3)
    local install_error_tracking=$(echo "$choices" | cut -d'|' -f4)

    # Install components
    print_header "Installing Components"

    create_directory_structure
    install_hooks
    install_agents
    install_skill_developer

    [ "$install_backend" = "true" ] && install_backend_skill
    [ "$install_frontend" = "true" ] && install_frontend_skill
    install_other_skills "$install_route_tester" "$install_error_tracking"

    install_commands

    # Configuration
    create_skill_rules "$install_backend" "$install_frontend" "$install_route_tester" "$install_error_tracking"
    create_settings
    create_readme

    # Success
    print_header "Installation Complete! 🎉"

    echo -e "${GREEN}✅ Claude Code infrastructure installed successfully${NC}\n"

    echo -e "${BLUE}Installed Components:${NC}"
    echo "  📚 skill-developer"
    [ "$install_backend" = "true" ] && echo "  📚 backend-dev-guidelines"
    [ "$install_frontend" = "true" ] && echo "  📚 frontend-dev-guidelines"
    [ "$install_route_tester" = "true" ] && echo "  📚 route-tester"
    [ "$install_error_tracking" = "true" ] && echo "  📚 error-tracking"
    echo "  🤖 6 universal agents"
    echo "  🪝 2 essential hooks"
    echo "  💬 dev-docs command"
    echo "  ⚙️  Project configuration"

    echo -e "\n${BLUE}Configuration:${NC}"
    echo "  Location: .claude/"
    echo "  Settings: .claude/settings.json"
    echo "  Rules: .claude/skills/skill-rules.json"

    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo "  1. Review .claude/skills/skill-rules.json"
    echo "  2. Adjust pathPatterns if needed"
    echo "  3. Test: Edit a file and see if skills activate"
    echo "  4. Commit .claude/ to version control"

    echo -e "\n${BLUE}Usage:${NC}"
    echo "  • Skills auto-activate based on file paths and prompts"
    echo "  • Ask Claude: \"How to create a route?\" → backend skill activates"
    echo "  • Edit .tsx file → frontend skill activates"
    echo "  • Use /dev-docs to generate project documentation"

    echo -e "\n${GREEN}Happy coding with Claude! 🚀${NC}\n"
}

# Run
main "$@"

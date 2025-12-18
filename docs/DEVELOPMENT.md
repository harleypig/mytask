# Development Guide

This document describes the development environment and setup needed to work on this project.

## Prerequisites

### Required Tools

* **Perl**: Version 5.20 or later (check with `perl -v`)
* **Git**: For version control
* **local::lib**: For managing Perl module dependencies (isolated from system Perl)
* **cpanm** (or equivalent): For installing Perl modules (CPAN::Minus or `cpan`)
* **Make**: For build automation (if using Makefile-based builds)

### Development Environment

* **Unix-like system**: Linux, macOS, WSL, or similar
* **Shell**: Bash or compatible shell
* **Text editor**: Any editor capable of editing Perl and Markdown files

## Perl Environment Setup

The project supports two development scenarios for managing Perl dependencies:

1. **Standard Setup**: Uses `local::lib` for project-specific module isolation
2. **Perlbrew Setup**: Uses `perlbrew` for Perl version and module management

The bootstrap script automatically detects which scenario you're using. Choose the setup method that best fits your workflow.

### Standard Setup (local::lib)

This setup uses `local::lib` to create a project-specific Perl module directory (`.local-lib/`) that keeps dependencies isolated from your system Perl installation.

#### Prerequisites

* Perl 5.20 or later
* `cpanm` installed (via system package manager or preferred method)
* Ability to install `local::lib` module

#### Initial Setup

1. Install `cpanm` if not already available:
   ```bash
   # Using system package manager (recommended)
   sudo apt-get install cpanminus    # Debian/Ubuntu
   brew install cpanminus             # macOS
   # Or use your distribution's package manager
   ```

2. Install `local::lib` if not already available:
   ```bash
   cpanm --local-lib=~/perl5 local::lib

   # Or install via cpan
   cpan local::lib
   ```

3. Configure your shell to use `local::lib` (optional, for global use):
   ```bash
   # Add to your ~/.bashrc or ~/.zshrc
   eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"
   ```

4. Reload your shell configuration (if you added the above):
   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

#### Project-Specific Setup

Run the bootstrap script:

```bash
./scripts/bootstrap.sh
```

The bootstrap script will:
* Detect that you're using standard setup (no perlbrew detected)
* Verify that `cpanm` is available (exits with error if not found)
* Create the `.local-lib/` directory in the project root
* Generate `scripts/local-env.sh` with the necessary environment variables
* Install project dependencies automatically (if dependency files exist)

After running the bootstrap script, activate the environment:

```bash
source scripts/local-env.sh
```

**Note**: You must source `scripts/local-env.sh` each time you start a new shell session to work on the project.

#### Installing Perl Modules

Before installing or using Perl modules, ensure you have sourced the environment:

```bash
source scripts/local-env.sh
```

Then install project dependencies:

```bash
# Install project dependencies (when defined)
cpanm --installdeps .
```

Modules will be installed to your `.local-lib/` directory without requiring root access.

---

### Perlbrew Setup

This setup uses `perlbrew` to manage Perl versions and modules. Perlbrew provides a complete Perl environment management solution, making it ideal for developers who work with multiple Perl versions.

#### Prerequisites

* `perlbrew` installed and initialized
* A perlbrew-managed Perl version active
* `cpanm` installed via perlbrew

#### Initial Setup

1. Install perlbrew (if not already installed):
   ```bash
   # Using system package manager (recommended)
   sudo apt-get install perlbrew    # Debian/Ubuntu
   brew install perlbrew             # macOS
   # Or use your distribution's package manager

   # Or install via cpanm
   cpanm App::perlbrew
   ```

2. Initialize perlbrew in your shell:
   ```bash
   # Initialize perlbrew
   perlbrew init
   # Add to your ~/.bashrc or ~/.zshrc
   source ~/perl5/perlbrew/etc/bashrc
   ```

3. Install a Perl version (if needed):
   ```bash
   perlbrew install perl-5.36.0
   perlbrew switch perl-5.36.0
   ```

4. Install cpanm via perlbrew:
   ```bash
   perlbrew install-cpanm
   ```

5. Reload your shell configuration:
   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

#### Project-Specific Setup

Run the bootstrap script:

```bash
./scripts/bootstrap.sh
```

The bootstrap script will:
* Detect that you're using perlbrew (checks for `perlbrew` command and active perlbrew Perl)
* Verify that `cpanm` is available (exits with error if not found)
* Generate `scripts/local-env.sh` with perlbrew-aware environment setup
* Install project dependencies automatically (if dependency files exist)

After running the bootstrap script, activate the environment:

```bash
source scripts/local-env.sh
```

**Note**: If perlbrew is already initialized in your shell, you may not need to source `scripts/local-env.sh`. However, sourcing it ensures consistency and that the correct Perl paths are set.

#### Installing Perl Modules

Perlbrew users can install modules using `cpanm` (provided by perlbrew):

```bash
# Ensure perlbrew environment is active
source scripts/local-env.sh  # if needed

# Install project dependencies
cpanm --installdeps .
```

Modules will be installed to your perlbrew-managed Perl's library directory.

---

### Choosing a Setup Method

* **Use Standard Setup** if:
  * You want project-specific dependency isolation
  * You prefer a simple, lightweight setup
  * You don't need multiple Perl versions

* **Use Perlbrew Setup** if:
  * You work with multiple Perl versions
  * You want comprehensive Perl environment management
  * You prefer perlbrew's workflow and tools

Both methods work seamlessly with the project's bootstrap script, which automatically detects your setup.

### Key CPAN Modules

Based on the implementation notes, the project will use:

* `Path::Tiny` - File path manipulation
* `File::Spec` - Portable file path operations
* `TOML::Tiny` - TOML parsing and generation
* `Data::UUID` - UUID generation
* `Time::Piece` - Date/time handling
* `DateTime` - Comprehensive date/time (if needed)
* `File::NFSLock` - Advisory file locking
* `Getopt::Long` - Command-line option parsing
* `App::Cmd` - CLI application framework (or alternatives)

**Note**: A `cpanfile` or `Makefile.PL` will be created as dependencies are finalized (see Milestone 1).

## Project Structure

```
mytask/
├── .local-lib/        # local::lib directory (dot-named for clean root)
├── bin/               # Tool scripts (the application executables)
├── scripts/           # Development scripts (e.g., local-env.sh)
├── docs/              # Documentation
├── lib/               # Perl modules (when created)
├── t/                 # Tests (when created)
├── examples/          # Example scripts/configs (when created)
├── AGENTS.md          # AI agent guidelines
├── TODO.md            # Open questions and tasks
└── README.md          # Project overview (when created)
```

### Directory Naming Conventions

To keep the root directory clean, files and directories that are not part of the core project structure should be **dot-named** (prefixed with a dot). Examples:

* **`.local-lib/`** - local::lib directory for Perl module dependencies
* **`.git/`** - Git repository metadata (standard)
* **`.gitignore`** - Git ignore patterns (standard)
* Other development artifacts should follow this pattern

### Directory Purposes

* **`bin/`** - Contains tool scripts (the actual application executables). These are the user-facing commands that will be installed or executed.
* **`scripts/`** - Contains development scripts (e.g., `local-env.sh` for setting up local development environment). These are helper scripts for developers, not part of the application itself.

## Development Workflow

### Getting Started

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd mytask
   ```

2. Run the bootstrap script:
   ```bash
   ./scripts/bootstrap.sh
   ```
   The bootstrap script automatically detects your setup (standard local::lib or perlbrew):
   * **Standard setup**: Creates `.local-lib/` directory and sets up local::lib environment
   * **Perlbrew setup**: Uses perlbrew-managed Perl and generates perlbrew-aware environment
   * Creates `scripts/local-env.sh` with the appropriate environment variables
   * Installs project dependencies (if `cpanfile`, `Makefile.PL`, or `Build.PL` exists)

3. Activate the environment:
   ```bash
   source scripts/local-env.sh
   ```
   **Important**: You must source `scripts/local-env.sh` each time you work on this project (see [Working on the Project](#working-on-the-project)).

   **Note**: For perlbrew users, if perlbrew is already initialized in your shell, you may not need to source this script. However, sourcing it ensures consistency.

4. Review documentation:
   * Start with `docs/README.md` for project overview
   * Review `docs/milestones.md` for development milestones
   * Check `docs/design-decisions.md` for key design choices
   * Review `AGENTS.md` for development guidelines

### Working on the Project

Each time you start working on the project in a new shell session, you should activate the environment:

```bash
source scripts/local-env.sh
```

**For standard setup (local::lib):**
This sets up the necessary environment variables (like `PERL5LIB`) so that Perl can find modules installed in `.local-lib/`. Without sourcing this script, Perl commands won't be able to use the project's local dependencies.

**For perlbrew setup:**
This ensures perlbrew is initialized and the correct Perl paths are set. If perlbrew is already initialized in your shell, you may not strictly need to source this, but doing so ensures consistency.

**Why manual sourcing?** The bootstrap script doesn't automatically source the environment for your shell because:
* Environment variables set in a script don't persist to your shell session
* Making it explicit helps you understand what's happening
* You'll remember to source it each time you work on the project

**Verify the environment is active:**

For standard setup, check for `PERL5LIB`:
```bash
echo $PERL5LIB
```

For perlbrew setup, verify perlbrew Perl is being used:
```bash
which perl
perl -v
```

### Working on Milestones

Each milestone has specific requirements (see `docs/milestones.md`):

1. **Documentation**: Complete documentation before implementation
2. **Tests**: Write tests as you implement (test framework TBD)
3. **Implementation**: Working code that satisfies milestone requirements
4. **Versioning**: Follow versioning guidelines (minor for milestones 1-5, major for milestone 6+)

### Code Style

Follow Perl best practices:

* Use `strict` and `warnings`
* Follow consistent indentation (spaces or tabs - to be decided)
* Write clear, readable code over clever optimizations
* Document complex logic with comments
* Follow repository naming conventions (see `AGENTS.md`)

## Testing

**Status**: Testing framework to be determined (see TODO.md - Testing Strategy)

Once a testing framework is chosen, tests will be located in the `t/` directory and run pattern:
* `t/*.t` - Test files
* Use standard Perl testing conventions

## Building and Packaging

**Status**: Build system to be determined

Future considerations:
* `Makefile.PL` or `Build.PL` for module installation
* `cpanfile` for dependency management
* Fatpacking or PAR::Packer for standalone executables (if desired)

## Documentation

Documentation is maintained in the `docs/` directory:

* **README.md** - Project overview and entry point
* **milestones.md** - Development milestones
* **design-decisions.md** - Key design decisions
* **data-model.md** - Task data structure
* **architecture.md** - System architecture
* **cli-design.md** - CLI interface specification
* **implementation-notes.md** - Implementation language and tools
* **migration.md** - Migration and export documentation
* **DEVELOPMENT.md** - This file

Documentation follows these principles:
* Word wrapping at 78 columns in Markdown and comments
* Clear, practical examples
* Consistent terminology

## Contributing

For detailed contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

Quick reference:
* Follow milestone structure (see `docs/milestones.md`)
* Write tests for all code changes
* Update documentation as you implement features
* Follow guidelines in `AGENTS.md`

## Future Development Environment Updates

As milestones are completed, this document will be updated to include:

* **Milestone 1**: Task file format examples and validation tools
* **Milestone 2**: CLI command structure and testing
* **Milestone 3**: Configuration file examples and validation
* **Milestone 4**: Hook script examples and testing framework
* **Later milestones**: Additional tools and processes as needed

---

**Note**: This is a living document. Update it as the development environment evolves and new tools or processes are established.

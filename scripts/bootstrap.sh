#!/usr/bin/env bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Detect if perlbrew is being used
PERLBREW_DETECTED=false
if command -v perlbrew >/dev/null 2>&1; then
  # Check if perlbrew is initialized and active
  if [ -n "${PERLBREW_ROOT:-}" ] || [ -n "${PERLBREW_HOME:-}" ] || perlbrew list >/dev/null 2>&1; then
    # Check if current Perl is managed by perlbrew
    PERL_PATH=$(command -v perl)
    if [ -n "$PERL_PATH" ] && [[ "$PERL_PATH" == *"perlbrew"* ]]; then
      PERLBREW_DETECTED=true
    fi
  fi
fi

if [ "$PERLBREW_DETECTED" = true ]; then
  # Perlbrew setup
  echo "Detected perlbrew environment."
  echo "Using perlbrew-managed Perl: $(perl -v | head -2 | tail -1)"
  
  # Generate perlbrew-aware environment script
  cat > "$PROJECT_ROOT/scripts/local-env.sh" << 'ENVEOF'
#!/usr/bin/env bash
# Environment setup for perlbrew users
# This script ensures perlbrew is initialized if needed

# Initialize perlbrew if not already done
if [ -z "${PERLBREW_ROOT:-}" ]; then
  if [ -s "$HOME/perl5/perlbrew/etc/bashrc" ]; then
    source "$HOME/perl5/perlbrew/etc/bashrc"
  fi
elif [ -s "$PERLBREW_ROOT/etc/bashrc" ]; then
  source "$PERLBREW_ROOT/etc/bashrc"
fi

# Ensure perlbrew Perl is in PATH (if perlbrew is available)
if command -v perlbrew >/dev/null 2>&1; then
  # Get the currently active perlbrew Perl version
  ACTIVE_PERL=$(perlbrew list 2>/dev/null | grep '^\s*\*' | awk '{print $NF}' | head -1)
  if [ -n "$ACTIVE_PERL" ] && [ -d "$PERLBREW_ROOT/perls/$ACTIVE_PERL/bin" ]; then
    export PATH="$PERLBREW_ROOT/perls/$ACTIVE_PERL/bin:$PATH"
  fi
fi
ENVEOF
  
  # Check for cpanm (perlbrew users should install it via perlbrew)
  if ! command -v cpanm >/dev/null 2>&1; then
    echo "Error: cpanm not found."
    echo "Please install cpanm using: perlbrew install-cpanm"
    exit 1
  fi
  
  # Source the environment for this script
  # shellcheck disable=SC1090
  source "$PROJECT_ROOT/scripts/local-env.sh"
  
else
  # Standard local::lib setup
  LOCAL_LIB_DIR="$PROJECT_ROOT/.local-lib"
  
  echo "Using standard local::lib setup."
  echo "Using local::lib at: $LOCAL_LIB_DIR"
  
  # Ensure local::lib exists and generate env snippet
  perl -Mlocal::lib="$LOCAL_LIB_DIR" -e1
  
  # Capture the env exports into scripts/local-env.sh (overwrites each time)
  # Use setup_env_hash to set environment, then capture the variables
  perl -Mlocal::lib="$LOCAL_LIB_DIR" \
    -e 'local::lib->setup_env_hash("'"$LOCAL_LIB_DIR"'"); 
        print "export PERL_LOCAL_LIB_ROOT=\"$ENV{PERL_LOCAL_LIB_ROOT}\"\n" if $ENV{PERL_LOCAL_LIB_ROOT};
        if ($ENV{PERL_MB_OPT}) {
          my $opt = $ENV{PERL_MB_OPT};
          $opt =~ s/"/\\"/g;
          print "export PERL_MB_OPT=\"$opt\"\n";
        }
        if ($ENV{PERL_MM_OPT}) {
          my $opt = $ENV{PERL_MM_OPT};
          $opt =~ s/"/\\"/g;
          print "export PERL_MM_OPT=\"$opt\"\n";
        }
        print "export PERL5LIB=\"$ENV{PERL5LIB}\"\n" if $ENV{PERL5LIB};
        my $path = $ENV{PATH};
        if ($path && index($path, "'"$LOCAL_LIB_DIR"'/bin") == -1) {
          print "export PATH=\"'"$LOCAL_LIB_DIR"'/bin:$path\"\n";
        } elsif ($path) {
          print "export PATH=\"$path\"\n";
        }' \
    > "$PROJECT_ROOT/scripts/local-env.sh"
  
  # Load the env for this script's execution (so cpanm installs into local-lib)
  # Note: This does NOT affect your shell - you must source scripts/local-env.sh manually
  # shellcheck disable=SC1090
  source "$PROJECT_ROOT/scripts/local-env.sh"
  
  # Check for cpanm (users should install it via their system package manager or preferred method)
  if ! command -v cpanm >/dev/null 2>&1; then
    echo "Error: cpanm not found."
    echo "Please install cpanm using your system package manager or preferred method."
    echo "For example: sudo apt-get install cpanminus  # Debian/Ubuntu"
    echo "              brew install cpanminus          # macOS"
    exit 1
  fi
fi

# Install project deps
if [ -f "$PROJECT_ROOT/cpanfile" ]; then
  cpanm --installdeps "$PROJECT_ROOT"
elif [ -f "$PROJECT_ROOT/Makefile.PL" ] || [ -f "$PROJECT_ROOT/Build.PL" ]; then
  cpanm .
else
  echo "No cpanfile / Makefile.PL / Build.PL found; nothing to install."
fi

echo ""
echo "Bootstrap complete."
echo ""

if [ "$PERLBREW_DETECTED" = true ]; then
  echo "Perlbrew environment detected. To activate the environment, run:"
  echo "  source scripts/local-env.sh"
  echo ""
  echo "Note: If perlbrew is already initialized in your shell, you may not need"
  echo "to source this script. However, sourcing it ensures consistency."
else
  echo "To activate the local::lib environment, run:"
  echo "  source scripts/local-env.sh"
  echo ""
  echo "You must source scripts/local-env.sh each time you work on this project."
fi

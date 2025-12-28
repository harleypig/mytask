.PHONY: all test test-file tidy prove critic testall clean help

# Default target
all: test

# Run all tests via helper (defaults: -l with dynamic jobs)
test:
	@echo "Running tests..."
	@scripts/run-perl-prove.sh

# Format Perl sources (perltidy)
tidy:
	@echo "Running perltidy on Perl sources..."
	@FILES=$$(git ls-files '*.pl' '*.pm' '*.t' '*.psgi' '*.PL'); \
	if [ -n "$$FILES" ]; then \
	  scripts/run-perltidy.sh $$FILES; \
	else \
	  echo "No Perl files found"; \
	fi

# Run perlcritic on Perl sources
critic:
	@echo "Running perlcritic on Perl sources..."
	@scripts/run-perlcritic.sh lib t

# Run prove via helper script (respects local env)
prove:
	@echo "Running prove (via scripts/run-perl-prove.sh)..."
	@scripts/run-perl-prove.sh

# Run tidy, prove, and critic
testall: tidy prove critic
	@echo "Completed tidy, prove, and critic"

# Run specific test file (usage: make test-file FILE=t/01-format-schema.t)
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=t/01-format-schema.t"; \
		exit 1; \
	fi
	@scripts/run-perl-prove.sh $(FILE)

# Clean temporary files
clean:
	@echo "Cleaning..."
	@find . -type f -name "*.bak" -delete
	@find . -type f -name "*~" -delete
	@find . -type d -name ".build" -exec rm -rf {} + 2>/dev/null || true

# Help target
help:
	@echo "Available targets:"
	@echo "  make test          - Run all tests"
	@echo "  make test-file FILE=t/01-format-schema.t - Run specific test file"
	@echo "  make tidy          - Run perltidy on Perl sources"
	@echo "  make prove         - Run test suite via scripts/run-perl-prove.sh"
	@echo "  make critic        - Run perlcritic on lib/ and t/"
	@echo "  make testall       - Run tidy, prove, and critic"
	@echo "  make clean         - Remove temporary files"
	@echo "  make help          - Show this help message"


.PHONY: test test-verbose test-parallel clean

# Default target
all: test

# Run all tests
test:
	@echo "Running tests..."
	@prove -l t/

# Run tests with verbose output
test-verbose:
	@echo "Running tests (verbose)..."
	@prove -lv t/

# Run tests in parallel
test-parallel:
	@echo "Running tests (parallel)..."
	@prove -j4 -l t/

# Run specific test file (usage: make test-file FILE=t/01-format-schema.t)
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=t/01-format-schema.t"; \
		exit 1; \
	fi
	@prove -l $(FILE)

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
	@echo "  make test-verbose  - Run tests with verbose output"
	@echo "  make test-parallel - Run tests in parallel (4 jobs)"
	@echo "  make test-file FILE=t/01-format-schema.t - Run specific test file"
	@echo "  make clean         - Remove temporary files"
	@echo "  make help          - Show this help message"


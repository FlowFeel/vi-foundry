.PHONY: test unit integration regression lint all clean

# Lint (static analysis)
lint:
	Rscript -e "lintr::lint_package()"

# Pure unit tests (no Docker, 0ms)
unit:
	Rscript run_tests.R unit

# Integration (testcontainers simulacrum + BDD)
integration:
	docker compose -f compose/docker-compose.test.yml up --abort-on-container-exit --exit-code-from verifier

# Regression (baseline oracle comparison)
regression:
	python tests/compare_baseline.py --tolerance 0.001 --baseline baseline --output test-output

# Full run
all: lint unit integration regression

# Clean
clean:
	rm -rf test-output/
	docker compose -f compose/docker-compose.test.yml down -v 2>/dev/null || true

.PHONY: test lint unit simulacra integration regression verify docker-stack all clean \
	charts charts-refresh charts-test


# Lint (static analysis)
lint:
	Rscript -e "lintr::lint_package()"

# Pure unit tests (no Docker, 0ms)
unit:
	Rscript run_tests.R unit

# Simulacrum parameter-recovery tests (STDD)
simulacra:
	Rscript run_tests.R simulacra
	Rscript scripts/run_simulacra.R --n-sims 20

# End-to-end integration tests (BDD scenarios as testthat)
integration:
	Rscript run_tests.R integration

# Regression gate: compare pipeline output to the baseline oracle (testthat)
regression:
	Rscript run_tests.R regression

# Full Docker simulacrum stack: r-runtime runs the simulacra + integration
# gates in a containerized environment (with Postgres for the DB round-trip),
# verifier confirms. Requires Docker.
docker-stack:
	docker compose -f compose/docker-compose.test.yml up --abort-on-container-exit --exit-code-from verifier

# Strict baseline comparison via the independent Python verifier. Produces
# test-output/results.yml and compares to baseline/oracle.yml. Reports
# divergences until the bundled data is reconciled (review items 4-6).
verify:
	Rscript scripts/run_pipeline.R --output test-output
	python3 tests/compare_baseline.py --tolerance 0.001 --baseline baseline --output test-output

# Chart pipeline (see charts/charts.yml)
# Verify every committed figure reproduces byte-identical to its blessed hash.
# Non-mutating: regenerates into a scratch dir and restores the working tree.
charts:
	python3 scripts/fetch_external_data.py
	python3 scripts/render_charts.py
	python3 -m pytest tests/test_charts.py -q

# Bless intentional figure changes: regenerate in place, update expected_sha256
# in charts/charts.yml. Commit charts.yml + the regenerated PNGs together.
charts-refresh:
	python3 scripts/render_charts.py --refresh

# Run just the chart test suite (determinism/conformance/baseline/freshness)
charts-test:
	python3 -m pytest tests/test_charts.py -q

# All testthat gates + lint (no Docker required)
all: lint unit simulacra integration regression

clean:
	rm -rf test-output/
	docker compose -f compose/docker-compose.test.yml down -v 2>/dev/null || true

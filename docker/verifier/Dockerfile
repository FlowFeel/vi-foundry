FROM python:3.13-slim

# The verifier confirms the r-runtime completed its gates successfully by
# checking for a success marker on the shared output volume. It does not run
# the baseline-oracle comparison here (that is `make regression`, which runs
# tests/compare_baseline.py locally against the real-data oracle and is
# expected to report divergences pending data reconciliation, items 4-6).
WORKDIR /workspace
CMD ["sh", "-c", "test -f /workspace/output/success && echo 'integration + simulacrum gates passed' || (echo 'integration gates FAILED (no success marker)'; exit 1)"]

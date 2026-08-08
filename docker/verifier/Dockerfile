FROM python:3.13-slim

RUN pip install --no-cache-dir pyyaml

COPY tests/compare_baseline.py /workspace/compare_baseline.py

WORKDIR /workspace
CMD ["python", "compare_baseline.py", "--tolerance", "0.001", \
     "--baseline", "/workspace/baseline", \
     "--output", "/workspace/output"]

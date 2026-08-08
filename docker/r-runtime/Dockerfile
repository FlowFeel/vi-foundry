FROM rocker/r-ver:4.4.3

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('DBI','RPostgres','yaml','plumber','testthat','withr','covr'), repos='https://cloud.r-project.org/')"

WORKDIR /workspace
EXPOSE 8787

COPY docker/r-runtime/health.R /workspace/health.R
CMD ["R", "-e", "plumber::plumb('/workspace/health.R')$run(host='0.0.0.0', port=8787)"]

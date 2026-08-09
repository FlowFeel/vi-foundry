FROM rocker/tidyverse:4.5.3

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('ape','caper','phytools','readxl','yaml','DBI','RPostgres','testthat','withr','roxygen2'), repos='https://cloud.r-project.org/')"

WORKDIR /workspace

# Default: a health endpoint (kept for compatibility). The compose stack
# overrides the command to install the package and run the gates.
COPY docker/r-runtime/health.R /workspace/health.R
CMD ["R", "-e", "plumber::plumb('/workspace/health.R')$run(host='0.0.0.0', port=8787)"]

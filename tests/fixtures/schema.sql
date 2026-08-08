-- Schema for simulacrum fixture data
CREATE TABLE IF NOT EXISTS species (
    species_id SERIAL PRIMARY KEY,
    species_name VARCHAR(255) NOT NULL,
    family VARCHAR(255),
    plastome_size_kb NUMERIC,
    parasitism_score INTEGER,
    genome_size_mb NUMERIC,
    ne INTEGER,
    niche_breadth NUMERIC,
    integration_depth NUMERIC
);

CREATE TABLE IF NOT EXISTS test_results (
    test_id VARCHAR(64) PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    prediction TEXT,
    competitor TEXT,
    beta NUMERIC,
    r_squared NUMERIC,
    p_value NUMERIC,
    spearman_rho NUMERIC,
    n INTEGER,
    seed INTEGER,
    converged BOOLEAN,
    elapsed_sec NUMERIC,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

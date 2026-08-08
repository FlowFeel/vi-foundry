-- Minimal seed data for simulacrum convergence testing
-- These are small, deterministic fixtures — NOT the real datasets
INSERT INTO species (species_name, family, plastome_size_kb, parasitism_score) VALUES
    ('Lindenbergia_philippensis', 'Orobanchaceae', 150.0, 0),
    ('Schwalbea_americana', 'Orobanchaceae', 120.0, 1),
    ('Orobanche_minor', 'Orobanchaceae', 100.0, 2),
    ('Phelipanche_aegyptiaca', 'Orobanchaceae', 75.0, 3),
    ('Conopholis_americana', 'Orobanchaceae', 50.0, 4);

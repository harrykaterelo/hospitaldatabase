LOAD DATA LOCAL INFILE '/Users/hariskaterelos/Documents/hospital-db-management/bussiness_rules/data/4.2 Κωδικοί ICD-10 15-12-2011 2.csv'
INTO TABLE icd
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(kodikos, perigrafi, @ignore1, @ignore2, @ignore3)
SET
    kodikos = TRIM(kodikos),
    perigrafi = TRIM(REPLACE(perigrafi, '\r', ''));
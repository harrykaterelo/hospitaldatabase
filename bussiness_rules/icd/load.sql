LOAD DATA LOCAL INFILE 'C:/Users/giann/Documents/hospitaldatabase/bussiness_rules/data/icd10.csv'
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
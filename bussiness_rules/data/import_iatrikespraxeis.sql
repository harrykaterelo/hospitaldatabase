LOAD DATA LOCAL INFILE '/Users/hariskaterelos/Documents/hospital-db-management/bussiness_rules/data/iatrikespraxeis.csv'
INTO TABLE iatrikespraxeis
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(kodikos, onoma);
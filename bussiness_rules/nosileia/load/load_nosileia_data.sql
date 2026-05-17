SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE '/Users/hariskaterelos/Documents/hospital-db-management/bussiness_rules/data/nosileia_data.csv'
INTO TABLE nosiltemp
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(nosileia_id, amka_astheni, tmima_id, ar_kliis, kod_ken, @synoliko_kostos)
SET synoliko_kostos = NULLIF(@synoliko_kostos, 'NULL');
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA LOCAL INFILE '/Users/hariskaterelos/Documents/hospital-db-management/bussiness_rules/data/tmima_mysql_ready.csv'
INTO TABLE tmima
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(onoma, perigrafi, arithmos_klinon, orofos_ktiriou, amka_dieftinti, tmima_id);




SELECT 'LOADED DEPARTMENTS INTO DATABASE...' AS msg;



DELIMITER //

DROP PROCEDURE IF EXISTS add_asthenis //

CREATE PROCEDURE add_asthenis(
    IN p_amka                CHAR(11),
    IN p_onoma               VARCHAR(50),
    IN p_eponymo             VARCHAR(50),
    IN p_ilikia              SMALLINT,
    IN p_email               VARCHAR(100),
    IN p_tilefono            VARCHAR(15),
    IN p_patronymo           VARCHAR(50),
    IN p_fylo                VARCHAR(10),
    IN p_varos               DECIMAL(5,2),
    IN p_ypsos               DECIMAL(5,2),
    IN p_diefthinsi          VARCHAR(200),
    IN p_epangelma           VARCHAR(100),
    IN p_ypikoiotita         VARCHAR(50),
    IN p_asfalistikos_foreas VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT IGNORE INTO anthropos (amka, onoma, eponymo, ilikia, email, tilefono)
    VALUES (p_amka, p_onoma, p_eponymo, p_ilikia, p_email, p_tilefono);

    INSERT INTO asthenis (amka, patronymo, fylo, varos, ypsos, diefthinsi, epangelma, ypikoiotita, asfalistikos_foreas)
    VALUES (p_amka, p_patronymo, p_fylo, p_varos, p_ypsos, p_diefthinsi, p_epangelma, p_ypikoiotita, p_asfalistikos_foreas);

    COMMIT;
END //

DELIMITER ;

DELIMITER //

DROP PROCEDURE IF EXISTS add_diagnosi //

CREATE PROCEDURE add_diagnosi(
    IN p_nosileia_id     INT,
    IN p_icd             VARCHAR(10),
    IN p_tipos_diagnosis VARCHAR(20),
    IN p_imerominia      DATE
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    INSERT INTO diagnosi (nosileia_id, icd, tipos_diagnosis, imerominia)
    VALUES (p_nosileia_id, p_icd, p_tipos_diagnosis, p_imerominia);
    COMMIT;
END //

DELIMITER ;

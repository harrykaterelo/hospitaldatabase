DELIMITER //
 
DROP PROCEDURE IF EXISTS add_diagnosi //
 
CREATE PROCEDURE add_diagnosi(
    IN p_nosileia_id     INT,
    IN p_icd             VARCHAR(10),
    IN p_tipos_diagnosis VARCHAR(20)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
 
    START TRANSACTION;
    INSERT IGNORE INTO diagnosi (nosileia_id, icd, tipos_diagnosis)
    VALUES (p_nosileia_id, p_icd, p_tipos_diagnosis);
    COMMIT;
END //
 
DELIMITER ;
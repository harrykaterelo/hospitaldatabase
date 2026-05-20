DELIMITER //
 
DROP PROCEDURE IF EXISTS add_klini //
 
CREATE PROCEDURE add_klini(
    IN p_tmima_id   INT,
    IN p_ar_kliis   SMALLINT,
    IN p_typos      VARCHAR(30),
    IN p_katastasi  VARCHAR(30)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
 
    START TRANSACTION;
    INSERT IGNORE INTO klini (tmima_id, ar_kliis, typos, katastasi)
    VALUES (p_tmima_id, p_ar_kliis, p_typos, p_katastasi);
    COMMIT;
END //
 
DELIMITER ;
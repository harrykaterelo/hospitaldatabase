DELIMITER //

DROP PROCEDURE IF EXISTS add_nosileia //

CREATE PROCEDURE add_nosileia(
    IN p_amka_astheni   CHAR(11),
    IN p_tmima_id       INT,
    IN p_ar_kliis       SMALLINT,
    IN p_kod_ken        VARCHAR(20)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    INSERT INTO nosileia (amka_astheni, tmima_id, ar_kliis, kod_ken)
    VALUES (p_amka_astheni, p_tmima_id, p_ar_kliis, p_kod_ken);
    COMMIT;
END //

DELIMITER ;

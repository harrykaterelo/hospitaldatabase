DELIMITER //

DROP PROCEDURE IF EXISTS register_nosileia //

CREATE PROCEDURE register_nosileia(
    IN  p_amka_astheni       CHAR(11),
    IN  p_tmima_id           INT,
    IN  p_ar_kliis           SMALLINT,
    IN  p_kod_ken            VARCHAR(20),
    IN  p_icd                VARCHAR(10),
    IN  p_imerominia_eisodou DATE,
    OUT p_nosileia_id        INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO nosileia (amka_astheni, tmima_id, ar_kliis, kod_ken, imerominia_eisodou)
    VALUES (p_amka_astheni, p_tmima_id, p_ar_kliis, p_kod_ken, p_imerominia_eisodou);

    SET p_nosileia_id = LAST_INSERT_ID();

    INSERT INTO diagnosi (nosileia_id, icd, tipos_diagnosis)
    VALUES (p_nosileia_id, p_icd, 'Εισοδος');

    COMMIT;
END //

DELIMITER ;

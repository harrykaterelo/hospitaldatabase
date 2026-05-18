DELIMITER //

DROP PROCEDURE IF EXISTS add_nosileia //

CREATE PROCEDURE add_nosileia(
    IN p_amka_astheni        CHAR(11),
    IN p_tmima_id            INT,
    IN p_ar_kliis            SMALLINT,
    IN p_kod_ken             VARCHAR(20),
    IN p_imerominia_eisodou  DATE,
    IN p_icd_eisodou         VARCHAR(10),
    IN p_imerominia_eksodou  DATE,
    IN p_icd_eksodou         VARCHAR(10)
)
BEGIN
    DECLARE v_nosileia_id INT;
    DECLARE v_ar_kliis SMALLINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    /*
      Case 1:
      If imerominia_eksodou IS NOT NULL,
      this is a completed nosileia, so use the bed number passed in params.
    */
    IF p_imerominia_eksodou IS NOT NULL THEN

        IF p_ar_kliis IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ar_kliis is required when imerominia_eksodou is not NULL';
        END IF;

        SET v_ar_kliis = p_ar_kliis;

    /*
      Case 2:
      If imerominia_eksodou IS NULL,
      this is an active nosileia, so find an available bed automatically.
    */
    ELSE

        SELECT dk.ar_kliis
        INTO v_ar_kliis
        FROM diathesimes_klines dk
        WHERE dk.tmima_id = p_tmima_id
        ORDER BY RAND()
        LIMIT 1;

        IF v_ar_kliis IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No available bed found for this tmima';
        END IF;

    END IF;

    INSERT INTO nosileia (
        amka_astheni,
        tmima_id,
        ar_kliis,
        kod_ken,
        imerominia_eisodou,
        imerominia_eksodou
    )
    VALUES (
        p_amka_astheni,
        p_tmima_id,
        v_ar_kliis,
        p_kod_ken,
        p_imerominia_eisodou,
        p_imerominia_eksodou
    );

    SET v_nosileia_id = LAST_INSERT_ID();

    /*
      Always add diagnosis Εισοδος
    */
    INSERT INTO diagnosi (
        nosileia_id,
        icd,
        tipos_diagnosis
    )
    VALUES (
        v_nosileia_id,
        p_icd_eisodou,
        'Εισοδος'
    );

    /*
      Add diagnosis Εξοδος only if the nosileia has imerominia_eksodou
    */
    IF p_imerominia_eksodou IS NOT NULL THEN

        INSERT INTO diagnosi (
            nosileia_id,
            icd,
            tipos_diagnosis
        )
        VALUES (
            v_nosileia_id,
            p_icd_eksodou,
            'Εξοδος'
        );

    END IF;

    COMMIT;

    SELECT v_nosileia_id AS nosileia_id, v_ar_kliis AS ar_kliis;

END //

DELIMITER ;
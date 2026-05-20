DELIMITER //

DROP PROCEDURE IF EXISTS register_dialogi //

CREATE PROCEDURE register_dialogi(
    IN p_amka_astheni    CHAR(11),
    IN p_wra_afiksis     DATETIME,
    IN p_symptomata      TEXT,
    IN p_epipedo         TINYINT,
    IN p_apotelesma      VARCHAR(20),
    IN p_odigies         TEXT,
    IN p_wra_oloklirosis DATETIME
)
BEGIN
    DECLARE v_amka_nosilevti CHAR(11);

    /*
      Pick a random nurse automatically.
      This assumes nosileutis has column amka.
    */
    SELECT e.amka_proswpiko
        INTO v_amka_nosilevti
        FROM efimeria_se_kathikon_triage e
        JOIN vardia v
        ON v.vardia_id = e.vardia
        WHERE p_wra_afiksis >= TIMESTAMP(DATE(e.imerominia), v.vardia_ora_ekkinisis)
        AND p_wra_afiksis < CASE
            WHEN v.vardia_ora_lixis > v.vardia_ora_ekkinisis THEN
                TIMESTAMP(DATE(e.imerominia), v.vardia_ora_lixis)
            ELSE
                TIMESTAMP(DATE(e.imerominia) + INTERVAL 1 DAY, v.vardia_ora_lixis)
        END
        ORDER BY RAND()
        LIMIT 1;

    IF v_amka_nosilevti IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No nosileutis found for register_dialogi';
    END IF;

    INSERT INTO dialogistoixeiwn (
        amka_astheni,
        amka_nosilevti,
        wra_afiksis,
        symptomata,
        epipedo,
        apotelesma,
        odigies,
        wra_oloklirosis
    )
    VALUES (
        p_amka_astheni,
        v_amka_nosilevti,
        p_wra_afiksis,
        p_symptomata,
        p_epipedo,
        p_apotelesma,
        p_odigies,
        p_wra_oloklirosis
    );
END //

DELIMITER ;
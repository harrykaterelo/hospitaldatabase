DELIMITER //

DROP PROCEDURE IF EXISTS generate_syntagografiseis //

CREATE PROCEDURE generate_syntagografiseis()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE insert_failed INT DEFAULT 0;

    DECLARE v_nosileia_id     INT;
    DECLARE v_amka_astheni    CHAR(11);
    DECLARE v_imer_eisodou    DATE;
    DECLARE v_imer_eksodou    DATE;
    DECLARE v_num             INT;
    DECLARE v_imer_enarksis   DATE;
    DECLARE v_imer_liksis     DATE;
    DECLARE v_amka_iatrou     CHAR(11);
    DECLARE v_kod_ema         INT;
    DECLARE v_dosologia       VARCHAR(200);
    DECLARE v_syxnotita       VARCHAR(100);
    DECLARE v_diarkeia_days   INT;
    DECLARE i                 INT;

    DECLARE cur CURSOR FOR
        SELECT 
            nosileia_id, 
            amka_astheni, 
            imerominia_eisodou, 
            imerominia_eksodou
        FROM nosileia;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET insert_failed = 1;
    END;

    OPEN cur;

    read_loop: LOOP

        FETCH cur INTO 
            v_nosileia_id, 
            v_amka_astheni, 
            v_imer_eisodou, 
            v_imer_eksodou;

        IF done = 1 THEN 
            LEAVE read_loop; 
        END IF;

        SET v_num = FLOOR(RAND() * 6);

        IF v_num > 0 THEN

            SET v_diarkeia_days = DATEDIFF(
                COALESCE(v_imer_eksodou, CURDATE()), 
                v_imer_eisodou
            );

            SET i = 0;

            inner_loop: WHILE i < v_num DO

                SET insert_failed = 0;

                SET v_imer_enarksis = DATE_ADD(
                    v_imer_eisodou, 
                    INTERVAL FLOOR(RAND() * (v_diarkeia_days + 1)) DAY
                );

                SET v_imer_liksis = DATE_ADD(
                    v_imer_enarksis, 
                    INTERVAL FLOOR(RAND() * 10) DAY
                );

                SET v_amka_iatrou = NULL;

                SELECT ep.amka_proswpiko
                INTO v_amka_iatrou
                FROM efimeria_proswpiko ep
                JOIN iatros i_t 
                    ON i_t.amka = ep.amka_proswpiko
                WHERE ep.imerominia = v_imer_enarksis
                ORDER BY RAND()
                LIMIT 1;

                IF v_amka_iatrou IS NOT NULL THEN

                    SELECT kod_ema 
                    INTO v_kod_ema
                    FROM farmako
                    ORDER BY RAND()
                    LIMIT 1;

                    SET v_dosologia = ELT(
                        FLOOR(RAND() * 5) + 1,
                        '1 χάπι', 
                        '2 χάπια', 
                        '5 ml', 
                        '10 ml', 
                        '1 σταγόνα'
                    );

                    SET v_syxnotita = ELT(
                        FLOOR(RAND() * 5) + 1,
                        '1 φορά την ημέρα', 
                        '2 φορές την ημέρα', 
                        '3 φορές την ημέρα',
                        'κάθε 8 ώρες', 
                        'κάθε 12 ώρες'
                    );

                    INSERT IGNORE INTO syntagografisi (
                        nosileia_id, 
                        kod_ema, 
                        amka_iatrou, 
                        amka_astheni,
                        imer_enarksis, 
                        dosologia, 
                        syxnotita, 
                        imer_liksis
                    )
                    VALUES (
                        v_nosileia_id, 
                        v_kod_ema, 
                        v_amka_iatrou, 
                        v_amka_astheni,
                        v_imer_enarksis, 
                        v_dosologia, 
                        v_syxnotita, 
                        v_imer_liksis
                    );

                    -- Optional: do something if the trigger rejected it
                    IF insert_failed = 1 THEN
                        SET insert_failed = 0;
                    END IF;

                END IF;

                SET i = i + 1;

            END WHILE inner_loop;

        END IF;

    END LOOP;

    CLOSE cur;

END //

DELIMITER ;
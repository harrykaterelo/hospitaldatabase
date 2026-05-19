    SET NAMES utf8mb4;

    DELIMITER //

    DROP PROCEDURE IF EXISTS load_generated_full_seed //

    CREATE PROCEDURE load_generated_full_seed()
    BEGIN
        DECLARE done INT DEFAULT 0;

        DECLARE v_nosileia_id_seed INT;
        DECLARE v_amka_astheni CHAR(11);
        DECLARE v_tmima_id INT;
        DECLARE v_ar_kliis SMALLINT;
        DECLARE v_kod_ken VARCHAR(20);
        DECLARE v_imerominia_eisodou DATETIME;
        DECLARE v_imerominia_eksodou DATETIME;
        DECLARE v_icd_eisodou VARCHAR(10);
        DECLARE v_icd_eksodou VARCHAR(10);

        DECLARE v_has_iatriki_praxi TINYINT;
        DECLARE v_iatriki_praxi_date DATETIME;
        DECLARE v_amka_iatrou CHAR(11);
        DECLARE v_vardia_onoma VARCHAR(100);

        DECLARE v_new_nosileia_id INT;
        DECLARE v_final_ar_kliis SMALLINT;

        DECLARE v_praxi_kodikos VARCHAR(20);
        DECLARE v_kod_xwrou VARCHAR(20);
        DECLARE v_praxi_onoma VARCHAR(200);
        DECLARE v_praxi_katigoria VARCHAR(30);
        DECLARE v_praxi_diarkeia_lepta SMALLINT;
        DECLARE v_praxi_kostos DECIMAL(10,2);

        DECLARE cur CURSOR FOR
            SELECT
                nosileia_id_seed,
                amka_astheni,
                tmima_id,
                ar_kliis,
                kod_ken,
                imerominia_eisodou,
                imerominia_eksodou,
                icd_eisodou,
                icd_eksodou,
                has_iatriki_praxi,
                iatriki_praxi_date,
                amka_iatrou,
                vardia_onoma
            FROM generated_full_seed
            ORDER BY nosileia_id_seed;

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

        OPEN cur;

        read_loop: LOOP

            FETCH cur INTO
                v_nosileia_id_seed,
                v_amka_astheni,
                v_tmima_id,
                v_ar_kliis,
                v_kod_ken,
                v_imerominia_eisodou,
                v_imerominia_eksodou,
                v_icd_eisodou,
                v_icd_eksodou,
                v_has_iatriki_praxi,
                v_iatriki_praxi_date,
                v_amka_iatrou,
                v_vardia_onoma;

            IF done = 1 THEN
                LEAVE read_loop;
            END IF;

            BEGIN
                DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
                BEGIN
                    ROLLBACK;
                END;

                START TRANSACTION;

                CALL add_nosileia_from_seed(
                v_amka_astheni,
                v_tmima_id,
                v_ar_kliis,
                v_kod_ken,
                DATE(v_imerominia_eisodou),
                v_icd_eisodou,
                DATE(v_imerominia_eksodou),
                v_icd_eksodou,
                v_new_nosileia_id,
                v_final_ar_kliis
            );

            IF v_has_iatriki_praxi = 1 AND v_amka_iatrou IS NOT NULL THEN

                /*
                Fixed/generated values for missing iatrikipraxi columns.
                Change these defaults if you want different seed behavior.
                */

                SET v_praxi_kodikos = CONCAT(
                'PRAXI-',
                v_new_nosileia_id,
                '-',
                LPAD(FLOOR(RAND() * 1000000), 6, '0')
            );

                SELECT xe.kodikos
                INTO v_kod_xwrou
                FROM xwros_epembasis xe
                ORDER BY RAND()
                LIMIT 1;

                IF v_kod_xwrou IS NULL THEN
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'No xwros_epembasis found for iatriki praxi';
                END IF;

                SET v_praxi_onoma = COALESCE(v_vardia_onoma, 'Generated Ιατρική Πράξη');
                SET v_praxi_katigoria = 'Θεραπευτική';
                SET v_praxi_diarkeia_lepta = 60;
                SET v_praxi_kostos = 250.00;

                INSERT INTO iatrikipraxi (
                    kodikos,
                    nosileia_id,
                    amka_kyriou_xeirourgou,
                    kod_xwrou,
                    onoma,
                    katigoria,
                    diarkeia_lepta,
                    kostos,
                    imerominia_wra
                )
                VALUES (
                    v_praxi_kodikos,
                    v_new_nosileia_id,
                    v_amka_iatrou,
                    v_kod_xwrou,
                    v_praxi_onoma,
                    v_praxi_katigoria,
                    v_praxi_diarkeia_lepta,
                    v_praxi_kostos,
                    COALESCE(v_iatriki_praxi_date, v_imerominia_eisodou)
                );

            END IF;

            COMMIT;
            END;

        END LOOP;

        CLOSE cur;

    END //

    DELIMITER ;
DELIMITER //

DROP PROCEDURE IF EXISTS load_voithoi_seed //

CREATE PROCEDURE load_voithoi_seed()
BEGIN
    DECLARE done INT DEFAULT 0;

    DECLARE v_kod_praxis VARCHAR(20);
    DECLARE v_amka_voithou CHAR(11);

    DECLARE cur CURSOR FOR
        SELECT
            kod_praxis,
            amka_voithou
        FROM voithoi_seed
        ORDER BY kod_praxis, amka_voithou;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CLOSE cur;
        RESIGNAL;
    END;

    OPEN cur;

    START TRANSACTION;

    read_loop: LOOP

        FETCH cur INTO
            v_kod_praxis,
            v_amka_voithou;

        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO praxi_voithos (
            kod_praxis,
            amka_voithou
        )
        VALUES (
            v_kod_praxis,
            v_amka_voithou
        );

    END LOOP;

    COMMIT;

    CLOSE cur;

END //

DELIMITER ;
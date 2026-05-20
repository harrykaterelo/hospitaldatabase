DELIMITER //

DROP PROCEDURE IF EXISTS seed_random_axiologiseis //

CREATE PROCEDURE seed_random_axiologiseis()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_nosileia_id INT;

    DECLARE cur CURSOR FOR
        SELECT n.nosileia_id
        FROM nosileia n
        LEFT JOIN axiologisi a
            ON a.nosileia_id = n.nosileia_id
        WHERE a.nosileia_id IS NULL
        ORDER BY RAND()
        LIMIT 300;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO v_nosileia_id;

        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO axiologisi (
            nosileia_id,
            poiotita_iatr_frontidas,
            poiotita_nosileft_frontidas,
            kathariotita,
            fagito,
            synoliki_empeiria
        )
        VALUES (
            v_nosileia_id,
            FLOOR(1 + RAND() * 5),
            FLOOR(1 + RAND() * 5),
            FLOOR(1 + RAND() * 5),
            FLOOR(1 + RAND() * 5),
            FLOOR(1 + RAND() * 5)
        );

    END LOOP;

    CLOSE cur;
END //

DELIMITER ;

CALL seed_random_axiologiseis();
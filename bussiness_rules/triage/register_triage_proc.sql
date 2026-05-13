DELIMITER //

DROP PROCEDURE IF EXISTS register_triage //

-- Εγγράφει νέο ασθενή στο ΤΕΠ.
-- Επιστρέφει το id_dialogis της νέας εγγραφής μέσω OUT παραμέτρου.
CREATE PROCEDURE register_triage(
    IN  p_amka_astheni   CHAR(11),
    IN  p_amka_nosilevti CHAR(11),
    IN  p_symptomata     TEXT,
    IN  p_epipedo        TINYINT,
    OUT p_id_dialogis    INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_epipedo NOT BETWEEN 1 AND 5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Το επίπεδο επείγοντος πρέπει να είναι μεταξύ 1 και 5.';
    END IF;

    START TRANSACTION;

    INSERT INTO dialogistoixeiwn
        (amka_astheni, amka_nosilevti, wra_afiksis, symptomata, epipedo)
    VALUES
        (p_amka_astheni, p_amka_nosilevti, NOW(), p_symptomata, p_epipedo);

    SET p_id_dialogis = LAST_INSERT_ID();

    COMMIT;
END //

DELIMITER ;

DELIMITER //

DROP PROCEDURE IF EXISTS complete_triage //

-- Ολοκληρώνει διαλογή:
--   p_apotelesma = 'Αποχώρηση' → ασθενής παίρνει οδηγίες και φεύγει
--   p_apotelesma = 'Παραπομπή' → παραπομπή για νοσηλεία
CREATE PROCEDURE complete_triage(
    IN p_id_dialogis     INT,
    IN p_apotelesma      VARCHAR(20),
    IN p_odigies         TEXT,
    IN p_wra_oloklirosis DATETIME
)
BEGIN
    DECLARE v_current_apotelesma VARCHAR(20);
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = TRUE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT apotelesma INTO v_current_apotelesma
    FROM dialogistoixeiwn
    WHERE id_dialogis = p_id_dialogis
    FOR UPDATE;

    IF v_not_found THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Δεν βρέθηκε εγγραφή διαλογής με αυτό το id.';
    END IF;

    -- Αποτρέπουμε διπλή ολοκλήρωση
    IF v_current_apotelesma IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η διαλογή έχει ήδη ολοκληρωθεί.';
    END IF;

    UPDATE dialogistoixeiwn
    SET
        apotelesma      = p_apotelesma,
        odigies         = p_odigies,
        wra_oloklirosis = p_wra_oloklirosis
    WHERE id_dialogis = p_id_dialogis;

    COMMIT;
END //

DELIMITER ;

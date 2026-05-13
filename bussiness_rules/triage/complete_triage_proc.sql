DELIMITER //

DROP PROCEDURE IF EXISTS complete_triage //

-- Ολοκληρώνει διαλογή:
--   p_apotelesma = 'Αποχώρηση' → ασθενής παίρνει οδηγίες και φεύγει
--                                  (p_odigies συμπληρώνεται, p_nosileia_id = NULL)
--   p_apotelesma = 'Παραπομπή' → παραπομπή για νοσηλεία
--                                  (p_odigies = NULL, p_nosileia_id απαιτείται)
CREATE PROCEDURE complete_triage(
    IN p_id_dialogis  INT,
    IN p_apotelesma   VARCHAR(20),
    IN p_odigies      TEXT,
    IN p_nosileia_id  INT
)
BEGIN
    DECLARE v_current_apotelesma VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Έλεγχος εγκυρότητας αποτελέσματος
    IF p_apotelesma NOT IN ('Αποχώρηση', 'Παραπομπή') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Το αποτέλεσμα πρέπει να είναι «Αποχώρηση» ή «Παραπομπή».';
    END IF;

    START TRANSACTION;

    SELECT apotelesma INTO v_current_apotelesma
    FROM dialogistoixeiwn
    WHERE id_dialogis = p_id_dialogis
    FOR UPDATE;

    IF v_current_apotelesma IS NULL THEN
        -- Ακόμα σε αναμονή: να μην βρεθεί ήδη ολοκληρωμένη εγγραφή
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Δεν βρέθηκε εκκρεμής εγγραφή διαλογής με αυτό το id.';
    END IF;

    -- Αποτρέπουμε διπλή ολοκλήρωση
    IF v_current_apotelesma IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η διαλογή έχει ήδη ολοκληρωθεί.';
    END IF;

    -- Επιπλέον επαλήθευση συνέπειας δεδομένων
    IF p_apotelesma = 'Παραπομπή' AND p_nosileia_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Για παραπομπή απαιτείται έγκυρο nosileia_id.';
    END IF;

    IF p_apotelesma = 'Αποχώρηση' AND p_nosileia_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ασθενής που αποχωρεί δεν μπορεί να έχει παραπομπή νοσηλείας.';
    END IF;

    UPDATE dialogistoixeiwn
    SET
        apotelesma      = p_apotelesma,
        odigies         = p_odigies,
        nosileia_id     = p_nosileia_id,
        wra_oloklirosis = NOW()
    WHERE id_dialogis = p_id_dialogis;

    COMMIT;
END //

DELIMITER ;

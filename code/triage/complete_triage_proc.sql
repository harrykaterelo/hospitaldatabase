DELIMITER //

DROP PROCEDURE IF EXISTS complete_triage //

-- Ολοκληρώνει διαλογή:
--   p_apotelesma = 'Αποχώρηση' → ασθενής παίρνει οδηγίες και φεύγει
--   p_apotelesma = 'Παραπομπή' → δημιουργία ενεργής νοσηλείας +
--                                καταχώρηση στο parapobi_gia_nosileia
-- Τα παράμετροι για τη νοσηλεία είναι υποχρεωτικοί ΜΟΝΟ αν apotelesma = 'Παραπομπή'.
CREATE PROCEDURE complete_triage(
    IN p_id_dialogis     INT,
    IN p_apotelesma      VARCHAR(20),
    IN p_odigies         TEXT,
    IN p_wra_oloklirosis DATETIME,
    -- Παράμετροι νοσηλείας (χρησιμοποιούνται αν apotelesma = 'Παραπομπή')
    IN p_tmima_id            INT,
    IN p_kod_ken             VARCHAR(20),
    IN p_imerominia_eisodou  DATE,
    IN p_icd_eisodou         VARCHAR(10)
)
BEGIN
    DECLARE v_current_apotelesma VARCHAR(20);
    DECLARE v_amka_astheni       CHAR(11);
    DECLARE v_ar_kliis           SMALLINT;
    DECLARE v_nosileia_id        INT;
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = TRUE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT apotelesma, amka_astheni
    INTO v_current_apotelesma, v_amka_astheni
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

    -- Αν παραπομπή, δημιούργησε ενεργή νοσηλεία + diagnosi εισόδου + εγγραφή στο parapobi
    IF p_apotelesma = 'Παραπομπή' THEN

        IF p_tmima_id IS NULL
           OR p_kod_ken IS NULL
           OR p_imerominia_eisodou IS NULL
           OR p_icd_eisodou IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Για παραπομπή απαιτούνται tmima_id, kod_ken, imerominia_eisodou, icd_eisodou.';
        END IF;

        -- Βρες διαθέσιμη κλίνη στο τμήμα
        SET v_not_found = FALSE;

        SELECT dk.ar_kliis
        INTO v_ar_kliis
        FROM diathesimes_klines dk
        WHERE dk.tmima_id = p_tmima_id
        ORDER BY RAND()
        LIMIT 1;

        IF v_ar_kliis IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Δεν υπάρχει διαθέσιμη κλίνη στο τμήμα.';
        END IF;

        -- Δημιουργία νοσηλείας (ενεργή — χωρίς ημερομηνία εξόδου)
        INSERT INTO nosileia (
            amka_astheni,
            tmima_id,
            ar_kliis,
            kod_ken,
            imerominia_eisodou,
            imerominia_eksodou
        )
        VALUES (
            v_amka_astheni,
            p_tmima_id,
            v_ar_kliis,
            p_kod_ken,
            p_imerominia_eisodou,
            NULL
        );

        SET v_nosileia_id = LAST_INSERT_ID();

        -- Διάγνωση εισόδου
        INSERT INTO diagnosi (nosileia_id, icd, tipos_diagnosis)
        VALUES (v_nosileia_id, p_icd_eisodou, 'Εισοδος');

        -- Σύνδεση διαλογής με νοσηλεία
        INSERT INTO parapobi_gia_nosileia (id_dialogis, nosileia_id)
        VALUES (p_id_dialogis, v_nosileia_id);

    END IF;

    COMMIT;
END //

DELIMITER ;

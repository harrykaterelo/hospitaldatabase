DELIMITER //

-- =====================================================
-- TRIGGER: nosileia_insert_trigger
-- Ελέγχει πριν την εισαγωγή νοσηλείας:
--   Η κλίνη είναι διαθέσιμη
-- =====================================================
DROP TRIGGER IF EXISTS nosileia_insert_trigger //

CREATE TRIGGER nosileia_insert_trigger
BEFORE INSERT ON nosileia
FOR EACH ROW
BEGIN
    DECLARE v_klini_available INT DEFAULT 0;
    DECLARE v_existing_tmima_id INT;
    DECLARE v_existing_ar_kliis SMALLINT;

    IF EXISTS (
        SELECT 1
        FROM nosileia n
        JOIN diagnosi d_eis
            ON d_eis.nosileia_id = n.nosileia_id AND d_eis.tipos_diagnosis = 'Εισοδος'
        LEFT JOIN diagnosi d_ex
            ON d_ex.nosileia_id = n.nosileia_id AND d_ex.tipos_diagnosis = 'Εξοδος'
        WHERE n.amka_astheni = NEW.amka_astheni
        AND d_ex.nosileia_id IS NULL
        ) THEN
        SELECT n.tmima_id, n.ar_kliis
        INTO v_existing_tmima_id, v_existing_ar_kliis
        FROM nosileia n
        JOIN diagnosi d_eis
            ON d_eis.nosileia_id = n.nosileia_id AND d_eis.tipos_diagnosis = 'Εισοδος'
        LEFT JOIN diagnosi d_ex
            ON d_ex.nosileia_id = n.nosileia_id AND d_ex.tipos_diagnosis = 'Εξοδος'
        WHERE n.amka_astheni = NEW.amka_astheni
        AND d_ex.nosileia_id IS NULL
        LIMIT 1;

        SET NEW.tmima_id = v_existing_tmima_id;
        SET NEW.ar_kliis = v_existing_ar_kliis;
    ELSE
        SELECT COUNT(*)
        INTO v_klini_available
        FROM klini
        WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis AND katastasi='Διαθέσιμη';

        IF v_klini_available = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η κλίνη δεν είναι διαθέσιμη';
        END IF;
    END IF;
END //


-- =====================================================
-- TRIGGER: nosileia_after_insert_trigger
-- Μετά την εισαγωγή νοσηλείας, η κλίνη γίνεται Κατειλημμένη
-- =====================================================
DROP TRIGGER IF EXISTS nosileia_after_insert_trigger //

CREATE TRIGGER nosileia_after_insert_trigger
AFTER INSERT ON nosileia
FOR EACH ROW
BEGIN
    UPDATE klini
    SET katastasi = 'Κατειλημμένη'
    WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis;
END //


DELIMITER ;








-- =====================================================
-- TRIGGER: axiologisi_insert_trigger
-- Η αξιολόγηση επιτρέπεται μόνο μετά την έξοδο του ασθενούς
-- =====================================================
DROP TRIGGER IF EXISTS axiologisi_insert_trigger //

CREATE TRIGGER axiologisi_insert_trigger
BEFORE INSERT ON axiologisi
FOR EACH ROW
BEGIN
    DECLARE v_exodos INT DEFAULT 0;

    SELECT COUNT(*) INTO v_exodos
    FROM diagnosi
    WHERE nosileia_id = NEW.nosileia_id AND tipos_diagnosis = 'Εξοδος';

    IF v_exodos = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η αξιολόγηση μπορεί να γίνει μόνο μετά την έξοδο του ασθενούς';
    END IF;
END //
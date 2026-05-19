-- =====================================================
-- TRIGGER: axiologisi_insert_trigger
-- Η αξιολόγηση επιτρέπεται μόνο μετά την έξοδο του ασθενούς
-- =====================================================
DELIMITER //
DROP TRIGGER IF EXISTS axiologisi_insert_trigger //

CREATE TRIGGER axiologisi_insert_trigger
BEFORE INSERT ON axiologisi
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM nosileia
        WHERE nosileia_id = NEW.nosileia_id AND imerominia_eksodou IS NOT NULL
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η αξιολόγηση μπορεί να γίνει μόνο μετά την έξοδο του ασθενούς';
    END IF;
END //
DELIMITER ;
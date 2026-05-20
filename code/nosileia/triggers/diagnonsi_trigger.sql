-- =====================================================
-- TRIGGER: diagnosi_insert_trigger
-- Η διάγνωση εισόδου απαιτεί υποχρεωτικά κωδικό ICD.
-- =====================================================
DELIMITER //
DROP TRIGGER IF EXISTS diagnosi_insert_trigger //

CREATE TRIGGER diagnosi_insert_trigger
BEFORE INSERT ON diagnosi
FOR EACH ROW
BEGIN
    IF NEW.tipos_diagnosis = 'Εισοδος' AND NEW.icd IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η διάγνωση εισόδου απαιτεί κωδικό ICD';
    END IF;

    IF NEW.tipos_diagnosis = 'Εξοδος' THEN
        IF NOT EXISTS (
            SELECT 1 FROM diagnosi
            WHERE nosileia_id = NEW.nosileia_id AND tipos_diagnosis = 'Εισοδος'
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Δεν υπάρχει διάγνωση εισόδου για αυτή τη νοσηλεία';
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM nosileia
            WHERE nosileia_id = NEW.nosileia_id AND imerominia_eksodou IS NOT NULL
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η ημερομηνία εξόδου δεν έχει οριστεί στη νοσηλεία';
        END IF;
    END IF;
END //


DELIMITER ;

DELIMITER //

DROP TRIGGER IF EXISTS syntagografisi_insert_trigger //

CREATE TRIGGER syntagografisi_insert_trigger
BEFORE INSERT ON syntagografisi
FOR EACH ROW
BEGIN
    DECLARE v_allergy_conflict INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_allergy_conflict
    FROM farmako_drastiki fd
    JOIN allergy a ON a.kod_do = fd.kod_do
    WHERE fd.kod_ema       = NEW.kod_ema
      AND a.amka_astheni   = NEW.amka_astheni;

    IF v_allergy_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Απαγορεύεται η συνταγογράφηση: ο ασθενής έχει αλλεργία σε δραστική ουσία του φαρμάκου';
    END IF;
END //



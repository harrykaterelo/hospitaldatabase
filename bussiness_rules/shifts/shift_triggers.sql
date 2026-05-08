DELIMITER //

DROP TRIGGER IF EXISTS shift_trigger_insert//

CREATE TRIGGER shift_trigger_insert 
BEFORE INSERT ON efimeria_proswpiko
FOR EACH ROW
BEGIN
    DECLARE tmima_exists INT;
    DECLARE vardia_exists INT;
    DECLARE efimeria_exists INT;
    SELECT COUNT(*) INTO tmima_exists FROM tmima WHERE tmima_id = NEW.tmima;
    SELECT COUNT(*) INTO vardia_exists FROM vardia WHERE vardia_id = NEW.vardia;
    SELECT COUNT(*) INTO efimeria_exists FROM efimeria WHERE tmima = NEW.tmima AND imerominia = NEW.imerominia AND vardia = NEW.vardia;
    IF tmima_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Το τμήμα δεν υπάρχει';
    END IF;
    IF vardia_exists = 0 THEN
        INSERT INTO error_log (error_message, error_time) VALUES ('Η βάρδια δεν υπάρχει', NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Η βάρδια δεν υπάρχει';
    END IF;
    IF efimeria_exists = 0 THEN
        INSERT INTO error_log (error_message, error_time) VALUES ('Η εφημερία δεν υπάρχει', NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Η εφημερία δεν υπάρχει';
    END IF;
END //
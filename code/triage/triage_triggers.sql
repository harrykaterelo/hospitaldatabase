DELIMITER //

DROP TRIGGER IF EXISTS triage_trigger_insert //

-- Επιβεβαιώνει ότι ο νοσηλευτής που καταγράφει τη διαλογή
-- είναι όντως ο νοσηλευτής διαλογής (efimeria_se_kathikon_triage)
-- για την ημέρα/βάρδια στην οποία πέφτει το wra_afiksis.
CREATE TRIGGER triage_trigger_insert
BEFORE INSERT ON dialogistoixeiwn
FOR EACH ROW
BEGIN
    DECLARE v_imerominia DATE;
    DECLARE v_vardia INT;
    DECLARE v_triage_amka CHAR(11);
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = TRUE;

    -- 1. Βρες σε ποια βάρδια / ημερομηνία ανήκει η ώρα άφιξης
    SELECT
        CASE
            WHEN v.vardia_ora_lixis > v.vardia_ora_ekkinisis
                THEN DATE(NEW.wra_afiksis)
            WHEN TIME(NEW.wra_afiksis) >= v.vardia_ora_ekkinisis
                THEN DATE(NEW.wra_afiksis)
            ELSE DATE_SUB(DATE(NEW.wra_afiksis), INTERVAL 1 DAY)
        END,
        v.vardia_id
    INTO v_imerominia, v_vardia
    FROM vardia v
    WHERE
        (v.vardia_ora_lixis > v.vardia_ora_ekkinisis
         AND TIME(NEW.wra_afiksis) >= v.vardia_ora_ekkinisis
         AND TIME(NEW.wra_afiksis) <  v.vardia_ora_lixis)
        OR
        (v.vardia_ora_lixis <= v.vardia_ora_ekkinisis
         AND (TIME(NEW.wra_afiksis) >= v.vardia_ora_ekkinisis
              OR TIME(NEW.wra_afiksis) < v.vardia_ora_lixis))
    LIMIT 1;

    -- 2. Βρες τον ορισμένο νοσηλευτή διαλογής γι' αυτή τη βάρδια
    SET v_not_found = FALSE;

    SELECT amka_proswpiko
    INTO v_triage_amka
    FROM efimeria_se_kathikon_triage
    WHERE imerominia = v_imerominia
      AND vardia     = v_vardia;

    IF v_not_found THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Δεν έχει οριστεί νοσηλευτής διαλογής για αυτή τη βάρδια.';
    END IF;

    -- 3. Επιβεβαίωση ότι ο νοσηλευτής της εγγραφής είναι ο νοσηλευτής διαλογής
    IF v_triage_amka <> NEW.amka_nosilevti THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ο νοσηλευτής δεν είναι ο νοσηλευτής διαλογής για αυτή τη βάρδια.';
    END IF;
END //

DELIMITER ;

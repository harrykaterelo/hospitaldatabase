DELIMITER //
 
DROP TRIGGER IF EXISTS shift_trigger_insert//

CREATE TRIGGER shift_trigger_insert 
BEFORE INSERT ON efimeria_proswpiko
FOR EACH ROW
BEGIN
    DECLARE v_max_allowed INT DEFAULT 0;
    DECLARE v_monthly_count INT DEFAULT 0;

    DECLARE v_rest_hours INT DEFAULT 8;
    DECLARE v_allowed_consecutive INT;

    DECLARE v_last_shift_end DATETIME;
    DECLARE v_new_shift_start DATETIME;
    DECLARE v_hours_since_last INT;

    DECLARE v_consecutive_same_type INT DEFAULT 0;
    DECLARE msg VARCHAR(255);
    /*
      Get limits/settings for the new shift and staff type
    */
    SELECT
        COALESCE(CASE
            WHEN p.typos_proswpikou = 'Ιατρός'
                THEN er.iatros_max_monthly_ef_count
            WHEN p.typos_proswpikou = 'Νοσηλευτής'
                THEN er.nosileutes_max_monthly_ef_count
            WHEN p.typos_proswpikou = 'Διοικητικό'
                THEN er.dioikitiko_max_monthly_ef_count
            ELSE 0
        END,100000),
        v.endiamesi_ora_anapausis_hours,
        v.epitreptes_sinexomenes_vardies,
        
        TIMESTAMP(NEW.imerominia, v.vardia_ora_ekkinisis)
    INTO
        v_max_allowed,
        v_rest_hours,
        v_allowed_consecutive,
        
        v_new_shift_start
    FROM proswpiko p
    JOIN vardia v
        ON v.vardia_id = NEW.vardia
    CROSS JOIN efimeria_requirements er
    WHERE p.amka = NEW.amka_proswpiko
    LIMIT 1;
    

    /*
      1. Count shifts in same month
    */
    SELECT  COALESCE(COUNT(*),0)
    INTO v_monthly_count
    FROM efimeria_proswpiko e
    WHERE e.amka_proswpiko = NEW.amka_proswpiko
      AND YEAR(e.imerominia) = YEAR(NEW.imerominia)
      AND MONTH(e.imerominia) = MONTH(NEW.imerominia);

    IF v_monthly_count >= v_max_allowed THEN
        set msg  = 'Έχει ξεπεραστεί το μηνιαίο όριο εφημεριών';
        call add_error(msg);
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = msg;
    END IF;


    /*
      2. Get most recent previous shift end
    */
    SELECT
    CASE
        WHEN v.vardia_ora_lixis <= v.vardia_ora_ekkinisis
            THEN TIMESTAMP(DATE_ADD(e.imerominia, INTERVAL 1 DAY), v.vardia_ora_lixis)
        ELSE TIMESTAMP(e.imerominia, v.vardia_ora_lixis)
    END
INTO v_last_shift_end
FROM efimeria_proswpiko e
JOIN vardia v
    ON v.vardia_id = e.vardia
WHERE e.amka_proswpiko = NEW.amka_proswpiko
  AND TIMESTAMP(e.imerominia, v.vardia_ora_ekkinisis) < v_new_shift_start
ORDER BY
    CASE
        WHEN v.vardia_ora_lixis <= v.vardia_ora_ekkinisis
            THEN TIMESTAMP(DATE_ADD(e.imerominia, INTERVAL 1 DAY), v.vardia_ora_lixis)
        ELSE TIMESTAMP(e.imerominia, v.vardia_ora_lixis)
    END DESC
LIMIT 1;


    /*
      If there is a previous shift, check rest hours
    */
    IF v_last_shift_end IS NOT NULL THEN

        SET v_hours_since_last =
            TIMESTAMPDIFF(HOUR, v_last_shift_end, v_new_shift_start);

        IF v_hours_since_last < v_rest_hours THEN
            call add_error('Δεν υπάρχει το ελάχιστο διάστημα ανάπαυσης μεταξύ των βαρδιών');
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Δεν υπάρχει το ελάχιστο διάστημα ανάπαυσης μεταξύ των βαρδιών';
        END IF;

    END IF;


    /*
      3. Check consecutive same-type shifts.

      This checks the most recent previous shifts, in descending order.
      If the latest N previous shifts are the same type as the new one,
      then adding this new one exceeds the allowed limit.
    */
    IF v_allowed_consecutive IS NOT NULL THEN

    SELECT COUNT(*)
    INTO v_consecutive_same_type
    FROM efimeria_proswpiko e
    JOIN vardia v
        ON v.vardia_id = e.vardia
    WHERE e.amka_proswpiko = NEW.amka_proswpiko
      AND e.vardia = NEW.vardia
      AND e.imerominia IN (
          DATE_SUB(NEW.imerominia, INTERVAL 1 DAY),
          DATE_SUB(NEW.imerominia, INTERVAL 2 DAY),
          DATE_SUB(NEW.imerominia, INTERVAL 3 DAY)
      );

    IF v_consecutive_same_type >= v_allowed_consecutive THEN
        SET msg = CONCAT(
            'Έχει ξεπεραστεί το όριο συνεχόμενων νυχτερινών βαρδιών για ΑΜΚΑ ',
            NEW.amka_proswpiko
        );
        call add_error(msg);
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = msg;
    END IF;



    END IF;
END//

DROP TRIGGER IF EXISTS shift_trigger_after_insert//

CREATE TRIGGER shift_trigger_after_insert
AFTER INSERT ON efimeria_proswpiko
FOR EACH ROW
BEGIN
    IF efimeria_check(NEW.tmima, NEW.imerominia, NEW.vardia) = 1 THEN
        UPDATE efimeria
        SET statusEf = 'FINISHED'
        WHERE tmima = NEW.tmima
          AND imerominia = NEW.imerominia
          AND vardia = NEW.vardia;
    END IF;
END//

DELIMITER ;
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

    /*
      Get limits/settings for the new shift and staff type
    */
    SELECT
        CASE
            WHEN p.typos_proswpikou = 'Ιατρός'
                THEN er.iatros_max_monthly_ef_count
            WHEN p.typos_proswpikou = 'Νοσηλευτής'
                THEN er.nosileutes_max_monthly_ef_count
            WHEN p.typos_proswpikou = 'Διοικητικό'
                THEN er.dioikitiko_max_monthly_ef_count
            ELSE 0
        END,
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
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Έχει ξεπεραστεί το μηνιαίο όριο εφημεριών';
    END IF;


    /*
      2. Get most recent previous shift end
    */
    SELECT TIMESTAMP(e.imerominia, v.vardia_ora_lixis)
    INTO v_last_shift_end
    FROM efimeria_proswpiko e
    JOIN vardia v
        ON v.vardia_id = e.vardia
    WHERE e.amka_proswpiko = NEW.amka_proswpiko
      AND e.imerominia <= NEW.imerominia
    ORDER BY e.imerominia DESC, v.vardia_ora_lixis DESC
    LIMIT 1;


    /*
      If there is a previous shift, check rest hours
    */
    IF v_last_shift_end IS NOT NULL THEN

        SET v_hours_since_last =
            TIMESTAMPDIFF(HOUR, v_last_shift_end, v_new_shift_start);

        IF v_hours_since_last < v_rest_hours THEN
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
    FROM (
        SELECT v.vardia_id
        FROM efimeria_proswpiko e
        JOIN vardia v
            ON v.vardia_id = e.vardia
        WHERE e.amka_proswpiko = NEW.amka_proswpiko
          AND e.imerominia < NEW.imerominia
        ORDER BY e.imerominia DESC
        LIMIT 3
    ) AS recent_shifts
    WHERE recent_shifts.vardia_id = NEW.vardia;

    IF v_consecutive_same_type >= v_allowed_consecutive THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Έχει ξεπεραστεί το όριο συνεχόμενων βαρδιών ίδιου τύπου';
    END IF;

    END IF;
END//

DELIMITER ;
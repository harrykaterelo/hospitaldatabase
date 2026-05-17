DELIMITER //

CREATE PROCEDURE add_shift(
    IN p_tmima VARCHAR(100),
    IN p_imerominia DATE,
    IN p_vardia VARCHAR(15),
    IN p_amka_proswpiko CHAR(11)
)
BEGIN 
    DECLARE v_vardia_id INT DEFAULT NULL;
    DECLARE v_efimeria_exists INT DEFAULT 0;
    DECLARE v_tmima_id INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT vardia_id 
    INTO v_vardia_id 
    FROM vardia 
    WHERE vardia_onoma = p_vardia
    LIMIT 1;

    SELECT tmima_id 
    INTO v_tmima_id 
    FROM tmima 
    WHERE onoma = p_tmima
    LIMIT 1;

    IF v_vardia_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Η βάρδια δεν υπάρχει';
    END IF;

    IF v_tmima_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Το τμήμα δεν υπάρχει';
    END IF;
    
    START TRANSACTION;

    SELECT COUNT(*) 
    INTO v_efimeria_exists 
    FROM efimeria 
    WHERE tmima = v_tmima_id 
      AND imerominia = p_imerominia 
      AND vardia = v_vardia_id;

    IF v_efimeria_exists = 0 THEN
        INSERT INTO efimeria (tmima, imerominia, vardia) 
        VALUES (v_tmima_id, p_imerominia, v_vardia_id);
    END IF;

    INSERT INTO efimeria_proswpiko (
        tmima, 
        imerominia, 
        vardia, 
        amka_proswpiko
    ) 
    VALUES (
        v_tmima_id, 
        p_imerominia, 
        v_vardia_id, 
        p_amka_proswpiko
    );

    IF efimeria_check(v_tmima_id, p_imerominia, v_vardia_id) = 1 THEN
        UPDATE efimeria 
        SET statusEf = 'FINISHED' 
        WHERE tmima = v_tmima_id 
          AND imerominia = p_imerominia 
          AND vardia = v_vardia_id;
    END IF;

    COMMIT;
END//

DELIMITER ;
CREATE PROCEDURE add_shift(
    IN p_tmima VARCHAR(100),
    IN p_imerominia DATE,
    IN p_vardia VARCHAR(15),
    IN p_amka_proswpiko CHAR(11)
)
BEGIN 
     DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    DECLARE v_vardia_id INT;
    DECLARE v_tmima_id INT;
    SELECT vardia_id INTO v_vardia_id FROM vardia WHERE vardia_onoma = p_vardia;
    SELECT tmima_id INTO v_tmima_id FROM tmima WHERE onoma = p_tmima;
    if v_vardia_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Η βάρδια δεν υπάρχει';
    END IF;
    if v_tmima_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Το τμήμα δεν υπάρχει';
    END IF;
    DECLARE v_efimeria_exists INT;
    START TRANSACTION;
    SELECT COUNT(*) INTO v_efimeria_exists FROM efimeria 
    WHERE tmima = v_tmima_id AND imerominia  = p_imerominia AND vardia = v_vardia_id;
    if v_efimeria_exists = 0 THEN
        INSERT INTO efimeria (tmima,imerominia,vardia) VALUES (v_tmima_id, p_imerominia, v_vardia_id);
    END IF;
    INSERT INTO efimeria_proswpiko (tmima, imerominia, vardia, amka_proswpiko) VALUES (v_tmima_id, p_imerominia, v_vardia_id, p_amka_proswpiko);
    COMMIT;
END //
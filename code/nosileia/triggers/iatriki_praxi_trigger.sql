-- =====================================================
-- TRIGGER: iatrikipraxi_insert_trigger
-- Ελέγχει πριν την εισαγωγή ιατρικής πράξης:
--   1. Η ημερομηνία επέμβασης είναι εντός νοσηλείας
--   2. Δεν υπάρχει άλλη επέμβαση στον ίδιο χώρο την ίδια ώρα
--   3. Ο κύριος χειρουργός δεν συμμετέχει σε άλλη επέμβαση (ως κύριος)
--   4. Ο κύριος χειρουργός δεν είναι βοηθός σε άλλη επέμβαση την ίδια ώρα
-- =====================================================
DELIMITER //

DROP TRIGGER IF EXISTS iatrikipraxi_insert_trigger //

CREATE TRIGGER iatrikipraxi_insert_trigger
BEFORE INSERT ON iatrikipraxi
FOR EACH ROW
BEGIN
    DECLARE v_imer_eisagogis              DATE;
    DECLARE v_imer_exodou                 DATE;
    DECLARE v_space_conflict              INT DEFAULT 0;
    DECLARE v_surgeon_conflict            INT DEFAULT 0;
    DECLARE v_surgeon_as_assist_conflict  INT DEFAULT 0;
    DECLARE v_new_end                     DATETIME;

    SET v_new_end = DATE_ADD(NEW.imerominia_wra, INTERVAL NEW.diarkeia_lepta MINUTE);

    -- 1. Ημερομηνία επέμβασης εντός νοσηλείας
    SELECT imerominia_eisodou, imerominia_eksodou
    INTO v_imer_eisagogis, v_imer_exodou
    FROM nosileia
    WHERE nosileia_id = NEW.nosileia_id;

    IF DATE(NEW.imerominia_wra) < v_imer_eisagogis THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία επέμβασης είναι πριν την εισαγωγή του ασθενούς';
    END IF;

    IF v_imer_exodou IS NOT NULL AND DATE(NEW.imerominia_wra) > v_imer_exodou THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία επέμβασης είναι μετά την έξοδο του ασθενούς';
    END IF;

    -- 2. Σύγκρουση χώρου
    SELECT COUNT(*)
    INTO v_space_conflict
    FROM iatrikipraxi ip
    WHERE ip.kod_xwrou = NEW.kod_xwrou
      AND NEW.imerominia_wra < DATE_ADD(ip.imerominia_wra, INTERVAL ip.diarkeia_lepta MINUTE)
      AND ip.imerominia_wra < v_new_end;

    IF v_space_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Υπάρχει άλλη επέμβαση στον ίδιο χώρο την ίδια ώρα';
    END IF;

    -- 3. Σύγκρουση κύριου χειρουργού (ως κύριος)
    SELECT COUNT(*)
    INTO v_surgeon_conflict
    FROM iatrikipraxi ip
    WHERE ip.amka_kyriou_xeirourgou = NEW.amka_kyriou_xeirourgou
      AND NEW.imerominia_wra < DATE_ADD(ip.imerominia_wra, INTERVAL ip.diarkeia_lepta MINUTE)
      AND ip.imerominia_wra < v_new_end;

    IF v_surgeon_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο κύριος χειρουργός συμμετέχει ήδη σε άλλη επέμβαση την ίδια ώρα';
    END IF;

    -- 4. Σύγκρουση κύριου χειρουργού (ως βοηθός αλλού)
    SELECT COUNT(*)
    INTO v_surgeon_as_assist_conflict
    FROM praxi_voithos pv
    JOIN iatrikipraxi ip ON ip.kodikos = pv.kod_praxis
    WHERE pv.amka_voithou = NEW.amka_kyriou_xeirourgou
      AND NEW.imerominia_wra < DATE_ADD(ip.imerominia_wra, INTERVAL ip.diarkeia_lepta MINUTE)
      AND ip.imerominia_wra < v_new_end;

    IF v_surgeon_as_assist_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο κύριος χειρουργός είναι ήδη βοηθός σε άλλη επέμβαση την ίδια ώρα';
    END IF;
END //




-- =====================================================
-- TRIGGER: praxi_voithos_insert_trigger
-- Ελέγχει πριν την εισαγωγή βοηθού σε επέμβαση:
--   1. Ο βοηθός δεν είναι ο κύριος χειρουργός της ίδιας επέμβασης

--   3. Αν είναι ιατρός: δεν συμμετέχει ως κύριος σε άλλη επέμβαση την ίδια ώρα
--   4. Δεν είναι ήδη βοηθός σε άλλη επέμβαση την ίδια ώρα
-- =====================================================
DROP TRIGGER IF EXISTS praxi_voithos_insert_trigger //

CREATE TRIGGER praxi_voithos_insert_trigger
BEFORE INSERT ON praxi_voithos
FOR EACH ROW
BEGIN
    DECLARE v_main_surgeon              CHAR(11);
    DECLARE v_op_start                  DATETIME;
    DECLARE v_op_duration               SMALLINT;
    DECLARE v_op_end                    DATETIME;
    DECLARE v_typos                     VARCHAR(20);
    DECLARE v_as_surgeon_conflict       INT DEFAULT 0;
    DECLARE v_as_assistant_conflict     INT DEFAULT 0;

    SELECT amka_kyriou_xeirourgou, imerominia_wra, diarkeia_lepta
    INTO v_main_surgeon, v_op_start, v_op_duration
    FROM iatrikipraxi
    WHERE kodikos = NEW.kod_praxis;

    SET v_op_end = DATE_ADD(v_op_start, INTERVAL v_op_duration MINUTE);

    -- 1. Ο βοηθός δεν είναι ο κύριος χειρουργός
    IF NEW.amka_voithou = v_main_surgeon THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο βοηθός δεν μπορεί να είναι ο κύριος χειρουργός της ίδιας επέμβασης';
    END IF;

    -- 2. Έλεγχος τύπου προσωπικού
    SELECT typos_proswpikou INTO v_typos
    FROM proswpiko WHERE amka = NEW.amka_voithou;

    

    -- 3. Αν ο βοηθός είναι ιατρός, δεν επιτρέπεται να είναι κύριος αλλού
    IF v_typos = 'Ιατρός' THEN
        SELECT COUNT(*)
        INTO v_as_surgeon_conflict
        FROM iatrikipraxi ip
        WHERE ip.amka_kyriou_xeirourgou = NEW.amka_voithou
          AND v_op_start < DATE_ADD(ip.imerominia_wra, INTERVAL ip.diarkeia_lepta MINUTE)
          AND ip.imerominia_wra < v_op_end;

        IF v_as_surgeon_conflict > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ο βοηθός ιατρός συμμετέχει ως κύριος χειρουργός σε άλλη επέμβαση την ίδια ώρα';
        END IF;
    END IF;

    -- 4. Δεν επιτρέπεται να είναι βοηθός σε άλλη επέμβαση την ίδια ώρα
    SELECT COUNT(*)
    INTO v_as_assistant_conflict
    FROM praxi_voithos pv
    JOIN iatrikipraxi ip ON ip.kodikos = pv.kod_praxis
    WHERE pv.amka_voithou = NEW.amka_voithou
      AND v_op_start < DATE_ADD(ip.imerominia_wra, INTERVAL ip.diarkeia_lepta MINUTE)
      AND ip.imerominia_wra < v_op_end;

    IF v_as_assistant_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο βοηθός συμμετέχει ήδη σε άλλη επέμβαση την ίδια ώρα';
    END IF;
END //
DELIMITER ;

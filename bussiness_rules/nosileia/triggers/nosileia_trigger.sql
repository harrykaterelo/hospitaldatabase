DELIMITER //

-- =====================================================
-- TRIGGER: nosileia_insert_trigger
-- Ελέγχει πριν την εισαγωγή νοσηλείας:
--   Η κλίνη είναι διαθέσιμη
-- =====================================================
DROP TRIGGER IF EXISTS nosileia_insert_trigger //

CREATE TRIGGER nosileia_insert_trigger
BEFORE INSERT ON nosileia
FOR EACH ROW
BEGIN
    DECLARE v_klini_available INT DEFAULT 0;
    DECLARE v_existing_tmima_id INT;
    DECLARE v_existing_ar_kliis SMALLINT;

    IF EXISTS (
        SELECT 1
        FROM nosileia n
        JOIN diagnosi d_eis
            ON d_eis.nosileia_id = n.nosileia_id AND d_eis.tipos_diagnosis = 'Εισοδος'
        LEFT JOIN diagnosi d_ex
            ON d_ex.nosileia_id = n.nosileia_id AND d_ex.tipos_diagnosis = 'Εξοδος'
        WHERE n.amka_astheni = NEW.amka_astheni
        AND d_ex.nosileia_id IS NULL
        ) THEN
        SELECT n.tmima_id, n.ar_kliis
        INTO v_existing_tmima_id, v_existing_ar_kliis
        FROM nosileia n
        JOIN diagnosi d_eis
            ON d_eis.nosileia_id = n.nosileia_id AND d_eis.tipos_diagnosis = 'Εισοδος'
        LEFT JOIN diagnosi d_ex
            ON d_ex.nosileia_id = n.nosileia_id AND d_ex.tipos_diagnosis = 'Εξοδος'
        WHERE n.amka_astheni = NEW.amka_astheni
        AND d_ex.nosileia_id IS NULL
        LIMIT 1;

        SET NEW.tmima_id = v_existing_tmima_id;
        SET NEW.ar_kliis = v_existing_ar_kliis;
    ELSE
        SELECT COUNT(*)
        INTO v_klini_available
        FROM diathesimes_klines
        WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis;

        IF v_klini_available = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η κλίνη δεν είναι διαθέσιμη';
        END IF;
    END IF;
END //


-- =====================================================
-- TRIGGER: nosileia_after_insert_trigger
-- Μετά την εισαγωγή νοσηλείας, η κλίνη γίνεται Κατειλημμένη
-- =====================================================
DROP TRIGGER IF EXISTS nosileia_after_insert_trigger //

CREATE TRIGGER nosileia_after_insert_trigger
AFTER INSERT ON nosileia
FOR EACH ROW
BEGIN
    UPDATE klini
    SET katastasi = 'Κατειλημμένη'
    WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis;
END //


-- =====================================================
-- TRIGGER: exetasi_insert_trigger
-- Ελέγχει ότι η ημερομηνία εξέτασης είναι εντός της νοσηλείας
-- =====================================================
DROP TRIGGER IF EXISTS exetasi_insert_trigger //

CREATE TRIGGER exetasi_insert_trigger
BEFORE INSERT ON exetasi
FOR EACH ROW
BEGIN
    DECLARE v_imer_eisagogis DATE;
    DECLARE v_imer_exodou    DATE;

    SELECT imerominia INTO v_imer_eisagogis
    FROM diagnosi
    WHERE nosileia_id = NEW.nosileia_id AND tipos_diagnosis = 'Εισοδος';

    SELECT imerominia INTO v_imer_exodou
    FROM diagnosi
    WHERE nosileia_id = NEW.nosileia_id AND tipos_diagnosis = 'Εξοδος';

    IF NEW.imerominia < v_imer_eisagogis THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εξέτασης είναι πριν την εισαγωγή του ασθενούς';
    END IF;

    IF v_imer_exodou IS NOT NULL AND NEW.imerominia > v_imer_exodou THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εξέτασης είναι μετά την έξοδο του ασθενούς';
    END IF;
END //


-- =====================================================
-- TRIGGER: iatrikipraxi_insert_trigger
-- Ελέγχει πριν την εισαγωγή ιατρικής πράξης:
--   1. Η ημερομηνία επέμβασης είναι εντός νοσηλείας
--   2. Δεν υπάρχει άλλη επέμβαση στον ίδιο χώρο την ίδια ώρα
--   3. Ο κύριος χειρουργός δεν συμμετέχει σε άλλη επέμβαση (ως κύριος)
--   4. Ο κύριος χειρουργός δεν είναι βοηθός σε άλλη επέμβαση την ίδια ώρα
-- =====================================================
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
    SELECT imerominia INTO v_imer_eisagogis
    FROM diagnosi
    WHERE nosileia_id = NEW.nosileia_id AND tipos_diagnosis = 'Εισοδος';

    SELECT imerominia INTO v_imer_exodou
    FROM diagnosi
    WHERE nosileia_id = NEW.nosileia_id AND tipos_diagnosis = 'Εξοδος';

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
--   2. Ο βοηθός είναι ιατρός ή νοσηλευτής (όχι διοικητικό)
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

    IF v_typos = 'Διοικητικό' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Το διοικητικό προσωπικό δεν μπορεί να είναι βοηθός σε επέμβαση';
    END IF;

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


-- =====================================================
-- TRIGGER: axiologisi_insert_trigger
-- Η αξιολόγηση επιτρέπεται μόνο μετά την έξοδο του ασθενούς
-- =====================================================
DROP TRIGGER IF EXISTS axiologisi_insert_trigger //

CREATE TRIGGER axiologisi_insert_trigger
BEFORE INSERT ON axiologisi
FOR EACH ROW
BEGIN
    DECLARE v_exodos INT DEFAULT 0;

    SELECT COUNT(*) INTO v_exodos
    FROM diagnosi
    WHERE nosileia_id = NEW.nosileia_id AND tipos_diagnosis = 'Εξοδος';

    IF v_exodos = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η αξιολόγηση μπορεί να γίνει μόνο μετά την έξοδο του ασθενούς';
    END IF;
END //


-- =====================================================
-- TRIGGER: diagnosi_insert_trigger
-- Η διάγνωση εισόδου απαιτεί υποχρεωτικά κωδικό ICD.
-- Η ημερομηνία εξόδου πρέπει να είναι >= εισόδου.
-- =====================================================
DROP TRIGGER IF EXISTS diagnosi_insert_trigger //

CREATE TRIGGER diagnosi_insert_trigger
BEFORE INSERT ON diagnosi
FOR EACH ROW
BEGIN
    DECLARE v_imer_eisagogis DATE;

    IF NEW.imerominia > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία δεν μπορεί να είναι μελλοντική';
    END IF;

    IF NEW.tipos_diagnosis = 'Εισοδος' AND NEW.icd IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η διάγνωση εισόδου απαιτεί κωδικό ICD';
    END IF;

    IF NEW.tipos_diagnosis = 'Εξοδος' THEN
        SELECT imerominia INTO v_imer_eisagogis
        FROM diagnosi
        WHERE nosileia_id = NEW.nosileia_id AND tipos_diagnosis = 'Εισοδος';

        IF v_imer_eisagogis IS NOT NULL AND NEW.imerominia < v_imer_eisagogis THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η ημερομηνία εξόδου πρέπει να είναι μετά ή την ίδια μέρα με την εισαγωγή';
        END IF;
    END IF;
END //


-- =====================================================
-- TRIGGER: diagnosi_after_insert_kostos
-- Όταν μπει διάγνωση Εξοδου:
--   1. Υπολογίζει και αποθηκεύει οριστικά το synoliko_kostos
--   2. Η κλίνη ξαναγίνεται Διαθέσιμη
-- =====================================================
DROP TRIGGER IF EXISTS diagnosi_after_insert_kostos //

CREATE TRIGGER diagnosi_after_insert_kostos
AFTER INSERT ON diagnosi
FOR EACH ROW
BEGIN
    DECLARE v_imer_eisagogis DATE;
    DECLARE v_actual_days    INT;
    DECLARE v_vasiko         DECIMAL(10,2);
    DECLARE v_mdn            SMALLINT;
    DECLARE v_imer_xrewsi    DECIMAL(8,2);
    DECLARE v_kod_ken        VARCHAR(20);
    DECLARE v_tmima_id       INT;
    DECLARE v_ar_kliis       SMALLINT;
    DECLARE v_kostos_ken     DECIMAL(10,2);
    DECLARE v_kostos_exet    DECIMAL(10,2) DEFAULT 0;
    DECLARE v_kostos_praxi   DECIMAL(10,2) DEFAULT 0;

    IF NEW.tipos_diagnosis = 'Εξοδος' THEN

        SELECT imerominia INTO v_imer_eisagogis
        FROM diagnosi
        WHERE nosileia_id = NEW.nosileia_id AND tipos_diagnosis = 'Εισοδος';

        SELECT kod_ken, tmima_id, ar_kliis
        INTO v_kod_ken, v_tmima_id, v_ar_kliis
        FROM nosileia WHERE nosileia_id = NEW.nosileia_id;

        SELECT vasiko_kostos, mdn, imer_xrewsi
        INTO v_vasiko, v_mdn, v_imer_xrewsi
        FROM ken WHERE kod_ken = v_kod_ken;

        SET v_actual_days = DATEDIFF(NEW.imerominia, v_imer_eisagogis);

        IF v_actual_days <= v_mdn THEN
            SET v_kostos_ken = v_vasiko;
        ELSE
            SET v_kostos_ken = v_vasiko + (v_actual_days - v_mdn) * v_imer_xrewsi;
        END IF;

        SELECT COALESCE(SUM(kostos), 0) INTO v_kostos_exet
        FROM exetasi WHERE nosileia_id = NEW.nosileia_id;

        SELECT COALESCE(SUM(kostos), 0) INTO v_kostos_praxi
        FROM iatrikipraxi WHERE nosileia_id = NEW.nosileia_id;

        UPDATE nosileia SET synoliko_kostos = v_kostos_ken + v_kostos_exet + v_kostos_praxi
        WHERE nosileia_id = NEW.nosileia_id;

        UPDATE klini SET katastasi = 'Διαθέσιμη'
        WHERE tmima_id = v_tmima_id AND ar_kliis = v_ar_kliis;

    END IF;
END //

DELIMITER ;

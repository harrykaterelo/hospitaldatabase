-- =====================================================
-- TRIGGER: diagnosi_insert_trigger
-- Η διάγνωση εισόδου απαιτεί υποχρεωτικά κωδικό ICD.
-- Η ημερομηνία εξόδου πρέπει να είναι >= εισόδου.
-- =====================================================
DELIMITER //
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

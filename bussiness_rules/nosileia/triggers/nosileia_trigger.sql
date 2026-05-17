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
    DECLARE v_existing_tmima_id INT;
    DECLARE v_existing_ar_kliis SMALLINT;

    IF NEW.imerominia_eisodou > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εισόδου δεν μπορεί να είναι μελλοντική';
    END IF;

    IF NEW.imerominia_eksodou IS NOT NULL AND NEW.imerominia_eksodou > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εξόδου δεν μπορεί να είναι μελλοντική';
    END IF;

    IF EXISTS (
        SELECT 1 FROM nosileia
        WHERE amka_astheni = NEW.amka_astheni
        AND imerominia_eksodou IS NULL
    ) THEN
        SELECT tmima_id, ar_kliis
        INTO v_existing_tmima_id, v_existing_ar_kliis
        FROM nosileia
        WHERE amka_astheni = NEW.amka_astheni
        AND imerominia_eksodou IS NULL
        LIMIT 1;

        SET NEW.tmima_id = v_existing_tmima_id;
        SET NEW.ar_kliis = v_existing_ar_kliis;
    ELSE
        IF NOT EXISTS (
            SELECT 1 FROM diathesimes_klines
            WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η κλίνη δεν είναι διαθέσιμη';
        END IF;
    END IF;
END //


-- =====================================================
-- TRIGGER: nosileia_after_insert_trigger
-- Μετά την εισαγωγή νοσηλείας:
--   - Αν δεν έχει imerominia_eksodou: κλίνη → Κατειλημμένη
--   - Αν έχει imerominia_eksodou (εισαγωγή με αμέσως γνωστή έξοδο):
--       υπολογίζει κόστος + κλίνη → Διαθέσιμη
-- =====================================================
DROP TRIGGER IF EXISTS nosileia_after_insert_trigger //

CREATE TRIGGER nosileia_after_insert_trigger
AFTER INSERT ON nosileia
FOR EACH ROW
BEGIN
    DECLARE v_actual_days  INT;
    DECLARE v_vasiko       DECIMAL(10,2);
    DECLARE v_mdn          SMALLINT;
    DECLARE v_imer_xrewsi  DECIMAL(8,2);
    DECLARE v_kostos_ken   DECIMAL(10,2);
    DECLARE v_kostos_exet  DECIMAL(10,2) DEFAULT 0;
    DECLARE v_kostos_praxi DECIMAL(10,2) DEFAULT 0;

    IF NEW.imerominia_eksodou IS NULL THEN
        UPDATE klini SET katastasi = 'Κατειλημμένη'
        WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis;
    ELSE
        SELECT vasiko_kostos, mdn, imer_xrewsi
        INTO v_vasiko, v_mdn, v_imer_xrewsi
        FROM ken WHERE kod_ken = NEW.kod_ken;

        SET v_actual_days = DATEDIFF(NEW.imerominia_eksodou, NEW.imerominia_eisodou);

        IF v_actual_days <= v_mdn THEN
            SET v_kostos_ken = v_vasiko;
        ELSE
            SET v_kostos_ken = v_vasiko + (v_actual_days - v_mdn) * v_imer_xrewsi;
        END IF;

        SELECT COALESCE(SUM(kostos), 0) INTO v_kostos_exet
        FROM exetasi WHERE nosileia_id = NEW.nosileia_id;

        SELECT COALESCE(SUM(kostos), 0) INTO v_kostos_praxi
        FROM iatrikipraxi WHERE nosileia_id = NEW.nosileia_id;

        UPDATE nosileia
        SET synoliko_kostos = v_kostos_ken + v_kostos_exet + v_kostos_praxi
        WHERE nosileia_id = NEW.nosileia_id;

        UPDATE klini SET katastasi = 'Διαθέσιμη'
        WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis;
    END IF;
END //


-- =====================================================
-- TRIGGER: nosileia_before_update_trigger
-- Ελέγχει πριν το update νοσηλείας:
--   Η imerominia_eksodou (αν οριστεί) να μην είναι μελλοντική
-- =====================================================
DROP TRIGGER IF EXISTS nosileia_before_update_trigger //

CREATE TRIGGER nosileia_before_update_trigger
BEFORE UPDATE ON nosileia
FOR EACH ROW
BEGIN
    IF OLD.imerominia_eksodou IS NULL AND NEW.imerominia_eksodou IS NOT NULL
       AND NEW.imerominia_eksodou > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εξόδου δεν μπορεί να είναι μελλοντική';
    END IF;
END //


-- =====================================================
-- TRIGGER: nosileia_after_update_eksodou
-- Όταν οριστεί η imerominia_eksodou (από NULL σε τιμή):
--   1. Υπολογίζει και αποθηκεύει το synoliko_kostos
--   2. Η κλίνη ξαναγίνεται Διαθέσιμη
-- =====================================================
DROP TRIGGER IF EXISTS nosileia_after_update_eksodou //

CREATE TRIGGER nosileia_after_update_eksodou
AFTER UPDATE ON nosileia
FOR EACH ROW
BEGIN
    DECLARE v_actual_days  INT;
    DECLARE v_vasiko       DECIMAL(10,2);
    DECLARE v_mdn          SMALLINT;
    DECLARE v_imer_xrewsi  DECIMAL(8,2);
    DECLARE v_kostos_ken   DECIMAL(10,2);
    DECLARE v_kostos_exet  DECIMAL(10,2) DEFAULT 0;
    DECLARE v_kostos_praxi DECIMAL(10,2) DEFAULT 0;

    IF OLD.imerominia_eksodou IS NULL AND NEW.imerominia_eksodou IS NOT NULL THEN

        SELECT vasiko_kostos, mdn, imer_xrewsi
        INTO v_vasiko, v_mdn, v_imer_xrewsi
        FROM ken WHERE kod_ken = NEW.kod_ken;

        SET v_actual_days = DATEDIFF(NEW.imerominia_eksodou, NEW.imerominia_eisodou);

        IF v_actual_days <= v_mdn THEN
            SET v_kostos_ken = v_vasiko;
        ELSE
            SET v_kostos_ken = v_vasiko + (v_actual_days - v_mdn) * v_imer_xrewsi;
        END IF;

        SELECT COALESCE(SUM(kostos), 0) INTO v_kostos_exet
        FROM exetasi WHERE nosileia_id = NEW.nosileia_id;

        SELECT COALESCE(SUM(kostos), 0) INTO v_kostos_praxi
        FROM iatrikipraxi WHERE nosileia_id = NEW.nosileia_id;

        UPDATE nosileia
        SET synoliko_kostos = v_kostos_ken + v_kostos_exet + v_kostos_praxi
        WHERE nosileia_id = NEW.nosileia_id;

        UPDATE klini SET katastasi = 'Διαθέσιμη'
        WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis;

    END IF;
END //


DELIMITER ;








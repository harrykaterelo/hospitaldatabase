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

    SELECT imerominia_eisodou, imerominia_eksodou
    INTO v_imer_eisagogis, v_imer_exodou
    FROM nosileia
    WHERE nosileia_id = NEW.nosileia_id;

    IF NEW.imerominia < v_imer_eisagogis THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εξέτασης είναι πριν την εισαγωγή του ασθενούς';
    END IF;

    IF v_imer_exodou IS NOT NULL AND NEW.imerominia > v_imer_exodou THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εξέτασης είναι μετά την έξοδο του ασθενούς';
    END IF;
END //


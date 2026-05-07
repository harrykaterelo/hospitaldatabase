DELIMITER //
DROP TRIGGER IF EXISTS doctor_insert_trigger ;
CREATE TRIGGER doctor_insert_trigger
BEFORE INSERT ON iatros
FOR EACH ROW
BEGIN
    DECLARE has_to_be_supervised BOOL DEFAULT FALSE;
    DECLARE grade_exists INT DEFAULT 0;

    DECLARE epop tis_exists INT DEFAULT 0;
    DECLARE vathmida_epopti VARCHAR(50);
    DECLARE epoptis_tou_epopti CHAR(11);
    DECLARE epoptis_can_supervise BOOL DEFAULT FALSE;

    -- Check that the new doctor's vathmida exists
    SELECT COUNT(*)
    INTO grade_exists
    FROM vathmida_iatrou
    WHERE vathmida_onoma = NEW.vathmida;

    IF grade_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Η βαθμίδα του γιατρού δεν υπάρχει';
    END IF;

    -- Check if this vathmida requires supervision
    SELECT is_supervised
    INTO has_to_be_supervised
    FROM vathmida_iatrou
    WHERE vathmida_onoma = NEW.vathmida
    LIMIT 1;

    -- Case 1: doctor has no supervisor
    IF NEW.amka_epoptis IS NULL THEN

        IF has_to_be_supervised = TRUE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ο γιατρός με αυτήν την βαθμίδα πρέπει αναγκαστικά να έχει επόπτη';
        END IF;

    -- Case 2: doctor has supervisor
    ELSE
        IF has_to_be_supervised = FALSE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'αυτος ο γιατρος με αυτην την βαθμιδα δεν μπορει να εχει εποπτη';
        END IF;
        -- Doctor cannot supervise themselves
        IF NEW.amka_epoptis = NEW.amka THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ο γιατρός δεν μπορεί να είναι επόπτης του εαυτού του';
        END IF;

        -- Check supervisor exists
        SELECT COUNT(*)
        INTO epoptis_exists
        FROM iatros
        WHERE amka = NEW.amka_epoptis;

        IF epoptis_exists = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ο επόπτης δεν υπάρχει';
        END IF;

        -- Get supervisor info
        SELECT i.vathmida, i.epoptis
        INTO vathmida_epopti, epoptis_tou_epopti
        FROM iatros i
        WHERE i.amka = NEW.amka_epoptis
        LIMIT 1;

        -- Check if supervisor's vathmida is allowed to supervise
        SELECT can_supervise
        INTO epoptis_can_supervise
        FROM vathmida_iatrou
        WHERE vathmida_onoma = vathmida_epopti
        LIMIT 1;

        IF epoptis_can_supervise = FALSE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Η βαθμίδα του επόπτη δεν επιτρέπεται να επιβλέπει γιατρούς';
        END IF;

        -- Prevent direct cycle:
        -- NEW doctor has supervisor X, but X already has supervisor NEW doctor
        IF epoptis_tou_epopti = NEW.amka THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Δεν επιτρέπεται κυκλική εξάρτηση εποπτείας';
        END IF;

    END IF;

END//

DELIMITER ;
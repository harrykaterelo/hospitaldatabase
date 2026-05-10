DELIMITER //

DROP TRIGGER IF EXISTS proswpiko_anikei_se_tmima_insert_trigger //

CREATE TRIGGER proswpiko_anikei_se_tmima_insert_trigger
BEFORE INSERT ON proswpiko_anikei_se_tmima
FOR EACH ROW
BEGIN

DECLARE proswpiko_exists INT DEFAULT 0;
DECLARE tmima_exists INT DEFAULT 0;
DECLARE katigoria VARCHAR(20);
DECLARE anikei_idi INT DEFAULT 0;
DECLARE vathmida_doctor INT DEFAULT 0;
DECLARE dieftinti_se_allo_tmima INT DEFAULT 0;

SELECT COUNT(*)
INTO proswpiko_exists
FROM proswpiko
WHERE amka = NEW.amka_proswpikou;

IF proswpiko_exists = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'To προσωπικό με αυτό το AMKA δεν υπάρχει';
END IF;

SELECT COUNT(*)
INTO tmima_exists
FROM tmima
WHERE tmima_id = NEW.tmima_id;

IF tmima_exists = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Το τμήμα με αυτό το ID δεν υπάρχει';
END IF;

SELECT typos_proswpikou 
INTO katigoria
FROM proswpiko
WHERE amka = NEW.amka_proswpikou;

IF katigoria IN ('Νοσηλευτής', 'Διοικητικό') THEN

    SELECT COUNT(*)
    INTO anikei_idi
    FROM proswpiko_anikei_se_tmima
    WHERE amka_proswpikou = NEW.amka_proswpikou;

    IF anikei_idi = 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = CONCAT('Το προσωπικό τύπου ', katigoria, ' ανήκει ήδη σε τμήμα. Αν θες να αλλάξεις το τμήμα κανε CALL το update_tmima_proswpikou');
    END IF;
END IF;

IF katigoria = 'Ιατρός' THEN

    SELECT vathmida
    INTO vatmida_doctor
    FROM iatros
    WHERE amka = NEW.amka_proswpikou;

    IF vatmida_doctor = 4 THEN
        SELECT COUNT(*)
        INTO dieftinti_se_allo_tmima
        FROM tmima
        WHERE amka_dieftinti = NEW.amka_proswpikou;

        IF dieftinti_se_allo_tmima != 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ο ιατρός αυτός είναι ήδη διευθυντής σε άλλο τμήμα. Αν θες να αλλάξεις το τμήμα κανε CALL το update_tmima_proswpikou';
        END IF;
    END IF;
END IF;

END //


DROP TRIGGER IF EXISTS proswpiko_allagi_tmimatos_insert_trigger //

CREATE TRIGGER proswpiko_allagi_tmimatos_insert_trigger
AFTER INSERT ON proswpiko_allagi_tmimatos
FOR EACH ROW
BEGIN

DECLARE proswpiko_exists INT DEFAULT 0;
DECLARE tmima_exists INT DEFAULT 0;

SELECT COUNT(*)
INTO proswpiko_exists
FROM proswpiko
WHERE amka = NEW.amka_proswpikou;

IF proswpiko_exists = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'To προσωπικό με αυτό το AMKA δεν υπάρχει';
END IF;

SELECT COUNT(*)
INTO tmima_exists
FROM tmima
WHERE tmima_id = NEW.tmima_id;

IF tmima_exists = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Το τμήμα με αυτό το ID δεν υπάρχει';
END IF;

UPDATE proswpiko_anikei_se_tmima
SET tmima_id = NEW.tmima_id
WHERE amka_proswpikou = NEW.amka_proswpikou;

END //

DROP TRIGGER IF EXISTS tmima_insert_trigger //

CREATE TRIGGER tmima_insert_trigger
BEFORE INSERT ON tmima
FOR EACH ROW
BEGIN

DECLARE dieftinti_exists INT DEFAULT 0;
DECLARE vatmida_dieftinti TINYINT;
DECLARE dieftinti_se_allo_tmima INT DEFAULT 0;
IF NEW.amka_dieftinti IS NOT NULL THEN

    SELECT COUNT(*)
    INTO dieftinti_exists
    FROM iatros
    WHERE amka = NEW.amka_dieftinti;

    IF dieftinti_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο διευθυντής με αυτό το ΑΜΚΑ δεν είναι δηλωμένος ιατρός';
    END IF;   

    SELECT vathmida
    INTO vatmida_dieftinti
    FROM iatros
    WHERE amka = NEW.amka_dieftinti;

    IF vatmida_dieftinti != 4 THEN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο ιατρός με αυτό το ΑΜΚΑ δεν έχει βαθμίδα διευθυντή';
    END IF;

    SELECT COUNT(*)
    INTO dieftinti_se_allo_tmima
    FROM tmima
    WHERE amka_dieftinti = NEW.amka_dieftinti;

    IF dieftinti_se_allo_tmima != 0 THEN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο διευθυντής αυτός είναι ήδη διευθυντής σε άλλο τμήμα. Αν θες να τον ορίσεις διευθυντή αυτού του τμήματος κάνε INSERT το τμήμα χωρίς διευθυντή και μετά χρησιμοποίησε την update_tmima_proswpikou';
    END IF;
END IF;
END //

DELIMITER ;
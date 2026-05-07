CREATE TRIGGER doctor_insert_trigger
BEFORE INSERT ON iatros
FOR EACH ROW
BEGIN
    DECLARE has_to_be_supervised BOOL;
    IF NEW.epoptis=NULL THEN
        SELECT is_supervised INTO has_to_be_supervised FROM vathmida_iatrou WHERE vathmida_onoma=NEW.vathmida;
    IF has_to_be_supervised = TRUE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT  = 'Ο ΓΙΑΤΡΟΣ ΜΕ ΑΥΤΗ ΤΗΝ ΒΑΘΜΙΔΑ ΠΡΕΠΕΙ ΑΝΑΓΚΑΣΤΙΚΑ ΝΑ ΕΧΕΙ ΕΠΟΠΤΗ';
    END IF
    END IF

    ELSE THEN
        DECLARE vathmida_epopti CHAR;
        DECLARE epoptis_tou_epopti CHAR;
        I

END;§
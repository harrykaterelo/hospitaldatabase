DELIMITER //
DROP FUNCTION IF EXISTS efimeria_check //
CREATE FUNCTION efimeria_check(
    p_tmima INT,
    p_imerominia DATE,
    p_vardia INT
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_doctors INT DEFAULT 0;
    DECLARE v_nurses INT DEFAULT 0;
    DECLARE v_admins INT DEFAULT 0;

    DECLARE doctor_min_count INT DEFAULT 3;
    DECLARE nurse_min_count INT DEFAULT 6;
    DECLARE admin_min_count INT DEFAULT 2;

    DECLARE docs_that_require_senior_in_shift INT DEFAULT 0;
    DECLARE docs_that_can_cover_shift INT DEFAULT 0;

    SELECT 
        iatros_min_count,
        nosileutes_min_count,
        dioikitiko_min_count
    INTO
        doctor_min_count,
        nurse_min_count,
        admin_min_count
    FROM efimeria_requirements
    LIMIT 1;

    SELECT 
        COALESCE(SUM(CASE WHEN p.typos_proswpikou = 'iatros' THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN p.typos_proswpikou = 'nosileutis' THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN p.typos_proswpikou = 'dioikitikos' THEN 1 ELSE 0 END), 0)
    INTO    
        v_doctors,
        v_nurses,
        v_admins
    FROM efimeria_proswpiko ep
    JOIN proswpiko p
        ON ep.amka_proswpiko = p.amka
    WHERE ep.tmima = p_tmima
      AND ep.imerominia = p_imerominia
      AND ep.vardia = p_vardia;

    IF v_doctors < doctor_min_count
       OR v_nurses < nurse_min_count
       OR v_admins < admin_min_count THEN
        RETURN 0;
    END IF;

    SELECT
        COALESCE(SUM(CASE WHEN v.require_senior_in_shift = 1 THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN v.can_cover_specialist_shift = 1 THEN 1 ELSE 0 END), 0)
    INTO 
        docs_that_require_senior_in_shift,
        docs_that_can_cover_shift
    FROM efimeria_proswpiko ep
    JOIN iatros i
        ON ep.amka_proswpiko = i.amka
    JOIN vathmida v
        ON i.vathmida = v.vathmida
    WHERE ep.tmima = p_tmima
      AND ep.imerominia = p_imerominia
      AND ep.vardia = p_vardia;

    IF docs_that_require_senior_in_shift > 0
       AND docs_that_can_cover_shift = 0 THEN
        RETURN 0;
    END IF;

    RETURN 1;
END//

DELIMITER ;
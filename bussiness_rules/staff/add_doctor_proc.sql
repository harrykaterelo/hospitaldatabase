DELIMITER //
DROP PROCEDURE IF EXISTS add_doctor ;

CREATE PROCEDURE my_proc()
BEGIN
  SELECT 'new version' AS test;
END;
CREATE PROCEDURE add_doctor(
    IN p_amka CHAR(11),
    IN p_onoma VARCHAR(50),
    IN p_eponymo VARCHAR(50),
    IN p_ilikia SMALLINT,
    IN p_email VARCHAR(100),
    IN p_tilefono VARCHAR(15),
    IN p_imerominia_proslipsis DATE,
    IN p_typos_proswpikou VARCHAR(20),
    IN p_ar_ad_is VARCHAR(20),
    IN p_eidikotita VARCHAR(80),
    IN p_vathmida VARCHAR(30),
    IN p_amka_epoptis CHAR(11)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    
    -- Insert into anthropos
    INSERT INTO anthropos (amka, onoma, eponymo, ilikia, email, tilefono)
    VALUES (p_amka, p_onoma, p_eponymo, p_ilikia, p_email, p_tilefono);
    -- Insert into proswpiko
    INSERT INTO proswpiko (amka, imerominia_proslipsis, typos_proswpikou)
    VALUES (p_amka, p_imerominia_proslipsis, p_typos_proswpikou);
    -- Insert into iatros
    INSERT INTO iatros (amka, ar_ad_is, eidikotita, vathmida, amka_epoptis)
    VALUES (p_amka, p_ar_ad_is, p_eidikotita, (SELECT vathmida_id FROM vathmida_iatrou WHERE vathmida_onoma = p_vathmida), p_amka_epoptis);
END //

DELIMITER ;    
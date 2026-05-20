DELIMITER //

DROP PROCEDURE IF EXISTS add_doctor //

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
    IN p_vathmida_id INT,
    IN p_amka_epoptis CHAR(11)
)
BEGIN
    DECLARE v_vathmida_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    

    

    START TRANSACTION;

    INSERT INTO anthropos (
        amka, onoma, eponymo, ilikia, email, tilefono
    )
    VALUES (
        p_amka, p_onoma, p_eponymo, p_ilikia, p_email, p_tilefono
    );

    INSERT INTO proswpiko (
        amka, imerominia_proslipsis, typos_proswpikou
    )
    VALUES (
        p_amka, p_imerominia_proslipsis, p_typos_proswpikou
    );

    INSERT INTO iatros (
        amka, ar_ad_is, eidikotita, vathmida, amka_epoptis
    )
    VALUES (
        p_amka, p_ar_ad_is, p_eidikotita, p_vathmida_id, p_amka_epoptis
    );

    COMMIT;
END //

DELIMITER ;
SET NAMES utf8mb4;

DELIMITER //

DROP PROCEDURE IF EXISTS add_dioikitiko //

CREATE PROCEDURE add_dioikitiko(
    IN p_amka                   CHAR(11),
    IN p_onoma                  VARCHAR(50),
    IN p_eponymo                VARCHAR(50),
    IN p_ilikia                 SMALLINT,
    IN p_email                  VARCHAR(100),
    IN p_tilefono               VARCHAR(15),
    IN p_imerominia_proslipsis  DATE,
    IN p_rolos                  VARCHAR(80),
    IN p_grafeio                VARCHAR(50),
    IN p_tmima_id               INT
)
BEGIN
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
        p_amka, p_imerominia_proslipsis, 'Διοικητικό'
    );

    INSERT INTO dioikitiko (
        amka, rolos, grafeio
    )
    VALUES (
        p_amka, p_rolos, p_grafeio
    );

    INSERT INTO proswpiko_anikei_se_tmima (
        amka_proswpikou, tmima_id
    )
    VALUES (
        p_amka, p_tmima_id
    );

    COMMIT;
END //

DELIMITER ;

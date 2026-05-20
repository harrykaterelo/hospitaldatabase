
DROP PROCEDURE IF EXISTS query_4;

DELIMITER //
CREATE PROCEDURE query_4(IN p_amka CHAR(11))
BEGIN
    WITH nosileies_iatrou AS (
        SELECT DISTINCT nosileia_id
        FROM exetasi
        WHERE amka_iatrou = p_amka
        UNION
        SELECT DISTINCT nosileia_id
        FROM iatrikipraxi
        WHERE amka_kyriou_xeirourgou = p_amka
    )
    SELECT
        p_amka                                       AS amka_iatrou,
        COUNT(*)                                     AS plithos_axiologiseon,
        ROUND(AVG(a.poiotita_iatr_frontidas), 2)     AS mo_poiotita_iatr_frontidas,
        ROUND(AVG(a.synoliki_empeiria), 2)           AS mo_synoliki_empeiria
    FROM nosileies_iatrou ni
    JOIN axiologisi a ON a.nosileia_id = ni.nosileia_id;
END //
DELIMITER ;

ANALYZE
SELECT
    COUNT(*)                                     AS plithos_axiologiseon,
    ROUND(AVG(a.poiotita_iatr_frontidas), 2)     AS mo_poiotita_iatr_frontidas,
    ROUND(AVG(a.synoliki_empeiria), 2)           AS mo_synoliki_empeiria
FROM (
    SELECT DISTINCT nosileia_id
    FROM exetasi IGNORE INDEX (amka_iatrou)
    WHERE amka_iatrou = '10000000004'
    UNION
    SELECT DISTINCT nosileia_id
    FROM iatrikipraxi
    WHERE amka_kyriou_xeirourgou = '10000000004'
) ni
JOIN axiologisi a ON a.nosileia_id = ni.nosileia_id;


ANALYZE
SELECT
    COUNT(*)                                     AS plithos_axiologiseon,
    ROUND(AVG(a.poiotita_iatr_frontidas), 2)     AS mo_poiotita_iatr_frontidas,
    ROUND(AVG(a.synoliki_empeiria), 2)           AS mo_synoliki_empeiria
FROM (
    SELECT DISTINCT nosileia_id
    FROM exetasi
    WHERE amka_iatrou = '10000000004'
    UNION
    SELECT DISTINCT nosileia_id
    FROM iatrikipraxi
    WHERE amka_kyriou_xeirourgou = '10000000004'
) ni
JOIN axiologisi a ON a.nosileia_id = ni.nosileia_id;


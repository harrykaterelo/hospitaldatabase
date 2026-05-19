DROP PROCEDURE IF EXISTS query_2;

DELIMITER //
CREATE PROCEDURE query_2(IN p_eidikotita VARCHAR(80))
BEGIN
    WITH efimeries AS (
        SELECT DISTINCT amka_proswpiko
        FROM efimeria_proswpiko
        WHERE YEAR(imerominia) = YEAR(CURDATE())
    ),
    epemvaseis AS (
        SELECT
            amka_kyriou_xeirourgou,
            COUNT(*) AS arithmos_epemvaseon
        FROM iatrikipraxi
        
        GROUP BY amka_kyriou_xeirourgou
    )
    SELECT
        i.amka,
        i.eidikotita,
        IF(ef.amka_proswpiko IS NOT NULL, 'Ναι', 'Όχι') AS eixe_efimeria,
        COALESCE(ep.arithmos_epemvaseon, 0)             AS arithmos_epemvaseon,
    SUM(COALESCE(ep.arithmos_epemvaseon, 0)) OVER () AS synolo_epemvaseon
    FROM iatros i
    LEFT JOIN efimeries ef  ON ef.amka_proswpiko = i.amka
    LEFT JOIN epemvaseis ep ON ep.amka_kyriou_xeirourgou = i.amka
    WHERE i.eidikotita = p_eidikotita
    ORDER BY i.amka;
END //
DELIMITER ;

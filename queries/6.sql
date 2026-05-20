DROP PROCEDURE IF EXISTS query_6;

DELIMITER //
CREATE PROCEDURE query_6(IN p_amka CHAR(11))
BEGIN
    SELECT
        n.nosileia_id,
        n.imerominia_eisodou,
        n.imerominia_eksodou,
        n.synoliko_kostos,
        MAX(CASE WHEN d.tipos_diagnosis = 'Εισοδος' THEN d.icd END)  AS icd_eisodou,
        MAX(CASE WHEN d.tipos_diagnosis = 'Εξοδος'  THEN d.icd END)  AS icd_eksodou,
        ROUND(AVG((a.poiotita_iatr_frontidas
                 + a.poiotita_nosileft_frontidas
                 + a.kathariotita
                 + a.fagito
                 + a.synoliki_empeiria) / 5.0), 2)                   AS mo_axiologisis
    FROM nosileia n
    LEFT JOIN diagnosi   d ON d.nosileia_id = n.nosileia_id
    LEFT JOIN axiologisi a ON a.nosileia_id = n.nosileia_id
    WHERE n.amka_astheni = p_amka
    GROUP BY n.nosileia_id,
             n.imerominia_eisodou,
             n.imerominia_eksodou,
             n.synoliko_kostos
    ORDER BY n.imerominia_eisodou DESC;
END //
DELIMITER ;

ANALYZE
SELECT
    n.nosileia_id,
    n.imerominia_eisodou,
    n.imerominia_eksodou,
    n.synoliko_kostos,
    MAX(CASE WHEN d.tipos_diagnosis = 'Εισοδος' THEN d.icd END)  AS icd_eisodou,
    MAX(CASE WHEN d.tipos_diagnosis = 'Εξοδος'  THEN d.icd END)  AS icd_eksodou,
    ROUND(AVG((a.poiotita_iatr_frontidas
             + a.poiotita_nosileft_frontidas
             + a.kathariotita
             + a.fagito
             + a.synoliki_empeiria) / 5.0), 2)                   AS mo_axiologisis
FROM nosileia n IGNORE INDEX (amka_astheni)
LEFT JOIN diagnosi   d ON d.nosileia_id = n.nosileia_id
LEFT JOIN axiologisi a ON a.nosileia_id = n.nosileia_id
WHERE n.amka_astheni = '24063510108'
GROUP BY n.nosileia_id,
         n.imerominia_eisodou,
         n.imerominia_eksodou,
         n.synoliko_kostos
ORDER BY n.imerominia_eisodou DESC;


ANALYZE
SELECT
    n.nosileia_id,
    n.imerominia_eisodou,
    n.imerominia_eksodou,
    n.synoliko_kostos,
    MAX(CASE WHEN d.tipos_diagnosis = 'Εισοδος' THEN d.icd END)  AS icd_eisodou,
    MAX(CASE WHEN d.tipos_diagnosis = 'Εξοδος'  THEN d.icd END)  AS icd_eksodou,
    ROUND(AVG((a.poiotita_iatr_frontidas
             + a.poiotita_nosileft_frontidas
             + a.kathariotita
             + a.fagito
             + a.synoliki_empeiria) / 5.0), 2)                   AS mo_axiologisis
FROM nosileia n
LEFT JOIN diagnosi   d ON d.nosileia_id = n.nosileia_id
LEFT JOIN axiologisi a ON a.nosileia_id = n.nosileia_id
WHERE n.amka_astheni = '24063510108'
GROUP BY n.nosileia_id,
         n.imerominia_eisodou,
         n.imerominia_eksodou,
         n.synoliko_kostos
ORDER BY n.imerominia_eisodou DESC;



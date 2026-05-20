CREATE OR REPLACE VIEW query_7 AS
SELECT
    d.onoma                     AS drastiki_ousia,
    COUNT(DISTINCT a.amka_astheni) AS arithmos_allergikon,
    COUNT(DISTINCT fd.kod_ema)     AS arithmos_farmakon
FROM drastiki_ousia d
JOIN farmako_drastiki fd ON fd.ousia_id = d.ousia_id
LEFT JOIN allergy a         ON a.ousia_id  = d.ousia_id
GROUP BY d.ousia_id, d.onoma
ORDER BY arithmos_allergikon DESC;


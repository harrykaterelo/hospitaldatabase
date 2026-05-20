CREATE OR REPLACE VIEW query_5 AS
SELECT
    i.amka,
    an.ilikia,
    COUNT(*) AS arithmos_xeirourgikon
FROM iatros i
JOIN anthropos an ON an.amka = i.amka
JOIN iatrikipraxi ip ON ip.amka_kyriou_xeirourgou = i.amka
WHERE an.ilikia < 35
  AND ip.katigoria = 'Χειρουργική'
GROUP BY i.amka
ORDER BY arithmos_xeirourgikon DESC;

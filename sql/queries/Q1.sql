CREATE OR REPLACE VIEW query_1 AS
WITH ken_kostos AS (
    SELECT
        n.tmima_id,
        YEAR(n.imerominia_eisodou)          AS etos,
        n.kod_ken,
        a.asfalistikos_foreas,
        k.vasiko_kostos                     AS vasiko,
        CASE
            WHEN n.imerominia_eksodou IS NOT NULL
                THEN GREATEST(DATEDIFF(n.imerominia_eksodou, n.imerominia_eisodou) - k.mdn, 0) * k.imer_xrewsi
            ELSE 0
        END                                AS prostheto
    FROM nosileia n
    JOIN ken k      ON k.kod_ken = n.kod_ken
    JOIN asthenis a ON a.amka    = n.amka_astheni
)
SELECT
    tmima_id,
    etos,
    kod_ken,
    asfalistikos_foreas,
    COUNT(*)            AS arithmos_nosilion,
    SUM(vasiko)         AS synoliko_vasiko,
    SUM(prostheto)      AS synoliko_prostheto,
    SUM(vasiko + prostheto) AS synoliko_esoda
FROM ken_kostos
GROUP BY tmima_id, etos, kod_ken, asfalistikos_foreas
ORDER BY tmima_id, etos, kod_ken, asfalistikos_foreas;

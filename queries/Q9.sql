CREATE OR REPLACE VIEW query_9 AS
WITH durations AS (
    -- Κανονική νοσηλεία: αρχίζει και τελειώνει στο ίδιο έτος
    SELECT
        n.amka_astheni,
        YEAR(n.imerominia_eisodou) AS etos,
        DATEDIFF(
            COALESCE(n.imerominia_eksodou, CURDATE()),
            n.imerominia_eisodou
        ) AS diarkeia_imeron
    FROM nosileia n
    WHERE YEAR(COALESCE(n.imerominia_eksodou, CURDATE())) = YEAR(n.imerominia_eisodou)

    UNION

    -- Cross-year: μέρες στο έτος ΕΙΣΟΔΟΥ
    SELECT
        n.amka_astheni,
        YEAR(n.imerominia_eisodou) AS etos,
        DATEDIFF(
            DATE(CONCAT(YEAR(n.imerominia_eisodou), '-12-31')),
            n.imerominia_eisodou
        ) AS diarkeia_imeron
    FROM nosileia n
    WHERE YEAR(COALESCE(n.imerominia_eksodou, CURDATE())) > YEAR(n.imerominia_eisodou)

    UNION

    -- Cross-year: μέρες στο έτος ΕΞΟΔΟΥ
    SELECT
        n.amka_astheni,
        YEAR(n.imerominia_eksodou) AS etos,
        DATEDIFF(
            n.imerominia_eksodou,
            DATE(CONCAT(YEAR(n.imerominia_eksodou), '-01-01'))
        ) AS diarkeia_imeron
    FROM nosileia n
    WHERE n.imerominia_eksodou IS NOT NULL
      AND YEAR(n.imerominia_eksodou) > YEAR(n.imerominia_eisodou)
),
per_year AS (
    SELECT
        amka_astheni,
        etos,
        SUM(diarkeia_imeron) AS synoliki_diarkeia
    FROM durations
    GROUP BY amka_astheni, etos
    HAVING synoliki_diarkeia > 15
)
SELECT
    etos,
    synoliki_diarkeia,
    GROUP_CONCAT(amka_astheni ORDER BY amka_astheni) AS asthenis
FROM per_year
GROUP BY etos, synoliki_diarkeia
HAVING COUNT(*) > 1
ORDER BY etos, synoliki_diarkeia;

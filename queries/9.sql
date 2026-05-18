CREATE OR REPLACE VIEW query_9 AS
WITH durations AS (
    SELECT
        n.amka_astheni,
        YEAR(n.imerominia_eisodou) AS etos,
        DATEDIFF(
            LEAST(
                COALESCE(n.imerominia_eksodou, CURDATE()),
                DATE(CONCAT(YEAR(n.imerominia_eisodou), '-12-31'))
            ),
            n.imerominia_eisodou
        ) AS diarkeia_imeron
    FROM nosileia n
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
    py.amka_astheni,
    py.etos,
    py.synoliki_diarkeia
FROM per_year py
WHERE EXISTS (
    SELECT 1 FROM per_year py2
    WHERE py2.amka_astheni != py.amka_astheni
      AND py2.etos          = py.etos
      AND py2.synoliki_diarkeia = py.synoliki_diarkeia
)
ORDER BY py.etos, py.synoliki_diarkeia, py.amka_astheni;

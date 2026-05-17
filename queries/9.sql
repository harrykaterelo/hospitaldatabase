CREATE OR REPLACE VIEW query_9 AS
WITH durations AS (
    SELECT
        n.amka_astheni,
        YEAR(d_in.imerominia) AS etos,
        DATEDIFF(
            LEAST(
                COALESCE(d_out.imerominia, CURDATE()),
                DATE(CONCAT(YEAR(d_in.imerominia), '-12-31'))
            ),
            d_in.imerominia
        ) AS diarkeia_imeron
    FROM nosileia n
    JOIN diagnosi d_in  ON d_in.nosileia_id  = n.nosileia_id
                       AND d_in.tipos_diagnosis  = 'Εισοδος'
    LEFT JOIN diagnosi d_out ON d_out.nosileia_id = n.nosileia_id
                            AND d_out.tipos_diagnosis = 'Εξοδος'
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

WITH durations AS (
    SELECT
        n.amka_astheni,
        n.nosileia_id,
        YEAR(d_in.imerominia)                          AS etos,
        DATEDIFF(d_out.imerominia, d_in.imerominia)    AS diarkeia_imeron
    FROM nosileia n
    JOIN diagnosi d_in  ON d_in.nosileia_id  = n.nosileia_id
                       AND d_in.tipos_diagnosis  = 'Εισοδος'
    JOIN diagnosi d_out ON d_out.nosileia_id = n.nosileia_id
                       AND d_out.tipos_diagnosis = 'Εξοδος'
),
per_year AS (
    SELECT
        amka_astheni,
        etos,
        COUNT(*)              AS plithos_nosilewn,
        MIN(diarkeia_imeron)  AS min_diarkeia,
        MAX(diarkeia_imeron)  AS max_diarkeia,
        SUM(diarkeia_imeron)  AS synoliki_diarkeia
    FROM durations
    GROUP BY amka_astheni, etos
)
SELECT
    py.amka_astheni,
    py.etos,
    py.plithos_nosilewn,
    py.min_diarkeia        AS diarkeia_kathe_nosileia,
    py.synoliki_diarkeia
FROM per_year py
WHERE py.min_diarkeia = py.max_diarkeia   -- ίδιος αριθμός ημερών σε κάθε νοσηλεία
  AND py.synoliki_diarkeia > 15           -- σύνολο > 15 μέρες
  AND py.plithos_nosilewn > 1             -- τουλάχιστον 2 νοσηλείες
ORDER BY py.amka_astheni, py.etos;

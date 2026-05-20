CREATE OR REPLACE VIEW query_10 AS 
WITH prescribed_ousies AS (
    SELECT DISTINCT
        s.nosileia_id,
        s.amka_astheni,
        d.ousia_id,
        d.onoma AS ousia_onoma
    FROM syntagografisi s
    JOIN farmako_drastiki fd
        ON fd.kod_ema = s.kod_ema
    JOIN drastiki_ousia d
        ON d.ousia_id = fd.ousia_id
),
ousia_pairs AS (
    SELECT
        p1.ousia_id AS ousia_id_1,
        p1.ousia_onoma AS ousia_1,
        p2.ousia_id AS ousia_id_2,
        p2.ousia_onoma AS ousia_2,
        COUNT(distinct p1.nosileia_id) AS frequency
    FROM prescribed_ousies p1
    JOIN prescribed_ousies p2
        ON p1.nosileia_id = p2.nosileia_id
       AND p1.amka_astheni = p2.amka_astheni
       AND p1.ousia_id < p2.ousia_id
    GROUP BY
        p1.ousia_id,
        p1.ousia_onoma,
        p2.ousia_id,
        p2.ousia_onoma
),
ranked_pairs AS (
    SELECT
        *,
        RANK() OVER (
            ORDER BY frequency DESC
        ) AS pair_rank
    FROM ousia_pairs
)
SELECT
    ousia_1,
    ousia_2,
    frequency,
    pair_rank
FROM ranked_pairs
WHERE pair_rank <= 3
ORDER BY pair_rank, frequency DESC;
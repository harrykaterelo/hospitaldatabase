CREATE OR REPLACE VIEW query_3 AS
WITH nosileia_ana_astheni AS (
    SELECT
    n.amka_astheni,
    n.tmima_id,
    IF (n.imerominia_eksodou IS NULL,  
         (SELECT trexon_kostos 
         FROM trexon_kostos_nosileia 
         WHERE nosileia_id = n.nosileia_id),
        n.synoliko_kostos
    )   AS kostos
FROM nosileia n
),
per_tmima AS (
    SELECT 
        amka_astheni,
        tmima_id,
        SUM(kostos) AS total_kostos,
        COUNT(*) as fores   
    FROM nosileia_ana_astheni
    GROUP BY amka_astheni, tmima_id
    HAVING fores > 3
)
SELECT 
    amka_astheni,
    tmima_id,
    fores,
    total_kostos
FROM per_tmima
ORDER BY amka_astheni, tmima_id;
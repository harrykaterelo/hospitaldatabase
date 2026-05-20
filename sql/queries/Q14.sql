CREATE OR REPLACE VIEW query_14 as 
WITH first_table AS (
    SELECT 
        LEFT(d.icd, 1) AS icd_category,
        YEAR(n.imerominia_eisodou) AS year_,
        COUNT(*) AS admissions_count
    FROM diagnosi d
    JOIN nosileia n 
        ON n.nosileia_id = d.nosileia_id
    WHERE d.tipos_diagnosis = 'Εισοδος'
    GROUP BY 
        LEFT(d.icd, 1),
        YEAR(n.imerominia_eisodou)
)
SELECT
    f1.icd_category,
    f1.year_ AS year_1,
    f2.year_ AS year_2,
    f1.admissions_count
FROM first_table f1
JOIN first_table f2
    ON f2.icd_category = f1.icd_category
   AND f2.year_ = f1.year_ + 1
   AND f2.admissions_count = f1.admissions_count
WHERE f1.admissions_count >= 5;
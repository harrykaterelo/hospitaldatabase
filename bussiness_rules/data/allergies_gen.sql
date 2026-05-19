SET NAMES utf8mb4;

-- =====================================================
-- Allergy data generator
-- Κάθε ασθενής αποκτά τυχαία 0-5 αλλεργίες σε δραστικές ουσίες
-- =====================================================

INSERT INTO allergy (amka_astheni, ousia_id)
WITH patient_allergy_count AS (
    SELECT
        amka,
        FLOOR(RAND() * 6) AS num_allergies
    FROM asthenis
),
ranked AS (
    SELECT
        p.amka,
        o.ousia_id,
        p.num_allergies,
        ROW_NUMBER() OVER (PARTITION BY p.amka ORDER BY RAND()) AS rn
    FROM patient_allergy_count p
    CROSS JOIN drastiki_ousia o
    WHERE p.num_allergies > 0
)
SELECT amka, ousia_id
FROM ranked
WHERE rn <= num_allergies;

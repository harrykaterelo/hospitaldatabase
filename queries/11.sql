CREATE OR REPLACE VIEW query_11 AS
WITH iatroiMeEpemvaseisAirithmo AS (
    SELECT
        p.amka_kyriou_xeirourgou,
        COUNT(*) AS num_iatrikes
    FROM iatrikipraxi p
    GROUP BY p.amka_kyriou_xeirourgou
),
allIatroiMeEpemvaseisArithmo AS (
    SELECT
        i.amka AS amka_kyriou_xeirourgou,
        COALESCE(epemv.num_iatrikes, 0) AS num_iatrikes
    FROM iatros i
    LEFT JOIN iatroiMeEpemvaseisAirithmo epemv
        ON epemv.amka_kyriou_xeirourgou = i.amka
),
ranked AS (
    SELECT
        amka_kyriou_xeirourgou,
        num_iatrikes,
        RANK() OVER (ORDER BY num_iatrikes DESC) AS rnk
    FROM allIatroiMeEpemvaseisArithmo
),
keepMax AS (
    SELECT MAX(num_iatrikes) AS max_num_iatrikes
    FROM allIatroiMeEpemvaseisArithmo
)
SELECT
    r.amka_kyriou_xeirourgou,
    a.onoma,
    a.eponymo,
    r.num_iatrikes
FROM ranked r
JOIN anthropos a
    ON a.amka = r.amka_kyriou_xeirourgou
WHERE r.num_iatrikes <= (
    SELECT max_num_iatrikes - 5
    FROM keepMax
);
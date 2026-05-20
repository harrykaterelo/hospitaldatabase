CREATE OR REPLACE VIEW query_13 AS
WITH RECURSIVE hierarchy AS (
    -- Επίπεδο 1: άμεσος επόπτης κάθε ιατρού
    SELECT
        i.amka AS amka_iatrou,
        i.amka_epoptis AS amka_epopti,
        1 AS epipedo
    FROM iatros i
    WHERE i.amka_epoptis IS NOT NULL

    UNION ALL

    -- Επόμενα επίπεδα: επόπτης του επόπτη
    SELECT
        h.amka_iatrou,
        i.amka_epoptis AS amka_epopti,
        h.epipedo + 1 AS epipedo
    FROM hierarchy h
    JOIN iatros i
        ON i.amka = h.amka_epopti
    WHERE i.amka_epoptis IS NOT NULL
)
SELECT
    h.amka_iatrou,
    a_iatros.onoma AS onoma_iatrou,
    h.amka_epopti,
    a_epoptis.onoma AS onoma_epopti,
    h.epipedo
FROM hierarchy h
JOIN proswpiko p_iatros
    ON p_iatros.amka = h.amka_iatrou
JOIN proswpiko p_epoptis
    ON p_epoptis.amka = h.amka_epopti
join anthropos a_iatros on
    a_iatros.amka =h.amka_iatrou
join anthropos a_epoptis on
    a_epoptis.amka = h.amka_epopti;
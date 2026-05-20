-- ============================================================
-- Query 4
-- Για συγκεκριμένο ιατρό, υπολογισμός του μέσου όρου των
-- αξιολογήσεων των ασθενών του:
--   * Ποιότητα ιατρικής φροντίδας  -> poiotita_iatr_frontidas
--   * Συνολική εντύπωση νοσηλείας  -> synoliki_empeiria
--
-- Ως "ασθενείς του ιατρού" θεωρούμε όσες νοσηλείες (nosileia)
-- σχετίζονται με τον ιατρό είτε μέσω εξέτασης (exetasi.amka_iatrou)
-- είτε μέσω ιατρικής πράξης ως κύριος χειρουργός
-- (iatrikipraxi.amka_kyriou_xeirourgou).
-- ============================================================

DROP PROCEDURE IF EXISTS query_4;

DELIMITER //
CREATE PROCEDURE query_4(IN p_amka CHAR(11))
BEGIN
    WITH nosileies_iatrou AS (
        SELECT DISTINCT nosileia_id
        FROM exetasi
        WHERE amka_iatrou = p_amka
        UNION
        SELECT DISTINCT nosileia_id
        FROM iatrikipraxi
        WHERE amka_kyriou_xeirourgou = p_amka
    )
    SELECT
        p_amka                                       AS amka_iatrou,
        COUNT(*)                                     AS plithos_axiologiseon,
        ROUND(AVG(a.poiotita_iatr_frontidas), 2)     AS mo_poiotita_iatr_frontidas,
        ROUND(AVG(a.synoliki_empeiria), 2)           AS mo_synoliki_empeiria
    FROM nosileies_iatrou ni
    JOIN axiologisi a ON a.nosileia_id = ni.nosileia_id;
END //
DELIMITER ;

-- ============================================================
-- (α) EXPLAIN / EXPLAIN ANALYZE - κανονική έκδοση
-- (αφήνουμε τον optimizer να διαλέξει τα indexes — αναμένεται
--  ref lookup στα FK indexes exetasi.amka_iatrou και
--  iatrikipraxi.amka_kyriou_xeirourgou, μετά eq_ref στο
--  PRIMARY KEY του axiologisi).
-- ============================================================

-- Αντικατέστησε το '12345678901' με ένα πραγματικό amka ιατρού
-- ώστε ο optimizer να βλέπει σταθερές τιμές (literals).
EXPLAIN
SELECT
    COUNT(*)                                     AS plithos_axiologiseon,
    ROUND(AVG(a.poiotita_iatr_frontidas), 2)     AS mo_poiotita_iatr_frontidas,
    ROUND(AVG(a.synoliki_empeiria), 2)           AS mo_synoliki_empeiria
FROM (
    SELECT DISTINCT nosileia_id
    FROM exetasi
    WHERE amka_iatrou = '12345678901'
    UNION
    SELECT DISTINCT nosileia_id
    FROM iatrikipraxi
    WHERE amka_kyriou_xeirourgou = '12345678901'
) ni
JOIN axiologisi a ON a.nosileia_id = ni.nosileia_id;

EXPLAIN ANALYZE
SELECT
    COUNT(*)                                     AS plithos_axiologiseon,
    ROUND(AVG(a.poiotita_iatr_frontidas), 2)     AS mo_poiotita_iatr_frontidas,
    ROUND(AVG(a.synoliki_empeiria), 2)           AS mo_synoliki_empeiria
FROM (
    SELECT DISTINCT nosileia_id
    FROM exetasi
    WHERE amka_iatrou = '12345678901'
    UNION
    SELECT DISTINCT nosileia_id
    FROM iatrikipraxi
    WHERE amka_kyriou_xeirourgou = '12345678901'
) ni
JOIN axiologisi a ON a.nosileia_id = ni.nosileia_id;


-- ============================================================
-- (β) Εναλλακτική έκδοση με hints / FORCE INDEX
-- USE INDEX () "αδειάζει" τη λίστα διαθέσιμων indexes, οπότε
-- αναγκάζει full table scan στους πίνακες exetasi και
-- iatrikipraxi. Έτσι φαίνεται καθαρά η διαφορά πλάνου
-- και χρόνου εκτέλεσης.
-- ============================================================

EXPLAIN
SELECT
    COUNT(*)                                     AS plithos_axiologiseon,
    ROUND(AVG(a.poiotita_iatr_frontidas), 2)     AS mo_poiotita_iatr_frontidas,
    ROUND(AVG(a.synoliki_empeiria), 2)           AS mo_synoliki_empeiria
FROM (
    SELECT DISTINCT nosileia_id
    FROM exetasi USE INDEX ()
    WHERE amka_iatrou = '12345678901'
    UNION
    SELECT DISTINCT nosileia_id
    FROM iatrikipraxi USE INDEX ()
    WHERE amka_kyriou_xeirourgou = '12345678901'
) ni
JOIN axiologisi a ON a.nosileia_id = ni.nosileia_id;

EXPLAIN ANALYZE
SELECT
    COUNT(*)                                     AS plithos_axiologiseon,
    ROUND(AVG(a.poiotita_iatr_frontidas), 2)     AS mo_poiotita_iatr_frontidas,
    ROUND(AVG(a.synoliki_empeiria), 2)           AS mo_synoliki_empeiria
FROM (
    SELECT DISTINCT nosileia_id
    FROM exetasi USE INDEX ()
    WHERE amka_iatrou = '12345678901'
    UNION
    SELECT DISTINCT nosileia_id
    FROM iatrikipraxi USE INDEX ()
    WHERE amka_kyriou_xeirourgou = '12345678901'
) ni
JOIN axiologisi a ON a.nosileia_id = ni.nosileia_id;

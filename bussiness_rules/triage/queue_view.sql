-- ============================================================
-- View: oura_anamenomenwn
-- Εμφανίζει την ουρά αναμονής του ΤΕΠ:
--   • Μόνο εκκρεμείς ασθενείς (apotelesma IS NULL)
--   • Ταξινόμηση: πρώτα ανά επίπεδο επείγοντος (1 = πιο επείγον),
--                 για ίδιο επίπεδο αυστηρή FIFO βάσει wra_afiksis
-- ============================================================

CREATE OR REPLACE VIEW oura_anamenomenwn AS
SELECT
    d.id_dialogis,
    d.epipedo,
    CASE d.epipedo
        WHEN 1 THEN 'Άμεσο'
        WHEN 2 THEN 'Επείγον'
        WHEN 3 THEN 'Επιτακτικό'
        WHEN 4 THEN 'Λιγότερο επείγον'
        WHEN 5 THEN 'Μη επείγον'
    END                                         AS perigrafi_epipedou,
    d.wra_afiksis,
    TIMESTAMPDIFF(MINUTE, d.wra_afiksis, NOW()) AS lepta_anamon_is,
    a.amka                                      AS amka_astheni,
    ant.onoma                                   AS onoma_astheni,
    ant.eponymo                                 AS eponymo_astheni,
    d.symptomata,
    pn.onoma                                    AS onoma_nosilevti,
    pn.eponymo                                  AS eponymo_nosilevti
FROM dialogistoixeiwn d
JOIN asthenis   a   ON a.amka  = d.amka_astheni
JOIN anthropos  ant ON ant.amka = a.amka
JOIN nosileutis n   ON n.amka  = d.amka_nosilevti
JOIN proswpiko  p   ON p.amka  = n.amka
JOIN anthropos  pn  ON pn.amka = p.amka
WHERE d.apotelesma IS NULL
ORDER BY d.epipedo ASC, d.wra_afiksis ASC;

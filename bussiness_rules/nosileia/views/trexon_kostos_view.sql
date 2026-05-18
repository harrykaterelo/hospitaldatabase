-- ============================================================
-- View: trexon_kostos_nosileia
-- Εμφανίζει το τρέχον κόστος κάθε νοσηλείας:
--   • Αν υπάρχει Εξοδος → χρησιμοποιεί το αποθηκευμένο synoliko_kostos
--   • Αν δεν υπάρχει Εξοδος → υπολογίζει δυναμικά με CURDATE()
-- ============================================================

CREATE OR REPLACE VIEW trexon_kostos_nosileia AS
SELECT
    n.nosileia_id,
    n.amka_astheni,
    n.imerominia_eisodou                        AS imer_eisagogis,
    n.imerominia_eksodou                        AS imer_exodou,
    CASE
        WHEN n.imerominia_eksodou IS NOT NULL
            THEN n.synoliko_kostos
        ELSE
            CASE
                WHEN DATEDIFF(CURDATE(), n.imerominia_eisodou) <= k.mdn
                    THEN k.vasiko_kostos
                ELSE
                    k.vasiko_kostos + (DATEDIFF(CURDATE(), n.imerominia_eisodou) - k.mdn) * k.imer_xrewsi
            END
            + COALESCE(ex_sum.total_exetasewn, 0)
            + COALESCE(ip_sum.total_praxewn, 0)
    END                                         AS trexon_kostos,
    CASE WHEN n.imerominia_eksodou IS NULL THEN 'Ανοιχτή' ELSE 'Κλειστή' END AS katastasi
FROM nosileia n
JOIN ken k ON k.kod_ken = n.kod_ken
LEFT JOIN (SELECT nosileia_id, SUM(kostos) AS total_exetasewn FROM exetasi GROUP BY nosileia_id) ex_sum
    ON ex_sum.nosileia_id = n.nosileia_id
LEFT JOIN (SELECT nosileia_id, SUM(kostos) AS total_praxewn FROM iatrikipraxi GROUP BY nosileia_id) ip_sum
    ON ip_sum.nosileia_id = n.nosileia_id;

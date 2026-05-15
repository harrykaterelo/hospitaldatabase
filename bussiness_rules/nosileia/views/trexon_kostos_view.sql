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
    d_eis.imerominia                            AS imer_eisagogis,
    d_ex.imerominia                             AS imer_exodou,
    CASE
        WHEN d_ex.imerominia IS NOT NULL
            THEN n.synoliko_kostos
        ELSE
            CASE
                WHEN DATEDIFF(CURDATE(), d_eis.imerominia) <= k.mdn
                    THEN k.vasiko_kostos
                ELSE
                    k.vasiko_kostos + (DATEDIFF(CURDATE(), d_eis.imerominia) - k.mdn) * k.imer_xrewsi
            END
            + COALESCE(ex_sum.total_exetasewn, 0)
            + COALESCE(ip_sum.total_praxewn, 0)
    END                                         AS trexon_kostos,
    CASE WHEN d_ex.imerominia IS NULL THEN 'Ανοιχτή' ELSE 'Κλειστή' END AS katastasi
FROM nosileia n
JOIN ken k ON k.kod_ken = n.kod_ken
LEFT JOIN diagnosi d_eis ON d_eis.nosileia_id = n.nosileia_id AND d_eis.tipos_diagnosis = 'Εισοδος'
LEFT JOIN diagnosi d_ex  ON d_ex.nosileia_id  = n.nosileia_id AND d_ex.tipos_diagnosis  = 'Εξοδος'
LEFT JOIN (SELECT nosileia_id, SUM(kostos) AS total_exetasewn FROM exetasi GROUP BY nosileia_id) ex_sum
    ON ex_sum.nosileia_id = n.nosileia_id
LEFT JOIN (SELECT nosileia_id, SUM(kostos) AS total_praxewn FROM iatrikipraxi GROUP BY nosileia_id) ip_sum
    ON ip_sum.nosileia_id = n.nosileia_id;

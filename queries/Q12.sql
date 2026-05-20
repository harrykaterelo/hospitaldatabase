DROP PROCEDURE IF EXISTS query_12;

DELIMITER //

CREATE PROCEDURE query_12(
    IN p_week_start DATE
)
BEGIN
    -- Πρώτη ημέρα της εβδομάδας = p_week_start (συμπεριλαμβάνεται)
    -- Τελευταία ημέρα της εβδομάδας = p_week_start + 6 ημέρες
    SELECT
        t.tmima_id,
        t.onoma                            AS tmima_onoma,
        v.vardia_id,
        v.vardia_onoma,
        p.typos_proswpikou,
        CASE
            WHEN p.typos_proswpikou = 'Ιατρός'     THEN 'Ειδικότητα'
            WHEN p.typos_proswpikou = 'Νοσηλευτής' THEN 'Βαθμίδα'
            ELSE 'Ρόλος'
        END                                AS ypoklasi_label,
        CASE
            WHEN p.typos_proswpikou = 'Ιατρός'     THEN i.eidikotita
            WHEN p.typos_proswpikou = 'Νοσηλευτής' THEN n.vathmida_nosileuti
            ELSE d.rolos
        END                                AS ypoklasi_timi,
        COUNT(*)                           AS apaitoumeno_proswpiko
    FROM efimeria_proswpiko ep
    JOIN efimeria e
        ON  e.tmima      = ep.tmima
        AND e.imerominia = ep.imerominia
        AND e.vardia     = ep.vardia
    JOIN tmima t
        ON t.tmima_id = ep.tmima
    JOIN vardia v
        ON v.vardia_id = ep.vardia
    JOIN proswpiko p
        ON p.amka = ep.amka_proswpiko
    LEFT JOIN iatros i
        ON i.amka = p.amka
    LEFT JOIN nosileutis n
        ON n.amka = p.amka
    LEFT JOIN dioikitiko d
        ON d.amka = p.amka
    WHERE ep.imerominia >= p_week_start
      AND ep.imerominia <  DATE_ADD(p_week_start, INTERVAL 7 DAY)
    GROUP BY
        t.tmima_id,
        t.onoma,
        v.vardia_id,
        v.vardia_onoma,
        p.typos_proswpikou,
        ypoklasi_timi
    ORDER BY
        t.onoma,
        v.vardia_id,
        p.typos_proswpikou,
        ypoklasi_timi;
END //

DELIMITER ;
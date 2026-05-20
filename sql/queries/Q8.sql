DROP PROCEDURE IF EXISTS query_8;

DELIMITER //

CREATE PROCEDURE query_8(
    IN p_imerominia DATE,
    IN p_tmima INT
)
BEGIN
    SELECT
        p.amka,
        
        p.typos_proswpikou,
        CASE
            WHEN p.typos_proswpikou = 'Ιατρός' THEN i.eidikotita
            WHEN p.typos_proswpikou = 'Νοσηλευτής' THEN n.vathmida_nosileuti
            ELSE d.rolos
        END AS vathmida_proswpikou
    FROM proswpiko p
    JOIN proswpiko_anikei_se_tmima pat
        ON pat.amka_proswpikou = p.amka
    LEFT JOIN iatros i
        ON i.amka = p.amka
    LEFT JOIN nosileutis n
        ON n.amka = p.amka
    LEFT JOIN dioikitiko d
        ON d.amka = p.amka
    WHERE pat.tmima_id = p_tmima
      AND NOT EXISTS (
          SELECT 1
          FROM efimeria_proswpiko ep
          WHERE ep.amka_proswpiko = p.amka
            AND ep.tmima = p_tmima
            AND ep.imerominia = p_imerominia
      )
    ORDER BY p.typos_proswpikou;
END //

DELIMITER ;
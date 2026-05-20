WITH triageStats AS (
    SELECT
        epipedo,
        COUNT(*) AS peristatika_ana_epipedo,
        AVG(TIMESTAMPDIFF(MINUTE, wra_afiksis, wra_oloklirosis)) / 60.0 AS avg_anamoni,
        SUM(CASE 
                WHEN apotelesma = 'Παραπομπή' 
                THEN 1 
                ELSE 0 
            END) AS arithmos_parapobon
    FROM dialogistoixeiwn
    WHERE wra_oloklirosis IS NOT NULL
    GROUP BY epipedo
),
referralsPerDepartment AS (
    SELECT
        d.epipedo,
        t.onoma AS tmima_onoma,
        COUNT(DISTINCT n.nosileia_id) AS parapobes_ana_tmima
    FROM dialogistoixeiwn d
    JOIN parapobi_gia_nosileia pn
        ON pn.id_dialogis = d.id_dialogis
    JOIN nosileia n
        ON n.nosileia_id = pn.nosileia_id
    JOIN tmima t
        ON t.tmima_id = n.tmima_id
    WHERE d.apotelesma = 'Παραπομπή'
    GROUP BY d.epipedo, n.tmima_id, t.onoma
)
SELECT
    s.epipedo,
    ROUND(s.avg_anamoni, 2) AS mesi_anamoni_se_ores,
    s.peristatika_ana_epipedo,
    s.arithmos_parapobon,
    ROUND(s.arithmos_parapobon * 100.0 / s.peristatika_ana_epipedo, 2) AS parapobes_pososto_tis_ekato,
    r.tmima_onoma,
    r.parapobes_ana_tmima
FROM triageStats s
LEFT JOIN referralsPerDepartment r
    ON r.epipedo = s.epipedo
ORDER BY s.epipedo, r.parapobes_ana_tmima DESC;
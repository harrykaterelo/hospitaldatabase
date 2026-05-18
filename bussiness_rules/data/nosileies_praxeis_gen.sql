
DROP TABLE IF EXISTS seed_add_nosileia;
DROP TABLE IF EXISTS seed_add_iatriki_praxi;
DROP TABLE IF EXISTS generated_full_seed;


CREATE TABLE generated_full_seed (
    nosileia_id_seed        INT,
    amka_astheni            CHAR(11),
    tmima_id                INT,
    ar_kliis                SMALLINT,
    kod_ken                 VARCHAR(20),
    imerominia_eisodou      DATETIME,
    imerominia_eksodou      DATETIME,
    icd_eisodou             VARCHAR(10),
    icd_eksodou             VARCHAR(10),

    has_iatriki_praxi       TINYINT,
    iatriki_praxi_date      DATETIME,
    amka_iatrou             CHAR(11),
    vardia_onoma            VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO generated_full_seed (
    nosileia_id_seed,
    amka_astheni,
    tmima_id,
    ar_kliis,
    kod_ken,
    imerominia_eisodou,
    imerominia_eksodou,
    icd_eisodou,
    icd_eksodou,
    has_iatriki_praxi,
    iatriki_praxi_date,
    amka_iatrou,
    vardia_onoma
)
WITH RECURSIVE nums AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM nums
    WHERE n < 10
    
    
),
date_total AS (
    SELECT COUNT(*) AS total_dates
    FROM date_hours
),
randomized_dates AS (
    SELECT
        dh.datetime_value,
        ROW_NUMBER() OVER (ORDER BY RAND()) AS date_rn,
        dt.total_dates
    FROM date_hours dh
    CROSS JOIN date_total dt
),
 randomized_buckets AS(SELECT 
    datetime_value,
    CEIL(date_rn / (total_dates / 200.0)) AS bucket_num
FROM randomized_dates),

patientsNumbered AS (
    SELECT
        a.amka,
        ROW_NUMBER() OVER (ORDER BY RAND()) AS rn
    FROM asthenis a
    ORDER BY RAND()
    LIMIT 200
    
),

patientsMatch AS (
    SELECT
        p.amka,
        n.n,
        p.rn,
        b.datetime_value,
        ROW_NUMBER() OVER (
            PARTITION BY p.amka
            ORDER BY RAND()
        ) AS rn_inside_patient
    FROM patientsNumbered p
    JOIN nums n
        ON ((p.rn - 1) % 10) + 1 = n.n
	JOIN randomized_buckets b
		on b.bucket_num = p.rn
	
),
patientsDatesKept AS (
    SELECT amka, datetime_value
    FROM patientsMatch 
    WHERE rn_inside_patient < n
),
exagogi_duration AS (
    SELECT 5 AS days_to_add
    UNION ALL
    SELECT days_to_add + 1
    FROM exagogi_duration
    WHERE dayS_to_add < 15
),


patientDatesCount AS (
    SELECT COUNT(*) AS countTotal
    FROM patientsDatesKept
),
numbered AS (
    SELECT 
        pdk.amka,
        pdk.datetime_value,
        pC.countTotal,
        ROW_NUMBER() OVER (ORDER BY RAND()) AS rn
    FROM patientsDatesKept pdk
    CROSS JOIN patientDatesCount pC
),
nosilStartAndEndDates as(

	select pdk.amka,
        pdk.datetime_value,
        DATE_ADD(datetime_value, INTERVAL ex_d.days_to_add DAY) as 'datetime_exagogis',
        pdk.countTotal,
        pdk.rn as nosileia_id
    FROM numbered pdk
    join exagogi_duration ex_d
    on ((pdk.rn-1)%10)+5 = ex_d.days_to_add
),
nosilStartEndDiagnosis as(
	SELECT n.nosileia_id,
    (select kodikos from icd order by rand() limit 1) as diagnosi_eisodou,
    (select kodikos from icd order by rand() limit 1) as diagnosi_exodou
    from nosilStartAndEndDates n
			
) ,
nosilKen as (
	SELECT nosileia_id,
    (select kod_ken from ken order by rand() limit 1) as kodikos_ken
    from nosilStartAndEndDates
    

),


numberOfIatrikesPraxeis AS(
select 1 as num_praxeis UNION ALL SELECT num_praxeis+1 from numberOfIatrikesPraxeis where num_praxeis<3),
hasIatrikiPraxi AS (
    SELECT
        amka,
        datetime_value,
        datetime_exagogis,
        CASE 
            WHEN countTotal / 2 < nosileia_id THEN 1 
            ELSE 0 
        END AS hasIatrikiPraxi,
        nosileia_id
    FROM nosilStartAndEndDates
),
iatrikiPraxiDates as (
SELECT 
i.datetime_value,
i.amka,
datetime_exagogis,
i.hasIatrikiPraxi,
nip.num_praxeis as num_praxeis,
dh.datetime_value as 'iatriki_praxi_date',
ROW_NUMBER() OVER (PARTITION BY i.datetime_value,i.datetime_exagogis order by rand()) as group_id,
i.nosileia_id from hasIatrikiPraxi i 
left join date_hours dh 
on dh.datetime_value between i.datetime_value and i.datetime_exagogis and i.hasIatrikiPraxi=1
LEFT JOIN numberOfIatrikesPraxeis nip 
    ON ((i.nosileia_id - 1) % 3) + 1 = nip.num_praxeis
   AND i.hasIatrikiPraxi = 1

),
departmentsNumbered AS (
    SELECT
        t.*,
        ROW_NUMBER() OVER (ORDER BY t.tmima_id) AS dept_rn,
        COUNT(*) OVER () AS dept_count
    FROM tmima t
    where t.onoma!='Επειγόντων'
),

nosileiesNumberedForDept AS (
    SELECT
        nosileia_id,
        ROW_NUMBER() OVER (ORDER BY nosileia_id) AS nosileia_dept_rn
    FROM (
        SELECT DISTINCT nosileia_id
        FROM iatrikiPraxiDates
        
    ) x
),

nosileiaDepartments AS (
    SELECT
        n.nosileia_id,
        d.tmima_id
    FROM nosileiesNumberedForDept n
    JOIN departmentsNumbered d
        ON d.dept_rn = ((n.nosileia_dept_rn - 1) % d.dept_count) + 1 
),

assignDepartments AS (
    SELECT
        i.*,
        nd.tmima_id
    FROM iatrikiPraxiDates i
    JOIN nosileiaDepartments nd
        ON nd.nosileia_id = i.nosileia_id
    WHERE i.group_id <= i.num_praxeis or i.hasIatrikiPraxi=0
),
nosilKliniNumbered as (
	SELECT ar_kliis ,tmima_id ,ROW_NUMBER() OVER (partition by tmima_id order by rand()) as rn
    from klini
),
nosilKlini AS (
    SELECT DISTINCT
        n.nosileia_id,
        k.ar_kliis
    FROM assignDepartments n
    JOIN nosilKliniNumbered k 
        ON k.tmima_id = n.tmima_id 
       AND k.rn = 1
),
praxisWithShifts AS (
    SELECT *
    FROM (
        SELECT
            a.*,
            x.vardia_onoma,
            x.amka AS amka_iatrou,
            ROW_NUMBER() OVER (
                PARTITION BY a.nosileia_id, a.iatriki_praxi_date
                ORDER BY RAND()
            ) AS doctor_rn
        FROM assignDepartments a
        LEFT JOIN (
            SELECT 
                v.vardia_onoma,
                e.tmima,
                e.imerominia,
                v.vardia_ora_ekkinisis AS start_time,
                v.vardia_ora_lixis AS end_time,
                e.amka_proswpiko AS amka
            FROM efimeria_proswpiko e
            JOIN vardia v 
                ON e.vardia = v.vardia_id
            JOIN iatros i
                ON i.amka = e.amka_proswpiko
        ) x 
            ON x.tmima = a.tmima_id
           AND (
                (
                    x.start_time < x.end_time
                    AND DATE(a.iatriki_praxi_date) = x.imerominia
                    AND TIME(a.iatriki_praxi_date) >= x.start_time
                    AND TIME(a.iatriki_praxi_date) < x.end_time
                )
                OR
                (
                    x.start_time > x.end_time
                    AND (
                        (
                            DATE(a.iatriki_praxi_date) = x.imerominia
                            AND TIME(a.iatriki_praxi_date) >= x.start_time
                        )
                        OR
                        (
                            DATE(a.iatriki_praxi_date) = DATE_ADD(x.imerominia, INTERVAL 1 DAY)
                            AND TIME(a.iatriki_praxi_date) < x.end_time
                        )
                    )
                )
           )
    ) z
    WHERE z.doctor_rn = 1
)

SELECT
    p.nosileia_id,
    p.amka,
    p.tmima_id,
    k.ar_kliis,
    n.kodikos_ken,
    p.datetime_value,
    p.datetime_exagogis,
    d.diagnosi_eisodou,
    d.diagnosi_exodou,
    p.hasIatrikiPraxi,
    p.iatriki_praxi_date,
    p.amka_iatrou,
    p.vardia_onoma
FROM praxisWithShifts p
JOIN nosilStartEndDiagnosis d 
    ON d.nosileia_id = p.nosileia_id
JOIN nosilKen n 
    ON n.nosileia_id = p.nosileia_id
JOIN nosilKlini k 
    ON k.nosileia_id = p.nosileia_id;






 

UPDATE nosileia n
JOIN (
    SELECT real1.real_amka AS realAm, fake.fake_amka AS fakeAm
    FROM (
        SELECT amka_astheni AS fake_amka,
               ROW_NUMBER() OVER (ORDER BY RAND()) AS rn
        FROM (SELECT DISTINCT amka_astheni FROM nosileia) x
    ) AS fake
    JOIN (
        SELECT amka AS real_amka,
               ROW_NUMBER() OVER (ORDER BY RAND()) AS rn
        FROM asthenis
    ) AS real1 ON fake.rn = real1.rn
) AS newTable ON newTable.fakeAm = n.amka_astheni
SET n.amka_astheni = newTable.realAm;

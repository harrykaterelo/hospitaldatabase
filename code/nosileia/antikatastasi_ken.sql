UPDATE nosileia n
JOIN (
    SELECT real1.real_ken AS realKen, fake.fake_ken AS fakeKen
    FROM (
        SELECT kod_ken AS fake_ken,
               ROW_NUMBER() OVER (ORDER BY RAND()) AS rn
        FROM (SELECT DISTINCT kod_ken FROM nosileia) x
    ) AS fake
    JOIN (
        SELECT kod_ken AS real_ken,
               ROW_NUMBER() OVER (ORDER BY RAND()) AS rn
        FROM ken
    ) AS real1 ON fake.rn = real1.rn
) AS newTable ON newTable.fakeKen = n.kod_ken
SET n.kod_ken = newTable.realKen;

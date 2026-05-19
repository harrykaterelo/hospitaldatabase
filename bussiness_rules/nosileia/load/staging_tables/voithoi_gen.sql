
DROP TABLE IF EXISTS voithoi_seed;
CREATE TABLE voithoi_seed (
    kod_praxis      VARCHAR(20)     NOT NULL,
    amka_voithou    CHAR(11)        NOT NULL,
    PRIMARY KEY (kod_praxis, amka_voithou),
    FOREIGN KEY (kod_praxis) REFERENCES iatrikipraxi(kodikos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (amka_voithou) REFERENCES proswpiko(amka)
        ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO voithoi_seed (kod_praxis,amka_voithou)
with RECURSIVE voithoiLimit as(

	SELECT 0 as limitVoithon
    union all
    select limitVoithon+1 from voithoiLimit
    where limitVoithon<=3
    
),
 iatrikiPraxiWithVoithousLimit as(
	select i.*,v.limitVoithon,n.tmima_id from (
	select * , ROW_NUMBER() OVER (ORDER BY RAND() ) as rn FROM iatrikipraxi) as i
    join voithoiLimit v on v.limitVoithon = (rn%3)+1 join nosileia n on n.nosileia_id = i.nosileia_id)
,
groupBySameEfimeria as (

select i.*,x.imerominia,x.tmima,x.vardia,COUNT(*) OVER (
            PARTITION BY x.imerominia, x.vardia
        ) AS group_count,
ROW_NUMBER() OVER (partition by x.imerominia,x.vardia order by i.kodikos) as row_num from iatrikiPraxiWithVoithousLimit i
join (SELECT e.*,v.* from efimeria e join vardia v on v.vardia_id=e.vardia where e.tmima !=20 )x
on ((
                    x.vardia_ora_ekkinisis < x.vardia_ora_lixis
                    AND DATE(i.imerominia_wra) = x.imerominia
                    AND TIME(i.imerominia_wra) >= x.vardia_ora_ekkinisis
                    AND TIME(i.imerominia_wra) < x.vardia_ora_lixis
                )
                OR
                (
                    x.vardia_ora_ekkinisis > x.vardia_ora_lixis
                    AND (
                        (
                            DATE(i.imerominia_wra) = x.imerominia
                            AND TIME(i.imerominia_wra) >= x.vardia_ora_ekkinisis
                        )
                        OR
                        (
                            DATE(i.imerominia_wra) = DATE_ADD(x.imerominia, INTERVAL 1 DAY)
                            AND TIME(i.imerominia_wra) < x.vardia_ora_lixis
                        )
                    )
                ) ) ),
 keepOnly as(
 select i.* from groupBySameEfimeria i where  ((i.row_num - 1) % 20) = 0
 ),
 findVoithous as(
	SELECT k.*,e.amka_proswpiko,ROW_NUMBER() OVER (PARTITION BY k.kodikos ORDER BY RAND()) as proswpiko_num from keepOnly k join efimeria_proswpiko e 
    on e.amka_proswpiko!=k.amka_kyriou_xeirourgou 
    and e.tmima = k.tmima and k.vardia = e.vardia and e.imerominia=k.imerominia)
SELECT kodikos,amka_proswpiko as amka_voithou from findVoithous where proswpiko_num<=limitVoithon;
 
 

 

    

CREATE TABLE efimeria_proswpiko (
        tmima  INT    NOT NULL,
        imerominia      DATE            NOT NULL,
        vardia          INT NOT NULL,
        amka_proswpiko  CHAR(11)        NOT NULL,
        PRIMARY KEY (tmima, imerominia, vardia, amka_proswpiko),
        FOREIGN KEY (tmima, imerominia, vardia)
            REFERENCES efimeria(tmima, imerominia, vardia)
            ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY (amka_proswpiko) REFERENCES proswpiko(amka)
           ON DELETE CASCADE ON UPDATE CASCADE
    ) 
    ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE efimeria_requirements (
    iatros_max_monthly_ef_count INT NOT NULL DEFAULT 15,
    nosileutes_max_monthly_ef_count INT NOT NULL DEFAULT 20,
    dioikitiko_max_monthly_ef_count INT NOT NULL DEFAULT 25,
    iatros_min_count INT NOT NULL DEFAULT 3 CHECK (iatros_min_count >= 0),
    nosileutes_min_count INT NOT NULL DEFAULT 6 CHECK (nosileutes_min_count >= 0),
    dioikitiko_min_count INT NOT NULL DEFAULT 2 CHECK (dioikitiko_min_count >= 0),
    PRIMARY KEY (iatros_min_count, nosileutes_min_count, dioikitiko_min_count)
);
CREATE TABLE efimeria (
        statusEf VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
        tmima  INT    NOT NULL,
        imerominia      DATE            NOT NULL,
        vardia          INT NOT NULL,
        FOREIGN KEY (vardia) REFERENCES vardia(vardia_id),
        PRIMARY KEY (tmima, imerominia, vardia),
        FOREIGN KEY (tmima) REFERENCES tmima(tmima_id)
            ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE vardia (
    vardia_id INT AUTO_INCREMENT PRIMARY KEY,
    vardia_onoma VARCHAR(15) NOT NULL
        CHECK (vardia_onoma IN ('Πρωινή','Απογευματινή','Νυχτερινή')),
    
    vardia_ora_ekkinisis TIME NOT NULL,
    vardia_ora_lixis TIME NOT NULL,
    endiamesi_ora_anapausis_hours INT NOT NULL CHECK (endiamesi_ora_anapausis_hours >= 0),
    epitreptes_sinexomenes_vardies INT  NULL CHECK (epitreptes_sinexomenes_vardies >= 0)
);
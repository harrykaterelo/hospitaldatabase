CREATE TABLE asthenis (
    amka                CHAR(11)        NOT NULL,
    patronymo           VARCHAR(50)     NULL,
    fylo VARCHAR(10) NOT NULL CHECK (fylo IN ('Αρσενικό', 'Θηλυκό')),
    varos               DECIMAL(5,2)    NULL CHECK (varos > 0),
    ypsos               DECIMAL(5,2)    NULL CHECK (ypsos > 0),
    diefthinsi          VARCHAR(200)    NULL,
    epangelma           VARCHAR(100)    NULL,
    ypikoiotita         VARCHAR(50)     NULL,
    asfalistikos_foreas VARCHAR(100)    NOT NULL,
    PRIMARY KEY (amka),
    FOREIGN KEY (amka) REFERENCES anthropos(amka)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ektakti_epafi (
    amka_astheni    CHAR(11)        NOT NULL,
    tilefono        VARCHAR(15)     NOT NULL,
    onoma           VARCHAR(50)     NOT NULL,
    eponymo         VARCHAR(50)     NOT NULL,
    email           VARCHAR(100)    NULL,
    PRIMARY KEY (amka_astheni, tilefono),
    FOREIGN KEY (amka_astheni) REFERENCES asthenis(amka)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
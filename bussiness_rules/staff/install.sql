
SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;

CREATE TABLE anthropos (
    amka            CHAR(11)        NOT NULL,
    onoma           VARCHAR(50)     NOT NULL,
    eponymo         VARCHAR(50)     NOT NULL,
    ilikia          SMALLINT        NOT NULL CHECK (ilikia BETWEEN 0 AND 150),
    email           VARCHAR(100)    NOT NULL,
    tilefono        VARCHAR(15)     NOT NULL,
    PRIMARY KEY (amka)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE vathmida_iatrou(
    vathmida_id INT AUTO_INCREMENT PRIMARY KEY,
    vathmida_onoma VARCHAR(30),
    is_supervised BOOL NULL,
    can_supervise BOOL NULL,
    can_cover_specialist_shift BOOL NOT NULL DEFAULT 0,
    can_run_department BOOL NOT NULL DEFAULT 0
);
CREATE TABLE proswpiko (
    amka                    CHAR(11)        NOT NULL,
    imerominia_proslipsis   DATE            NOT NULL,
    typos_proswpikou        VARCHAR(20)     NOT NULL
         CHECK (typos_proswpikou IN ('Ιατρός', 'Νοσηλευτής', 'Διοικητικό')),

    PRIMARY KEY (amka),
    FOREIGN KEY (amka) 
        REFERENCES anthropos(amka)
        ON DELETE CASCADE 
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
 CREATE TABLE iatros (
    amka            CHAR(11)        NOT NULL,
    ar_ad_is        VARCHAR(20)     NOT NULL UNIQUE,
    eidikotita      VARCHAR(80)     NOT NULL,
    vathmida        INT             NOT NULL,
    FOREIGN KEY (vathmida) REFERENCES  vathmida_iatrou(vathmida_id),
    amka_epoptis    CHAR(11)        NULL,
    PRIMARY KEY (amka),
    FOREIGN KEY (amka) REFERENCES proswpiko(amka)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (amka_epoptis) REFERENCES iatros(amka)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE nosileutis (
    amka            CHAR(11)        NOT NULL,
    vathmida_nosileuti VARCHAR(20)  NOT NULL
        CHECK (vathmida_nosileuti IN ('Βοηθός Νοσηλευτή', 'Νοσηλευτής', 'Προϊστάμενος')),
    PRIMARY KEY (amka),
    FOREIGN KEY (amka) REFERENCES proswpiko(amka)
        ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE dioikitiko (   
    amka            CHAR(11)        NOT NULL,
    rolos           VARCHAR(80)     NOT NULL,
    grafeio         VARCHAR(50)     NULL,
    PRIMARY KEY (amka),
    FOREIGN KEY (amka) REFERENCES proswpiko(amka)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
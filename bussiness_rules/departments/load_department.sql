CREATE TABLE tmima (
    onoma           VARCHAR(100)    NOT NULL UNIQUE,
    perigrafi       TEXT            NULL,
    arithmos_klinon SMALLINT        NOT NULL CHECK (arithmos_klinon >= 0),
    orofos_ktiriou   VARCHAR(50)     NOT NULL,
    amka_dieftinti  CHAR(11)        NULL, 
    tmima_id        INT             AUTO_INCREMENT,
    PRIMARY KEY (tmima_id),
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
 

ALTER TABLE tmima
    ADD CONSTRAINT fk_tmima_dieftintis
    FOREIGN KEY (amka_dieftinti) REFERENCES iatros(amka)
    ON DELETE SET NULL ON UPDATE CASCADE;
 

CREATE TABLE proswpiko_anikei_se_tmima (
    amka_proswpikou CHAR(11) NOT NULL,
    tmima_id        INT      NOT NULL,

    PRIMARY KEY (amka_proswpikou, tmima_id),

    FOREIGN KEY (amka_proswpikou)
        REFERENCES proswpiko(amka)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (tmima_id)
        REFERENCES tmima(tmima_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;;

CREATE TABLE klini (   
    tmima_id        INT             NOT NULL,
    ar_kliis        SMALLINT        NOT NULL CHECK (ar_kliis > 0),
    typos           VARCHAR(30)     NOT NULL,
    katastasi       VARCHAR(30)     NOT NULL
        CHECK (katastasi IN ('Διαθέσιμη','Κατειλημμένη','Υπό συντήρηση')),
    PRIMARY KEY (tmima_id, ar_kliis),
    FOREIGN KEY (tmima_id) REFERENCES tmima(tmima_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
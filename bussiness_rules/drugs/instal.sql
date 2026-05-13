CREATE TABLE farmako (
    kod_ema             INT             NOT NULL AUTO_INCREMENT,
    onoma               VARCHAR(300)    NOT NULL,
    tropos_xorigisis    VARCHAR(200)    NULL,
    PRIMARY KEY (kod_ema),
    UNIQUE (onoma, tropos_xorigisis)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE drastiki_ousia (
    ousia_id        INT             NOT NULL AUTO_INCREMENT,
    onoma           VARCHAR(300)    NOT NULL,
    PRIMARY KEY (ousia_id),
    UNIQUE (onoma)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE farmako_drastiki (
    kod_ema         INT             NOT NULL,
    ousia_id        INT             NOT NULL,
    PRIMARY KEY (kod_ema, ousia_id),
    FOREIGN KEY (kod_ema) REFERENCES farmako(kod_ema)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ousia_id) REFERENCES drastiki_ousia(ousia_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE allergy (
    amka_astheni    CHAR(11)        NOT NULL,
    ousia_id        INT             NOT NULL,
    PRIMARY KEY (amka_astheni, ousia_id),
    FOREIGN KEY (amka_astheni) REFERENCES asthenis(amka)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ousia_id) REFERENCES drastiki_ousia(ousia_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE syntagografisi (
    kod_ema         INT             NOT NULL,
    amka_iatrou     CHAR(11)        NOT NULL,
    amka_astheni    CHAR(11)        NOT NULL,
    imer_enarksis   DATE            NOT NULL,
    dosologia       VARCHAR(200)    NOT NULL,
    syxnotita       VARCHAR(100)    NOT NULL,
    imer_liksis     DATE            NULL,
    PRIMARY KEY (kod_ema, amka_iatrou, amka_astheni, imer_enarksis),
    FOREIGN KEY (kod_ema) REFERENCES farmako(kod_ema)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (amka_iatrou) REFERENCES iatros(amka)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (amka_astheni) REFERENCES asthenis(amka)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (imer_liksis IS NULL OR imer_liksis >= imer_enarksis)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

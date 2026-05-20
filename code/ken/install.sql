CREATE TABLE ken (
    kod_ken         VARCHAR(20)     NOT NULL,
    vasiko_kostos   DECIMAL(10,2)   NOT NULL CHECK (vasiko_kostos >= 0),
    mdn             SMALLINT        NOT NULL CHECK (mdn > 0),
    imer_xrewsi     DECIMAL(8,2)    NOT NULL CHECK (imer_xrewsi >= 0),
    PRIMARY KEY (kod_ken)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
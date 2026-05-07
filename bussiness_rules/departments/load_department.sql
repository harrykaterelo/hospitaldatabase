CREATE TABLE tmima (
    onoma           VARCHAR(100)    NOT NULL,
    perigrafi       TEXT            NULL,
    arithmos_klinon SMALLINT        NOT NULL CHECK (arithmos_klinon >= 0),
    rofos_ktiriou   VARCHAR(50)     NOT NULL,
    amka_dieftinti  CHAR(11)        NULL,  -- FK προς iatros (circular → add after)
    PRIMARY KEY (onoma)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
 
-- ============================================================
-- 6. ΙΑΤΡΟΣ  (ISA from proswpiko)
-- ============================================================

 
-- Τώρα προσθέτουμε FK tmima → iatros (circular χρειάζεται ALTER)
ALTER TABLE tmima
    ADD CONSTRAINT fk_tmima_dieftintis
    FOREIGN KEY (amka_dieftinti) REFERENCES iatros(amka)
    ON DELETE SET NULL ON UPDATE CASCADE;
 
-- ============================================================
-- 7. ΙΑΤΡΟΣ–ΤΜΗΜΑ  (M:N, ιατρός μπορεί σε πολλά τμήματα)
-- ============================================================
CREATE TABLE iatros_tmima (
    amka_iatrou     CHAR(11)        NOT NULL,
    onoma_tmimatos  VARCHAR(100)    NOT NULL,
    PRIMARY KEY (amka_iatrou, onoma_tmimatos),
    FOREIGN KEY (amka_iatrou) REFERENCES iatros(amka)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (onoma_tmimatos) REFERENCES tmima(onoma)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE klini (
    onoma_tmimatos  VARCHAR(100)    NOT NULL,
    ar_kliis        SMALLINT        NOT NULL CHECK (ar_kliis > 0),
    typos           VARCHAR(30)     NOT NULL,
    katastasi       VARCHAR(30)     NOT NULL
        CHECK (katastasi IN ('Διαθέσιμη','Κατειλημμένη','Υπό συντήρηση')),
    PRIMARY KEY (onoma_tmimatos, ar_kliis),
    FOREIGN KEY (onoma_tmimatos) REFERENCES tmima(onoma)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
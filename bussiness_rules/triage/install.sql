-- ============================================================
-- ΔΙΑΛΟΓΗ ΣΤΟΙΧΕΙΩΝ (Triage)
-- Καταγράφει κάθε επίσκεψη ασθενή στο ΤΕΠ.
-- Ο ασθενής τοποθετείται στην ουρά ανά epipedo (1=άμεσο … 5=μη
-- επείγον) και, για ίδιο epipedo, με αυστηρή FIFO σειρά
-- βάσει wra_afiksis.
-- Αποτέλεσμα: 'Αποχώρηση' (οδηγίες & έξοδος) ή
--             'Παραπομπή'  (παραπομπή για νοσηλεία)
-- ============================================================
CREATE TABLE efimeria_se_kathikon_triage (
    tmima INT NOT NULL DEFAULT 20,
    imerominia DATE NOT NULL,
    vardia INT NOT NULL,
    amka_proswpiko CHAR(11) NOT NULL,

    PRIMARY KEY (tmima, imerominia, vardia, amka_proswpiko),

    

    FOREIGN KEY (tmima, imerominia, vardia, amka_proswpiko)
        REFERENCES efimeria_proswpiko (
            tmima,
            imerominia,
            vardia,
            amka_proswpiko
        )
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE dialogistoixeiwn (
    id_dialogis     INT             NOT NULL AUTO_INCREMENT,
    amka_astheni    CHAR(11)        NOT NULL,
    amka_nosilevti  CHAR(11)        NOT NULL,
    wra_afiksis     DATETIME        NOT NULL DEFAULT (NOW()),
    symptomata      TEXT            NOT NULL,
    epipedo         TINYINT         NOT NULL
        CHECK (epipedo BETWEEN 1 AND 5),

    -- NULL ενώ ο ασθενής αναμένει εξυπηρέτηση
    apotelesma      VARCHAR(20)     NULL
        CHECK (apotelesma IN ('Αποχώρηση', 'Παραπομπή')),
    odigies         TEXT            NULL,    -- συμπληρώνεται αν αποχωρεί
    wra_oloklirosis DATETIME        NULL,    -- στιγμή ολοκλήρωσης

    -- συμπληρώνεται αν παραπέμπεται για νοσηλεία
    nosileia_id     INT             NULL,

    PRIMARY KEY (id_dialogis),

    FOREIGN KEY (amka_astheni)
        REFERENCES asthenis(amka)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    FOREIGN KEY (amka_nosilevti)
        REFERENCES nosileutis(amka)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    FOREIGN KEY (nosileia_id)
        REFERENCES nosileia(nosileia_id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    -- αν αποτέλεσμα = 'Αποχώρηση', να μην υπάρχει παραπομπή και αντίστροφα
    CONSTRAINT chk_apotelesma_nosileuth
        CHECK (
            (apotelesma = 'Παραπομπή'  AND nosileia_id IS NOT NULL) OR
            (apotelesma = 'Αποχώρηση' AND nosileia_id IS NULL) OR
            apotelesma IS NULL
        )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

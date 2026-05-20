-- ============================================================
-- HOSPITAL DATABASE - FULL INSTALL
-- Δημιουργεί όλους τους πίνακες σε σωστή σειρά εξαρτήσεων (FK).
-- Δεν χρειάζεται SET FOREIGN_KEY_CHECKS = 0.
-- ============================================================

SET NAMES utf8mb4;

-- ============================================================
-- 1. STAFF / ΠΡΟΣΩΠΙΚΟ
-- ============================================================

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
    amka_epoptis    CHAR(11)        NULL,
    PRIMARY KEY (amka),
    FOREIGN KEY (vathmida) REFERENCES vathmida_iatrou(vathmida_id),
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE dioikitiko (
    amka            CHAR(11)        NOT NULL,
    rolos           VARCHAR(80)     NOT NULL,
    grafeio         VARCHAR(50)     NULL,
    PRIMARY KEY (amka),
    FOREIGN KEY (amka) REFERENCES proswpiko(amka)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 2. ASTHENIS / ΑΣΘΕΝΕΙΣ
-- ============================================================

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

-- ============================================================
-- 3. LOOKUP TABLES (ICD / KEN / XWROS EPEMBASIS)
-- ============================================================

CREATE TABLE icd (
    kodikos VARCHAR(10) NOT NULL,
    perigrafi TEXT NOT NULL,
    PRIMARY KEY (kodikos)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ken (
    kod_ken         VARCHAR(20)     NOT NULL,
    vasiko_kostos   DECIMAL(10,2)   NOT NULL CHECK (vasiko_kostos >= 0),
    mdn             SMALLINT        NOT NULL CHECK (mdn > 0),
    imer_xrewsi     DECIMAL(8,2)    NOT NULL CHECK (imer_xrewsi >= 0),
    PRIMARY KEY (kod_ken)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE xwros_epembasis (
    kodikos         VARCHAR(20)     NOT NULL,
    typos           VARCHAR(30)     NOT NULL
        CHECK (typos IN ('Χειρουργείο','Αίθουσα επέμβασης')),
    PRIMARY KEY (kodikos)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 4. DEPARTMENTS / ΤΜΗΜΑΤΑ - ΚΛΙΝΕΣ
-- ============================================================

CREATE TABLE tmima (
    onoma           VARCHAR(100)    NOT NULL UNIQUE,
    perigrafi       TEXT            NULL,
    arithmos_klinon SMALLINT        NOT NULL CHECK (arithmos_klinon >= 0),
    orofos_ktiriou  VARCHAR(50)     NOT NULL,
    amka_dieftinti  CHAR(11)        NULL,
    tmima_id        INT             NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (tmima_id),
    FOREIGN KEY (amka_dieftinti) REFERENCES iatros(amka)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE klini (
    tmima_id        INT             NOT NULL,
    ar_kliis        SMALLINT        NOT NULL CHECK (ar_kliis > 0),
    typos           VARCHAR(30)     NOT NULL,
    katastasi       VARCHAR(30)     NOT NULL
        CHECK (katastasi IN ('Διαθέσιμη','Κατειλημμένη','Υπό Συντήρηση')),
    PRIMARY KEY (tmima_id, ar_kliis),
    FOREIGN KEY (tmima_id) REFERENCES tmima(tmima_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 5. NOSILEIA / ΝΟΣΗΛΕΙΑ
-- ============================================================

CREATE TABLE nosileia (
    nosileia_id        INT             NOT NULL AUTO_INCREMENT,
    amka_astheni       CHAR(11)        NOT NULL,
    tmima_id           INT             NOT NULL,
    ar_kliis           SMALLINT        NULL,
    kod_ken            VARCHAR(20)     NOT NULL,
    imerominia_eisodou DATE            NOT NULL,
    imerominia_eksodou DATE            NULL,
    synoliko_kostos    DECIMAL(10,2)   NULL CHECK (synoliko_kostos >= 0),
    CONSTRAINT chk_imerominia_eksodou
        CHECK (imerominia_eksodou IS NULL OR imerominia_eksodou >= imerominia_eisodou),
    PRIMARY KEY (nosileia_id),
    FOREIGN KEY (amka_astheni) REFERENCES asthenis(amka)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (tmima_id, ar_kliis) REFERENCES klini(tmima_id, ar_kliis)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (kod_ken) REFERENCES ken(kod_ken)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE diagnosi (
    nosileia_id     INT             NOT NULL,
    icd             VARCHAR(10)     NULL,
    tipos_diagnosis VARCHAR(20)     NOT NULL
        CHECK (tipos_diagnosis IN ('Εισοδος', 'Εξοδος')),
    PRIMARY KEY (nosileia_id, tipos_diagnosis),
    FOREIGN KEY (icd) REFERENCES icd(kodikos)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE axiologisi (
    nosileia_id                 INT             NOT NULL,
    poiotita_iatr_frontidas     TINYINT         NOT NULL CHECK (poiotita_iatr_frontidas BETWEEN 1 AND 5),
    poiotita_nosileft_frontidas TINYINT         NOT NULL CHECK (poiotita_nosileft_frontidas BETWEEN 1 AND 5),
    kathariotita                TINYINT         NOT NULL CHECK (kathariotita BETWEEN 1 AND 5),
    fagito                      TINYINT         NOT NULL CHECK (fagito BETWEEN 1 AND 5),
    synoliki_empeiria           TINYINT         NOT NULL CHECK (synoliki_empeiria BETWEEN 1 AND 5),
    PRIMARY KEY (nosileia_id),
    FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE exetasi (
    nosileia_id         INT             NOT NULL,
    kodikos             VARCHAR(20)     NOT NULL,
    typos               VARCHAR(80)     NOT NULL,
    imerominia          DATE            NOT NULL,
    apotelesma_keim     TEXT            NULL,
    apotelesma_ar_timi  DECIMAL(12,4)   NULL,
    apotelesma_monada   VARCHAR(30)     NULL,
    kostos              DECIMAL(10,2)   NOT NULL CHECK (kostos >= 0),
    amka_iatrou         CHAR(11)        NOT NULL,
    PRIMARY KEY (nosileia_id, kodikos),
    FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (amka_iatrou) REFERENCES iatros(amka)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE iatrikipraxi (
    kodikos                 VARCHAR(20)     NOT NULL,
    nosileia_id             INT             NOT NULL,
    amka_kyriou_xeirourgou  CHAR(11)        NOT NULL,
    kod_xwrou               VARCHAR(20)     NOT NULL,
    onoma                   VARCHAR(200)    NOT NULL,
    katigoria               VARCHAR(30)     NOT NULL
        CHECK (katigoria IN ('Χειρουργική','Διαγνωστική','Θεραπευτική')),
    diarkeia_lepta          SMALLINT        NOT NULL CHECK (diarkeia_lepta > 0),
    kostos                  DECIMAL(10,2)   NOT NULL CHECK (kostos >= 0),
    imerominia_wra          DATETIME        NOT NULL,
    PRIMARY KEY (kodikos),
    FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (amka_kyriou_xeirourgou) REFERENCES iatros(amka)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (kod_xwrou) REFERENCES xwros_epembasis(kodikos)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE praxi_voithos (
    kod_praxis      VARCHAR(20)     NOT NULL,
    amka_voithou    CHAR(11)        NOT NULL,
    PRIMARY KEY (kod_praxis, amka_voithou),
    FOREIGN KEY (kod_praxis) REFERENCES iatrikipraxi(kodikos)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (amka_voithou) REFERENCES proswpiko(amka)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 6. TRIAGE / ΔΙΑΛΟΓΗ ΤΕΠ
-- ============================================================

CREATE TABLE dialogistoixeiwn (
    id_dialogis     INT             NOT NULL AUTO_INCREMENT,
    amka_astheni    CHAR(11)        NOT NULL,
    amka_nosilevti  CHAR(11)        NOT NULL,
    wra_afiksis     DATETIME        NOT NULL DEFAULT (NOW()),
    symptomata      TEXT            NOT NULL,
    epipedo         TINYINT         NOT NULL
        CHECK (epipedo BETWEEN 1 AND 5),
    apotelesma      VARCHAR(20)     NULL
        CHECK (apotelesma IN ('Αποχώρηση', 'Παραπομπή')),
    odigies         TEXT            NULL,
    wra_oloklirosis DATETIME        NULL,
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
    CONSTRAINT chk_apotelesma_nosileuth
        CHECK (
            (apotelesma = 'Παραπομπή'  AND nosileia_id IS NOT NULL) OR
            (apotelesma = 'Αποχώρηση' AND nosileia_id IS NULL) OR
            apotelesma IS NULL
        )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 7. SHIFTS / ΕΦΗΜΕΡΙΕΣ
-- ============================================================

CREATE TABLE vardia (
    vardia_id INT AUTO_INCREMENT PRIMARY KEY,
    vardia_onoma VARCHAR(15) NOT NULL
        CHECK (vardia_onoma IN ('Πρωινή','Απογευματινή','Νυχτερινή')),
    vardia_ora_ekkinisis TIME NOT NULL,
    vardia_ora_lixis TIME NOT NULL,
    endiamesi_ora_anapausis_hours INT NOT NULL CHECK (endiamesi_ora_anapausis_hours >= 0),
    epitreptes_sinexomenes_vardies INT  NULL CHECK (epitreptes_sinexomenes_vardies >= 0)
);

CREATE TABLE efimeria (
    statusEf VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    tmima  INT    NOT NULL,
    imerominia      DATE            NOT NULL,
    vardia          INT NOT NULL,
    PRIMARY KEY (tmima, imerominia, vardia),
    FOREIGN KEY (vardia) REFERENCES vardia(vardia_id),
    FOREIGN KEY (tmima) REFERENCES tmima(tmima_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE efimeria_proswpiko (
    tmima           INT             NOT NULL,
    imerominia      DATE            NOT NULL,
    vardia          INT             NOT NULL,
    amka_proswpiko  CHAR(11)        NOT NULL,
    PRIMARY KEY (tmima, imerominia, vardia, amka_proswpiko),
    FOREIGN KEY (tmima, imerominia, vardia)
        REFERENCES efimeria(tmima, imerominia, vardia)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (amka_proswpiko) REFERENCES proswpiko(amka)
       ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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

CREATE TABLE efimeria_requirements (
    iatros_max_monthly_ef_count INT NOT NULL DEFAULT 15,
    nosileutes_max_monthly_ef_count INT NOT NULL DEFAULT 20,
    dioikitiko_max_monthly_ef_count INT NOT NULL DEFAULT 25,
    iatros_min_count INT NOT NULL DEFAULT 3 CHECK (iatros_min_count >= 0),
    nosileutes_min_count INT NOT NULL DEFAULT 6 CHECK (nosileutes_min_count >= 0),
    dioikitiko_min_count INT NOT NULL DEFAULT 2 CHECK (dioikitiko_min_count >= 0),
    PRIMARY KEY (iatros_min_count, nosileutes_min_count, dioikitiko_min_count)
);

-- ============================================================
-- 8. DRUGS / ΦΑΡΜΑΚΑ - ΣΥΝΤΑΓΟΓΡΑΦΗΣΗ
-- ============================================================

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
    nosileia_id     INT             NOT NULL,
    kod_ema         INT             NOT NULL,
    amka_iatrou     CHAR(11)        NOT NULL,
    amka_astheni    CHAR(11)        NOT NULL,
    imer_enarksis   DATE            NOT NULL,
    dosologia       VARCHAR(200)    NOT NULL,
    syxnotita       VARCHAR(100)    NOT NULL,
    imer_liksis     DATE            NULL,
    PRIMARY KEY (kod_ema, amka_iatrou, amka_astheni, imer_enarksis),
    CHECK (imer_liksis IS NULL OR imer_liksis >= imer_enarksis),
    FOREIGN KEY (kod_ema) REFERENCES farmako(kod_ema)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (amka_iatrou) REFERENCES iatros(amka)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (amka_astheni) REFERENCES asthenis(amka)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- HOSPITAL DATABASE - FULL INSTALL
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
    requires_senior_in_shift BOOL NOT NULL DEFAULT 0,
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
    typos               VARCHAR(80)     NOT NULL
        CHECK (typos IN ('αιματολογικές','βιοχημικές','απεικονιστικές')),
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

CREATE TABLE iatrikespraxeis (
    kodikos VARCHAR(32) NOT NULL,
    onoma TEXT NOT NULL,
    PRIMARY KEY (kodikos)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

CREATE TABLE iatrikipraxi (
    kodikos                 VARCHAR(20)     NOT NULL,
    nosileia_id             INT             NOT NULL,
    amka_kyriou_xeirourgou  CHAR(11)        NOT NULL,
    kod_xwrou               VARCHAR(20)     NOT NULL,
    iatriki_praxi_kodikos   VARCHAR(32)     COLLATE utf8mb4_unicode_ci NOT NULL,
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
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (iatriki_praxi_kodikos) REFERENCES iatrikespraxeis(kodikos)
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

    PRIMARY KEY (id_dialogis),

    FOREIGN KEY (amka_astheni)
        REFERENCES asthenis(amka)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    FOREIGN KEY (amka_nosilevti)
        REFERENCES nosileutis(amka)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_wres_diagologis
        CHECK (wra_oloklirosis IS NULL OR wra_afiksis < wra_oloklirosis)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE parapobi_gia_nosileia (
    id_dialogis     INT     NOT NULL,
    nosileia_id     INT     NOT NULL,
    PRIMARY KEY (id_dialogis, nosileia_id),
    FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_dialogis) REFERENCES dialogistoixeiwn(id_dialogis)
        ON DELETE CASCADE ON UPDATE CASCADE
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

    PRIMARY KEY (imerominia, vardia),

    

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

-- ============================================================
-- 9. ERROR LOG / AUDIT
-- ============================================================

CREATE TABLE error_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    error_message TEXT NOT NULL,
    error_time DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- VIEWS
-- ============================================================

CREATE VIEW diathesimes_klines AS
SELECT tmima_id, ar_kliis
FROM klini
WHERE katastasi = 'Διαθέσιμη';

CREATE OR REPLACE VIEW oura_anamenomenwn AS
SELECT
    d.id_dialogis,
    d.epipedo,
    CASE d.epipedo
        WHEN 1 THEN 'Άμεσο'
        WHEN 2 THEN 'Επείγον'
        WHEN 3 THEN 'Επιτακτικό'
        WHEN 4 THEN 'Λιγότερο επείγον'
        WHEN 5 THEN 'Μη επείγον'
    END                                         AS perigrafi_epipedou,
    d.wra_afiksis,
    TIMESTAMPDIFF(MINUTE, d.wra_afiksis, NOW()) AS lepta_anamon_is,
    d.amka_astheni,
    d.symptomata
FROM dialogistoixeiwn d
WHERE d.apotelesma IS NULL
ORDER BY d.epipedo ASC, d.wra_afiksis ASC;

-- ============================================================
-- STORED PROCEDURES / FUNCTIONS
-- ============================================================

DELIMITER //

DROP PROCEDURE IF EXISTS add_error //

CREATE PROCEDURE add_error(
    IN p_error_message TEXT
)
BEGIN
    INSERT INTO error_log (
        error_message,
        error_time
    )
    VALUES (
        p_error_message,
        NOW()
    );
END //

DROP FUNCTION IF EXISTS efimeria_check //

CREATE FUNCTION efimeria_check(
    p_tmima INT,
    p_imerominia DATE,
    p_vardia INT
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_doctors INT DEFAULT 0;
    DECLARE v_nurses INT DEFAULT 0;
    DECLARE v_admins INT DEFAULT 0;

    DECLARE doctor_min_count INT DEFAULT 3;
    DECLARE nurse_min_count INT DEFAULT 6;
    DECLARE admin_min_count INT DEFAULT 2;

    DECLARE docs_that_require_senior_in_shift INT DEFAULT 0;
    DECLARE docs_that_can_cover_shift INT DEFAULT 0;

    SELECT
        iatros_min_count,
        nosileutes_min_count,
        dioikitiko_min_count
    INTO
        doctor_min_count,
        nurse_min_count,
        admin_min_count
    FROM efimeria_requirements
    LIMIT 1;

    SELECT
        COALESCE(SUM(CASE WHEN p.typos_proswpikou = 'Ιατρός' THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN p.typos_proswpikou = 'Νοσηλευτής' THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN p.typos_proswpikou = 'Διοικητικό' THEN 1 ELSE 0 END), 0)
    INTO
        v_doctors,
        v_nurses,
        v_admins
    FROM efimeria_proswpiko ep
    JOIN proswpiko p
        ON ep.amka_proswpiko = p.amka
    WHERE ep.tmima = p_tmima
      AND ep.imerominia = p_imerominia
      AND ep.vardia = p_vardia;

    IF v_doctors < doctor_min_count
       OR v_nurses < nurse_min_count
       OR v_admins < admin_min_count THEN
        RETURN 0;
    END IF;

    SELECT
        COALESCE(SUM(CASE WHEN v.requires_senior_in_shift = 1 THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN v.can_cover_specialist_shift = 1 THEN 1 ELSE 0 END), 0)
    INTO
        docs_that_require_senior_in_shift,
        docs_that_can_cover_shift
    FROM efimeria_proswpiko ep
    JOIN iatros i
        ON ep.amka_proswpiko = i.amka
    JOIN vathmida_iatrou v
        ON i.vathmida = v.vathmida_id
    WHERE ep.tmima = p_tmima
      AND ep.imerominia = p_imerominia
      AND ep.vardia = p_vardia;

    IF docs_that_require_senior_in_shift > 0
       AND docs_that_can_cover_shift = 0 THEN
        RETURN 0;
    END IF;

    RETURN 1;
END //

-- ------------------------------------------------------------
-- TRIAGE PROCEDURES
-- ------------------------------------------------------------

DROP PROCEDURE IF EXISTS register_dialogi //

CREATE PROCEDURE register_dialogi(
    IN p_amka_astheni    CHAR(11),
    IN p_wra_afiksis     DATETIME,
    IN p_symptomata      TEXT,
    IN p_epipedo         TINYINT,
    IN p_apotelesma      VARCHAR(20),
    IN p_odigies         TEXT,
    IN p_wra_oloklirosis DATETIME
)
BEGIN
    DECLARE v_amka_nosilevti CHAR(11);

    SELECT e.amka_proswpiko
        INTO v_amka_nosilevti
        FROM efimeria_se_kathikon_triage e
        JOIN vardia v
        ON v.vardia_id = e.vardia
        WHERE p_wra_afiksis >= TIMESTAMP(DATE(e.imerominia), v.vardia_ora_ekkinisis)
        AND p_wra_afiksis < CASE
            WHEN v.vardia_ora_lixis > v.vardia_ora_ekkinisis THEN
                TIMESTAMP(DATE(e.imerominia), v.vardia_ora_lixis)
            ELSE
                TIMESTAMP(DATE(e.imerominia) + INTERVAL 1 DAY, v.vardia_ora_lixis)
        END
        ORDER BY RAND()
        LIMIT 1;

    IF v_amka_nosilevti IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No nosileutis found for register_dialogi';
    END IF;

    INSERT INTO dialogistoixeiwn (
        amka_astheni,
        amka_nosilevti,
        wra_afiksis,
        symptomata,
        epipedo,
        apotelesma,
        odigies,
        wra_oloklirosis
    )
    VALUES (
        p_amka_astheni,
        v_amka_nosilevti,
        p_wra_afiksis,
        p_symptomata,
        p_epipedo,
        p_apotelesma,
        p_odigies,
        p_wra_oloklirosis
    );
END //

DROP PROCEDURE IF EXISTS complete_triage //

CREATE PROCEDURE complete_triage(
    IN p_id_dialogis     INT,
    IN p_apotelesma      VARCHAR(20),
    IN p_odigies         TEXT,
    IN p_wra_oloklirosis DATETIME,
    IN p_tmima_id            INT,
    IN p_kod_ken             VARCHAR(20),
    IN p_imerominia_eisodou  DATE,
    IN p_icd_eisodou         VARCHAR(10)
)
BEGIN
    DECLARE v_current_apotelesma VARCHAR(20);
    DECLARE v_amka_astheni       CHAR(11);
    DECLARE v_ar_kliis           SMALLINT;
    DECLARE v_nosileia_id        INT;
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = TRUE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT apotelesma, amka_astheni
    INTO v_current_apotelesma, v_amka_astheni
    FROM dialogistoixeiwn
    WHERE id_dialogis = p_id_dialogis
    FOR UPDATE;

    IF v_not_found THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Δεν βρέθηκε εγγραφή διαλογής με αυτό το id.';
    END IF;

    IF v_current_apotelesma IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η διαλογή έχει ήδη ολοκληρωθεί.';
    END IF;

    UPDATE dialogistoixeiwn
    SET
        apotelesma      = p_apotelesma,
        odigies         = p_odigies,
        wra_oloklirosis = p_wra_oloklirosis
    WHERE id_dialogis = p_id_dialogis;

    IF p_apotelesma = 'Παραπομπή' THEN

        IF p_tmima_id IS NULL
           OR p_kod_ken IS NULL
           OR p_imerominia_eisodou IS NULL
           OR p_icd_eisodou IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Για παραπομπή απαιτούνται tmima_id, kod_ken, imerominia_eisodou, icd_eisodou.';
        END IF;

        SET v_not_found = FALSE;

        SELECT dk.ar_kliis
        INTO v_ar_kliis
        FROM diathesimes_klines dk
        WHERE dk.tmima_id = p_tmima_id
        ORDER BY RAND()
        LIMIT 1;

        IF v_ar_kliis IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Δεν υπάρχει διαθέσιμη κλίνη στο τμήμα.';
        END IF;

        INSERT INTO nosileia (
            amka_astheni,
            tmima_id,
            ar_kliis,
            kod_ken,
            imerominia_eisodou,
            imerominia_eksodou
        )
        VALUES (
            v_amka_astheni,
            p_tmima_id,
            v_ar_kliis,
            p_kod_ken,
            p_imerominia_eisodou,
            NULL
        );

        SET v_nosileia_id = LAST_INSERT_ID();

        INSERT INTO diagnosi (nosileia_id, icd, tipos_diagnosis)
        VALUES (v_nosileia_id, p_icd_eisodou, 'Εισοδος');

        INSERT INTO parapobi_gia_nosileia (id_dialogis, nosileia_id)
        VALUES (p_id_dialogis, v_nosileia_id);

    END IF;

    COMMIT;
END //

-- ------------------------------------------------------------
-- STAFF PROCEDURES
-- ------------------------------------------------------------

DROP PROCEDURE IF EXISTS add_doctor //

CREATE PROCEDURE add_doctor(
    IN p_amka CHAR(11),
    IN p_onoma VARCHAR(50),
    IN p_eponymo VARCHAR(50),
    IN p_ilikia SMALLINT,
    IN p_email VARCHAR(100),
    IN p_tilefono VARCHAR(15),
    IN p_imerominia_proslipsis DATE,
    IN p_typos_proswpikou VARCHAR(20),
    IN p_ar_ad_is VARCHAR(20),
    IN p_eidikotita VARCHAR(80),
    IN p_vathmida_id INT,
    IN p_amka_epoptis CHAR(11)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO anthropos (amka, onoma, eponymo, ilikia, email, tilefono)
    VALUES (p_amka, p_onoma, p_eponymo, p_ilikia, p_email, p_tilefono);

    INSERT INTO proswpiko (amka, imerominia_proslipsis, typos_proswpikou)
    VALUES (p_amka, p_imerominia_proslipsis, p_typos_proswpikou);

    INSERT INTO iatros (amka, ar_ad_is, eidikotita, vathmida, amka_epoptis)
    VALUES (p_amka, p_ar_ad_is, p_eidikotita, p_vathmida_id, p_amka_epoptis);

    COMMIT;
END //

DROP PROCEDURE IF EXISTS add_nosileutis //

CREATE PROCEDURE add_nosileutis(
    IN p_amka                   CHAR(11),
    IN p_onoma                  VARCHAR(50),
    IN p_eponymo                VARCHAR(50),
    IN p_ilikia                 SMALLINT,
    IN p_email                  VARCHAR(100),
    IN p_tilefono               VARCHAR(15),
    IN p_imerominia_proslipsis  DATE,
    IN p_vathmida_nosileuti     VARCHAR(20),
    IN p_tmima_id               INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO anthropos (amka, onoma, eponymo, ilikia, email, tilefono)
    VALUES (p_amka, p_onoma, p_eponymo, p_ilikia, p_email, p_tilefono);

    INSERT INTO proswpiko (amka, imerominia_proslipsis, typos_proswpikou)
    VALUES (p_amka, p_imerominia_proslipsis, 'Νοσηλευτής');

    INSERT INTO nosileutis (amka, vathmida_nosileuti)
    VALUES (p_amka, p_vathmida_nosileuti);

    INSERT INTO proswpiko_anikei_se_tmima (amka_proswpikou, tmima_id)
    VALUES (p_amka, p_tmima_id);

    COMMIT;
END //

DROP PROCEDURE IF EXISTS add_dioikitiko //

CREATE PROCEDURE add_dioikitiko(
    IN p_amka                   CHAR(11),
    IN p_onoma                  VARCHAR(50),
    IN p_eponymo                VARCHAR(50),
    IN p_ilikia                 SMALLINT,
    IN p_email                  VARCHAR(100),
    IN p_tilefono               VARCHAR(15),
    IN p_imerominia_proslipsis  DATE,
    IN p_rolos                  VARCHAR(80),
    IN p_grafeio                VARCHAR(50),
    IN p_tmima_id               INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO anthropos (amka, onoma, eponymo, ilikia, email, tilefono)
    VALUES (p_amka, p_onoma, p_eponymo, p_ilikia, p_email, p_tilefono);

    INSERT INTO proswpiko (amka, imerominia_proslipsis, typos_proswpikou)
    VALUES (p_amka, p_imerominia_proslipsis, 'Διοικητικό');

    INSERT INTO dioikitiko (amka, rolos, grafeio)
    VALUES (p_amka, p_rolos, p_grafeio);

    INSERT INTO proswpiko_anikei_se_tmima (amka_proswpikou, tmima_id)
    VALUES (p_amka, p_tmima_id);

    COMMIT;
END //

-- ------------------------------------------------------------
-- ASTHENIS PROCEDURE
-- ------------------------------------------------------------

DROP PROCEDURE IF EXISTS add_asthenis //

CREATE PROCEDURE add_asthenis(
    IN p_amka                CHAR(11),
    IN p_onoma               VARCHAR(50),
    IN p_eponymo             VARCHAR(50),
    IN p_ilikia              SMALLINT,
    IN p_email               VARCHAR(100),
    IN p_tilefono            VARCHAR(15),
    IN p_patronymo           VARCHAR(50),
    IN p_fylo                VARCHAR(10),
    IN p_varos               DECIMAL(5,2),
    IN p_ypsos               DECIMAL(5,2),
    IN p_diefthinsi          VARCHAR(200),
    IN p_epangelma           VARCHAR(100),
    IN p_ypikoiotita         VARCHAR(50),
    IN p_asfalistikos_foreas VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT IGNORE INTO anthropos (amka, onoma, eponymo, ilikia, email, tilefono)
    VALUES (p_amka, p_onoma, p_eponymo, p_ilikia, p_email, p_tilefono);

    INSERT INTO asthenis (amka, patronymo, fylo, varos, ypsos, diefthinsi, epangelma, ypikoiotita, asfalistikos_foreas)
    VALUES (p_amka, p_patronymo, p_fylo, p_varos, p_ypsos, p_diefthinsi, p_epangelma, p_ypikoiotita, p_asfalistikos_foreas);

    COMMIT;
END //

-- ------------------------------------------------------------
-- DEPARTMENT / KLINI PROCEDURES
-- ------------------------------------------------------------

DROP PROCEDURE IF EXISTS add_klini //

CREATE PROCEDURE add_klini(
    IN p_tmima_id   INT,
    IN p_ar_kliis   SMALLINT,
    IN p_typos      VARCHAR(30),
    IN p_katastasi  VARCHAR(30)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    INSERT IGNORE INTO klini (tmima_id, ar_kliis, typos, katastasi)
    VALUES (p_tmima_id, p_ar_kliis, p_typos, p_katastasi);
    COMMIT;
END //

-- ------------------------------------------------------------
-- NOSILEIA PROCEDURES
-- ------------------------------------------------------------

DROP PROCEDURE IF EXISTS add_diagnosi //

CREATE PROCEDURE add_diagnosi(
    IN p_nosileia_id     INT,
    IN p_icd             VARCHAR(10),
    IN p_tipos_diagnosis VARCHAR(20)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    INSERT INTO diagnosi (nosileia_id, icd, tipos_diagnosis)
    VALUES (p_nosileia_id, p_icd, p_tipos_diagnosis);
    COMMIT;
END //

DROP PROCEDURE IF EXISTS add_nosileia //

CREATE PROCEDURE add_nosileia(
    IN p_amka_astheni        CHAR(11),
    IN p_tmima_id            INT,
    IN p_ar_kliis            SMALLINT,
    IN p_kod_ken             VARCHAR(20),
    IN p_imerominia_eisodou  DATE,
    IN p_icd_eisodou         VARCHAR(10),
    IN p_imerominia_eksodou  DATE,
    IN p_icd_eksodou         VARCHAR(10)
)
BEGIN
    DECLARE v_nosileia_id INT;
    DECLARE v_ar_kliis SMALLINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_imerominia_eksodou IS NOT NULL THEN

        IF p_ar_kliis IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ar_kliis is required when imerominia_eksodou is not NULL';
        END IF;

        SET v_ar_kliis = p_ar_kliis;

    ELSE

        SELECT dk.ar_kliis
        INTO v_ar_kliis
        FROM diathesimes_klines dk
        WHERE dk.tmima_id = p_tmima_id
        ORDER BY RAND()
        LIMIT 1;

        IF v_ar_kliis IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No available bed found for this tmima';
        END IF;

    END IF;

    INSERT INTO nosileia (
        amka_astheni,
        tmima_id,
        ar_kliis,
        kod_ken,
        imerominia_eisodou,
        imerominia_eksodou
    )
    VALUES (
        p_amka_astheni,
        p_tmima_id,
        v_ar_kliis,
        p_kod_ken,
        p_imerominia_eisodou,
        p_imerominia_eksodou
    );

    SET v_nosileia_id = LAST_INSERT_ID();

    INSERT INTO diagnosi (nosileia_id, icd, tipos_diagnosis)
    VALUES (v_nosileia_id, p_icd_eisodou, 'Εισοδος');

    IF p_imerominia_eksodou IS NOT NULL THEN
        INSERT INTO diagnosi (nosileia_id, icd, tipos_diagnosis)
        VALUES (v_nosileia_id, p_icd_eksodou, 'Εξοδος');
    END IF;

    COMMIT;

    SELECT v_nosileia_id AS nosileia_id, v_ar_kliis AS ar_kliis;
END //

-- ------------------------------------------------------------
-- SHIFTS PROCEDURE
-- ------------------------------------------------------------

DROP PROCEDURE IF EXISTS add_shift //

CREATE PROCEDURE add_shift(
    IN p_tmima VARCHAR(100),
    IN p_imerominia DATE,
    IN p_vardia VARCHAR(15),
    IN p_amka_proswpiko CHAR(11)
)
BEGIN
    DECLARE v_vardia_id INT DEFAULT NULL;
    DECLARE v_efimeria_exists INT DEFAULT 0;
    DECLARE v_tmima_id INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT vardia_id
    INTO v_vardia_id
    FROM vardia
    WHERE vardia_onoma = p_vardia
    LIMIT 1;

    SELECT tmima_id
    INTO v_tmima_id
    FROM tmima
    WHERE onoma = p_tmima
    LIMIT 1;

    IF v_vardia_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η βάρδια δεν υπάρχει';
    END IF;

    IF v_tmima_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Το τμήμα δεν υπάρχει';
    END IF;

    START TRANSACTION;

    SELECT COUNT(*)
    INTO v_efimeria_exists
    FROM efimeria
    WHERE tmima = v_tmima_id
      AND imerominia = p_imerominia
      AND vardia = v_vardia_id;

    IF v_efimeria_exists = 0 THEN
        INSERT INTO efimeria (tmima, imerominia, vardia)
        VALUES (v_tmima_id, p_imerominia, v_vardia_id);
    END IF;

    INSERT INTO efimeria_proswpiko (
        tmima,
        imerominia,
        vardia,
        amka_proswpiko
    )
    VALUES (
        v_tmima_id,
        p_imerominia,
        v_vardia_id,
        p_amka_proswpiko
    );

    

    COMMIT;
END //

DELIMITER ;

-- ============================================================
-- ============================================================
-- TRIGGERS
-- ============================================================

DELIMITER //

-- ============================================================
-- STAFF TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS doctor_insert_trigger //

CREATE TRIGGER doctor_insert_trigger
BEFORE INSERT ON iatros
FOR EACH ROW
BEGIN
    DECLARE has_to_be_supervised BOOL DEFAULT 0;
    DECLARE grade_exists INT DEFAULT 0;

    DECLARE epoptis_exists INT DEFAULT 0;
    DECLARE vathmida_epopti INT;
    DECLARE epoptis_tou_epopti VARCHAR(20);
    DECLARE epoptis_can_supervise BOOL DEFAULT 0;

    SELECT COUNT(*)
    INTO grade_exists
    FROM vathmida_iatrou
    WHERE vathmida_id = NEW.vathmida;

    IF grade_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η βαθμίδα του γιατρού δεν υπάρχει';
    END IF;

    SELECT is_supervised
    INTO has_to_be_supervised
    FROM vathmida_iatrou
    WHERE vathmida_id = NEW.vathmida
    LIMIT 1;

    IF NEW.amka_epoptis IS NULL THEN

        IF has_to_be_supervised = 1 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ο γιατρός με αυτήν την βαθμίδα πρέπει αναγκαστικά να έχει επόπτη';
        END IF;

    ELSE
        IF has_to_be_supervised = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Αυτός ο γιατρός με αυτήν την βαθμίδα δεν μπορεί να έχει επόπτη';
        END IF;

        IF NEW.amka_epoptis = NEW.amka THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ο γιατρός δεν μπορεί να είναι επόπτης του εαυτού του';
        END IF;

        SELECT COUNT(*)
        INTO epoptis_exists
        FROM iatros
        WHERE amka = NEW.amka_epoptis;

        IF epoptis_exists = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ο επόπτης δεν υπάρχει';
        END IF;

        SELECT i.vathmida, i.amka_epoptis
        INTO vathmida_epopti, epoptis_tou_epopti
        FROM iatros i
        WHERE i.amka = NEW.amka_epoptis
        LIMIT 1;

        SELECT can_supervise
        INTO epoptis_can_supervise
        FROM vathmida_iatrou
        WHERE vathmida_id = vathmida_epopti
        LIMIT 1;

        IF epoptis_can_supervise = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η βαθμίδα του επόπτη δεν επιτρέπεται να επιβλέπει γιατρούς';
        END IF;

        IF epoptis_tou_epopti = NEW.amka THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Δεν επιτρέπεται κυκλική εξάρτηση εποπτείας';
        END IF;

    END IF;

END //

-- ============================================================
-- DEPARTMENT TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS proswpiko_anikei_se_tmima_insert_trigger //

CREATE TRIGGER proswpiko_anikei_se_tmima_insert_trigger
BEFORE INSERT ON proswpiko_anikei_se_tmima
FOR EACH ROW
BEGIN

    DECLARE proswpiko_exists INT DEFAULT 0;
    DECLARE tmima_exists INT DEFAULT 0;
    DECLARE katigoria VARCHAR(20);
    DECLARE anikei_idi INT DEFAULT 0;
    DECLARE mporei_na_dieftinei INT DEFAULT 0;
    DECLARE dieftinti_se_allo_tmima INT DEFAULT 0;
    DECLARE msg TEXT;

    SELECT COUNT(*)
    INTO proswpiko_exists
    FROM proswpiko
    WHERE amka = NEW.amka_proswpikou;

    IF proswpiko_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'To προσωπικό με αυτό το AMKA δεν υπάρχει';
    END IF;

    SELECT COUNT(*)
    INTO tmima_exists
    FROM tmima
    WHERE tmima_id = NEW.tmima_id;

    IF tmima_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Το τμήμα με αυτό το ID δεν υπάρχει';
    END IF;

    SELECT typos_proswpikou 
    INTO katigoria
    FROM proswpiko
    WHERE amka = NEW.amka_proswpikou;

    IF katigoria IN ('Νοσηλευτής', 'Διοικητικό') THEN

        SELECT COUNT(*)
        INTO anikei_idi
        FROM proswpiko_anikei_se_tmima
        WHERE amka_proswpikou = NEW.amka_proswpikou;

        IF anikei_idi = 1 THEN
            SET msg = CONCAT(
                'Το προσωπικό τύπου ',
                katigoria,
                ' ανήκει ήδη σε τμήμα. Αν θες να αλλάξεις το τμήμα κανε CALL το update_tmima_proswpikou'
            );

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = msg;
        END IF;

    END IF;

    IF katigoria = 'Ιατρός' THEN

        SELECT v.can_run_department
        INTO mporei_na_dieftinei
        FROM iatros AS i
        JOIN vathmida_iatrou AS v
            ON i.vathmida = v.vathmida_id
        WHERE i.amka = NEW.amka_proswpikou;

        IF mporei_na_dieftinei = 1 THEN

            SELECT COUNT(*)
            INTO dieftinti_se_allo_tmima
            FROM tmima
            WHERE amka_dieftinti = NEW.amka_proswpikou;

            IF dieftinti_se_allo_tmima != 0 THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Ο ιατρός αυτός είναι ήδη διευθυντής σε άλλο τμήμα. Αν θες να αλλάξεις το τμήμα κανε CALL το update_tmima_proswpikou';
            END IF;

        END IF;

    END IF;

END //

DROP TRIGGER IF EXISTS tmima_insert_trigger //

CREATE TRIGGER tmima_insert_trigger
BEFORE INSERT ON tmima
FOR EACH ROW
BEGIN

DECLARE dieftinti_exists INT DEFAULT 0;
DECLARE vathmida_dieftinti VARCHAR(20);
DECLARE dieftinti_se_allo_tmima INT DEFAULT 0;
IF NEW.amka_dieftinti IS NOT NULL THEN

    SELECT COUNT(*)
    INTO dieftinti_exists
    FROM iatros
    WHERE amka = NEW.amka_dieftinti;

    IF dieftinti_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο διευθυντής με αυτό το ΑΜΚΑ δεν είναι δηλωμένος ιατρός';
    END IF;   

    SELECT v.vathmida_onoma
    INTO vathmida_dieftinti
    FROM iatros i
    join vathmida_iatrou v on v.vathmida_id = i.vathmida
    WHERE amka = NEW.amka_dieftinti;

    IF vathmida_dieftinti != 'Διεθυντής' THEN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο ιατρός με αυτό το ΑΜΚΑ δεν έχει βαθμίδα διευθυντή';
    END IF;

    SELECT COUNT(*)
    INTO dieftinti_se_allo_tmima
    FROM tmima
    WHERE amka_dieftinti = NEW.amka_dieftinti;

    IF dieftinti_se_allo_tmima != 0 THEN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο διευθυντής αυτός είναι ήδη διευθυντής σε άλλο τμήμα. Αν θες να τον ορίσεις διευθυντή αυτού του τμήματος κάνε INSERT το τμήμα χωρίς διευθυντή και μετά χρησιμοποίησε την update_tmima_proswpikou';
    END IF;
END IF;
END //

-- ============================================================
-- NOSILEIA TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS nosileia_insert_trigger //

CREATE TRIGGER nosileia_insert_trigger
BEFORE INSERT ON nosileia
FOR EACH ROW
BEGIN
    DECLARE v_existing_tmima_id INT;
    DECLARE v_existing_ar_kliis SMALLINT;
    DECLARE v_actual_days  INT;
    DECLARE v_vasiko       DECIMAL(10,2);
    DECLARE v_mdn          SMALLINT;
    DECLARE v_imer_xrewsi  DECIMAL(8,2);
    DECLARE v_kostos_ken   DECIMAL(10,2);
    DECLARE v_kostos_exet  DECIMAL(10,2) DEFAULT 0;
    DECLARE v_kostos_praxi DECIMAL(10,2) DEFAULT 0;

    IF NEW.imerominia_eisodou > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εισόδου δεν μπορεί να είναι μελλοντική';
    END IF;

    IF NEW.imerominia_eksodou IS NOT NULL AND NEW.imerominia_eksodou > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εξόδου δεν μπορεί να είναι μελλοντική';
    END IF;

    IF EXISTS (
        SELECT 1 FROM nosileia
        WHERE amka_astheni = NEW.amka_astheni
        AND imerominia_eksodou IS NULL
    ) THEN
        SELECT tmima_id, ar_kliis
        INTO v_existing_tmima_id, v_existing_ar_kliis
        FROM nosileia
        WHERE amka_astheni = NEW.amka_astheni
        AND imerominia_eksodou IS NULL
        LIMIT 1;

        SET NEW.tmima_id = v_existing_tmima_id;
        SET NEW.ar_kliis = v_existing_ar_kliis;
    ELSE
        IF NOT EXISTS (
            SELECT 1 FROM diathesimes_klines
            WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η κλίνη δεν είναι διαθέσιμη';
        END IF;
    END IF;

    IF NEW.imerominia_eksodou IS NOT NULL THEN
        SELECT vasiko_kostos, mdn, imer_xrewsi
        INTO v_vasiko, v_mdn, v_imer_xrewsi
        FROM ken WHERE kod_ken = NEW.kod_ken;

        SET v_actual_days = DATEDIFF(NEW.imerominia_eksodou, NEW.imerominia_eisodou);

        IF v_actual_days <= v_mdn THEN
            SET v_kostos_ken = v_vasiko;
        ELSE
            SET v_kostos_ken = v_vasiko + (v_actual_days - v_mdn) * v_imer_xrewsi;
        END IF;

        SELECT COALESCE(SUM(kostos), 0) INTO v_kostos_exet
        FROM exetasi WHERE nosileia_id = NEW.nosileia_id;

        SELECT COALESCE(SUM(kostos), 0) INTO v_kostos_praxi
        FROM iatrikipraxi WHERE nosileia_id = NEW.nosileia_id;

        SET NEW.synoliko_kostos = v_kostos_ken + v_kostos_exet + v_kostos_praxi;
    END IF;
END //

DROP TRIGGER IF EXISTS nosileia_after_insert_trigger //

CREATE TRIGGER nosileia_after_insert_trigger
AFTER INSERT ON nosileia
FOR EACH ROW
BEGIN
    IF NEW.imerominia_eksodou IS NULL THEN
        UPDATE klini SET katastasi = 'Κατειλημμένη'
        WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis;
    ELSE
        UPDATE klini SET katastasi = 'Διαθέσιμη'
        WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis;
    END IF;
END //

DROP TRIGGER IF EXISTS nosileia_before_update_trigger //

CREATE TRIGGER nosileia_before_update_trigger
BEFORE UPDATE ON nosileia
FOR EACH ROW
BEGIN
    DECLARE v_actual_days  INT;
    DECLARE v_vasiko       DECIMAL(10,2);
    DECLARE v_mdn          SMALLINT;
    DECLARE v_imer_xrewsi  DECIMAL(8,2);
    DECLARE v_kostos_ken   DECIMAL(10,2);
    DECLARE v_kostos_exet  DECIMAL(10,2) DEFAULT 0;
    DECLARE v_kostos_praxi DECIMAL(10,2) DEFAULT 0;

    IF OLD.imerominia_eksodou IS NULL AND NEW.imerominia_eksodou IS NOT NULL
       AND NEW.imerominia_eksodou > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εξόδου δεν μπορεί να είναι μελλοντική';
    END IF;

    IF OLD.imerominia_eksodou IS NULL AND NEW.imerominia_eksodou IS NOT NULL THEN
        SELECT vasiko_kostos, mdn, imer_xrewsi
        INTO v_vasiko, v_mdn, v_imer_xrewsi
        FROM ken WHERE kod_ken = NEW.kod_ken;

        SET v_actual_days = DATEDIFF(NEW.imerominia_eksodou, NEW.imerominia_eisodou);

        IF v_actual_days <= v_mdn THEN
            SET v_kostos_ken = v_vasiko;
        ELSE
            SET v_kostos_ken = v_vasiko + (v_actual_days - v_mdn) * v_imer_xrewsi;
        END IF;

        SELECT COALESCE(SUM(kostos), 0) INTO v_kostos_exet
        FROM exetasi WHERE nosileia_id = NEW.nosileia_id;

        SELECT COALESCE(SUM(kostos), 0) INTO v_kostos_praxi
        FROM iatrikipraxi WHERE nosileia_id = NEW.nosileia_id;

        SET NEW.synoliko_kostos = v_kostos_ken + v_kostos_exet + v_kostos_praxi;
    END IF;
END //

DROP TRIGGER IF EXISTS nosileia_after_update_eksodou //

CREATE TRIGGER nosileia_after_update_eksodou
AFTER UPDATE ON nosileia
FOR EACH ROW
BEGIN
    IF OLD.imerominia_eksodou IS NULL AND NEW.imerominia_eksodou IS NOT NULL THEN
        UPDATE klini SET katastasi = 'Διαθέσιμη'
        WHERE tmima_id = NEW.tmima_id AND ar_kliis = NEW.ar_kliis;
    END IF;
END //

DROP TRIGGER IF EXISTS diagnosi_insert_trigger //

CREATE TRIGGER diagnosi_insert_trigger
BEFORE INSERT ON diagnosi
FOR EACH ROW
BEGIN
    IF NEW.tipos_diagnosis = 'Εισοδος' AND NEW.icd IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η διάγνωση εισόδου απαιτεί κωδικό ICD';
    END IF;

    IF NEW.tipos_diagnosis = 'Εξοδος' THEN
        IF NOT EXISTS (
            SELECT 1 FROM diagnosi
            WHERE nosileia_id = NEW.nosileia_id AND tipos_diagnosis = 'Εισοδος'
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Δεν υπάρχει διάγνωση εισόδου για αυτή τη νοσηλεία';
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM nosileia
            WHERE nosileia_id = NEW.nosileia_id AND imerominia_eksodou IS NOT NULL
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η ημερομηνία εξόδου δεν έχει οριστεί στη νοσηλεία';
        END IF;
    END IF;
END //

DROP TRIGGER IF EXISTS axiologisi_insert_trigger //

CREATE TRIGGER axiologisi_insert_trigger
BEFORE INSERT ON axiologisi
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM nosileia
        WHERE nosileia_id = NEW.nosileia_id AND imerominia_eksodou IS NOT NULL
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η αξιολόγηση μπορεί να γίνει μόνο μετά την έξοδο του ασθενούς';
    END IF;
END //

DROP TRIGGER IF EXISTS exetasi_insert_trigger //

CREATE TRIGGER exetasi_insert_trigger
BEFORE INSERT ON exetasi
FOR EACH ROW
BEGIN
    DECLARE v_imer_eisagogis DATE;
    DECLARE v_imer_exodou    DATE;

    SELECT imerominia_eisodou, imerominia_eksodou
    INTO v_imer_eisagogis, v_imer_exodou
    FROM nosileia
    WHERE nosileia_id = NEW.nosileia_id;

    IF NEW.imerominia < v_imer_eisagogis THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εξέτασης είναι πριν την εισαγωγή του ασθενούς';
    END IF;

    IF v_imer_exodou IS NOT NULL AND NEW.imerominia > v_imer_exodou THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία εξέτασης είναι μετά την έξοδο του ασθενούς';
    END IF;
END //

DROP TRIGGER IF EXISTS iatrikipraxi_insert_trigger //

CREATE TRIGGER iatrikipraxi_insert_trigger
BEFORE INSERT ON iatrikipraxi
FOR EACH ROW
BEGIN
    DECLARE v_imer_eisagogis              DATE;
    DECLARE v_imer_exodou                 DATE;
    DECLARE v_space_conflict              INT DEFAULT 0;
    DECLARE v_surgeon_conflict            INT DEFAULT 0;
    DECLARE v_surgeon_as_assist_conflict  INT DEFAULT 0;
    DECLARE v_new_end                     DATETIME;

    SET v_new_end = DATE_ADD(NEW.imerominia_wra, INTERVAL NEW.diarkeia_lepta MINUTE);

    SELECT imerominia_eisodou, imerominia_eksodou
    INTO v_imer_eisagogis, v_imer_exodou
    FROM nosileia
    WHERE nosileia_id = NEW.nosileia_id;

    IF DATE(NEW.imerominia_wra) < v_imer_eisagogis THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία επέμβασης είναι πριν την εισαγωγή του ασθενούς';
    END IF;

    IF v_imer_exodou IS NOT NULL AND DATE(NEW.imerominia_wra) > v_imer_exodou THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η ημερομηνία επέμβασης είναι μετά την έξοδο του ασθενούς';
    END IF;

    SELECT COUNT(*)
    INTO v_space_conflict
    FROM iatrikipraxi ip
    WHERE ip.kod_xwrou = NEW.kod_xwrou
      AND NEW.imerominia_wra < DATE_ADD(ip.imerominia_wra, INTERVAL ip.diarkeia_lepta MINUTE)
      AND ip.imerominia_wra < v_new_end;

    IF v_space_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Υπάρχει άλλη επέμβαση στον ίδιο χώρο την ίδια ώρα';
    END IF;

    SELECT COUNT(*)
    INTO v_surgeon_conflict
    FROM iatrikipraxi ip
    WHERE ip.amka_kyriou_xeirourgou = NEW.amka_kyriou_xeirourgou
      AND NEW.imerominia_wra < DATE_ADD(ip.imerominia_wra, INTERVAL ip.diarkeia_lepta MINUTE)
      AND ip.imerominia_wra < v_new_end;

    IF v_surgeon_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο κύριος χειρουργός συμμετέχει ήδη σε άλλη επέμβαση την ίδια ώρα';
    END IF;

    SELECT COUNT(*)
    INTO v_surgeon_as_assist_conflict
    FROM praxi_voithos pv
    JOIN iatrikipraxi ip ON ip.kodikos = pv.kod_praxis
    WHERE pv.amka_voithou = NEW.amka_kyriou_xeirourgou
      AND NEW.imerominia_wra < DATE_ADD(ip.imerominia_wra, INTERVAL ip.diarkeia_lepta MINUTE)
      AND ip.imerominia_wra < v_new_end;

    IF v_surgeon_as_assist_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο κύριος χειρουργός είναι ήδη βοηθός σε άλλη επέμβαση την ίδια ώρα';
    END IF;
END //

DROP TRIGGER IF EXISTS praxi_voithos_insert_trigger //

CREATE TRIGGER praxi_voithos_insert_trigger
BEFORE INSERT ON praxi_voithos
FOR EACH ROW
BEGIN
    DECLARE v_main_surgeon              CHAR(11);
    DECLARE v_op_start                  DATETIME;
    DECLARE v_op_duration               SMALLINT;
    DECLARE v_op_end                    DATETIME;
    DECLARE v_typos                     VARCHAR(20);
    DECLARE v_as_surgeon_conflict       INT DEFAULT 0;
    DECLARE v_as_assistant_conflict     INT DEFAULT 0;

    SELECT amka_kyriou_xeirourgou, imerominia_wra, diarkeia_lepta
    INTO v_main_surgeon, v_op_start, v_op_duration
    FROM iatrikipraxi
    WHERE kodikos = NEW.kod_praxis;

    SET v_op_end = DATE_ADD(v_op_start, INTERVAL v_op_duration MINUTE);

    IF NEW.amka_voithou = v_main_surgeon THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο βοηθός δεν μπορεί να είναι ο κύριος χειρουργός της ίδιας επέμβασης';
    END IF;

    SELECT typos_proswpikou INTO v_typos
    FROM proswpiko WHERE amka = NEW.amka_voithou;

    IF v_typos = 'Ιατρός' THEN
        SELECT COUNT(*)
        INTO v_as_surgeon_conflict
        FROM iatrikipraxi ip
        WHERE ip.amka_kyriou_xeirourgou = NEW.amka_voithou
          AND v_op_start < DATE_ADD(ip.imerominia_wra, INTERVAL ip.diarkeia_lepta MINUTE)
          AND ip.imerominia_wra < v_op_end;

        IF v_as_surgeon_conflict > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ο βοηθός ιατρός συμμετέχει ως κύριος χειρουργός σε άλλη επέμβαση την ίδια ώρα';
        END IF;
    END IF;

    SELECT COUNT(*)
    INTO v_as_assistant_conflict
    FROM praxi_voithos pv
    JOIN iatrikipraxi ip ON ip.kodikos = pv.kod_praxis
    WHERE pv.amka_voithou = NEW.amka_voithou
      AND v_op_start < DATE_ADD(ip.imerominia_wra, INTERVAL ip.diarkeia_lepta MINUTE)
      AND ip.imerominia_wra < v_op_end;

    IF v_as_assistant_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο βοηθός συμμετέχει ήδη σε άλλη επέμβαση την ίδια ώρα';
    END IF;
END //

-- ============================================================
-- SHIFTS TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS shift_trigger_insert //

CREATE TRIGGER shift_trigger_insert
BEFORE INSERT ON efimeria_proswpiko
FOR EACH ROW
BEGIN
    DECLARE v_max_allowed INT DEFAULT 0;
    DECLARE v_monthly_count INT DEFAULT 0;

    DECLARE v_rest_hours INT DEFAULT 8;
    DECLARE v_allowed_consecutive INT;

    DECLARE v_last_shift_end DATETIME;
    DECLARE v_new_shift_start DATETIME;
    DECLARE v_hours_since_last INT;

    DECLARE v_consecutive_same_type INT DEFAULT 0;
    DECLARE msg VARCHAR(255);

    SELECT
        COALESCE(CASE
            WHEN p.typos_proswpikou = 'Ιατρός'
                THEN er.iatros_max_monthly_ef_count
            WHEN p.typos_proswpikou = 'Νοσηλευτής'
                THEN er.nosileutes_max_monthly_ef_count
            WHEN p.typos_proswpikou = 'Διοικητικό'
                THEN er.dioikitiko_max_monthly_ef_count
            ELSE 0
        END,100000),
        v.endiamesi_ora_anapausis_hours,
        v.epitreptes_sinexomenes_vardies,
        TIMESTAMP(NEW.imerominia, v.vardia_ora_ekkinisis)
    INTO
        v_max_allowed,
        v_rest_hours,
        v_allowed_consecutive,
        v_new_shift_start
    FROM proswpiko p
    JOIN vardia v
        ON v.vardia_id = NEW.vardia
    CROSS JOIN efimeria_requirements er
    WHERE p.amka = NEW.amka_proswpiko
    LIMIT 1;

    SELECT COALESCE(COUNT(*),0)
    INTO v_monthly_count
    FROM efimeria_proswpiko e
    WHERE e.amka_proswpiko = NEW.amka_proswpiko
      AND YEAR(e.imerominia) = YEAR(NEW.imerominia)
      AND MONTH(e.imerominia) = MONTH(NEW.imerominia);

    IF v_monthly_count >= v_max_allowed THEN
        SET msg = 'Έχει ξεπεραστεί το μηνιαίο όριο εφημεριών';
        CALL add_error(msg);
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = msg;
    END IF;

    SELECT
        CASE
            WHEN v.vardia_ora_lixis <= v.vardia_ora_ekkinisis
                THEN TIMESTAMP(DATE_ADD(e.imerominia, INTERVAL 1 DAY), v.vardia_ora_lixis)
            ELSE TIMESTAMP(e.imerominia, v.vardia_ora_lixis)
        END
    INTO v_last_shift_end
    FROM efimeria_proswpiko e
    JOIN vardia v
        ON v.vardia_id = e.vardia
    WHERE e.amka_proswpiko = NEW.amka_proswpiko
      AND TIMESTAMP(e.imerominia, v.vardia_ora_ekkinisis) < v_new_shift_start
    ORDER BY
        CASE
            WHEN v.vardia_ora_lixis <= v.vardia_ora_ekkinisis
                THEN TIMESTAMP(DATE_ADD(e.imerominia, INTERVAL 1 DAY), v.vardia_ora_lixis)
            ELSE TIMESTAMP(e.imerominia, v.vardia_ora_lixis)
        END DESC
    LIMIT 1;

    IF v_last_shift_end IS NOT NULL THEN

        SET v_hours_since_last =
            TIMESTAMPDIFF(HOUR, v_last_shift_end, v_new_shift_start);

        IF v_hours_since_last < v_rest_hours THEN
            CALL add_error('Δεν υπάρχει το ελάχιστο διάστημα ανάπαυσης μεταξύ των βαρδιών');
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Δεν υπάρχει το ελάχιστο διάστημα ανάπαυσης μεταξύ των βαρδιών';
        END IF;

    END IF;

    IF v_allowed_consecutive IS NOT NULL THEN

        SELECT COUNT(*)
        INTO v_consecutive_same_type
        FROM efimeria_proswpiko e
        JOIN vardia v
            ON v.vardia_id = e.vardia
        WHERE e.amka_proswpiko = NEW.amka_proswpiko
          AND e.vardia = NEW.vardia
          AND e.imerominia IN (
              DATE_SUB(NEW.imerominia, INTERVAL 1 DAY),
              DATE_SUB(NEW.imerominia, INTERVAL 2 DAY),
              DATE_SUB(NEW.imerominia, INTERVAL 3 DAY)
          );

        IF v_consecutive_same_type >= v_allowed_consecutive THEN
            SET msg = CONCAT(
                'Έχει ξεπεραστεί το όριο συνεχόμενων νυχτερινών βαρδιών για ΑΜΚΑ ',
                NEW.amka_proswpiko
            );
            CALL add_error(msg);
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = msg;
        END IF;

    END IF;
END //

DROP TRIGGER IF EXISTS shift_trigger_after_insert //

CREATE TRIGGER shift_trigger_after_insert
AFTER INSERT ON efimeria_proswpiko
FOR EACH ROW
BEGIN
    IF efimeria_check(NEW.tmima, NEW.imerominia, NEW.vardia) = 1 THEN
        UPDATE efimeria
        SET statusEf = 'FINISHED'
        WHERE tmima = NEW.tmima
          AND imerominia = NEW.imerominia
          AND vardia = NEW.vardia;
    END IF;
END //

-- ============================================================
-- TRIAGE TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS triage_trigger_insert //

CREATE TRIGGER triage_trigger_insert
BEFORE INSERT ON dialogistoixeiwn
FOR EACH ROW
BEGIN
    DECLARE v_imerominia DATE;
    DECLARE v_vardia INT;
    DECLARE v_triage_amka CHAR(11);
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = TRUE;

    SELECT
        CASE
            WHEN v.vardia_ora_lixis > v.vardia_ora_ekkinisis
                THEN DATE(NEW.wra_afiksis)
            WHEN TIME(NEW.wra_afiksis) >= v.vardia_ora_ekkinisis
                THEN DATE(NEW.wra_afiksis)
            ELSE DATE_SUB(DATE(NEW.wra_afiksis), INTERVAL 1 DAY)
        END,
        v.vardia_id
    INTO v_imerominia, v_vardia
    FROM vardia v
    WHERE
        (v.vardia_ora_lixis > v.vardia_ora_ekkinisis
         AND TIME(NEW.wra_afiksis) >= v.vardia_ora_ekkinisis
         AND TIME(NEW.wra_afiksis) <  v.vardia_ora_lixis)
        OR
        (v.vardia_ora_lixis <= v.vardia_ora_ekkinisis
         AND (TIME(NEW.wra_afiksis) >= v.vardia_ora_ekkinisis
              OR TIME(NEW.wra_afiksis) < v.vardia_ora_lixis))
    LIMIT 1;

    SET v_not_found = FALSE;

    SELECT amka_proswpiko
    INTO v_triage_amka
    FROM efimeria_se_kathikon_triage
    WHERE imerominia = v_imerominia
      AND vardia     = v_vardia;

    IF v_not_found THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Δεν έχει οριστεί νοσηλευτής διαλογής για αυτή τη βάρδια.';
    END IF;

    IF v_triage_amka <> NEW.amka_nosilevti THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ο νοσηλευτής δεν είναι ο νοσηλευτής διαλογής για αυτή τη βάρδια.';
    END IF;
END //

-- ============================================================
-- DRUGS TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS syntagografisi_insert_trigger //

CREATE TRIGGER syntagografisi_insert_trigger
BEFORE INSERT ON syntagografisi
FOR EACH ROW
BEGIN
    DECLARE v_allergy_conflict INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_allergy_conflict
    FROM farmako_drastiki fd
    JOIN allergy a ON a.ousia_id = fd.ousia_id
    WHERE fd.kod_ema       = NEW.kod_ema
      AND a.amka_astheni   = NEW.amka_astheni;

    IF v_allergy_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Απαγορεύεται η συνταγογράφηση: ο ασθενής έχει αλλεργία σε δραστική ουσία του φαρμάκου';
    END IF;
END //

DELIMITER ;

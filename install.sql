-- ============================================================
-- install.sql  –  Γενικό Νοσοκομείο Υγειόπολης
-- ΒΔ 2025-2026, ΣΗΜΜΥ ΕΜΠ
-- Συμβατό με: MariaDB 10.6+ / MySQL 8+
-- Encoding: UTF-8
-- ============================================================
 
SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;
 
-- ============================================================
-- ΚΑΘΑΡΙΣΜΟΣ (drop σε αντίστροφη σειρά εξαρτήσεων)
-- ============================================================
DROP TABLE IF EXISTS eikona_farmako;
DROP TABLE IF EXISTS eikona_iatrikipraxi;
DROP TABLE IF EXISTS eikona_nosileia;
DROP TABLE IF EXISTS eikona_tmima;
DROP TABLE IF EXISTS eikona_anthropos;
DROP TABLE IF EXISTS eikona;
DROP TABLE IF EXISTS allergy;
DROP TABLE IF EXISTS syntagografisi;
DROP TABLE IF EXISTS farmako_drastiki;
DROP TABLE IF EXISTS drastiki_ousia;
DROP TABLE IF EXISTS farmako;
DROP TABLE IF EXISTS dialogistoixeiwn;
DROP TABLE IF EXISTS praxi_voithos;
DROP TABLE IF EXISTS iatrikipraxi;
DROP TABLE IF EXISTS xwros_epembasis;
DROP TABLE IF EXISTS exetasi;
DROP TABLE IF EXISTS axiologisi;
DROP TABLE IF EXISTS nosileia_diagnosi_ex;
DROP TABLE IF EXISTS nosileia_diagnosi_eis;
DROP TABLE IF EXISTS diagnosi;
DROP TABLE IF EXISTS nosileia;
DROP TABLE IF EXISTS ken;
DROP TABLE IF EXISTS efimeria_proswpiko;
DROP TABLE IF EXISTS efimeria;
DROP TABLE IF EXISTS klini;
DROP TABLE IF EXISTS iatros_tmima;
DROP TABLE IF EXISTS tmima;
DROP TABLE IF EXISTS dioikitiko;
DROP TABLE IF EXISTS nosilevtis;
DROP TABLE IF EXISTS iatros;
DROP TABLE IF EXISTS proswpiko;
DROP TABLE IF EXISTS ektakti_epafi;
DROP TABLE IF EXISTS asthenis;
DROP TABLE IF EXISTS anthropos;
 
SET FOREIGN_KEY_CHECKS = 1;
 
-- ============================================================
-- 1. ΑΝΘΡΩΠΟΣ  (superclass)
-- ============================================================


    CREATE TABLE tmima (
        onoma           VARCHAR(100)    NOT NULL,
        perigrafi       TEXT            NULL,
        arithmos_klinon SMALLINT        NOT NULL CHECK (arithmos_klinon >= 0),
        orofos_ktiriou   VARCHAR(50)     NOT NULL,
        amka_dieftinti  CHAR(11)        NULL,  -- FK προς iatros (circular → add after)
        PRIMARY KEY (onoma)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

     -- ============================================================
    -- 8. ΝΟΣΗΛΕΥΤΗΣ  (ISA from proswpiko)
    -- ============================================================
    CREATE TABLE nosilevtis (
        amka            CHAR(11)        NOT NULL,
        vathmida        VARCHAR(30)     NOT NULL
            CHECK (vathmida IN ('Βοηθός Νοσηλευτή','Νοσηλευτής','Προϊστάμενος')),
        onoma_tmimatos  VARCHAR(100)    NOT NULL,
        PRIMARY KEY (amka),
        FOREIGN KEY (amka) REFERENCES proswpiko(amka)
            ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY (onoma_tmimatos) REFERENCES tmima(onoma)
            ON DELETE RESTRICT ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- ============================================================
    -- 9. ΔΙΟΙΚΗΤΙΚΟ  (ISA from proswpiko)
    -- ============================================================
    CREATE TABLE dioikitiko (
        amka            CHAR(11)        NOT NULL,
        rolos           VARCHAR(80)     NOT NULL,
        grafeio         VARCHAR(50)     NULL,
        onoma_tmimatos  VARCHAR(100)    NOT NULL,
        PRIMARY KEY (amka),
        FOREIGN KEY (amka) REFERENCES proswpiko(amka)
            ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY (onoma_tmimatos) REFERENCES tmima(onoma)
            ON DELETE RESTRICT ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    -- CREATE TABLE asthenis (
    --     amka                CHAR(11)        NOT NULL,
    --     patronymo           VARCHAR(50)     NULL,
    --     fylo                CHAR(1)         NOT NULL CHECK (fylo IN ('Α','Θ','Α','F','M')),
    --     varos               DECIMAL(5,2)    NULL CHECK (varos > 0),
    --     ypsos               DECIMAL(5,2)    NULL CHECK (ypsos > 0),
    --     diefthinsi          VARCHAR(200)    NULL,
    --     epangelma           VARCHAR(100)    NULL,
    --     ypikoiotita         VARCHAR(50)     NULL,
    --     asfalistikos_foreas VARCHAR(100)    NOT NULL,
    --     PRIMARY KEY (amka),
    --     FOREIGN KEY (amka) REFERENCES anthropos(amka)
    --         ON DELETE CASCADE ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 3. ΕΚΤΑΚΤΗ_ΕΠΑΦΗ  (weak entity, owned by asthenis)
    -- -- ============================================================
    -- CREATE TABLE ektakti_epafi (
    --     amka_astheni    CHAR(11)        NOT NULL,
    --     tilefono        VARCHAR(15)     NOT NULL,
    --     onoma           VARCHAR(50)     NOT NULL,
    --     eponymo         VARCHAR(50)     NOT NULL,
    --     email           VARCHAR(100)    NULL,
    --     PRIMARY KEY (amka_astheni, tilefono),
    --     FOREIGN KEY (amka_astheni) REFERENCES asthenis(amka)
    --         ON DELETE CASCADE ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 4. ΠΡΟΣΩΠΙΚΟ  (ISA from anthropos)
    -- -- ============================================================

    
    -- -- ============================================================
    -- -- 5. ΤΜΗΜΑ  (πρώτα, γιατί ΙΑΤΡΟΣ reference to ΤΜΗΜΑ)
    -- -- ============================================================

    
    -- -- ============================================================
    -- -- 6. ΙΑΤΡΟΣ  (ISA from proswpiko)
    -- -- ============================================================

    
    -- -- Τώρα προσθέτουμε FK tmima → iatros (circular χρειάζεται ALTER)
    -- ALTER TABLE tmima
    --     ADD CONSTRAINT fk_tmima_dieftintis
    --     FOREIGN KEY (amka_dieftinti) REFERENCES iatros(amka)
    --     ON DELETE SET NULL ON UPDATE CASCADE;
    
    -- -- ============================================================
    -- -- 7. ΙΑΤΡΟΣ–ΤΜΗΜΑ  (M:N, ιατρός μπορεί σε πολλά τμήματα)
    -- -- ============================================================
    -- CREATE TABLE iatros_tmima (
    --     amka_iatrou     CHAR(11)        NOT NULL,
    --     onoma_tmimatos  VARCHAR(100)    NOT NULL,
    --     PRIMARY KEY (amka_iatrou, onoma_tmimatos),
    --     FOREIGN KEY (amka_iatrou) REFERENCES iatros(amka)
    --         ON DELETE CASCADE ON UPDATE CASCADE,
    --     FOREIGN KEY (onoma_tmimatos) REFERENCES tmima(onoma)
    --         ON DELETE CASCADE ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
   
    
    -- -- ============================================================
    -- -- 10. ΚΛΙΝΗ  (weak entity, owned by tmima)
    -- -- ============================================================
    -- CREATE TABLE klini (
    --     onoma_tmimatos  VARCHAR(100)    NOT NULL,
    --     ar_kliis        SMALLINT        NOT NULL CHECK (ar_kliis > 0),
    --     typos           VARCHAR(30)     NOT NULL,
    --     katastasi       VARCHAR(30)     NOT NULL
    --         CHECK (katastasi IN ('Διαθέσιμη','Κατειλημμένη','Υπό συντήρηση')),
    --     PRIMARY KEY (onoma_tmimatos, ar_kliis),
    --     FOREIGN KEY (onoma_tmimatos) REFERENCES tmima(onoma)
    --         ON DELETE CASCADE ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 11. ΕΦΗΜΕΡΙΑ  (weak entity, owned by tmima)
    -- -- ============================================================
    -- CREATE TABLE efimeria (
    --     onoma_tmimatos  VARCHAR(100)    NOT NULL,
    --     imerominia      DATE            NOT NULL,
    --     vardia          VARCHAR(15)     NOT NULL
    --         CHECK (vardia IN ('Πρωινή','Απογευματινή','Νυχτερινή')),
    --     PRIMARY KEY (onoma_tmimatos, imerominia, vardia),
    --     FOREIGN KEY (onoma_tmimatos) REFERENCES tmima(onoma)
    --         ON DELETE CASCADE ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 12. ΕΦΗΜΕΡΙΑ_ΠΡΟΣΩΠΙΚΟ  (M:N junction)
    -- -- ============================================================
    
    
    -- -- ============================================================
    -- -- 13. ΚΕΝ  (Κλειστά Ενοποιημένα Νοσήλια)
    -- -- ============================================================
    -- CREATE TABLE ken (
    --     kod_ken         VARCHAR(20)     NOT NULL,
    --     vasiko_kostos   DECIMAL(10,2)   NOT NULL CHECK (vasiko_kostos >= 0),
    --     mdn             DECIMAL(5,1)    NOT NULL CHECK (mdn > 0),
    --     imer_xrewsi     DECIMAL(8,2)    NOT NULL CHECK (imer_xrewsi >= 0),
    --     PRIMARY KEY (kod_ken)
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 14. ΝΟΣΗΛΕΙΑ
    -- -- ============================================================
    -- CREATE TABLE nosileia (
    --     nosileia_id             INT             NOT NULL AUTO_INCREMENT,
    --     amka_astheni            CHAR(11)        NOT NULL,
    --     onoma_tmimatos          VARCHAR(100)    NOT NULL,
    --     onoma_tmimatos_kliis    VARCHAR(100)    NOT NULL,
    --     ar_kliis                SMALLINT        NOT NULL,
    --     kod_ken                 VARCHAR(20)     NOT NULL,
    --     imer_eisagogis          DATE            NOT NULL,
    --     imer_exodou             DATE            NULL,
    --     PRIMARY KEY (nosileia_id),
    --     FOREIGN KEY (amka_astheni) REFERENCES asthenis(amka)
    --         ON DELETE RESTRICT ON UPDATE CASCADE,
    --     FOREIGN KEY (onoma_tmimatos) REFERENCES tmima(onoma)
    --         ON DELETE RESTRICT ON UPDATE CASCADE,
    --     FOREIGN KEY (onoma_tmimatos_kliis, ar_kliis)
    --         REFERENCES klini(onoma_tmimatos, ar_kliis)
    --         ON DELETE RESTRICT ON UPDATE CASCADE,
    --     FOREIGN KEY (kod_ken) REFERENCES ken(kod_ken)
    --         ON DELETE RESTRICT ON UPDATE CASCADE,
    --     CHECK (imer_exodou IS NULL OR imer_exodou >= imer_eisagogis)
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 15. ΔΙΑΓΝΩΣΗ  (ICD-10 catalog)
    -- -- ============================================================
    -- CREATE TABLE diagnosi (
    --     icd             VARCHAR(10)     NOT NULL,
    --     perigrafi       TEXT            NOT NULL,
    --     PRIMARY KEY (icd)
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 16. ΝΟΣΗΛΕΙΑ_ΔΙΑΓΝΩΣΗ_ΕΙΣ  (M:N junction)
    -- -- ============================================================
    -- CREATE TABLE nosileia_diagnosi_eis (
    --     nosileia_id     INT             NOT NULL,
    --     icd             VARCHAR(10)     NOT NULL,
    --     PRIMARY KEY (nosileia_id, icd),
    --     FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
    --         ON DELETE CASCADE ON UPDATE CASCADE,
    --     FOREIGN KEY (icd) REFERENCES diagnosi(icd)
    --         ON DELETE RESTRICT ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 17. ΝΟΣΗΛΕΙΑ_ΔΙΑΓΝΩΣΗ_ΕΞ  (M:N junction)
    -- -- ============================================================
    -- CREATE TABLE nosileia_diagnosi_ex (
    --     nosileia_id     INT             NOT NULL,
    --     icd             VARCHAR(10)     NOT NULL,
    --     PRIMARY KEY (nosileia_id, icd),
    --     FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
    --         ON DELETE CASCADE ON UPDATE CASCADE,
    --     FOREIGN KEY (icd) REFERENCES diagnosi(icd)
    --         ON DELETE RESTRICT ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 18. ΑΞΙΟΛΟΓΗΣΗ  (weak entity, 1:1 με nosileia)
    -- -- ============================================================
    -- CREATE TABLE axiologisi (
    --     nosileia_id                 INT             NOT NULL,
    --     poiotita_iatr_frontidas     TINYINT         NOT NULL CHECK (poiotita_iatr_frontidas BETWEEN 1 AND 5),
    --     poiotita_nosileft_frontidas TINYINT         NOT NULL CHECK (poiotita_nosileft_frontidas BETWEEN 1 AND 5),
    --     kathariotita                TINYINT         NOT NULL CHECK (kathariotita BETWEEN 1 AND 5),
    --     fagito                      TINYINT         NOT NULL CHECK (fagito BETWEEN 1 AND 5),
    --     synolikí_empeiria           TINYINT         NOT NULL CHECK (synolikí_empeiria BETWEEN 1 AND 5),
    --     PRIMARY KEY (nosileia_id),
    --     FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
    --         ON DELETE CASCADE ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 19. ΕΞΕΤΑΣΗ  (weak entity, owned by nosileia)
    -- -- ============================================================
    -- CREATE TABLE exetasi (
    --     nosileia_id         INT             NOT NULL,
    --     kodikos             VARCHAR(20)     NOT NULL,
    --     typos               VARCHAR(80)     NOT NULL,
    --     imerominia          DATE            NOT NULL,
    --     apotelesma_keim     TEXT            NULL,
    --     apotelesma_ar_timi  DECIMAL(12,4)   NULL,
    --     apotelesma_monada   VARCHAR(30)     NULL,
    --     kostos              DECIMAL(10,2)   NOT NULL CHECK (kostos >= 0),
    --     amka_iatrou         CHAR(11)        NOT NULL,
    --     PRIMARY KEY (nosileia_id, kodikos),
    --     FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
    --         ON DELETE CASCADE ON UPDATE CASCADE,
    --     FOREIGN KEY (amka_iatrou) REFERENCES iatros(amka)
    --         ON DELETE RESTRICT ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 20. ΧΩΡΟΣ_ΕΠΕΜΒΑΣΗΣ
    -- -- ============================================================
    -- CREATE TABLE xwros_epembasis (
    --     kodikos         VARCHAR(20)     NOT NULL,
    --     typos           VARCHAR(30)     NOT NULL
    --         CHECK (typos IN ('Χειρουργείο','Αίθουσα επέμβασης')),
    --     rofos           VARCHAR(30)     NULL,
    --     PRIMARY KEY (kodikos)
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 21. ΙΑΤΡΙΚΗ_ΠΡΑΞΗ
    -- -- ============================================================
    -- CREATE TABLE iatrikipraxi (
    --     kodikos                 VARCHAR(20)     NOT NULL,
    --     nosileia_id             INT             NOT NULL,
    --     amka_kyriou_xeirourgou  CHAR(11)        NOT NULL,
    --     kod_xwrou               VARCHAR(20)     NOT NULL,
    --     onoma                   VARCHAR(200)    NOT NULL,
    --     katigoria               VARCHAR(30)     NOT NULL
    --         CHECK (katigoria IN ('Χειρουργική','Διαγνωστική','Θεραπευτική')),
    --     diarkeia_lepta          SMALLINT        NOT NULL CHECK (diarkeia_lepta > 0),
    --     kostos                  DECIMAL(10,2)   NOT NULL CHECK (kostos >= 0),
    --     imerominia_wra          DATETIME        NOT NULL,
    --     PRIMARY KEY (kodikos),
    --     FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
    --         ON DELETE RESTRICT ON UPDATE CASCADE,
    --     FOREIGN KEY (amka_kyriou_xeirourgou) REFERENCES iatros(amka)
    --         ON DELETE RESTRICT ON UPDATE CASCADE,
    --     FOREIGN KEY (kod_xwrou) REFERENCES xwros_epembasis(kodikos)
    --         ON DELETE RESTRICT ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 22. ΠΡΑΞΗ_ΒΟΗΘΟΣ  (M:N: iatrikipraxi ↔ proswpiko)
    -- -- ============================================================
    -- CREATE TABLE praxi_voithos (
    --     kod_praxis      VARCHAR(20)     NOT NULL,
    --     amka_voithou    CHAR(11)        NOT NULL,
    --     PRIMARY KEY (kod_praxis, amka_voithou),
    --     FOREIGN KEY (kod_praxis) REFERENCES iatrikipraxi(kodikos)
    --         ON DELETE CASCADE ON UPDATE CASCADE,
    --     FOREIGN KEY (amka_voithou) REFERENCES proswpiko(amka)
    --         ON DELETE CASCADE ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 23. ΔΙΑΛΟΓΗ_ΣΤΟΙΧΕΙΩΝ  (triage)
    -- -- ============================================================
    -- CREATE TABLE dialogistoixeiwn (
    --     id_dialogis         INT             NOT NULL AUTO_INCREMENT,
    --     amka_astheni        CHAR(11)        NOT NULL,
    --     amka_nosilevti      CHAR(11)        NOT NULL,
    --     wra_afiksis         DATETIME        NOT NULL,
    --     symptomata          TEXT            NOT NULL,
    --     epipedo             TINYINT         NOT NULL CHECK (epipedo BETWEEN 1 AND 5),
    --     nosileia_id         INT             NULL,   -- NULL αν αποχωρεί
    --     PRIMARY KEY (id_dialogis),
    --     FOREIGN KEY (amka_astheni) REFERENCES asthenis(amka)
    --         ON DELETE RESTRICT ON UPDATE CASCADE,
    --     FOREIGN KEY (amka_nosilevti) REFERENCES nosilevtis(amka)
    --         ON DELETE RESTRICT ON UPDATE CASCADE,
    --     FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id)
    --         ON DELETE SET NULL ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 24. ΦΑΡΜΑΚΟ  (EMA Article 57 catalog)
    -- -- ============================================================
    -- CREATE TABLE farmako (
    --     kod_ema         VARCHAR(50)     NOT NULL,
    --     onoma           VARCHAR(300)    NOT NULL,
    --     kataskeyastis   VARCHAR(200)    NULL,
    --     morfi           VARCHAR(100)    NULL,
    --     PRIMARY KEY (kod_ema)
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 25. ΔΡΑΣΤΙΚΗ_ΟΥΣΙΑ
    -- -- ============================================================
    -- CREATE TABLE drastiki_ousia (
    --     kodikos         VARCHAR(50)     NOT NULL,
    --     onoma           VARCHAR(300)    NOT NULL,
    --     PRIMARY KEY (kodikos)
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 26. ΦΑΡΜΑΚΟ_ΔΡΑΣΤΙΚΗ  (M:N junction)
    -- -- ============================================================
    -- CREATE TABLE farmako_drastiki (
    --     kod_ema         VARCHAR(50)     NOT NULL,
    --     kod_do          VARCHAR(50)     NOT NULL,
    --     PRIMARY KEY (kod_ema, kod_do),
    --     FOREIGN KEY (kod_ema) REFERENCES farmako(kod_ema)
    --         ON DELETE CASCADE ON UPDATE CASCADE,
    --     FOREIGN KEY (kod_do) REFERENCES drastiki_ousia(kodikos)
    --         ON DELETE CASCADE ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 27. ΑΛΛΕΡΓΙΑ  (M:N: asthenis ↔ drastiki_ousia)
    -- -- ============================================================
    -- CREATE TABLE allergy (
    --     amka_astheni    CHAR(11)        NOT NULL,
    --     kod_do          VARCHAR(50)     NOT NULL,
    --     PRIMARY KEY (amka_astheni, kod_do),
    --     FOREIGN KEY (amka_astheni) REFERENCES asthenis(amka)
    --         ON DELETE CASCADE ON UPDATE CASCADE,
    --     FOREIGN KEY (kod_do) REFERENCES drastiki_ousia(kodikos)
    --         ON DELETE CASCADE ON UPDATE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 28. ΣΥΝΤΑΓΟΓΡΑΦΗΣΗ
    -- -- ============================================================
    -- CREATE TABLE syntagografisi (
    --     kod_ema         VARCHAR(50)     NOT NULL,
    --     amka_iatrou     CHAR(11)        NOT NULL,
    --     amka_astheni    CHAR(11)        NOT NULL,
    --     imer_enarksis   DATE            NOT NULL,
    --     dosologia       VARCHAR(200)    NOT NULL,
    --     syxnotita       VARCHAR(100)    NOT NULL,
    --     imer_liksis     DATE            NULL,
    --     PRIMARY KEY (kod_ema, amka_iatrou, amka_astheni, imer_enarksis),
    --     FOREIGN KEY (kod_ema) REFERENCES farmako(kod_ema)
    --         ON DELETE RESTRICT ON UPDATE CASCADE,
    --     FOREIGN KEY (amka_iatrou) REFERENCES iatros(amka)
    --         ON DELETE RESTRICT ON UPDATE CASCADE,
    --     FOREIGN KEY (amka_astheni) REFERENCES asthenis(amka)
    --         ON DELETE RESTRICT ON UPDATE CASCADE,
    --     CHECK (imer_liksis IS NULL OR imer_liksis >= imer_enarksis)
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- ============================================================
    -- -- 29. ΕΙΚΟΝΑ
    -- -- ============================================================
    -- CREATE TABLE eikona (
    --     id_eikonas      INT             NOT NULL AUTO_INCREMENT,
    --     url             VARCHAR(500)    NOT NULL,
    --     perigrafi       TEXT            NULL,
    --     PRIMARY KEY (id_eikonas)
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- -- Junction tables για ΕΙΚΟΝΑ
    -- CREATE TABLE eikona_anthropos (
    --     id_eikonas  INT         NOT NULL,
    --     amka        CHAR(11)    NOT NULL,
    --     PRIMARY KEY (id_eikonas, amka),
    --     FOREIGN KEY (id_eikonas) REFERENCES eikona(id_eikonas) ON DELETE CASCADE,
    --     FOREIGN KEY (amka) REFERENCES anthropos(amka) ON DELETE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- CREATE TABLE eikona_tmima (
    --     id_eikonas      INT             NOT NULL,
    --     onoma_tmimatos  VARCHAR(100)    NOT NULL,
    --     PRIMARY KEY (id_eikonas, onoma_tmimatos),
    --     FOREIGN KEY (id_eikonas) REFERENCES eikona(id_eikonas) ON DELETE CASCADE,
    --     FOREIGN KEY (onoma_tmimatos) REFERENCES tmima(onoma) ON DELETE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- CREATE TABLE eikona_nosileia (
    --     id_eikonas  INT     NOT NULL,
    --     nosileia_id INT     NOT NULL,
    --     PRIMARY KEY (id_eikonas, nosileia_id),
    --     FOREIGN KEY (id_eikonas) REFERENCES eikona(id_eikonas) ON DELETE CASCADE,
    --     FOREIGN KEY (nosileia_id) REFERENCES nosileia(nosileia_id) ON DELETE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- CREATE TABLE eikona_iatrikipraxi (
    --     id_eikonas  INT         NOT NULL,
    --     kodikos     VARCHAR(20) NOT NULL,
    --     PRIMARY KEY (id_eikonas, kodikos),
    --     FOREIGN KEY (id_eikonas) REFERENCES eikona(id_eikonas) ON DELETE CASCADE,
    --     FOREIGN KEY (kodikos) REFERENCES iatrikipraxi(kodikos) ON DELETE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    -- CREATE TABLE eikona_farmako (
    --     id_eikonas  INT         NOT NULL,
    --     kod_ema     VARCHAR(50) NOT NULL,
    --     PRIMARY KEY (id_eikonas, kod_ema),
    --     FOREIGN KEY (id_eikonas) REFERENCES eikona(id_eikonas) ON DELETE CASCADE,
    --     FOREIGN KEY (kod_ema) REFERENCES farmako(kod_ema) ON DELETE CASCADE
    -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
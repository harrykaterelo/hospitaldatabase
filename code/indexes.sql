-- Query 1: Έσοδα ανά τμήμα και ανά έτος με ανάλυση ανά ΚΕΝ
CREATE INDEX idx_nosileia_tmima_eisodos ON nosileia(tmima_id, imerominia_eisodou);

-- Query 2: Ιατροί ανά ειδικότητα με εφημερίες και επεμβάσεις
CREATE INDEX idx_eidikotita ON iatros(eidikotita);
CREATE INDEX idx_efimeria_amka_imerominia ON efimeria_proswpiko(amka_proswpiko, imerominia);

-- Query 3: Ασθενείς με 3+ νοσηλείες στο ίδιο τμήμα
CREATE INDEX idx_nosileia_asthenis_tmima ON nosileia(amka_astheni, tmima_id);

-- Query 5: Νέοι ιατροί (ηλικία < 35) με τις περισσότερες χειρουργικές επεμβάσεις
CREATE INDEX idx_ilikia ON anthropos(ilikia);
CREATE INDEX idx_praxi_katigoria_xeirourgos ON iatrikipraxi(katigoria, amka_kyriou_xeirourgou);

-- Query 8: Προσωπικό τμήματος που ΔΕΝ είναι σε εφημερία σε δεδομένη ημερομηνία
-- Επιταχύνει το NOT EXISTS πάνω στο efimeria_proswpiko (το PK ξεκινάει με tmima).
CREATE INDEX idx_ef_proswpiko_amka_tmima_imer ON efimeria_proswpiko(amka_proswpiko, tmima, imerominia);
-- Φιλτράρισμα ανά typos_proswpikou όταν συνδυάζεται με JOIN στο proswpiko_anikei_se_tmima.
CREATE INDEX idx_proswpiko_typos ON proswpiko(typos_proswpikou);

-- Query 9: Ασθενείς με ίσο αριθμό ημερών νοσηλείας (>15) στο ίδιο έτος
CREATE INDEX idx_nosileia_amka_eisodos_eksodos ON nosileia(amka_astheni, imerominia_eisodou, imerominia_eksodou);

-- Query 10: Συχνότερα ζευγάρια δραστικών ουσιών στην ίδια νοσηλεία
-- Self-join στη syntagografisi πάνω στο (nosileia_id, amka_astheni).
CREATE INDEX idx_syntagografisi_nosileia_astheni ON syntagografisi(nosileia_id, amka_astheni, kod_ema);

-- Query 12: Απαιτούμενο προσωπικό ανά τμήμα/βάρδια/υποκλάση για συγκεκριμένη εβδομάδα
-- Σάρωση εύρους ημερομηνιών χωρίς να γνωρίζουμε εκ των προτέρων το tmima.
CREATE INDEX idx_ef_proswpiko_imer_tmima_vardia ON efimeria_proswpiko(imerominia, tmima, vardia);
-- Lookup ρόλου διοικητικού / βαθμίδας νοσηλευτή κατά την εμφάνιση στις εφημερίες.
CREATE INDEX idx_dioikitiko_rolos ON dioikitiko(rolos);
CREATE INDEX idx_nosileutis_vathmida ON nosileutis(vathmida_nosileuti);

-- Query 14: Κατηγορίες ICD με ίδιο αριθμό εισαγωγών σε διαδοχικά έτη
-- Φιλτράρισμα tipos_diagnosis='Εισοδος' + JOIN στο nosileia με covering index.
CREATE INDEX idx_diagnosi_typos_icd ON diagnosi(tipos_diagnosis, icd, nosileia_id);

-- Query 15: Στατιστικά διαλογής (triage) ανά επίπεδο & παραπομπές ανά τμήμα
CREATE INDEX idx_dialogi_epipedo_oloklirosis ON dialogistoixeiwn(epipedo, wra_oloklirosis);
CREATE INDEX idx_dialogi_apotelesma_epipedo ON dialogistoixeiwn(apotelesma, epipedo);

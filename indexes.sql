-- ============================================================
-- Indexes για τα queries 1-5
-- ============================================================

-- Query 1: Έσοδα ανά τμήμα και ανά έτος με ανάλυση ανά ΚΕΝ
CREATE INDEX idx_nosileia_tmima_eisodos ON nosileia(tmima_id, imerominia_eisodou);

-- Query 2: Ιατροί ανά ειδικότητα με εφημερίες και επεμβάσεις
CREATE INDEX idx_eidikotita ON iatros(eidikotita);
CREATE INDEX idx_efimeria_amka_imerominia ON efimeria_proswpiko(amka_proswpiko, imerominia);

-- Query 3: Ασθενείς με 3+ νοσηλείες στο ίδιο τμήμα
CREATE INDEX idx_nosileia_asthenis_tmima ON nosileia(amka_astheni, tmima_id);

-- Query 4: Μέσος όρος αξιολογήσεων για συγκεκριμένο ιατρό
-- (χρησιμοποιεί ήδη υπάρχοντα FK indexes: exetasi.amka_iatrou, iatrikipraxi.amka_kyriou_xeirourgou)

-- Query 2, 5: φίλτρο κατηγορίας + GROUP BY χειρουργός
CREATE INDEX idx_praxi_katigoria_xeirourgos ON iatrikipraxi(katigoria, amka_kyriou_xeirourgou);

-- Query 5: Νέοι ιατροί (ηλικία < 35) με τις περισσότερες χειρουργικές επεμβάσεις
CREATE INDEX idx_ilikia ON anthropos(ilikia);

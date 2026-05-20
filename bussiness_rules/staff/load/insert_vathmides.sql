-- Seed data για τις βαθμίδες ιατρών (vathmida_iatrou)
-- Πρέπει να εκτελεστεί πριν από οποιοδήποτε insert στον πίνακα iatros,
-- καθώς ο iatros έχει FK → vathmida_iatrou.

SET NAMES utf8mb4;

INSERT INTO vathmida_iatrou
    (vathmida_id, vathmida_onoma, is_supervised, can_supervise,
     can_cover_specialist_shift, requires_senior_in_shift, can_run_department)
VALUES
    (1, 'Ειδικευόμενος', 1,    0, 0, 1, 0),
    (2, 'Διευθυντής',    0,    1, 1, 0, 1),
    (3, 'Επιμελητής Α΄', NULL, 1, 1, 0, 0),
    (4, 'Επιμελητής Β΄', NULL, 1, 0, 0, 0);

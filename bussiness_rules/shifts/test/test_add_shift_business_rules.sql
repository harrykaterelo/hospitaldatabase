/*
  MySQL test file for add_shift / shift_trigger_insert / efimeria_check

  What it tests:
    1. Unknown vardia name is rejected by add_shift
    2. Unknown tmima name is rejected by add_shift
    3. A valid first assignment creates efimeria + efimeria_proswpiko
    4. Monthly max-shift limit is enforced
    5. Minimum rest-hours rule is enforced
    6. Consecutive same-type shift limit is enforced
    7. efimeria_check returns 0 when minimum staff counts are not met
    8. Optional senior-cover rule test, using generated nurse/admin staff

  Assumptions:
    - You already have at least one tmima row.
    - You already have doctors in iatros with vathmida 1 and at least one of 2/3.
    - vardia contains: 'Πρωινή', 'Απογευματινή', 'Νυχτερινή'.
    - add_shift, shift_trigger_insert, and efimeria_check have already been created.

  IMPORTANT: This script uses test dates in year 2099 and deletes its own test rows.
*/

SET NAMES utf8mb4;

DROP TEMPORARY TABLE IF EXISTS test_results;
CREATE TEMPORARY TABLE test_results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(120) NOT NULL,
    expected_error BOOL NOT NULL,
    actual_error BOOL NOT NULL,
    passed BOOL NOT NULL,
    message TEXT NULL
);

DROP PROCEDURE IF EXISTS run_sql_test;
DELIMITER //
CREATE PROCEDURE run_sql_test(
    IN p_test_name VARCHAR(120),
    IN p_sql TEXT,
    IN p_expected_error BOOL
)
BEGIN
    DECLARE v_error BOOL DEFAULT FALSE;
    DECLARE v_message TEXT DEFAULT NULL;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error = TRUE;
        GET DIAGNOSTICS CONDITION 1 v_message = MESSAGE_TEXT;
    END;

    SET @stmt_sql = p_sql;
    PREPARE stmt FROM @stmt_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    INSERT INTO test_results(test_name, expected_error, actual_error, passed, message)
    VALUES (p_test_name, p_expected_error, v_error, p_expected_error = v_error, v_message);
END//
DELIMITER ;

/* -------------------------
   Pick existing base data
   ------------------------- */

SET @test_month_start = DATE('2099-01-01');
SET @test_month_end   = DATE('2099-03-01');

SELECT tmima_id, onoma
INTO @tmima_id, @tmima_name
FROM tmima
ORDER BY tmima_id
LIMIT 1;

SELECT vardia_id INTO @morning_id FROM vardia WHERE vardia_onoma = 'Πρωινή' LIMIT 1;
SELECT vardia_id INTO @afternoon_id FROM vardia WHERE vardia_onoma = 'Απογευματινή' LIMIT 1;
SELECT vardia_id INTO @night_id FROM vardia WHERE vardia_onoma = 'Νυχτερινή' LIMIT 1;

SELECT i.amka
INTO @junior_doc
FROM iatros i
JOIN proswpiko p ON p.amka = i.amka
WHERE i.vathmida = 1
ORDER BY i.amka
LIMIT 1;

SELECT i.amka
INTO @senior_doc
FROM iatros i
JOIN proswpiko p ON p.amka = i.amka
WHERE i.vathmida IN (2, 3)
ORDER BY i.amka
LIMIT 1;

SELECT i.amka
INTO @any_doc
FROM iatros i
JOIN proswpiko p ON p.amka = i.amka
ORDER BY i.amka
LIMIT 1;

/* Hard stop if required seed data is missing. */
DROP PROCEDURE IF EXISTS assert_seed_data;
DELIMITER //
CREATE PROCEDURE assert_seed_data()
BEGIN
    IF @tmima_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No tmima row exists. Add a department before running tests.';
    END IF;
    IF @morning_id IS NULL OR @afternoon_id IS NULL OR @night_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Missing one or more required vardia rows: Πρωινή, Απογευματινή, Νυχτερινή.';
    END IF;
    IF @any_doc IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No doctors exist in iatros/proswpiko. Add at least one doctor before running tests.';
    END IF;
END//
DELIMITER ;
CALL assert_seed_data();

/* -------------------------
   Clean old test data
   ------------------------- */

DELETE FROM efimeria
WHERE imerominia >= @test_month_start
  AND imerominia < @test_month_end;

/* Save + normalize requirements for deterministic tests. */
DROP TEMPORARY TABLE IF EXISTS saved_efimeria_requirements;
CREATE TEMPORARY TABLE saved_efimeria_requirements AS
SELECT * FROM efimeria_requirements;

DELETE FROM efimeria_requirements;
INSERT INTO efimeria_requirements (
    iatros_max_monthly_ef_count,
    nosileutes_max_monthly_ef_count,
    dioikitiko_max_monthly_ef_count,
    iatros_min_count,
    nosileutes_min_count,
    dioikitiko_min_count
) VALUES (2, 20, 25, 3, 6, 2);

/* Make rest/consecutive limits deterministic for the test vardies. */
UPDATE vardia
SET endiamesi_ora_anapausis_hours = 8,  
    epitreptes_sinexomenes_vardies = 2
WHERE vardia_id IN (@morning_id, @afternoon_id, @night_id);

/* -------------------------
   1. Procedure validations
   ------------------------- */

CALL run_sql_test(
    'rejects unknown vardia name',
    CONCAT('CALL add_shift(', QUOTE(@tmima_name), ', ''2099-01-01'', ''ΛάθοςΒάρδια'', ', QUOTE(@any_doc), ')'),
    TRUE
);

CALL run_sql_test(
    'rejects unknown tmima name',
    CONCAT('CALL add_shift(''ΛάθοςΤμήμα'', ''2099-01-01'', ''Πρωινή'', ', QUOTE(@any_doc), ')'),
    TRUE
);

/* -------------------------
   2. Valid insert creates shift
   ------------------------- */

CALL run_sql_test(
    'valid first shift assignment succeeds',
    CONCAT('CALL add_shift(', QUOTE(@tmima_name), ', ''2099-01-01'', ''Πρωινή'', ', QUOTE(@any_doc), ')'),
    FALSE
);

INSERT INTO test_results(test_name, expected_error, actual_error, passed, message)
SELECT
    'valid insert created efimeria parent row',
    FALSE,
    FALSE,
    EXISTS (
        SELECT 1 FROM efimeria
        WHERE tmima = @tmima_id AND imerominia = '2099-01-01' AND vardia = @morning_id
    ),
    NULL;

INSERT INTO test_results(test_name, expected_error, actual_error, passed, message)
SELECT
    'valid insert created efimeria_proswpiko row',
    FALSE,
    FALSE,
    EXISTS (
        SELECT 1 FROM efimeria_proswpiko
        WHERE tmima = @tmima_id AND imerominia = '2099-01-01'
          AND vardia = @morning_id AND amka_proswpiko = @any_doc
    ),
    NULL;

/* -------------------------
   3. Monthly max limit
   Requirements set doctor max = 2.
   The third January assignment for the same doctor should fail.
   ------------------------- */

CALL run_sql_test(
    'monthly limit allows second doctor shift',
    CONCAT('CALL add_shift(', QUOTE(@tmima_name), ', ''2099-01-10'', ''Πρωινή'', ', QUOTE(@any_doc), ')'),
    FALSE
);

CALL run_sql_test(
    'monthly limit rejects third doctor shift',
    CONCAT('CALL add_shift(', QUOTE(@tmima_name), ', ''2099-01-20'', ''Απογευματινή'', ', QUOTE(@any_doc), ')'),
    TRUE
);

/* -------------------------
   4. Minimum rest-hours rule
   Use another doctor if possible; otherwise this may interact with monthly limit.
   ------------------------- */

SELECT i.amka
INTO @rest_doc
FROM iatros i
JOIN proswpiko p ON p.amka = i.amka
WHERE i.amka <> @any_doc
ORDER BY i.amka
LIMIT 1;
SET @rest_doc = COALESCE(@rest_doc, @any_doc);

/* Clean this doctor in January to avoid cross-test interference. */
DELETE ep FROM efimeria_proswpiko ep
WHERE ep.amka_proswpiko = @rest_doc
  AND ep.imerominia >= '2099-01-01'
  AND ep.imerominia <  '2099-02-01';

CALL run_sql_test(
    'rest-hours setup morning shift succeeds',
    CONCAT('CALL add_shift(', QUOTE(@tmima_name), ', ''2099-01-03'', ''Πρωινή'', ', QUOTE(@rest_doc), ')'),
    FALSE
);

CALL run_sql_test(
    'rest-hours rejects too-close afternoon shift',
    CONCAT('CALL add_shift(', QUOTE(@tmima_name), ', ''2099-01-03'', ''Απογευματινή'', ', QUOTE(@rest_doc), ')'),
    TRUE
);

/* -------------------------
   5. Consecutive same-type limit
   Use February to avoid January monthly-limit rows.
   With epitreptes_sinexomenes_vardies = 2, the 3rd same-type shift should fail.
   ------------------------- */

SELECT i.amka
INTO @consecutive_doc
FROM iatros i
JOIN proswpiko p ON p.amka = i.amka
WHERE i.amka NOT IN (@any_doc, @rest_doc)
ORDER BY i.amka
LIMIT 1;
SET @consecutive_doc = COALESCE(@consecutive_doc, @rest_doc, @any_doc);

DELETE ep FROM efimeria_proswpiko ep
WHERE ep.amka_proswpiko = @consecutive_doc
  AND ep.imerominia >= '2099-02-01'
  AND ep.imerominia <  '2099-03-01';

CALL run_sql_test(
    'consecutive setup first same shift succeeds',
    CONCAT('CALL add_shift(', QUOTE(@tmima_name), ', ''2099-02-01'', ''Πρωινή'', ', QUOTE(@consecutive_doc), ')'),
    FALSE
);

CALL run_sql_test(
    'consecutive setup second same shift succeeds',
    CONCAT('CALL add_shift(', QUOTE(@tmima_name), ', ''2099-02-02'', ''Πρωινή'', ', QUOTE(@consecutive_doc), ')'),
    FALSE
);

CALL run_sql_test(
    'consecutive rule rejects third same shift',
    CONCAT('CALL add_shift(', QUOTE(@tmima_name), ', ''2099-02-03'', ''Πρωινή'', ', QUOTE(@consecutive_doc), ')'),
    TRUE
);

/* -------------------------
   6. efimeria_check basic minimum-count test
   With only one doctor assigned, this should be 0.
   ------------------------- */

INSERT INTO test_results(test_name, expected_error, actual_error, passed, message)
SELECT
    'efimeria_check returns 0 when staff minimums are not met',
    FALSE,
    FALSE,
    efimeria_check(@tmima_id, '2099-01-01', @morning_id) = 0,
    CONCAT('efimeria_check returned ', efimeria_check(@tmima_id, '2099-01-01', @morning_id));

/* -------------------------
   7. Optional: make synthetic nurses/admins and enough doctors for a full shift.
      This block lets you test efimeria_check more fully even if your database
      currently only has doctors.

      Note: leave this enabled only after fixing efimeria_check column/table names.
   ------------------------- */

/*
-- Example synthetic staff. AMKAs start with 999 so they are easy to delete.
INSERT IGNORE INTO anthropos(amka, onoma, eponymo, ilikia, email, tilefono) VALUES
('99900000001','Test','Nurse1',30,'n1@test.local','6900000001'),
('99900000002','Test','Nurse2',30,'n2@test.local','6900000002'),
('99900000003','Test','Nurse3',30,'n3@test.local','6900000003'),
('99900000004','Test','Nurse4',30,'n4@test.local','6900000004'),
('99900000005','Test','Nurse5',30,'n5@test.local','6900000005'),
('99900000006','Test','Nurse6',30,'n6@test.local','6900000006'),
('99900000007','Test','Admin1',30,'a1@test.local','6900000007'),
('99900000008','Test','Admin2',30,'a2@test.local','6900000008');

INSERT IGNORE INTO proswpiko(amka, imerominia_proslipsis, typos_proswpikou) VALUES
('99900000001','2098-01-01','nosileutis'),
('99900000002','2098-01-01','nosileutis'),
('99900000003','2098-01-01','nosileutis'),
('99900000004','2098-01-01','nosileutis'),
('99900000005','2098-01-01','nosileutis'),
('99900000006','2098-01-01','nosileutis'),
('99900000007','2098-01-01','dioikitikos'),
('99900000008','2098-01-01','dioikitikos');

-- Insert the support staff directly into the target shift.
INSERT IGNORE INTO efimeria(tmima, imerominia, vardia)
VALUES (@tmima_id, '2099-01-15', @morning_id);

INSERT IGNORE INTO efimeria_proswpiko(tmima, imerominia, vardia, amka_proswpiko)
SELECT @tmima_id, '2099-01-15', @morning_id, amka
FROM proswpiko
WHERE amka BETWEEN '99900000001' AND '99900000008';

-- Add three doctors: one junior requiring senior coverage, and one senior if available.
INSERT IGNORE INTO efimeria_proswpiko(tmima, imerominia, vardia, amka_proswpiko)
VALUES (@tmima_id, '2099-01-15', @morning_id, @junior_doc);

INSERT IGNORE INTO efimeria_proswpiko(tmima, imerominia, vardia, amka_proswpiko)
VALUES (@tmima_id, '2099-01-15', @morning_id, @senior_doc);

-- Add one more existing doctor if present.
INSERT IGNORE INTO efimeria_proswpiko(tmima, imerominia, vardia, amka_proswpiko)
SELECT @tmima_id, '2099-01-15', @morning_id, i.amka
FROM iatros i
WHERE i.amka NOT IN (@junior_doc, @senior_doc)
LIMIT 1;

INSERT INTO test_results(test_name, expected_error, actual_error, passed, message)
SELECT
    'efimeria_check returns 1 when full staffing and senior coverage exist',
    FALSE,
    FALSE,
    efimeria_check(@tmima_id, '2099-01-15', @morning_id) = 1,
    CONCAT('efimeria_check returned ', efimeria_check(@tmima_id, '2099-01-15', @morning_id));
*/

/* -------------------------
   Results
   ------------------------- */

SELECT
    id,
    test_name,
    CASE WHEN passed THEN 'PASS' ELSE 'FAIL' END AS result,
    expected_error,
    actual_error,
    message
FROM test_results
ORDER BY id;

SELECT
    SUM(passed = 1) AS passed_tests,
    SUM(passed = 0) AS failed_tests,
    COUNT(*) AS total_tests
FROM test_results;

/* -------------------------
   Cleanup
   ------------------------- */

DELETE FROM efimeria
WHERE imerominia >= @test_month_start
  AND imerominia < @test_month_end;

DELETE FROM proswpiko WHERE amka LIKE '999%';
DELETE FROM anthropos WHERE amka LIKE '999%';

DELETE FROM efimeria_requirements;
INSERT INTO efimeria_requirements SELECT * FROM saved_efimeria_requirements;

DROP PROCEDURE IF EXISTS run_sql_test;
DROP PROCEDURE IF EXISTS assert_seed_data;

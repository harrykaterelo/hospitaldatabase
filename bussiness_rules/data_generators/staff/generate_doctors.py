#!/usr/bin/env python3
"""
generate_doctors.py
===================
Generates SQL INSERT statements (via stored procedure calls) for ~570 doctors
across 20 departments, following the staff_generation_rules document.

Rules implemented
-----------------
* Total target: 570 doctors (safe mid-point of 550-600).
* Vathmida distribution per department (20 departments):
    - 1 Διευθυντής  (vathmida_id=2)  per dept  →  20 total
    - 25% Ειδικευόμενοι (vathmida_id=1)           →  ~143 total
    - Επιμελητής Α΄  (vathmida_id=3): fills gap   →  calculated
    - Επιμελητής Β΄  (vathmida_id=4): remainder
* Supervision:
    - Ειδικευόμενοι  (is_supervised=1) → ALWAYS have a supervisor.
      Supervisor must have can_supervise=1 (vathmida 2, 3, or 4 — but only
      2 and 3 are confirmed can_supervise=1 from the schema; Επιμελητής Β΄
      is also can_supervise=1 per the table).
    - Διευθυντές (is_supervised=0) → NEVER have a supervisor.
    - Επιμελητής Α΄ / Β΄ (is_supervised=NULL) → no supervisor assigned here
      (NULL is safe for the trigger).
* Department assignment:
    - Not stored in add_doctor; a separate temp-table script handles it.
* AMKA: 11-digit, unique.
* ar_ad_is: medical licence number, unique.
"""

import random
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from bussiness_rules.data_generators.staff.shared_data import (
    gen_amka, gen_email, gen_phone, gen_date, gen_age,
    pick_gender_name, sql_str, EIDIKOTITES,
)

random.seed(42)

# ── Config ────────────────────────────────────────────────────────────────────

NUM_DEPARTMENTS = 20
TARGET_TOTAL   = 570

# Exact one Διευθυντής per dept
NUM_DIRECTORS = NUM_DEPARTMENTS                                # 20

# 25% Ειδικευόμενοι
NUM_EIDIKEVOMENOI = round(TARGET_TOTAL * 0.25)                 # 142-143

# Remaining split: more Επιμελητής Α΄ than Β΄ (Α΄ fills the "at least" rule)
REMAINING = TARGET_TOTAL - NUM_DIRECTORS - NUM_EIDIKEVOMENOI
NUM_EPIM_A = round(REMAINING * 0.55)
NUM_EPIM_B = REMAINING - NUM_EPIM_A

# vathmida_id constants
VATHMIDA_EIDIKEVOMENOS = 1
VATHMIDA_DIRECTOR      = 2
VATHMIDA_EPIM_A        = 3
VATHMIDA_EPIM_B        = 4

# ── Licence number generator ──────────────────────────────────────────────────

_used_ar_ad = set()

def gen_ar_ad_is() -> str:
    while True:
        n = f"ΙΑΤ{random.randint(100000, 999999)}"
        if n not in _used_ar_ad:
            _used_ar_ad.add(n)
            return n

# ── Doctor record dataclass (plain dict) ─────────────────────────────────────

def make_doctor(vathmida_id: int,
                eidikotita: str,
                amka_epoptis: str | None,
                typos: str = "Ιατρός") -> dict:
    _, onoma, eponymo = pick_gender_name()
    return {
        "amka":                 gen_amka(),
        "onoma":                onoma,
        "eponymo":              eponymo,
        "ilikia":               gen_age(28, 65),
        "email":                gen_email(onoma, eponymo),
        "tilefono":             gen_phone(),
        "imerominia_proslipsis":gen_date(2005, 2025),
        "typos_proswpikou":     typos,
        "ar_ad_is":             gen_ar_ad_is(),
        "eidikotita":           eidikotita,
        "vathmida_id":          vathmida_id,
        "amka_epoptis":         amka_epoptis,
    }

# ── Generation logic ──────────────────────────────────────────────────────────

def generate_doctors() -> list[dict]:
    doctors: list[dict] = []

    # 1. Διευθυντές — no supervisor
    directors: list[dict] = []
    for _ in range(NUM_DIRECTORS):
        d = make_doctor(VATHMIDA_DIRECTOR, random.choice(EIDIKOTITES), None)
        directors.append(d)
        doctors.append(d)

    # 2. Επιμελητές Α΄ — can supervise, no supervisor (is_supervised=NULL → omit)
    epim_a_list: list[dict] = []
    for _ in range(NUM_EPIM_A):
        d = make_doctor(VATHMIDA_EPIM_A, random.choice(EIDIKOTITES), None)
        epim_a_list.append(d)
        doctors.append(d)

    # 3. Επιμελητές Β΄ — can supervise, no supervisor (is_supervised=NULL → omit)
    epim_b_list: list[dict] = []
    for _ in range(NUM_EPIM_B):
        d = make_doctor(VATHMIDA_EPIM_B, random.choice(EIDIKOTITES), None)
        epim_b_list.append(d)
        doctors.append(d)

    # Eligible supervisors: vathmida 2 (can_supervise=1), 3 (can_supervise=1), 4 (can_supervise=1)
    eligible_supervisors = (
        [d["amka"] for d in directors] +
        [d["amka"] for d in epim_a_list] +
        [d["amka"] for d in epim_b_list]
    )

    # 4. Ειδικευόμενοι — MUST have a supervisor from the eligible list
    for _ in range(NUM_EIDIKEVOMENOI):
        supervisor_amka = random.choice(eligible_supervisors)
        d = make_doctor(VATHMIDA_EIDIKEVOMENOS, random.choice(EIDIKOTITES), supervisor_amka)
        doctors.append(d)

    return doctors


def doctor_to_call(d: dict) -> str:
    """Render a CALL add_doctor(...) statement."""
    epoptis = sql_str(d["amka_epoptis"])
    lines = [
        "CALL add_doctor(",
        f"    {sql_str(d['amka'])},",
        f"    {sql_str(d['onoma'])},",
        f"    {sql_str(d['eponymo'])},",
        f"    {d['ilikia']},",
        f"    {sql_str(d['email'])},",
        f"    {sql_str(d['tilefono'])},",
        f"    {sql_str(d['imerominia_proslipsis'])},",
        f"    {sql_str(d['typos_proswpikou'])},",
        f"    {sql_str(d['ar_ad_is'])},",
        f"    {sql_str(d['eidikotita'])},",
        f"    {d['vathmida_id']},",
        f"    {epoptis}",
        ");",
    ]
    return "\n".join(lines)


# ── Dept-assignment temp table (distribution: 0.5 one dept, 0.4 two, 0.1 three) ──

def gen_dept_temp_table(doctors: list[dict]) -> str:
    lines = [
        "-- Temporary doctor-department mapping",
        "-- Distribution: 50% → 1 dept, 40% → 2 depts, 10% → 3 depts",
        "-- Import this yourself into proswpiko_anikei_se_tmima or a staging table.",
        "",
        "DROP TEMPORARY TABLE IF EXISTS tmp_doctor_dept;",
        "CREATE TEMPORARY TABLE tmp_doctor_dept (",
        "    doctor_amka  CHAR(11)    NOT NULL,",
        "    tmima_id     INT         NOT NULL",
        ");",
        "",
        "INSERT INTO tmp_doctor_dept (doctor_amka, tmima_id) VALUES",
    ]

    value_rows = []
    for d in doctors:
        r = random.random()
        if r < 0.5:
            n_depts = 1
        elif r < 0.9:
            n_depts = 2
        else:
            n_depts = 3

        depts = random.sample(range(1, NUM_DEPARTMENTS + 1), n_depts)
        for dept in depts:
            value_rows.append(f"    ({sql_str(d['amka'])}, {dept})")

    lines.append(",\n".join(value_rows) + ";")
    return "\n".join(lines)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    output_dir = os.path.dirname(__file__)
    doctors = generate_doctors()

    print(f"Generated {len(doctors)} doctors:")
    counts = {}
    for d in doctors:
        counts[d["vathmida_id"]] = counts.get(d["vathmida_id"], 0) + 1
    labels = {1: "Ειδικευόμενος", 2: "Διευθυντής", 3: "Επιμελητής Α΄", 4: "Επιμελητής Β΄"}
    for vid, cnt in sorted(counts.items()):
        print(f"  vathmida_id={vid} ({labels[vid]}): {cnt}")

    # ── SQL file 1: insert doctors ────────────────────────────────────────────
    sql_path = os.path.join(output_dir, "insert_doctors.sql")
    with open(sql_path, "w", encoding="utf-8") as f:
        f.write("-- AUTO-GENERATED: insert_doctors.sql\n")
        f.write("-- Doctors are inserted ordered by vathmida so supervisors exist before supervisees.\n")
        f.write("-- Order: Διευθυντές → Επιμελητές Α΄ → Επιμελητές Β΄ → Ειδικευόμενοι\n\n")
        f.write("SET NAMES utf8mb4;\n\n")

        # Sort: supervisors first
        order = {2: 0, 3: 1, 4: 2, 1: 3}
        sorted_docs = sorted(doctors, key=lambda d: order[d["vathmida_id"]])

        for d in sorted_docs:
            f.write(doctor_to_call(d))
            f.write("\n\n")

    print(f"\nSQL written to: {sql_path}")

    # ── SQL file 2: temp dept table ───────────────────────────────────────────
    dept_path = os.path.join(output_dir, "tmp_doctor_dept.sql")
    with open(dept_path, "w", encoding="utf-8") as f:
        f.write("-- AUTO-GENERATED: tmp_doctor_dept.sql\n")
        f.write("-- Run in your session; import tmp_doctor_dept into your real table yourself.\n\n")
        f.write("SET NAMES utf8mb4;\n\n")
        f.write(gen_dept_temp_table(doctors))
        f.write("\n\n")
        f.write("-- Preview:\n")
        f.write("SELECT * FROM tmp_doctor_dept LIMIT 20;\n")

    print(f"Dept mapping written to: {dept_path}")


if __name__ == "__main__":
    main()

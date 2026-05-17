#!/usr/bin/env python3
"""
generate_doctors.py
===================
Generates SQL INSERT statements for 570 doctors across 20 departments.

Main idea
---------
Instead of generating doctors globally and assigning departments randomly,
this script generates a balanced doctor pool per department.

Per-department distribution:
    Departments 1–10:
        1  Διευθυντής
        8  Επιμελητές Α΄
        12 Επιμελητές Β΄
        8  Ειδικευόμενοι
        = 29 doctors

    Departments 11–20:
        1  Διευθυντής
        8  Επιμελητές Α΄
        11 Επιμελητές Β΄
        8  Ειδικευόμενοι
        = 28 doctors

Total:
    10 * 29 + 10 * 28 = 570 doctors

Why this is better for rotation
-------------------------------
Each department gets:
    - exactly 1 Διευθυντής
    - 9 senior doctors total, counting Διευθυντής + Επιμελητές Α΄
    - 11–12 Επιμελητές Β΄
    - 8 Ειδικευόμενοι

This avoids departments randomly ending up with too few seniors.
"""

import random
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

from shared_data import (
    gen_amka,
    gen_email,
    gen_phone,
    gen_date,
    gen_age,
    pick_gender_name,
    sql_str,
    Role,
    EIDIKOTITES,
)

random.seed(42)

# ── Config ────────────────────────────────────────────────────────────────────

NUM_DEPARTMENTS = 20

# Per-department targets
DIRECTORS_PER_DEPT = 1
EPIM_A_PER_DEPT = 8
EPIM_B_PER_DEPT_BASE = 11
EIDIKEVOMENOI_PER_DEPT = 8

# Add +1 Επιμελητής Β΄ to the first 10 departments:
# 10 departments * 29 doctors + 10 departments * 28 doctors = 570 total
EXTRA_EPIM_B_DEPTS = 10

# vathmida_id constants
VATHMIDA_EIDIKEVOMENOS = 1
VATHMIDA_DIRECTOR = 2
VATHMIDA_EPIM_A = 3
VATHMIDA_EPIM_B = 4

VATHMIDA_LABELS = {
    VATHMIDA_EIDIKEVOMENOS: "Ειδικευόμενος",
    VATHMIDA_DIRECTOR: "Διευθυντής",
    VATHMIDA_EPIM_A: "Επιμελητής Α΄",
    VATHMIDA_EPIM_B: "Επιμελητής Β΄",
}

# ── Licence number generator ──────────────────────────────────────────────────

_used_ar_ad = set()


def gen_ar_ad_is() -> str:
    while True:
        n = f"ΙΑΤ{random.randint(100000, 999999)}"
        if n not in _used_ar_ad:
            _used_ar_ad.add(n)
            return n


# ── Doctor generator ──────────────────────────────────────────────────────────

def make_doctor(
    vathmida_id: int,
    eidikotita: str,
    amka_epoptis: str | None,
    typos: str = "Ιατρός",
) -> dict:
    _, onoma, eponymo = pick_gender_name()

    return {
        "amka": gen_amka(Role.DOCTOR),
        "onoma": onoma,
        "eponymo": eponymo,
        "ilikia": gen_age(28, 65),
        "email": gen_email(onoma, eponymo),
        "tilefono": gen_phone(),
        "imerominia_proslipsis": gen_date(2005, 2025),
        "typos_proswpikou": typos,
        "ar_ad_is": gen_ar_ad_is(),
        "eidikotita": eidikotita,
        "vathmida_id": vathmida_id,
        "amka_epoptis": amka_epoptis,
    }


# ── Generation logic ──────────────────────────────────────────────────────────

def generate_doctors() -> tuple[list[dict], list[tuple[str, int]]]:
    """
    Returns:
        doctors:
            list of doctor dictionaries

        doctor_depts:
            list of (doctor_amka, tmima_id) tuples
            used to generate tmp_doctor_dept.sql
    """

    doctors: list[dict] = []
    doctor_depts: list[tuple[str, int]] = []

    for dept_id in range(1, NUM_DEPARTMENTS + 1):
        dept_doctors: list[dict] = []

        # ── 1. One Διευθυντής per department ────────────────────────────────
        for _ in range(DIRECTORS_PER_DEPT):
            d = make_doctor(
                VATHMIDA_DIRECTOR,
                random.choice(EIDIKOTITES),
                None,
            )
            dept_doctors.append(d)

        # ── 2. Επιμελητές Α΄ per department ─────────────────────────────────
        for _ in range(EPIM_A_PER_DEPT):
            d = make_doctor(
                VATHMIDA_EPIM_A,
                random.choice(EIDIKOTITES),
                None,
            )
            dept_doctors.append(d)

        # ── 3. Επιμελητές Β΄ per department ─────────────────────────────────
        epim_b_count = EPIM_B_PER_DEPT_BASE

        if dept_id <= EXTRA_EPIM_B_DEPTS:
            epim_b_count += 1

        for _ in range(epim_b_count):
            d = make_doctor(
                VATHMIDA_EPIM_B,
                random.choice(EIDIKOTITES),
                None,
            )
            dept_doctors.append(d)

        # Supervisors for Ειδικευόμενοι should come from the same department.
        # This keeps supervision realistic and local.
        eligible_supervisors = [
            d["amka"]
            for d in dept_doctors
            if d["vathmida_id"] in {
                VATHMIDA_DIRECTOR,
                VATHMIDA_EPIM_A,
                VATHMIDA_EPIM_B,
            }
        ]

        if not eligible_supervisors:
            raise RuntimeError(
                f"No eligible supervisors found for department {dept_id}"
            )

        # ── 4. Ειδικευόμενοι per department ─────────────────────────────────
        for _ in range(EIDIKEVOMENOI_PER_DEPT):
            supervisor_amka = random.choice(eligible_supervisors)

            d = make_doctor(
                VATHMIDA_EIDIKEVOMENOS,
                random.choice(EIDIKOTITES),
                supervisor_amka,
            )

            dept_doctors.append(d)

        # Add this department's doctors to the global output
        for d in dept_doctors:
            doctors.append(d)
            doctor_depts.append((d["amka"], dept_id))

    return doctors, doctor_depts


# ── SQL rendering ─────────────────────────────────────────────────────────────

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


def gen_dept_temp_table(doctor_depts: list[tuple[str, int]]) -> str:
    """
    Generate a temporary doctor-department mapping table.

    Unlike the previous version, this does NOT randomly assign doctors
    to departments. The mapping was already decided during generation.
    """

    lines = [
        "-- Temporary doctor-department mapping",
        "-- Deterministic per-department distribution for stable shift rotation.",
        "",
        "DROP TEMPORARY TABLE IF EXISTS tmp_doctor_dept;",
        "CREATE TEMPORARY TABLE tmp_doctor_dept (",
        "    doctor_amka  CHAR(11)    NOT NULL,",
        "    tmima_id     INT         NOT NULL",
        ");",
        "",
        "INSERT INTO tmp_doctor_dept (doctor_amka, tmima_id) VALUES",
    ]

    value_rows = [
        f"    ({sql_str(amka)}, {dept_id})"
        for amka, dept_id in doctor_depts
    ]

    lines.append(",\n".join(value_rows) + ";")

    return "\n".join(lines)


# ── Validation helpers ────────────────────────────────────────────────────────

def print_global_counts(doctors: list[dict]) -> None:
    print(f"Generated {len(doctors)} doctors:")

    counts = {}

    for d in doctors:
        vid = d["vathmida_id"]
        counts[vid] = counts.get(vid, 0) + 1

    for vid in sorted(counts):
        label = VATHMIDA_LABELS[vid]
        print(f"  vathmida_id={vid} ({label}): {counts[vid]}")


def print_department_counts(
    doctors: list[dict],
    doctor_depts: list[tuple[str, int]],
) -> None:
    amka_to_doctor = {
        d["amka"]: d
        for d in doctors
    }

    dept_counts: dict[int, dict[int, int]] = {}

    for amka, dept_id in doctor_depts:
        d = amka_to_doctor[amka]
        vid = d["vathmida_id"]

        if dept_id not in dept_counts:
            dept_counts[dept_id] = {}

        dept_counts[dept_id][vid] = dept_counts[dept_id].get(vid, 0) + 1

    print("\nPer-department doctor distribution:")

    for dept_id in sorted(dept_counts):
        counts = dept_counts[dept_id]

        directors = counts.get(VATHMIDA_DIRECTOR, 0)
        epim_a = counts.get(VATHMIDA_EPIM_A, 0)
        epim_b = counts.get(VATHMIDA_EPIM_B, 0)
        eid = counts.get(VATHMIDA_EIDIKEVOMENOS, 0)

        seniors = directors + epim_a
        total = directors + epim_a + epim_b + eid

        print(
            f"  Dept {dept_id:02d}: "
            f"total={total}, "
            f"Διευθυντές={directors}, "
            f"Α΄={epim_a}, "
            f"Β΄={epim_b}, "
            f"Ειδικευόμενοι={eid}, "
            f"seniors={seniors}"
        )


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    output_dir = os.path.dirname(__file__)

    doctors, doctor_depts = generate_doctors()

    print_global_counts(doctors)
    print_department_counts(doctors, doctor_depts)

    # ── SQL file 1: insert doctors ───────────────────────────────────────────
    sql_path = os.path.join(output_dir, "insert_doctors.sql")

    with open(sql_path, "w", encoding="utf-8") as f:
        f.write("-- AUTO-GENERATED: insert_doctors.sql\n")
        f.write("-- Doctors are inserted ordered by vathmida so supervisors exist before supervisees.\n")
        f.write("-- Order: Διευθυντές → Επιμελητές Α΄ → Επιμελητές Β΄ → Ειδικευόμενοι\n\n")
        f.write("SET NAMES utf8mb4;\n\n")

        # Supervisors first, Ειδικευόμενοι last
        order = {
            VATHMIDA_DIRECTOR: 0,
            VATHMIDA_EPIM_A: 1,
            VATHMIDA_EPIM_B: 2,
            VATHMIDA_EIDIKEVOMENOS: 3,
        }

        sorted_docs = sorted(
            doctors,
            key=lambda d: order[d["vathmida_id"]],
        )

        for d in sorted_docs:
            f.write(doctor_to_call(d))
            f.write("\n\n")

    print(f"\nSQL written to: {sql_path}")

    # ── SQL file 2: department mapping ───────────────────────────────────────
    dept_path = os.path.join(output_dir, "tmp_doctor_dept.sql")

    with open(dept_path, "w", encoding="utf-8") as f:
        f.write("-- AUTO-GENERATED: tmp_doctor_dept.sql\n")
        f.write("-- Run in your session; import tmp_doctor_dept into your real table yourself.\n\n")
        f.write("SET NAMES utf8mb4;\n\n")
        f.write(gen_dept_temp_table(doctor_depts))
        f.write("\n\n")
        f.write("-- Preview:\n")
        f.write("SELECT * FROM tmp_doctor_dept LIMIT 20;\n\n")
        f.write("-- Per-department counts:\n")
        f.write("SELECT tmima_id, COUNT(*) AS doctors_in_dept\n")
        f.write("FROM tmp_doctor_dept\n")
        f.write("GROUP BY tmima_id\n")
        f.write("ORDER BY tmima_id;\n")

    print(f"Dept mapping written to: {dept_path}")


if __name__ == "__main__":
    main()
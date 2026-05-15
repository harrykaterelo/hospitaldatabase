#!/usr/bin/env python3
"""
generate_nurses.py
==================
Generates SQL INSERT statements (via stored procedure calls) for ~640 nurses
across 20 regular departments, following staff_generation_rules.

Rules implemented
-----------------
* 31 nurses per regular department × 20 = 620 base.
* Safety buffer to ~640 (≈ 1.03× — document says 640×1.2=700 as safe).
  We generate 640 here (mid-safe), skipping the Emergency Dept which is
  handled separately (shift-based, noted in rules).
* vathmida_nosileuti distribution (from document ratios):
    - ΤΕ Νοσηλευτής                  50%
    - ΠΕ Νοσηλευτής                  30%
    - ΔΕ Νοσηλευτικής Βοήθειας       20%
* Each nurse is assigned to exactly one department (tmima_id 1-20),
  distributed as evenly as possible (round-robin then shuffle).
* typos_proswpikou is hard-coded to 'Νοσηλευτής' inside the procedure;
  the procedure does not accept it as a parameter.
"""

import random
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from bussiness_rules.data_generators.staff.shared_data import (
    gen_amka, gen_email, gen_phone, gen_date, gen_age,
    pick_gender_name, sql_str,Role,
    VATHMIDES_NOSILEUTI, VATHMIDA_NOSILEUTI_WEIGHTS,
)

random.seed(123)

# ── Config ────────────────────────────────────────────────────────────────────

NUM_DEPARTMENTS = 20
# 31 nurses per dept = 620 base; we target 640 (round up for safety)
# Emergency dept is excluded — shift-based, handled separately.
TARGET_TOTAL = 640

# ── Generation logic ──────────────────────────────────────────────────────────

def pick_vathmida() -> str:
    return random.choices(VATHMIDES_NOSILEUTI, weights=VATHMIDA_NOSILEUTI_WEIGHTS, k=1)[0]


def make_nurse(tmima_id: int) -> dict:
    _, onoma, eponymo = pick_gender_name()
    return {
        "amka":                  gen_amka(Role.NURSE),
        "onoma":                 onoma,
        "eponymo":               eponymo,
        "ilikia":                gen_age(22, 60),
        "email":                 gen_email(onoma, eponymo),
        "tilefono":              gen_phone(),
        "imerominia_proslipsis": gen_date(2000, 2025),
        "vathmida_nosileuti":    pick_vathmida(),
        "tmima_id":              tmima_id,
    }


def generate_nurses() -> list[dict]:
    # Build a department list with even distribution then shuffle
    base_per_dept = TARGET_TOTAL // NUM_DEPARTMENTS       # 32
    remainder     = TARGET_TOTAL % NUM_DEPARTMENTS        # 0

    dept_list: list[int] = []
    for dept_id in range(1, NUM_DEPARTMENTS + 1):
        count = base_per_dept + (1 if dept_id <= remainder else 0)
        dept_list.extend([dept_id] * count)

    random.shuffle(dept_list)

    nurses = [make_nurse(dept_id) for dept_id in dept_list]
    return nurses


def nurse_to_call(n: dict) -> str:
    """Render a CALL add_nosileutis(...) statement."""
    lines = [
        "CALL add_nosileutis(",
        f"    {sql_str(n['amka'])},",
        f"    {sql_str(n['onoma'])},",
        f"    {sql_str(n['eponymo'])},",
        f"    {n['ilikia']},",
        f"    {sql_str(n['email'])},",
        f"    {sql_str(n['tilefono'])},",
        f"    {sql_str(n['imerominia_proslipsis'])},",
        f"    {sql_str(n['vathmida_nosileuti'])},",
        f"    {n['tmima_id']}",
        ");",
    ]
    return "\n".join(lines)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    output_dir = os.path.dirname(__file__)
    nurses = generate_nurses()

    print(f"Generated {len(nurses)} nurses across {NUM_DEPARTMENTS} departments.")

    # vathmida distribution summary
    dist: dict[str, int] = {}
    for n in nurses:
        dist[n["vathmida_nosileuti"]] = dist.get(n["vathmida_nosileuti"], 0) + 1
    for vat, cnt in dist.items():
        pct = cnt / len(nurses) * 100
        print(f"  {vat}: {cnt}  ({pct:.1f}%)")

    # dept distribution summary
    dept_dist: dict[int, int] = {}
    for n in nurses:
        dept_dist[n["tmima_id"]] = dept_dist.get(n["tmima_id"], 0) + 1
    print(f"  Depts covered: {sorted(dept_dist.keys())}")
    print(f"  Nurses per dept — min: {min(dept_dist.values())}, max: {max(dept_dist.values())}")

    sql_path = os.path.join(output_dir, "insert_nurses.sql")
    with open(sql_path, "w", encoding="utf-8") as f:
        f.write("-- AUTO-GENERATED: insert_nurses.sql\n")
        f.write(f"-- {len(nurses)} nurses across {NUM_DEPARTMENTS} regular departments.\n")
        f.write("-- Emergency department nurses are handled separately (shift-based).\n\n")
        f.write("SET NAMES utf8mb4;\n\n")
        for n in nurses:
            f.write(nurse_to_call(n))
            f.write("\n\n")

    print(f"\nSQL written to: {sql_path}")


if __name__ == "__main__":
    main()

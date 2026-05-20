#!/usr/bin/env python3
"""
generate_admin.py
=================
Generates SQL INSERT statements (via stored procedure calls) for administrative
(Διοικητικό) staff following the hospital schema.

Rules / assumptions (staff_generation_rules + schema)
-----------------------------------------------------
* The rules document focuses on doctors and nurses; admin sizing is derived
  from common hospital ratios: ~2-3 admin per department.
* We generate 3 admin staff per department × 20 departments = 60 total, a
  reasonable operational baseline.
* Each admin belongs to exactly one department (tmima_id 1-20) via the
  proswpiko_anikei_se_tmima table — this is handled inside add_dioikitiko.
* grafeio: office label, e.g. "Α1", "Β2" etc.
* rolos: drawn from a realistic pool of admin roles.
* typos_proswpikou is hard-coded to 'Διοικητικό' inside the procedure.
"""

import random
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from bussiness_rules.data_generators.staff.shared_data import (
    gen_amka, gen_email, gen_phone, gen_date, gen_age,
    pick_gender_name, sql_str,Role,
    ADMIN_ROLES, GRAFEIO_PREFIXES,
)

random.seed(77)

# ── Config ────────────────────────────────────────────────────────────────────

NUM_DEPARTMENTS   = 20
ADMIN_PER_DEPT    = 12         # 3 × 20 = 60 total

# ── Generation logic ──────────────────────────────────────────────────────────

def gen_grafeio(dept_id: int) -> str:
    """E.g. 'Α3', 'Γ1' — deterministic to dept, random letter."""
    letter = random.choice(GRAFEIO_PREFIXES)
    number = random.randint(1, 9)
    return f"{letter}{number}"


def make_admin(tmima_id: int) -> dict:
    _, onoma, eponymo = pick_gender_name()
    return {
        "amka":                  gen_amka(Role.ADMIN),
        "onoma":                 onoma,
        "eponymo":               eponymo,
        "ilikia":                gen_age(22, 62),
        "email":                 gen_email(onoma, eponymo),
        "tilefono":              gen_phone(),
        "imerominia_proslipsis": gen_date(2000, 2025),
        "rolos":                 random.choice(ADMIN_ROLES),
        "grafeio":               gen_grafeio(tmima_id),
        "tmima_id":              tmima_id,
    }


def generate_admin_staff() -> list[dict]:
    staff = []
    for dept_id in range(1, NUM_DEPARTMENTS + 1):
        for _ in range(ADMIN_PER_DEPT):
            staff.append(make_admin(dept_id))
    return staff


def admin_to_call(a: dict) -> str:
    """Render a CALL add_dioikitiko(...) statement."""
    lines = [
        "CALL add_dioikitiko(",
        f"    {sql_str(a['amka'])},",
        f"    {sql_str(a['onoma'])},",
        f"    {sql_str(a['eponymo'])},",
        f"    {a['ilikia']},",
        f"    {sql_str(a['email'])},",
        f"    {sql_str(a['tilefono'])},",
        f"    {sql_str(a['imerominia_proslipsis'])},",
        f"    {sql_str(a['rolos'])},",
        f"    {sql_str(a['grafeio'])},",
        f"    {a['tmima_id']}",
        ");",
    ]
    return "\n".join(lines)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    output_dir = os.path.dirname(__file__)
    staff = generate_admin_staff()

    print(f"Generated {len(staff)} administrative staff ({ADMIN_PER_DEPT} per dept × {NUM_DEPARTMENTS} depts).")

    role_dist: dict[str, int] = {}
    for a in staff:
        role_dist[a["rolos"]] = role_dist.get(a["rolos"], 0) + 1
    print("  Role distribution:")
    for role, cnt in sorted(role_dist.items(), key=lambda x: -x[1]):
        print(f"    {role}: {cnt}")

    sql_path = os.path.join(output_dir, "insert_admin.sql")
    with open(sql_path, "w", encoding="utf-8") as f:
        f.write("-- AUTO-GENERATED: insert_admin.sql\n")
        f.write(f"-- {len(staff)} administrative staff across {NUM_DEPARTMENTS} departments.\n\n")
        f.write("SET NAMES utf8mb4;\n\n")
        for a in staff:
            f.write(admin_to_call(a))
            f.write("\n\n")

    print(f"\nSQL written to: {sql_path}")


if __name__ == "__main__":
    main()

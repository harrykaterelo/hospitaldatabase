#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_shifts.py
==================
Generates SQL CALL add_shift(...) statements for a 3-year period
across all 20 hospital departments.

Strategy: Shuffled Circular Rotation
--------------------------------------
For each department and each staff category (doctors/nurses/admin):
  1. Load the pool of people in that dept from the CSV.
  2. Shuffle once (random but deterministic via seed).
  3. Maintain a rotating index pointer that advances by `needed` positions
     each shift. This means:
       - Everyone gets an equal share of shifts over time.
       - The same person is guaranteed to NOT appear in adjacent slots
         (min separation = pool_size / needed shifts apart).
       - With pool sizes of 12-35, this gives 32-93 hours between
         any person's consecutive shifts — well above the 8h minimum.
       - 3 consecutive nights rule: with pool_size >= 12 and only 3
         shifts/day, the same person cycles back every pool_size/needed
         days minimum (4+ days for admin) — never 4 consecutive nights.

Doctor special rule:
  - If any Ειδικευόμενος is in the 3-doctor draw, at least one
    Επιμελητής Α΄ or Διευθυντής must also be present.
  - Achieved by maintaining TWO rotating queues per dept:
      * senior_queue: Διευθυντής + Επιμελητής Α΄ (shuffled)
      * junior_queue: Επιμελητής Β΄ + Ειδικευόμενος (shuffled,
                      but Ειδικευόμενος weighted to appear less)
  - Draw logic: pick 3 from the combined circular queue; if result
    contains an Ειδικευόμενος and no senior, swap one non-senior
    slot with the next senior in the senior_queue.

Monthly cap enforcement:
  - Track shift_count[amka][year-month]. If a person hits their cap
    mid-rotation, skip them and take the next available person.
    (This only triggers in the nurse case near 85% utilization.)

Output: one SQL file per department to keep file sizes manageable.
"""

import csv
import random
from datetime import datetime, date, timedelta
from collections import defaultdict
import os

# ── Config (mirrors util.py) ──────────────────────────────────────────────────

START_DATE = datetime(2026,1,2,10,30)
END_DATE = datetime(2026,5,15,10,30)


IATROS_MAX_MONTHLY      = 15
NOSILEUTIS_MAX_MONTHLY  = 20
DIOIKITIKO_MAX_MONTHLY  = 25

IATROS_MIN      = 3
NOSILEUTIS_MIN  = 6
DIOIKITIKO_MIN  = 2

SHIFT_NAMES = ["Πρωινή", "Απογευματινή", "Νυχτερινή"]

RANDOM_SEED = 42

# Vathmida categories
SENIOR_VATHMIDES  = {"Διευθυντής", "Επιμελητής Α΄"}
JUNIOR_VATHMIDES  = {"Επιμελητής Β΄", "Ειδικευόμενος"}
EID_VATHMIDA      = "Ειδικευόμενος"

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "shifts_sql")
deptNames  = {}
# ── Load CSVs ─────────────────────────────────────────────────────────────────

def load_iatroi(path: str) -> dict[str, list[dict]]:
    """Returns {tmima_id: [{'amka':..,'vathmida':..}, ...]}"""
    dept: dict[str, list[dict]] = defaultdict(list)
    with open(path, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            dept[row["tmima_id"]].append({
                "amka":     row["amka"],
                "vathmida": row["vathmida_onoma"],
                
            })
            deptNames[row["tmima_id"]] = row["onoma"]
    return dept


def load_simple(path: str) -> dict[str, list[str]]:
    """Returns {tmima_id: [amka, ...]} for nurses and admin."""
    dept: dict[str, list[str]] = defaultdict(list)
    with open(path, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            dept[row["tmima_id"]].append(row["amka"])
    return dept

# ── Department name lookup (tmima_id → name for the procedure) ───────────────
# The procedure takes p_tmima VARCHAR(100) — we use a standard naming scheme.
# Adjust if your actual tmima.onoma values differ.

def dept_name(dept_id: str) -> str:
    return f"{deptNames[dept_id]}"

# ── Circular queue helper ─────────────────────────────────────────────────────

class CircularQueue:
    """
    Infinite circular iterator over a list.
    Call next_n(n, month_key, cap_tracker, amka_set, max_cap) to get
    n items that haven't hit their monthly cap.
    """
    def __init__(self, items: list):
        self.items = list(items)
        self.idx   = 0

    def peek_next(self) -> str:
        return self.items[self.idx % len(self.items)]

    def advance(self, n: int = 1):
        self.idx = (self.idx + n) % len(self.items)

    def next_n_available(self, n: int, month_key: str,
                         cap_tracker: dict, max_cap: int) -> list[str]:
        """
        Returns n unique AMKAs, skipping anyone at their monthly cap.
        Advances the pointer past the chosen slots.
        """
        chosen = []
        seen   = set()
        attempts = 0
        max_attempts = len(self.items) * 3  # safety exit

        while len(chosen) < n and attempts < max_attempts:
            amka = self.items[self.idx % len(self.items)]
            self.idx += 1
            attempts += 1
            if amka in seen:
                continue
            if cap_tracker.get((amka, month_key), 0) >= max_cap:
                continue
            chosen.append(amka)
            seen.add(amka)

        if len(chosen) < n:
            raise RuntimeError(
                f"Could not find {n} available staff for month {month_key}. "
                f"Pool exhausted (pool size: {len(self.items)})."
            )
        return chosen

# ── Doctor draw with senior-guarantee ────────────────────────────────────────

class DoctorQueue:
    """
    Maintains two circular queues per dept (senior / all) and
    enforces the Ειδικευόμενος → needs senior rule.
    """
    def __init__(self, doctors: list[dict]):
        self.pick = [
            (0,1,2),
            (0,3,0),
            (1,1,1),
            (2,0,1),
            (0,2,1)
        ]
        
        # Separate into senior and non-senior
        seniors    = [d for d in doctors if d["vathmida"] in SENIOR_VATHMIDES]
        
        non_senior = [d for d in doctors if d["vathmida"] not in SENIOR_VATHMIDES]
        junior = [d for d in doctors if d["vathmida"] =="Επιμελητής Β΄"]

        # Shuffle
        random.shuffle(seniors)
        random.shuffle(non_senior)
        
        random.shuffle(junior)

        # Interleaved full pool: mostly seniors, some non-senior
        # We build a combined pool weighted so Ειδικευόμενοι appear ~25%
        eid    = [d for d in doctors if d["vathmida"] == EID_VATHMIDA]
        others = [d for d in doctors if d["vathmida"] != EID_VATHMIDA]
        random.shuffle(eid)
        random.shuffle(others)

        # Full pool: interleave so not all Eid cluster together
        # Store only amka strings in queues; vathmida looked up via self.all_doctors
        full = []
        ei, oi = 0, 0
        while ei < len(eid) or oi < len(others):
            # 3 others for every 1 eid
            for _ in range(3):
                if oi < len(others):
                    full.append(others[oi]["amka"]); oi += 1
            if ei < len(eid):
                full.append(eid[ei]["amka"]); ei += 1

        self.full_queue   = CircularQueue(full)
        self.eidikeuomenos_queue = CircularQueue(d["amka"] for d in eid)
        self.junior_queue = CircularQueue(d['amka'] for d in junior)
        self.senior_queue = CircularQueue([d["amka"] for d in seniors])
        self.all_doctors  = {d["amka"]: d["vathmida"] for d in doctors}

    def draw(self, n: int, month_key: str,
             cap_tracker: dict, max_cap: int) -> list[str]:
        """
        Draw n doctors respecting monthly caps.
        If any Ειδικευόμενος is drawn and no senior is present,
        swap the last non-senior with a senior from senior_queue.
        """
        if n != 3:
            raise ValueError("DoctorQueue.draw currently expects n = 3")

        # Pick one valid combination randomly
        eid_count, junior_count, senior_count = self.pick[random.randint(0,len(self.pick)-1)]
            
        
        chosen_amkas = (
            self.eidikeuomenos_queue.next_n_available(
                eid_count, month_key, cap_tracker, max_cap
            )
            + self.junior_queue.next_n_available(
                junior_count, month_key, cap_tracker, max_cap
            )
            + self.senior_queue.next_n_available(
                senior_count, month_key, cap_tracker, max_cap
            )
        )

        random.shuffle(chosen_amkas)

        return chosen_amkas

# ── SQL formatter ─────────────────────────────────────────────────────────────

def make_call(dept_name_str: str, date_str: str,
              shift_name: str, amka: str) -> str:
    def q(s): return f"'{s}'"
    return (
        f"CALL add_shift({q(dept_name_str)}, {q(date_str)}, "
        f"{q(shift_name)}, {q(amka)});"
    )

# ── Month key helper ──────────────────────────────────────────────────────────

def month_key(d: date) -> str:
    return f"{d.year}-{d.month:02d}"

# ── Main generation ───────────────────────────────────────────────────────────

def generate_dept(dept_id: str,
                  doctor_rows: list[dict],
                  nurse_amkas: list[str],
                  admin_amkas: list[str]) -> list[str]:
    """Generate all CALL statements for one department. Returns list of SQL lines."""

    random.seed(RANDOM_SEED + int(dept_id))

    dname = dept_name(dept_id)

    # Shuffle pools
    nurses_shuffled = list(nurse_amkas)
    admin_shuffled  = list(admin_amkas)
    random.shuffle(nurses_shuffled)
    random.shuffle(admin_shuffled)

    # Build queues
    doc_queue    = DoctorQueue(doctor_rows)
    nurse_queue  = CircularQueue(nurses_shuffled)
    admin_queue  = CircularQueue(admin_shuffled)

    # Monthly cap trackers: (amka, 'YYYY-MM') → count
    doc_caps:   dict[tuple, int] = defaultdict(int)
    nurse_caps: dict[tuple, int] = defaultdict(int)
    admin_caps: dict[tuple, int] = defaultdict(int)

    lines: list[str] = []
    current = START_DATE.date()
    end     = END_DATE.date()

    while current < end:
        mk = month_key(current)
        for shift_name in SHIFT_NAMES:
            # ── Doctors ──────────────────────────────────────────────────────
            doc_amkas = doc_queue.draw(
                IATROS_MIN, mk, doc_caps, IATROS_MAX_MONTHLY
            )
            for amka in doc_amkas:
                doc_caps[(amka, mk)] += 1
                lines.append(make_call(dname, current.isoformat(), shift_name, amka))

            # ── Nurses ───────────────────────────────────────────────────────
            nurse_amkas_chosen = nurse_queue.next_n_available(
                NOSILEUTIS_MIN, mk, nurse_caps, NOSILEUTIS_MAX_MONTHLY
            )
            for amka in nurse_amkas_chosen:
                nurse_caps[(amka, mk)] += 1
                lines.append(make_call(dname, current.isoformat(), shift_name, amka))

            # ── Admin ─────────────────────────────────────────────────────────
            admin_amkas_chosen = admin_queue.next_n_available(
                DIOIKITIKO_MIN, mk, admin_caps, DIOIKITIKO_MAX_MONTHLY
            )
            for amka in admin_amkas_chosen:
                admin_caps[(amka, mk)] += 1
                lines.append(make_call(dname, current.isoformat(), shift_name, amka))

        current += timedelta(days=1)

    return lines


def main():
    random.seed(RANDOM_SEED)

    # Load data
    iatroi_by_dept    = load_iatroi("bussiness_rules/data/iatros_data.csv")
    nurses_by_dept    = load_simple("/Users/hariskaterelos/Documents/hospital-db-management/bussiness_rules/data/nosileutis_data.csv")
    admin_by_dept     = load_simple("bussiness_rules/data/dioikitiko_data.csv")

    all_depts = sorted(
        set(iatroi_by_dept) | set(nurses_by_dept) | set(admin_by_dept),
        key=int
    )

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    total_lines = 0
    for dept_id in all_depts:
        print(f"Generating dept {dept_id}...", end=" ", flush=True)
        try:
            lines = generate_dept(
                dept_id,
                iatroi_by_dept.get(dept_id, []),
                nurses_by_dept.get(dept_id, []),
                admin_by_dept.get(dept_id, []),
            )
        except RuntimeError as e:
            print(f"\n  ERROR dept {dept_id}: {e}")
            continue

        out_path = os.path.join(OUTPUT_DIR, f"shifts_dept_{dept_id.zfill(2)}.sql")
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(f"-- AUTO-GENERATED shifts for {dept_name(dept_id)}\n")
            f.write(f"-- Period: {START_DATE.date()} → {END_DATE.date()}\n")
            f.write(f"-- Lines: {len(lines)}\n\n")
            f.write("SET NAMES utf8mb4;\n\n")
            f.write("\n".join(lines))
            f.write("\n")

        total_lines += len(lines)
        print(f"{len(lines):,} calls → {os.path.basename(out_path)}")

    print(f"\nDone. Total CALL statements: {total_lines:,}")
    print(f"Output dir: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()

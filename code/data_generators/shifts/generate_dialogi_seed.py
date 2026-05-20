#!/usr/bin/env python3
"""
Generate SQL CALLs for register_dialogi(...) using a time-based triage queue simulation.

Input CSV expectation:
- One row per patient or patient/nosileia relation.
- Must contain an AMKA column.
- Should contain a has_nosileia column.
- Should contain an admission date column for nosileia patients.

Default simulated interval:
2023-01-01 00:00:00 to 2026-05-14 23:59:59

Queue rule:
- Pick lowest epipedo first.
- For same epipedo, FIFO by wra_afiksis.

Arrival model:
- Poisson process, implemented as exponential inter-arrival times.

Processing model:
- Normal distribution, mean 15 minutes, std 4 minutes, minimum 5 minutes.
"""

from __future__ import annotations

import argparse
import heapq
import math
import random
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timedelta, date
from pathlib import Path
from typing import Optional

import numpy as np
import pandas as pd


DEFAULT_START = "2023-01-01 00:00:00"
DEFAULT_END = "2026-05-14 23:59:59"

DEFAULT_MEAN_INTERARRIVAL_MINUTES = 13.5
DEFAULT_SERVICE_MEAN_MINUTES = 15.0
DEFAULT_SERVICE_STD_MINUTES = 4.0
DEFAULT_SERVICE_MIN_MINUTES = 5.0

EPIPEDO_VALUES = [1, 2, 3, 4, 5]
EPIPEDO_WEIGHTS = [0.05, 0.15, 0.30, 0.35, 0.15]

SYMPTOMATA = [
    "Πυρετός και αδυναμία",
    "Πόνος στο στήθος",
    "Δύσπνοια",
    "Κοιλιακός πόνος",
    "Ζάλη και τάση λιποθυμίας",
    "Τραυματισμός μετά από πτώση",
    "Έντονος πονοκέφαλος",
    "Ναυτία και έμετος",
    "Αλλεργική αντίδραση",
    "Οξύς πόνος άκρου",
    "Υψηλή αρτηριακή πίεση",
    "Πόνος στη μέση",
]

ODIGIES_APOXORISIS = [
    "Σύσταση για ξεκούραση και επανεκτίμηση αν τα συμπτώματα επιδεινωθούν.",
    "Λήψη υγρών και παρακολούθηση θερμοκρασίας για 24 ώρες.",
    "Σύσταση για επικοινωνία με προσωπικό ιατρό εντός 48 ωρών.",
    "Αποφυγή έντονης δραστηριότητας και επανεξέταση αν χρειαστεί.",
    "Χορήγηση γενικών οδηγιών και επιστροφή στο ΤΕΠ σε περίπτωση επιδείνωσης.",
    "Παρακολούθηση συμπτωμάτων και τήρηση οδηγιών εξόδου.",
]


@dataclass
class SimPatient:
    sim_id: int
    wra_afiksis: datetime
    epipedo: int
    processing_minutes: int
    symptomata: str
    service_start: Optional[datetime] = None
    wra_oloklirosis: Optional[datetime] = None
    amka_astheni: Optional[str] = None
    apotelesma: Optional[str] = None
    odigies: Optional[str] = None


def sql_string(value: Optional[object]) -> str:
    if value is None or (isinstance(value, float) and math.isnan(value)):
        return "NULL"

    if isinstance(value, (datetime, pd.Timestamp)):
        value = value.strftime("%Y-%m-%d %H:%M:%S")
    elif isinstance(value, date):
        value = value.strftime("%Y-%m-%d")

    s = str(value)
    s = s.replace("\\", "\\\\").replace("'", "''")
    return f"'{s}'"


def normalize_bool(value: object) -> bool:
    if pd.isna(value):
        return False
    s = str(value).strip().lower()
    return s in {"1", "true", "yes", "y", "nai", "ναι", "has", "has_nosileia"}


def find_column(df: pd.DataFrame, explicit: Optional[str], candidates: list[str]) -> str:
    if explicit:
        if explicit not in df.columns:
            raise ValueError(f"Column '{explicit}' was not found. Available columns: {list(df.columns)}")
        return explicit

    lower_map = {c.lower().strip(): c for c in df.columns}
    for candidate in candidates:
        key = candidate.lower().strip()
        if key in lower_map:
            return lower_map[key]

    raise ValueError(
        "Could not auto-detect a required column. "
        f"Tried: {candidates}. Available columns: {list(df.columns)}"
    )


def random_processing_minutes(rng: np.random.Generator, mean: float, std: float, min_minutes: float) -> int:
    value = rng.normal(mean, std)
    value = max(min_minutes, value)
    return int(round(value))


def load_patient_csv(
    csv_path: Path,
    amka_col: Optional[str],
    has_nosileia_col: Optional[str],
    admission_col: Optional[str],
) -> tuple[dict[date, list[str]], list[str]]:
    df = pd.read_csv(csv_path, dtype=str, encoding="utf-8-sig")

    amka_col = find_column(df, amka_col, [
        "amka_astheni",
        "amka",
        "ΑΜΚΑ",
        "amkastheni",
        "patient_amka",
    ])

    has_col = find_column(df, has_nosileia_col, [
        "has_nosileia",
        "has nosileia",
        "exei_nosileia",
        "εχει_νοσηλεια",
        "has_hospitalization",
    ])

    adm_col = find_column(df, admission_col, [
        "imerominia_eisagogis",
        "imerominia_eisodou",
        "first_admitted",
        "first_admission_date",
        "earliest_imerominia_eisagogis",
        "ημερομηνια_εισαγωγης",
        "imerominia_eisagwgis",
    ])

    df[amka_col] = df[amka_col].astype(str).str.strip()
    df[has_col] = df[has_col].apply(normalize_bool)
    df[adm_col] = pd.to_datetime(df[adm_col], errors="coerce")

    referral_by_date: dict[date, list[str]] = defaultdict(list)
    no_nosileia_amkas: list[str] = []

    for _, row in df.iterrows():
        amka = str(row[amka_col]).strip()
        if not amka or amka.lower() == "nan":
            continue

        if bool(row[has_col]) and pd.notna(row[adm_col]):
            referral_by_date[row[adm_col].date()].append(amka)
        else:
            no_nosileia_amkas.append(amka)

    for d in list(referral_by_date.keys()):
        referral_by_date[d] = list(dict.fromkeys(referral_by_date[d]))

    no_nosileia_amkas = list(dict.fromkeys(no_nosileia_amkas))

    if not referral_by_date:
        print("WARNING: No nosileia/admission-date rows were found. All rows may become Αποχώρηση.")

    if not no_nosileia_amkas:
        print("WARNING: No non-nosileia patients were found. Reusing all AMKAs as fallback.")
        no_nosileia_amkas = list(dict.fromkeys(df[amka_col].dropna().astype(str).str.strip().tolist()))

    return referral_by_date, no_nosileia_amkas


def generate_arrivals(
    start_dt: datetime,
    end_dt: datetime,
    rng: np.random.Generator,
    py_rng: random.Random,
    mean_interarrival: float,
    service_mean: float,
    service_std: float,
    service_min: float,
    max_arrivals: Optional[int],
) -> list[SimPatient]:
    arrivals: list[SimPatient] = []
    current = start_dt
    sim_id = 1

    while current <= end_dt:
        delta_minutes = rng.exponential(mean_interarrival)
        current = current + timedelta(minutes=float(delta_minutes))

        if current > end_dt:
            break

        epipedo = int(rng.choice(EPIPEDO_VALUES, p=EPIPEDO_WEIGHTS))
        processing = random_processing_minutes(rng, service_mean, service_std, service_min)
        symptomata = py_rng.choice(SYMPTOMATA)

        arrivals.append(
            SimPatient(
                sim_id=sim_id,
                wra_afiksis=current,
                epipedo=epipedo,
                processing_minutes=processing,
                symptomata=symptomata,
            )
        )

        sim_id += 1

        if max_arrivals is not None and len(arrivals) >= max_arrivals:
            break

    return arrivals


def process_queue(arrivals: list[SimPatient], start_dt: datetime) -> list[SimPatient]:
    queue: list[tuple[int, datetime, int, SimPatient]] = []
    completed: list[SimPatient] = []

    i = 0
    server_free_at = start_dt

    while i < len(arrivals) or queue:
        if not queue and i < len(arrivals) and arrivals[i].wra_afiksis > server_free_at:
            server_free_at = arrivals[i].wra_afiksis

        while i < len(arrivals) and arrivals[i].wra_afiksis <= server_free_at:
            p = arrivals[i]
            heapq.heappush(queue, (p.epipedo, p.wra_afiksis, p.sim_id, p))
            i += 1

        if not queue:
            continue

        _, _, _, p = heapq.heappop(queue)

        p.service_start = max(server_free_at, p.wra_afiksis)
        p.wra_oloklirosis = p.service_start + timedelta(minutes=p.processing_minutes)

        server_free_at = p.wra_oloklirosis
        completed.append(p)

    return completed


def assign_patients_and_results(
    completed: list[SimPatient],
    referral_by_date: dict[date, list[str]],
    no_nosileia_amkas: list[str],
    py_rng: random.Random,
    reuse_referral_patients: bool,
) -> None:
    used_referral_indices: dict[date, int] = defaultdict(int)

    for p in completed:
        assert p.wra_oloklirosis is not None

        finish_date = p.wra_oloklirosis.date()
        candidates = referral_by_date.get(finish_date, [])

        assigned_referral = False

        if candidates:
            if reuse_referral_patients:
                p.amka_astheni = py_rng.choice(candidates)
                assigned_referral = True
            else:
                idx = used_referral_indices[finish_date]
                if idx < len(candidates):
                    p.amka_astheni = candidates[idx]
                    used_referral_indices[finish_date] += 1
                    assigned_referral = True

        if assigned_referral:
            p.apotelesma = "Παραπομπή"
            p.odigies = None
        else:
            p.amka_astheni = py_rng.choice(no_nosileia_amkas)
            p.apotelesma = "Αποχώρηση"
            p.odigies = py_rng.choice(ODIGIES_APOXORISIS)


def write_sql_calls(
    completed: list[SimPatient],
    output_sql_path: Path,
    procedure_name: str,
) -> None:
    with output_sql_path.open("w", encoding="utf-8", newline="\n") as f:
        f.write("SET NAMES utf8mb4;\n\n")
        f.write("-- Generated dialogistoixeiwn seed calls\n")
        f.write("-- Expected procedure signature used here:\n")
        f.write(f"-- CALL {procedure_name}(amka_astheni, wra_afiksis, symptomata, epipedo, apotelesma, odigies, wra_oloklirosis);\n\n")

        for p in completed:
            f.write(
                f"CALL {procedure_name}("
                f"{sql_string(p.amka_astheni)}, "
                f"{sql_string(p.wra_afiksis)}, "
                f"{sql_string(p.symptomata)}, "
                f"{p.epipedo}, "
                f"{sql_string(p.apotelesma)}, "
                f"{sql_string(p.odigies)}, "
                f"{sql_string(p.wra_oloklirosis)}"
                f");\n"
            )


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate SQL CALLs for dialogistoixeiwn triage simulation.")

    parser.add_argument("--input-csv", required=True, type=Path)
    parser.add_argument("--output-sql", default=Path("generated_dialogi_seed.sql"), type=Path)

    parser.add_argument("--amka-col", default=None)
    parser.add_argument("--has-nosileia-col", default=None)
    parser.add_argument("--admission-col", default=None)

    parser.add_argument("--start", default=DEFAULT_START)
    parser.add_argument("--end", default=DEFAULT_END)

    parser.add_argument("--mean-interarrival-minutes", type=float, default=DEFAULT_MEAN_INTERARRIVAL_MINUTES)
    parser.add_argument("--service-mean-minutes", type=float, default=DEFAULT_SERVICE_MEAN_MINUTES)
    parser.add_argument("--service-std-minutes", type=float, default=DEFAULT_SERVICE_STD_MINUTES)
    parser.add_argument("--service-min-minutes", type=float, default=DEFAULT_SERVICE_MIN_MINUTES)

    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--max-arrivals", type=int, default=None)

    parser.add_argument("--procedure-name", default="register_dialogi")

    parser.add_argument(
        "--reuse-referral-patients",
        action="store_true",
        help="Allow the same admitted patient AMKA to be used multiple times on the same date.",
    )

    args = parser.parse_args()

    start_dt = datetime.fromisoformat(args.start)
    end_dt = datetime.fromisoformat(args.end)

    rng = np.random.default_rng(args.seed)
    py_rng = random.Random(args.seed)

    referral_by_date, no_nosileia_amkas = load_patient_csv(
        csv_path=args.input_csv,
        amka_col=args.amka_col,
        has_nosileia_col=args.has_nosileia_col,
        admission_col=args.admission_col,
    )

    arrivals = generate_arrivals(
        start_dt=start_dt,
        end_dt=end_dt,
        rng=rng,
        py_rng=py_rng,
        mean_interarrival=args.mean_interarrival_minutes,
        service_mean=args.service_mean_minutes,
        service_std=args.service_std_minutes,
        service_min=args.service_min_minutes,
        max_arrivals=args.max_arrivals,
    )

    completed = process_queue(arrivals, start_dt=start_dt)

    assign_patients_and_results(
        completed=completed,
        referral_by_date=referral_by_date,
        no_nosileia_amkas=no_nosileia_amkas,
        py_rng=py_rng,
        reuse_referral_patients=args.reuse_referral_patients,
    )

    write_sql_calls(
        completed=completed,
        output_sql_path=args.output_sql,
        procedure_name=args.procedure_name,
    )

    print(f"Generated arrivals: {len(arrivals)}")
    print(f"Completed rows:     {len(completed)}")
    print(f"Output SQL:         {args.output_sql}")

    if completed:
        print(f"First arrival:      {completed[0].wra_afiksis}")
        print(f"Last completion:    {completed[-1].wra_oloklirosis}")

        referrals = sum(1 for p in completed if p.apotelesma == "Παραπομπή")
        exits = sum(1 for p in completed if p.apotelesma == "Αποχώρηση")
        print(f"Παραπομπή rows:     {referrals}")
        print(f"Αποχώρηση rows:     {exits}")


if __name__ == "__main__":
    main()

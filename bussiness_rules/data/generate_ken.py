import csv

INPUT_FILE  = 'bussiness_rules/data/ken.csv'
OUTPUT_FILE = 'bussiness_rules/data/load_ken.sql'

# imer_xrewsi (χρέωση ανά ημέρα πέρα από το MDN) δεν υπάρχει στο CSV.
# Όλες οι εγγραφές μπαίνουν με 0 — άλλαξέ το χειροκίνητα αν το χρειαστείς.
DEFAULT_IMER_XREWSI = 0.00

def parse_cost(raw):
    """
    Στο ελληνικό format η τελεία είναι διαχωριστικό χιλιάδων.
    '28.907' -> 28907.00
    '50.379' -> 50379.00
    """
    raw = raw.strip()
    if not raw:
        return None
    raw = raw.replace('.', '').replace(' ', '')
    try:
        return float(raw)
    except ValueError:
        return None

lines = [
    '-- INSERT statements for ken table',
    '-- Generated from ken.csv',
    '-- imer_xrewsi is set to 0.00 everywhere — update manually if needed',
    '-- Duplicates are ignored (INSERT IGNORE)',
    ''
]

skipped = []
seen    = set()

with open(INPUT_FILE, encoding='cp1253') as f:
    reader = csv.reader(f, delimiter=';')
    next(reader)  # παράλειψη header
    for row in reader:
        if len(row) < 4:
            continue

        kod_ken  = row[0].strip()
        cost_raw = row[2].strip()
        mdn_raw  = row[3].strip()

        # Παράλειψη κενών γραμμών και επικεφαλίδων κατηγορίας (π.χ. "ΤΚΑ 01")
        if not kod_ken:
            continue

        # Το MDN πρέπει να είναι ακέραιος > 0
        try:
            mdn = int(mdn_raw)
            if mdn <= 0:
                raise ValueError
        except ValueError:
            continue

        cost = parse_cost(cost_raw)
        if cost is None:
            skipped.append(kod_ken)
            continue

        # Duplicate codes στο CSV (λάθη στο αρχείο) — κρατάμε την πρώτη εμφάνιση
        if kod_ken in seen:
            skipped.append(f'{kod_ken}(duplicate)')
            continue
        seen.add(kod_ken)

        # Escape single quotes σε περίπτωση που υπάρχουν στον κωδικό
        kod_safe = kod_ken.replace("'", "''")

        line = (f"INSERT IGNORE INTO ken (kod_ken, vasiko_kostos, mdn, imer_xrewsi) "
                f"VALUES ('{kod_safe}', {cost:.2f}, {mdn}, {DEFAULT_IMER_XREWSI:.2f});")
        lines.append(line)

if skipped:
    lines += ['', f'-- Skipped: {", ".join(skipped)}']

with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f'Done. Output: {OUTPUT_FILE}')
print(f'Inserted: {len(seen)} rows')
if skipped:
    print(f'Skipped : {skipped}')

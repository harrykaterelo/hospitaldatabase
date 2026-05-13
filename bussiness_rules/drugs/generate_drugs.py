import csv
import re

INPUT_FILE  = 'bussiness_rules/data/article57.csv'
OUTPUT_FILE = 'bussiness_rules/drugs/load.sql'

# Γραμμές μεταδεδομένων πριν τον πίνακα (1-15 στο Excel → 0-14 σε Python)
HEADER_ROW  = 15   # η γραμμή 16 του Excel (0-indexed)
DELIMITER   = ','  # άλλαξε σε ';' αν χρειαστεί
ENCODING    = 'utf-8-sig'


def fix_phone(raw: str) -> str | None:
    """Διορθώνει τηλέφωνα που το Excel έγραψε σε επιστημονική σημειογραφία."""
    if not raw:
        return None
    raw = raw.strip()
    if not raw:
        return None

    # Αντικατάσταση ευρωπαϊκού decimal comma → dot για float()
    normalized = raw.replace(',', '.')

    # Αν είναι σε μορφή π.χ. "4.97429E+11"
    if re.fullmatch(r'[+\-]?\d+\.?\d*[eE][+\-]\d+', normalized):
        try:
            val = int(float(normalized))
            return str(val)
        except (ValueError, OverflowError):
            pass

    return raw


def esc(s: str | None) -> str:
    """Escape τιμής για SQL string literal."""
    if s is None or s == '':
        return 'NULL'
    return "'" + s.replace("'", "''") + "'"


# ---------------------------------------------------------------
# Ανάγνωση CSV
# key = (onoma, tropos, xora_egkr, katoxos, xora_psmf, email, thl)
# value = set of δραστικών ουσιών
# ---------------------------------------------------------------
drugs: dict[tuple, set[str]] = {}

with open(INPUT_FILE, encoding=ENCODING, newline='') as f:
    reader = csv.reader(f, delimiter=DELIMITER)

    for _ in range(HEADER_ROW):
        next(reader)        # παράλειψη μεταδεδομένων

    next(reader)            # παράλειψη γραμμής επικεφαλίδων (row 16)

    for row in reader:
        if len(row) < 8:
            continue

        onoma     = row[0].strip()
        drastiki  = row[1].strip()
        tropos    = row[2].strip()
        xora_egkr = row[3].strip()
        katoxos   = row[4].strip()
        xora_psmf = row[5].strip()
        email     = row[6].strip()
        thl       = fix_phone(row[7])

        if not onoma:
            continue

        key = (onoma, tropos, xora_egkr, katoxos, xora_psmf, email, thl)
        if key not in drugs:
            drugs[key] = set()
        if drastiki:
            drugs[key].add(drastiki)

# ---------------------------------------------------------------
# Παραγωγή SQL
# ---------------------------------------------------------------
lines = [
    '-- Αυτόματα παραγόμενο αρχείο – EMA Article 57',
    '-- ΜΗΝ επεξεργαστείς χειροκίνητα.',
    '',
    'SET NAMES utf8mb4;',
    '',
]

# Όλες οι δραστικές ουσίες
all_drastikes: set[str] = set()
for drastikes in drugs.values():
    all_drastikes.update(drastikes)

lines.append('-- ── Δραστικές ουσίες ─────────────────────────────────────────')
for do in sorted(all_drastikes):
    lines.append(f"INSERT IGNORE INTO drastiki_ousia (onoma) VALUES ({esc(do)});")

lines += ['', '-- ── Φάρμακα ─────────────────────────────────────────────────', '']

for key, drastikes in drugs.items():
    onoma, tropos, xora_egkr, katoxos, xora_psmf, email, thl = key

    lines.append(
        f"INSERT INTO farmako "
        f"(onoma, tropos_xorigisis, xora_egkrisis, katoxos_adeias, xora_psmf, epivlepsi_email, epivlepsi_thl) "
        f"VALUES ("
        f"{esc(onoma)}, {esc(tropos)}, {esc(xora_egkr)}, {esc(katoxos)}, "
        f"{esc(xora_psmf)}, {esc(email)}, {esc(thl)}"
        f");"
    )
    lines.append("SET @ema := LAST_INSERT_ID();")

    for do in sorted(drastikes):
        lines.append(
            f"INSERT IGNORE INTO farmako_drastiki (kod_ema, onoma_do) VALUES (@ema, {esc(do)});"
        )

    lines.append('')

with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f'Φάρμακα εισαχθέντα : {len(drugs)}')
print(f'Δραστικές ουσίες   : {len(all_drastikes)}')
print(f'Αρχείο             : {OUTPUT_FILE}')

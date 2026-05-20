import csv

INPUT_FILE  = 'bussiness_rules/data/farmka.csv'
OUTPUT_FILE = 'bussiness_rules/drugs/load.sql'

HEADER_ROW  = 20
DELIMITER   = ';'
ENCODING    = 'cp1252'

def esc(s: str | None) -> str:
    """Escape τιμής για SQL string literal."""
    if s is None or s == '':
        return 'NULL'
    return "'" + s.replace("'", "''") + "'"

drugs: dict[tuple, set[str]] = {}

with open(INPUT_FILE, encoding=ENCODING, newline='') as f:
    reader = csv.reader(f, delimiter=DELIMITER)

    for _ in range(HEADER_ROW):
        next(reader)      

    next(reader)          

    for row in reader:
        if len(row) < 8:
            continue

        onoma     = row[0].strip()
        drastikes_raw = [d.strip() for d in row[1].split('|') if d.strip()]
        tropos    = row[2].strip()
        if not onoma:
            continue

        key = (onoma, tropos)
        if key not in drugs:
            drugs[key] = set()
        drugs[key].update(drastikes_raw)


lines = [
    'SET NAMES utf8mb4;',
    '',
]

all_drastikes: set[str] = set()
for drastikes in drugs.values():
    all_drastikes.update(drastikes)

lines.append('-- ── Δραστικές ουσίες ─────────────────────────────────────────')
for do in sorted(all_drastikes):
    lines.append(f"INSERT IGNORE INTO drastiki_ousia (onoma) VALUES ({esc(do)});")

lines += ['', '-- ── Φάρμακα ─────────────────────────────────────────────────', '']

for key, drastikes in drugs.items():
    onoma, tropos = key

    lines.append(
        f"INSERT IGNORE INTO farmako (onoma, tropos_xorigisis) "
        f"VALUES ({esc(onoma)}, {esc(tropos)});"
    )
    lines.append("SET @is_new := ROW_COUNT();")
    lines.append(
        f"SET @ema := (SELECT kod_ema FROM farmako WHERE onoma = {esc(onoma)} AND tropos_xorigisis = {esc(tropos)});"
    )

    for do in sorted(drastikes):
        lines.append(
            f"INSERT IGNORE INTO farmako_drastiki (kod_ema, ousia_id) "
            f"SELECT @ema, ousia_id FROM drastiki_ousia WHERE onoma = {esc(do)} AND @is_new > 0;"
        )

    lines.append('')

with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f'Φάρμακα εισαχθέντα : {len(drugs)}')
print(f'Δραστικές ουσίες   : {len(all_drastikes)}')
print(f'Αρχείο             : {OUTPUT_FILE}')

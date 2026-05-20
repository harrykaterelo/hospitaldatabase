import csv

INPUT_FILE  = 'bussiness_rules/data/ken.csv'
OUTPUT_FILE = 'bussiness_rules/data/load_ken.sql'

def parse_cost(raw):
    if not raw:
        return None
    raw = raw.replace('.', '').replace(' ', '').replace('€', '')
    try:
        return float(raw)
    except ValueError:
        return None

lines = [
    '-- INSERT statements for ken table',
    ''
]

count = 0

with open(INPUT_FILE, encoding='cp1253') as f:
    reader = csv.reader(f, delimiter=';')
    next(reader)  # παράλειψη header
    for row in reader:

        kod_ken  = row[0].strip()
        cost_raw = row[2].strip()
        mdn_raw  = row[3].strip()

        try:
            mdn = int(mdn_raw)
        except ValueError:
            continue

        cost = parse_cost(cost_raw)
        if cost is None:
            continue

        imer_xrewsi = cost / mdn

        line = (f"INSERT INTO ken (kod_ken, vasiko_kostos, mdn, imer_xrewsi) "
                f"VALUES ('{kod_ken}', {cost:.2f}, {mdn}, {imer_xrewsi:.2f});")
        lines.append(line)
        count += 1

with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f'Inserted: {count} rows')

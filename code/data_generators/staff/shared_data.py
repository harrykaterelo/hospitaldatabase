"""
Shared Greek name data and helper utilities for staff SQL generation.
"""

import random
import datetime

# ── Greek name pools ──────────────────────────────────────────────────────────

MALE_FIRST_NAMES = [
    "Γιώργης", "Νίκος", "Κώστας", "Δημήτρης", "Παναγιώτης",
    "Γιάννης", "Βασίλης", "Χρήστος", "Αλέξανδρος", "Σταύρος",
    "Μιχάλης", "Αντώνης", "Θανάσης", "Πέτρος", "Λευτέρης",
    "Ηλίας", "Σπύρος", "Θεόδωρος", "Κυριάκος", "Φώτης",
    "Μανώλης", "Αργύρης", "Σωτήρης", "Ευάγγελος", "Γρηγόρης",
    "Τάσος", "Λάμπρος", "Στέλιος", "Δημοσθένης", "Άγγελος",
    "Ορέστης", "Απόστολος", "Χαράλαμπος", "Βαγγέλης", "Νεκτάριος",
    "Αχιλλέας", "Οδυσσέας", "Περικλής", "Αλκιβιάδης", "Κλέων",
]

FEMALE_FIRST_NAMES = [
    "Μαρία", "Ελένη", "Κατερίνα", "Σοφία", "Αναστασία",
    "Γεωργία", "Δήμητρα", "Παναγιώτα", "Χριστίνα", "Νικολέτα",
    "Αγγελική", "Βασιλική", "Ευαγγελία", "Φωτεινή", "Αντωνία",
    "Ιωάννα", "Θεοδώρα", "Αλεξάνδρα", "Ειρήνη", "Σταυρούλα",
    "Αρετή", "Ζωή", "Μελίνα", "Αθηνά", "Ρένα",
    "Κυριακή", "Ευτυχία", "Μαγδαληνή", "Σεβαστή", "Λαμπρινή",
    "Αφροδίτη", "Χαρά", "Δάφνη", "Κλεοπάτρα", "Ολυμπία",
    "Πηνελόπη", "Αριάδνη", "Καλλιόπη", "Θάλεια", "Ευρυδίκη",
]

LAST_NAMES = [
    "Παπαδόπουλος", "Παπαδημητρίου", "Ιωαννίδης", "Παπανικολάου", "Κωνσταντινίδης",
    "Αλεξίου", "Νικολαΐδης", "Γεωργίου", "Δημητρίου", "Αντωνίου",
    "Χριστοδούλου", "Σταυρίδης", "Μιχαηλίδης", "Θεοδωρίδης", "Αναστασίου",
    "Καραγιάννης", "Παπαζήσης", "Σιδηρόπουλος", "Τσιώλης", "Μαυρίδης",
    "Ζαχαρίου", "Οικονόμου", "Λαζαρίδης", "Ευαγγελίδης", "Κυριακίδης",
    "Χατζηγεωργίου", "Τριανταφυλλίδης", "Παπαθανασίου", "Βασιλόπουλος", "Μακρής",
    "Σακελλαρίου", "Κατσαρός", "Τσιτσιπάς", "Ξανθόπουλος", "Βλαχόπουλος",
    "Τσακαλίδης", "Γκαράνης", "Μπέλλος", "Κασσαβέτης", "Σφακιανάκης",
    "Ρούσσος", "Καρράς", "Ντάλλας", "Πλέσσας", "Μαρκόπουλος",
    "Κουτσούμπας", "Τσίπρας", "Μητσοτάκης", "Παπανδρέου", "Βενιζέλος",
]

EIDIKOTITES = [
    "Καρδιολογία", "Νευρολογία", "Ορθοπεδική", "Παθολογία", "Χειρουργική",
    "Παιδιατρική", "Γυναικολογία", "Ουρολογία", "Οφθαλμολογία", "Δερματολογία",
    "Ψυχιατρική", "Πνευμονολογία", "Νεφρολογία", "Ογκολογία", "Ενδοκρινολογία",
    "Γαστρεντερολογία", "Αιματολογία", "Ρευματολογία", "Αναισθησιολογία", "Ακτινολογία",
]

VATHMIDES_NOSILEUTI = [
    'Βοηθός Νοσηλευτή', 'Νοσηλευτής', 'Προϊστάμενος'
]

VATHMIDA_NOSILEUTI_WEIGHTS = [0.50, 0.30, 0.20]

ADMIN_ROLES = [
    "Γραμματέας Τμήματος", "Υπεύθυνος Αρχείου", "Διαχειριστής Εξοπλισμού",
    "Λογιστής", "Υπεύθυνος Μισθοδοσίας", "Διοικητικός Βοηθός",
    "Υπεύθυνος Προμηθειών", "Τμηματάρχης Διοίκησης", "Στέλεχος Ανθρωπίνων Πόρων",
    "Υπεύθυνος Ποιότητας",
]

GRAFEIO_PREFIXES = ["Α", "Β", "Γ", "Δ", "Ε"]

# ── Utility helpers ────────────────────────────────────────────────────────────

_used_amkas: set[str] = set()
_used_emails: set[str] = set()
_amka_counter_doc_base = 10000000000  # deterministic base
_amka_counter_nos_base = 20000000000
_amka_counter_dii_base = 30000000000
from enum import Enum

class Role(Enum):
    DOCTOR = "doctor"
    NURSE = "nurse"
    ADMIN = "admin"

def gen_amka(staff_type:Role) -> str:
    """Generate a unique 11-digit AMKA."""
    global _amka_counter_doc_base
    global _amka_counter_nos_base
    global _amka_counter_dii_base
    amka = ''
    if(staff_type==Role.DOCTOR):
        _amka_counter_doc_base += 1
        amka = str(_amka_counter_doc_base)
    
    elif (staff_type==Role.NURSE):

        _amka_counter_nos_base += 1
        amka = str(_amka_counter_nos_base)
    else:
        _amka_counter_dii_base += 1
        amka = str(_amka_counter_dii_base)
    assert len(amka) == 11
    return amka


def gen_email(onoma: str, eponymo: str) -> str:
    """Generate a unique email from name parts."""
    import unicodedata

    def strip_accents(s: str) -> str:
        nfkd = unicodedata.normalize("NFKD", s)
        return "".join(c for c in nfkd if not unicodedata.combining(c))

    base_onoma = strip_accents(onoma).lower().replace(" ", "")
    base_eponymo = strip_accents(eponymo).lower().replace(" ", "")
    candidate = f"{base_onoma}.{base_eponymo}@hospital.gr"
    if candidate not in _used_emails:
        _used_emails.add(candidate)
        return candidate
    for i in range(1, 9999):
        candidate = f"{base_onoma}.{base_eponymo}{i}@hospital.gr"
        if candidate not in _used_emails:
            _used_emails.add(candidate)
            return candidate
    raise RuntimeError("Email space exhausted")


def gen_phone() -> str:
    """Generate a Greek mobile number."""
    prefixes = ["69", "694", "697", "698", "693"]
    prefix = random.choice(prefixes)
    rest = "".join(str(random.randint(0, 9)) for _ in range(10 - len(prefix)))
    return prefix + rest


def gen_date(start_year: int = 2010, end_year: int = 2025) -> str:
    """Generate a random hire date."""
    start = datetime.date(start_year, 1, 1)
    end = datetime.date(end_year, 12, 31)
    delta = (end - start).days
    return (start + datetime.timedelta(days=random.randint(0, delta))).isoformat()


def gen_age(min_age: int = 25, max_age: int = 65) -> int:
    return random.randint(min_age, max_age)


def pick_gender_name() -> tuple[str, str, str]:
    """Return (gender, onoma, eponymo)."""
    gender = random.choice(["M", "F"])
    if gender == "M":
        onoma = random.choice(MALE_FIRST_NAMES)
        eponymo = random.choice(LAST_NAMES)
    else:
        onoma = random.choice(FEMALE_FIRST_NAMES)
        # Feminise surname
        ep = random.choice(LAST_NAMES)
        if ep.endswith("ης"):
            eponymo = ep[:-2] + "η"
        elif ep.endswith("ος"):
            eponymo = ep[:-2] + "ου"
        elif ep.endswith("ης"):
            eponymo = ep[:-2] + "η"
        else:
            eponymo = ep
    return gender, onoma, eponymo


def sql_str(value) -> str:
    """Escape a Python value for SQL insertion."""
    if value is None:
        return "NULL"
    s = str(value).replace("'", "''")
    return f"'{s}'"

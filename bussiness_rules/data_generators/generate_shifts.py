
from util import START_DATE,END_DATE
iatros_max_monthly_ef_count  = 25
nosileutes_max_monthly_ef_count  = 20
dioikitiko_max_monthly_ef_count =15
iatros_min_count =3
nosileutes_min_count  = 6
dioikitiko_min_count  = 2
endiamesi_ora_anapausis_hours = 8
epitreptes_sinexomenes_nixterines_vardies = 3
shift_duration =8
shiftNames = ["Πρωινή","Απογευματινή","Νυχτερινή"]
doctorDep = {}
nosileutesDep = {}
dioikitikoDep = {}

all_available_shifts_in_time_span = ((END_DATE-START_DATE).total_seconds()/3600)/shift_duration

print(all_available_shifts_in_time_span)
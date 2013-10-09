##########################################
from pandas import *
import datetime
import sys
##########################################

def main():
	argv = sys.argv[1:]
	if len(argv) > 0:
		v_year, v_month, v_day = argv
		v_year, v_month, v_day = int(v_year), int(v_month), int(v_day)
		v_calc_date = datetime.date(v_year,v_month,v_day)
	else:
		dt = datetime.datetime.now() - datetime.timedelta(days=1)
		v_year, v_month, v_day = dt.year, dt.month, dt.day
		v_calc_date = datetime.date(v_year,v_month,v_day)

	v_path = "./data/sleeping_prevention_mail/sucess_user_"
	v_path = v_path + v_calc_date.strftime("%Y%m%d")
	v_path = v_path + ".dat"
	
	df = read_table(v_path, header=None, names=["user_id"])
	df["date"] = v_calc_date.strftime("%Y-%m-%d")
	df.to_csv("./data/sleeping_prevention_mail/sucess_user_list.txt", mode="a", index=False, header=False)
	
if __name__ == '__main__':
	main()

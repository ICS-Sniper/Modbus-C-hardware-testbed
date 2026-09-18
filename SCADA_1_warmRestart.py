# PLCX is the control interface, talking and giving instructions to all PLCs
# Modified for warm restart functionality - uses utils_warmRestart instead of utils
from devices import PLC
from utils_warmRestart import SCADA_DATA, SCADA_PROTOCOL, SCADA_ADDR
from utils_warmRestart import IP
from utils_warmRestart import getdata, setdata
import time
from datetime import datetime
from HMI.HMI import *
import os
import csv
import multiprocessing as mp
import pickle


tags_to_log = ['HMI.P1.State','HMI.P2.State','HMI.P3.State','HMI.P4.State','HMI.P5.State','HMI.P6.State','HMI.P101.Status','HMI.P102.Status','HMI.MV101.Status','HMI.MV201.Status','HMI.FIT101.Pv','HMI.LIT101.Pv','HMI.LS201.Alarm','HMI.LS202.Alarm','HMI.LSL203.Alarm','HMI.LSLL203.Alarm','HMI.P201.Status','HMI.P202.Status','HMI.P203.Status','HMI.P204.Status','HMI.P205.Status','HMI.P206.Status','HMI.P207.Status','HMI.P208.Status','HMI.FIT201.Pv','HMI.AIT201.Pv','HMI.AIT202.Pv','HMI.AIT203.Pv','HMI.P301.Status','HMI.P302.Status','HMI.FIT301.Pv','HMI.LIT301.Pv','HMI.PSH301.Alarm','HMI.DPSH301.Alarm','HMI.DPIT301.Pv','HMI.MV301.Status','HMI.MV302.Status','HMI.MV303.Status','HMI.MV304.Status','HMI.LS401.Alarm','HMI.LIT401.Pv','HMI.P401.Status','HMI.P402.Status','HMI.P403.Status','HMI.P404.Status','HMI.UV401.Status','HMI.AIT401.Pv','HMI.AIT402.Pv','HMI.FIT401.Pv','HMI.AIT501.Pv','HMI.AIT502.Pv','HMI.AIT503.Pv','HMI.AIT504.Pv','HMI.FIT501.Pv','HMI.FIT502.Pv','HMI.FIT503.Pv','HMI.FIT504.Pv','HMI.MV501.Status','HMI.MV502.Status','HMI.MV503.Status','HMI.MV504.Status','HMI.P501.Status','HMI.P502.Status','HMI.LSL601.Alarm','HMI.LSL602.Alarm','HMI.LSL603.Alarm','HMI.LSH601.Alarm','HMI.LSH602.Alarm','HMI.LSH603.Alarm','HMI.P601.Status','HMI.P602.Status','HMI.P603.Status']

class H(PLC):


	def pre_loop(self):
		# Initialize all tags in the enip server
		time.sleep(10)
		counter = 0
		for key, value in SCADA_DATA.items():
			setdata(self,key, SCADA_ADDR, value)
			counter = counter + 1
		print('No of tags set:', counter)
		print("Initialization done")


	def create_log_file(self, path):
	    # Ensure path exists
		if not os.path.exists(path):
			raise FileNotFoundError("Path does not exist")

	    # List all files in the directory
		files = [f for f in os.listdir(path) if f.endswith(".csv")]

	    # Extract numeric part of file names (ignore non-numeric ones)
		nums = []
		for f in files:
			name, ext = os.path.splitext(f)
			if name.isdigit():
				nums.append(int(name))

	    # Determine the next file number
		next_num = max(nums) + 1 if nums else 1
		new_file = os.path.join(path, str(next_num) + ".csv")

		headers = "t_stamp,"

		for ctr in range(0,len(tags_to_log)):
			headers = headers + tags_to_log[ctr]

			if ctr<len(tags_to_log)-1:
				headers  = headers  + ','
			else:
				headers  = headers  + '\n'

	    # Write to the new CSV file
		with open(new_file, "w") as f:
			f.write(headers)

		# print(f"Created: {new_file}")
		return os.path.abspath(new_file)


	# def log_curr_status(self,logfilename):
	#
	# 	default_value = -999
	# 	# get current local datetime
	# 	now = datetime.now()
	# 	formatted_time = now.strftime("%d/%b/%Y %H:%M:%S")
	# 	values = formatted_time+','
	#
	# 	with open(logfilename, "a") as f:
	# 		for ctr in range(0,len(tags_to_log)):
	# 			values = values + str(getdata(self,tags_to_log[ctr], SCADA_ADDR, default_value))
	#
	# 			if ctr<len(tags_to_log)-1:
	# 				values = values + ','
	# 			else:
	# 				values = values + '\n'
	#
	# 		f.write(values)
	# 		# writer.writerow(values)

	def snapshot_consumer(self,queue,filename):
		"""Consumes snapshots from queue and saves them to disk."""
		while True:
			item = queue.get()  # blocking read
			if item is None:
				break  # signal to stop

			snapshot, ts = item
			values = ts+','
			with open(filename, "a") as f:
	            # pickle.dump(snapshot, f, protocol=2)  # protocol=2 for Python2.7
				for ctr in range(0,len(tags_to_log)):
					values = values + str(snapshot[tags_to_log[ctr]])

					if ctr<len(tags_to_log)-1:
						values = values + ','
					else:
						values = values + '\n'

				f.write(values)

		print("Saved snapshot:", filename)


	def main_loop(self):
		print("SCADA main loop starts here")
		#logfilename = self.create_log_file("./scadalogs/")

		#q = mp.Queue()
		# consumer = mp.Process(target=self.snapshot_consumer, args=(q,logfilename,))
		# consumer.daemon = True
		# consumer.start()

		while(True):
			# Implement alarms here
			# self.log_curr_status(logfilename)
			#print(self.memory)
			# ts = datetime.now().strftime("%d/%b/%Y %H:%M:%S")
			# q.put((self.memory.copy(),ts))
			time.sleep(1)

		############################ Code to test if ENIP server has been set up correctly ###########
		# plantreseton = 0
		# while(True):
		# 	try:
		# 		plantreseton = float(self.receive(('HMI.PLANT.Reset_On',2),SCADA_ADDR))
		# 	except:
		# 		print("Did not receive HMI.PLANT.Reset_On value")
		# 		pass
		# 	print('Received value:', plantreseton)
		# 	time.sleep(1)


if __name__ == "__main__":

    # notice that memory init is different form disk init
	scada = H(
        name='scada',
        protocol=SCADA_PROTOCOL,
        # state=STATE,
        memory=SCADA_DATA,
        disk=SCADA_DATA)
	time.sleep(10)
	print("Sleep over")
	scada.main_loop()

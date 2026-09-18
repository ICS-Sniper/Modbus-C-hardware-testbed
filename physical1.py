"""
Deployed on a computer with IP 192.168.137.1, simulating Actuator and Plant within process 1.
Acting as a Modbus TCP Server to communicate with Micro820 PLC.
Address Mapping:
  - 100-109: Digital Inputs & Analog Inputs (PLC reads)
  - 200-203: Digital Outputs (PLC writes)
"""

from pymodbus.server.sync import StartTcpServer
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.device import ModbusDeviceIdentification
import threading
import time
import struct

class PhysicalSimulator1:
    """SWaT physical simulator for T101 Tank and MV101 Valve"""
    
    def __init__(self, context):
        self.context = context
        self.slave_id = 0x00
        
        # Physical parameters
        self.p = {
            "f_mv101": 2.3 * 1000000000 / 3600,  # open flow rate
            "S_t101": 1.5 * 1000000,              # cross-sectional area
            "f_p101": 2.0 * 1000000000 / 3600,    # flow rate
            "LIT101_ALL": 250,                     # alarm low low
            "LIT101_AL": 500,                      # alarm low
            "LIT101_AH": 800,                      # alarm high
            "LIT101_AHH": 1100                     # alarm high high
        }
        
        # Initial states
        self.lit101_pv = 505.0  # initial level (mm)
        self.time_interval = 1.0  # scan interval (s)
        self.print_counter = 0  # counter for print throttling
        
        # IO States
        self.io_mv101_do_open = 0
        self.io_mv101_do_close = 1
        self.io_p101_do_start = 0
        self.io_p102_do_start = 0
        
        self.io_mv101_di_zso = 0
        self.io_mv101_di_zsc = 1
        self.io_p101_di_run = 0
        self.io_p102_di_run = 0
        
        # Initialize Modbus registers
        self._init_registers()
        
    def _init_registers(self):
        """ Initialize Modbus registers with default values """
        # Write initial DI states (PLC reads from address 100-109)
        self._write_bool(100, 0)  # IO.MV101.DI_ZSO
        self._write_bool(101, 1)  # IO.MV101.DI_ZSC (initially closed)
        self._write_bool(102, 0)  # IO.P101.DI_Run
        self._write_bool(103, 0)  # IO.P102.DI_Run
        
        # Write initial level value (address 104-105, 2 registers for REAL)
        self._write_real(104, self.lit101_pv)
        
        # Write initial alarm states (address 106-109)
        ahh, ah, al, all = self._calculate_alarms(self.lit101_pv)
        self._write_bool(106, ahh)
        self._write_bool(107, ah)
        self._write_bool(108, al)
        self._write_bool(109, all)
        
    def _read_bool(self, address):
        """Read BOOL value from Modbus register (returns 0 or 1)"""
        result = self.context[self.slave_id].getValues(3, address - 1, count=1)
        return result[0]
    
    def _write_bool(self, address, value):
        """Write BOOL value to Modbus register (expects 0 or 1)"""
        self.context[self.slave_id].setValues(3, address - 1, [value])
    
    def _read_real(self, address):
        """Read REAL value from Modbus register (2 registers)"""
        result = self.context[self.slave_id].getValues(3, address - 1, count=2)
        # Convert two 16-bit registers to 32-bit float
        high = result[0]
        low = result[1]
        bytes_data = struct.pack('>HH', high, low)
        return struct.unpack('>f', bytes_data)[0]
    
    def _write_real(self, address, value):
        """Write REAL value to Modbus register (2 registers)"""
        # Convert 32-bit float to two 16-bit registers
        bytes_data = struct.pack('>f', value)
        high, low = struct.unpack('>HH', bytes_data)
        self.context[self.slave_id].setValues(3, address - 1, [high, low])
    
    def _calculate_alarms(self, pv):
        """Calculate level alarms (returns 0 or 1)"""
        ahh = 1 if pv >= self.p["LIT101_AHH"] else 0
        ah = 1 if pv >= self.p["LIT101_AH"] else 0
        al = 1 if pv <= self.p["LIT101_AL"] else 0
        all = 1 if pv <= self.p["LIT101_ALL"] else 0
        return ahh, ah, al, all
    
    def read_outputs_from_plc(self):
        """Read DO commands from Micro820 (address 200-203)"""
        self.io_mv101_do_open = self._read_bool(200)
        self.io_mv101_do_close = self._read_bool(201)
        self.io_p101_do_start = self._read_bool(202)
        self.io_p102_do_start = self._read_bool(203)
    
    def simulate_actuator(self):
        """Simulate actuator behavior (Loopback mode)"""
        # MV101 valve logic
        self.io_mv101_di_zso = self.io_mv101_do_open
        self.io_mv101_di_zsc = self.io_mv101_do_close
        
        # Pump logic (simple loopback)
        self.io_p101_di_run = self.io_p101_do_start
        self.io_p102_di_run = self.io_p102_do_start
    
    def simulate_plant(self):
        """Simulate physical process (T101 tank level dynamics)"""
        h_t101 = 0.0
        
        # MV101 open, water inlet
        if self.io_mv101_di_zso == 1:
            h_t101 += self.p['f_mv101'] / self.p['S_t101']
        
        # Pump running, water outlet
        if self.io_p101_di_run ==  1 or self.io_p102_di_run == 1:
            h_t101 -= self.p['f_p101'] / self.p['S_t101']
        
        # Update level
        self.lit101_pv += h_t101 * self.time_interval
        
        # Boundary limits
        if self.lit101_pv < 0:
            self.lit101_pv = 0.0
        if self.lit101_pv > 1200:
            self.lit101_pv = 1200.0
    
    def write_inputs_to_plc(self):
        """Write DI and AI to Modbus registers for Micro820 to read (address 100-109)"""
        # Write digital inputs (address 100-103)
        self._write_bool(100, self.io_mv101_di_zso)
        self._write_bool(101, self.io_mv101_di_zsc)
        self._write_bool(102, self.io_p101_di_run)
        self._write_bool(103, self.io_p102_di_run)
        
        # Write level value (address 104-105, 2 registers for REAL)
        self._write_real(104, self.lit101_pv)
        
        # Calculate and write alarms (address 106-109)
        ahh, ah, al, all = self._calculate_alarms(self.lit101_pv)
        self._write_bool(106, ahh)
        self._write_bool(107, ah)
        self._write_bool(108, al)
        self._write_bool(109, all)
    
    def run_cycle(self):
        """Execute one complete simulation cycle"""
        # 1. Read DO commands from PLC
        self.read_outputs_from_plc()
        
        # 2. Simulate actuators
        self.simulate_actuator()
        
        # 3. Simulate physical process
        self.simulate_plant()
        
        # 4. Write DI and AI
        self.write_inputs_to_plc()
        
        # Print every 5 seconds (counter-based throttling)
        self.print_counter += 1
        if self.print_counter % 5 == 0:
            print(
                "[Plant1] LIT101={0:.2f}mm | "
                "MV101_DO_Open={1} | MV101_DI_ZSO={2} | "
                "P101_Run={3} | P102_Run={4}".format(
                    self.lit101_pv,
                    self.io_mv101_do_open,
                    self.io_mv101_di_zso,
                    self.io_p101_di_run,
                    self.io_p102_di_run
                )
            )
    
    def start(self):
        """Start simulation loop"""
        print("[Plant Simulator] Starting...")
        while True:
            try:
                self.run_cycle()
                time.sleep(self.time_interval)
            except Exception as e:
                print(f"[Plant Simulator] Error: {e}")
                time.sleep(1)


def run_modbus_server(context):
    """Run Modbus TCP Server"""
    # Device identification
    identity = ModbusDeviceIdentification()
    identity.VendorName = 'SWAT Simulator'
    identity.ProductCode = 'PlantSim Process1'
    identity.VendorUrl = 'http://github.com/bashwork/pymodbus/'
    identity.ProductName = 'SWAT Process1 Simulator'
    identity.ModelName = 'PlantSim V1.0'
    identity.MajorMinorRevision = '1.0.0'
    
    # Start server
    print("[Physical1] Starting Modbus TCP server on 0.0.0.0:502")
    StartTcpServer(context, identity=identity, address=("0.0.0.0", 502))


if __name__ == "__main__":
    # Create Modbus slave context with sequential data block
    # Address range: 1-300 (sufficient for all registers)
    store = ModbusSlaveContext(
        hr=ModbusSequentialDataBlock(1, [0]*400)  # Holding Registers only
    )
    
    # Create Modbus server context
    context = ModbusServerContext(slaves=store, single=True)
    
    # Create plant simulator
    plant_sim = PhysicalSimulator1(context)
    
    # Start Modbus server thread
    server_thread = threading.Thread(target=run_modbus_server, args=(context,), daemon=True)
    server_thread.start()
    
    # Wait for server to start
    time.sleep(2)
    
    # Start simulation loop
    plant_sim.start()

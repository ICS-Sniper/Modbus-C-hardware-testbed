# plant_main.py
from physical1 import PhysicalSimulator1
from physical2 import PhysicalSimulator2
from physical3 import PhysicalSimulator3
from physical4 import PhysicalSimulator4
from physical5 import PhysicalSimulator5
from physical6 import PhysicalSimulator6
from pymodbus.server.sync import StartTcpServer
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext, ModbusSequentialDataBlock
from pymodbus.device import ModbusDeviceIdentification
import threading
import time
import signal
import sys

def run_modbus_server(context, port, process_num):
    """Run Modbus TCP Server on specified port"""
    identity = ModbusDeviceIdentification()
    identity.VendorName = 'SWAT Simulator'
    identity.ProductCode = f'PlantSim{process_num}'
    identity.ProductName = f'SWAT Process{process_num} Simulator'
    identity.ModelName = f'PlantSim V{process_num}.0'
    identity.MajorMinorRevision = '1.0.0'
    
    print(f"[Physical{process_num}] Starting Modbus TCP server on 0.0.0.0:{port}")
    StartTcpServer(context, identity=identity, address=("0.0.0.0", port))

def signal_handler(signum, frame):
    """Handle interrupt signals gracefully"""
    print("\nReceived interrupt signal, shutting down...")
    sys.exit(0)

if __name__ == "__main__":
    # Set up signal handling
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    print("Initializing Physical Simulators\n")
    
    # Create contexts and simulators
    simulators = []
    servers = []
    simulator_threads = []
    
    simulator_classes = {
        1: PhysicalSimulator1, 2: PhysicalSimulator2, 3: PhysicalSimulator3,
        4: PhysicalSimulator4, 5: PhysicalSimulator5, 6: PhysicalSimulator6
    }
    
    for process_num, port in [(1, 502), (2, 503), (3, 504), (4, 505), (5, 506), (6, 507)]:
        # Create Modbus context
        store = ModbusSlaveContext(hr=ModbusSequentialDataBlock(1, [0]*400))
        context = ModbusServerContext(slaves=store, single=True)
        
        # Create simulator based on process number
        simulator_class = simulator_classes[process_num]
        sim = simulator_class(context)
        simulators.append(sim)
        
        # Start Modbus server thread
        server_thread = threading.Thread(
            target=run_modbus_server, 
            args=(context, port, process_num), 
            daemon=True,
            name=f"ModbusServer-P{process_num}"
        )
        server_thread.start()
        servers.append(server_thread)
    
    # Wait for servers to start
    time.sleep(2)
    
    # Start simulation loops
    print("Starting Physical Simulators\n")
    for i, sim in enumerate(simulators, 1):
        sim_thread = threading.Thread(
            target=sim.start,
            daemon=True,
            name=f"PlantSim-P{i}"
        )
        sim_thread.start()
        simulator_threads.append(sim_thread)
        print(f"Started Physical Simulator {i}")
    
    print("\nAll simulators started successfully!")
    print("Press Ctrl+C to stop all simulators\n")
    
    try:
        # Keep main thread alive
        while True:
            time.sleep(1)
            
            # Check if any critical threads have died
            for i, thread in enumerate(servers + simulator_threads, 1):
                if not thread.is_alive():
                    print(f"Warning: Thread {thread.name} has stopped!")
                    
    except KeyboardInterrupt:
        print("\nShutting down plant simulators...")
    except Exception as e:
        print(f"Error in main loop: {e}")
    finally:
        print("Plant simulator stopped.")
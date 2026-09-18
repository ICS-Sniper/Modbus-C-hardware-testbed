# Warm Restart Implementation for Micro820 PLC2

## Overview
This implementation provides a software-triggered system reinitialization capability (warm restart) that allows remote reset of the PLC to its initial state without requiring program redownload or physical intervention.

## Industrial Context
- **Platform**: Allen-Bradley Micro820 PLC
- **Standard Behavior**: Retentive - variables, outputs, and registers persist across power cycles and SCADA disconnects
- **Problem**: In automated testing or recovery scenarios, manual program redownload is impractical
- **Solution**: Industry-standard "Warm Restart Logic" / "Software Reinitialization"

## Files Created

### 1. **utils_warmRestart.py**
Modified version of utils.py with the following additions:
- `SCADA_DATA['HMI.PLANT.Reset_System'] = '0'` - Initial value for reset trigger
- `SCADA_TAGS` entry: `('HMI.PLANT.Reset_System', 962, 1)` - Modbus register mapping (offset 962)
- **Note**: Offset 962 chosen to fit within servers.py holding_registers range (1-999)

### 2. **SCADA_1_warmRestart.py**
Modified version of SCADA_1.py:
- Updated imports to use `utils_warmRestart` instead of `utils`
- No logic changes - automatic integration through modified utils

### 3. **modbus_helpers/servers_warm_restart.py**
Modified version of `modbus_helpers/servers.py`:
- Updated import: `from utils_warmRestart import SCADA_TAGS`
- Enables warm restart support when using pymodbus asynchronous server
- Required if using servers.py for SCADA Modbus server (alternative to SCADA_1.py)

### 4. **trigger_warm_restart.py**
Standalone Python script for triggering warm restart:
- **Deployment**: Linux Gateway (10.8.0.2) or any machine with network access to SCADA
- **Purpose**: Remotely trigger PLC reset without Python SCADA codebase
- **Usage**: `python3 trigger_warm_restart.py --verify`
- Supports custom SCADA IP/port via command-line arguments
- Built-in verification to confirm reset completion

### 5. **Micro820_PLC2_Main_noFIT_warmRestart.st**
Modified version of the PLC Structured Text program with:

#### Variable Addition:
```st
hmiplantresetsystem : BOOL := FALSE;  (* Warm restart trigger from SCADA *)
```

#### SCADA Read Logic:
- New MSG function `MSG_Read_SCADA_962` reads Modbus register 962
- Continuously monitors `HMI.PLANT.Reset_System` tag

#### Warm Restart Logic (Lines 263-494):
Executes when `hmiplantresetsystem = TRUE`:
- Resets all 130+ state variables to initial values
- Returns state machine to State 1 (Idle)
- Resets all equipment to safe initial conditions:
  - All pumps (P201-P208) → Status=1 (Off), Auto=TRUE
  - MV201 valve → Status=1 (Closed), Auto=TRUE
  - All permissives → -1 (all bits set)
  - All shutdowns → 0 (clear)
  - All alarms → FALSE
  - All duty selections → 1 (primary)
- Clears all timers (TON_FIT102_P1_TM through P6_TM)
- Resets all I/O to safe states
- **Auto-clears the reset flag** after completion

## Usage Instructions

### Deployment:
1. **SCADA Server**:
   ```bash
   # Use the warm restart version instead of original
   python SCADA_1_warmRestart.py
   ```

2. **Micro820 PLC**:
   - Import `Micro820_PLC2_Main_noFIT_warmRestart.st` into Connected Components Workbench
   - Download to Micro820 PLC (one-time operation)
   - PLC will now support warm restart functionality

### Triggering a Warm Restart:

#### Method 1: Via Linux Gateway Script (Recommended)
**Network Architecture**:
```
PLC (192.168.137.10)
    ↓ Modbus/TCP → 10.8.0.3:502
Linux Gateway (192.168.137.1 + 10.8.0.2)
    ↓ OpenVPN tunnel
SCADA EC2 (10.8.0.3:502)
```

**On Linux Gateway (10.8.0.2)**:
```bash
# Upload trigger_warm_restart.py to Gateway
scp trigger_warm_restart.py ubuntu@<gateway-ip>:/home/ubuntu/

# SSH to Gateway
ssh ubuntu@<gateway-ip>

# Install dependencies (if not already installed)
pip3 install pymodbus

# Trigger warm restart with verification
python3 trigger_warm_restart.py --verify
```

**Output**:
```
Connecting to SCADA at 10.8.0.3:502...
Connection successful.
Triggering warm restart (writing 1 to register 962)...
Warm restart triggered successfully.
Waiting for PLC to complete reset (1 second)...
Verifying reset completion...
Reset flag value: 0
✓ Warm restart completed successfully (flag auto-cleared).
Connection closed.
```

#### Method 2: Via Direct Modbus Write
```python
from pymodbus.client.sync import ModbusTcpClient

# Connect to SCADA
client = ModbusTcpClient('10.8.0.3', port=502)

# Trigger warm restart
client.write_register(962, 1)  # Write 1 to offset 962

# Wait for reset to complete
import time
time.sleep(0.5)  # One PLC scan cycle

# Verify flag auto-cleared
value = client.read_holding_registers(962, 1)
print(f"Reset complete, flag value: {value.registers[0]}")  # Should be 0
```

#### Method 3: Via Python SCADA Tag Write
```python
from utils_warmRestart import setdata, SCADA_ADDR

# Assuming 'self' is your PLC object
setdata(self, 'HMI.PLANT.Reset_System', SCADA_ADDR, 1)
```

#### Method 4: Via HMI/SCADA Operator Interface
Configure HMI button to write value `1` to tag `HMI.PLANT.Reset_System`

## Technical Details

### Execution Flow:
1. SCADA/HMI writes `1` to Modbus register 962
2. PLC reads register → `hmiplantresetsystem := TRUE`
3. Main program IF block executes warm restart logic (one scan)
4. All variables reset to initial values
5. Reset flag automatically cleared → `hmiplantresetsystem := FALSE`
6. System returns to normal operation in initial state

### Scan Cycle Behavior:
- **Scan 1**: Detect reset trigger
- **Scan 2-3**: Execute reinitialization (may take 1-2 scans depending on complexity)
- **Scan 4+**: Normal operation with fresh initial state

### Safety Considerations:
- All outputs forced to safe states during reset
- State machine returns to Idle (State 1)
- All shutdowns cleared temporarily (permissives will re-evaluate)
- Critical alarm conditions re-trigger immediately post-reset

## Testing Procedure

### 1. Pre-Reset Verification:
```python
# Start system and advance to State 2
setdata(self, 'HMI.PLANT.Start', SCADA_ADDR, 1)
time.sleep(2)

# Verify system running
state =getdata(self, 'HMI.P2.State', SCADA_ADDR, 0)
print(f"System State before reset: {state}")  # Should be 2
```

### 2. Execute Warm Restart:
```python
# Trigger reset
setdata(self, 'HMI.PLANT.Reset_System', SCADA_ADDR, 1)
time.sleep(1)  # Wait for PLC to process
```

### 3. Post-Reset Verification:
```python
# Check state machine
state = getdata(self, 'HMI.P2.State', SCADA_ADDR, 0)
print(f"System State after reset: {state}")  # Should be 1

# Check reset flag auto-cleared
reset_flag = getdata(self, 'HMI.PLANT.Reset_System', SCADA_ADDR, 0)
print(f"Reset flag status: {reset_flag}")  # Should be 0

# Verify equipment initial states
mv201_status = getdata(self, 'HMI.MV201.Status', SCADA_ADDR, 1)
p201_status = getdata(self, 'HMI.P201.Status', SCADA_ADDR, 1)
print(f"MV201: {mv201_status}, P201: {p201_status}")  # Both should be 1
```

## Differences from Cold Restart:
| Feature | Cold Restart | Warm Restart (This Implementation) |
|---------|--------------|-------------------------------------|
| Trigger | Power cycle / program reload | Remote Modbus write |
| Speed | Minutes (CCW download) | < 1 second (1-2 PLC scans) |
| Network | Requires CCW ethernet connection | Uses existing Modbus connection |
| Physical Access | Yes (PLC visit or remote CCW) | No (fully remote) |
| Automation | Not scriptable | Fully scriptable |
| Use Case | Commissioning, major updates | Testing, recovery, automated scenarios |

## Troubleshooting

### Issue: Reset flag doesn't clear
**Cause**: PLC not scanning or Modbus communication failure
**Solution**: 
1. Check PLC Run mode indicator
2. Verify Modbus connection
3. Check SCADA logs for communication errors

### Issue: Variables not resetting
**Cause**: ST program not running the IF block
**Solution**:
1. Verify `hmiplantresetsystem` variable is being read correctly
2. Add ladder logic monitoring to confirm IF block execution
3. Check scan time - may need multiple scans for completion

### Issue: System unstable after reset
**Cause**: External process values not reset (plant still running)
**Solution**: Warm restart resets PLC only. See "Full System Reinitialization" section below for complete chain reset.

## Full System Reinitialization (PLC + SCADA + Plant)

When you need to reset the **entire simulation chain** (not just PLC):

### Network Architecture Context:
```
physical2.py (Plant Simulator, port 503)
    ↔ Modbus I/O
Micro820 PLC (192.168.137.10)
    ↔ Modbus SCADA (port 502)
SCADA_1_warmRestart.py (10.8.0.3:502)
```

### Complete Shutdown Sequence:
1. **Stop SCADA first**:
   ```bash
   # On SCADA EC2 (10.8.0.3)
   # Press Ctrl+C on SCADA_1_warmRestart.py terminal
   ```
   *Reason*: Prevent SCADA from writing stale data during PLC reset

2. **Stop Plant Simulator**:
   ```bash
   # On Plant Simulator host
   # Press Ctrl+C on physical2.py terminal
   ```
   *Reason*: Clear physical process states (tank levels, flows, etc.)

3. **Wait 2 seconds**: Allow all connections to close cleanly

### Complete Startup Sequence:
1. **Start Plant Simulator first**:
   ```bash
   python3 physical2.py
   ```
   *Output*: `[Modbus Server] Starting on 0.0.0.0:503...`
   *Wait*: Until "Plant Simulator 2 Starting..." appears

2. **Start SCADA**:
   ```bash
   python SCADA_1_warmRestart.py
   ```
   *Output*: `No of tags set: XXX` then `Initialization done`
   *Wait*: Until "SCADA main loop starts here" appears

3. **Trigger PLC Warm Restart** (optional but recommended):
   ```bash
   # From Linux Gateway or any client
   python3 trigger_warm_restart.py --verify
   ```
   *Purpose*: Ensure PLC starts from known initial state

4. **Verification**:
   ```python
   # Check all systems in initial state
   from pymodbus.client.sync import ModbusTcpClient
   
   # Check SCADA
   scada = ModbusTcpClient('10.8.0.3', 502)
   state = scada.read_holding_registers(18, 1)  # HMI.P2.State
   print(f"P2 State: {state.registers[0]}")  # Should be 1
   
   # Check Plant
   plant = ModbusTcpClient('<plant-ip>', 503)
   mv201 = plant.read_holding_registers(100, 1)  # MV201 position
   print(f"MV201 ZSC (closed): {mv201.registers[0]}")  # Should be 1
   ```

### Quick Reset Script:
```bash
#!/bin/bash
# save as: full_chain_restart.sh

echo "Stopping SCADA..."
pkill -f SCADA_1_warmRestart.py

echo "Stopping Plant Simulator..."
pkill -f physical2.py

echo "Waiting for cleanup..."
sleep 2

echo "Starting Plant Simulator..."
python3 physical2.py > /tmp/plant.log 2>&1 &
sleep 3

echo "Starting SCADA..."
python SCADA_1_warmRestart.py > /tmp/scada.log 2>&1 &
sleep 5

echo "Triggering PLC warm restart..."
python3 trigger_warm_restart.py --verify

echo "Full chain reinitialization complete."
```

### Why This Order Matters:
- **Plant first**: Provides stable I/O endpoints for PLC to connect to
- **SCADA second**: Initializes all tags before PLC reads them
- **PLC warm restart last**: Ensures PLC state matches fresh SCADA/Plant states
- **Reverse order for shutdown**: Prevents SCADA from logging errors when Plant disconnects

## Maintenance Notes
- **Original files preserved**: `utils.py`, `SCADA_1.py`, `modbus_helpers/servers.py`, `Micro820_PLC2_Main_noFIT.st`
- **Warm restart versions**: Have `_warmRestart` suffix
- **Coexistence**: Both versions can run in same directory
- **Disable warm restart**: Use original files instead of `_warmRestart` versions
- **Register allocation**: Offset 962 chosen to fit within servers.py maximum range (999)

## Author Notes
Implementation follows industry best practices for Allen-Bradley PLC systems:
- Self-clearing flag prevents continuous reset
- Comprehensive variable coverage ensures clean state
- Safe-state forcing protects equipment
- Modbus-compatible for integration with existing SCADA infrastructure

**Created**: 2025-02-16
**PLC Platform**: Allen-Bradley Micro820
**Protocol**: Modbus TCP (SCADA port 502, Plant port 503)

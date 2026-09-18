#!/usr/bin/env python3
"""
Warm Restart Trigger Script for Linux Gateway

This script can be deployed on the Linux Gateway (10.8.0.2) to remotely trigger
a warm restart of the Micro820 PLC via SCADA.

Network Architecture:
  PLC (192.168.137.10)
      ↓ Modbus/TCP → 10.8.0.3:502
  Linux Gateway (192.168.137.1 + 10.8.0.2)
      ↓ OpenVPN tunnel
  SCADA EC2 (10.8.0.3:502)

Usage:
  python3 trigger_warm_restart.py
  python3 trigger_warm_restart.py --verify  # Verify reset completed
"""

import argparse
import time
import sys


def trigger_warm_restart(scada_ip='10.8.0.3', scada_port=502, verify=False):
    """
    Trigger a warm restart of the PLC system.
    
    Args:
        scada_ip: SCADA server IP address (default: 10.8.0.3)
        scada_port: SCADA Modbus port (default: 502)
        verify: If True, verify the reset completed successfully
    
    Returns:
        True if successful, False otherwise
    """
    try:
        from pymodbus.client.sync import ModbusTcpClient
    except ImportError:
        print("ERROR: pymodbus not installed. Install with: pip3 install pymodbus")
        return False
    
    print(f"Connecting to SCADA at {scada_ip}:{scada_port}...")
    client = ModbusTcpClient(scada_ip, port=scada_port)
    
    if not client.connect():
        print(f"ERROR: Could not connect to SCADA at {scada_ip}:{scada_port}")
        return False
    
    print("Connection successful.")
    
    try:
        # Trigger warm restart by writing 1 to offset 962
        print("Triggering warm restart (writing 1 to register 962)...")
        result = client.write_register(962, 1)
        
        if result.isError():
            print(f"ERROR: Failed to write register: {result}")
            return False
        
        print("Warm restart triggered successfully.")
        
        if verify:
            # Wait for PLC to process the reset
            print("Waiting for PLC to complete reset (1 second)...")
            time.sleep(1)
            
            # Verify the reset flag auto-cleared
            print("Verifying reset completion...")
            result = client.read_holding_registers(962, 1)
            
            if result.isError():
                print(f"ERROR: Failed to read register: {result}")
                return False
            
            flag_value = result.registers[0]
            print(f"Reset flag value: {flag_value}")
            
            if flag_value == 0:
                print("✓ Warm restart completed successfully (flag auto-cleared).")
                return True
            else:
                print(f"⚠ WARNING: Reset flag not cleared (value={flag_value}). PLC may still be processing.")
                return False
        else:
            print("Note: Use --verify to confirm reset completion.")
            return True
            
    except Exception as e:
        print(f"ERROR: {e}")
        return False
    finally:
        client.close()
        print("Connection closed.")


def main():
    parser = argparse.ArgumentParser(
        description='Trigger warm restart of Micro820 PLC via SCADA',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic trigger
  python3 trigger_warm_restart.py
  
  # Trigger and verify completion
  python3 trigger_warm_restart.py --verify
  
  # Custom SCADA address
  python3 trigger_warm_restart.py --ip 10.8.0.5 --port 5020
        """
    )
    
    parser.add_argument(
        '--ip',
        type=str,
        default='10.8.0.3',
        help='SCADA server IP address (default: 10.8.0.3)'
    )
    
    parser.add_argument(
        '--port',
        type=int,
        default=502,
        help='SCADA Modbus port (default: 502)'
    )
    
    parser.add_argument(
        '--verify',
        action='store_true',
        help='Verify reset completion after triggering'
    )
    
    args = parser.parse_args()
    
    success = trigger_warm_restart(args.ip, args.port, args.verify)
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

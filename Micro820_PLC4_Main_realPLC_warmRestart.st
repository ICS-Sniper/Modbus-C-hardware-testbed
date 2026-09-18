(*
================================================================================
Micro820 PLC4 Main Program (RO Feed & Dosing Stage)
================================================================================
Converted from plc4.py for real Micro820 PLC execution
================================================================================
*)

PROGRAM Warm_Restart
(*
================================================================================
Warm Restart Logic for PLC4 (RO Feed & Dosing Stage)
================================================================================
Purpose: Software-triggered system reinitialization via Modbus
Industry Standard: Allen-Bradley Micro820 retains variable states across power
cycles and SCADA disconnects. This logic enables remote reset to initial state
without program redownload.

Usage: Write 1 to HMI.PLANT.Reset_System (Modbus register 965) to trigger reset
================================================================================
*)
// HMI.PLANT.Reset_System (offset 965 - Warm Restart Trigger)
MSG_Read_SCADA_965(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_965
);
IF MSG_Read_SCADA_965.Q THEN
    hmiplantresetsystem := SCADA_read_965[1].0;
    msg_write_SCADA_965_enable := TRUE;
ELSE
    msg_write_SCADA_965_enable := FALSE;
END_IF;

IF hmiplantresetsystem THEN
    (* Reset state machine variables *)
    hmip4state := 1;
    hmip4state_prev := 0;
    hmip4permissiveon := TRUE;
    
    (* Reset SCADA control inputs *)
    hmiplantreseton := TRUE;
    hmiplantautoon := TRUE;
    hmiplantautooff := FALSE;
    hmiplantstart := FALSE;
    hmirohppsdon := FALSE;
    
    (* Reset external dependencies *)
    hmimv501status := 1;
    hmimv502status := 1;
    hmimv503status := 1;
    hmimv504status := 1;
    hmip301status := 1;
    hmip302status := 1;
    hmimv301close := FALSE;
    hmimv302close := FALSE;
    hmimv303close := FALSE;
    hmimv304open := FALSE;
    hmip602status := 1;
    hmimv302open := FALSE;
    hmimv304close := FALSE;
    
    (* Reset pumps P401, P402 *)
    hmip401auto := TRUE;
    hmip401reset := FALSE;
    hmip401status := 1;
    hmip401fault := FALSE;
    hmip401avl := TRUE;
    hmip401permissive := -1;
    hmip401msgpermissive := 0;
    hmip401sd := 0;
    hmip401shutdown := 0;
    hmip401msgshutdown := 0;
    
    hmip402auto := TRUE;
    hmip402reset := FALSE;
    hmip402status := 1;
    hmip402fault := FALSE;
    hmip402avl := TRUE;
    hmip402permissive := -1;
    hmip402msgpermissive := 0;
    hmip402sd := 0;
    hmip402shutdown := 0;
    hmip402msgshutdown := 0;
    
    (* Reset pumps P403, P404 *)
    hmip403auto := TRUE;
    hmip403reset := FALSE;
    hmip403status := 1;
    hmip403fault := FALSE;
    hmip403avl := TRUE;
    hmip403permissive := -1;
    hmip403msgpermissive := 0;
    hmip403sd := 0;
    hmip403shutdown := 0;
    hmip403msgshutdown := 0;
    
    hmip404auto := TRUE;
    hmip404reset := FALSE;
    hmip404status := 1;
    hmip404fault := FALSE;
    hmip404avl := TRUE;
    hmip404permissive := -1;
    hmip404msgpermissive := 0;
    hmip404sd := 0;
    hmip404shutdown := 0;
    hmip404msgshutdown := 0;
    
    (* Reset UV401 *)
    hmiuv401auto := TRUE;
    hmiuv401reset := TRUE;
    hmiuv401resetrunhr := FALSE;
    hmiuv401status := 1;
    hmiuv401fault := FALSE;
    hmiuv401avl := TRUE;
    hmiuv401permissive := -1;
    hmiuv401msgpermissive := 0;
    hmiuv401sd := 0;
    hmiuv401shutdown := 0;
    hmiuv401msgshutdown := 0;
    hmiuv401runhr := 0;
    hmiuv401totalrunhr := 0;
    
    (* Reset LIT401 alarms *)
    hmilit401hty := TRUE;
    hmilit401ahh := FALSE;
    hmilit401ah := FALSE;
    hmilit401al := FALSE;
    hmilit401all := FALSE;
    hmilit401pv := 0.0;
    
    (* Reset AIT401, AIT402 alarms *)
    hmiait401hty := TRUE;
    hmiait401ahh := FALSE;
    hmiait401ah := FALSE;
    hmiait401al := FALSE;
    hmiait401all := FALSE;
    
    hmiait402hty := TRUE;
    hmiait402ahh := FALSE;
    hmiait402ah := FALSE;
    hmiait402al := FALSE;
    hmiait402all := FALSE;
    
    (* Reset FIT401 alarms *)
    hmifit401hty := TRUE;
    hmifit401ahh := FALSE;
    hmifit401ah := FALSE;
    hmifit401al := FALSE;
    hmifit401all := FALSE;
    
    (* Reset LS401 *)
    hmils401alarm := FALSE;
    
    (* Reset duty selectors *)
    hmiprofeedduty := 1;
    hmiprofeeddutybothpmpnotavl := FALSE;
    hmiprofeeddutyselectedpmpnotavl := FALSE;
    hmiprofeeddutypumprunning := FALSE;
    
    hmipnahso3orpduty := 1;
    hmipnahso3orpdutybothpmpnotavl := FALSE;
    hmipnahso3orpdutyselectedpmpnotavl := FALSE;
    hmipnahso3orpdutypumprunning := FALSE;
    
    hmiplantresetsystem := FALSE;
END_IF;

SCADA_write_965[1].0 := hmiplantresetsystem;
MSG_Write_SCADA_965(
	IN := msg_write_SCADA_965_enable,
	LocalCfg := LocalCfgWrite_c6,
	LocalAddr := SCADA_write_965
);


PROGRAM Modbus_SCADA_READ_CORE
(*
================================================================================
SCADA Read - Core Tags (Always Read)
================================================================================
*)
// Read common control signals (offsets 0-5: Reset_On, Auto_On, Auto_Off, Ready, Stop, Start)
MSG_Read_SCADA_0_5(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e6,
	LocalAddr := SCADA_read_0_5
);
IF MSG_Read_SCADA_0_5.Q THEN
	hmiplantreseton := SCADA_read_0_5[1].0;
	hmiplantautoon := SCADA_read_0_5[2].0;
	hmiplantautooff := SCADA_read_0_5[3].0;
    hmiplantstart := SCADA_read_0_5[6].0;
END_IF;

// Read MV501 Status (offset 812)
MSG_Read_SCADA_812(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_812
);
IF MSG_Read_SCADA_812.Q THEN
	hmimv501status := ANY_TO_INT(SCADA_read_812[1]);
END_IF;

// Read MV502 Status (offset 821)
MSG_Read_SCADA_821(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_821
);
IF MSG_Read_SCADA_821.Q THEN
	hmimv502status := ANY_TO_INT(SCADA_read_821[1]);
END_IF;

// Read MV503 Status (offset 830)
MSG_Read_SCADA_830(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_830
);
IF MSG_Read_SCADA_830.Q THEN
	hmimv503status := ANY_TO_INT(SCADA_read_830[1]);
END_IF;

// Read MV504 Status (offset 839)
MSG_Read_SCADA_839(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_839
);
IF MSG_Read_SCADA_839.Q THEN
	hmimv504status := ANY_TO_INT(SCADA_read_839[1]);
END_IF;

// Read P301 Status (offset 372)
MSG_Read_SCADA_372(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_372
);
IF MSG_Read_SCADA_372.Q THEN
	hmip301status := ANY_TO_INT(SCADA_read_372[1]);
END_IF;

// Read P302 Status (offset 388)
MSG_Read_SCADA_388(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_388
);
IF MSG_Read_SCADA_388.Q THEN
	hmip302status := ANY_TO_INT(SCADA_read_388[1]);
END_IF;

// Read MV301.Close (offset 435)
MSG_Read_SCADA_435(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_435
);
IF MSG_Read_SCADA_435.Q THEN
	hmimv301close := SCADA_read_435[1].0;
END_IF;

// Read MV302.Open, Close (offsets 443-444)
MSG_Read_SCADA_443_444(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e2,
	LocalAddr := SCADA_read_443_444
);
IF MSG_Read_SCADA_443_444.Q THEN
	hmimv302open := SCADA_read_443_444[1].0;
	hmimv302close := SCADA_read_443_444[2].0;
END_IF;

// Read MV303.Close (offset 453)
MSG_Read_SCADA_453(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_453
);
IF MSG_Read_SCADA_453.Q THEN
	hmimv303close := SCADA_read_453[1].0;
END_IF;

// Read MV304.Open, Close (offsets 461-462)
MSG_Read_SCADA_461_462(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e2,
	LocalAddr := SCADA_read_461_462
);
IF MSG_Read_SCADA_461_462.Q THEN
	hmimv304open := SCADA_read_461_462[1].0;   // offset 461
	hmimv304close := SCADA_read_461_462[2].0;  // offset 462
END_IF;

// Read P602 Status (offset 928)
MSG_Read_SCADA_928(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_928
);
IF MSG_Read_SCADA_928.Q THEN
	hmip602status := ANY_TO_INT(SCADA_read_928[1]);
END_IF;


PROGRAM Modbus_L1_Read
(*
================================================================================
Plant Read - Physical Simulator (192.168.137.1:505)
================================================================================
*)
// P401, P402 feedback (100-101) and LIT401 Pv and alarms (102-107)
MSG_READ_L1_100(
	IN := TRUE, 
	LocalCfg := LocalCfgRead_c3_L1_e8,
	LocalAddr := L1_read_100
);
IF MSG_READ_L1_100.Q THEN
	IO_P401_DI_Run := L1_read_100[1].0;
	IO_P402_DI_Run := L1_read_100[2].0;
	// Convert 2 WORD registers to REAL for LIT401.Pv (102-103)
	tempReal[0] := L1_read_100[3];
	tempReal[1] := L1_read_100[4];
	// Read LIT401 alarms (104-107)
	hmilit401ahh := L1_read_100[5].0;
	hmilit401ah := L1_read_100[6].0;
	hmilit401al := L1_read_100[7].0;
	hmilit401all := L1_read_100[8].0;
	COP_L1_102_103_TO_lit401pv(
		Enable := TRUE,
		Src := tempReal,
		Dest := hmilit401pv,
		Length := 1
	);
END_IF;


PROGRAM Plant_Control
IF hmiplantreseton THEN
    hmip401reset := TRUE;
    hmip402reset := TRUE;
    hmip403reset := TRUE;
    hmip404reset := TRUE;
    hmiuv401reset := TRUE;
END_IF;

IF hmiplantautoon THEN
    hmip401auto := TRUE;
    hmip402auto := TRUE;
    hmip403auto := TRUE;
    hmip404auto := TRUE;
    hmiuv401auto := TRUE;
END_IF;

IF hmiplantautooff THEN
    hmip401auto := FALSE;
    hmip402auto := FALSE;
    hmip403auto := FALSE;
    hmip404auto := FALSE;
    hmiuv401auto := FALSE;
END_IF;


PROGRAM Permissive_Shutdown
(*
================================================================================
Stage 3: Permissive calculations and Shutdown logic for PLC4
================================================================================
*)
hmip4permissiveon := (hmip401avl OR hmip402avl) AND (hmip403avl OR hmip404avl) AND hmiuv401avl;

Mid_FIT401_Tot_Enb := (hmip401status = 2) OR (hmip402status = 2);

TON_FIT401_TM(
	IN := ((hmip401status = 2) OR (hmip402status = 2)) AND hmifit401all,
	PT := T#6s
);

TON_FIT401_P1_TM(
	IN := hmifit401all AND (hmip401status = 2),
	PT := T#6s
);

TON_FIT401_P2_TM(
	IN := hmifit401all AND (hmip402status = 2),
	PT := T#6s
);

(* P401 Permissive calculations *)
hmip401permissive.0 := NOT hmilit401all;
hmip401permissive.1 := (hmimv501status = 2) OR (hmimv502status = 2) OR (hmimv503status = 2) OR (hmimv504status = 2);

hmip401msgpermissive.1 := hmip401permissive.0;
hmip401msgpermissive.2 := FALSE;

(* P401 Shutdown calculations *)
hmip401sd.0 := hmilit401all;
hmip401sd.1 := TON_FIT401_P1_TM.Q;
hmip401sd.2 := (hmip401status = 2) AND (hmimv501status <> 2) AND (hmimv502status <> 2) AND (hmimv503status <> 2) AND (hmimv504status <> 2);

hmip401msgshutdown.1 := hmip401shutdown.0;
hmip401msgshutdown.2 := hmip401shutdown.1;
hmip401msgshutdown.3 := hmip401shutdown.2;
hmip401msgshutdown.4 := hmip401shutdown.3;
hmip401msgshutdown.5 := hmip401shutdown.4;

(* P402 Permissive calculations *)
hmip402permissive.0 := NOT hmilit401all;
hmip402permissive.1 := (hmimv501status = 2) OR (hmimv502status = 2) OR (hmimv503status = 2) OR (hmimv504status = 2);

hmip402msgpermissive.1 := hmip402permissive.0;

(* P402 Shutdown calculations *)
hmip402sd.0 := hmilit401all;
hmip402sd.1 := TON_FIT401_P2_TM.Q;
hmip402sd.2 := (hmip402status = 2) AND (hmimv501status <> 2) AND (hmimv502status <> 2) AND (hmimv503status <> 2) AND (hmimv504status <> 2);

hmip402msgshutdown.1 := hmip402shutdown.0;
hmip402msgshutdown.2 := hmip402shutdown.1;
hmip402msgshutdown.3 := hmip402shutdown.2;
hmip402msgshutdown.4 := hmip402shutdown.3;
hmip402msgshutdown.5 := hmip402shutdown.4;

(* P403 Permissive calculations *)
hmip403permissive.0 := NOT hmils401alarm;
hmip403permissive.1 := (hmip401status = 2) OR (hmip402status = 2);

hmip403msgpermissive.1 := hmip403permissive.0;
hmip403msgpermissive.2 := hmip403permissive.1;

(* P403 Shutdown calculations *)
hmip403sd.0 := hmils401alarm;
hmip403sd.1 := ((hmip401status = 2) OR (hmip402status = 2)) AND hmifit401all;

hmip403msgshutdown.1 := hmip403shutdown.0;
hmip403msgshutdown.2 := hmip403shutdown.1;
hmip403msgshutdown.3 := hmip403shutdown.2;
hmip403msgshutdown.4 := hmip403shutdown.3;
hmip403msgshutdown.5 := hmip403shutdown.4;

(* P404 Permissive calculations *)
hmip404permissive.0 := NOT hmils401alarm;
hmip404permissive.1 := (hmip401status = 2) OR (hmip402status = 2);

hmip404msgpermissive.1 := hmip404permissive.0;
hmip404msgpermissive.2 := hmip404permissive.1;

(* P404 Shutdown calculations *)
hmip404sd.0 := hmils401alarm;
hmip404sd.1 := ((hmip401status = 2) OR (hmip402status = 2)) AND hmifit401all;

hmip404msgshutdown.1 := hmip404shutdown.0;
hmip404msgshutdown.2 := hmip404shutdown.1;
hmip404msgshutdown.3 := hmip404shutdown.2;
hmip404msgshutdown.4 := hmip404shutdown.3;
hmip404msgshutdown.5 := hmip404shutdown.4;

(* UV401 Permissive calculations *)
hmiuv401permissive.0 := (hmip401status = 2) OR (hmip402status = 2);
hmiuv401permissive.1 := hmifit401all;

hmiuv401msgpermissive.1 := hmiuv401permissive.0;
hmiuv401msgpermissive.2 := hmiuv401permissive.1;

(* UV401 Shutdown calculations *)
hmiuv401sd.0 := TON_FIT401_TM.Q;

hmiuv401msgshutdown.1 := hmiuv401shutdown.0;
hmiuv401msgshutdown.2 := hmiuv401shutdown.1;
hmiuv401msgshutdown.3 := hmiuv401shutdown.2;
hmiuv401msgshutdown.4 := hmiuv401shutdown.3;
hmiuv401msgshutdown.5 := hmiuv401shutdown.4;


PROGRAM State_Machine
(*
================================================================================
Stage 5: State machine - RO Feed and Dosing Control (6 states)
================================================================================
Process Description:
State 1:  Standby
State 2:  RO feed pumps starting (wait for MV503 and MV504 open)
State 3:  UV401 starting
State 4:  Normal operation (UV401 running, NAHSO3/ORP dosing active)
State 5:  Shutdown sequence (wait for MV503 and MV504 close)
State 6:  UV401 stopping
================================================================================
*)

CASE hmip4state OF
1:
	hmip4state_prev := hmip4state;
	Mid_UV401_AutoInp := FALSE;
	Mid_P_RO_FEED_DUTY_AutoInp := FALSE;
	Mid_P_NAHSO3_ORP_DUTY_AutoInp := FALSE;
	
	IF hmip4permissiveon AND hmiplantstart THEN
		hmip4state := 2;
	END_IF;

2:
	hmip4state_prev := hmip4state;
	Mid_UV401_AutoInp := FALSE;
	Mid_P_RO_FEED_DUTY_AutoInp := (hmimv503status = 2) AND (hmimv504status = 2);
	Mid_P_NAHSO3_ORP_DUTY_AutoInp := FALSE;
	
	IF hmip401status = 2 THEN
		hmip4state := 3;
	END_IF;

3:
	hmip4state_prev := hmip4state;
	Mid_UV401_AutoInp := TRUE;
	Mid_P_RO_FEED_DUTY_AutoInp := TRUE;
	Mid_P_NAHSO3_ORP_DUTY_AutoInp := FALSE;
	
	IF hmiuv401status = 2 THEN
		hmip4state := 4;
	END_IF;

4:
	hmip4state_prev := hmip4state;
	Mid_UV401_AutoInp := TRUE;
	Mid_P_RO_FEED_DUTY_AutoInp := TRUE;
	
	// SETD logic for NAHSO3/ORP dosing
	IF ((hmip401status = 2) OR (hmip402status = 2)) AND hmiait402ah THEN
		Mid_P_NAHSO3_ORP_DUTY_AutoInp := TRUE;
	ELSIF ((hmip401status <> 2) AND (hmip402status <> 2)) OR hmiait402al THEN
		Mid_P_NAHSO3_ORP_DUTY_AutoInp := FALSE;
	END_IF;
	
	IF hmirohppsdon THEN
		hmip4state := 5;
	END_IF;

5:
	hmip4state_prev := hmip4state;
	Mid_UV401_AutoInp := TRUE;
	Mid_P_RO_FEED_DUTY_AutoInp := (hmimv503status = 1) AND (hmimv504status = 1);
	Mid_P_NAHSO3_ORP_DUTY_AutoInp := FALSE;
	
	IF NOT (hmip401status = 2) THEN
		hmip4state := 6;
	END_IF;

6:
	hmip4state_prev := hmip4state;
	Mid_UV401_AutoInp := FALSE;
	Mid_P_RO_FEED_DUTY_AutoInp := FALSE;
	Mid_P_NAHSO3_ORP_DUTY_AutoInp := FALSE;
	
	IF hmiuv401status = 1 THEN
		hmip4state := 1;
	END_IF;

ELSE
	hmip4state := 1;
END_CASE;


PROGRAM Function_Blocks
(*
================================================================================
Stage 6: Function block execution
================================================================================
*)

(* P_RO_FEED_DUTY Duty Selector *)
P_RO_FEED_DUTY_FB(
    AutoInp := Mid_P_RO_FEED_DUTY_AutoInp,
    Pmp1_Status := hmip401status,
    Pmp1_Avl := hmip401avl,
    Pmp2_Status := hmip402status,
    Pmp2_Avl := hmip402avl,
    Selection := hmiprofeedduty
);
hmiprofeeddutybothpmpnotavl := P_RO_FEED_DUTY_FB.Both_Pmp_Not_Avl;
hmiprofeeddutyselectedpmpnotavl := P_RO_FEED_DUTY_FB.Selected_Pmp_Not_Avl;
hmiprofeeddutypumprunning := P_RO_FEED_DUTY_FB.Pump_Running;

(* P401 Function Block *)
P401_FB(
    Start := P_RO_FEED_DUTY_FB.Start_Pmp1,
    Auto := hmip401auto,
    Reset := hmip401reset,
    Permissive := hmip401permissive,
    SD := hmip401sd,
    DI_Run := IO_P401_DI_Run,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P401_FB.Status <> -99 THEN
    hmip401status := P401_FB.Status;
END_IF;
hmip401fault := P401_FB.Fault;
hmip401avl := P401_FB.Avl;
hmip401shutdown := P401_FB.Shutdown;
IO_P401_DO_Start := P401_FB.DO_Start;

(* P402 Function Block *)
P402_FB(
    Start := P_RO_FEED_DUTY_FB.Start_Pmp2,
    Auto := hmip402auto,
    Reset := hmip402reset,
    Permissive := hmip402permissive,
    SD := hmip402sd,
    DI_Run := IO_P402_DI_Run,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P402_FB.Status <> -99 THEN
    hmip402status := P402_FB.Status;
END_IF;
hmip402fault := P402_FB.Fault;
hmip402avl := P402_FB.Avl;
hmip402shutdown := P402_FB.Shutdown;
IO_P402_DO_Start := P402_FB.DO_Start;

(* UV401 Function Block *)
UV401_FB(
    AutoInp := Mid_UV401_AutoInp,
    Auto := hmiuv401auto,
    Reset := hmiuv401reset,
    Permissive := hmiuv401permissive,
    SD := hmiuv401sd,
    DI_Auto := TRUE,
    DI_Run := FALSE,
    DI_Fault := FALSE
);
IF UV401_FB.Status <> -99 THEN
    hmiuv401status := UV401_FB.Status;
END_IF;
hmiuv401fault := UV401_FB.Fault;
hmiuv401avl := UV401_FB.Avl;
hmiuv401shutdown := UV401_FB.Shutdown;
(* NOTE: RunHr and Total_RunHr are handled in Runtime_Tracking program *)

(* LS401 Switch Function Block *)
LS401_FB(
	DI_LS := FALSE,
	DelayMs := 0
);
hmils401alarm := LS401_FB.Status;

(* P_NAHSO3_ORP_DUTY Duty Selector *)
P_NAHSO3_ORP_DUTY_FB(
    AutoInp := Mid_P_NAHSO3_ORP_DUTY_AutoInp,
    Pmp1_Status := hmip403status,
    Pmp1_Avl := hmip403avl,
    Pmp2_Status := hmip404status,
    Pmp2_Avl := hmip404avl,
    Selection := hmipnahso3orpduty
);
hmipnahso3orpdutybothpmpnotavl := P_NAHSO3_ORP_DUTY_FB.Both_Pmp_Not_Avl;
hmipnahso3orpdutyselectedpmpnotavl := P_NAHSO3_ORP_DUTY_FB.Selected_Pmp_Not_Avl;
hmipnahso3orpdutypumprunning := P_NAHSO3_ORP_DUTY_FB.Pump_Running;

(* P403 Function Block *)
P403_FB(
    Start := P_NAHSO3_ORP_DUTY_FB.Start_Pmp1,
    Auto := hmip403auto,
    Reset := hmip403reset,
    Permissive := hmip403permissive,
    SD := hmip403sd,
    DI_Run := FALSE,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P403_FB.Status <> -99 THEN
    hmip403status := P403_FB.Status;
END_IF;
hmip403fault := P403_FB.Fault;
hmip403avl := P403_FB.Avl;
hmip403shutdown := P403_FB.Shutdown;

(* P404 Function Block *)
P404_FB(
    Start := P_NAHSO3_ORP_DUTY_FB.Start_Pmp2,
    Auto := hmip404auto,
    Reset := hmip404reset,
    Permissive := hmip404permissive,
    SD := hmip404sd,
    DI_Run := FALSE,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P404_FB.Status <> -99 THEN
    hmip404status := P404_FB.Status;
END_IF;
hmip404fault := P404_FB.Fault;
hmip404avl := P404_FB.Avl;
hmip404shutdown := P404_FB.Shutdown;


PROGRAM Modbus_L1_Write
(*
================================================================================
Stage 7: Write outputs to Plant Simulator
================================================================================
*)
// Plant write (200-201) - P401, P402 start commands
L1_write_200[1].0 := IO_P401_DO_Start;
L1_write_200[2].0 := IO_P402_DO_Start;

MSG_WRITE_L1_200(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_L1_e2,
	LocalAddr := L1_write_200
);



PROGRAM Modbus_SCADA_Write
(*
================================================================================
Stage 8: Write status back to SCADA
================================================================================
*)

// Write HMI.P4.State (offset 25) - Independent MSG for each state transition
IF hmip4state_prev > 6 THEN
	SCADA_write_25[1] := ANY_TO_WORD(1);
ELSE
	SCADA_write_25[1] := ANY_TO_WORD(hmip4state);
END_IF;

MSG_P4State_1to2(IN := (hmip4state_prev = 1 AND hmip4state = 2), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_25);
MSG_P4State_2to3(IN := (hmip4state_prev = 2 AND hmip4state = 3), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_25);
MSG_P4State_3to4(IN := (hmip4state_prev = 3 AND hmip4state = 4), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_25);
MSG_P4State_4to5(IN := (hmip4state_prev = 4 AND hmip4state = 5), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_25);
MSG_P4State_5to6(IN := (hmip4state_prev = 5 AND hmip4state = 6), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_25);
MSG_P4State_6to1(IN := (hmip4state_prev = 6 AND hmip4state = 1), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_25);
MSG_P4State_InvalidTo1(IN := (hmip4state_prev > 6), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_25);

// Write LIT401 (offsets 473-478) - AHH, AH, AL, ALL, Pv
SCADA_write_473_478[1].0 := hmilit401ahh;   // offset 473
SCADA_write_473_478[2].0 := hmilit401ah;    // offset 474
SCADA_write_473_478[3].0 := hmilit401al;    // offset 475
SCADA_write_473_478[4].0 := hmilit401all;   // offset 476
COP_LIT401_Pv(
    Enable := TRUE,
    Src := hmilit401pv,
    Dest := SCADA_write_473_478[5],  // offset 477-478 (2 registers for REAL)
    Length := 2
);
MSG_Write_SCADA_473_478(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e6,
	LocalAddr := SCADA_write_473_478
);

// Write P401 status (offsets 479-494) - 16 tags
SCADA_write_479_494[1].0 := hmip401auto;
SCADA_write_479_494[2] := ANY_TO_WORD(hmip401permissive);
SCADA_write_479_494[3] := ANY_TO_WORD(hmip401msgpermissive);
SCADA_write_479_494[4] := ANY_TO_WORD(hmip401sd);
SCADA_write_479_494[5] := ANY_TO_WORD(hmip401msgshutdown);
SCADA_write_479_494[6].0 := hmip401reset;
SCADA_write_479_494[7] := 0;  // Reset_RunHr
SCADA_write_479_494[8].0 := hmip401avl;
SCADA_write_479_494[9].0 := hmip401fault;
SCADA_write_479_494[10].0 := FALSE;  // FTS
SCADA_write_479_494[11].0 := FALSE;  // FTR
SCADA_write_479_494[12] := ANY_TO_WORD(hmiuv401runhr);  // RunHr
SCADA_write_479_494[13] := ANY_TO_WORD(hmiuv401totalrunhr);  // Total_RunHr
SCADA_write_479_494[14] := ANY_TO_WORD(hmip401shutdown);
SCADA_write_479_494[15].0 := FALSE;  // Pump_Running
SCADA_write_479_494[16] := ANY_TO_WORD(hmip401status);
MSG_Write_SCADA_479_494(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e16,
	LocalAddr := SCADA_write_479_494
);

// Write P402 status (offsets 495-510) - 16 tags
SCADA_write_495_510[1].0 := hmip402auto;
SCADA_write_495_510[2] := ANY_TO_WORD(hmip402permissive);
SCADA_write_495_510[3] := ANY_TO_WORD(hmip402msgpermissive);
SCADA_write_495_510[4] := ANY_TO_WORD(hmip402sd);
SCADA_write_495_510[5] := ANY_TO_WORD(hmip402msgshutdown);
SCADA_write_495_510[6].0 := hmip402reset;
SCADA_write_495_510[7] := 0;  // Reset_RunHr
SCADA_write_495_510[8].0 := hmip402avl;
SCADA_write_495_510[9].0 := hmip402fault;
SCADA_write_495_510[10].0 := FALSE;  // FTS
SCADA_write_495_510[11].0 := FALSE;  // FTR
SCADA_write_495_510[12] := 0;  // RunHr
SCADA_write_495_510[13] := 0;  // Total_RunHr
SCADA_write_495_510[14] := ANY_TO_WORD(hmip402shutdown);
SCADA_write_495_510[15].0 := FALSE;  // Pump_Running
SCADA_write_495_510[16] := ANY_TO_WORD(hmip402status);
MSG_Write_SCADA_495_510(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e16,
	LocalAddr := SCADA_write_495_510
);

// Write UV401 status (offsets 543-555) - 13 tags
SCADA_write_543_555[1].0 := hmiuv401auto;
SCADA_write_543_555[2].0 := hmiuv401avl;
SCADA_write_543_555[3].0 := hmiuv401reset;
SCADA_write_543_555[4].0 := FALSE;
SCADA_write_543_555[5].0 := FALSE;
SCADA_write_543_555[6] := ANY_TO_WORD(hmiuv401runhr);
SCADA_write_543_555[7].0 := hmiuv401resetrunhr;
SCADA_write_543_555[8] := ANY_TO_WORD(hmiuv401permissive);
SCADA_write_543_555[9] := ANY_TO_WORD(hmiuv401msgpermissive);
SCADA_write_543_555[10] := ANY_TO_WORD(hmiuv401sd);
SCADA_write_543_555[11] := ANY_TO_WORD(hmiuv401msgshutdown);
SCADA_write_543_555[12] := ANY_TO_WORD(hmiuv401shutdown);
SCADA_write_543_555[13] := ANY_TO_WORD(hmiuv401status);
MSG_Write_SCADA_543_555(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e13,
	LocalAddr := SCADA_write_543_555
);

// Write P_NAHSO3_ORP_DUTY status (offsets 556-559)
SCADA_write_556_559[1] := ANY_TO_WORD(hmipnahso3orpduty);           // offset 556 (Selection)
SCADA_write_556_559[2].0 := hmipnahso3orpdutybothpmpnotavl;         // offset 557
SCADA_write_556_559[3].0 := hmipnahso3orpdutyselectedpmpnotavl;     // offset 558
SCADA_write_556_559[4].0 := hmipnahso3orpdutypumprunning;           // offset 559
MSG_Write_SCADA_556_559(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e4,
	LocalAddr := SCADA_write_556_559
);

// Write P_RO_FEED_DUTY status (offsets 560-563)
SCADA_write_560_563[1] := ANY_TO_WORD(hmiprofeedduty);              // offset 560 (Selection)
SCADA_write_560_563[2].0 := hmiprofeeddutybothpmpnotavl;            // offset 561
SCADA_write_560_563[3].0 := hmiprofeeddutyselectedpmpnotavl;        // offset 562
SCADA_write_560_563[4].0 := hmiprofeeddutypumprunning;              // offset 563
MSG_Write_SCADA_560_563(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e4,
	LocalAddr := SCADA_write_560_563
);

// Write P403 status (offsets 511-526) - 16 tags
SCADA_write_511_526[1].0 := hmip403auto;
SCADA_write_511_526[2] := ANY_TO_WORD(hmip403permissive);
SCADA_write_511_526[3] := ANY_TO_WORD(hmip403msgpermissive);
SCADA_write_511_526[4] := ANY_TO_WORD(hmip403sd);
SCADA_write_511_526[5] := ANY_TO_WORD(hmip403msgshutdown);
SCADA_write_511_526[6].0 := hmip403reset;
SCADA_write_511_526[7] := 0;  // Reset_RunHr
SCADA_write_511_526[8].0 := hmip403avl;
SCADA_write_511_526[9].0 := hmip403fault;
SCADA_write_511_526[10].0 := FALSE;  // FTS
SCADA_write_511_526[11].0 := FALSE;  // FTR
SCADA_write_511_526[12] := 0;  // RunHr
SCADA_write_511_526[13] := 0;  // Total_RunHr
SCADA_write_511_526[14] := ANY_TO_WORD(hmip403shutdown);
SCADA_write_511_526[15].0 := FALSE;  // Pump_Running
SCADA_write_511_526[16] := ANY_TO_WORD(hmip403status);
MSG_Write_SCADA_511_526(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e16,
	LocalAddr := SCADA_write_511_526
);

// Write P404 status (offsets 527-542) - 16 tags
SCADA_write_527_542[1].0 := hmip404auto;
SCADA_write_527_542[2] := ANY_TO_WORD(hmip404permissive);
SCADA_write_527_542[3] := ANY_TO_WORD(hmip404msgpermissive);
SCADA_write_527_542[4] := ANY_TO_WORD(hmip404sd);
SCADA_write_527_542[5] := ANY_TO_WORD(hmip404msgshutdown);
SCADA_write_527_542[6].0 := hmip404reset;
SCADA_write_527_542[7] := 0;  // Reset_RunHr
SCADA_write_527_542[8].0 := hmip404avl;
SCADA_write_527_542[9].0 := hmip404fault;
SCADA_write_527_542[10].0 := FALSE;  // FTS
SCADA_write_527_542[11].0 := FALSE;  // FTR
SCADA_write_527_542[12] := 0;  // RunHr
SCADA_write_527_542[13] := 0;  // Total_RunHr
SCADA_write_527_542[14] := ANY_TO_WORD(hmip404shutdown);
SCADA_write_527_542[15].0 := FALSE;  // Pump_Running
SCADA_write_527_542[16] := ANY_TO_WORD(hmip404status);
MSG_Write_SCADA_527_542(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e16,
	LocalAddr := SCADA_write_527_542
);


PROGRAM Clock_Pulse_Generator
(*
================================================================================
Clock Pulse Generator for PLC4
================================================================================
Purpose: Generate periodic pulse signals for runtime tracking

Sec_P:  Pulse signal that transitions TRUE once per second
        Used for incrementing UV401 run hour counter via seconds accumulation
        
Implementation: Uses TON timer with self-resetting logic to generate
                periodic pulses. Rising edge detection ensures clean
                single-scan pulse outputs.
================================================================================
*)

(* 1-Second Pulse Generator *)
TON_1Sec(IN := NOT TON_1Sec.Q, PT := T#1s);
R_TRIG_1Sec(CLK := TON_1Sec.Q);
Sec_P := R_TRIG_1Sec.Q;

(*
================================================================================
Runtime Tracking for UV401
================================================================================
Purpose: Track run hours and total run hours for UV401 lamp
using the 1-second pulse from Clock_Pulse_Generator

Logic: Accumulate seconds when UV401 is running (status = 2)
       When seconds reach 3600 (1 hour), increment RunHr and Total_RunHr
       Reset_RunHr signal clears current session hours only
================================================================================
*)

// UV401 run hour tracking - accumulate seconds when running
IF Sec_P AND (hmiuv401status = 2) THEN
    UV401_Sec_Counter := UV401_Sec_Counter + 1;
END_IF;

// When 3600 seconds (1 hour) accumulated, increment run hours
IF UV401_Sec_Counter >= 3600 THEN
    hmiuv401runhr := hmiuv401runhr + 1;
    hmiuv401totalrunhr := hmiuv401totalrunhr + 1;
    UV401_Sec_Counter := 0;  // Reset second counter
END_IF;

// Reset UV401 run hour if requested (only current session hours, not total)
IF hmiuv401resetrunhr THEN
    hmiuv401runhr := 0;
    UV401_Sec_Counter := 0;  // Also reset second counter
END_IF;

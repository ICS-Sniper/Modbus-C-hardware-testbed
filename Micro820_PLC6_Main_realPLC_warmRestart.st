(*
================================================================================
Micro820 PLC6 Main Program (Product Water Stage)
================================================================================
Converted from plc6.py for real Micro820 PLC execution  
Corrected version - SCADA reads only external dependencies, not internal calculations
================================================================================
*)

PROGRAM Warm_Restart
(*
================================================================================
Warm Restart Logic for PLC6 (Product Water Stage)
================================================================================
Purpose: Software-triggered system reinitialization via Modbus
Industry Standard: Allen-Bradley Micro820 retains variable states across power
cycles and SCADA disconnects. This logic enables remote reset to initial state
without program redownload.

Usage: Write 1 to HMI.PLANT.Reset_System (Modbus register 967) to trigger reset
================================================================================
*)
// HMI.PLANT.Reset_System (offset 967 - Warm Restart Trigger)
MSG_Read_SCADA_967(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_967
);
IF MSG_Read_SCADA_967.Q THEN
    hmiplantresetsystem := SCADA_read_967[1].0;
    msg_write_SCADA_967_enable := TRUE;
ELSE
    msg_write_SCADA_967_enable := FALSE;
END_IF;

IF hmiplantresetsystem THEN
    (* Reset state machine variables *)
    hmip6state := 1;
    hmip6state_prev := 0;
    hmip6permissiveon := TRUE;
    
    (* Reset SCADA control inputs *)
    hmiplantreseton := TRUE;
    hmiplantautoon := TRUE;
    hmiplantautooff := FALSE;
    hmiplantstart := FALSE;
    hmiplantstop := FALSE;
    hmiplantcriticalsdon := FALSE;
    
    (* Reset external dependencies *)
    hmilit101ahh := FALSE;
    hmiait202pv := 0.0;
    hmip301status := 1;
    hmip302status := 1;
    hmimv301open := TRUE;
    hmimv301close := FALSE;
    hmimv302close := FALSE;
    hmimv303open := TRUE;
    hmimv303close := FALSE;
    hmimv304close := FALSE;
    hmimv304open := TRUE;
    hmip401status := 1;
    hmip402status := 1;
    hmip501status := 1;
    hmip502status := 1;
    hmimv501open := TRUE;
    hmimv501close := FALSE;
    hmimv502open := TRUE;
    hmimv502close := FALSE;
    hmimv503open := TRUE;
    hmimv503close := FALSE;
    hmimv504open := TRUE;
    hmimv504close := FALSE;
    
    (* Reset level switches *)
    hmilsl601alarm := FALSE;
    hmilsl601delay := 0;
    hmilsl602alarm := FALSE;
    hmilsl602delay := 0;
    hmilsl603alarm := FALSE;
    hmilsl603delay := 0;
    hmilsh601alarm := FALSE;
    hmilsh601delay := 0;
    hmilsh602alarm := FALSE;
    hmilsh602delay := 0;
    hmilsh603alarm := FALSE;
    hmilsh603delay := 0;
    
    (* Reset P601 *)
    hmip601auto := TRUE;
    hmip601reset := FALSE;
    hmip601resetrunhr := FALSE;
    hmip601status := 1;
    hmip601fault := FALSE;
    hmip601avl := TRUE;
    hmip601permissive := -1;
    hmip601msgpermissive := 0;
    hmip601sd := 0;
    hmip601shutdown := 0;
    hmip601msgshutdown := 0;
	
    (* Reset P602 *)
    hmip602auto := TRUE;
    hmip602reset := FALSE;
    hmip602status := 1;
    hmip602fault := FALSE;
    hmip602avl := TRUE;
    hmip602permissive := -1;
    hmip602msgpermissive := 0;
    hmip602sd := 0;
    hmip602shutdown := 0;
    hmip602msgshutdown := 0;
    
    (* Reset P603 *)
    hmip603auto := TRUE;
    hmip603reset := FALSE;
    hmip603status := 1;
    hmip603fault := FALSE;
    hmip603avl := TRUE;
    hmip603permissive := -1;
    hmip603msgpermissive := 0;
    hmip603sd := 0;
    hmip603shutdown := 0;
    hmip603msgshutdown := 0;
    
    (* Reset intermediate signals *)
    hmimidp602autoinp := 0;
    hmimidp603autoinp := 0;
    Mid_P601_AutoInp := FALSE;
    Mid_P602_AutoInp := FALSE;
    Mid_P603_AutoInp := FALSE;
    Mid_P_PERMEATE_SR := FALSE;
    
    hmiplantresetsystem := FALSE;
END_IF;

SCADA_write_967[1].0 := hmiplantresetsystem;
MSG_Write_SCADA_967(
	IN := msg_write_SCADA_967_enable,
	LocalCfg := LocalCfgWrite_c6_e1,
	LocalAddr := SCADA_write_967
);

PROGRAM Modbus_SCADA_READ_CORE
(*
================================================================================
SCADA Read - Core Tags (Always Read)
================================================================================
*)
// Read offsets 0-6: Reset_On, Auto_On, Auto_Off, Ready, Stop, Start, Critical_SD_On
MSG_Read_SCADA_0_6(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e7,
	LocalAddr := SCADA_read_0_6
);
IF MSG_Read_SCADA_0_6.Q THEN
	hmiplantreseton := SCADA_read_0_6[1].0;
	hmiplantautoon := SCADA_read_0_6[2].0;
	hmiplantautooff := SCADA_read_0_6[3].0;
    hmiplantstop := SCADA_read_0_6[5].0;
    hmiplantstart := SCADA_read_0_6[6].0;
    hmiplantcriticalsdon := SCADA_read_0_6[7].0;
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

// Read MV301.Open, Close (offsets 434-435)
MSG_Read_SCADA_434_435(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e2,
	LocalAddr := SCADA_read_434_435
);
IF MSG_Read_SCADA_434_435.Q THEN
	hmimv301open := SCADA_read_434_435[1].0;
	hmimv301close := SCADA_read_434_435[2].0;
END_IF;

// Read MV302.Close (offset 444)
MSG_Read_SCADA_444(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_444
);
IF MSG_Read_SCADA_444.Q THEN
	hmimv302close := SCADA_read_444[1].0;
END_IF;

// Read MV303.Open, Close (offsets 452-453)
MSG_Read_SCADA_452_453(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e2,
	LocalAddr := SCADA_read_452_453
);
IF MSG_Read_SCADA_452_453.Q THEN
	hmimv303open := SCADA_read_452_453[1].0;
	hmimv303close := SCADA_read_452_453[2].0;
END_IF;

// Read MV304.Open, Close (offsets 461-462)
MSG_Read_SCADA_461_462(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e2,
	LocalAddr := SCADA_read_461_462
);
IF MSG_Read_SCADA_461_462.Q THEN
	hmimv304open := SCADA_read_461_462[1].0;
	hmimv304close := SCADA_read_461_462[2].0;
END_IF;

// Read P401 Status (offset 494)
MSG_Read_SCADA_494(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_494
);
IF MSG_Read_SCADA_494.Q THEN
	hmip401status := ANY_TO_INT(SCADA_read_494[1]);
END_IF;

// Read P402 Status (offset 510)
MSG_Read_SCADA_510(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_510
);
IF MSG_Read_SCADA_510.Q THEN
	hmip402status := ANY_TO_INT(SCADA_read_510[1]);
END_IF;

// Read P501 Status (offset 849)
MSG_Read_SCADA_849(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_849
);
IF MSG_Read_SCADA_849.Q THEN
	hmip501status := ANY_TO_INT(SCADA_read_849[1]);
END_IF;

// Read P502 Status (offset 868)
MSG_Read_SCADA_868(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_868
);
IF MSG_Read_SCADA_868.Q THEN
	hmip502status := ANY_TO_INT(SCADA_read_868[1]);
END_IF;

// Read MV501.Open, Close (offsets 815-816)
MSG_Read_SCADA_815_816(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e2,
	LocalAddr := SCADA_read_815_816
);
IF MSG_READ_SCADA_815_816.Q THEN
	hmimv501open := SCADA_read_815_816[1].0;
	hmimv501close := SCADA_read_815_816[2].0;
END_IF;

// Read MV502.Open, Close (offsets 824-825)
MSG_Read_SCADA_824_825(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e2,
	LocalAddr := SCADA_read_824_825
);
IF MSG_Read_SCADA_824_825.Q THEN
	hmimv502open := SCADA_read_824_825[1].0;
	hmimv502close := SCADA_read_824_825[2].0;
END_IF;

// Read MV503.Open, Close (offsets 833-834)
MSG_Read_SCADA_833_834(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e2,
	LocalAddr := SCADA_read_833_834
);
IF MSG_Read_SCADA_833_834.Q THEN
	hmimv503open := SCADA_read_833_834[1].0;
	hmimv503close := SCADA_read_833_834[2].0;
END_IF;

// Read MV504.Open, Close (offsets 842-843)
MSG_Read_SCADA_842_843(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e2,
	LocalAddr := SCADA_read_842_843
);
IF MSG_Read_SCADA_842_843.Q THEN
	hmimv504open := SCADA_read_842_843[1].0;
	hmimv504close := SCADA_read_842_843[2].0;
END_IF;


PROGRAM Modbus_SCADA_READ_S2_ST
(*
================================================================================
SCADA Read - State 2 Specific Tags
================================================================================
These are read conditionally when hmip6state = 2 in plc6.py fetchData()
================================================================================
*)
IF hmip6state = 2 THEN
	// Read AIT202.Pv (offset 313, 2 registers for REAL)
	MSG_Read_SCADA_313(
		IN := TRUE,
		LocalCfg := LocalCfgRead_c3_e2,
		LocalAddr := SCADA_read_313
	);
	IF MSG_Read_SCADA_313.Q THEN
    	tempReal[0] := SCADA_read_313[1];
    	tempReal[1] := SCADA_read_313[2];
		COP_313_TO_AIT202pv(
		    Enable := TRUE,
		    Src := tempReal,
		    Dest := hmiait202pv,
		    Length := 1
		);
	END_IF;
	
	// Read LIT101.AHH (offset 47)
	MSG_Read_SCADA_47(
		IN := TRUE,
		LocalCfg := LocalCfgRead_c3_e1,
		LocalAddr := SCADA_read_47
	);
	IF MSG_Read_SCADA_47.Q THEN
		hmilit101ahh := SCADA_read_47[1].0;
	END_IF;
	
	// Read Mid_P602_AutoInp (offset 330)
	MSG_Read_SCADA_330(
		IN := TRUE,
		LocalCfg := LocalCfgRead_c3_e1,
		LocalAddr := SCADA_read_330
	);
	IF MSG_Read_SCADA_330.Q THEN
		hmimidp602autoinp := ANY_TO_INT(SCADA_read_330[1]);
		hmimidp603autoinp := ANY_TO_INT(SCADA_read_330[1]);  // P603 uses same signal
	END_IF;
END_IF;


PROGRAM Modbus_L1_Read
(*
================================================================================
L1 Read - Physical Simulator Feedback (192.168.137.1:507)
================================================================================
Physical6.py Modbus mapping:
  - 100-108: P601/P602/P603 DI (Auto, Run, Fault)
  - 109-114: Level switches (LSL601/602/603, LSH601/602/603)
================================================================================
*)
MSG_READ_L1_100(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_L1_e15,
	LocalAddr := L1_read_100
);
IF MSG_READ_L1_100.Q THEN
	IO_P601_DI_Auto := L1_read_100[1].0;
	IO_P601_DI_Run := L1_read_100[2].0;
	IO_P601_DI_Fault := L1_read_100[3].0;
	IO_P602_DI_Auto := L1_read_100[4].0;
	IO_P602_DI_Run := L1_read_100[5].0;
	IO_P602_DI_Fault := L1_read_100[6].0;
	IO_P603_DI_Auto := L1_read_100[7].0;
	IO_P603_DI_Run := L1_read_100[8].0;
	IO_P603_DI_Fault := L1_read_100[9].0;
	IO_LSL601_Alarm := L1_read_100[10].0;
	IO_LSL602_Alarm := L1_read_100[11].0;
	IO_LSL603_Alarm := L1_read_100[12].0;
	IO_LSH601_Alarm := L1_read_100[13].0;
	IO_LSH602_Alarm := L1_read_100[14].0;
	IO_LSH603_Alarm := L1_read_100[15].0;
END_IF;


PROGRAM Plant_Control
(*
================================================================================
Plant Control - Reset and Auto commands
================================================================================
*)
IF hmiplantreseton THEN
    hmip601reset := TRUE;
    hmip602reset := TRUE;
    hmip603reset := TRUE;
END_IF;

IF hmiplantautoon THEN
    hmip601auto := TRUE;
    hmip602auto := TRUE;
    hmip603auto := TRUE;
END_IF;

IF hmiplantautooff THEN
    hmip601auto := FALSE;
    hmip602auto := FALSE;
    hmip603auto := FALSE;
END_IF;


PROGRAM Permissive_Shutdown
(*
================================================================================
Permissive and Shutdown Logic for PLC6
================================================================================
*)
// P6.Permissive_On calculation
hmip6permissiveon := hmip601avl AND hmip602avl AND hmip603avl;

// P601 Permissive
hmip601permissive.0 := NOT hmilsl601alarm;

hmip601msgpermissive.1 := hmip601permissive.0;

// P601 Shutdown
hmip601sd.0 := hmilsl601alarm;

hmip601msgshutdown.1 := hmip601shutdown.0;
hmip601msgshutdown.2 := hmip601shutdown.1;
hmip601msgshutdown.3 := hmip601shutdown.2;
hmip601msgshutdown.4 := hmip601shutdown.3;
hmip601msgshutdown.5 := hmip601shutdown.4;

// P602 Permissive
hmip602permissive.0 := NOT hmilsl602alarm;

hmip602msgpermissive.1 := hmip602permissive.0;

// P602 Shutdown - SD[0] = 0 per plc6.py
hmip602sd.0 := FALSE;

hmip602msgshutdown.1 := hmip602shutdown.0;
hmip602msgshutdown.2 := hmip602shutdown.1;
hmip602msgshutdown.3 := hmip602shutdown.2;
hmip602msgshutdown.4 := hmip602shutdown.3;
hmip602msgshutdown.5 := hmip602shutdown.4;

// P603 Permissive
hmip603permissive.0 := NOT hmilsl603alarm;

hmip603msgpermissive.1 := hmip603permissive.0;

// P603 Shutdown
hmip603sd.0 := hmilsl603alarm;

hmip603msgshutdown.1 := hmip603shutdown.0;
hmip603msgshutdown.2 := hmip603shutdown.1;
hmip603msgshutdown.3 := hmip603shutdown.2;
hmip603msgshutdown.4 := hmip603shutdown.3;
hmip603msgshutdown.5 := hmip603shutdown.4;


PROGRAM State_Machine
(*
================================================================================
State Machine - Product Water Control (2 states)
================================================================================
Process Description:
State 1: Stopped - All pumps off
State 2: Running - P601 controlled by SETD logic, P602/P603 by external signals
================================================================================
*)

// Force stop conditions
IF hmiplantstop OR hmiplantcriticalsdon THEN
	hmip6state := 1;
END_IF;

CASE hmip6state OF
1:
	hmip6state_prev := hmip6state;
	Mid_P601_AutoInp := FALSE;
	Mid_P602_AutoInp := FALSE;
	Mid_P603_AutoInp := FALSE;
	
	IF hmip6permissiveon AND hmiplantstart THEN
		hmip6state := 2;
	END_IF;

2:
	hmip6state_prev := hmip6state;
	
	// SETD logic for P601 (Mid_P_PERMEATE_SR)
	// Set condition: LSH601 AND AIT202>=7 AND NOT LIT101.AHH
	// Reset condition: LIT101.AHH OR LSL601 OR AIT202<7
	IF hmilsh601alarm AND (hmiait202pv >= 7.0) AND (NOT hmilit101ahh) THEN
		Mid_P_PERMEATE_SR := TRUE;
	ELSIF hmilit101ahh OR hmilsl601alarm OR (hmiait202pv < 7.0) THEN
		Mid_P_PERMEATE_SR := FALSE;
	END_IF;
	
	Mid_P601_AutoInp := Mid_P_PERMEATE_SR;
	Mid_P602_AutoInp := (hmimidp602autoinp = 1);  // Signal from P3, UF
	Mid_P603_AutoInp := (hmimidp603autoinp = 1);  // Same signal as P602
	
ELSE
	hmip6state := 1;
END_CASE;


PROGRAM Function_Blocks
(*
================================================================================
Function Block Execution - Level Switches and Pumps
================================================================================
*)

// LSL601 Function Block
LSL601_FB(
    DI_LS := IO_LSL601_Alarm,
    DelayMs := hmilsl601delay
);
hmilsl601alarm := LSL601_FB.Status;

// LSL602 Function Block
LSL602_FB(
    DI_LS := IO_LSL602_Alarm,
    DelayMs := hmilsl602delay
);
hmilsl602alarm := LSL602_FB.Status;

// LSL603 Function Block
LSL603_FB(
    DI_LS := IO_LSL603_Alarm,
    DelayMs := hmilsl603delay
);
hmilsl603alarm := LSL603_FB.Status;

// LSH601 Function Block
LSH601_FB(
    DI_LS := IO_LSH601_Alarm,
    DelayMs := hmilsh601delay
);
hmilsh601alarm := LSH601_FB.Status;

// LSH602 Function Block
LSH602_FB(
    DI_LS := IO_LSH602_Alarm,
    DelayMs := hmilsh602delay
);
hmilsh602alarm := LSH602_FB.Status;

// LSH603 Function Block
LSH603_FB(
    DI_LS := IO_LSH603_Alarm,
    DelayMs := hmilsh603delay
);
hmilsh603alarm := LSH603_FB.Status;

// P601 Function Block
P601_FB(
    Start := Mid_P601_AutoInp,
    Auto := hmip601auto,
    Reset := hmip601reset,
    Permissive := hmip601permissive,
    SD := hmip601sd,
    DI_Run := IO_P601_DI_Run,
    DI_Auto := IO_P601_DI_Auto,
    DI_Fault := IO_P601_DI_Fault,
    Avl_Init := hmip601avl,
    Fault_Init := hmip601fault,
    Shutdown_Init := hmip601shutdown
);
IF P601_FB.Status <> -99 THEN
    hmip601status := P601_FB.Status;
END_IF;
hmip601fault := P601_FB.Fault;
hmip601avl := P601_FB.Avl;
hmip601shutdown := P601_FB.Shutdown;
IO_P601_DO_Start := P601_FB.DO_Start;

// P602 Function Block
P602_FB(
    Start := Mid_P602_AutoInp,
    Auto := hmip602auto,
    Reset := hmip602reset,
    Permissive := hmip602permissive,
    SD := hmip602sd,
    DI_Run := IO_P602_DI_Run,
    DI_Auto := IO_P602_DI_Auto,
    DI_Fault := IO_P602_DI_Fault,
    Avl_Init := hmip602avl,
    Fault_Init := hmip602fault,
    Shutdown_Init := hmip602shutdown
);
IF P602_FB.Status <> -99 THEN
    hmip602status := P602_FB.Status;
END_IF;
hmip602fault := P602_FB.Fault;
hmip602avl := P602_FB.Avl;
hmip602shutdown := P602_FB.Shutdown;
IO_P602_DO_Start := P602_FB.DO_Start;

// P603 Function Block
P603_FB(
    Start := Mid_P603_AutoInp,
    Auto := hmip603auto,
    Reset := hmip603reset,
    Permissive := hmip603permissive,
    SD := hmip603sd,
    DI_Run := IO_P603_DI_Run,
    DI_Auto := IO_P603_DI_Auto,
    DI_Fault := IO_P603_DI_Fault,
    Avl_Init := hmip603avl,
    Fault_Init := hmip603fault,
    Shutdown_Init := hmip603shutdown
);
IF P603_FB.Status <> -99 THEN
    hmip603status := P603_FB.Status;
END_IF;
hmip603fault := P603_FB.Fault;
hmip603avl := P603_FB.Avl;
hmip603shutdown := P603_FB.Shutdown;
IO_P603_DO_Start := P603_FB.DO_Start;


PROGRAM Modbus_L1_Write
(*
================================================================================
Stage 7: Write outputs to Plant Simulator
================================================================================
*)
L1_write_200[1].0 := IO_P601_DO_Start;
L1_write_200[2].0 := IO_P602_DO_Start;
L1_write_200[3].0 := IO_P603_DO_Start;

MSG_WRITE_L1_200(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_L1_e3,
	LocalAddr := L1_write_200
);


PROGRAM Modbus_SCADA_WRITE
(*
================================================================================
Stage 8: Write status back to SCADA
================================================================================
*)
// Write P6.Permissive_On (offset 870)
SCADA_write_870[1].0 := hmip6permissiveon;
MSG_Write_SCADA_870(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c6_e1,
	LocalAddr := SCADA_write_870
);

// Write P6.State (offset 35) - Independent MSG for each state transition
IF hmiplantstop OR hmiplantcriticalsdon THEN
	SCADA_write_35[1] := ANY_TO_WORD(1);
ELSIF hmip6state_prev > 2 THEN
	SCADA_write_35[1] := ANY_TO_WORD(1);
ELSE
	SCADA_write_35[1] := ANY_TO_WORD(hmip6state);
END_IF;

MSG_P6State_StopOrCriticalTo1(
	IN := (hmiplantstop OR hmiplantcriticalsdon),
	LocalCfg := LocalCfgWrite_c6_e1,
	LocalAddr := SCADA_write_35
);
MSG_P6State_1to2(
	IN := (hmip6state_prev = 1 AND hmip6state = 2),
	LocalCfg := LocalCfgWrite_c6_e1,
	LocalAddr := SCADA_write_35
);
MSG_P6State_InvalidTo1(
	IN := (hmip6state_prev > 2),
	LocalCfg := LocalCfgWrite_c6_e1,
	LocalAddr := SCADA_write_35
);

// Write LSL/LSH alarms (offsets 885, 887, 889, 891, 893, 895)
SCADA_write_885_896[1].0 := hmilsl601alarm;
SCADA_write_885_896[2] := ANY_TO_WORD(hmilsl601delay);
SCADA_write_885_896[3].0 := hmilsl601alarm;
SCADA_write_885_896[4] := ANY_TO_WORD(hmilsl602delay);
SCADA_write_885_896[5].0 := hmilsl603alarm;
SCADA_write_885_896[6] := ANY_TO_WORD(hmilsl603delay);
SCADA_write_885_896[7].0 := hmilsh601alarm;
SCADA_write_885_896[8] := ANY_TO_WORD(hmilsh601delay);
SCADA_write_885_896[9].0 := hmilsh602alarm;
SCADA_write_885_896[10] := ANY_TO_WORD(hmilsh602delay);
SCADA_write_885_896[11].0 := hmilsh603alarm;
SCADA_write_885_896[12] := ANY_TO_WORD(hmilsh603delay);
MSG_Write_SCADA_885_896(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e12,
	LocalAddr := SCADA_write_885_896
);

(*
================================================================================
Write P601 complete block (offsets 897-912, 16 registers)
================================================================================
*)
SCADA_write_897_912[1].0 := hmip601auto;
SCADA_write_897_912[2] := ANY_TO_WORD(hmip601permissive);
SCADA_write_897_912[3] := ANY_TO_WORD(hmip601msgpermissive);
SCADA_write_897_912[4] := ANY_TO_WORD(hmip601sd);
SCADA_write_897_912[5] := ANY_TO_WORD(hmip601msgshutdown);
SCADA_write_897_912[6] := ANY_TO_WORD(0);
SCADA_write_897_912[7] := 0;
SCADA_write_897_912[8].0 := hmip601avl;
SCADA_write_897_912[9].0 := hmip601fault;
SCADA_write_897_912[10].0 := FALSE;
SCADA_write_897_912[11].0 := FALSE;
SCADA_write_897_912[12] := 0;
SCADA_write_897_912[13] := 0;
SCADA_write_897_912[14] := ANY_TO_WORD(hmip601shutdown);
SCADA_write_897_912[15].0 := FALSE;
SCADA_write_897_912[16] := ANY_TO_WORD(hmip601status);

MSG_Write_SCADA_897_912(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e16,
	LocalAddr := SCADA_write_897_912
);

(*
================================================================================
Write P602 complete block (offsets 913-928, 16 registers)
================================================================================
*)
SCADA_write_913_928[1].0 := hmip602auto;
SCADA_write_913_928[2] := ANY_TO_WORD(hmip602permissive);
SCADA_write_913_928[3] := ANY_TO_WORD(hmip602msgpermissive);
SCADA_write_913_928[4] := ANY_TO_WORD(hmip602sd);
SCADA_write_913_928[5] := ANY_TO_WORD(hmip602msgshutdown);
SCADA_write_913_928[6] := 0;
SCADA_write_913_928[7] := 0;
SCADA_write_913_928[8].0 := hmip602avl;
SCADA_write_913_928[9].0 := hmip602fault;
SCADA_write_913_928[10].0 := FALSE;
SCADA_write_913_928[11].0 := FALSE;
SCADA_write_913_928[12] := 0;
SCADA_write_913_928[13] := 0;
SCADA_write_913_928[14] := ANY_TO_WORD(hmip602shutdown);
SCADA_write_913_928[15].0 := FALSE;
SCADA_write_913_928[16] := ANY_TO_WORD(hmip602status);

MSG_Write_SCADA_913_928(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e16,
	LocalAddr := SCADA_write_913_928
);

(*
================================================================================
Write P603 complete block (offsets 929-944, 16 registers)
================================================================================
*)
SCADA_write_929_944[1].0 := hmip603auto;
SCADA_write_929_944[2] := ANY_TO_WORD(hmip603permissive);
SCADA_write_929_944[3] := ANY_TO_WORD(hmip603msgpermissive);
SCADA_write_929_944[4] := ANY_TO_WORD(hmip603sd);
SCADA_write_929_944[5] := ANY_TO_WORD(hmip603msgshutdown);
SCADA_write_929_944[6] := 0;
SCADA_write_929_944[7] := 0;
SCADA_write_929_944[8].0 := hmip603avl;
SCADA_write_929_944[9].0 := hmip603fault;
SCADA_write_929_944[10].0 := FALSE;
SCADA_write_929_944[11].0 := FALSE;
SCADA_write_929_944[12] := 0;
SCADA_write_929_944[13] := 0;
SCADA_write_929_944[14] := ANY_TO_WORD(hmip603shutdown);
SCADA_write_929_944[15].0 := FALSE;
SCADA_write_929_944[16] := ANY_TO_WORD(hmip603status);

MSG_Write_SCADA_929_944(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e16,
	LocalAddr := SCADA_write_929_944
);

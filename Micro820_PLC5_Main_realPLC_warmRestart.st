(*
================================================================================
Micro820 PLC5 Main Program (High Pressure RO Stage)
================================================================================
Converted from plc5.py for real Micro820 PLC execution
================================================================================
*)

PROGRAM Warm_Restart
(*
================================================================================
Warm Restart Logic for PLC5 (High Pressure RO Stage)
================================================================================
Purpose: Software-triggered system reinitialization via Modbus
Industry Standard: Allen-Bradley Micro820 retains variable states across power
cycles and SCADA disconnects. This logic enables remote reset to initial state
without program redownload.

Usage: Write 1 to HMI.PLANT.Reset_System (Modbus register 966) to trigger reset
================================================================================
*)
// HMI.PLANT.Reset_System (offset 966 - Warm Restart Trigger)
MSG_Read_SCADA_966(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_966
);
IF MSG_Read_SCADA_966.Q THEN
    hmiplantresetsystem := SCADA_read_966[1].0;
    msg_write_SCADA_966_enable := TRUE;
ELSE
    msg_write_SCADA_966_enable := FALSE;
END_IF;

IF hmiplantresetsystem THEN
    (* Reset state machine variables *)
    hmip5state := 1;
    hmip5state_prev := 0;
    hmip5permissiveon := TRUE;
    
    (* Reset SCADA control inputs *)
    hmiplantreseton := TRUE;
    hmiplantautoon := TRUE;
    hmiplantautooff := FALSE;
    hmiplantstart := FALSE;
    hmiplantstop := FALSE;
    
    (* Reset external dependencies *)
    hmip401status := 1;
    hmip402status := 1;
    hmiuv401status := 1;
    hmiprofeeddutypumprunning := FALSE;
    hmifit401all := FALSE;
    
    (* Reset MV501-504 *)
    hmimv501auto := TRUE;
    hmimv501reset := TRUE;
    hmimv501fto := FALSE;
    hmimv501ftc := FALSE;
    hmimv501status := 1;
    hmimv501avl := TRUE;
    hmimv501open := TRUE;
    hmimv501close := FALSE;
    
    hmimv502auto := TRUE;
    hmimv502reset := TRUE;
    hmimv502fto := FALSE;
    hmimv502ftc := FALSE;
    hmimv502status := 1;
    hmimv502avl := TRUE;
    hmimv502open := TRUE;
    hmimv502close := FALSE;
    
    hmimv503auto := TRUE;
    hmimv503reset := TRUE;
    hmimv503fto := FALSE;
    hmimv503ftc := FALSE;
    hmimv503status := 1;
    hmimv503avl := TRUE;
    hmimv503open := TRUE;
    hmimv503close := FALSE;
    
    hmimv504auto := TRUE;
    hmimv504reset := TRUE;
    hmimv504fto := FALSE;
    hmimv504ftc := FALSE;
    hmimv504status := 1;
    hmimv504avl := TRUE;
    hmimv504open := TRUE;
    hmimv504close := FALSE;
    
    (* Reset pumps P501, P502 *)
    hmip501auto := TRUE;
    hmip501status := 2;
    hmip501reset := FALSE;
    hmip501resetrunhr := TRUE;
    hmip501speedcommand := 7710;
    hmip501permissive := -1;
    hmip501msgpermissive := 0;
    hmip501msgshutdown := 0;
    hmip501sd := 0;
    hmip501avl := TRUE;
    hmip501fault := FALSE;
    hmip501fts := FALSE;
    hmip501ftr := FALSE;
    hmip501runhr := 0;
    hmip501totalrunhr := 0;
    hmip501speed := 0.0;
    hmip501driveready := FALSE;
    hmip501shutdown := 0;
    
    hmip502auto := TRUE;
    hmip502status := 2;
    hmip502reset := FALSE;
    hmip502resetrunhr := TRUE;
    hmip502speedcommand := 7710;
    hmip502permissive := -1;
    hmip502msgpermissive := 0;
    hmip502msgshutdown := 0;
    hmip502sd := 0;
    hmip502avl := TRUE;
    hmip502fault := FALSE;
    hmip502fts := FALSE;
    hmip502ftr := FALSE;
    hmip502runhr := 0;
    hmip502totalrunhr := 0;
    hmip502speed := 0.0;
    hmip502driveready := FALSE;
    hmip502shutdown := 0;
    
    (* Reset duty selector *)
    hmiprohighduty := 1;
    hmiprohighdutybothpmpnotavl := FALSE;
    hmiprohighdutyselectedpmpnotavl := FALSE;
    hmiprohighdutypumprunning := FALSE;
    
    (* Reset analog instruments *)
    hmiait501hty := TRUE;
    hmiait501ahh := FALSE;
    hmiait501ah := FALSE;
    hmiait501al := FALSE;
    hmiait501all := FALSE;
    
    hmiait502hty := TRUE;
    hmiait502ahh := FALSE;
    hmiait502ah := FALSE;
    hmiait502al := FALSE;
    hmiait502all := FALSE;
    
    hmiait503hty := TRUE;
    hmiait503ahh := FALSE;
    hmiait503ah := FALSE;
    hmiait503al := FALSE;
    hmiait503all := FALSE;
    
    hmiait504hty := TRUE;
    hmiait504ahh := FALSE;
    hmiait504ah := FALSE;
    hmiait504al := FALSE;
    hmiait504all := FALSE;
    hmiait504pv := 0.0;
    
    hmipit501hty := TRUE;
    hmipit501ahh := FALSE;
    hmipit501ah := FALSE;
    hmipit501al := FALSE;
    hmipit501all := FALSE;
    hmipit501pv := 0.0;
    
    hmipit502hty := TRUE;
    hmipit502ahh := FALSE;
    hmipit502ah := FALSE;
    hmipit502al := FALSE;
    hmipit502all := FALSE;
    hmipit502pv := 0.0;
    
    hmipit503hty := TRUE;
    hmipit503ahh := FALSE;
    hmipit503ah := FALSE;
    hmipit503al := FALSE;
    hmipit503all := FALSE;
    hmipit503pv := 0.0;
    
    hmifit501hty := FALSE;
    hmifit501ahh := FALSE;
    hmifit501ah := FALSE;
    hmifit501al := FALSE;
    hmifit501all := FALSE;
    hmifit501pv := 0.0;
    
    hmifit502hty := FALSE;
    hmifit502ahh := FALSE;
    hmifit502ah := FALSE;
    hmifit502al := FALSE;
    hmifit502all := FALSE;
    hmifit502pv := 0.0;
    
    hmifit503hty := FALSE;
    hmifit503ahh := FALSE;
    hmifit503ah := FALSE;
    hmifit503al := FALSE;
    hmifit503all := FALSE;
    hmifit503pv := 0.0;
    
    hmifit504hty := FALSE;
    hmifit504ahh := FALSE;
    hmifit504ah := FALSE;
    hmifit504al := FALSE;
    hmifit504all := FALSE;
    hmifit504pv := 0.0;
    
    (* Reset cycle variables *)
    hmicyp5rotmp := 0.0;
    hmicyp5hppqmaxm3h := 0.0;
    hmicyp5hmihppqsetm3h := 0.0;
    hmicyp5minrovsdspeed := 0.0;
    hmicyp5rampingratepersec := 0.0;
    hmicyp5vsdminspeed := 0.0;
    hmicyp5vsdhighspeed := 0.0;
    hmicyp5mv501timeouttm := 0;
    hmicyp5mv502timeouttm := 0;
    hmicyp5mv503timeouttm := 0;
    hmicyp5mv504timeouttm := 0;
    hmicyp5rohppsdon := FALSE;
    hmicyp5flushingmin := 0;
    hmicyp5flushingminsp := 2;
    hmicyp5rohighpumpshutdown := FALSE;
    hmicyp5sdflushingdoneon := FALSE;
    hmicyp5rosdflushing := FALSE;
    hmicyp5rosdflushingmin := 0;
    
    (* Reset mid variables *)
    Mid_P_RO_HIGH_AutoInp := FALSE;
    Mid_MV501_AutoInp := FALSE;
    Mid_MV502_AutoInp := FALSE;
    Mid_MV503_AutoInp := FALSE;
    Mid_MV504_AutoInp := FALSE;
    Mid_P50X_AutoSpeed := 0.0;
    
    hmiplantresetsystem := FALSE;
END_IF;

SCADA_write_966[1].0 := hmiplantresetsystem;
MSG_Write_SCADA_966(
	IN := msg_write_SCADA_966_enable,
	LocalCfg := LocalCfgWrite_c6_e1,
	LocalAddr := SCADA_write_966
);


PROGRAM Modbus_SCADA_READ
(*
================================================================================
SCADA Read - Only tags used by plc5.py fetchData()
================================================================================
Matches plc5.py fetchData() lines 286-299:
  - HMI.PLANT.Start (state==1)    - offset 5
  - HMI.FIT401.ALL                - offset 607
  - HMI.P401.Status               - offset 494
  - HMI.P402.Status               - offset 510
  - HMI.PLANT.Auto_Off            - offset 2
  - HMI.PLANT.Auto_On             - offset 1
  - HMI.PLANT.Reset_On            - offset 0
  - HMI.PLANT.Stop                - offset 4
  - HMI.UV401.Status              - offset 555
  - HMI.P_RO_FEED_DUTY.Pump_Running - offset 563
================================================================================
*)
(*
================================================================================
SCADA Read - Core Tags (Always Read)
================================================================================
*)
// Read PLANT control signals (offsets 0-6)
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

// Read UV401 Status (offset 555)
MSG_Read_SCADA_555(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_555
);
IF MSG_Read_SCADA_555.Q THEN
	hmiuv401status := ANY_TO_INT(SCADA_read_555[1]);
END_IF;

// Read P_RO_FEED_DUTY.Pump_Running (offset 563)
MSG_Read_SCADA_563(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_563
);
IF MSG_Read_SCADA_563.Q THEN
	hmiprofeeddutypumprunning := SCADA_read_563[1].0;
END_IF;

// Read FIT401.ALL (offset 607)
MSG_Read_SCADA_607(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_607
);
IF MSG_Read_SCADA_607.Q THEN
	hmifit401all := SCADA_read_607[1].0;
END_IF;


PROGRAM Modbus_L1_Read
(*
================================================================================
Plant Read - Physical Simulator (192.168.137.1:506)
================================================================================
*)
MSG_Read_L1_100(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_L1_e22,
	LocalAddr := L1_read_100
);
IF MSG_Read_L1_100.Q THEN
    // P501 VSD inputs (100-106)
    IO_P501_VSD_Active := L1_read_100[1].0;
    IO_P501_VSD_Ready := L1_read_100[2].0;
	tempReal[0] := L1_read_100[3];
	tempReal[1] := L1_read_100[4];
    COP_P501_OutputFreq(
        Enable := TRUE,
        Src := tempReal,
        Dest := IO_P501_VSD_OutputFreq,
        Length := 1
    );
    IO_P501_VSD_Faulted := L1_read_100[5].0;
    IO_P501_DI_Auto := L1_read_100[6].0;
    IO_P501_DI_Run := L1_read_100[7].0;
    
    // P502 VSD inputs (107-113)
    IO_P502_VSD_Active := L1_read_100[8].0;
    IO_P502_VSD_Ready := L1_read_100[9].0;
	tempReal[0] := L1_read_100[10];
	tempReal[1] := L1_read_100[11];
    COP_P502_OutputFreq(
        Enable := TRUE,
        Src := tempReal,
        Dest := IO_P502_VSD_OutputFreq,
        Length := 1
    );
    IO_P502_VSD_Faulted := L1_read_100[12].0;
    IO_P502_DI_Auto := L1_read_100[13].0;
    IO_P502_DI_Run := L1_read_100[14].0;
    
    // Valve feedback (114-121)
    IO_MV501_DI_ZSO := L1_read_100[15].0;
    IO_MV501_DI_ZSC := L1_read_100[16].0;
    IO_MV502_DI_ZSO := L1_read_100[17].0;
    IO_MV502_DI_ZSC := L1_read_100[18].0;
    IO_MV503_DI_ZSO := L1_read_100[19].0;
    IO_MV503_DI_ZSC := L1_read_100[20].0;
    IO_MV504_DI_ZSO := L1_read_100[21].0;
    IO_MV504_DI_ZSC := L1_read_100[22].0;
    
    // Speed is REAL type (0-100%), used for float comparisons in state machine
    hmip501speed := IO_P501_VSD_OutputFreq;
    hmip502speed := IO_P502_VSD_OutputFreq;
END_IF;


PROGRAM Plant_Control
IF hmiplantreseton THEN
    hmip501reset := TRUE;
    hmip502reset := TRUE;
    hmimv501reset := TRUE;
    hmimv502reset := TRUE;
    hmimv503reset := TRUE;
    hmimv504reset := TRUE;
END_IF;

IF hmiplantautoon THEN
    hmip501auto := TRUE;
    hmip502auto := TRUE;
    hmimv501auto := TRUE;
    hmimv502auto := TRUE;
    hmimv503auto := TRUE;
    hmimv504auto := TRUE;
END_IF;

IF hmiplantautooff THEN
    hmip501auto := FALSE;
    hmip502auto := FALSE;
    hmimv501auto := FALSE;
    hmimv502auto := FALSE;
    hmimv503auto := FALSE;
    hmimv504auto := FALSE;
END_IF;


PROGRAM Permissive_Shutdown
(*
================================================================================
Stage 3: Permissive calculations and Shutdown logic for PLC5
================================================================================
*)
hmip5permissiveon := (hmip501avl OR hmip502avl) AND hmimv501avl 
	AND hmimv502avl AND hmimv503avl AND hmimv504avl;

Mid_FIT501_Tot_Enb := (hmip501status = 2) OR (hmip502status = 2);
Mid_FIT502_Tot_Enb := (hmimv501status = 2);
Mid_FIT503_Tot_Enb := (hmip401status = 2) OR (hmip402status = 2);
Mid_FIT504_Tot_Enb := (hmip401status = 2) OR (hmip402status = 2);

TON_FIT401_TM(
	IN := (hmifit401all AND hmiprofeeddutypumprunning),
	PT := T#3s
);

// Calculate cycle parameters
hmicyp5rotmp := ((hmipit501pv + hmipit503pv) / 2.0) - hmipit502pv;
hmicyp5hppqmaxm3h := 2.0;
hmicyp5hmihppqsetm3h := 1.25;
hmicyp5minrovsdspeed := hmicyp5hmihppqsetm3h / hmicyp5hppqmaxm3h * 50.0 * 0.1;
hmicyp5rampingratepersec := 1.5;
hmicyp5vsdminspeed := 10.0;
hmicyp5vsdhighspeed := 30.0;

// P501 Permissive calculations
hmip501permissive.0 := hmiprofeeddutypumprunning;
hmip501permissive.1 := NOT hmifit401all;
hmip501permissive.2 := (hmiuv401status = 2);

hmip501msgpermissive.1 := hmip501permissive.0;
hmip501msgpermissive.2 := hmip501permissive.1;
hmip501msgpermissive.3 := hmip501permissive.2;

// P501 Shutdown calculations
hmip501sd.0 := NOT hmiprofeeddutypumprunning;
hmip501sd.1 := TON_FIT401_TM.Q;
hmip501sd.2 := (hmiuv401status <> 2);
hmip501sd.3 := FALSE;
hmip501sd.4 := FALSE;

hmip501msgshutdown.1 := hmip501shutdown.0;
hmip501msgshutdown.2 := hmip501shutdown.1;
hmip501msgshutdown.3 := hmip501shutdown.2;
hmip501msgshutdown.4 := hmip501shutdown.3;
hmip501msgshutdown.5 := hmip501shutdown.4;

// P502 Permissive calculations
hmip502permissive.0 := hmiprofeeddutypumprunning;
hmip502permissive.1 := NOT hmifit401all;
hmip502permissive.2 := (hmiuv401status = 2);

hmip502msgpermissive.1 := hmip502permissive.0;
hmip502msgpermissive.2 := hmip502permissive.1;
hmip502msgpermissive.3 := hmip502permissive.2;

// P502 Shutdown calculations
hmip502sd.0 := NOT hmiprofeeddutypumprunning;
hmip502sd.1 := TON_FIT401_TM.Q;
hmip502sd.2 := (hmiuv401status <> 2);
hmip502sd.3 := FALSE;
hmip502sd.4 := FALSE;

hmip502msgshutdown.1 := hmip502shutdown.0;
hmip502msgshutdown.2 := hmip502shutdown.1;
hmip502msgshutdown.3 := hmip502shutdown.2;
hmip502msgshutdown.4 := hmip502shutdown.3;
hmip502msgshutdown.5 := hmip502shutdown.4;


PROGRAM State_Machine
(*
================================================================================
State Machine - High Pressure RO Control (21 states)
================================================================================
Process Description:
State 1:  Standby/Initial
State 2:  Wait for RO Feed Duty running
State 3:  Open MV503, MV504 (reject valves)
State 4:  Wait for MV503, MV504 open
State 5:  Start P_RO_HIGH_DUTY pumps (P501/P502)
State 6:  Ramp up VSD speed
State 7:  Wait for conductivity check
State 8:  Open MV501 (permeate valve)
State 9:  Close MV503 (reject valve)
State 10: Open MV502 (permeate valve)
State 11: Close MV504 (reject valve)
State 12: Normal operation
State 13: Ramp down VSD speed (shutdown initiated)
State 14: Stop P_RO_HIGH_DUTY pumps
State 15: Open MV504 (reject valve for flushing)
State 16: Close MV502 (permeate valve)
State 17: Open MV503 (reject valve for flushing)
State 18: Close MV501 (permeate valve)
State 19: Flushing mode
State 20: Wait for upstream shutdown
State 21: Close MV503, MV504 (complete shutdown)
================================================================================
*)

CASE hmip5state OF
1:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := FALSE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := FALSE;
	Mid_MV504_AutoInp := FALSE;
	Mid_P50X_AutoSpeed := hmicyp5vsdminspeed;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF hmip5permissiveon AND hmiplantstart THEN
		hmip5state := 3;
	END_IF;

2:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := FALSE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := FALSE;
	Mid_MV504_AutoInp := FALSE;
	Mid_P50X_AutoSpeed := hmicyp5vsdminspeed;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF hmiprofeeddutypumprunning THEN
		hmip5state := 3;
	END_IF;

3:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := FALSE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := TRUE;
	Mid_MV504_AutoInp := TRUE;
	Mid_P50X_AutoSpeed := hmicyp5vsdminspeed;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF (hmimv503status = 2) AND (hmimv504status = 2) AND hmiprofeeddutypumprunning THEN
		hmip5state := 4;
	END_IF;

4:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := FALSE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := TRUE;
	Mid_MV504_AutoInp := TRUE;
	Mid_P50X_AutoSpeed := hmicyp5vsdminspeed;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	hmip5state := 5;

5:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := TRUE;
	Mid_MV501_AutoInp := FALSE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := TRUE;
	Mid_MV504_AutoInp := TRUE;
	Mid_P50X_AutoSpeed := hmicyp5vsdminspeed;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF (hmip501speed >= Mid_P50X_AutoSpeed) OR (hmip502speed >= Mid_P50X_AutoSpeed) THEN
		hmip5state := 6;
	END_IF;

6:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := TRUE;
	Mid_MV501_AutoInp := FALSE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := TRUE;
	Mid_MV504_AutoInp := TRUE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	// Ramp up speed (simulated - would use timer in real implementation)
	IF Mid_P50X_AutoSpeed < hmicyp5vsdhighspeed THEN
		Mid_P50X_AutoSpeed := Mid_P50X_AutoSpeed + 0.5;
	END_IF;
	
	IF ((hmifit501pv > hmicyp5hmihppqsetm3h) AND (hmipit502pv < hmipit503pv)) AND (hmipit501pv > 250.0) THEN
		hmip5state := 7;
	END_IF;

7:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := TRUE;
	Mid_MV501_AutoInp := FALSE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := TRUE;
	Mid_MV504_AutoInp := TRUE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF hmiait504pv < hmiait504sah THEN
		hmip5state := 8;
	END_IF;

8:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := TRUE;
	Mid_MV501_AutoInp := TRUE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := TRUE;
	Mid_MV504_AutoInp := TRUE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF hmimv501status = 2 THEN
		hmip5state := 9;
	END_IF;

9:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := TRUE;
	Mid_MV501_AutoInp := TRUE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := FALSE;
	Mid_MV504_AutoInp := TRUE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF hmimv503status = 1 THEN
		hmip5state := 10;
	END_IF;

10:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := TRUE;
	Mid_MV501_AutoInp := TRUE;
	Mid_MV502_AutoInp := TRUE;
	Mid_MV503_AutoInp := FALSE;
	Mid_MV504_AutoInp := TRUE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF hmimv502status = 2 THEN
		hmip5state := 11;
	END_IF;

11:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := TRUE;
	Mid_MV501_AutoInp := TRUE;
	Mid_MV502_AutoInp := TRUE;
	Mid_MV503_AutoInp := FALSE;
	Mid_MV504_AutoInp := FALSE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF hmimv504status = 1 THEN
		hmip5state := 12;
	END_IF;

12:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := TRUE;
	Mid_MV501_AutoInp := TRUE;
	Mid_MV502_AutoInp := TRUE;
	Mid_MV503_AutoInp := FALSE;
	Mid_MV504_AutoInp := FALSE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF hmiplantstop THEN
		hmip5state := 13;
	END_IF;

13:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := TRUE;
	Mid_MV501_AutoInp := TRUE;
	Mid_MV502_AutoInp := TRUE;
	Mid_MV503_AutoInp := FALSE;
	Mid_MV504_AutoInp := FALSE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	// Ramp down speed (simulated - would use timer in real implementation)
	IF Mid_P50X_AutoSpeed > hmicyp5vsdminspeed THEN
		Mid_P50X_AutoSpeed := Mid_P50X_AutoSpeed - 0.5;
	END_IF;
	
	IF (hmip501speed <= hmicyp5vsdminspeed) AND (hmip502speed <= hmicyp5vsdminspeed) THEN
		hmip5state := 14;
	END_IF;

14:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := TRUE;
	Mid_MV502_AutoInp := TRUE;
	Mid_MV503_AutoInp := FALSE;
	Mid_MV504_AutoInp := FALSE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF NOT hmiprohighdutypumprunning THEN
		hmip5state := 15;
	END_IF;

15:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := TRUE;
	Mid_MV502_AutoInp := TRUE;
	Mid_MV503_AutoInp := FALSE;
	Mid_MV504_AutoInp := TRUE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	
	// Increment timeout once per second (using Sec_P pulse)
	IF Sec_P THEN
		hmicyp5mv504timeouttm := hmicyp5mv504timeouttm + 1;
	END_IF;
	
	IF (hmimv504status = 2) OR (hmicyp5mv504timeouttm > 120) THEN
		hmip5state := 16;
	END_IF;

16:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := TRUE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := FALSE;
	Mid_MV504_AutoInp := TRUE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	// Increment timeout once per second (using Sec_P pulse)
	IF Sec_P THEN
		hmicyp5mv502timeouttm := hmicyp5mv502timeouttm + 1;
	END_IF;
	
	IF (hmimv502status = 1) OR (hmicyp5mv502timeouttm > 120) THEN
		hmip5state := 17;
	END_IF;

17:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := TRUE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := TRUE;
	Mid_MV504_AutoInp := TRUE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	// Increment timeout once per second (using Sec_P pulse)
	IF Sec_P THEN
		hmicyp5mv503timeouttm := hmicyp5mv503timeouttm + 1;
	END_IF;
	
	IF (hmimv503status = 2) OR (hmicyp5mv503timeouttm > 120) THEN
		hmip5state := 18;
	END_IF;

18:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := FALSE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := TRUE;
	Mid_MV504_AutoInp := TRUE;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	// Increment timeout once per second (using Sec_P pulse)
	IF Sec_P THEN
		hmicyp5mv501timeouttm := hmicyp5mv501timeouttm + 1;
	END_IF;
	
	IF (hmimv501status = 1) OR (hmicyp5mv501timeouttm > 120) THEN
		hmip5state := 19;
	END_IF;

19:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := FALSE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := TRUE;
	Mid_MV504_AutoInp := TRUE;
	Mid_P50X_AutoSpeed := hmicyp5vsdminspeed;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF hmicyp5rosdflushingmin > 2 THEN  // FLUSHING_MIN_SP
		hmip5state := 20;
	END_IF;

20:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := FALSE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := TRUE;
	Mid_MV504_AutoInp := TRUE;
	Mid_P50X_AutoSpeed := hmicyp5vsdminspeed;
	hmicyp5rohppsdon := TRUE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	hmicyp5mv503timeouttm := 0;
	hmicyp5mv504timeouttm := 0;
	
	IF NOT hmiprofeeddutypumprunning THEN
		hmip5state := 21;
	END_IF;

21:
	hmip5state_prev := hmip5state;
	Mid_P_RO_HIGH_AutoInp := FALSE;
	Mid_MV501_AutoInp := FALSE;
	Mid_MV502_AutoInp := FALSE;
	Mid_MV503_AutoInp := FALSE;
	Mid_MV504_AutoInp := FALSE;
	Mid_P50X_AutoSpeed := hmicyp5vsdminspeed;
	hmicyp5rohppsdon := FALSE;
	hmicyp5flushingmin := 0;
	hmicyp5rosdflushingmin := 0;
	hmicyp5rohighpumpshutdown := FALSE;
	hmicyp5sdflushingdoneon := FALSE;
	hmicyp5mv501timeouttm := 0;
	hmicyp5mv502timeouttm := 0;
	
	// Increment timeouts once per second (using Sec_P pulse)
	IF Sec_P THEN
		hmicyp5mv503timeouttm := hmicyp5mv503timeouttm + 1;
		hmicyp5mv504timeouttm := hmicyp5mv504timeouttm + 1;
	END_IF;
	
	IF ((hmimv503status = 1) AND (hmimv504status = 1)) OR (hmicyp5mv503timeouttm > 120) OR (hmicyp5mv504timeouttm > 120) THEN
		hmip5state := 1;
	END_IF;

ELSE
	hmip5state := 1;
END_CASE;


PROGRAM Function_Blocks
(*
================================================================================
Function Block Execution
================================================================================
*)

(* MV501 Function Block *)
MV501_FB(
    AutoInp := Mid_MV501_AutoInp,
    Auto := hmimv501auto,
    Reset := hmimv501reset,
    DI_ZSC := IO_MV501_DI_ZSC,  // From physical simulator
    DI_ZSO := IO_MV501_DI_ZSO   // From physical simulator
);
IF MV501_FB.Status <> -99 THEN
    hmimv501status := MV501_FB.Status;
END_IF;
hmimv501avl := MV501_FB.Avl;
hmimv501fto := MV501_FB.FTO;
hmimv501ftc := MV501_FB.FTC;
IO_MV501_DO_Open := MV501_FB.DO_Open;
IO_MV501_DO_Close := MV501_FB.DO_Close;

(* MV502 Function Block *)
MV502_FB(
    AutoInp := Mid_MV502_AutoInp,
    Auto := hmimv502auto,
    Reset := hmimv502reset,
    DI_ZSC := IO_MV502_DI_ZSC,
    DI_ZSO := IO_MV502_DI_ZSO
);
IF MV502_FB.Status <> -99 THEN
    hmimv502status := MV502_FB.Status;
END_IF;
hmimv502avl := MV502_FB.Avl;
hmimv502fto := MV502_FB.FTO;
hmimv502ftc := MV502_FB.FTC;
IO_MV502_DO_Open := MV502_FB.DO_Open;
IO_MV502_DO_Close := MV502_FB.DO_Close;

(* MV503 Function Block *)
MV503_FB(
    AutoInp := Mid_MV503_AutoInp,
    Auto := hmimv503auto,
    Reset := hmimv503reset,
    DI_ZSC := IO_MV503_DI_ZSC,
    DI_ZSO := IO_MV503_DI_ZSO
);
IF MV503_FB.Status <> -99 THEN
    hmimv503status := MV503_FB.Status;
END_IF;
hmimv503avl := MV503_FB.Avl;
hmimv503fto := MV503_FB.FTO;
hmimv503ftc := MV503_FB.FTC;
IO_MV503_DO_Open := MV503_FB.DO_Open;
IO_MV503_DO_Close := MV503_FB.DO_Close;

(* MV504 Function Block *)
MV504_FB(
    AutoInp := Mid_MV504_AutoInp,
    Auto := hmimv504auto,
    Reset := hmimv504reset,
    DI_ZSC := IO_MV504_DI_ZSC,
    DI_ZSO := IO_MV504_DI_ZSO
);
IF MV504_FB.Status <> -99 THEN
    hmimv504status := MV504_FB.Status;
END_IF;
hmimv504avl := MV504_FB.Avl;
hmimv504fto := MV504_FB.FTO;
hmimv504ftc := MV504_FB.FTC;
IO_MV504_DO_Open := MV504_FB.DO_Open;
IO_MV504_DO_Close := MV504_FB.DO_Close;

(* P_RO_HIGH_DUTY Duty Selector *)
P_RO_HIGH_DUTY_FB(
    AutoInp := Mid_P_RO_HIGH_AutoInp,
    Pmp1_Status := hmip501status,
    Pmp1_Avl := hmip501avl,
    Pmp2_Status := hmip502status,
    Pmp2_Avl := hmip502avl,
    Selection := hmiprohighduty
);
hmiprohighdutybothpmpnotavl := P_RO_HIGH_DUTY_FB.Both_Pmp_Not_Avl;
hmiprohighdutyselectedpmpnotavl := P_RO_HIGH_DUTY_FB.Selected_Pmp_Not_Avl;
hmiprohighdutypumprunning := P_RO_HIGH_DUTY_FB.Pump_Running;

(* P501 VSD Function Block *)
P501_VSD_FB(
    Start := P_RO_HIGH_DUTY_FB.Start_Pmp1,
    Auto := hmip501auto,
    Speed_Set := Mid_P50X_AutoSpeed,
    Reset := hmip501reset,
    Permissive := hmip501permissive,
    SD := hmip501sd,
    VSD_Active := IO_P501_VSD_Active,
    VSD_Ready := IO_P501_VSD_Ready,
    VSD_Faulted := IO_P501_VSD_Faulted,
    DI_Run := IO_P501_DI_Run,
    DI_Auto := IO_P501_DI_Auto,
	VSD_OutputFreq := 0.0
);
IF P501_VSD_FB.Status <> -99 THEN
    hmip501status := P501_VSD_FB.Status;
END_IF;
hmip501fault := P501_VSD_FB.Fault;
hmip501avl := P501_VSD_FB.Avl;
hmip501shutdown := P501_VSD_FB.Shutdown;
IO_P501_DO_Start := P501_VSD_FB.DO_Start;
IO_P501_DO_Stop := P501_VSD_FB.DO_Stop;
IO_P501_FreqCommand := P501_VSD_FB.FreqCommand;

(* P502 VSD Function Block *)
P502_VSD_FB(
    Start := P_RO_HIGH_DUTY_FB.Start_Pmp2,
    Auto := hmip502auto,
    Speed_Set := Mid_P50X_AutoSpeed,
    Reset := hmip502reset,
    Permissive := hmip502permissive,
    SD := hmip502sd,
    VSD_Active := IO_P502_VSD_Active,
    VSD_Ready := IO_P502_VSD_Ready,
    VSD_Faulted := IO_P502_VSD_Faulted,
    DI_Run := IO_P502_DI_Run,
    DI_Auto := IO_P502_DI_Auto
);
IF P502_VSD_FB.Status <> -99 THEN
    hmip502status := P502_VSD_FB.Status;
END_IF;
hmip502fault := P502_VSD_FB.Fault;
hmip502avl := P502_VSD_FB.Avl;
hmip502shutdown := P502_VSD_FB.Shutdown;
IO_P502_DO_Start := P502_VSD_FB.DO_Start;
IO_P502_DO_Stop := P502_VSD_FB.DO_Stop;
IO_P502_FreqCommand := P502_VSD_FB.FreqCommand;


PROGRAM Modbus_L1_Write
(*
================================================================================
Stage 7: Write outputs to Plant Simulator
================================================================================
*)
// Write P501 VSD commands (200-203)
L1_write_200[1].0 := IO_P501_DO_Start;
L1_write_200[2].0 := IO_P501_DO_Stop;
COP_P501_FreqCommand(
    Enable := TRUE,
    Src := IO_P501_FreqCommand,
    Dest := L1_write_200[3],
    Length := 2
);
// Write P502 VSD commands (204-207)
L1_write_200[5].0 := IO_P502_DO_Start;
L1_write_200[6].0 := IO_P502_DO_Stop;
COP_P502_FreqComman(
    Enable := TRUE,
    Src := IO_P502_FreqCommand,
    Dest := L1_write_200[7],
    Length := 2
);
// Write valve commands (208-215)
L1_write_200[9].0 := IO_MV501_DO_Open;
L1_write_200[10].0 := IO_MV501_DO_Close;
L1_write_200[11].0 := IO_MV502_DO_Open;
L1_write_200[12].0 := IO_MV502_DO_Close;
L1_write_200[13].0 := IO_MV503_DO_Open;
L1_write_200[14].0 := IO_MV503_DO_Close;
L1_write_200[15].0 := IO_MV504_DO_Open;
L1_write_200[16].0 := IO_MV504_DO_Close;

MSG_WRITE_L1_200(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_L1_e16,
	LocalAddr := L1_write_200
);


PROGRAM Modbus_SCADA_Write
(*
================================================================================
Write status back to SCADA
================================================================================
*)

(*
================================================================================
Stage 8: Write status back to SCADA
================================================================================
*)
// Write HMI.P5.State (offset 30) - Independent MSG for each state transition
IF hmiplantstop THEN
	SCADA_write_30[1] := ANY_TO_WORD(13);
ELSIF hmip5state_prev > 21 THEN
	SCADA_write_30[1] := ANY_TO_WORD(1);
ELSE
	SCADA_write_30[1] := ANY_TO_WORD(hmip5state);
END_IF;

MSG_P5State_StopTo13(IN := hmiplantstop, LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_1to3(IN := (hmip5state_prev = 1 AND hmip5state = 3), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_2to3(IN := (hmip5state_prev = 2 AND hmip5state = 3), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_3to4(IN := (hmip5state_prev = 3 AND hmip5state = 4), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_5to6(IN := (hmip5state_prev = 5 AND hmip5state = 6), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_6to7(IN := (hmip5state_prev = 6 AND hmip5state = 7), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_7to8(IN := (hmip5state_prev = 7 AND hmip5state = 8), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_8to9(IN := (hmip5state_prev = 8 AND hmip5state = 9), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_9to10(IN := (hmip5state_prev = 9 AND hmip5state = 10), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_10to11(IN := (hmip5state_prev = 10 AND hmip5state = 11), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_11to12(IN := (hmip5state_prev = 11 AND hmip5state = 12), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_12to13(IN := (hmip5state_prev = 12 AND hmip5state = 13), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_13to14(IN := (hmip5state_prev = 13 AND hmip5state = 14), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_14to15(IN := (hmip5state_prev = 14 AND hmip5state = 15), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_15to16(IN := (hmip5state_prev = 15 AND hmip5state = 16), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_16to17(IN := (hmip5state_prev = 16 AND hmip5state = 17), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_17to18(IN := (hmip5state_prev = 17 AND hmip5state = 18), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_18to19(IN := (hmip5state_prev = 18 AND hmip5state = 19), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_19to20(IN := (hmip5state_prev = 19 AND hmip5state = 20), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_20to21(IN := (hmip5state_prev = 20 AND hmip5state = 21), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_21to1(IN := (hmip5state_prev = 21 AND hmip5state = 1), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);
MSG_P5State_InvalidTo1(IN := (hmip5state_prev > 21), LocalCfg := LocalCfgWrite_c6_e1, LocalAddr := SCADA_write_30);

// Write HMI.P5.Permissive_On (offset 28)
SCADA_write_28[1].0 := hmip5permissiveon;
MSG_Write_SCADA_28(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c6_e1,
	LocalAddr := SCADA_write_28
);

// Write MV501 status (offsets 808-813)
// HMI.MV501.Auto (808), Reset (809), FTO (810), FTC (811), Status (812), Avl (813)
SCADA_write_808_813[1].0 := hmimv501auto;
SCADA_write_808_813[2].0 := hmimv501reset;
SCADA_write_808_813[3].0 := hmimv501fto;
SCADA_write_808_813[4].0 := hmimv501ftc;
SCADA_write_808_813[5] := ANY_TO_WORD(hmimv501status);
SCADA_write_808_813[6].0 := hmimv501avl;
MSG_Write_SCADA_808_813(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e6,
	LocalAddr := SCADA_write_808_813
);

// Write MV502 status (offsets 817-822)
// HMI.MV502.Auto (817), Reset (818), FTO (819), FTC (820), Status (821), Avl (822)
SCADA_write_817_822[1].0 := hmimv502auto;
SCADA_write_817_822[2].0 := hmimv502reset;
SCADA_write_817_822[3].0 := hmimv502fto;
SCADA_write_817_822[4].0 := hmimv502ftc;
SCADA_write_817_822[5] := ANY_TO_WORD(hmimv502status);
SCADA_write_817_822[6].0 := hmimv502avl;
MSG_Write_SCADA_817_822(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e6,
	LocalAddr := SCADA_write_817_822
);

// Write MV503 status (offsets 826-831)
// HMI.MV503.Auto (826), Reset (827), FTO (828), FTC (829), Status (830), Avl (831)
SCADA_write_826_831[1].0 := hmimv503auto;
SCADA_write_826_831[2].0 := hmimv503reset;
SCADA_write_826_831[3].0 := hmimv503fto;
SCADA_write_826_831[4].0 := hmimv503ftc;
SCADA_write_826_831[5] := ANY_TO_WORD(hmimv503status);
SCADA_write_826_831[6].0 := hmimv503avl;
MSG_Write_SCADA_826_831(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e6,
	LocalAddr := SCADA_write_826_831
);

// Write MV504 status (offsets 835-840)
// HMI.MV504.Auto (835), Reset (836), FTO (837), FTC (838), Status (839), Avl (840)
SCADA_write_835_840[1].0 := hmimv504auto;
SCADA_write_835_840[2].0 := hmimv504reset;
SCADA_write_835_840[3].0 := hmimv504fto;
SCADA_write_835_840[4].0 := hmimv504ftc;
SCADA_write_835_840[5] := ANY_TO_WORD(hmimv504status);
SCADA_write_835_840[6].0 := hmimv504avl;
MSG_Write_SCADA_835_840(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e6,
	LocalAddr := SCADA_write_835_840
);

// Write P_RO_HIGH_DUTY status (offsets 845-846)
SCADA_write_845_846[1].0 := hmiprohighdutybothpmpnotavl;
SCADA_write_845_846[2].0 := hmiprohighdutyselectedpmpnotavl;

MSG_Write_SCADA_845_846(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e2,
	LocalAddr := SCADA_write_845_846
);

// Write P501 status (offsets 848-866)
SCADA_write_848[1].0 := hmip501auto;
SCADA_write_848[2] := ANY_TO_WORD(hmip501status);
SCADA_write_848[3].0 := hmip501reset;
SCADA_write_848[4].0 := hmip501resetrunhr;
SCADA_write_848[5] := ANY_TO_WORD(hmip501speedcommand);
SCADA_write_848[6] := ANY_TO_WORD(hmip501permissive);
SCADA_write_848[7] := ANY_TO_WORD(hmip501msgpermissive);
SCADA_write_848[8] := ANY_TO_WORD(hmip501msgshutdown);
SCADA_write_848[9] := ANY_TO_WORD(hmip501sd);
SCADA_write_848[10].0 := hmip501avl;
SCADA_write_848[11] := ANY_TO_WORD(hmip501sd);
SCADA_write_848[12].0 := hmip501fault;
SCADA_write_848[13].0 := hmip501fts;
SCADA_write_848[14].0 := hmip501ftr;
SCADA_write_848[15] := ANY_TO_WORD(hmip501runhr);
SCADA_write_848[16] := ANY_TO_WORD(hmip501totalrunhr);
SCADA_write_848[17] := ANY_TO_WORD(ANY_TO_INT(hmip501speed));
SCADA_write_848[18].0 := hmip501driveready;
SCADA_write_848[19] := ANY_TO_WORD(hmip501shutdown);

MSG_Write_SCADA_848_866(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e19,
	LocalAddr := SCADA_write_848
);

// Write P502 status (offsets 867-884)
SCADA_write_867[1].0 := hmip502auto;
SCADA_write_867[2] := ANY_TO_WORD(hmip502status);
SCADA_write_867[3].0 := hmip502reset;
SCADA_write_867[4].0 := hmip502resetrunhr;
SCADA_write_867[5] := ANY_TO_WORD(hmip502speedcommand);
SCADA_write_867[6] := ANY_TO_WORD(hmip502permissive);
SCADA_write_867[7] := ANY_TO_WORD(hmip502msgpermissive);
SCADA_write_867[8] := ANY_TO_WORD(hmip502msgshutdown);
SCADA_write_867[9] := ANY_TO_WORD(hmip502sd);
SCADA_write_867[10].0 := hmip502avl;
SCADA_write_867[11].0 := hmip502fault;
SCADA_write_867[12].0 := hmip502fts;
SCADA_write_867[13].0 := hmip502ftr;
SCADA_write_867[14] := ANY_TO_WORD(hmip502runhr);
SCADA_write_867[15] := ANY_TO_WORD(hmip502totalrunhr);
SCADA_write_867[16] := ANY_TO_WORD(ANY_TO_INT(hmip502speed));
SCADA_write_867[17].0 := hmip502driveready;
SCADA_write_867[18] := ANY_TO_WORD(hmip502shutdown);

MSG_Write_SCADA_867_884(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e18,
	LocalAddr := SCADA_write_867
);

(*
================================================================================
Write Cy_P5 cycle parameters (offsets 621-631)
================================================================================
*)

// MV501_TIMEOUT_TM (621) - Incremented in State 18, write only when not in that state
IF hmip5state_prev <> 18 AND hmip5state_prev <= 21 THEN
    SCADA_write_621[1] := ANY_TO_WORD(hmicyp5mv501timeouttm);
    MSG_Write_SCADA_621(
        IN := TRUE,
        LocalCfg := LocalCfgWrite_c6_e1,
        LocalAddr := SCADA_write_621
    );
END_IF;

// MV502_TIMEOUT_TM (622) - Incremented in State 16, write only when not in that state
IF hmip5state_prev <> 16 AND hmip5state_prev <= 21 THEN
    SCADA_write_622[1] := ANY_TO_WORD(hmicyp5mv502timeouttm);
    MSG_Write_SCADA_622(
        IN := TRUE,
        LocalCfg := LocalCfgWrite_c6_e1,
        LocalAddr := SCADA_write_622
    );
END_IF;

// MV503_TIMEOUT_TM (623) - Incremented in State 17 and 21, write only when not in those states
IF (hmip5state_prev <> 17) AND (hmip5state_prev < 21) THEN
    SCADA_write_623[1] := ANY_TO_WORD(hmicyp5mv503timeouttm);
    MSG_Write_SCADA_623(
        IN := TRUE,
        LocalCfg := LocalCfgWrite_c6_e1,
        LocalAddr := SCADA_write_623
    );
END_IF;

// MV504_TIMEOUT_TM (624) - Incremented in State 15 and 21, write only when not in those states
IF (hmip5state_prev <> 15) AND (hmip5state_prev < 21) THEN
    SCADA_write_623[1] := ANY_TO_WORD(hmicyp5mv504timeouttm);
    MSG_Write_SCADA_624(
        IN := TRUE,
        LocalCfg := LocalCfgWrite_c6_e1,
        LocalAddr := SCADA_write_624
    );
END_IF;

// RO_HPP_SD_On (625) - Set in state machine (State 20 = TRUE, others = FALSE)
IF hmip5state_prev <= 21 THEN
	SCADA_write_625[1].0 := hmicyp5rohppsdon;
	MSG_Write_SCADA_625(
		IN := TRUE,
		LocalCfg := LocalCfgWrite_c6_e1,
		LocalAddr := SCADA_write_625
	);
END_IF;

// FLUSHING_MIN (626)
IF (hmip5state_prev <> 4) AND (hmip5state_prev <= 21) THEN
	SCADA_write_626[1] := ANY_TO_WORD(hmicyp5flushingmin);
	MSG_Write_SCADA_626(
		IN := TRUE,
		LocalCfg := LocalCfgWrite_c6_e1,
		LocalAddr := SCADA_write_626
	);
END_IF;

// RO_HIGH_PUMP_Shutdown (628) - Always FALSE in state machine (unused variable)
IF hmip5state_prev <= 21 THEN
	SCADA_write_628[1].0 := hmicyp5rohighpumpshutdown;
	MSG_Write_SCADA_628(
		IN := TRUE,
		LocalCfg := LocalCfgWrite_c6_e1,
		LocalAddr := SCADA_write_628
	);
END_IF;

// SD_FLUSHING_DONE_On (629) - Always FALSE in state machine (unused variable)
IF (hmip5state_prev <> 4) AND (hmip5state_prev <= 21) THEN
	SCADA_write_629[1].0 := hmicyp5sdflushingdoneon;
	MSG_Write_SCADA_629(
		IN := TRUE,
		LocalCfg := LocalCfgWrite_c6_e1,
		LocalAddr := SCADA_write_629
	);
END_IF;

// RO_SD_FLUSHING_MIN (631) - State 19 preserves value but no increment logic in plc5.py
IF hmip5state_prev <= 21 THEN
	SCADA_write_631[1] := ANY_TO_WORD(hmicyp5rosdflushingmin);
	MSG_Write_SCADA_631(
		IN := TRUE,
		LocalCfg := LocalCfgWrite_c6_e1,
		LocalAddr := SCADA_write_631
	);
END_IF;


PROGRAM Clock_Pulse_Generator
(*
================================================================================
Clock Pulse Generator for PLC5
================================================================================
Purpose: Generate periodic pulse signals for VSD run hour tracking

Sec_P:  Pulse signal that transitions TRUE once per second
        Used for incrementing RunHr and Total_RunHr for P501/P502 VSDs
        
Implementation: Uses TON timers with self-resetting logic to generate
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
Runtime Tracking for P501/P502 VSDs
================================================================================
Purpose: Track run hours and total run hours for variable speed drives
using the 1-second pulse from Clock_Pulse_Generator

Logic: Accumulate seconds when VSD is running (status = 2)
       When seconds reach 3600 (1 hour), increment RunHr and Total_RunHr
       Reset_RunHr signal clears current session hours only
================================================================================
*)

// P501 VSD run hour tracking - accumulate seconds when running
IF Sec_P AND (hmip501status = 2) THEN
    P501_Sec_Counter := P501_Sec_Counter + 1;
END_IF;

// When 3600 seconds (1 hour) accumulated, increment run hours
IF P501_Sec_Counter >= 3600 THEN
    hmip501runhr := hmip501runhr + 1;
    hmip501totalrunhr := hmip501totalrunhr + 1;
    P501_Sec_Counter := 0;  // Reset second counter
END_IF;

// Reset P501 run hour if requested (only current session hours, not total)
IF hmip501resetrunhr THEN
    hmip501runhr := 0;
    P501_Sec_Counter := 0;  // Also reset second counter
END_IF;

// P502 VSD run hour tracking - accumulate seconds when running
IF Sec_P AND (hmip502status = 2) THEN
    P502_Sec_Counter := P502_Sec_Counter + 1;
END_IF;

// When 3600 seconds (1 hour) accumulated, increment run hours
IF P502_Sec_Counter >= 3600 THEN
    hmip502runhr := hmip502runhr + 1;
    hmip502totalrunhr := hmip502totalrunhr + 1;
    P502_Sec_Counter := 0;  // Reset second counter
END_IF;

// Reset P502 run hour if requested (only current session hours, not total)
IF hmip502resetrunhr THEN
    hmip502runhr := 0;
    P502_Sec_Counter := 0;  // Also reset second counter
END_IF;

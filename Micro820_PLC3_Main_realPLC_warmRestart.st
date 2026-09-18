PROGRAM Warm_Restart
(*
================================================================================
Warm Restart Logic for PLC3 (UF Feed Stage)
================================================================================
Purpose: Software-triggered system reinitialization via Modbus
Industry Standard: Allen-Bradley Micro820 retains variable states across power
cycles and SCADA disconnects. This logic enables remote reset to initial state
without program redownload.

Usage: Write 1 to HMI.PLANT.Reset_System (Modbus register 964) to trigger reset
================================================================================
*)

// HMI.PLANT.Reset_System (offset 964 - Warm Restart Trigger)
MSG_Read_SCADA_964(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_964
);
IF MSG_Read_SCADA_964.Q THEN
    hmiplantresetsystem := SCADA_read_964[1].0;
    msg_write_SCADA_964_enable := TRUE;
ELSE
    msg_write_SCADA_964_enable := FALSE;
END_IF;

IF hmiplantresetsystem THEN
    (* Reset state machine variables *)
    hmip3state := 1;
    hmip3state_prev := 0;
    hmip3shutdown := TRUE;
    hmip3ready := FALSE;
    hmip3permissiveon := TRUE;
    hmip3tmphigh := FALSE;
    
    (* Reset SCADA control inputs *)
    hmiplantreseton := TRUE;
    hmiplantautoon := TRUE;
    hmiplantautooff := FALSE;
    hmiplantstop := FALSE;
    hmiplantstart := FALSE;
    hmiplantcriticalsdon := FALSE;
    hmiplanttmphigh := FALSE;
    
    (* Reset external dependencies *)
    hmilit401ahh := FALSE;
    hmilit401ah := FALSE;
    hmilit401al := FALSE;
    hmip205status := 1;
    hmimv201open := FALSE;
    hmip101status := 1;
    hmip602status := 1;
    
    (* Reset valve MV301 *)
    hmimv301auto := TRUE;
    hmimv301reset := TRUE;
    hmimv301fto := FALSE;
    hmimv301ftc := FALSE;
    hmimv301open := TRUE;
    hmimv301close := FALSE;
    hmimv301status := 1;
    hmimv301avl := TRUE;
    
    (* Reset valve MV302 *)
    hmimv302auto := TRUE;
    hmimv302reset := TRUE;
    hmimv302fto := FALSE;
    hmimv302ftc := FALSE;
    hmimv302open := TRUE;
    hmimv302close := FALSE;
    hmimv302status := 1;
    hmimv302avl := TRUE;
    
    (* Reset valve MV303 *)
    hmimv303auto := TRUE;
    hmimv303reset := TRUE;
    hmimv303fto := FALSE;
    hmimv303ftc := FALSE;
    hmimv303open := TRUE;
    hmimv303close := FALSE;
    hmimv303status := 1;
    hmimv303avl := TRUE;
    
    (* Reset valve MV304 *)
    hmimv304auto := TRUE;
    hmimv304reset := TRUE;
    hmimv304fto := FALSE;
    hmimv304ftc := FALSE;
    hmimv304open := TRUE;
    hmimv304close := FALSE;
    hmimv304status := 1;
    hmimv304avl := TRUE;
    
    (* Reset pumps P301 and P302 *)
    hmip301auto := TRUE;
    hmip301reset := FALSE;
    hmip301status := 1;
    hmip301fault := FALSE;
    hmip301avl := TRUE;
    hmip301permissive := -1;
    hmip301msgpermissive := 0;
    hmip301sd := 0;
    hmip301shutdown := 0;
    hmip301msgshutdown := 0;
    
    hmip302auto := TRUE;
    hmip302reset := FALSE;
    hmip302status := 1;
    hmip302fault := FALSE;
    hmip302avl := TRUE;
    hmip302permissive := -1;
    hmip302msgpermissive := 0;
    hmip302sd := 0;
    hmip302shutdown := 0;
    hmip302msgshutdown := 0;
    
    (* Reset LIT301 alarms *)
    hmilit301hty := TRUE;
    hmilit301ahh := FALSE;
    hmilit301ah := FALSE;
    hmilit301al := FALSE;
    hmilit301all := FALSE;
    hmilit301pv := 0.0;
    
    (* Reset FIT301 alarms *)
    hmifit301hty := FALSE;
    hmifit301ahh := FALSE;
    hmifit301ah := FALSE;
    hmifit301al := FALSE;
    hmifit301all := FALSE;
    
    (* Reset switch alarms *)
    hmipsh301alarm := FALSE;
    hmipsh301delay := 0;
    hmidpsh301alarm := FALSE;
    hmidpsh301delay := 0;
    
    (* Reset DPIT301 alarms *)
    hmidpit301hty := TRUE;
    hmidpit301ahh := FALSE;
    hmidpit301ah := FALSE;
    hmidpit301al := FALSE;
    hmidpit301all := FALSE;
    
    (* Reset UF pump duty selector *)
    hmiufbothpmpnotavl := FALSE;
    hmiufselectedpmpnotavl := FALSE;
    hmiufpumprunning := FALSE;
    hmipufdutyselection := 1;
    
    (* Reset cycle counters *)
    hmicyp3ufrefillsec := 0;
    hmicyp3uffiltrationmin := 0;
    hmicyp3backwashsec := 0;
    hmicyp3cipcleaningsec := 0;
    hmicyp3drainsec := 0;
    hmicyp3bwcnt := 0;
    
    (* Reset setpoints - keep default values *)
    hmicyp3ufrefillsecsp := 30;
    hmicyp3uffiltrationminsp := 3;
    hmicyp3backwashsecsp := 30;
    hmicyp3drainsecsp := 30;
    hmicyp3cipcleaningsecsp := 0;
    
    (* Reset intermediate control signals *)
    Mid_MV301_AutoInp := FALSE;
    Mid_MV302_AutoInp := FALSE;
    Mid_MV303_AutoInp := FALSE;
    Mid_MV304_AutoInp := FALSE;
    Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
    Mid_P602_AutoInp := FALSE;
    Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
    Mid_NEXT := FALSE;
    
    (* Reset plant I/O to safe states *)
    IO_MV301_DI_ZSO := FALSE;
    IO_MV301_DI_ZSC := TRUE;
    IO_MV302_DI_ZSO := FALSE;
    IO_MV302_DI_ZSC := TRUE;
    IO_MV303_DI_ZSO := FALSE;
    IO_MV303_DI_ZSC := TRUE;
    IO_MV304_DI_ZSO := FALSE;
    IO_MV304_DI_ZSC := TRUE;
    IO_P301_DI_Run := FALSE;
    IO_P302_DI_Run := FALSE;
    IO_PSH301_DI_LS := FALSE;
    IO_DPSH301_DI_LS := FALSE;
    
    IO_MV301_DO_Open := FALSE;
    IO_MV301_DO_Close := TRUE;
    IO_MV302_DO_Open := FALSE;
    IO_MV302_DO_Close := TRUE;
    IO_MV303_DO_Open := FALSE;
    IO_MV303_DO_Close := TRUE;
    IO_MV304_DO_Open := FALSE;
    IO_MV304_DO_Close := TRUE;
    IO_P301_DO_Start := FALSE;
    IO_P302_DO_Start := FALSE;
    
    (* Auto-clear the reset flag *)
    hmiplantresetsystem := FALSE;
END_IF;

SCADA_write_964[1].0 := hmiplantresetsystem;
MSG_Write_SCADA_964(
    IN := msg_write_SCADA_964_enable,
    LocalCfg := LocalCfgWrite_c6,
    LocalAddr := SCADA_write_964
);


PROGRAM Modbus_SCADA_READ_CORE
(*
================================================================================
SCADA Read - Core Tags (Always Read)
================================================================================
*)
// Read common control signals (offsets 0, 1, 2, 4, 6)
// HMI.PLANT.Reset_On (0), Auto_On (1), Auto_Off (2), Stop (4), Critical_SD_On (6)
MSG_Read_SCADA_Core(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e7,
	LocalAddr := SCADA_read_core
);
msg_read_scada_core_q := MSG_Read_SCADA_Core.Q;
IF MSG_Read_SCADA_Core.Q THEN
	// HMI.PLANT.Reset_On (offset 0)
    hmiplantreseton := SCADA_read_core[1].0;
	// HMI.PLANT.Auto_On (offset 1)
    hmiplantautoon := SCADA_read_core[2].0;
	// HMI.PLANT.Auto_Off (offset 2)
    hmiplantautooff := SCADA_read_core[3].0;
	// HMI.PLANT.Stop (offset 4)
    hmiplantstop := SCADA_read_core[5].0;
	// HMI.PLANT.Critical_SD_On (offset 6)
    hmiplantcriticalsdon := SCADA_read_core[7].0;
END_IF;

// HMI.LIT401.AHH (offset 473)
MSG_Read_SCADA_473(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_473
);
IF MSG_Read_SCADA_473.Q THEN
	hmilit401ahh := SCADA_read_473[1].0;
END_IF;

// HMI.MV201.Open (offset 122)
MSG_Read_SCADA_122(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_122
);
IF MSG_Read_SCADA_122.Q THEN
    hmimv201open := SCADA_read_122[1].0;
END_IF;

// HMI.P101.Status (offset 94)
MSG_Read_SCADA_94(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_94
);
IF MSG_Read_SCADA_94.Q THEN
    hmip101status := ANY_TO_INT(SCADA_read_94[1]);
END_IF;


PROGRAM Modbus_SCADA_READ_S1_ST
// Read (Cmd = 3), Targetcfg address 5 = plantstart
IF msg_read_scada_core_q THEN
	// HMI.PLANT.Start (offset 5)
    hmiplantstart := SCADA_read_core[6].0;
END_IF;


PROGRAM Modbus_SCADA_READ_Sn_ST
// HMI.LIT401.AH (offset 474)
MSG_Read_SCADA_474(
	IN := (hmip3state > 1), 
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_474
);
IF (hmip3state > 1) AND MSG_Read_SCADA_474.Q THEN
    hmilit401ah := SCADA_read_474[1].0;
END_IF;

// HMI.P602.Status (offset 928)
MSG_Read_SCADA_928(
	IN := ((hmip3state = 11) OR (hmip3state = 13)),
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_928
);
IF ((hmip3state = 11) OR (hmip3state = 13)) AND MSG_Read_SCADA_928.Q THEN
    hmip602status := ANY_TO_INT(SCADA_read_928[1]);
END_IF;

// HMI.P205.Status (offset 207)
MSG_Read_SCADA_207(
	IN := ((hmip3state = 17) OR (hmip3state = 19)),
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_207
);
IF ((hmip3state = 17) OR (hmip3state = 19)) AND MSG_Read_SCADA_207.Q THEN
    hmip205status := ANY_TO_INT(SCADA_read_207[1]);
END_IF;

// HMI.LIT401.AL (offset 475)
MSG_Read_SCADA_475(
	IN := (hmip3state = 99),
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_475
);
IF (hmip3state = 99) AND MSG_Read_SCADA_475.Q THEN
    hmilit401al := SCADA_read_475[1].0;
END_IF;


PROGRAM Modbus_L1_Read
// PLC as a Modbus client communicates with the Modbus server running on a 
// local machine with IP 192.168.137.1
// Plant read (100-117)
MSG_READ_L1_100(
	IN := TRUE, 
	LocalCfg := LocalCfgRead_c3_L1_e18,
	LocalAddr := L1_read_100
);
IF MSG_READ_L1_100.Q THEN
	IO_MV301_DI_ZSO := L1_read_100[1].0;
	IO_MV301_DI_ZSC := L1_read_100[2].0;
	IO_MV302_DI_ZSO := L1_read_100[3].0;
	IO_MV302_DI_ZSC := L1_read_100[4].0;
	IO_MV303_DI_ZSO := L1_read_100[5].0;
	IO_MV303_DI_ZSC := L1_read_100[6].0;
	IO_MV304_DI_ZSO := L1_read_100[7].0;
	IO_MV304_DI_ZSC := L1_read_100[8].0;
	IO_P301_DI_Run := L1_read_100[9].0;
	IO_P302_DI_Run := L1_read_100[10].0;
	IO_PSH301_DI_LS := L1_read_100[11].0;
	IO_DPSH301_DI_LS := L1_read_100[12].0;
    tempReal[0] := L1_read_100[13];
    tempReal[1] := L1_read_100[14];
    hmilit301ahh := L1_read_100[15].0;
    hmilit301ah := L1_read_100[16].0;
    hmilit301al := L1_read_100[17].0;
    hmilit301all := L1_read_100[18].0;
END_IF;
COP_L1_112_113_TO_lit301pv(
    Enable := TRUE,
    Src := tempReal,
    Dest := hmilit301pv,
    Length := 1
);


PROGRAM Plant_Control
IF hmiplantreseton THEN
    hmimv301reset := TRUE;
    hmimv302reset := TRUE;
    hmimv303reset := TRUE;
    hmimv304reset := TRUE;
    hmip301reset := TRUE;
    hmip302reset := TRUE;
END_IF;

IF hmiplantautoon THEN
    hmimv301auto := TRUE;
    hmimv302auto := TRUE;
    hmimv303auto := TRUE;
    hmimv304auto := TRUE;
    hmip301auto := TRUE;
    hmip302auto := TRUE;
END_IF;

IF hmiplantautooff THEN
    hmimv301auto := FALSE;
    hmimv302auto := FALSE;
    hmimv303auto := FALSE;
    hmimv304auto := FALSE;
    hmip301auto := FALSE;
    hmip302auto := FALSE;
END_IF;


PROGRAM Permissive_Shutdown
(*
================================================================================
Stage 3: Permissive calculations and Shutdown logic
================================================================================
*)
hmip3permissiveon := hmimv301avl AND hmimv302avl AND hmimv303avl AND 
                     hmimv304avl AND (hmip301avl OR hmip302avl);

TON_FIT301_P1_TM(
	IN := (hmifit301all AND (hmip301status = 2)),
	PT := T#6s
);

TON_FIT301_P2_TM(
	IN := (hmifit301all AND (hmip302status = 2)),
	PT := T#6s
);

(* P301 Permissive calculations *)
hmip301permissive.0 := NOT hmilit301all;
hmip301permissive.1 := NOT hmilit401ahh;
hmip301permissive.2 := (hmimv302status = 2) OR (hmimv304status = 2);

hmip301msgpermissive.1 := hmip301permissive.0;
hmip301msgpermissive.2 := hmip301permissive.1;
hmip301msgpermissive.3 := hmip301permissive.2;

(* P301 Shutdown calculations *)
hmip301sd.0 := hmilit301all;
hmip301sd.1 := hmilit401ahh;
hmip301sd.2 := hmipsh301alarm;
hmip301sd.3 := FALSE;
hmip301sd.4 := (hmip301status = 2) AND (hmimv302status <> 2) AND (hmimv304status <> 2);

hmip301msgshutdown.1 := hmip301shutdown.0;
hmip301msgshutdown.2 := hmip301shutdown.1;
hmip301msgshutdown.3 := hmip301shutdown.2;
hmip301msgshutdown.4 := hmip301shutdown.3;
hmip301msgshutdown.5 := hmip301shutdown.4;

(* P302 Permissive calculations *)
hmip302permissive.0 := NOT hmilit301all;
hmip302permissive.1 := NOT hmilit401ahh;
hmip302permissive.2 := (hmimv302status = 2) OR (hmimv304status = 2);

hmip302msgpermissive.1 := hmip302permissive.0;
hmip302msgpermissive.2 := hmip302permissive.1;
hmip302msgpermissive.3 := hmip302permissive.2;

(* P302 Shutdown calculations *)
hmip302sd.0 := hmilit301all;
hmip302sd.1 := hmilit401ahh;
hmip302sd.2 := hmipsh301alarm;
hmip302sd.3 := FALSE;
hmip302sd.4 := (hmip302status = 2) AND (hmimv302status <> 2) AND (hmimv304status <> 2);

hmip302msgshutdown.1 := hmip302shutdown.0;
hmip302msgshutdown.2 := hmip302shutdown.1;
hmip302msgshutdown.3 := hmip302shutdown.2;
hmip302msgshutdown.4 := hmip302shutdown.3;
hmip302msgshutdown.5 := hmip302shutdown.4;

(* Shutdown logic *)
IF hmiplantstop OR hmiplantcriticalsdon THEN
    hmip3shutdown := TRUE;
END_IF;

(* TMP High determination *)
IF hmidpit301hty THEN
    hmiplanttmphigh := hmidpit301ah;
ELSE
    hmiplanttmphigh := hmidpsh301alarm;
END_IF;

IF hmiplanttmphigh THEN
    hmip3tmphigh := TRUE;
ELSE
    hmip3tmphigh := FALSE;
END_IF;

(* LIT401 high alarm triggers state 99 *)
IF hmilit401ah AND (hmip3state > 1) THEN
    hmip3state := 99;
END_IF;


PROGRAM State_Machine
(*
================================================================================
Stage 5: State machine - UF Feed Control (19 states + fault state 99)
================================================================================
Process Description:
State 1:  Standby
State 2:  Initial valve positioning (MV304 opening)
State 3:  Feed pump startup (P301/P302)
State 4:  UF Refill phase
State 5:  MV302 opening
State 6:  MV304 closing
State 7:  UF Filtration phase
State 8:  Feed pump shutdown
State 9:  End of filtration cycle
State 10: MV301 and MV303 opening
State 11: Backwash pump (P602) startup
State 12: Backwash phase
State 13: P602 shutdown
State 14: MV301 closing
State 15: MV304 opening
State 16: Drain phase
State 17: CIP cleaning startup (P205)
State 18: CIP cleaning phase
State 19: P205 shutdown
State 99: Fault state
================================================================================
*)

CASE hmip3state OF
    1: (* Standby *)
        hmip3state_prev := 1;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := FALSE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        hmip3shutdown := FALSE;
        
        IF hmip3permissiveon AND hmiplantstart THEN
            hmip3state := 2;
        END_IF;
    
    2: (* Initial valve positioning - MV304 opening *)
        hmip3state_prev := 2;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := FALSE;
        Mid_MV304_AutoInp := NOT hmilit301all AND NOT hmilit401ah;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF (hmimv304status = 2) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 3;
        END_IF;
    
    3: (* Feed pump startup *)
        hmip3state_prev := 3;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := FALSE;
        Mid_MV304_AutoInp := TRUE;
        Mid_P_UF_FEED_DUTY_AutoInp := TRUE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF (hmip301status = 2) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 4;
        END_IF;
    
    4: (* UF Refill - increment counter *)
        hmip3state_prev := 4;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := FALSE;
        Mid_MV304_AutoInp := TRUE;
        Mid_P_UF_FEED_DUTY_AutoInp := TRUE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF Sec_P THEN
            hmicyp3ufrefillsec := hmicyp3ufrefillsec + 1;
        END_IF;
        
        IF (hmicyp3ufrefillsec > hmicyp3ufrefillsecsp) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 5;
        END_IF;
    
    5: (* MV302 opening *)
        hmip3state_prev := 5;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := TRUE;
        Mid_MV303_AutoInp := FALSE;
        Mid_MV304_AutoInp := TRUE;
        Mid_P_UF_FEED_DUTY_AutoInp := TRUE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF (hmimv302status = 2) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 6;
        END_IF;
    
    6: (* MV304 closing *)
        hmip3state_prev := 6;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := TRUE;
        Mid_MV303_AutoInp := FALSE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := TRUE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec :=  0;
        
        IF (hmimv304status = 1) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 7;
        END_IF;
    
    7: (* UF Filtration - increment minute counter *)
        hmip3state_prev := 7;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := TRUE;
        Mid_MV303_AutoInp := FALSE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := TRUE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF hmip3tmphigh THEN
            hmip3state := 8;
        ELSE
            IF Min_P THEN
                hmicyp3uffiltrationmin := hmicyp3uffiltrationmin + 1;
            END_IF;
        END_IF;
        
        IF (hmicyp3uffiltrationmin >= hmicyp3uffiltrationminsp) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 8;
        END_IF;
        
        IF hmip3shutdown AND hmilit401ah THEN
            Mid_NEXT := FALSE;
            hmip3state := 8;
        END_IF;
    
    8: (* Feed pump shutdown *)
        hmip3state_prev := 8;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := TRUE;
        Mid_MV303_AutoInp := FALSE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF (hmip301status <> 2) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 9;
        END_IF;
    
    9: (* End of filtration cycle *)
        hmip3state_prev := 9;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := FALSE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF hmip3shutdown THEN
            hmip3state := 1;
        ELSIF (hmimv302status = 1) OR Mid_NEXT THEN
            IF NOT hmip3shutdown THEN
                Mid_NEXT := FALSE;
                hmip3state := 10;
            END_IF;
        END_IF;
    
    10: (* MV301 and MV303 opening *)
        hmip3state_prev := 10;
        Mid_MV301_AutoInp := TRUE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := TRUE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF ((hmimv301status = 2) AND (hmimv303status = 2)) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 11;
        END_IF;
    
    11: (* Backwash pump startup *)
        hmip3state_prev := 11;
        Mid_MV301_AutoInp := TRUE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := TRUE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := TRUE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF (hmip602status = 2) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 12;
        END_IF;
    
    12: (* Backwash phase - increment counter *)
        hmip3state_prev := 12;
        Mid_MV301_AutoInp := TRUE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := TRUE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := TRUE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF Sec_P THEN
            hmicyp3backwashsec := hmicyp3backwashsec + 1;
        END_IF;
        
        IF (hmicyp3backwashsec > hmicyp3backwashsecsp) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmicyp3bwcnt := hmicyp3bwcnt + 1;
            hmip3state := 13;
        END_IF;
    
    13: (* P602 shutdown *)
        hmip3state_prev := 13;
        Mid_MV301_AutoInp := TRUE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := TRUE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF (hmip602status = 1) OR Mid_NEXT THEN
            hmip3state := 14;
        END_IF;
    
    14: (* MV301 closing *)
        hmip3state_prev := 14;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := TRUE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF (hmimv301status = 1) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 15;
        END_IF;
    
    15: (* MV304 opening *)
        hmip3state_prev := 15;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := TRUE;
        Mid_MV304_AutoInp := TRUE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF (hmimv304status = 2) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 16;
        END_IF;
    
    16: (* Drain phase - increment counter *)
        hmip3state_prev := 16;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := TRUE;
        Mid_MV304_AutoInp := TRUE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        
        IF Sec_P THEN
            hmicyp3drainsec := hmicyp3drainsec + 1;
        END_IF;
        
        IF (hmicyp3drainsec > hmicyp3drainsecsp) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 4;  (* Return to refill *)
        END_IF;
    
    17: (* CIP cleaning startup *)
        hmip3state_prev := 17;
        Mid_MV301_AutoInp := TRUE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := TRUE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := TRUE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF (hmip205status = 2) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 18;
        END_IF;
    
    18: (* CIP cleaning phase - increment counter *)
        hmip3state_prev := 18;
        Mid_MV301_AutoInp := TRUE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := TRUE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := TRUE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3drainsec := 0;
        
        IF Sec_P THEN
            hmicyp3cipcleaningsec := hmicyp3cipcleaningsec + 1;
        END_IF;
        
        IF (hmicyp3cipcleaningsec > hmicyp3cipcleaningsecsp) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 19;
        END_IF;
    
    19: (* P205 shutdown *)
        hmip3state_prev := 19;
        Mid_MV301_AutoInp := TRUE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := TRUE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3drainsec := 0;
        
        IF (hmip205status <> 2) OR Mid_NEXT THEN
            Mid_NEXT := FALSE;
            hmip3state := 14;  (* Return to MV301 closing *)
        END_IF;
    
    99: (* Fault state *)
        hmip3state_prev := 99;
        Mid_MV301_AutoInp := FALSE;
        Mid_MV302_AutoInp := FALSE;
        Mid_MV303_AutoInp := FALSE;
        Mid_MV304_AutoInp := FALSE;
        Mid_P_UF_FEED_DUTY_AutoInp := FALSE;
        Mid_P602_AutoInp := FALSE;
        Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
        
        hmicyp3ufrefillsec := 0;
        hmicyp3uffiltrationmin := 0;
        hmicyp3backwashsec := 0;
        hmicyp3cipcleaningsec := 0;
        hmicyp3drainsec := 0;
        
        IF (hmilit401al AND NOT hmip3shutdown) OR hmiplantstart THEN
            hmip3state := 2;
        ELSIF hmilit401ah AND hmip3shutdown THEN
            hmip3state := 1;
        END_IF;
    
ELSE
    (* Invalid state - return to standby *)
    hmip3state := 1;
END_CASE;


PROGRAM Function_Blocks
(*
================================================================================
Stage 6: Function block execution
================================================================================
*)

(* MV301 Function Block *)
MV301_FB(
    AutoInp := Mid_MV301_AutoInp,
    Auto := hmimv301auto,
    Reset := hmimv301reset,
    DI_ZSO := IO_MV301_DI_ZSO,
    DI_ZSC := IO_MV301_DI_ZSC,
    FTO_Init := hmimv301fto,
    FTC_Init := hmimv301ftc,
    Cmd_Open_Init := hmimv301open,
    Cmd_Close_Init := hmimv301close
);
IF MV301_FB.Status <> -99 THEN
    hmimv301status := MV301_FB.Status;
END_IF;
hmimv301avl := MV301_FB.Avl;
IO_MV301_DO_Open := MV301_FB.DO_Open;
IO_MV301_DO_Close := MV301_FB.DO_Close;

(* MV302 Function Block *)
MV302_FB(
    AutoInp := Mid_MV302_AutoInp,
    Auto := hmimv302auto,
    Reset := hmimv302reset,
    DI_ZSO := IO_MV302_DI_ZSO,
    DI_ZSC := IO_MV302_DI_ZSC,
    FTO_Init := hmimv302fto,
    FTC_Init := hmimv302ftc,
    Cmd_Open_Init := hmimv302open,
    Cmd_Close_Init := hmimv302close
);
IF MV302_FB.Status <> -99 THEN
    hmimv302status := MV302_FB.Status;
END_IF;
hmimv302avl := MV302_FB.Avl;
IO_MV302_DO_Open := MV302_FB.DO_Open;
IO_MV302_DO_Close := MV302_FB.DO_Close;

(* MV303 Function Block *)
MV303_FB(
    AutoInp := Mid_MV303_AutoInp,
    Auto :=  hmimv303auto,
    Reset := hmimv303reset,
    DI_ZSO := IO_MV303_DI_ZSO,
    DI_ZSC := IO_MV303_DI_ZSC,
    FTO_Init := hmimv303fto,
    FTC_Init := hmimv303ftc,
    Cmd_Open_Init := hmimv303open,
    Cmd_Close_Init := hmimv303close
);
IF MV303_FB.Status <> -99 THEN
    hmimv303status := MV303_FB.Status;
END_IF;
hmimv303avl := MV303_FB.Avl;
IO_MV303_DO_Open := MV303_FB.DO_Open;
IO_MV303_DO_Close := MV303_FB.DO_Close;

(* MV304 Function Block *)
MV304_FB(
    AutoInp := Mid_MV304_AutoInp,
    Auto := hmimv304auto,
    Reset := hmimv304reset,
    DI_ZSO := IO_MV304_DI_ZSO,
    DI_ZSC := IO_MV304_DI_ZSC,
    FTO_Init := hmimv304fto,
    FTC_Init := hmimv304ftc,
    Cmd_Open_Init := hmimv304open,
    Cmd_Close_Init := hmimv304close
);
IF MV304_FB.Status <> -99 THEN
    hmimv304status := MV304_FB.Status;
END_IF;
hmimv304avl := MV304_FB.Avl;
IO_MV304_DO_Open := MV304_FB.DO_Open;
IO_MV304_DO_Close := MV304_FB.DO_Close;

(* PSH301 Switch Function Block *)
PSH301_FB(
	DI_LS := IO_PSH301_DI_LS,
	DelayMs := hmipsh301delay
);
hmipsh301alarm := PSH301_FB.Status;

(* DPSH301 Switch Function Block *)
DPSH301_FB(
	DI_LS := IO_DPSH301_DI_LS,
	DelayMs := hmidpsh301delay
);
hmidpsh301alarm := DPSH301_FB.Status;

(* P_UF_FEED_DUTY Function Block *)
P_UF_FEED_DUTY_FB(
    AutoInp := Mid_P_UF_FEED_DUTY_AutoInp,
    Pmp1_Status := hmip301status,
    Pmp1_Avl := hmip301avl,
    Pmp2_Status := hmip302status,
    Pmp2_Avl := hmip302avl,
    Selection := hmipufdutyselection
);
hmiufbothpmpnotavl := P_UF_FEED_DUTY_FB.Both_Pmp_Not_Avl;
hmiufselectedpmpnotavl := P_UF_FEED_DUTY_FB.Selected_Pmp_Not_Avl;
hmiufpumprunning := P_UF_FEED_DUTY_FB.Pump_Running;

(* P301 Function Block *)
P301_FB(
    Start := P_UF_FEED_DUTY_FB.Start_Pmp1,
    Auto := hmip301auto,
    Reset := hmip301reset,
    Permissive := hmip301permissive,
    SD := hmip301sd,
    DI_Run := IO_P301_DI_Run,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P301_FB.Status <> -99 THEN
    hmip301status := P301_FB.Status;
END_IF;
hmip301fault := P301_FB.Fault;
hmip301avl := P301_FB.Avl;
hmip301shutdown := P301_FB.Shutdown;
IO_P301_DO_Start := P301_FB.DO_Start;

(* P302 Function Block *)
P302_FB(
    Start := P_UF_FEED_DUTY_FB.Start_Pmp2,
    Auto := hmip302auto,
    Reset := hmip302reset,
    Permissive := hmip302permissive,
    SD := hmip302sd,
    DI_Run := IO_P302_DI_Run,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P302_FB.Status <> -99 THEN
    hmip302status := P302_FB.Status;
END_IF;
hmip302fault := P302_FB.Fault;
hmip302avl := P302_FB.Avl;
hmip302shutdown := P302_FB.Shutdown;
IO_P302_DO_Start := P302_FB.DO_Start;


PROGRAM Modbus_L1_Write
(*
================================================================================
Stage 7: Write outputs to Plant Simulator
================================================================================
*)
// Plant write (200-209)
L1_write_200[1].0 := IO_MV301_DO_Open;
L1_write_200[2].0 := IO_MV301_DO_Close;
L1_write_200[3].0 := IO_MV302_DO_Open;
L1_write_200[4].0 := IO_MV302_DO_Close;
L1_write_200[5].0 := IO_MV303_DO_Open;
L1_write_200[6].0 := IO_MV303_DO_Close;
L1_write_200[7].0 := IO_MV304_DO_Open;
L1_write_200[8].0 := IO_MV304_DO_Close;
L1_write_200[9].0 := IO_P301_DO_Start;
L1_write_200[10].0 := IO_P302_DO_Start;

MSG_WRITE_L1_200(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_L1_e10,
	LocalAddr := L1_write_200
);


PROGRAM Modbus_SCADA_Write
(*
================================================================================
Stage 8: Write status back to SCADA
================================================================================
*)

(* Conditional write - Cycle timers (offsets 331-335) *)
// Write HMI.Cy_P3.UF_REFILL_SEC (331)
// Write in all states except state 4 without Sec_P
IF (hmip3state_prev <> 4) OR (hmip3state_prev = 4 AND Sec_P) THEN
    SCADA_write_331[1] := ANY_TO_WORD(hmicyp3ufrefillsec);
    MSG_Write_SCADA_331(
        IN := TRUE,
        LocalCfg := LocalCfgWrite_c6,
        LocalAddr := SCADA_write_331
    );
END_IF;

// Write HMI.Cy_P3.UF_FILTRATION_MIN (332) 
// Write in all states except state 7 without Min_P
IF (hmip3state_prev <> 7) OR (hmip3state_prev = 7 AND Min_P) THEN
    SCADA_write_332[1] := ANY_TO_WORD(hmicyp3uffiltrationmin);
    MSG_Write_SCADA_332(
        IN := TRUE,
        LocalCfg := LocalCfgWrite_c6,
        LocalAddr := SCADA_write_332
    );
END_IF;

// Write HMI.Cy_P3.BACKWASH_SEC (333)
// Write in all states except state 12 without Sec_P
IF (hmip3state_prev <> 12) OR (hmip3state_prev = 12 AND Sec_P) THEN
    SCADA_write_332[1] := ANY_TO_WORD(hmicyp3backwashsec);
    MSG_Write_SCADA_333(
        IN := TRUE,
        LocalCfg := LocalCfgWrite_c6,
        LocalAddr := SCADA_write_333
    );
END_IF;

// Write HMI.Cy_P3.CIP_CLEANING_SEC (334)
// Write in all states except state 18 without Sec_P
IF (hmip3state_prev <> 18) OR (hmip3state_prev = 18 AND Sec_P) THEN
    SCADA_write_334[1] := ANY_TO_WORD(hmicyp3cipcleaningsec);
    MSG_Write_SCADA_334(
        IN := TRUE,
        LocalCfg := LocalCfgWrite_c6,
        LocalAddr := SCADA_write_334
    );
END_IF;

// Write HMI.Cy_P3.DRAIN_SEC (335)
// Write in all states except state 16 without Sec_P
IF (hmip3state_prev <> 16) OR (hmip3state_prev = 16 AND Sec_P) THEN
    SCADA_write_335[1] := ANY_TO_WORD(hmicyp3drainsec);
    MSG_Write_SCADA_335(
        IN := TRUE,
        LocalCfg := LocalCfgWrite_c6,
        LocalAddr := SCADA_write_335
    );
END_IF;

// Write HMI.P3.State (offset 20) - Independent MSG for each state transition
IF hmilit401ah AND (hmip3state = 99) THEN
    SCADA_write_20[1] := ANY_TO_WORD(99);
ELSIF hmip3state_prev > 19 AND hmip3state_prev <> 99 THEN
    SCADA_write_20[1] := ANY_TO_WORD(1);
ELSE
    SCADA_write_20[1] := ANY_TO_WORD(hmip3state);
END_IF;

MSG_P3State_To99(
    IN := (hmilit401ah AND hmip3state = 99),
    LocalCfg := LocalCfgWrite_c6,
    LocalAddr := SCADA_write_20
);
MSG_P3State_1to2(IN := (hmip3state_prev = 1 AND hmip3state = 2), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_2to3(IN := (hmip3state_prev = 2 AND hmip3state = 3), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_3to4(IN := (hmip3state_prev = 3 AND hmip3state = 4), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_4to5(IN := (hmip3state_prev = 4 AND hmip3state = 5), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_5to6(IN := (hmip3state_prev = 5 AND hmip3state = 6), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_6to7(IN := (hmip3state_prev = 6 AND hmip3state = 7), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_7to8(IN := (hmip3state_prev = 7 AND hmip3state = 8), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_8to9(IN := (hmip3state_prev = 8 AND hmip3state = 9), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_9to1(IN := (hmip3state_prev = 9 AND hmip3state = 1), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_9to10(IN := (hmip3state_prev = 9 AND hmip3state = 10), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_10to11(IN := (hmip3state_prev = 10 AND hmip3state = 11), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_11to12(IN := (hmip3state_prev = 11 AND hmip3state = 12), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_12to13(IN := (hmip3state_prev = 12 AND hmip3state = 13), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_13to14(IN := (hmip3state_prev = 13 AND hmip3state = 14), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_14to15(IN := (hmip3state_prev = 14 AND hmip3state = 15), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_15to16(IN := (hmip3state_prev = 15 AND hmip3state = 16), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_16to4(IN := (hmip3state_prev = 16 AND hmip3state = 4), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_17to18(IN := (hmip3state_prev = 17 AND hmip3state = 18), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_18to19(IN := (hmip3state_prev = 18 AND hmip3state = 19), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_19to14(IN := (hmip3state_prev = 19 AND hmip3state = 14), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_99to1(IN := (hmip3state_prev = 99 AND hmip3state = 1), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_99to2(IN := (hmip3state_prev = 99 AND hmip3state = 2), LocalCfg := LocalCfgWrite_c6, LocalAddr := SCADA_write_20);
MSG_P3State_InvalidTo1(
    IN := (hmip3state_prev > 19 AND hmip3state_prev <> 99),
    LocalCfg := LocalCfgWrite_c6,
    LocalAddr := SCADA_write_20
);

(* Unconditional write *)
// Write HMI.PLANT.TMP_High (7)
IF hmidpit301hty THEN
    SCADA_write_7[1].0 := hmidpit301ah;
ELSE
    SCADA_write_7[1].0 := hmidpsh301alarm;
END_IF;
MSG_Write_SCADA_7(
    IN := TRUE,
    LocalCfg := LocalCfgWrite_c6,
    LocalAddr := SCADA_write_7
);

// Write valve statuses (MV301-MV304)
// HMI.MV301.Auto (427), Reset (428), FTO (429), FTC (430), Status (431), Avl (432)
SCADA_write_427_432[1].0 := hmimv301auto;
SCADA_write_427_432[2].0 := hmimv301reset;
SCADA_write_427_432[3].0 := hmimv301fto;
SCADA_write_427_432[4].0 := hmimv301ftc;
SCADA_write_427_432[5] := ANY_TO_WORD(hmimv301status);
SCADA_write_427_432[6].0 := hmimv301avl;
MSG_Write_SCADA_427_432(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e6,
	LocalAddr := SCADA_write_427_432
);

// HMI.MV302.Auto (436), Reset (437), FTO (438), FTC (439), Status (440), Avl (441)
SCADA_write_436_441[1].0 := hmimv302auto;
SCADA_write_436_441[2].0 := hmimv302reset;
SCADA_write_436_441[3].0 := hmimv302fto;
SCADA_write_436_441[4].0 := hmimv302ftc;
SCADA_write_436_441[5] := ANY_TO_WORD(hmimv302status);
SCADA_write_436_441[6].0 := hmimv302avl;
MSG_Write_SCADA_436_441(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e6,
	LocalAddr := SCADA_write_436_441
);

// HMI.MV303.Auto (445), Reset (446), FTO (447), FTC (448), Status (449), Avl (450)
SCADA_write_445_450[1].0 := hmimv303auto;
SCADA_write_445_450[2].0 := hmimv303reset;
SCADA_write_445_450[3].0 := hmimv303fto;
SCADA_write_445_450[4].0 := hmimv303ftc;
SCADA_write_445_450[5] := ANY_TO_WORD(hmimv303status);
SCADA_write_445_450[6].0 := hmimv303avl;
MSG_Write_SCADA_445_450(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e6,
	LocalAddr := SCADA_write_445_450
);

// HMI.MV304.Auto (454), Reset (455), FTO (456), FTC (457), Status (458), Avl (459)
SCADA_write_454_459[1].0 := hmimv304auto;
SCADA_write_454_459[2].0 := hmimv304reset;
SCADA_write_454_459[3].0 := hmimv304fto;
SCADA_write_454_459[4].0 := hmimv304ftc;
SCADA_write_454_459[5] := ANY_TO_WORD(hmimv304status);
SCADA_write_454_459[6].0 := hmimv304avl;
MSG_Write_SCADA_454_459(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e6,
	LocalAddr := SCADA_write_454_459
);

// Write pump P301 status
SCADA_write_357_372[1].0 := hmip301auto;
SCADA_write_357_372[2] := ANY_TO_WORD(hmip301permissive);
SCADA_write_357_372[3] := ANY_TO_WORD(hmip301msgpermissive);
SCADA_write_357_372[4] := ANY_TO_WORD(hmip301sd);
SCADA_write_357_372[5] := ANY_TO_WORD(hmip301msgshutdown);
SCADA_write_357_372[6].0 := hmip301reset;
SCADA_write_357_372[7] := 0;  (* Reset_RunHr *)
SCADA_write_357_372[8].0 := hmip301avl;
SCADA_write_357_372[9].0 := hmip301fault;
SCADA_write_357_372[10].0 := FALSE; (* FTS *)
SCADA_write_357_372[11].0 := FALSE; (* FTR *)
SCADA_write_357_372[12] := 0; (* RunHr *)
SCADA_write_357_372[13] := 0; (* Total_RunHr *)
SCADA_write_357_372[14] := ANY_TO_WORD(hmip301shutdown);
SCADA_write_357_372[15].0 := FALSE; (* Pump_Running *)
SCADA_write_357_372[16] := ANY_TO_WORD(hmip301status);
MSG_Write_SCADA_357_372(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e16,
	LocalAddr := SCADA_write_357_372
);

// Write pump P302 status
SCADA_write_373_388[1].0 := hmip302auto;
SCADA_write_373_388[2] := ANY_TO_WORD(hmip302permissive);
SCADA_write_373_388[3] := ANY_TO_WORD(hmip302msgpermissive);
SCADA_write_373_388[4] := ANY_TO_WORD(hmip302sd);
SCADA_write_373_388[5] := ANY_TO_WORD(hmip302msgshutdown);
SCADA_write_373_388[6].0 := hmip302reset;
SCADA_write_373_388[7] := 0;  (* Reset_RunHr *)
SCADA_write_373_388[8].0 := hmip302avl;
SCADA_write_373_388[9].0 := hmip302fault;
SCADA_write_373_388[10].0 := FALSE; (* FTS *)
SCADA_write_373_388[11].0 := FALSE; (* FTR *)
SCADA_write_373_388[12] := 0; (* RunHr *)
SCADA_write_373_388[13] := 0; (* Total_RunHr *)
SCADA_write_373_388[14] := ANY_TO_WORD(hmip302shutdown);
SCADA_write_373_388[15].0 := FALSE; (* Pump_Running *)
SCADA_write_373_388[16] := ANY_TO_WORD(hmip302status);
MSG_Write_SCADA_373_388(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c16_e16,
	LocalAddr := SCADA_write_373_388
);

// Write P602 (offset 330)
SCADA_write_330[1].0 := Mid_P602_AutoInp;
MSG_Write_SCADA_330(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c6,
	LocalAddr := SCADA_write_330
);

// Write UF duty selector status (offset 390)
SCADA_write_390_392[1].0 := hmiufbothpmpnotavl;
SCADA_write_390_392[2].0 := hmiufselectedpmpnotavl;
SCADA_write_390_392[3].0 := hmiufpumprunning;
MSG_Write_SCADA_390_392(
    IN := TRUE,
    LocalCfg := LocalCfgWrite_c16_e3,
    LocalAddr := SCADA_write_390_392
);

// Write LIT301 alarms (351-354) and level (355-356)
SCADA_write_351_356[1].0 := hmilit301ahh;
SCADA_write_351_356[2].0 := hmilit301ah;
SCADA_write_351_356[3].0 := hmilit301al;
SCADA_write_351_356[4].0 := hmilit301all;
COP_LIT101_Pv(
    Enable := TRUE,
    Src := hmilit301pv,
    Dest := SCADA_write_351_356[5],
    Length := 2
);
MSG_Write_SCADA_351_356(
    IN := TRUE,
    LocalCfg := LocalCfgWrite_c16_e6,
    LocalAddr := SCADA_write_351_356
);

// Write P3 permissive status
SCADA_write_18[1].0 := hmip3permissiveon;
MSG_Write_SCADA_18(
	IN := TRUE,	
	LocalCfg := LocalCfgWrite_c6,
	LocalAddr := SCADA_write_18
);

// Write P3 shutdown status
SCADA_write_19[1].0 := hmip3shutdown;
MSG_Write_SCADA_19(
	IN := TRUE,
	LocalCfg := LocalCfgWrite_c6,
	LocalAddr := SCADA_write_19
);


PROGRAM Clock_Pulse_Generator
(*
================================================================================
Clock Pulse Generator for PLC3
================================================================================
Purpose: Generate periodic pulse signals for state machine timing

Sec_P:  Pulse signal that transitions TRUE once per second
        Used for incrementing second-level timers (UF refill, backwash, drain, CIP)
        
Min_P:  Pulse signal that transitions TRUE once per minute (60 seconds)
        Used for incrementing minute-level timers (UF filtration)

Implementation: Uses TON timers with self-resetting logic to generate
                periodic pulses. Rising edge detection ensures clean
                single-scan pulse outputs.
================================================================================
*)

(* 1-Second Pulse Generator *)
TON_1Sec(IN := NOT TON_1Sec.Q, PT := T#1s);
R_TRIG_1Sec(CLK := TON_1Sec.Q);
Sec_P := R_TRIG_1Sec.Q;

(* 1-Minute Pulse Generator *)
IF TON_1Sec.Q THEN
    Min_Counter := Min_Counter + 1;
END_IF;

IF Min_Counter >= 60 THEN
    Min_P := TRUE;
    Min_Counter := 0;
ELSE
    Min_P := FALSE;
END_IF;

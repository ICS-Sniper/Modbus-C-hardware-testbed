PROGRAM Warm_Restart
(*
================================================================================
Warm Restart Logic
================================================================================
Purpose: Software-triggered system reinitialization via Modbus
Industry Standard: Allen-Bradley Micro820 retains variable states across power
cycles and SCADA disconnects. This logic enables remote reset to initial state
without program redownload.

Usage: Write 1 to HMI.PLANT.Reset_System (Modbus register 963) to trigger reset
================================================================================
*)

// HMI.PLANT.Reset_System (offset 963 - Warm Restart Trigger)
MSG_Read_SCADA_963(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_963
);
IF MSG_Read_SCADA_963.Q THEN
    hmiplantresetsystem := SCADA_read_963[1].0;
    msg_write_SCADA_963_enable := TRUE;
ELSE
    msg_write_SCADA_963_enable := FALSE;
END_IF;

IF hmiplantresetsystem THEN
    (* Reset state machine variables *)
    hmip2state := 1;
    hmip2state_prev := 0;
    hmip2shutdown := TRUE;
    hmip2ready := FALSE;
    hmip2permissiveon := TRUE;
    
    (* Reset SCADA control inputs *)
    hmiplantreseton := TRUE;
    hmiplantautoon := TRUE;
    hmiplantautooff := FALSE;
    hmiplantstop := FALSE;
    hmiplantstart := FALSE;
    hmiplantcriticalsdon := FALSE;
    hmimv301status := 1;
    hmiait402ah := FALSE;
    hmiait503ah := FALSE;
    hmilit301ah := FALSE;
    hmilit301al := FALSE;
    
    (* Reset MV201 valve *)
    hmimv201auto := TRUE;
    hmimv201reset := TRUE;
    hmimv201fto := FALSE;
    hmimv201ftc := FALSE;
    hmimv201open := TRUE;
    hmimv201close := FALSE;
    hmimv201status := 1;
    hmimv201avl := TRUE;
    
    (* Reset all pumps - P201 through P208 *)
    hmip201auto := TRUE;
    hmip201reset := FALSE;
    hmip201status := 1;
    hmip201fault := FALSE;
    hmip201avl := TRUE;
    hmip201permissive := -1;
    hmip201msgpermissive := 0;
    hmip201sd := 0;
    hmip201shutdown := 0;
    hmip201msgshutdown := 0;
    
    hmip202auto := TRUE;
    hmip202reset := FALSE;
    hmip202status := 1;
    hmip202fault := FALSE;
    hmip202avl := TRUE;
    hmip202permissive := -1;
    hmip202msgpermissive := 0;
    hmip202sd := 0;
    hmip202shutdown := 0;
    hmip202msgshutdown := 0;
    
    hmip203auto := TRUE;
    hmip203reset := FALSE;
    hmip203status := 1;
    hmip203fault := FALSE;
    hmip203avl := TRUE;
    hmip203permissive := -1;
    hmip203msgpermissive := 0;
    hmip203sd := 0;
    hmip203shutdown := 0;
    hmip203msgshutdown := 0;
    
    hmip204auto := TRUE;
    hmip204reset := FALSE;
    hmip204status := 1;
    hmip204fault := FALSE;
    hmip204avl := TRUE;
    hmip204permissive := -1;
    hmip204msgpermissive := 0;
    hmip204sd := 0;
    hmip204shutdown := 0;
    hmip204msgshutdown := 0;
    
    hmip205auto := TRUE;
    hmip205reset := FALSE;
    hmip205status := 1;
    hmip205fault := FALSE;
    hmip205avl := TRUE;
    hmip205permissive := -1;
    hmip205msgpermissive := 0;
    hmip205sd := 0;
    hmip205shutdown := 0;
    hmip205msgshutdown := 0;
    
    hmip206auto := TRUE;
    hmip206reset := FALSE;
    hmip206status := 1;
    hmip206fault := FALSE;
    hmip206avl := TRUE;
    hmip206permissive := -1;
    hmip206msgpermissive := 0;
    hmip206sd := 0;
    hmip206shutdown := 0;
    hmip206msgshutdown := 0;
    
    hmip207auto := TRUE;
    hmip207reset := TRUE;
    hmip207status := 1;
    hmip207fault := FALSE;
    hmip207avl := TRUE;
    hmip207permissive := -1;
    hmip207msgpermissive := 0;
    hmip207sd := 0;
    hmip207shutdown := 0;
    hmip207msgshutdown := 0;
    
    hmip208auto := TRUE;
    hmip208reset := TRUE;
    hmip208status := 1;
    hmip208fault := FALSE;
    hmip208avl := TRUE;
    hmip208permissive := -1;
    hmip208msgpermissive := 0;
    hmip208sd := 0;
    hmip208shutdown := 0;
    hmip208msgshutdown := 0;
    
    (* Reset alarm flags *)
    hmifit201hty := FALSE;
    hmifit201ahh := FALSE;
    hmifit201ah := FALSE;
    hmifit201al := FALSE;
    hmifit201all := FALSE;
    
    hmiait201hty := FALSE;
    hmiait201ahh := FALSE;
    hmiait201ah := FALSE;
    hmiait201al := FALSE;
    hmiait201all := FALSE;
    
    hmiait202hty := FALSE;
    hmiait202ahh := FALSE;
    hmiait202ah := FALSE;
    hmiait202al := FALSE;
    hmiait202all := FALSE;
    
    hmiait203hty := FALSE;
    hmiait203ahh := FALSE;
    hmiait203ah := FALSE;
    hmiait203al := FALSE;
    hmiait203all := FALSE;
    
    (* Reset switch alarms *)
    hmils201alarm := FALSE;
    hmils201delay := 0;
    hmils202alarm := FALSE;
    hmils202delay := 0;
    hmilsl203alarm := FALSE;
    hmilsl203delay := 0;
    hmilsll203alarm := FALSE;
    hmilsll203delay := 0;
    
    (* Reset pump duty selector alarms *)
    hminaclbothpmpnotavl := FALSE;
    hminaclselectedpmpnotavl := FALSE;
    hminaclpumprunning := FALSE;
    
    hmihclbothpmpnotavl := FALSE;
    hmihclselectedpmpnotavl := FALSE;
    hmihclpumprunning := FALSE;
    
    hminaoclbothpmpnotavl := FALSE;
    hminaoclselectedpmpnotavl := FALSE;
    hminaoclpumprunning := FALSE;
    
    (* Reset duty selections *)
    hmipnacldutyselection := 1;
    hmiphcldutyselection := 1;
    hmipnaoclfacdutyselection := 1;
    
    (* Reset intermediate control signals *)
    Mid_MV201_AutoInp := FALSE;
    Mid_P_NACL_DUTY_AutoInp := FALSE;
    Mid_P_HCL_DUTY_AutoInp := FALSE;
    Mid_P_NAOCL_FAC_DUTY_AutoInp := FALSE;
    Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;
    Mid_FIT201_Tot_Enb := FALSE;
    
    (* Reset plant I/O to safe states *)
    IO_MV201_DI_ZSO := FALSE;
    IO_MV201_DI_ZSC := TRUE;
    IO_P201_DI_Run := FALSE;
    IO_P202_DI_Run := FALSE;
    IO_P203_DI_Run := FALSE;
    IO_P204_DI_Run := FALSE;
    IO_P205_DI_Run := FALSE;
    IO_P206_DI_Run := FALSE;
    IO_P207_DI_Run := FALSE;
    IO_P208_DI_Run := FALSE;
    IO_LS201_DI_LS := FALSE;
    IO_LS202_DI_LS := FALSE;
    IO_LSL203_DI_LS := FALSE;
    IO_LSLL203_DI_LS := FALSE;
    
    IO_MV201_DO_Open := FALSE;
    IO_MV201_DO_Close := FALSE;
    IO_P201_DO_Start := FALSE;
    IO_P202_DO_Start := FALSE;
    IO_P203_DO_Start := FALSE;
    IO_P204_DO_Start := FALSE;
    IO_P205_DO_Start := FALSE;
    IO_P206_DO_Start := FALSE;
    IO_P207_DO_Start := FALSE;
    IO_P208_DO_Start := FALSE;
    
    (* Clear reset trigger *)
    hmiplantresetsystem := FALSE;
    
    (* Warm restart complete - system returned to initial state *)
END_IF;

SCADA_write_963[1].0 := hmiplantresetsystem;
MSG_Write_SCADA_963(
    IN := msg_write_SCADA_963_enable,
    LocalCfg := LocalCfgWrite_c6,
    LocalAddr := SCADA_write_963
);
END_PROGRAM

PROGRAM Modbus_SCADA_Read_Core
// Read plant.reseton, autoon, autooff, stop, criticalsdon, and mv301status
// unconditionally. Offest starts from 0 to 2, 4, 6, and 431.
// Read offset 0~6
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

// HMI.MV301.Status (offset 431)
MSG_Read_SCADA_431(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_431
);
IF MSG_Read_SCADA_431.Q THEN
	hmimv301status := ANY_TO_INT(SCADA_read_431[1]);
END_IF;

// HMI.PLANT.Reset_System (offset 962 - Warm Restart Trigger)
MSG_Read_SCADA_962(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_962
);
IF MSG_Read_SCADA_962.Q THEN
    hmiplantresetsystem := SCADA_read_962[1].0;
END_IF;
END_PROGRAM

PROGRAM Modbus_SCADA_READ_S1_ST
// Read (Cmd = 3), Targetcfg address 5 = plantstart
IF msg_read_scada_core_q THEN
	// HMI.PLANT.Start (offset 5)
    hmiplantstart := SCADA_read_core[6].0;
END_IF;
END_PROGRAM

PROGRAM Modbus_SCADA_READ_S2_ST
// HMI.AIT402.AH (offset 589)
MSG_Read_SCADA_589(
	IN := (hmip2state = 2), 
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_589
);
IF (hmip2state = 2) AND MSG_Read_SCADA_589.Q THEN
    hmiait402ah := SCADA_read_589[1].0;
END_IF;
// HMI.AIT503.AH (offset 672)
MSG_Read_SCADA_672(
	IN := (hmip2state = 2),
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_672
);
IF (hmip2state = 2) AND MSG_Read_SCADA_672.Q THEN
    hmiait503ah := SCADA_read_672[1].0;
END_IF;
// HMI.LIT301.AH (offset 352)
MSG_Read_SCADA_352(
	IN := (hmip2state = 2), 
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_352
);
IF (hmip2state = 2) AND MSG_Read_SCADA_352.Q THEN
    hmilit301ah := SCADA_read_352[1].0;
END_IF;
// HMI.LIT301.AL (offset 353)
MSG_Read_SCADA_353(
	IN := (hmip2state = 2), 
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_353
);
IF (hmip2state = 2) AND MSG_Read_SCADA_353.Q THEN
    hmilit301al := SCADA_read_353[1].0;
END_IF;
END_PROGRAM

PROGRAM Modbus_L1_Read
// PLC as a Modbus client communicates with the Modbus server running on a 
// local machine with IP 192.168.137.1
// Plant read (100-113)
MSG_READ_L1_100(
	IN := TRUE, 
	LocalCfg := LocalCfgRead_c3_L1_e14,
	LocalAddr := L1_read_100
);
IF MSG_READ_L1_100.Q THEN
	IO_MV201_DI_ZSO := L1_read_100[1].0;
	IO_MV201_DI_ZSC := L1_read_100[2].0;
	IO_P201_DI_Run := L1_read_100[3].0;
	IO_P202_DI_Run := L1_read_100[4].0;
	IO_P203_DI_Run := L1_read_100[5].0;
	IO_P204_DI_Run := L1_read_100[6].0;
	IO_P205_DI_Run := L1_read_100[7].0;
	IO_P206_DI_Run := L1_read_100[8].0;
	IO_P207_DI_Run := L1_read_100[9].0;
	IO_P208_DI_Run := L1_read_100[10].0;
	IO_LS201_DI_LS := L1_read_100[11].0;
	IO_LS202_DI_LS := L1_read_100[12].0;
	IO_LSL203_DI_LS := L1_read_100[13].0;
	IO_LSLL203_DI_LS := L1_read_100[14].0;
END_IF;
END_PROGRAM

PROGRAM Plant_Control
IF hmiplantreseton THEN
    hmimv201reset := TRUE;
    hmip201reset := TRUE;
    hmip202reset := TRUE;
    hmip203reset := TRUE;
    hmip204reset := TRUE;
    hmip205reset := TRUE;
    hmip206reset := TRUE;
    hmip207reset := TRUE;
    hmip208reset := TRUE;
END_IF;

IF hmiplantautoon THEN
    hmimv201auto := TRUE;
    hmip201auto := TRUE;
    hmip202auto := TRUE;
    hmip203auto := TRUE;
    hmip204auto := TRUE;
    hmip205auto := TRUE;
    hmip206auto := TRUE;
    hmip207auto := TRUE;
    hmip208auto := TRUE;
END_IF;

IF hmiplantautooff THEN
    hmimv201auto := FALSE;
    hmip201auto := FALSE;
    hmip202auto := FALSE;
    hmip203auto := FALSE;
    hmip204auto := FALSE;
    hmip205auto := FALSE;
    hmip206auto := FALSE;
    hmip207auto := FALSE;
    hmip208auto := FALSE;
END_IF;
END_PROGRAM

PROGRAM Permissive_Shutdown
(*
================================================================================
Stage 3: Permissive calculations
================================================================================
*)
hmip2permissiveon := 
	hmimv201avl AND (hmip201avl OR hmip202avl) AND
    (hmip203avl OR hmip204avl) AND (hmip205avl OR hmip206avl);

Mid_FIT201_Tot_Enb := (hmimv201status = 2);

TON_FIT102_P1_TM(
	IN := (hmifit201all AND (hmimv201status = 2) AND (hmip201status = 2)),
	PT := T#1s
);
TON_FIT102_P2_TM(
	IN := (hmifit201all AND (hmimv201status = 2) AND (hmip202status = 2)),
	PT := T#1s
);
TON_FIT102_P3_TM(
	IN := (hmifit201all AND (hmimv201status = 2) AND (hmip203status = 2)),
	PT := T#1s
);
TON_FIT102_P4_TM(
	IN := (hmifit201all AND (hmimv201status = 2) AND (hmip204status = 2)),
	PT := T#1s
);
TON_FIT102_P5_TM(
	IN := (hmifit201all AND (hmimv201status = 2) AND (hmip205status = 2)),
	PT := T#1s
);
TON_FIT102_P6_TM(
	IN := (hmifit201all AND (hmimv201status = 2) AND (hmip206status = 2)),
	PT := T#1s
);

(* P201 Permissive *)
TempWord := ANY_TO_WORD(hmip201permissive);
TempWord.0 := NOT hmils201alarm;
TempWord.1 := (hmimv201status = 2);
TempWord.2 := hmifit201ah;
hmip201permissive := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip201msgpermissive);
TempWord.1 := hmip202permissive.0;
TempWord.2 := hmip202permissive.1;
TempWord.3 := hmip202permissive.2;
hmip201msgpermissive := ANY_TO_INT(TempWord);

(* P202 Permissive *)
TempWord := ANY_TO_WORD(hmip202permissive);
TempWord.0 := NOT hmils201alarm;
TempWord.1 := (hmimv201status = 2);
TempWord.2 := hmifit201ah;
hmip202permissive := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip202msgpermissive);
TempWord.1 := hmip202permissive.0;
TempWord.2 := hmip202permissive.1;
TempWord.3 := hmip202permissive.2;
hmip202msgpermissive := ANY_TO_INT(TempWord);

(* P203 Permissive *)
TempWord := ANY_TO_WORD(hmip203permissive);
TempWord.0 := NOT hmils202alarm;
TempWord.1 := (hmimv201status = 2);
TempWord.2 := hmifit201ah;
hmip203permissive := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip203msgpermissive);
TempWord.1 := hmip203permissive.0;
TempWord.2 := hmip203permissive.1;
TempWord.3 := hmip203permissive.2;
hmip203msgpermissive := ANY_TO_INT(TempWord);

(* P204 Permissive *)
TempWord := ANY_TO_WORD(hmip204permissive);
TempWord.0 := NOT hmils202alarm;
TempWord.1 := (hmimv201status = 2);
TempWord.2 := hmifit201ah;
hmip204permissive := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip204msgpermissive);
TempWord.1 := hmip204permissive.0;
TempWord.2 := hmip204permissive.1;
TempWord.3 := hmip204permissive.2;
hmip204msgpermissive := ANY_TO_INT(TempWord);

(* P205 Permissive *)
TempWord := ANY_TO_WORD(hmip205permissive);
TempWord.0 := NOT hmilsl203alarm;
TempWord.1 := (hmimv201status = 2);
TempWord.2 := hmifit201ah;
hmip205permissive := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip205msgpermissive);
TempWord.1 := hmip205permissive.0;
TempWord.2 := hmip205permissive.1;
TempWord.3 := hmip205permissive.2;
hmip205msgpermissive := ANY_TO_INT(TempWord);

(* P206 Permissive *)
TempWord := ANY_TO_WORD(hmip206permissive);
TempWord.0 := NOT hmilsl203alarm;
TempWord.1 := (hmimv201status = 2);
TempWord.2 := hmifit201ah;
hmip206permissive := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip206msgpermissive);
TempWord.1 := hmip206permissive.0;
TempWord.2 := hmip206permissive.1;
TempWord.3 := hmip206permissive.2;
hmip206msgpermissive := ANY_TO_INT(TempWord);

(* P207 Permissive *)
TempWord := ANY_TO_WORD(hmip207permissive);
TempWord.0 := NOT hmilsl203alarm;
TempWord.1 := (hmimv301status = 2);
hmip207permissive := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip207msgpermissive);
TempWord.1 := hmip207permissive.0;
TempWord.2 := hmip207permissive.1;
TempWord.3 := hmip207permissive.2;
hmip207msgpermissive := ANY_TO_INT(TempWord);

(* P208 Permissive *)
TempWord := ANY_TO_WORD(hmip208permissive);
TempWord.0 := NOT hmilsl203alarm;
TempWord.1 := (hmimv301status = 2);
hmip208permissive := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip208msgpermissive);
TempWord.1 := hmip208permissive.0;
TempWord.2 := hmip208permissive.1;
TempWord.3 := hmip208permissive.2;
hmip208msgpermissive := ANY_TO_INT(TempWord);

(*
================================================================================
Stage 4: Shutdown calculations
================================================================================
*)
TempWord := ANY_TO_WORD(hmip201sd);
TempWord.0 := hmils201alarm;
TempWord.1 := (hmip201status = 2) AND (hmimv201status <> 2);
TempWord.2 := TON_FIT102_P1_TM.Q;
hmip201sd := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip201msgshutdown);
TempWord.1 := hmip201shutdown.0;
TempWord.2 := hmip201shutdown.1;
TempWord.3 := hmip201shutdown.2;
hmip201msgshutdown := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip202sd);
TempWord.0 := hmils201alarm;
TempWord.1 := (hmip201status = 2) AND (hmimv201status <> 2);
TempWord.2 := TON_FIT102_P2_TM.Q;
hmip202sd := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip202msgshutdown);
TempWord.1 := hmip202shutdown.0;
TempWord.2 := hmip202shutdown.1;
TempWord.3 := hmip202shutdown.2;
hmip202msgshutdown := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip203sd);
TempWord.0 := hmils202alarm;
TempWord.1 := (hmip201status = 2) AND (hmimv201status <> 2);
TempWord.2 := TON_FIT102_P3_TM.Q;
hmip203sd := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip203msgshutdown);
TempWord.1 := hmip203shutdown.0;
TempWord.2 := hmip203shutdown.1;
TempWord.3 := hmip203shutdown.2;
hmip203msgshutdown := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip204sd);
TempWord.0 := hmils202alarm;
TempWord.1 := (hmip201status = 2) AND (hmimv201status <> 2);
TempWord.2 := TON_FIT102_P4_TM.Q;
hmip204sd := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip204msgshutdown);
TempWord.1 := hmip204shutdown.0;
TempWord.2 := hmip204shutdown.1;
TempWord.3 := hmip204shutdown.2;
hmip204msgshutdown := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip205sd);
TempWord.0 := hmilsl203alarm;
TempWord.1 := (hmip201status = 2) AND (hmimv201status <> 2);
TempWord.2 := TON_FIT102_P5_TM.Q;
hmip205sd := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip205msgshutdown);
TempWord.1 := hmip205shutdown.0;
TempWord.2 := hmip205shutdown.1;
TempWord.3 := hmip205shutdown.2;
hmip205msgshutdown := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip206sd);
TempWord.0 := hmilsl203alarm;
TempWord.1 := (hmip201status = 2) AND (hmimv201status <> 2);
TempWord.2 := TON_FIT102_P6_TM.Q;
hmip206sd := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip206msgshutdown);
TempWord.1 := hmip206shutdown.0;
TempWord.2 := hmip206shutdown.1;
TempWord.3 := hmip206shutdown.2;
hmip206msgshutdown := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip207sd);
TempWord.0 := hmilsl203alarm;
TempWord.1 := (hmip207status = 2) AND (hmimv301status <> 2);
hmip207sd := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip207msgshutdown);
TempWord.1 := hmip207shutdown.0;
TempWord.2 := hmip207shutdown.1;
hmip207msgshutdown := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip208sd);
TempWord.0 := hmilsl203alarm;
TempWord.1 := (hmip207status = 2) AND (hmimv301status <> 2);
hmip208sd := ANY_TO_INT(TempWord);

TempWord := ANY_TO_WORD(hmip208msgshutdown);
TempWord.1 := hmip208shutdown.0;
TempWord.2 := hmip208shutdown.1;
hmip208msgshutdown := ANY_TO_INT(TempWord);

IF hmiplantstop OR hmiplantcriticalsdon THEN
    hmip2shutdown := TRUE;
END_IF;

END_PROGRAM

PROGRAM State_Machine
(*
================================================================================
Stage 5: State machine
================================================================================
*)

IF hmip2state = 1 THEN
    hmip2state_prev := 1;
    Mid_MV201_AutoInp := FALSE;
    Mid_P_NACL_DUTY_AutoInp := FALSE;
    Mid_P_HCL_DUTY_AutoInp := FALSE;
    Mid_P_NAOCL_FAC_DUTY_AutoInp := FALSE;
    Mid_P_NAOCL_UF_DUTY_AutoInp := FALSE;

    IF hmip2permissiveon AND hmiplantstart THEN
        hmip2state := 2;
    END_IF;

ELSIF hmip2state = 2 THEN
    hmip2state_prev := 2;

    IF hmilit301ah THEN
        Mid_MV201_AutoInp := FALSE;
    ELSIF hmilit301al THEN
        Mid_MV201_AutoInp := TRUE;
    END_IF;

    IF (hmimv201status <> 2) OR hmiait201ah OR hmiait503ah OR hmils201alarm OR hmifit201all THEN
        Mid_P_NACL_DUTY_AutoInp := FALSE;
    ELSIF (hmimv201status = 2) AND hmiait201al AND (NOT hmiait503ah) THEN
        Mid_P_NACL_DUTY_AutoInp := TRUE;
    END_IF;

    IF (hmimv201status <> 2) OR hmiait202al OR hmils202alarm OR hmifit201all THEN
        Mid_P_HCL_DUTY_AutoInp := FALSE;
    ELSIF (hmimv201status = 2) AND hmiait202ah THEN
        Mid_P_HCL_DUTY_AutoInp := TRUE;
    END_IF;

    IF (hmimv201status <> 2) OR hmiait203ah OR hmiait402ah OR hmilsl203alarm THEN
        Mid_P_NAOCL_FAC_DUTY_AutoInp := FALSE;
    ELSIF (hmimv201status = 2) AND hmiait203al AND (NOT hmiait402ah) THEN
        Mid_P_NAOCL_FAC_DUTY_AutoInp := TRUE;
    END_IF;

    hmip2ready := TRUE;

    IF hmip2shutdown THEN
        IF hmilit301ah THEN
            hmip2shutdown := FALSE;
            hmip2state := 1;
        END_IF;
    END_IF;

ELSE
    hmip2state := 1;
END_IF;
END_PROGRAM

PROGRAM Function_Blocks
(*
================================================================================
Stage 6: Function block execution
================================================================================
*)

MV201_FB(
    AutoInp := Mid_MV201_AutoInp,
    Auto := hmimv201auto,
    Reset := hmimv201reset,
    DI_ZSO := IO_MV201_DI_ZSO,
    DI_ZSC := IO_MV201_DI_ZSC,
    FTO_Init := hmimv201fto,
    FTC_Init := hmimv201ftc,
    Cmd_Open_Init := hmimv201open,
    Cmd_Close_Init := hmimv201close
);
IF MV201_FB.Status <> -99 THEN
    hmimv201status := MV201_FB.Status;
END_IF;
hmimv201avl := MV201_FB.Avl;
IO_MV201_DO_Open := MV201_FB.DO_Open;
IO_MV201_DO_Close := MV201_FB.DO_Close;

LS201_FB(
	DI_LS := IO_LS201_DI_LS,
	DelayMs := hmils201delay
);
hmils201alarm := LS201_FB.Status;

LS202_FB(
	DI_LS := IO_LS202_DI_LS,
	DelayMs := hmils202delay
);
hmils202alarm := LS202_FB.Status;

LSL203_FB(
	DI_LS := IO_LSL203_DI_LS,
	DelayMs := hmilsl203delay
);
hmilsl203alarm := LSL203_FB.Status;

LSLL203_FB(
	DI_LS := IO_LSLL203_DI_LS,
	DelayMs := hmilsll203delay
);
hmilsll203alarm := LSLL203_FB.Status;

P_NACL_DUTY_FB(
    AutoInp := Mid_P_NACL_DUTY_AutoInp,
    Pmp1_Status := hmip201status,
    Pmp1_Avl := hmip201avl,
    Pmp2_Status := hmip202status,
    Pmp2_Avl := hmip202avl,
    Selection := hmipnacldutyselection
);
hminaclbothpmpnotavl := P_NACL_DUTY_FB.Both_Pmp_Not_Avl;
hminaclselectedpmpnotavl := P_NACL_DUTY_FB.Selected_Pmp_Not_Avl;
hminaclpumprunning := P_NACL_DUTY_FB.Pump_Running;

P_HCL_DUTY_FB(
    AutoInp := Mid_P_HCL_DUTY_AutoInp,
    Pmp1_Status := hmip203status,
    Pmp1_Avl := hmip203avl,
    Pmp2_Status := hmip204status,
    Pmp2_Avl := hmip204avl,
    Selection := hmiphcldutyselection
);
hmihclbothpmpnotavl := P_HCL_DUTY_FB.Both_Pmp_Not_Avl;
hmihclselectedpmpnotavl := P_HCL_DUTY_FB.Selected_Pmp_Not_Avl;
hmihclpumprunning := P_HCL_DUTY_FB.Pump_Running;

P_NAOCL_FAC_DUTY_FB(
    AutoInp := Mid_P_NAOCL_FAC_DUTY_AutoInp,
    Pmp1_Status := hmip205status,
    Pmp1_Avl := hmip205avl,
    Pmp2_Status := hmip206status,
    Pmp2_Avl := hmip206avl,
    Selection := hmipnaoclfacdutyselection
);
hminaoclbothpmpnotavl := P_NAOCL_FAC_DUTY_FB.Both_Pmp_Not_Avl;
hminaoclselectedpmpnotavl := P_NAOCL_FAC_DUTY_FB.Selected_Pmp_Not_Avl;
hminaoclpumprunning := P_NAOCL_FAC_DUTY_FB.Pump_Running;

P201_FB(
    Start := P_NACL_DUTY_FB.Start_Pmp1,
    Auto := hmip201auto,
    Reset := hmip201reset,
    Permissive := hmip201permissive,
    SD := hmip201sd,
    DI_Run := IO_P201_DI_Run,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P201_FB.Status <> -99 THEN
    hmip201status := P201_FB.Status;
END_IF;
hmip201fault := P201_FB.Fault;
hmip201avl := P201_FB.Avl;
hmip201shutdown := P201_FB.Shutdown;
IO_P201_DO_Start := P201_FB.DO_Start;

P202_FB(
    Start := P_NACL_DUTY_FB.Start_Pmp2,
    Auto := hmip202auto,
    Reset := hmip202reset,
    Permissive := hmip202permissive,
    SD := hmip202sd,
    DI_Run := IO_P202_DI_Run,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P202_FB.Status <> -99 THEN
    hmip202status := P202_FB.Status;
END_IF;
hmip202fault := P202_FB.Fault;
hmip202avl := P202_FB.Avl;
hmip202shutdown := P202_FB.Shutdown;
IO_P202_DO_Start := P202_FB.DO_Start;

P203_FB(
    Start := P_HCL_DUTY_FB.Start_Pmp1,
    Auto := hmip203auto,
    Reset := hmip203reset,
    Permissive := hmip203permissive,
    SD := hmip203sd,
    DI_Run := IO_P203_DI_Run,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P203_FB.Status <> -99 THEN
    hmip203status := P203_FB.Status;
END_IF;
hmip203fault := P203_FB.Fault;
hmip203avl := P203_FB.Avl;
hmip203shutdown := P203_FB.Shutdown;
IO_P203_DO_Start := P203_FB.DO_Start;

P204_FB(
    Start := P_HCL_DUTY_FB.Start_Pmp2,
    Auto := hmip204auto,
    Reset := hmip204reset,
    Permissive := hmip204permissive,
    SD := hmip204sd,
    DI_Run := IO_P204_DI_Run,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P204_FB.Status <> -99 THEN
    hmip204status := P204_FB.Status;
END_IF;
hmip204fault := P204_FB.Fault;
hmip204avl := P204_FB.Avl;
hmip204shutdown := P204_FB.Shutdown;
IO_P204_DO_Start := P204_FB.DO_Start;

P205_FB(
    Start := P_NAOCL_FAC_DUTY_FB.Start_Pmp1,
    Auto := hmip205auto,
    Reset := hmip205reset,
    Permissive := hmip205permissive,
    SD := hmip205sd,
    DI_Run := IO_P205_DI_Run,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P205_FB.Status <> -99 THEN
    hmip205status := P205_FB.Status;
END_IF;
hmip205fault := P205_FB.Fault;
hmip205avl := P205_FB.Avl;
hmip205shutdown := P205_FB.Shutdown;
IO_P205_DO_Start := P205_FB.DO_Start;

P206_FB(
    Start := P_NAOCL_FAC_DUTY_FB.Start_Pmp2,
    Auto := hmip206auto,
    Reset := hmip206reset,
    Permissive := hmip206permissive,
    SD := hmip206sd,
    DI_Run := IO_P206_DI_Run,
    DI_Auto := TRUE,
    DI_Fault := FALSE
);
IF P206_FB.Status <> -99 THEN
    hmip206status := P206_FB.Status;
END_IF;
hmip206fault := P206_FB.Fault;
hmip206avl := P206_FB.Avl;
hmip206shutdown := P206_FB.Shutdown;
IO_P206_DO_Start := P206_FB.DO_Start;
END_PROGRAM

PROGRAM Modbus_L1_Write
(*
================================================================================
Stage 7: Write outputs to Plant
================================================================================
*)

L1_write_200[1].0 := IO_MV201_DO_Open;
L1_write_200[2].0 := IO_MV201_DO_Close;
L1_write_200[3].0 := IO_P201_DO_Start;
L1_write_200[4].0 := IO_P202_DO_Start;
L1_write_200[5].0 := IO_P203_DO_Start;
L1_write_200[6].0 := IO_P204_DO_Start;
L1_write_200[7].0 := IO_P205_DO_Start;
L1_write_200[8].0 := IO_P206_DO_Start;
L1_write_200[9].0 := IO_P207_DO_Start;
L1_write_200[10].0 := IO_P208_DO_Start;
MSG_WRITE_L1_200(
	IN := TRUE, 
	LocalCfg := LocalCfgWrite_c16_L1_e10,
	LocalAddr := L1_write_200
);
END_PROGRAM

PROGRAM Modbus_SCADA_Write
(*
================================================================================
Stage 8: Write data to SCADA
================================================================================
*)

// HMI.P2.Permissive_On (offset 13)
SCADA_write[0][1].0 := hmip2permissiveon;
MSG_Write_SCADA_13(
    IN := TRUE,
    LocalAddr := SCADA_write[0],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P2.Shutdown (offset 14)
// Set Shutdown flag when plant stop or critical shutdown occurs
IF hmiplantstop OR hmiplantcriticalsdon THEN
    SCADA_write[1][1].0 := TRUE;
    MSG_Write_SCADA_14(
        IN := TRUE,
        LocalAddr := SCADA_write[1],
        LocalCfg := LocalCfgWrite_c6
    );
END_IF;

// HMI.P2.State (offset 15) - Independent MSG for each state transition
IF hmip2state_prev > 2 THEN
    SCADA_write[2][1] := ANY_TO_WORD(1);
ELSE
    SCADA_write[2][1] := ANY_TO_WORD(hmip2state);
END_IF;

MSG_P2State_1to2(
    IN := (hmip2state_prev = 1 AND hmip2state = 2),
    LocalAddr := SCADA_write[2],
    LocalCfg := LocalCfgWrite_c6
);

MSG_P2State_2to1(
    IN := (hmip2state_prev = 2 AND hmip2state = 1),
    LocalAddr := SCADA_write[2],
    LocalCfg := LocalCfgWrite_c6
);

MSG_P2State_InvalidTo1(
    IN := (hmip2state_prev > 2),
    LocalAddr := SCADA_write[2],
    LocalCfg := LocalCfgWrite_c6
);

// Clear Shutdown flag when transitioning from state 2 back to state 1
SCADA_write[1][1].0 := FALSE;
MSG_P2Shutdown_Clear_2to1(
    IN := (hmip2state_prev = 2 AND hmip2state = 1),
    LocalAddr := SCADA_write[1],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P2.Ready (offset 16)
SCADA_write[3][1].0 := hmip2ready;
MSG_Write_SCADA_16(
    IN := (hmip2state_prev = 2),
    LocalAddr := SCADA_write[3],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.MV201.Auto (offset 115)
SCADA_write[4][1].0 := hmimv201auto;
MSG_Write_SCADA_115(
    IN := TRUE,
    LocalAddr := SCADA_write[4],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.MV201.Reset (offset 116)
SCADA_write[5][1].0 := hmimv201reset;
MSG_Write_SCADA_116(
    IN := TRUE,
    LocalAddr := SCADA_write[5],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.MV201.Status (offset 119)
SCADA_write[6][1] := ANY_TO_WORD(hmimv201status);
MSG_Write_SCADA_119(
    IN := TRUE,
    LocalAddr := SCADA_write[6],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.MV201.Avl (offset 120)
SCADA_write[7][1].0 := hmimv201avl;
MSG_Write_SCADA_120(
    IN := TRUE,
    LocalAddr := SCADA_write[7],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.LS201.Alarm (offset 124)
SCADA_write[8][1].0 := hmils201alarm;
// HMI.LS202.Alarm (offset 125)
SCADA_write[9][1].0 := hmils202alarm;
// HMI.LSL203.Alarm (offset 126)
SCADA_write[10][1].0 := hmilsl203alarm;
// HMI.LSLL203.Alarm (offset 127)
SCADA_write[11][1].0 := hmilsll203alarm;
// HMI.P201.Auto (offset 128)
SCADA_write[12][1].0 := hmip201auto;
// HMI.P201.Permissive (offset 129)
SCADA_write[13][1] := ANY_TO_WORD(hmip201permissive);
// HMI.P201.MSG_Permissive (offset 130)
SCADA_write[14][1] := ANY_TO_WORD(hmip201msgpermissive);
// HMI.P201.SD (offset 131)
SCADA_write[15][1] := ANY_TO_WORD(hmip201sd);
// HMI.P201.MSG_Shutdown (offset 132)
SCADA_write[16][1] := ANY_TO_WORD(hmip201msgshutdown);
// HMI.P201.Reset (offset 133)
SCADA_write[17][1].0 := hmip201reset;
MSG_Write_SCADA_124_133(
    IN := TRUE,
    LocalAddr := SCADA_write[8],
    LocalCfg := LocalCfgWrite_c16_e10
);

// HMI.P201.Avl (offset 135)
SCADA_write[18][1].0 := hmip201avl;
MSG_Write_SCADA_135(
    IN := TRUE,
    LocalAddr := SCADA_write[18],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P201.Fault (offset 136)
SCADA_write[19][1].0 := hmip201fault;
MSG_Write_SCADA_136(
    IN := TRUE,
    LocalAddr := SCADA_write[19],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P201.Shutdown (offset 141)
SCADA_write[20][1] := ANY_TO_WORD(hmip201shutdown);
MSG_Write_SCADA_141(
    IN := TRUE,
    LocalAddr := SCADA_write[20],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P201.Status (offset 143)
SCADA_write[21][1] := ANY_TO_WORD(hmip201status);
// HMI.P202.Auto (offset 144)
SCADA_write[22][1].0 := hmip202auto;
// HMI.P202.Permissive (offset 145)
SCADA_write[23][1] := ANY_TO_WORD(hmip202permissive);
// HMI.P202.MSG_Permissive (offset 146)
SCADA_write[24][1] := ANY_TO_WORD(hmip202msgpermissive);
// HMI.P202.SD (offset 147)
SCADA_write[25][1] := ANY_TO_WORD(hmip202sd);
// HMI.P202.MSG_Shutdown (offset 148)
SCADA_write[26][1] := ANY_TO_WORD(hmip202msgshutdown);
// HMI.P202.Reset (offset 149)
SCADA_write[27][1].0 := hmip202reset;
MSG_Write_SCADA_143_149(
    IN := TRUE,
    LocalAddr := SCADA_write[21],
    LocalCfg := LocalCfgWrite_c16_e7
);

// HMI.P202.Avl (offset 151)
SCADA_write[28][1].0 := hmip202avl;
MSG_Write_SCADA_151(
    IN := TRUE,
    LocalAddr := SCADA_write[28],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P202.Fault (offset 152)
SCADA_write[29][1].0 := hmip202fault;
MSG_Write_SCADA_152(
    IN := TRUE,
    LocalAddr := SCADA_write[29],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P202.Shutdown (offset 157)
SCADA_write[30][1] := ANY_TO_WORD(hmip202shutdown);
MSG_Write_SCADA_157(
    IN := TRUE,
    LocalAddr := SCADA_write[30],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P202.Status (offset 159)
SCADA_write[31][1] := ANY_TO_WORD(hmip202status);
// HMI.P203.Auto (offset 160)
SCADA_write[32][1].0 := hmip203auto;
// HMI.P203.Permissive (offset 161)
SCADA_write[33][1] := ANY_TO_WORD(hmip203permissive);
// HMI.P203.MSG_Permissive (offset 162)
SCADA_write[34][1] := ANY_TO_WORD(hmip203msgpermissive);
// HMI.P203.SD (offset 163)
SCADA_write[35][1] := ANY_TO_WORD(hmip203sd);
// HMI.P203.MSG_Shutdown (offset 164)
SCADA_write[36][1] := ANY_TO_WORD(hmip203msgshutdown);
// HMI.P203.Reset (offset 165)
SCADA_write[37][1].0 := hmip203reset;
MSG_Write_SCADA_159_165(
    IN := TRUE,
    LocalAddr := SCADA_write[31],
    LocalCfg := LocalCfgWrite_c16_e7
);

// HMI.P203.Avl (offset 167)
SCADA_write[38][1].0 := hmip203avl;
MSG_Write_SCADA_167(
    IN := TRUE,
    LocalAddr := SCADA_write[38],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P203.Fault (offset 168)
SCADA_write[39][1].0 := hmip203fault;
MSG_Write_SCADA_168(
    IN := TRUE,
    LocalAddr := SCADA_write[39],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P203.Shutdown (offset 173)
SCADA_write[40][1] := ANY_TO_WORD(hmip203shutdown);
MSG_Write_SCADA_173(
    IN := TRUE,
    LocalAddr := SCADA_write[40],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P203.Status (offset 175)
SCADA_write[41][1] := ANY_TO_WORD(hmip203status);
// HMI.P204.Auto (offset 176)
SCADA_write[42][1].0 := hmip204auto;
// HMI.P204.Permissive (offset 177)
SCADA_write[43][1] := ANY_TO_WORD(hmip204permissive);
// HMI.P204.MSG_Permissive (offset 178)
SCADA_write[44][1] := ANY_TO_WORD(hmip204msgpermissive);
// HMI.P204.SD (offset 179)
SCADA_write[45][1] := ANY_TO_WORD(hmip204sd);
// HMI.P204.MSG_Shutdown (offset 180)
SCADA_write[46][1] := ANY_TO_WORD(hmip204msgshutdown);
// HMI.P204.Reset (offset 181)
SCADA_write[47][1].0 := hmip204reset;
MSG_Write_SCADA_175_181(
    IN := TRUE,
    LocalAddr := SCADA_write[41],
    LocalCfg := LocalCfgWrite_c16_e7
);

// HMI.P204.Avl (offset 183)
SCADA_write[48][1].0 := hmip204avl;
MSG_Write_SCADA_183(
    IN := TRUE,
    LocalAddr := SCADA_write[48],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P204.Fault (offset 184)
SCADA_write[49][1].0 := hmip204fault;
MSG_Write_SCADA_184(
    IN := TRUE,
    LocalAddr := SCADA_write[49],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P204.Shutdown (offset 189)
SCADA_write[50][1] := ANY_TO_WORD(hmip204shutdown);
MSG_Write_SCADA_189(
    IN := TRUE,
    LocalAddr := SCADA_write[50],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P204.Status (offset 191)
SCADA_write[51][1] := ANY_TO_WORD(hmip204status);
// HMI.P205.Auto (offset 192)
SCADA_write[52][1].0 := hmip205auto;
// HMI.P205.Permissive (offset 193)
SCADA_write[53][1] := ANY_TO_WORD(hmip205permissive);
// HMI.P205.MSG_Permissive (offset 194)
SCADA_write[54][1] := ANY_TO_WORD(hmip205msgpermissive);
// HMI.P205.SD (offset 195)
SCADA_write[55][1] := ANY_TO_WORD(hmip205sd);
// HMI.P205.MSG_Shutdown (offset 196)
SCADA_write[56][1] := ANY_TO_WORD(hmip205msgshutdown);
// HMI.P205.Reset (offset 197)
SCADA_write[57][1].0 := hmip205reset;
MSG_Write_SCADA_191_197(
    IN := TRUE,
    LocalAddr := SCADA_write[51],
    LocalCfg := LocalCfgWrite_c16_e7
);

// HMI.P205.Avl (offset 199)
SCADA_write[58][1].0 := hmip205avl;
MSG_Write_SCADA_199(
    IN := TRUE,
    LocalAddr := SCADA_write[58],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P205.Fault (offset 200)
SCADA_write[59][1].0 := hmip205fault;
MSG_Write_SCADA_200(
    IN := TRUE,
    LocalAddr := SCADA_write[59],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P205.Shutdown (offset 205)
SCADA_write[60][1] := ANY_TO_WORD(hmip205shutdown);
MSG_Write_SCADA_205(
    IN := TRUE,
    LocalAddr := SCADA_write[60],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P205.Status (offset 207)
SCADA_write[61][1] := ANY_TO_WORD(hmip205status);
// HMI.P206.Auto (offset 208)
SCADA_write[62][1].0 := hmip206auto;
// HMI.P206.Permissive (offset 209)
SCADA_write[63][1] := ANY_TO_WORD(hmip206permissive);
// HMI.P206.MSG_Permissive (offset 210)
SCADA_write[64][1] := ANY_TO_WORD(hmip206msgpermissive);
// HMI.P206.SD (offset 211)
SCADA_write[65][1] := ANY_TO_WORD(hmip206sd);
// HMI.P206.MSG_Shutdown (offset 212)
SCADA_write[66][1] := ANY_TO_WORD(hmip206msgshutdown);
// HMI.P206.Reset (offset 213)
SCADA_write[67][1].0 := hmip206reset;
MSG_Write_SCADA_207_213(
    IN := TRUE,
    LocalAddr := SCADA_write[61],
    LocalCfg := LocalCfgWrite_c16_e7
);

// HMI.P206.Avl (offset 215)
SCADA_write[68][1].0 := hmip206avl;
MSG_Write_SCADA_215(
    IN := TRUE,
    LocalAddr := SCADA_write[68],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P206.Fault (offset 216)
SCADA_write[69][1].0 := hmip206fault;
MSG_Write_SCADA_216(
    IN := TRUE,
    LocalAddr := SCADA_write[69],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P206.Shutdown (offset 221)
SCADA_write[70][1] := ANY_TO_WORD(hmip206shutdown);
MSG_Write_SCADA_221(
    IN := TRUE,
    LocalAddr := SCADA_write[70],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P206.Status (offset 223)
SCADA_write[71][1] := ANY_TO_WORD(hmip206status);
// HMI.P207.Auto (offset 224)
SCADA_write[72][1].0 := hmip207auto;
// HMI.P207.Permissive (offset 225)
SCADA_write[73][1] := ANY_TO_WORD(hmip207permissive);
// HMI.P207.MSG_Permissive (offset 226)
SCADA_write[74][1] := ANY_TO_WORD(hmip207msgpermissive);
// HMI.P207.SD (offset 227)
SCADA_write[75][1] := ANY_TO_WORD(hmip207sd);
// HMI.P207.MSG_Shutdown (offset 228)
SCADA_write[76][1] := ANY_TO_WORD(hmip207msgshutdown);
// HMI.P207.Reset (offset 229)
SCADA_write[77][1].0 := hmip207reset;
MSG_Write_SCADA_223_229(
    IN := TRUE,
    LocalAddr := SCADA_write[71],
    LocalCfg := LocalCfgWrite_c16_e7
);

// HMI.P208.Auto (offset 240)
SCADA_write[78][1].0 := hmip208auto;
// HMI.P208.Permissive (offset 241)
SCADA_write[79][1] := ANY_TO_WORD(hmip208permissive);
// HMI.P208.MSG_Permissive (offset 242)
SCADA_write[80][1] := ANY_TO_WORD(hmip208msgpermissive);
// HMI.P208.SD (offset 243)
SCADA_write[81][1] := ANY_TO_WORD(hmip208sd);
// HMI.P208.MSG_Shutdown (offset 244)
SCADA_write[82][1] := ANY_TO_WORD(hmip208msgshutdown);
// HMI.P208.Reset (offset 245)
SCADA_write[83][1].0 := hmip208reset;
MSG_Write_SCADA_240_245(
    IN := TRUE,
    LocalAddr := SCADA_write[78],
    LocalCfg := LocalCfgWrite_c16_e6
);

// HMI.P_NACL_DUTY.Both_Pmp_Not_Avl (offset 257)
SCADA_write[84][1].0 := hminaclbothpmpnotavl;
// HMI.P_NACL_DUTY.Selected_Pmp_Not_Avl (offset 258)
SCADA_write[85][1].0 := hminaclselectedpmpnotavl;
// HMI.P_NACL_DUTY.Pump_Running (offset 259)
SCADA_write[86][1].0 := hminaclpumprunning;
MSG_Write_SCADA_257_259(
    IN := TRUE,
    LocalAddr := SCADA_write[84],
    LocalCfg := LocalCfgWrite_c16_e3
);

// HMI.P_HCL_DUTY.Both_Pmp_Not_Avl (offset 261)
SCADA_write[87][1].0 := hmihclbothpmpnotavl;
// HMI.P_HCL_DUTY.Selected_Pmp_Not_Avl (offset 262)
SCADA_write[88][1].0 := hmihclselectedpmpnotavl;
// HMI.P_HCL_DUTY.Pump_Running (offset 263)
SCADA_write[89][1].0 := hmihclpumprunning;
MSG_Write_SCADA_261_263(
    IN := TRUE,
    LocalAddr := SCADA_write[87],
    LocalCfg := LocalCfgWrite_c16_e3
);

// HMI.P_NAOCL_FAC_DUTY.Both_Pmp_Not_Avl (offset 265)
SCADA_write[90][1].0 := hminaoclbothpmpnotavl;
// HMI.P_NAOCL_FAC_DUTY.Selected_Pmp_Not_Avl (offset 266)
SCADA_write[91][1].0 := hminaoclselectedpmpnotavl;
// HMI.P_NAOCL_FAC_DUTY.Pump_Running (offset 267)
SCADA_write[92][1].0 := hminaoclpumprunning;
MSG_Write_SCADA_265_267(
    IN := TRUE,
    LocalAddr := SCADA_write[90],
    LocalCfg := LocalCfgWrite_c16_e3
);
END_PROGRAM
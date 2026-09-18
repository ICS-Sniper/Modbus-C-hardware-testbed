(*
================================================================================
Micro820 PLC1 Main Program (Structured Text)
================================================================================
*)

(*
================================================================================
Warm Restart - Software-triggered reinitialization (offset 962)
================================================================================
*)
<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="Warm_Restart" ElementGuid="8e83b168-551e-4087-a389-d48d3e04dd97" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <Program />
  <LocalVars>
    <Variable Name="MSG_Read_SCADA_962" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(963,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="SCADA_read_962" Comment="" Address="" Alias="" StringSize="0" DataType="MODBUSLOCADDR" InitialValue="" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="SCADA_write_962" Comment="" Address="" Alias="" StringSize="0" DataType="MODBUSLOCADDR" InitialValue="" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_962" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(963,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="msg_write_SCADA_962_enable" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
  </LocalVars>
  <PouBody><![CDATA[PROGRAM Warm_Restart
(*
================================================================================
Warm Restart Logic for PLC1 (Raw Water Stage)
================================================================================
Purpose: Software-triggered system reinitialization via Modbus
Industry Standard: Allen-Bradley Micro820 retains variable states across power
cycles and SCADA disconnects. This logic enables remote reset to initial state
without program redownload.

Usage: Write 1 to HMI.PLANT.Reset_System (Modbus register 962) to trigger reset
Based on: plc1.py pre_loop() initial values
================================================================================
*)
// HMI.PLANT.Reset_System_PLC1 (offset 962 - Warm Restart Trigger)
MSG_Read_SCADA_962(
	IN := TRUE,
	LocalCfg := LocalCfgRead_c3_e1,
	LocalAddr := SCADA_read_962
);
IF MSG_Read_SCADA_962.Q THEN
    hmiplantresetsystem := SCADA_read_962[1].0;
	msg_write_SCADA_962_enable := TRUE;
ELSE
	msg_write_SCADA_962_enable := FALSE;
END_IF;

IF hmiplantresetsystem THEN
    (* Reset SCADA control inputs *)
    hmiplantreseton := TRUE;
    hmiplantautoon := TRUE;
    hmiplantautooff := FALSE;
    hmiplantstart := FALSE;
    hmiplantstop := FALSE;

    (* Reset state machine *)
    hmip1state := 1;
    hmip1state_prev := 0;
    hmip1permissiveon := TRUE;
    hmiplantready := FALSE;
    hmip1ready := FALSE;
    hmip1shutdown := TRUE;

    (* Reset external permissive dependencies *)
    hmip2permissiveon := FALSE;
    hmip3permissiveon := FALSE;
    hmip4permissiveon := FALSE;
    hmimv201status := 1;
    hmilit301al := FALSE;
    hmilit301ah := FALSE;

    (* Reset LIT101 *)
    hmilit101hty := TRUE;
    hmilit101ahh := FALSE;
    hmilit101ah := FALSE;
    hmilit101al := FALSE;
    hmilit101all := FALSE;
    hmilit101pv := 505.0;

    (* Reset MV101 *)
    hmimv101avl := TRUE;
    hmimv101auto := TRUE;
    hmimv101reset := TRUE;
    hmimv101status := 1;

    (* Reset P101 *)
    hmip101avl := TRUE;
    hmip101auto := TRUE;
    hmip101reset := FALSE;
    hmip101fault := FALSE;
    hmip101permissive := -1;
    hmip101msgpermissive := 0;
    hmip101sd := 0;
    hmip101shutdown := 0;
    hmip101msgshutdown := 0;
    hmip101status := 1;

    (* Reset P102 *)
    hmip102avl := TRUE;
    hmip102auto := TRUE;
    hmip102reset := FALSE;
    hmip102fault := FALSE;
    hmip102permissive := -1;
    hmip102msgpermissive := 0;
    hmip102sd := 0;
    hmip102shutdown := 0;
    hmip102msgshutdown := 0;
    hmip102status := 1;

    (* Reset pump duty selection *)
    hmiprawwaterdutyselection := 1;
    hmibothpmpnotavl := FALSE;
    hmiselectedpmpnotavl := FALSE;
    hmipumprunning := FALSE;

    (* Reset intermediate signals *)
    Mid_MV101_AutoInp := FALSE;
    Mid_P_RAW_WATER_DUTY_AutoInp := TRUE;

    hmiplantresetsystem := FALSE;
END_IF;
	
SCADA_write_962[1].0 := hmiplantresetsystem;
MSG_Write_SCADA_962(
	IN := msg_write_SCADA_962_enable,
	LocalCfg := LocalCfgWrite_c6,
	LocalAddr := SCADA_write_962
);
END_PROGRAM]]></PouBody>
</Pou>

(*
================================================================================
Phase 1: Read data from SCADA and Plant
================================================================================
*)

(* MSG scheduler - read phase (all reads executed every scan) *)
(* Note: In actual Micro820, MSG is asynchronous; simplified here to execute immediately after trigger *)

(* 1.1 Read SCADA core data (40001-40004) *)
MSG_Trigger_ReadSCADA_Core := TRUE;
IF MSG_Trigger_ReadSCADA_Core THEN
    (* Trigger MSG_READ_SCADA_CORE *)
    (* Assumes SCADA_Read_Core is populated after MSG completes *)
    (* In actual implementation, configure MSG instruction Source/Destination *)
    
    (* Parse core data *)
    hmiplantreseton := (SCADA_Read_Core[0] <> 0);
    hmiplantautoon := (SCADA_Read_Core[1] <> 0);
    hmiplantautooff := (SCADA_Read_Core[2] <> 0);
    hmiplantstop := (SCADA_Read_Core[3] <> 0);
    
    MSG_Trigger_ReadSCADA_Core := FALSE;
END_IF;


(* 1.2 Read SCADA state-specific data *)
// when hmip1state = 1
<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="Modbus_SCADA_READ_S1_single_ST" ElementGuid="417c1c3b-774f-4135-bbea-62a2da44ea05" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <Program />
  <LocalVars>
    <Variable Name="MSG_Read_SCADA_5" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),(4,10000,3,1),(6,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="SCADA_read_5" Comment="" Address="" Alias="" StringSize="0" DataType="MODBUSLOCADDR" InitialValue="" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Read_SCADA_13" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),(4,10000,3,1),(14,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="SCADA_read_13" Comment="" Address="" Alias="" StringSize="0" DataType="MODBUSLOCADDR" InitialValue="" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Read_SCADA_18" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),(4,10000,3,1),(19,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Read_SCADA_23" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),(4,10000,3,1),(24,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="SCADA_read_18" Comment="" Address="" Alias="" StringSize="0" DataType="MODBUSLOCADDR" InitialValue="" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="SCADA_read_23" Comment="" Address="" Alias="" StringSize="0" DataType="MODBUSLOCADDR" InitialValue="" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
  </LocalVars>
  <PouBody><![CDATA[PROGRAM Modbus_SCADA_READ_S1_single_ST
// Read (Cmd = 3), Targetcfg address 5 = plantstart, 13 = p2permissiveon, 
// 18 = p3permissiveon, and 23 = p4permissiveon
// plantstart
MSG_Read_SCADA_5(
    IN := (hmip1state = 1),
    LocalAddr := SCADA_read_5
);
IF (hmip1state = 1) AND MSG_Read_SCADA_5.Q THEN
    hmiplantstart := SCADA_read_5[1].0;
END_IF;
// p2permissiveon
MSG_Read_SCADA_13(
    IN := (hmip1state = 1),
    LocalAddr := SCADA_read_13
);
IF (hmip1state = 1) AND MSG_Read_SCADA_13.Q THEN
    hmip2permissiveon := SCADA_read_13[1].0;
END_IF;
// p3permissiveon
MSG_Read_SCADA_18(
    IN := (hmip1state = 1),
    LocalAddr := SCADA_read_18
);
IF (hmip1state = 1) AND MSG_Read_SCADA_18.Q THEN
    hmip3permissiveon := SCADA_read_18[1].0;
END_IF;
// p2permissiveon
MSG_Read_SCADA_23(
    IN := (hmip1state = 1),
    LocalAddr := SCADA_read_23
);
IF (hmip1state = 1) AND MSG_Read_SCADA_23.Q THEN
    hmip4permissiveon := SCADA_read_23[1].0;
END_IF;
END_PROGRAM]]></PouBody>
</Pou>
// when hmip1state > 1
<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="Modbus_SCADA_READ_S2_3_single_ST" ElementGuid="09d40845-ea9e-450a-846d-75b3c0a9fbc7" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <Program />
  <LocalVars>
    <Variable Name="MSG_Read_SCADA_119" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),(4,10000,3,1),(120,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="SCADA_read_119" Comment="" Address="" Alias="" StringSize="0" DataType="MODBUSLOCADDR" InitialValue="" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Read_SCADA_352" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),(4,10000,3,1),(353,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="SCADA_read_352" Comment="" Address="" Alias="" StringSize="0" DataType="MODBUSLOCADDR" InitialValue="" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Read_SCADA_353" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),(4,10000,3,1),(354,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="SCADA_read_353" Comment="" Address="" Alias="" StringSize="0" DataType="MODBUSLOCADDR" InitialValue="" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
  </LocalVars>
  <PouBody><![CDATA[PROGRAM Modbus_SCADA_READ_S2_3_single_ST
// Read (Cmd = 3), Targetcfg address 119 = mv201status, 352 = lit301ah, 
// and 353 = lit301al
// mv201status
MSG_Read_SCADA_119(
    IN := (hmip1state > 1),
    LocalAddr := SCADA_read_119
);
IF (hmip1state > 1) AND MSG_Read_SCADA_119.Q THEN
    hmimv201status := ANY_TO_INT(SCADA_read_119[1]);
END_IF;
// lit301ah
MSG_Read_SCADA_352(
    IN := (hmip1state > 1),
    LocalAddr := SCADA_read_352
);
IF (hmip1state > 1) AND MSG_Read_SCADA_352.Q THEN
    hmilit301ah := SCADA_read_352[1].0;
END_IF;
// lit301al
MSG_Read_SCADA_353(
    IN := (hmip1state > 1),
    LocalAddr := SCADA_read_353
);
IF (hmip1state > 1) AND MSG_Read_SCADA_353.Q THEN
    hmilit301al := SCADA_read_353[1].0;
END_IF;
END_PROGRAM]]></PouBody>
</Pou>

(* 1.3 Read IO and level from Plant (100-108) *)
MSG_Trigger_ReadPlant := TRUE;
IF MSG_Trigger_ReadPlant THEN
    (* Parse Plant data *)
    IO_MV101_DI_ZSO := (Plant_Read[0] <> 0);
    IO_MV101_DI_ZSC := (Plant_Read[1] <> 0);
    IO_P101_DI_Run := (Plant_Read[2] <> 0);
    IO_P102_DI_Run := (Plant_Read[3] <> 0);
    
    (* Parse REAL level value (2 registers) *)
    (* Requires MOVE_REAL or similar instruction to convert two INTs to REAL *)
    (* Simplified example: *)
    TempWord := INT_TO_WORD(Plant_Read[4]);
    (* hmilit101pv := ...; actual requires 32-bit combination *)
    (* Temporary simplification: *)
    hmilit101pv := INT_TO_REAL(Plant_Read[4]);
    
    hmilit101ahh := (Plant_Read[6] <> 0);
    hmilit101ah := (Plant_Read[7] <> 0);
    hmilit101al := (Plant_Read[8] <> 0);
    hmilit101all := (Plant_Read[9] <> 0);
    
    MSG_Trigger_ReadPlant := FALSE;
END_IF;

(*
================================================================================
Phase 2: Process PLANT control commands
================================================================================
*)

<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="Plant_Control" ElementGuid="3b9cb15f-f759-4fa9-9da6-c0844f2cf973" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <Program />
  <LocalVars />
  <PouBody><![CDATA[PROGRAM Plant_Control
IF hmiplantreseton THEN
    hmimv101reset := TRUE;
    hmip101reset := TRUE;
    hmip102reset := TRUE;
END_IF;

IF hmiplantautoon THEN
    hmimv101auto := TRUE;
    hmip101auto := TRUE;
    hmip102auto := TRUE;
END_IF;

IF hmiplantautooff THEN
    hmimv101auto := FALSE;
    hmip101auto := FALSE;
    hmip102auto := FALSE;
END_IF;
END_PROGRAM]]></PouBody>
</Pou>

(*
================================================================================
Phase 3: Calculate Permissive conditions
================================================================================
*)

(* P1 Permissive *)
hmip1permissiveon := hmimv101avl AND (hmip101avl OR hmip102avl);
hmiplantready := hmip1permissiveon AND hmip2permissiveon AND hmip3permissiveon AND hmip4permissiveon;

(* P101 Permissive (16-bit word operation) *)
hmip101permissive.0 := (hmilit101hty AND NOT hmilit101all);
hmip101permissive.1 := (hmimv201status = 2);

(* P101 MSG Permissive *)
hmip101msgpermissive.1 := hmip101permissive.0;
hmip101msgpermissive.2 := hmip101permissive.1;

(* P102 Permissive (16-bit word operation) *)
hmip102permissive.0 := (hmilit101hty AND NOT hmilit101all);
hmip102permissive.1 := (hmimv201status = 2);

(* P102 MSG Permissive *)
hmip102msgpermissive.1 := hmip102permissive.0;
hmip102msgpermissive.2 := hmip102permissive.1;

(*
================================================================================
Phase 4: Calculate Shutdown conditions
================================================================================
*)

(* P101 SD *)
hmip101sd.0 := (hmilit101hty AND hmilit101all);
hmip101sd.1 := ((hmip101status = 2) AND (hmimv201status <> 2));
hmip101sd.2 := FALSE;

(* P101 MSG Shutdown *)
hmip101msgshutdown.1 := hmip101shutdown.0;
hmip101msgshutdown.2 := hmip101shutdown.1;
hmip101msgshutdown.3 := hmip101shutdown.2;

(* P102 SD *)
hmip102sd.0 := (hmilit101hty AND hmilit101all);
hmip102sd.1 := ((hmip102status = 2) AND (hmimv201status <> 2));
hmip102sd.2 := FALSE;

(* P102 MSG Shutdown *)
hmip102msgshutdown.1 := hmip102shutdown.0;
hmip102msgshutdown.2 := hmip102shutdown.1;
hmip102msgshutdown.3 := hmip102shutdown.2;

(* Plant Stop command *)
IF hmiplantstop THEN
    hmip1shutdown := TRUE;
END_IF;

(*
================================================================================
Phase 5: State machine logic
================================================================================
*)

<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="State_Machine" ElementGuid="22daf525-1448-4678-9802-d89b1bb1e542" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <Program />
  <LocalVars />
  <PouBody><![CDATA[PROGRAM State_Machine
CASE hmip1state OF
    1:  (* State 1: Standby *)
        hmip1state_prev := 1;
        Mid_MV101_AutoInp := FALSE;
        Mid_P_RAW_WATER_DUTY_AutoInp := FALSE;
        hmip1ready := FALSE;
        
        IF hmiplantready AND hmiplantstart AND hmip1permissiveon THEN
            hmip1state := 2;
        END_IF;
        
    2:  (* State 2: Running *)
        hmip1state_prev := 2;
        
        IF hmilit101al THEN
            Mid_MV101_AutoInp := TRUE;
        END_IF;
        IF hmilit101ah THEN
            Mid_MV101_AutoInp := FALSE;
        END_IF;

        IF (hmimv201status = 2) AND hmilit301al THEN
            Mid_P_RAW_WATER_DUTY_AutoInp := TRUE;
        END_IF;
        IF (hmimv201status <> 2) OR hmilit301ah THEN
            Mid_P_RAW_WATER_DUTY_AutoInp := FALSE;
        END_IF;
        
        IF hmip1shutdown THEN
            hmip1state := 3;
            hmip1shutdown := FALSE;
        END_IF;
        
    3:  (* State 3: Shutdown Hold *)
        hmip1state_prev := 3;
        
        IF hmilit101al THEN
            Mid_MV101_AutoInp := TRUE;
        END_IF;
        IF hmilit101ah THEN
            Mid_MV101_AutoInp := FALSE;
        END_IF;
        
        IF (hmimv201status = 2) AND hmilit301al THEN
            Mid_P_RAW_WATER_DUTY_AutoInp := TRUE;
        END_IF;
        IF (hmimv201status <> 2) OR hmilit301ah THEN
            Mid_P_RAW_WATER_DUTY_AutoInp := FALSE;
        END_IF;
        
        (* Both levels high, return state 2 *)
        IF hmilit101ah AND hmilit301ah THEN
            Mid_MV101_AutoInp := FALSE;
            Mid_P_RAW_WATER_DUTY_AutoInp := FALSE;
            hmip1state := 2;
        END_IF;
        
        (* The second shutdown command, returns to state 1 *)
        IF hmip1shutdown THEN
            hmip1state := 1;
            hmip1state_prev := 3;
            hmip1shutdown := FALSE;
        END_IF;
        
END_CASE;
END_PROGRAM]]></PouBody>
</Pou>

(*
================================================================================
Phase 6: Execute Function Blocks
================================================================================
*)

(* MV101 Function Block *)
MV101_FB(
    AutoInp := Mid_MV101_AutoInp,
    Auto := hmimv101auto,
    Reset := hmimv101reset,
    DI_ZSO := IO_MV101_DI_ZSO,
    DI_ZSC := IO_MV101_DI_ZSC,
    FTO_Init := FALSE,      (* hmimv101fto = 0 from pre_loop *)
    FTC_Init := FALSE,      (* hmimv101ftc = 0 from pre_loop *)
    Cmd_Open_Init := TRUE,  (* hmimv101open = 1 from pre_loop *)
    Cmd_Close_Init := FALSE (* hmimv101close = 0 from pre_loop *)
);
hmimv101status_upd := MV101_FB.Status;
hmimv101avl := MV101_FB.Avl;
IO_MV101_DO_Open := MV101_FB.DO_Open;
IO_MV101_DO_Close := MV101_FB.DO_Close;

IF hmimv101status_upd <> -99 THEN
    hmimv101status := hmimv101status_upd;
END_IF;

(* Pump Duty Selection Function Block *)
P_RAW_WATER_DUTY_FB(
    AutoInp := Mid_P_RAW_WATER_DUTY_AutoInp,
    Pmp1_Status := hmip101status,
    Pmp1_Avl := hmip101avl,
    Pmp2_Status := hmip102status,
    Pmp2_Avl := hmip102avl,
    Selection := hmiprawwaterdutyselection
);
hmibothpmpnotavl := P_RAW_WATER_DUTY_FB.Both_Pmp_Not_Avl;
hmiselectedpmpnotavl := P_RAW_WATER_DUTY_FB.Selected_Pmp_Not_Avl;
hmipumprunning := P_RAW_WATER_DUTY_FB.Pump_Running;

(* P101 Function Block *)
P101_FB(
    Start := P_RAW_WATER_DUTY_FB.Start_Pmp1,
    Auto := hmip101auto,
    Reset := hmip101reset,
    Permissive := hmip101permissive,
    SD := hmip101sd,
    DI_Run := IO_P101_DI_Run,
    DI_Auto := TRUE,   (* Assume remote mode always enabled *)
    DI_Fault := FALSE  (* Read from actual IO if available *)
);
hmip101status_upd := P101_FB.Status;
hmip101fault := P101_FB.Fault;
hmip101avl := P101_FB.Avl;
hmip101shutdown := P101_FB.Shutdown;
IO_P101_DO_Start := P101_FB.DO_Start;

IF hmip101status_upd <> -99 THEN
    hmip101status := hmip101status_upd;
END_IF;

(* P102 Function Block *)
P102_FB(
    Start := P_RAW_WATER_DUTY_FB.Start_Pmp2,
    Auto := hmip102auto,
    Reset := hmip102reset,
    Permissive := hmip102permissive,
    SD := hmip102sd,
    DI_Run := IO_P102_DI_Run,
    DI_Auto := TRUE,   (* Assume remote mode always enabled *)
    DI_Fault := FALSE  (* Read from actual IO if available *)
);
hmip102status_upd := P102_FB.Status;
hmip102fault := P102_FB.Fault;
hmip102avl := P102_FB.Avl;
hmip102shutdown := P102_FB.Shutdown;
IO_P102_DO_Start := P102_FB.DO_Start;

IF hmip102status_upd <> -99 THEN
    hmip102status := hmip102status_upd;
END_IF;

(*
================================================================================
Phase 7: Send DO commands to Plant
================================================================================
*)

(* Fill Plant write buffer (50001-50004) *)
Plant_Write[0] := BOOL_TO_INT(IO_MV101_DO_Open);
Plant_Write[1] := BOOL_TO_INT(IO_MV101_DO_Close);
Plant_Write[2] := BOOL_TO_INT(IO_P101_DO_Start);
Plant_Write[3] := BOOL_TO_INT(IO_P102_DO_Start);

(* Trigger MSG_WRITE_PLANT *)
MSG_Trigger_WritePlant := TRUE;
IF MSG_Trigger_WritePlant THEN
    (* Execute MSG write *)
    MSG_Trigger_WritePlant := FALSE;
END_IF;

(*
================================================================================
Phase 8: Send data to SCADA
================================================================================
*)

<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="Modbus_SCADA_ST" ElementGuid="ba38fcc2-8de7-4cd8-904a-541f8934bc7f" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <Program />
  <LocalVars>
    <Variable Name="SCADA_write" Comment="" Address="" Alias="" StringSize="0" DataType="MODBUSLOCADDR" InitialValue="" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="">
      <Dimension Lower="0" Upper="38" />
    </Variable>
    <Variable Name="MSG_Write_SCADA_8" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(9,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_9" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(10,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_10" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(11,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_11" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(12,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_46" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(47,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_47" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(48,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_48" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(49,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_49" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(50,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_50" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(51,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_51" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(52,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="COP_LIT101_Pv" Comment="" Address="" Alias="" StringSize="0" DataType="COP" InitialValue=",,,,2(),,2(0),2(0)" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_53" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(54,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_54" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(55,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_57" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(58,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_58" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(59,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_79" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(80,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_80" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(81,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_81" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(82,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_82" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(83,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_83" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(84,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_84" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(85,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_85" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(86,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_87" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(88,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_92" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(93,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_94" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(95,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_95" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(96,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_96" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(97,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_97" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(98,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_98" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(99,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_99" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(100,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_100" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(101,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_102" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(103,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_103" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(104,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_108" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(109,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_110" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(111,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_112" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(113,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_113" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(114,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_Write_SCADA_114" Comment="" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(115,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_P1State_1to2" Comment="P1 State transition 1-&gt;2" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(11,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_P1State_2to3" Comment="P1 State transition 2-&gt;3" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(11,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_P1State_3to2" Comment="P1 State transition 3-&gt;2" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(11,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
    <Variable Name="MSG_P1State_3to1" Comment="P1 State transition 3-&gt;1" Address="" Alias="" StringSize="0" DataType="MSG_MODBUS2" InitialValue="2(),,(11,(10,8,0,3),502,255,250,3000,FALSE),,0" Modifier="NonRetain" Kind="Var" AccessRights="ReadWrite" RetainFlags="" CommentFields="" Attributes="0" GroupName="" />
  </LocalVars>
  <PouBody><![CDATA[PROGRAM Modbus_SCADA_ST
(* PLC as a Modbus client communicates with the Modbus server running on an 
EC2 with IP 10.8.0.3 *)
// Follow the offset no. in SCADA_TAGS

// HMI.P1.Permissive_On (offset 8)
SCADA_write[0][1].0 := hmip1permissiveon;
MSG_Write_SCADA_8(
    IN := TRUE,
    LocalAddr := SCADA_write[0],
	LocalCfg := LocalCfgWrite_c6
);

// HMI.P1.Shutdown (offset 9)
SCADA_write[1][1].0 := hmip1shutdown;
MSG_Write_SCADA_9(
    IN := TRUE,
    LocalAddr := SCADA_write[1],
	LocalCfg := LocalCfgWrite_c6
);

// HMI.P1.State (offset 10) - Independent MSG for each state transition
SCADA_write[2][1] := ANY_TO_WORD(hmip1state);

// Transition 1->2
MSG_P1State_1to2(
    IN := (hmip1state_prev = 1 AND hmip1state = 2),
    LocalAddr := SCADA_write[2],
    LocalCfg := LocalCfgWrite_c6
);

// Transition 2->3
MSG_P1State_2to3(
    IN := (hmip1state_prev = 2 AND hmip1state = 3),
    LocalAddr := SCADA_write[2],
    LocalCfg := LocalCfgWrite_c6
);

// Transition 3->2
MSG_P1State_3to2(
    IN := (hmip1state_prev = 3 AND hmip1state = 2),
    LocalAddr := SCADA_write[2],
    LocalCfg := LocalCfgWrite_c6
);

// Transition 3->1
MSG_P1State_3to1(
    IN := (hmip1state_prev = 3 AND hmip1state = 1),
    LocalAddr := SCADA_write[2],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P1.Ready (offset 11) - write when hmip1state_prev=1
SCADA_write[3][1].0 := hmip1ready;
MSG_Write_SCADA_11(
    IN := (hmip1state_prev = 1),
    LocalAddr := SCADA_write[3],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.LIT101.Hty (offset 46)
SCADA_write[4][1].0 := hmilit101hty;
MSG_Write_SCADA_46(
    IN := TRUE,
    LocalAddr := SCADA_write[4],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.LIT101.AHH (offset 47)
SCADA_write[5][1].0 := hmilit101ahh;
MSG_Write_SCADA_47(
    IN := TRUE,
    LocalAddr := SCADA_write[5],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.LIT101.AH (offset 48)
SCADA_write[6][1].0 := hmilit101ah;
MSG_Write_SCADA_48(
    IN := TRUE,
    LocalAddr := SCADA_write[6],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.LIT101.AL (offset 49)
SCADA_write[7][1].0 := hmilit101al;
MSG_Write_SCADA_49(
    IN := TRUE,
    LocalAddr := SCADA_write[7],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.LIT101.ALL (offset 50)
SCADA_write[8][1].0 := hmilit101all;
MSG_Write_SCADA_50(
    IN := TRUE,
    LocalAddr := SCADA_write[8],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.LIT101.Pv (offset 51, 2 registers) - REAL type
COP_LIT101_Pv(
    Enable := TRUE,
    Src := hmilit101pv,
    Dest := SCADA_write[9],
    Length := 2
);
MSG_Write_SCADA_51(
    IN := TRUE,
    LocalAddr := SCADA_write[9],
    LocalCfg := LocalCfgWrite_c16
);

// HMI.MV101.Auto (offset 53)
SCADA_write[10][1].0 := hmimv101auto;
MSG_Write_SCADA_53(
    IN := TRUE,
    LocalAddr := SCADA_write[10],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.MV101.Reset (offset 54)
SCADA_write[11][1].0 := hmimv101reset;
MSG_Write_SCADA_54(
    IN := TRUE,
    LocalAddr := SCADA_write[11],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.MV101.Status (offset 57) - INT type
SCADA_write[12][1] := ANY_TO_WORD(hmimv101status);
MSG_Write_SCADA_57(
    IN := TRUE,
    LocalAddr := SCADA_write[12],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.MV101.Avl (offset 58)
SCADA_write[13][1].0 := hmimv101avl;
MSG_Write_SCADA_58(
    IN := TRUE,
    LocalAddr := SCADA_write[13],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P101.Auto (offset 79)
SCADA_write[14][1].0 := hmip101auto;
MSG_Write_SCADA_79(
    IN := TRUE,
    LocalAddr := SCADA_write[14],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P101.Fault (offset 80)
SCADA_write[15][1].0 := hmip101fault;
MSG_Write_SCADA_80(
    IN := TRUE,
    LocalAddr := SCADA_write[15],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P101.Permissive (offset 81) - INT type
SCADA_write[16][1] := ANY_TO_WORD(hmip101permissive);
MSG_Write_SCADA_81(
    IN := TRUE,
    LocalAddr := SCADA_write[16],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P101.MSG_Permissive (offset 82) - INT type
SCADA_write[17][1] := ANY_TO_WORD(hmip101msgpermissive);
MSG_Write_SCADA_82(
    IN := TRUE,
    LocalAddr := SCADA_write[17],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P101.SD (offset 83) - INT type
SCADA_write[18][1] := ANY_TO_WORD(hmip101sd);
MSG_Write_SCADA_83(
    IN := TRUE,
    LocalAddr := SCADA_write[18],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P101.MSG_Shutdown (offset 84) - INT type
SCADA_write[19][1] := ANY_TO_WORD(hmip101msgshutdown);
MSG_Write_SCADA_84(
    IN := TRUE,
    LocalAddr := SCADA_write[19],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P101.Reset (offset 85)
SCADA_write[20][1].0 := hmip101reset;
MSG_Write_SCADA_85(
    IN := TRUE,
    LocalAddr := SCADA_write[20],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P101.Avl (offset 87)
SCADA_write[21][1].0 := hmip101avl;
MSG_Write_SCADA_87(
    IN := TRUE,
    LocalAddr := SCADA_write[21],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P101.Shutdown (offset 92) - INT type
SCADA_write[22][1] := ANY_TO_WORD(hmip101shutdown);
MSG_Write_SCADA_92(
    IN := TRUE,
    LocalAddr := SCADA_write[22],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P101.Status (offset 94) - INT type
SCADA_write[23][1] := ANY_TO_WORD(hmip101status);
MSG_Write_SCADA_94(
    IN := TRUE,
    LocalAddr := SCADA_write[23],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P102.Auto (offset 95)
SCADA_write[24][1].0 := hmip102auto;
MSG_Write_SCADA_95(
    IN := TRUE,
    LocalAddr := SCADA_write[24],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P102.Permissive (offset 96) - INT type
SCADA_write[25][1] := ANY_TO_WORD(hmip102permissive);
MSG_Write_SCADA_96(
    IN := TRUE,
    LocalAddr := SCADA_write[25],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P102.MSG_Permissive (offset 97) - INT type
SCADA_write[26][1] := ANY_TO_WORD(hmip102msgpermissive);
MSG_Write_SCADA_97(
    IN := TRUE,
    LocalAddr := SCADA_write[26],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P102.SD (offset 98) - INT type
SCADA_write[27][1] := ANY_TO_WORD(hmip102sd);
MSG_Write_SCADA_98(
    IN := TRUE,
    LocalAddr := SCADA_write[27],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P102.MSG_Shutdown (offset 99) - INT type
SCADA_write[28][1] := ANY_TO_WORD(hmip102msgshutdown);
MSG_Write_SCADA_99(
    IN := TRUE,
    LocalAddr := SCADA_write[28],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P102.Reset (offset 100)
SCADA_write[29][1].0 := hmip102reset;
MSG_Write_SCADA_100(
    IN := TRUE,
    LocalAddr := SCADA_write[29],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P102.Avl (offset 102)
SCADA_write[30][1].0 := hmip102avl;
MSG_Write_SCADA_102(
    IN := TRUE,
    LocalAddr := SCADA_write[30],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P102.Fault (offset 103)
SCADA_write[31][1].0 := hmip102fault;
MSG_Write_SCADA_103(
    IN := TRUE,
    LocalAddr := SCADA_write[31],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P102.Shutdown (offset 108) - INT type
SCADA_write[32][1] := ANY_TO_WORD(hmip102shutdown);
MSG_Write_SCADA_108(
    IN := TRUE,
    LocalAddr := SCADA_write[32],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P102.Status (offset 110) - INT type
SCADA_write[33][1] := ANY_TO_WORD(hmip102status);
MSG_Write_SCADA_110(
    IN := TRUE,
    LocalAddr := SCADA_write[33],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P_RAW_WATER_DUTY.Both_Pmp_Not_Avl (offset 112)
SCADA_write[34][1].0 := hmibothpmpnotavl;
MSG_Write_SCADA_112(
    IN := TRUE,
    LocalAddr := SCADA_write[34],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P_RAW_WATER_DUTY.Selected_Pmp_Not_Avl (offset 113)
SCADA_write[35][1].0 := hmiselectedpmpnotavl;
MSG_Write_SCADA_113(
    IN := TRUE,
    LocalAddr := SCADA_write[35],
    LocalCfg := LocalCfgWrite_c6
);

// HMI.P_RAW_WATER_DUTY.Pump_Running (offset 114)
SCADA_write[36][1].0 := hmipumprunning;
MSG_Write_SCADA_114(
    IN := TRUE,
    LocalAddr := SCADA_write[36],
    LocalCfg := LocalCfgWrite_c6
);
END_PROGRAM]]></PouBody>
</Pou>


(*
================================================================================
End of program
================================================================================
*)

END_PROGRAM

(*
================================================================================
Micro820 Function Blocks for PLC1
Implementation of MV_FBD, PMP_FBD, and Duty2_FBD based on controlblock.py
================================================================================
*)

(*
================================================================================
FUNCTION BLOCK: MV_FBD
Controls motorized valves with open/close commands and position feedback
================================================================================
*)
<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="MV_FBD" ElementGuid="d79db1ca-e24d-48e7-bf4d-2d3e0f389afd" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <FunctionBlock IdentifierNb="0" Keyword="" InitInstance="false" SymbMonExtraBytes="128" />
  <LocalVars>
    <Variable Name="Auto" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Reset" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="DI_ZSO" Comment="" Address="" Alias="Zone switch open" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="DI_ZSC" Comment="" Address="" Alias="Zone switch closed" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="AutoInp" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="FTO_Init" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="FTC_Init" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Cmd_Open_Init" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Cmd_Close_Init" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Status" Comment="1=close; 2=open; -99=no change; 0=transition" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="DO_Open" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="DO_Close" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Avl" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="FTC" Comment="" Address="" Alias="Fail to close" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
    <Variable Name="FTO" Comment="" Address="" Alias="Fail to open" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
    <Variable Name="Cmd_Open" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
    <Variable Name="Cmd_Close" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
  </LocalVars>
  <PouBody><![CDATA[FUNCTION_BLOCK MV_FBD
(*Controls motorized valves with open/close commands and position feedback. 
Manages valve automation based on AutoInp signal, 
reads limit switch positions (ZSO for open, ZSC for closed), 
handles fault detection (FTO - Fail To Open, FTC - Fail To Close), 
and outputs digital commands to actuate the valve. 
Returns current valve status and availability.*)
// Initialize fault states from inputs on first scan
IF __SYSVA_FIRST_SCAN THEN
	FTO := FTO_Init;
	FTC := FTC_Init;
	Cmd_Open := Cmd_Open_Init;
	Cmd_Close := Cmd_Close_Init;
END_IF;

// Reset fault logic
IF Reset THEN
    FTO := FALSE;
    FTC := FALSE;
END_IF;

// Availability logic
Avl := Auto;

// Auto control logic
IF AutoInp THEN
    Cmd_Open := TRUE;
    Cmd_Close := FALSE;
ELSE
    Cmd_Open := FALSE;
    Cmd_Close := TRUE;
END_IF;

// Output commands
DO_Open := Cmd_Open;
DO_Close := Cmd_Close;

// Initialize Status to -99 (no update by default)
Status := -99;
// Status feedback logic
IF DI_ZSC AND NOT DI_ZSO THEN
	Status := 1; // valve closed
ELSIF DI_ZSO AND NOT DI_ZSC THEN
	Status := 2; // valve open
ELSIF DI_ZSO AND DI_ZSC THEN
	Status := 0; // both active (error state)
ELSE
	Status := -99; // no change or in transition
END_IF;
END_FUNCTION_BLOCK]]></PouBody>
</Pou>

(******************************************************************************
FUNCTION BLOCK: SWITCH_FBD
Delays a digital switch alarm using an IEC TON timer
******************************************************************************)
<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="SWITCH_FBD" ElementGuid="6a1d4c0f-0d51-4f0b-9a6c-7e2b9b1654b9" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
    <FunctionBlock IdentifierNb="0" Keyword="" InitInstance="false" SymbMonExtraBytes="128" />
    <LocalVars>
        <Variable Name="DI_LS" Comment="Limit switch input" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
        <Variable Name="DelayMs" Comment="Delay time in milliseconds" Address="" Alias="" StringSize="0" DataType="DINT" InitialValue="0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
        <Variable Name="Status" Comment="Delayed alarm output" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
        <Variable Name="DelayTime" Comment="Converted delay time" Address="" Alias="" StringSize="0" DataType="TIME" InitialValue="T#0ms" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
        <Variable Name="TON_Delay" Comment="IEC on-delay timer" Address="" Alias="" StringSize="0" DataType="TON" InitialValue="" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
    </LocalVars>
    <PouBody><![CDATA[FUNCTION_BLOCK SWITCH_FBD
(* Delays a digital switch alarm using an IEC TON timer. *)
DelayTime := DINT_TO_TIME(DelayMs);
TON_Delay(IN := DI_LS, PT := DelayTime);
Status := TON_Delay.Q;
END_FUNCTION_BLOCK]]></PouBody>
</Pou>

(*
================================================================================
FUNCTION BLOCK: PMP_FBD
Controls pumps with start commands, permissive checks, and shutdown conditions
================================================================================
*)

<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="PMP_FBD" ElementGuid="c77daa2e-bb57-4417-95db-2a8adf1effeb" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <FunctionBlock IdentifierNb="0" Keyword="" InitInstance="false" SymbMonExtraBytes="128" />
  <LocalVars>
    <Variable Name="Start" Comment="Start command from Duty selector" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Auto" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Reset" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Permissive" Comment="Permissive conditions (bit-encoded, 65535=all satisfied)" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="SD" Comment="Shutdown conditions (bit-encoded)" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="DI_Run" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="DI_Auto" Comment="Remote/Auto mode" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="DI_Fault" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Avl_Init" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Fault_Init" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Shutdown_Init" Comment="Initial shutdown state" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Shutdown" Comment="Shutdown status" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Status" Comment="-99=no change, 1=stopped, 2=running" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="-99" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Fault" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Avl" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="DO_Start" Comment="Start command" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Cmd_Start" Comment="Internal start command" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
    <Variable Name="Internal_SD" Comment="Internal shutdown state" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
    <Variable Name="Cmd" Comment="Internal command state" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="1" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
  </LocalVars>
  <PouBody><![CDATA[FUNCTION_BLOCK PMP_FBD
(* Controls pumps with start commands, permissive checks, and shutdown conditions.
Manages pump automation based on Start signal from duty selector,
reads pump running feedback (DI_Run), handles remote/auto mode (DI_Auto),
monitors fault conditions (DI_Fault), validates permissive conditions,
processes shutdown requests, and outputs start command (DO_Start).
Returns current pump status, fault state, availability, and shutdown status. *)

// Initialize states from inputs on first scan
IF __SYSVA_FIRST_SCAN THEN
    Avl := Avl_Init;
    Fault := Fault_Init;
    Internal_SD := Shutdown_Init;
    Cmd_Start := FALSE;
END_IF;

// Reset logic - clears shutdown state
IF Reset THEN
    Internal_SD := 0;
END_IF;

// Update fault state: fault if DI_Fault active OR shutdown condition exists
Fault := DI_Fault OR (Internal_SD <> 0);

// Availability logic: available when Auto AND Remote AND NOT Fault AND NOT Shutdown
Avl := Auto AND DI_Auto AND NOT Fault AND (Internal_SD = 0);

// Initialize Status to -99 (no update by default)
Status := -99;
// Status feedback from DI_Run
IF NOT DI_Run THEN
    Status := 1;  // pump stopped
ELSE
    Status := 2;  // pump running
END_IF;

// Command logic
IF DI_Auto THEN
    // Remote mode active
    IF Auto THEN
        // Auto mode
        IF DI_Run THEN
            Cmd := 2;
        END_IF;
        
        IF NOT DI_Run OR Fault THEN
            Cmd := 1;
        END_IF;
        
        IF Start THEN
            // Start requested from duty selector
            IF NOT Fault AND (Permissive = -1) AND (SD = 0) THEN
                // All conditions satisfied: no fault, 
				// all permissives met, no shutdown
                Cmd_Start := TRUE;
            ELSIF Cmd_Start OR (SD <> 0) OR Fault THEN
                // Stop conditions: already running OR shutdown requested OR fault
                Internal_SD := SD;
                Cmd_Start := FALSE;
            END_IF;
        ELSE
            // No start request
            Cmd_Start := FALSE;
        END_IF;
    ELSE
        // Manual mode - no auto start
        Cmd_Start := FALSE;
    END_IF;
ELSE
    // Not in remote mode - no auto control
    Cmd_Start := FALSE;
    Cmd := 1;
END_IF;

// Output assignments
DO_Start := Cmd_Start;
Shutdown := Internal_SD;
END_FUNCTION_BLOCK]]></PouBody>
</Pou>

(*
================================================================================
FUNCTION BLOCK: Duty2_FBD
Manages duty/standby selection between two pumps
================================================================================
*)
<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="Duty2_FBD" ElementGuid="c9e2a266-b8e0-47eb-aaf0-faa8bd7682ec" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <FunctionBlock IdentifierNb="0" Keyword="" InitInstance="false" SymbMonExtraBytes="128" />
  <LocalVars>
    <Variable Name="AutoInp" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Pmp1_Status" Comment="" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Pmp1_Avl" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Pmp2_Status" Comment="" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Pmp2_Avl" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Selection" Comment="Duty pump selection (1=P101 duty, 2=P102 duty)" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Start_Pmp1" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Start_Pmp2" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Both_Pmp_Not_Avl" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Selected_Pmp_Not_Avl" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Pump_Running" Comment="At least one pump running" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
  </LocalVars>
  <PouBody><![CDATA[FUNCTION_BLOCK Duty2_FBD
(* Manages duty/standby selection between two pumps *)
(* Initialize outputs *)
Start_Pmp1 := FALSE;
Start_Pmp2 := FALSE;
Selected_Pmp_Not_Avl := FALSE;

(* Check if any pump is running *)
IF (Pmp1_Status = 2) OR (Pmp2_Status = 2) THEN
    Pump_Running := TRUE;
ELSE
    Pump_Running := FALSE;
END_IF;

(* Check if both pumps not available *)
Both_Pmp_Not_Avl := (NOT Pmp1_Avl) AND (NOT Pmp2_Avl);

(* Auto control logic *)
IF AutoInp THEN
    IF Selection = 1 THEN
        IF Pmp1_Avl THEN
            (* Duty pump available *)
            Start_Pmp1 := TRUE;
            Start_Pmp2 := FALSE;
            Selected_Pmp_Not_Avl := FALSE;
        ELSIF (NOT Pmp1_Avl) AND Pmp2_Avl THEN
            (* Duty pump not available, start standby *)
            Start_Pmp1 := FALSE;
            Start_Pmp2 := TRUE;
            Selected_Pmp_Not_Avl := TRUE;
        ELSIF (NOT Pmp1_Avl) AND (NOT Pmp2_Avl) THEN
            (* Both pumps not available *)
            Start_Pmp1 := FALSE;
            Start_Pmp2 := FALSE;
        ELSE
            Selected_Pmp_Not_Avl := FALSE;
        END_IF;
    END_IF;
    
    (* Selection = 2: P102 is duty pump *)
    IF Selection = 2 THEN
        IF Pmp2_Avl THEN
            (* Duty pump available *)
            Start_Pmp1 := FALSE;
            Start_Pmp2 := TRUE;
            Selected_Pmp_Not_Avl := FALSE;
        ELSIF (NOT Pmp2_Avl) AND Pmp1_Avl THEN
            (* Duty pump not available, start standby *)
            Start_Pmp1 := TRUE;
            Start_Pmp2 := FALSE;
            Selected_Pmp_Not_Avl := TRUE;
        ELSIF (NOT Pmp1_Avl) AND (NOT Pmp2_Avl) THEN
            (* Both pumps not available *)
            Start_Pmp1 := FALSE;
            Start_Pmp2 := FALSE;
        ELSE
            Selected_Pmp_Not_Avl := FALSE;
        END_IF;
    END_IF;
ELSE
    (* Not in auto mode - stop all pumps *)
    Start_Pmp1 := FALSE;
    Start_Pmp2 := FALSE;
END_IF;
END_FUNCTION_BLOCK]]></PouBody>
</Pou>
(*
================================================================================
FUNCTION BLOCK: AIN_FBD
Analog input function block with alarm monitoring
================================================================================
*)
<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="AIN_FBD" ElementGuid="a1b2c3d4-e5f6-7890-1234-567890abcdef" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <FunctionBlock IdentifierNb="0" Keyword="" InitInstance="false" SymbMonExtraBytes="128" />
  <LocalVars>
    <Variable Name="Value" Comment="Analog input value" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="0.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="AHH_SP" Comment="High-high alarm setpoint" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="100.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="AH_SP" Comment="High alarm setpoint" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="90.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="AL_SP" Comment="Low alarm setpoint" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="10.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="ALL_SP" Comment="Low-low alarm setpoint" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="0.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Hty" Comment="Healthy - no alarms" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="TRUE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="AHH" Comment="High-high alarm" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="AH" Comment="High alarm" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="AL" Comment="Low alarm" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="ALL" Comment="Low-low alarm" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
  </LocalVars>
  <PouBody><![CDATA[FUNCTION_BLOCK AIN_FBD
(* Analog input function block with alarm monitoring *)

(* Initialize all alarms to FALSE *)
AHH := FALSE;
AH := FALSE;
AL := FALSE;
ALL := FALSE;
Hty := TRUE;

(* Check for high-high alarm *)
IF Value >= AHH_SP THEN
    AHH := TRUE;
    Hty := FALSE;
END_IF;

(* Check for high alarm *)
IF Value >= AH_SP AND Value < AHH_SP THEN
    AH := TRUE;
    Hty := FALSE;
END_IF;

(* Check for low alarm *)
IF Value <= AL_SP AND Value > ALL_SP THEN
    AL := TRUE;
    Hty := FALSE;
END_IF;

(* Check for low-low alarm *)
IF Value <= ALL_SP THEN
    ALL := TRUE;
    Hty := FALSE;
END_IF;

END_FUNCTION_BLOCK]]></PouBody>
</Pou>

(*
================================================================================
FUNCTION BLOCK: FIT_FBD
Flow indicator/totalizer with alarm monitoring
================================================================================
*)
<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="FIT_FBD" ElementGuid="b2c3d4e5-f678-90ab-cdef-1234567890ab" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <FunctionBlock IdentifierNb="0" Keyword="" InitInstance="false" SymbMonExtraBytes="128" />
  <LocalVars>
    <Variable Name="FlowRate" Comment="Current flow rate" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="0.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="AHH_SP" Comment="High-high alarm setpoint" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="100.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="AH_SP" Comment="High alarm setpoint" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="90.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="AL_SP" Comment="Low alarm setpoint" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="10.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="ALL_SP" Comment="Low-low alarm setpoint" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="0.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Reset_Total" Comment="Reset totalizer" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Hty" Comment="Healthy - no alarms" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="AHH" Comment="High-high alarm" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="AH" Comment="High alarm" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="AL" Comment="Low alarm" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="ALL" Comment="Low-low alarm" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Totalizer" Comment="Accumulated flow total" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="0.0" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="InternalTotal" Comment="Internal totalizer storage" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="0.0" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
  </LocalVars>
  <PouBody><![CDATA[FUNCTION_BLOCK FIT_FBD
(* Flow indicator/totalizer with alarm monitoring *)

(* Initialize all alarms to FALSE *)
AHH := FALSE;
AH := FALSE;
AL := FALSE;
ALL := FALSE;
Hty := FALSE;

(* Reset totalizer if requested *)
IF Reset_Total THEN
    InternalTotal := 0.0;
END_IF;

(* Totalizer logic - accumulate flow *)
(* In a real system, this would integrate flow over time *)
(* Simplified version: just accumulate the flow rate *)
InternalTotal := InternalTotal + FlowRate;
Totalizer := InternalTotal;

(* Check for high-high alarm *)
IF FlowRate >= AHH_SP THEN
    AHH := TRUE;
END_IF;

(* Check for high alarm *)
IF FlowRate >= AH_SP AND FlowRate < AHH_SP THEN
    AH := TRUE;
END_IF;

(* Check for low alarm *)
IF FlowRate <= AL_SP AND FlowRate > ALL_SP THEN
    AL := TRUE;
END_IF;

(* Check for low-low alarm *)
IF FlowRate <= ALL_SP THEN
    ALL := TRUE;
END_IF;

(* Healthy when no alarms *)
IF NOT AHH AND NOT AH AND NOT AL AND NOT ALL THEN
    Hty := TRUE;
END_IF;

END_FUNCTION_BLOCK]]></PouBody>
</Pou>

(*
================================================================================
FUNCTION BLOCK: UV_FBD
UV lamp control with permissive/shutdown logic
================================================================================
NOTE: Run hour tracking (RunHr, Total_RunHr) should be implemented in the main
program using Clock_Pulse_Generator's Sec_P signal, not in this function block.
See PLC3/PLC5/PLC6 Runtime_Tracking programs for reference implementation.
================================================================================
*)
<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="UV_FBD" ElementGuid="d3e4f5g6-h789-01ab-cdef-234567890abc" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <FunctionBlock IdentifierNb="0" Keyword="" InitInstance="false" SymbMonExtraBytes="128" />
  <LocalVars>
    <Variable Name="AutoInp" Comment="Auto control input signal" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Auto" Comment="Auto mode enable" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="TRUE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Reset" Comment="Reset fault and shutdown" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Permissive" Comment="Permissive conditions (-1 = all satisfied)" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="SD" Comment="Shutdown conditions (0 = no shutdown)" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="DI_Auto" Comment="Digital input - Remote/Auto mode" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="DI_Run" Comment="Digital input - UV running feedback" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="DI_Fault" Comment="Digital input - UV trip/fault" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Status" Comment="UV status (-99=no update, 1=stopped, 2=running)" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="-99" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Fault" Comment="Fault condition" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Avl" Comment="UV availability" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Shutdown" Comment="Shutdown status" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="0" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="DO_Start" Comment="Digital output - Start command" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Internal_SD" Comment="Internal shutdown state" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="0" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
    <Variable Name="Internal_Fault" Comment="Internal fault state" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
    <Variable Name="Cmd_Start" Comment="Internal start command" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
  </LocalVars>
  <PouBody><![CDATA[FUNCTION_BLOCK UV_FBD
(* UV lamp control with permissive/shutdown logic.
Manages UV lamp automation based on AutoInp signal,
reads running feedback (DI_Run) and remote/auto mode (DI_Auto),
monitors fault conditions (DI_Fault), validates permissive conditions,
processes shutdown requests, and outputs start command (DO_Start).
Returns current UV status, fault state, availability, and shutdown status.

NOTE: Run hour tracking is NOT handled here - it should be implemented in
the main program's Runtime_Tracking section using Clock_Pulse_Generator's Sec_P. *)

// Initialize on first scan
IF __SYSVA_FIRST_SCAN THEN
    Internal_SD := 0;
    Internal_Fault := FALSE;
    Cmd_Start := FALSE;
END_IF;

// Reset logic
IF Reset THEN
    Internal_SD := 0;
END_IF;

// Update fault state from DI_Fault
Internal_Fault := DI_Fault;
Fault := Internal_Fault;

// Availability logic
Avl := Auto AND DI_Auto AND NOT Internal_Fault AND (Internal_SD = 0);

// Initialize Status to -99 (no update by default)
Status := -99;
// Status feedback from DI_Run
IF NOT DI_Run THEN
    Status := 1;  // UV stopped
ELSE
    Status := 2;  // UV running
END_IF;

// Command logic for remote/auto mode
IF DI_Auto THEN
    IF AutoInp THEN
        // Auto control active
        IF NOT Internal_Fault AND (Permissive = -1) AND (SD = 0) THEN
            Cmd_Start := TRUE;
        ELSIF Cmd_Start OR (SD <> 0) OR Internal_Fault THEN
            Internal_SD := SD;
            Cmd_Start := FALSE;
        END_IF;
    ELSE
        // Auto input off
        Cmd_Start := FALSE;
    END_IF;
ELSE
    // Not in remote/auto mode
    Cmd_Start := FALSE;
END_IF;

// Output assignments
DO_Start := Cmd_Start;
Shutdown := Internal_SD;
END_FUNCTION_BLOCK]]></PouBody>

(*
================================================================================
FUNCTION BLOCK: VSD_FBD
================================================================================
*)
<?xml version="1.0" encoding="utf-8"?>
<Pou FileVersion="200.00.006" Name="VSD_FBD" ElementGuid="50cf8b59-f23a-40ec-aabc-0531d6671908" Comment="" SingleTextLine="" Language="ST" Localization="Prj" GenDebugInfo="false" UseResPassword="true" GenerateSymbMon="true" Is1499="false" CustomFbd="0" GroupName="(User defined)">
  <FunctionBlock IdentifierNb="0" Keyword="" InitInstance="false" SymbMonExtraBytes="128" />
  <LocalVars>
    <Variable Name="Reset" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="VSD_Faulted" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Auto" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="DI_Auto" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="TRUE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="VSD_Active" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Start" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Permissive" Comment="" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="-1" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Speed_Set" Comment="" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="0.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="SD" Comment="" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="VSD_OutputFreq" Comment="" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="0.0" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="VSD_Ready" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="DI_Run" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarInput" AccessRights="Read" Direction="Input" CommentFields="" Attributes="0" />
    <Variable Name="Avl" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Fault" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Status" Comment="" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="-99" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="FreqCommand" Comment="" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="0.0" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Shutdown" Comment="" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="0" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="DO_Start" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="DO_Stop" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Rdy" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Speed" Comment="" Address="" Alias="" StringSize="0" DataType="REAL" InitialValue="0.0" Modifier="Constant" Kind="VarOutput" AccessRights="Write" Direction="Output" CommentFields="" Attributes="0" />
    <Variable Name="Internal_SD" Comment="" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="0" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
    <Variable Name="Internal_Fault" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
    <Variable Name="Cmd_Start" Comment="" Address="" Alias="" StringSize="0" DataType="BOOL" InitialValue="FALSE" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
    <Variable Name="Cmd" Comment="" Address="" Alias="" StringSize="0" DataType="INT" InitialValue="1" Modifier="Constant" Kind="Var" AccessRights="ReadWrite" Direction="Local" CommentFields="" Attributes="0" />
  </LocalVars>
  <PouBody><![CDATA[FUNCTION_BLOCK VSD_FBD
(* Variable Speed Drive control with speed control and fault monitoring.
Manages VSD automation based on Start signal from duty selector,
reads VSD feedback (VSD_Active, VSD_Ready, VSD_Faulted) from physical simulator,
monitors fault conditions, validates permissive conditions,
processes shutdown requests, controls frequency setpoint,
and outputs start/stop commands.
Returns current VSD status, fault state, availability, and shutdown status.

Based on controlblock.py VSD_FBD implementation. *)

// Initialize on first scan
IF __SYSVA_FIRST_SCAN THEN
    Internal_SD := 0;
    Internal_Fault := FALSE;
    Cmd_Start := FALSE;
    Cmd := 1;
END_IF;

// Reset logic
IF Reset THEN
    Internal_SD := 0;
END_IF;

// Update fault state from VSD_Faulted
Internal_Fault := VSD_Faulted OR (Internal_SD <> 0);
Fault := Internal_Fault;

// Availability logic
Avl := Auto AND DI_Auto AND NOT Internal_Fault AND (Internal_SD = 0);

// Initialize Status to -99 (no update by default)
Status := -99;

// Status feedback from VSD_Active (not DI_Run)
IF NOT VSD_Active THEN
    Status := 1;  // VSD stopped
ELSE
    Status := 2;  // VSD running
END_IF;
Rdy := VSD_Ready;
Speed := VSD_OutputFreq;
// Update Cmd based on VSD_Active
IF VSD_Active THEN
    Cmd := 2;
END_IF;
IF NOT VSD_Active OR VSD_Faulted THEN
    Cmd := 1;
END_IF;

// Command logic for remote/auto mode
IF DI_Auto THEN
    // Remote mode active
    IF Auto THEN
        // Auto mode
        IF Start THEN
            // Start requested from duty selector
            IF NOT VSD_Faulted AND (Permissive = -1) AND (SD = 0) THEN
                // All conditions satisfied: no fault, all permissives met, no shutdown
                Cmd_Start := TRUE;
                DO_Start := TRUE;
                DO_Stop := FALSE;
                FreqCommand := Speed_Set * 100.0;
            ELSIF Cmd_Start OR (SD <> 0) OR VSD_Faulted THEN
                // Stop conditions: already running OR shutdown requested OR fault
                Internal_SD := SD;
                Cmd_Start := FALSE;
                DO_Start := FALSE;
                DO_Stop := FALSE;
                Cmd := 1;
            END_IF;
            
            // Stop if not active
            IF NOT VSD_Active THEN
                DO_Start := FALSE;
                DO_Stop := TRUE;
                FreqCommand := Speed_Set * 100.0;
                Cmd := 1;
            END_IF;
        ELSE
            // No start request - stop VSD
            Cmd_Start := FALSE;
            DO_Start := FALSE;
            DO_Stop := TRUE;
        END_IF;
    ELSE
        // Manual mode - no auto control
        Cmd_Start := FALSE;
        DO_Start := FALSE;
        DO_Stop := TRUE;
    END_IF;
ELSE
    // Not in remote/auto mode
    Cmd_Start := FALSE;
    DO_Start := FALSE;
    DO_Stop := TRUE;
    Cmd := 1;
END_IF;

// Output shutdown status
Shutdown := Internal_SD;
END_FUNCTION_BLOCK]]></PouBody>
</Pou>
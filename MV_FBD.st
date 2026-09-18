(*Controls motorized valves with open/close commands and position feedback. 
Manages valve automation based on AutoInp signal, 
reads limit switch positions (ZSO for open, ZSC for closed), 
handles fault detection (FTO - Fail To Open, FTC - Fail To Close), 
and outputs digital commands to actuate the valve. 
Returns current valve status and availability.*)
// Reset fault logic
IF Reset THEN
    FTO := FALSE;
    FTC := FALSE;
END_IF;
// Availability logic
Avl := Auto;
// Auto control logic
IF Auto THEN
	// Auto mode: AutoInp controls
    IF AutoInp THEN
        DO_Open := TRUE;
        DO_Close := FALSE;
    ELSE
        DO_Open := FALSE;
        DO_Close := TRUE;
	END_IF;
ELSE
	// Manual mode: no command
	DO_Open := TRUE;
	DO_Close := FALSE;
END_IF;
// Initialize Status to -99 (no update by default)
Status := -99;
// Status feedback logic
IF DI_ZSC AND NOT DI_ZSO THEN
	Status := 1;
ELSIF DI_ZSO AND NOT DI_ZSC THEN
	Status := 2;
ELSIF DI_ZSO AND DI_ZSC THEN
	Status := 0;
ELSE
	Status := -99;
END_IF;
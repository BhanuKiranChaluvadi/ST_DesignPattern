{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_OperationType :
(
    UNKNOWN := 0,
    VALVE,
    MFC_SET,
    MFC_WAIT,
    PRESSURE_WAIT,
    TIMER_WAIT,
    LOOP
);
END_TYPE


{attribute 'strict'}
TYPE ST_OperationData :
STRUCT
    eOperation : E_OperationType;
    eValve : E_Valve; // Assuming E_Valve is defined elsewhere
    bOpen : BOOL;
    rSetPoint : REAL;
    tTimeout : TIME;
    tStabilizationTime : TIME;
    rFlowTolerance : REAL;
    bResetLoop : BOOL;
    nCurrentCycle : DINT;
    nMaxCycles : DINT;
    eLoopNextState : E_PurgeState; // Assuming E_PurgeState is defined elsewhere
    eLoopStartState : E_PurgeState;
    eNextState : E_PurgeState;
    eErrorState : E_ErrorState; // Assuming E_ErrorState is defined elsewhere
    eCategory : E_ErrorCategory; // Assuming E_ErrorCategory is defined elsewhere
    eErrorCode : E_ErrorCodes; // Assuming E_ErrorCodes is defined elsewhere
    sDescription : STRING;
    sCurrentValue : STRING;
    sExpectedValue : STRING;
    sUnit : STRING;
    bAbove: BOOL;
    rTolerance: REAL;
END_STRUCT
END_TYPE

INTERFACE I_Operation
METHOD Execute : BOOL
VAR_INPUT
    fbErrorHandler : REFERENCE TO FB_ErrorHandler;
END_VAR
    METHOD Reset : BOOL
VAR_INPUT
END_VAR
END_INTERFACE

FUNCTION_BLOCK ABSTRACT FB_BaseOperation IMPLEMENTS I_Operation
VAR
    _bDone : BOOL;
    _bError : BOOL;
    _eNextState : E_PurgeState;
END_VAR

METHOD ABSTRACT Execute : BOOL
VAR_INPUT
    fbErrorHandler : REFERENCE TO FB_ErrorHandler;
END_VAR
END_METHOD

METHOD Reset : BOOL
VAR_INPUT
END_VAR
    _bDone := FALSE;
    _bError := FALSE;
    Reset := TRUE;
END_METHOD


FUNCTION_BLOCK FB_ValveOperation EXTENDS FB_BaseOperation
VAR
    _fbValveManager: REFERENCE TO FB_ValveManager;
    _eValve : E_Valve;
    _bOpen : BOOL;
END_VAR

METHOD SetParameters : BOOL
VAR_INPUT
    fbValveManager: REFERENCE TO FB_ValveManager;
    eValve : E_Valve;
    bOpen : BOOL;
END_VAR
    _fbValveManager REF= fbValveManager;
    _eValve := eValve;
    _bOpen := bOpen;
    SetParameters := TRUE;
END_METHOD

METHOD Execute: BOOL
VAR_INPUT
    fbErrorHandler : REFERENCE TO FB_ErrorHandler;
END_VAR
VAR
    stError: ST_Error;
    stValveStatus: ST_ValveStatus;
END_VAR
    // Reset state
    _bDone := FALSE;
    _bError := FALSE;

    // Perform valve operation
    IF _bOpen THEN
        _fbValveManager.OpenValve(_eValve);
    ELSE
        _fbValveManager.CloseValve(_eValve);
    END_IF

    // Check valve status
    stValveStatus := _fbValveManager.GetValveStatus(_eValve);
    IF stValveStatus.bError THEN
        stError := stValveStatus.stError;
        fbErrorHandler.UpdateError(stError);
        _bError := TRUE;
        RETURN FALSE;
    END_IF

    // Check if valve operation is complete
    _bDone := NOT stValveStatus.bBusy;

    Execute := _bDone AND NOT _bError;
END_METHOD

INTERFACE I_OperationDecorator IMPLEMENTS I_Operation
END_INTERFACE

FUNCTION_BLOCK FB_TimeoutDecorator IMPLEMENTS I_OperationDecorator
VAR
    _operation : I_Operation;
    _tTimeout : TIME;
    _fbTimerManager : FB_TimerManager;
    _stOperationData : ST_OperationData;
END_VAR

METHOD SetParameters : BOOL
VAR_INPUT
    operation : I_Operation;
    tTimeout : TIME;
    stOperationData : ST_OperationData;
END_VAR
    _operation := operation;
    _tTimeout := tTimeout;
    _stOperationData := stOperationData;
    SetParameters := TRUE;
END_METHOD

METHOD Execute : BOOL
VAR_INPUT
    fbErrorHandler : REFERENCE TO FB_ErrorHandler;
END_VAR
VAR
    bTimedOut : BOOL;
    stError : ST_Error;
END_VAR
    // Update timers
    _fbTimerManager.Update();

    // Start operation timer if not active
    IF NOT _fbTimerManager.StartOperationTimer(_tTimeout) THEN
        _fbTimerManager.StartOperationTimer(_tTimeout);
    END_IF

    // Check for operation timeout
    IF _fbTimerManager.IsOperationTimeout() THEN
        stError.eCategory := E_ErrorCategory.Timeout; // Assuming E_ErrorCategory is defined elsewhere
        stError.eErrorCode := E_ErrorCodes.OperationTimeout; // Assuming E_ErrorCodes is defined elsewhere
        stError.sComponent := 'FB_TimeoutDecorator';
        stError.sDescription := 'Operation timeout';
        fbErrorHandler.UpdateError(stError);
        RETURN FALSE;
    END_IF

    // Execute the decorated operation
    Execute := _operation.Execute(fbErrorHandler := fbErrorHandler);
END_METHOD

METHOD Reset : BOOL
VAR_INPUT
END_VAR
    _fbTimerManager.Reset();
    Reset := TRUE;
END_METHOD


FUNCTION_BLOCK FB_StabilizationDecorator IMPLEMENTS I_OperationDecorator
VAR
    _operation : I_Operation;
    _tStabilizationTime : TIME;
    _fbTimerManager : FB_TimerManager;
    _bConditionMet : BOOL;
    _stOperationData : ST_OperationData;
END_VAR

METHOD SetParameters : BOOL
VAR_INPUT
    operation : I_Operation;
    tStabilizationTime : TIME;
    bConditionMet : BOOL;
    stOperationData : ST_OperationData;
END_VAR
    _operation := operation;
    _tStabilizationTime := tStabilizationTime;
    _bConditionMet := bConditionMet;
    _stOperationData := stOperationData;
    SetParameters := TRUE;
END_METHOD

METHOD Execute : BOOL
VAR_INPUT
    fbErrorHandler : REFERENCE TO FB_ErrorHandler;
END_VAR
VAR
    bStabilizationComplete : BOOL;
END_VAR
    // Execute the decorated operation
    IF NOT _operation.Execute(fbErrorHandler := fbErrorHandler) THEN
        Execute := FALSE;
        RETURN FALSE;
    END_IF

    // Start stabilization timer if condition met
    _fbTimerManager.StartStabilizationTimer(_tStabilizationTime, _bConditionMet);

    // Check if operation is complete
    bStabilizationComplete := _fbTimerManager.IsStabilizationComplete();
    IF bStabilizationComplete THEN
        Execute := TRUE;
    ELSE
        Execute := FALSE;
    END_IF
END_METHOD

METHOD Reset : BOOL
VAR_INPUT
END_VAR
    _fbTimerManager.Reset();
    Reset := TRUE;
END_METHOD

FUNCTION_BLOCK FB_OperationFactory
VAR
    _fbValveManager: REFERENCE TO FB_ValveManager;
    _fbValveOperation: POINTER TO FB_ValveOperation;
    _fbTimeoutDecorator : POINTER TO FB_TimeoutDecorator;
    _fbStabilizationDecorator : POINTER TO FB_StabilizationDecorator;
    _iOperation : I_Operation;
    _iTimeoutDecorator : I_OperationDecorator;
    _iStabilizationDecorator : I_OperationDecorator;
END_VAR

METHOD SetValveManager : BOOL
VAR_INPUT
    fbValveManager: REFERENCE TO FB_ValveManager;
END_VAR
    _fbValveManager REF= fbValveManager;
    SetValveManager := TRUE;
END_METHOD

METHOD CreateValveOperation : I_Operation
VAR_INPUT
    stOperationData : ST_OperationData;
    bWithTimeout : BOOL;
    bWithStabilization : BOOL;
END_VAR
    // Create Valve Operation
    _fbValveOperation := __NEW(FB_ValveOperation);
    _iOperation := _fbValveOperation^;
    _fbValveOperation^.SetParameters(
        fbValveManager := _fbValveManager,
        eValve := stOperationData.eValve,
        bOpen := stOperationData.bOpen
    );

    CreateValveOperation := _iOperation;

    IF bWithTimeout THEN
        _fbTimeoutDecorator := __NEW(FB_TimeoutDecorator);
        _iTimeoutDecorator := _fbTimeoutDecorator^;
        _fbTimeoutDecorator^.SetParameters(
            operation := CreateValveOperation,
            tTimeout := stOperationData.tTimeout,
            stOperationData := stOperationData
        );
        CreateValveOperation := _iTimeoutDecorator;
    END_IF;

    IF bWithStabilization THEN
        _fbStabilizationDecorator := __NEW(FB_StabilizationDecorator);
        _iStabilizationDecorator := _fbStabilizationDecorator^;
        _fbStabilizationDecorator^.SetParameters(
            operation := CreateValveOperation,
            tStabilizationTime := stOperationData.tStabilizationTime,
            bConditionMet := TRUE, // Set your condition here
            stOperationData := stOperationData
        );
        CreateValveOperation := _iStabilizationDecorator;
    END_IF;
END_METHOD

METHOD DeleteValveOperation : BOOL
VAR_INPUT
    bWithTimeout : BOOL;
    bWithStabilization : BOOL;
END_VAR
    IF _fbValveOperation <> 0 THEN
        __DELETE(_fbValveOperation);
        _fbValveOperation := 0;
    END_IF

    IF bWithTimeout AND _fbTimeoutDecorator <> 0 THEN
        __DELETE(_fbTimeoutDecorator);
        _fbTimeoutDecorator := 0;
    END_IF

    IF bWithStabilization AND _fbStabilizationDecorator <> 0 THEN
        __DELETE(_fbStabilizationDecorator);
        _fbStabilizationDecorator := 0;
    END_IF

    DeleteValveOperation := TRUE;
END_METHOD

INTERFACE I_OperationSequence
    METHOD AddOperation
    VAR_INPUT
        operation : I_Operation;
    END_VAR
    END_METHOD

    METHOD ExecuteAll : BOOL
    VAR_INPUT
         fbErrorHandler : REFERENCE TO FB_ErrorHandler;
    END_VAR
    END_METHOD

    METHOD ResetAll : BOOL
    END_METHOD
END_INTERFACE

FUNCTION_BLOCK FB_OperationSequence IMPLEMENTS I_OperationSequence
VAR
    _operations : ARRAY [1..10] OF I_Operation; // Assuming a max of 10 operations
    _operationCount : INT;
END_VAR

METHOD AddOperation
VAR_INPUT
    operation : I_Operation;
END_VAR
    _operationCount := _operationCount + 1;
    _operations[_operationCount] := operation;
END_METHOD

METHOD ExecuteAll : BOOL
VAR_INPUT
     fbErrorHandler : REFERENCE TO FB_ErrorHandler;
END_VAR
VAR
    i : INT;
    bResult : BOOL := TRUE;
END_VAR
    FOR i := 1 TO _operationCount DO
        IF _operations[i] <> 0 THEN
            bResult := bResult AND _operations[i].Execute(fbErrorHandler := fbErrorHandler);
        END_IF
    END_FOR
    ExecuteAll := bResult;
END_METHOD

METHOD ResetAll : BOOL
VAR
    i : INT;
END_VAR
    FOR i := 1 TO _operationCount DO
        IF _operations[i] <> 0 THEN
            _operations[i].Reset();
        END_IF
    END_FOR
    _operationCount := 0;
END_METHOD

PROGRAM MAIN
VAR
    fbOperationFactory : FB_OperationFactory;
    fbValveManager : FB_ValveManager; // Assuming FB_ValveManager is defined elsewhere
    fbOperationSequence : FB_OperationSequence;
    stOperationData1 : ST_OperationData;
    stOperationData2 : ST_OperationData;
    stOperationData3 : ST_OperationData;
    iValveOperation1 : I_Operation;
    iValveOperation2 : I_Operation;
    iValveOperation3 : I_Operation;
    bExecute : BOOL;
    bWithTimeout : BOOL := TRUE;
    bWithStabilization : BOOL := TRUE;
    fbErrorHandler : FB_ErrorHandler;
END_VAR

    // Initialize OperationFactory with ValveManager
    fbOperationFactory.SetValveManager(fbValveManager := fbValveManager);

    // Initialize operation data for Valve1
    stOperationData1.eOperation := E_OperationType.VALVE;
    stOperationData1.eValve := E_Valve.Valve1; // Assuming E_Valve.Valve1 is defined elsewhere
    stOperationData1.bOpen := TRUE;
    stOperationData1.tTimeout := T#5s;
    stOperationData1.tStabilizationTime := T#2s;

    // Create valve operation with timeout and stabilization for Valve1
    iValveOperation1 := fbOperationFactory.CreateValveOperation(
        stOperationData := stOperationData1,
        bWithTimeout := bWithTimeout,
        bWithStabilization := bWithStabilization
    );

     // Initialize operation data for Valve2
    stOperationData2.eOperation := E_OperationType.VALVE;
    stOperationData2.eValve := E_Valve.Valve2; // Assuming E_Valve.Valve2 is defined elsewhere
    stOperationData2.bOpen := FALSE;
    stOperationData2.tTimeout := T#3s;
    stOperationData2.tStabilizationTime := T#1s;

    // Create valve operation with timeout and stabilization for Valve2
    iValveOperation2 := fbOperationFactory.CreateValveOperation(
        stOperationData := stOperationData2,
        bWithTimeout := bWithTimeout,
        bWithStabilization := bWithStabilization
    );

     // Initialize operation data for Valve3
    stOperationData3.eOperation := E_OperationType.VALVE;
    stOperationData3.eValve := E_Valve.Valve3; // Assuming E_Valve.Valve3 is defined elsewhere
    stOperationData3.bOpen := TRUE;
    stOperationData3.tTimeout := T#4s;
    stOperationData3.tStabilizationTime := T#2s;

    // Create valve operation with timeout and stabilization for Valve3
    iValveOperation3 := fbOperationFactory.CreateValveOperation(
        stOperationData := stOperationData3,
        bWithTimeout := bWithTimeout,
        bWithStabilization := bWithStabilization
    );

    // Add operations to sequence
    fbOperationSequence.AddOperation(iValveOperation1);
    fbOperationSequence.AddOperation(iValveOperation2);
     fbOperationSequence.AddOperation(iValveOperation3);

    // Execute the sequence
    IF bExecute THEN
        bExecute := FALSE;
        fbOperationSequence.ExecuteAll(fbErrorHandler := fbErrorHandler);
    END_IF

    // Clean up memory
    fbOperationFactory.DeleteValveOperation(bWithTimeout := bWithTimeout ,bWithStabilization := bWithStabilization);
END_PROGRAM

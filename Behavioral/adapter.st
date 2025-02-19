{attribute 'qualified_only'}
{attribute 'strict'}
{attribute 'to_string'}
TYPE E_GasSystemType:
(
    PRECURSOR := 0,
    REACTANT := 1,
    INERT := 2
);
END_TYPE

{attribute 'qualified_only'}
{attribute 'strict'}
{attribute 'to_string'}
TYPE E_MFCState:
(
    Idle := 0,
    Running := 10,
    Error := 20
);
END_TYPE

TYPE ST_MFCConfig :
STRUCT
    fMaxFlow    : REAL;
    fMinFlow    : REAL;
    fTolerance  : REAL;
    sName       : STRING;
    sFlowUnit   : STRING := 'sccm';
END_STRUCT
END_TYPE

INTERFACE I_MFC
    METHOD SetFlow : BOOL
    VAR_INPUT
        fSetpoint : REAL;
    END_VAR
    END_METHOD

    METHOD GetFlow : REAL
    END_METHOD

    METHOD AtSetpoint : BOOL
    END_METHOD

    METHOD Stop : BOOL
    END_METHOD

    PROPERTY State : E_MFCState GET
    END_PROPERTY

    PROPERTY Error : ST_Error GET
    END_PROPERTY
END_INTERFACE

FUNCTION_BLOCK FB_MFC IMPLEMENTS I_MFC
VAR
    _config : ST_MFCConfig;
    _state : E_MFCState := E_MFCState.Idle;
    _errorHandler : FB_ErrorHandler;
    _pMFC : POINTER TO massFlowController;
END_VAR

VAR CONSTANT
    ZERO_FLOW_THRESHOLD : REAL := 0.001;
END_VAR

METHOD Initialize : BOOL
VAR_INPUT
    config: ST_MFCConfig;
    pMFC: POINTER TO massFlowController;
END_VAR
    _config := config;
    _pMFC := pMFC;
    _errorHandler := errorHandler;

    IF _pMFC = 0 THEN
        _errorHandler.RegisterError(
            eErrorCode := E_ErrorCodes.NotInitialized,
            eCategory := E_ErrorCategory.Hardware,
            sComponent := _config.sName,
            sDescription := 'MFC hardware not connected',
            sCurrentValue := '',
            sExpectedValue := '',
            sUnit := ''
        );
        _state := E_MFCState.Error;
        Initialize := FALSE;
        RETURN;
    END_IF

    Initialize := TRUE;
END_METHOD

METHOD SetFlow : BOOL
VAR_INPUT
    fSetpoint : REAL;
END_VAR
    IF _pMFC = 0 THEN
        _errorHandler.RegisterError(
            eErrorCode := E_ErrorCodes.NotInitialized,
            eCategory := E_ErrorCategory.Hardware,
            sComponent := _config.sName,
            sDescription := 'MFC hardware not connected',
            sCurrentValue := '',
            sExpectedValue := '',
            sUnit := ''
        );
        _state := E_MFCState.Error;
        SetFlow := FALSE;
        RETURN;
    END_IF

    IF fSetpoint < _config.fMinFlow OR fSetpoint > _config.fMaxFlow THEN
        _errorHandler.RegisterError(
            eErrorCode := E_ErrorCodes.FlowOutOfRange,
            eCategory := E_ErrorCategory.FlowControl,
            sComponent := _config.sName,
            sDescription := 'Flow setpoint out of range',
            sCurrentValue := REAL_TO_STRING(fSetpoint),
            sExpectedValue := CONCAT(LREAL_TO_STRING(_config.fMinFlow), CONCAT(' - ', LREAL_TO_STRING(_config.fMaxFlow))),
            sUnit := 'sccm'
        );
        _state := E_MFCState.Error;
        RETURN;
    END_IF

    _pMFC^.SetPointIn := fSetpoint;
    _state := SEL(fSetpoint = 0, E_MFCState.Running, E_MFCState.Idle);
    SetFlow := TRUE;
END_METHOD

METHOD GetFlow : REAL
    IF _pMFC <> 0 THEN
        GetFlow := _pMFC^.ProcessValue;
    END_IF
END_METHOD

METHOD AtSetpoint : BOOL
    IF _pMFC = 0 THEN
        AtSetpoint := FALSE;
        RETURN;
    END_IF

    AtSetpoint := ABS(_pMFC^.ProcessValue - _pMFC^.SetPointIn) <= (_pMFC^.SetPointIn * _config.fTolerance / 100.0);
END_METHOD

METHOD Stop : BOOL
    Stop := SetFlow(0.0);
END_METHOD

PROPERTY State : E_MFCState GET
    State := _state;
END_PROPERTY

PROPERTY Error : ST_Error GET
    Error := _errorHandler.GetError();
END_PROPERTY
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_DualMFC IMPLEMENTS I_MFC
VAR
    _highFlow: FB_MFC;
    _lowFlow: FB_MFC;
    _flowThreshold: REAL;
    _activeFlow: REFERENCE TO FB_MFC;
    _state: E_MFCState := E_MFCState.Idle;
    _errorHandler: FB_ErrorHandler;
END_VAR

METHOD Initialize : BOOL
VAR_INPUT
    highConfig: ST_MFCConfig;
    lowConfig: ST_MFCConfig;
    pHighMFC: POINTER TO massFlowController;
    pLowMFC: POINTER TO massFlowController;
    errorHandler: I_ErrorHandler;
END_VAR
    _errorHandler := errorHandler;

    IF NOT _highFlow.Initialize(highConfig, pHighMFC, _errorHandler) THEN
        _errorHandler.RegisterError(
            eErrorCode := E_ErrorCodes.MFCTimeout,
            eCategory := E_ErrorCategory.Initialization,
            sComponent := 'DualMFC-High',
            sDescription := 'Failed to initialize high flow MFC',
            sCurrentValue := '',
            sExpectedValue := '',
            sUnit := ''
        );
        _state := E_MFCState.Error;
        RETURN FALSE;
    END_IF

    IF NOT _lowFlow.Initialize(lowConfig, pLowMFC, _errorHandler) THEN
        _errorHandler.RegisterError(
            eErrorCode := E_ErrorCodes.MFCTimeout,
            eCategory := E_ErrorCategory.Initialization,
            sComponent := 'DualMFC-Low',
            sDescription := 'Failed to initialize low flow MFC',
            sCurrentValue := '',
            sExpectedValue := '',
            sUnit := ''
        );
        _state := E_MFCState.Error;
        RETURN FALSE;
    END_IF

    _flowThreshold := lowConfig.fMaxFlow;
    _activeFlow REF= _lowFlow;
    _state := E_MFCState.Idle;
    Initialize := TRUE;
END_METHOD

METHOD SetFlow : BOOL
VAR_INPUT
    fSetpoint : REAL;
END_VAR
    IF _state = E_MFCState.Error THEN
        RETURN FALSE;
    END_IF

    IF fSetpoint <= _flowThreshold THEN
        _highFlow.Stop();
        _activeFlow REF= _lowFlow;
    ELSE
        _lowFlow.Stop();
        _activeFlow REF= _highFlow;
    END_IF

    SetFlow := _activeFlow.SetFlow(fSetpoint);
    _state := _activeFlow.State;
END_METHOD

METHOD GetFlow : REAL
    GetFlow := _lowFlow.GetFlow() + _highFlow.GetFlow();
END_METHOD

METHOD Stop : BOOL
    _highFlow.Stop();
    _lowFlow.Stop();
    _state := E_MFCState.Idle;
    Stop := TRUE;
END_METHOD

METHOD AtSetpoint : BOOL
    IF _state = E_MFCState.Error THEN
        RETURN FALSE;
    END_IF

    AtSetpoint := _activeFlow.AtSetpoint();
END_METHOD

PROPERTY State : E_MFCState GET
    State := _state;
END_PROPERTY

PROPERTY Error : ST_Error GET
    IF _activeFlow.State = E_MFCState.Error THEN
        Error := _activeFlow.Error;
    ELSE
        Error := _errorHandler.GetError();
    END_IF
END_PROPERTY
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_MFCFactory
VAR CONSTANT
    PRECURSOR_HIGH_CONFIG : ST_MFCConfig := (
        fMaxFlow := 2000.0,
        fMinFlow := 400.0,
        fTolerance := 2.0,
        sName := 'Precursor High Flow',
        sFlowUnit := 'sccm'
    );

    PRECURSOR_LOW_CONFIG : ST_MFCConfig := (
        fMaxFlow := 400.0,
        fMinFlow := 0.0,
        fTolerance := 2.0,
        sName := 'Precursor Low Flow',
        sFlowUnit := 'sccm'
    );

    REACTANT_CONFIG : ST_MFCConfig := (
        fMaxFlow := 1000.0,
        fMinFlow := 0.0,
        fTolerance := 2.0,
        sName := 'Reactant Flow',
        sFlowUnit := 'sccm'
    );

    INERT_HIGH_CONFIG : ST_MFCConfig := (
        fMaxFlow := 5000.0,
        fMinFlow := 400.0,
        fTolerance := 2.0,
        sName := 'Inert High Flow',
        sFlowUnit := 'sccm'
    );

    INERT_LOW_CONFIG : ST_MFCConfig := (
        fMaxFlow := 400.0,
        fMinFlow := 0.0,
        fTolerance := 2.0,
        sName := 'Inert Low Flow',
        sFlowUnit := 'sccm'
    );
END_VAR

VAR
    _reactantMFC : FB_MFC;
    _precursorDualMFC : FB_DualMFC;
    _inertDualMFC : FB_DualMFC;
    _errorHandler : I_ErrorHandler;
    _bInitialized : BOOL := FALSE;

END_VAR

METHOD Initialize : BOOL
VAR_INPUT
    bResetError : BOOL := FALSE;
    errorHandler : I_ErrorHandler;
END_VAR
    _errorHandler := errorHandler;

    IF bResetError THEN
        _errorHandler.Reset();
    END_IF

    IF _bInitialized THEN
        Initialize := TRUE;
        RETURN;
    END_IF

    IF NOT _reactantMFC.Initialize(REACTANT_CONFIG, ADR(GVL_E02_MFC.MFC.st_MFC.ReactantMassFlowController1), _errorHandler) THEN
        _errorHandler.RegisterError(
            eErrorCode := E_ErrorCodes.MFCTimeout,
            eCategory := E_ErrorCategory.Initialization,
            sComponent := REACTANT_CONFIG.sName,
            sDescription := 'Failed to initialize reactant MFC',
            sCurrentValue := '',
            sExpectedValue := '',
            sUnit := REACTANT_CONFIG.sFlowUnit
        );
        RETURN;
    END_IF

    IF NOT _precursorDualMFC.Initialize(PRECURSOR_HIGH_CONFIG, PRECURSOR_LOW_CONFIG, ADR(GVL_E02_MFC.MFC.st_MFC.PrecursorMassFlowController1), ADR(GVL_E02_MFC.MFC.st_MFC.PrecursorMassFlowController2), _errorHandler) THEN
        _errorHandler.RegisterError(
            eErrorCode := E_ErrorCodes.MFCTimeout,
            eCategory := E_ErrorCategory.Initialization,
            sComponent := 'Precursor Dual MFC',
            sDescription := 'Failed to initialize precursor dual MFC',
            sCurrentValue := '',
            sExpectedValue := '',
            sUnit := PRECURSOR_HIGH_CONFIG.sFlowUnit
        );
        RETURN;
    END_IF

    IF NOT _inertDualMFC.Initialize(INERT_HIGH_CONFIG, INERT_LOW_CONFIG, ADR(GVL_E02_MFC.MFC.st_MFC.InertMassFlowController1), ADR(GVL_E02_MFC.MFC.st_MFC.InertMassFlowController2), _errorHandler) THEN
        _errorHandler.RegisterError(
            eErrorCode := E_ErrorCodes.MFCTimeout,
            eCategory := E_ErrorCategory.Initialization,
            sComponent := 'Inert Dual MFC',
            sDescription := 'Failed to initialize inert dual MFC',
            sCurrentValue := '',
            sExpectedValue := '',
            sUnit := INERT_HIGH_CONFIG.sFlowUnit
        );
        RETURN;
    END_IF

    _bInitialized := TRUE;
    Initialize := TRUE;
END_METHOD

METHOD GetController : REFERENCE TO I_MFC
VAR_INPUT
    eGasType : E_GasSystemType;
END_VAR
    IF NOT _bInitialized THEN
        _errorHandler.RegisterError(
            eErrorCode := E_ErrorCodes.NotInitialized,
            eCategory := E_ErrorCategory.Initialization,
            sComponent := 'MFCFactory',
            sDescription := 'Factory not initialized',
            sCurrentValue := '',
            sExpectedValue := '',
            sUnit := ''
        );
        RETURN;
    END_IF

    CASE eGasType OF
        E_GasSystemType.PRECURSOR:
            GetController REF= _precursorDualMFC;

        E_GasSystemType.REACTANT:
            GetController REF= _reactantMFC;

        E_GasSystemType.INERT:
            GetController REF= _inertDualMFC;

        ELSE
            _errorHandler.RegisterError(
                eErrorCode := E_ErrorCodes.InvalidConfiguration,
                eCategory := E_ErrorCategory.FlowControl,
                sComponent := 'MFCFactory',
                sDescription := 'Invalid gas system type',
                sCurrentValue := TO_STRING(eGasType),
                sExpectedValue := 'PRECURSOR, REACTANT, or INERT',
                sUnit := ''
            );
    END_CASE
END_METHOD

PROPERTY Error : ST_Error GET
    Error := _errorHandler.GetError();
END_PROPERTY
END_FUNCTION_BLOCK

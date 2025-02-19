INTERFACE I_EtherCATDevice
    METHOD IsDeviceOK : BOOL
END_INTERFACE

{attribute 'enable_dynamic_creation'}
FUNCTION_BLOCK EtherCATDevice IMPLEMENTS I_EtherCATDevice
    METHOD IsDeviceOK : BOOL
        IsDeviceOK := true;
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK EtherCATFactory
    METHOD PUBLIC CreateEtherCATDevice : I_EtherCATDevice
        VAR
            devicePtr: POINTER TO EtherCATDevice;
        END_VAR
        devicePtr := __NEW(EtherCATDevice);
        CreateEtherCATDevice := devicePtr^;
    END_METHOD
END_FUNCTION_BLOCK


PROGRAM MAIN
VAR
	EtherCATIOFactory : EtherCATFactory;
	GetEtherCATDevice: BOOL;
	myDevcie : I_EtherCATDevice;
	CheckMyDevice: BOOL;
	value: BOOL;
END_VAR
    IF GetEtherCATDevice THEN
        GetEtherCATDevice := FALSE;
        myDevcie := EtherCATIOFactory.CreateEtherCATDevice();
    END_IF

    IF CheckMyDevice THEN
        CheckMyDevice := false;
        value := myDevcie.IsDeviceOK();
    END_IF
END_PROGRAM

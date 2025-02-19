INTERFACE ITF_Cyclic EXTENDS __SYSTEM.IQueryInterface
    METHOD Cycle() : BOOL;
END_INTERFACE

{attribute 'enable_dynamic_creation'}
FUNCTION_BLOCK BasicObject IMPLEMENTS ITF_Cyclic
    METHOD Cycle : BOOL
END_FUNCTION_BLOCK

INTERFACE ITF_Mover
    PROPERTY VELOCITY : LREAL GET SET
END_INTERFACE

INTERFACE ITF_Station
    PROPERTY Position : LREAL GET SET
END_INTERFACE

INTERFACE ITF_Track
    PROPERTY Length : LREAL GET SET
END_INTERFACE

{attribute 'enable_dynamic_creation'}
FUNCTION_BLOCK Mover IMPLEMENTS ITF_Cyclic, ITF_Mover
VAR
	myMaxVelo : LREAL;
END_VAR
    {warning 'add method implementation '}
    METHOD Cycle : BOOL 
    END_METHOD

    PROPERTY Velocity : LREAL GET
        Velocity := myMaxVelo;
    END_PROPERTY

    PROPERTY Velocity : LREAL SET
        myMaxVelo := Velocity;
    END_PROPERTY
END_FUNCTION_BLOCK

{attribute 'enable_dynamic_creation'}
FUNCTION_BLOCK Station IMPLEMENTS ITF_Cyclic, ITF_Station
VAR
	MyTrackPosition : LREAL;
END_VAR
    {warning 'add method implementation '}
    METHOD Cycle : BOOL 
    END_METHOD

    PROPERTY Position : LREAL GET
        Position := MyTrackPosition;
    END_PROPERTY

    PROPERTY Position : LREAL SET
        MyTrackPosition := Position;
    END_PROPERTY
END_FUNCTION_BLOCK

{attribute 'enable_dynamic_creation'}
FUNCTION_BLOCK Track IMPLEMENTS ITF_Cyclic, ITF_Track
VAR
	MyTrackLength : LREAL;
END_VAR
    {warning 'add method implementation '}
    METHOD Cycle : BOOL 
    END_METHOD

    PROPERTY Length : LREAL GET
        Length := MyTrackLength;
    END_PROPERTY

    PROPERTY Length : LREAL SET
        MyTrackLength := Length;
    END_PROPERTY
END_FUNCTION_BLOCK

INTERFACE ITF_Factory
    METHOD Create : ITF_Cyclic
END_INTERFACE

FUNCTION_BLOCK Factory IMPLEMENTS ITF_Factory
VAR
	ObjPtr : POINTER TO BasicObject;
END_VAR
    METHOD Create : ITF_Cyclic
        ObjPtr := __NEW(BasicObject);
        Create := ObjPtr^;
    END_METHOD
END_FUNCTION_BLOCK


FUNCTION_BLOCK MoverFactory EXTENDS Factory
VAR
	ptrMover : POINTER TO Mover;
	itfMover : ITF_Mover;
END_VAR
    METHOD Create : ITF_Cyclic
        PtrMover := __NEW(Mover);
        Create := ptrMover^;
        IF __QUERYINTERFACE(Create,itfMover) THEN
            itfMover.Velocity := 4000.0;
        END_IF
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK StationFactory EXTENDS Factory
VAR
	prtStation : POINTER TO Station;
	itfStation : ITF_Station;
END_VAR
    METHOD Create : ITF_Cyclic
        prtStation := __NEW(Station);
        Create := prtStation^;
        IF __QUERYINTERFACE(Create,itfStation) THEN
            itfStation.Position := 1250.0;
        END_IF
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK TrackFactory EXTENDS Factory
VAR
	ptrTrack : POINTER TO Track;
	itfTrack : ITF_Track;
END_VAR
    METHOD Create : ITF_Cyclic
        ptrTrack := __NEW(Track);
        Create := ptrTrack^;
        IF __QUERYINTERFACE(Create,itfTrack) THEN
            itfTrack.Length := 2500.0;
        END_IF
    END_METHOD
END_FUNCTION_BLOCK


PROGRAM MAIN
VAR
	State: INT;
	XtsMoverFactory : MoverFactory;
	XtsStationFactory : StationFactory;
	XtsTrackFactory : TrackFactory;
	iFactory : ITF_Factory := XtsMoverFactory;
	XtsElements : ARRAY[0..8] OF ITF_Cyclic;
	
	iMover : ITF_Mover;
	MaxVelo : LREAL;
	xTest: BOOL;
END_VAR
    CASE State OF
	0:
		IF Initialise() THEN
			State := 1;
		END_IF
    END_CASE

    IF xTest THEN
        xTest := FALSE;
        IF __QUERYINTERFACE(XtsElements[1],iMover) THEN
            MaxVelo := iMover.Velocity;
        END_IF
    END_IF

    METHOD Initialise : BOOL
    VAR
        i: INT;
    END_VAR
        FOR i := 0 TO 2 DO
            XtsElements[i] := iFactory.Create();
        END_FOR
        iFactory := XtsStationFactory;
        FOR i := 3 TO 5 DO
            XtsElements[i] := iFactory.Create();
        END_FOR
        iFactory := XtsTrackFactory;
        FOR i := 6 TO 8 DO
            XtsElements[i] := iFactory.Create();
        END_FOR
        Initialise := TRUE;
    END_METHOD
END_PROGRAM

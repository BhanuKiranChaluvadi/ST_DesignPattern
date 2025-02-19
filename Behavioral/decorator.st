INTERFACE I_Shape
    METHOD M_Draw: BOOL
    END_METHOD
END_INTERFACE

FUNCTION_BLOCK FB_Circle IMPLEMENTS I_Shape
    METHOD M_Draw: BOOL
        ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Draw circle', '');
        M_Draw := TRUE;
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_Square IMPLEMENTS I_Shape
    METHOD M_Draw: BOOL
        ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Draw Square', '');
        M_Draw := TRUE;
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK ABSTRACT FB_ShapeDecorator IMPLEMENTS I_Shape
VAR
	_iDecoratedShape: I_Shape;
END_VAR
    METHOD FB_init: BOOL
    VAR_INPUT
        bInitRetains: BOOL; // if TRUE, the retain variables are initialized (warm start / cold start)
        bInCopyCode: BOOL; // if TRUE, the instance afterwards gets moved into the copy code (online change)
        iDecoratedShape: I_Shape;
    END_VAR
        _iDecoratedShape := iDecoratedShape;
    END_METHOD

    METHOD ABSTRACT M_Draw: BOOL
    END_METHOD
END_FUNCTION_BLOCK

{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_BorderDashType:
(
	Solid := 0,
	RoundDot,
	SquareDot,
	Dash,
	LongDashDot
);
END_TYPE


FUNCTION_BLOCK FB_BorderDashTypeDecorator EXTENDS FB_ShapeDecorator
VAR
	_eBorderDashType: E_BorderDashType;
END_VAR
    METHOD FB_init: BOOL
    VAR_INPUT
        bInitRetains: BOOL; // if TRUE, the retain variables are initialized (warm start / cold start)
        bInCopyCode: BOOL; // if TRUE, the instance afterwards gets moved into the copy code (online change)
        iDecoratedShape: I_Shape;
        eBorderDashType: E_BorderDashType;
    END_VAR
        SUPER^._iDecoratedShape := iDecoratedShape;
        _eBorderDashType := eBorderDashType;
    END_METHOD


    METHOD M_Draw: BOOL
        M_Draw := SUPER^._iDecoratedShape.M_Draw();
        M_SetBorderDashType(SUPER^._iDecoratedShape);
    END_METHOD

    METHOD M_SetBorderDashType
    VAR_INPUT
        iDecoratedShape: I_Shape;
    END_VAR
        CASE _eBorderDashType OF
            E_BorderDashType.Solid:
                ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Border Dash Type: Solid', '');

            E_BorderDashType.SquareDot:
                ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Border Dash Type: Square Dot', '');

            E_BorderDashType.RoundDot:
                ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Border Dash Type: Round Dot', '');

            E_BorderDashType.Dash:
                ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Border Dash Type: Dash', '');

            E_BorderDashType.LongDashDot:
                ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Border Dash Type:Long Dash Dot', '');

        ELSE
            ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Border Dash Type:Unkown', '');
        END_CASE
    END_METHOD

    PROPERTY P_GS_BorderDashType: E_BorderDashType
        GET:
            P_GS_BorderDashType := _eBorderDashType;
        SET:
            _eBorderDashType := P_GS_BorderDashType;
    END_PROPERTY
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_GreenShapeDecorator EXTENDS FB_ShapeDecorator
    METHOD FB_init: BOOL
    VAR_INPUT
        bInitRetains: BOOL; // if TRUE, the retain variables are initialized (warm start / cold start)
        bInCopyCode: BOOL; // if TRUE, the instance afterwards gets moved into the copy code (online change)
        iDecoratedShape: I_Shape;
    END_VAR
        SUPER^._iDecoratedShape := iDecoratedShape;
    END_METHOD

    METHOD M_Draw: BOOL
        M_Draw := SUPER^._iDecoratedShape.M_Draw();
        M_SetGreenBorder(SUPER^._iDecoratedShape);
    END_METHOD

    METHOD PRIVATE M_SetGreenBorder
    VAR_INPUT
        iDecoratedShape: I_Shape;
    END_VAR
        ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Border Color: Green', '');
    END_METHOD
END_FUNCTION_BLOCK

PROGRAM MAIN
VAR
	fbCircle: FB_Circle;
	fbGreenCircle: FB_GreenShapeDecorator(fbCircle);
	fbRoundDotBorderGreenCircle: FB_BorderDashTypeDecorator(fbGreenCircle, E_BorderDashType.RoundDot);

	fbSquare: FB_Square;
	fbGreenSquare: FB_GreenShapeDecorator(fbSquare);
	fbDashBorderGreenSquare: FB_BorderDashTypeDecorator(fbGreenSquare, E_BorderDashType.Dash);

	bDemoStart: BOOL;
END_VAR
    IF bDemoStart THEN

        bDemoStart := FALSE;

        fbRoundDotBorderGreenCircle.M_Draw();

        fbDashBorderGreenSquare.M_Draw();

    END_IF
END_PROGRAM

{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_Color:
(
	init := 0,
	Black ,
	Red,
	Yellow,
	end
);
END_TYPE

{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_Shape:
(
	init := 0,
	Circle,
	Rectangle,
	Sqaure,
	Star,
	Triangle,
	end,
	Custom
);
END_TYPE

{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_Factory:
(
	init := 0,
	Shape,
	Color,
	end
);
END_TYPE

INTERFACE I_Color
    METHOD M_Fill: BOOL
    END_METHOD
END_INTERFACE

INTERFACE I_Shape
    METHOD M_Draw: BOOL
    END_METHOD
END_INTERFACE


FUNCTION_BLOCK FB_Black IMPLEMENTS I_Color
    METHOD M_Fill: BOOL
        ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Paint Black', '');
        M_Fill := TRUE;
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_Red IMPLEMENTS I_Color
    METHOD M_Fill: BOOL
        ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Paint Red', '');
        M_Fill := TRUE;
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_Yellow IMPLEMENTS I_Color
    METHOD M_Fill: BOOL
        ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Paint Yellow', '');
        M_Fill := TRUE;
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_Circle IMPLEMENTS I_Shape
    METHOD M_Draw: BOOL
        ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Draw circle', '');
        M_Draw := TRUE;
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_Rectangle IMPLEMENTS I_Shape
    METHOD M_Draw: BOOL
            ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Draw rectangle', '');
            M_Draw := TRUE;
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_Sqaure IMPLEMENTS I_Shape
    METHOD M_Draw: BOOL
        ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Draw square', '');
        M_Draw := TRUE;
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_Star IMPLEMENTS I_Shape
    METHOD M_Draw: BOOL
        ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Draw star', '');
        M_Draw := TRUE;
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_Triangle IMPLEMENTS I_Shape
    METHOD M_Draw: BOOL
        ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Draw triangle', '');
        M_Draw := TRUE;
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK ABSTRACT FB_AbstractFactory
    METHOD M_GetColorObject: I_Color
    VAR_INPUT
        eColor: E_Color;
    END_VAR
    END_METHOD

    METHOD M_GetShapeObject: I_Shape
    VAR_INPUT
        eShape: E_Shape;
    END_VAR
    END_METHOD

    METHOD ABSTRACT M_ReleaseMemory: BOOL
    END_METHOD
END_FUNCTION_BLOCK

{attribute 'hide_all_locals'}
{attribute 'enable_dynamic_creation'}
FUNCTION_BLOCK FB_ColorCreator EXTENDS FB_AbstractFactory
    VAR
        pBlack: POINTER TO FB_Black;
        pRed: POINTER TO FB_Red;
        pCircle: POINTER TO FB_Circle;
        iColor: I_Color;
    END_VAR
    METHOD M_GetColorObject: I_Color
    VAR_INPUT
        eColor: E_Color;
    END_VAR
        CASE eColor OF:
            Black:

                // Dynamic instantiation
                pBlack := __NEW(FB_Black);
                iColor := pBlack^;

                // Return the object
                IF iColor <> 0 THEN
                    M_GetColorObject := iColor;
                END_IF

                eColor := E_Color.init;

            Red:

                // Dynamic instantiation
                pRed := __NEW(FB_Red);
                iColor := pRed^;

                // Return the object
                IF iColor <> 0 THEN
                    M_GetColorObject := iColor;
                END_IF

                eColor := E_Color.init;

            Yellow:

                // Dynamic instantiation
                pYellow := __NEW(FB_Yellow);
                iColor := pYellow^;

                // Return the object
                IF iColor <> 0 THEN
                    M_GetColorObject := iColor;
                END_IF

                eColor := E_Color.init;
        END_CASE
    END_METHOD

    METHOD M_ReleaseMemory
        // Release the memory
        IF (pBlack <> 0) THEN
            __DELETE(pBlack);
            pBlack := 0;
        END_IF

        // Release the memory
        IF (pRed <> 0) THEN
            __DELETE(pRed);
            pRed := 0;
        END_IF

        // Release the memory
        IF (pYellow <> 0) THEN
            __DELETE(pYellow);
            pYellow := 0;
        END_IF
    END_METHOD

    METHOD FB_exit
        M_ReleaseMemory();
    END_METHOD
END_FUNCTION_BLOCK

{attribute 'hide_all_locals'}
{attribute 'enable_dynamic_creation'}
FUNCTION_BLOCK FB_ShapeCreator EXTENDS FB_AbstractFactory
VAR
      pCircle: POINTER TO FB_Circle;
      pRectangle: POINTER TO FB_Rectangle;
      pSquare: POINTER TO FB_Square;
      pStar: POINTER TO FB_Star;
      pTriangle: POINTER TO FB_Triangle;
      iShape: I_Shape;
END_VAR

    METHOD M_GetShapeObject: I_shape
    VAR_INPUT
        eShape: E_Shape;
    END_VAR
        CASE eShape OF
            E_Shape.Circle:

                // Dynamic instantiation
                pCircle := __NEW(FB_Circle);
                iShape := pCircle^;

                // Return the object
                IF iShape <> 0 THEN
                    M_GetShapeObject := iShape;
                END_IF

                // Release the memory
                IF (pCircle <> 0) THEN
                    __DELETE(pCircle);
                    pCircle := 0;
                END_IF

                eShape := E_Shape.init;

            E_Shape.Rectangle:
                pRectangle := __NEW(FB_Rectangle);
                iShape := pRectangle^;

                // Return the object
                IF iShape <> 0 THEN
                    M_GetShapeObject := iShape;
                END_IF

                IF (pRectangle <> 0) THEN
                    __DELETE(pRectangle);
                    pRectangle := 0;
                END_IF

                eShape := E_Shape.init;

            E_Shape.Sqaure:
                pSquare := __NEW(FB_Square);
                iShape := pSquare^;

                // Return the object
                IF iShape <> 0 THEN
                    M_GetShapeObject := iShape;
                END_IF

                IF (pSquare <> 0) THEN
                    __DELETE(pSquare);
                    pSquare := 0;
                END_IF

                eShape := E_Shape.init;

            E_Shape.Star:
                pStar := __NEW(FB_Star);
                iShape := pStar^;

                // Return the object
                IF iShape <> 0 THEN
                    M_GetShapeObject := iShape;
                END_IF

                IF (pStar <> 0) THEN
                    __DELETE(pStar);
                    pStar := 0;
                END_IF

                eShape := E_Shape.init;

            E_Shape.Triangle:
                pTriangle := __NEW(FB_Triangle);
                iShape := pTriangle^;

                // Return the object
                IF iShape <> 0 THEN
                    M_GetShapeObject := iShape;
                END_IF

                IF (pTriangle <> 0) THEN
                    __DELETE(pTriangle);
                    pTriangle := 0;
                END_IF

                eShape := E_Shape.init;
        END_CASE
    END_METHOD

    METHOD M_ReleaseMemory: BOOL
    VAR_INPUT
    END_VAR
        IF (pCircle <> 0) THEN
            __DELETE(pCircle);
            pCircle := 0;
        END_IF

        IF (pRectangle <> 0) THEN
            __DELETE(pRectangle);
            pRectangle := 0;
        END_IF

        IF (pSquare <> 0) THEN
            __DELETE(pSquare);
            pSquare := 0;
        END_IF

        IF (pStar <> 0) THEN
            __DELETE(pStar);
            pStar := 0;
        END_IF

        IF (pTriangle <> 0) THEN
            __DELETE(pTriangle);
            pTriangle := 0;
        END_IF
    END_METHOD

    METHOD FB_exit: BOOL
    VAR_INPUT
        bInCopyCode: BOOL; // if TRUE, the exit method is called for exiting an instance that is copied afterwards (online change).
    END_VAR
        M_ReleaseMemory();
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_ShapeCreatorEX EXTENDS FB_ShapeCreator
VAR
	pCustomShape: POINTER TO FB_CustomShape;
END_VAR
    METHOD M_GetShapeObject: I_shape
        IF eShape = E_Shape.Custom THEN

            // Dynamic instantiation
            pCustomShape := __NEW(FB_CustomShape);
            iShape := pCustomShape^;

            // Return the object
            IF iShape <> 0 THEN
                M_GetShapeObject := iShape;
            END_IF

            // Release the memory
            IF (pCustomShape <> 0) THEN
                __DELETE(pCustomShape);
                pCustomShape := 0;
            END_IF

            eShape := E_Shape.init;
        ELSE
            M_GetShapeObject := SUPER^.M_GetShapeObject(eShape);
        END_IF
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_FactoryProducer
VAR
    pColorFactory: POINTER TO FB_ColorCreator;
    pShapeFactory: POINTER TO FB_ShapeCreator;
END_VAR
    METHOD M_GetFactory: REFERENCE TO FB_AbstractFactory
    VAR_INPUT
        eFactory: E_Factory;
    END_VAR
        CASE eFactory OF
            E_Factory.Color:

                pColorFactory := __NEW(FB_ColorCreator);
                IF pColorFactory <> 0 THEN
                    M_GetFactory REF= (pColorFactoy^);
                END_IF

                eFactory := E_Factory.init;

            E_Factory.Shape:

                pShapeFactory := __NEW(FB_ShapeCreator);
                IF pShapeFactory <> 0 THEN
                    M_GetFactory REF = (pShapeFactory^);
                END_IF

                eFactory := E_Factory.init;
        END_CASE
    END_METHOD

    METHOD M_ReleaseMemory: BOOL
        IF pColorFactoy <> 0 THEN
            __DELETE(pColorFactoy);
            pColorFactoy := 0;
        END_IF

        IF pShapeFactory <> 0 THEN
            __DELETE(pShapeFactory);
            pShapeFactory := 0;
        END_IF
    END_METHOD

    METHOD FB_exit: BOOL
    VAR_INPUT
        bInCopyCode: BOOL; // if TRUE, the exit method is called for exiting an instance that is copied afterwards (online change).
    END_VAR
        M_ReleaseMemory();
    END_METHOD
END_FUNCTION_BLOCK

PROGRAM MAIN
VAR
    fbFactoryProducer: FB_FactoryProducer;
    fbFactory: REFERENCE TO FB_AbstractFactory;

    iShape: I_Shape;
    iColor: I_Color;

    eShape: E_Shape := E_Shape.Star;
    eColor: E_Color := E_Color.Red;

    bStart1: BOOL;
    bStart2: BOOL;
END_VAR

IF bStart1 THEN
    // Draw
    fbFactory REF = fbFactoryProducer.M_GetFactory(eFactory := E_Factory.Shape);

    IF __ISVALIDREF(fbFactory) THEN
        iShape := fbFactory.M_GetShapeObject(eShape := eShape);
    END_IF

    IF iShape <> 0 THEN
		iShape.M_Draw();
	END_IF

    // Fill
    fbFactory REF = fbFactoryProducer.M_GetFactory(eFactory := E_Factory.Color);

    IF __ISVALIDREF(fbFactory) THEN
        iColor := fbFactory.M_GetColorObject(eColor := eColor);
    END_IF

    IF iColor <> 0 THEN
		iColor.M_Fill();
	END_IF

    // Release Memory
    fbFactoryProducer.M_ReleaseMemory();

    bStart1 := FALSE;
END_IF
// Alternatively, you can chain the methods and get the same result:
IF bStart2 THEN
	fbFactoryProducer.M_GetFactory(eFactory := E_Factory.Shape).M_GetShapeObject(eShape := eShape).M_Draw();
	fbFactoryProducer.M_GetFactory(eFactory := E_Factory.Color).M_GetColorObject(eColor := eColor).M_Fill();

	// Release Memory
	fbFactoryProducer.M_ReleaseMemory();
	bStart2 := FALSE;
END_IF
END_PROGRAM

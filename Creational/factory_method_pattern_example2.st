{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_Shape :
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

INTERFACE I_Shape
    METHOD M_Draw : BOOL 
    END_METHOD
END_INTERFACE

{attribute 'enable_dynamic_creation'}
FUNCTION_BLOCK FB_Circle IMPLEMENTS I_Shape
    METHOD M_Draw : BOOL
        ADSLOGSTR(ADSLOG_MSGTYPE_HINT, 'Draw circle', '');
        M_Draw := TRUE;
    END_METHOD
END_FUNCTION_BLOCK


{attribute 'hide_all_locals'}
FUNCTION_BLOCK FB_ShapeCreator
VAR_INPUT
	eShape : E_Shape;
END_VAR
VAR
      pCircle    : POINTER TO FB_Circle;
      pRectangle : POINTER TO FB_Rectangle;
      pSquare    : POINTER TO FB_Square;
      pStar      : POINTER TO FB_Star;
      pTriangle  : POINTER TO FB_Triangle;
      iShape 	 : I_Shape;
END_VAR
    METHOD M_GetShapeObject : I_shape
        CASE eShape OF
            E_Shape.Circle:
                
                //Dynamic instantiation  
                pCircle := __NEW(FB_Circle);
                iShape := pCircle^;
                
                //Return the object
                IF iShape <> 0 THEN
                    M_GetShapeObject := iShape;
                END_IF
                
                //Release the memory
                IF (pCircle <> 0) THEN
                    __DELETE(pCircle);
                    pCircle := 0;
                END_IF
                
                eShape := E_Shape.init;
            
            E_Shape.Rectangle:
                pRectangle := __NEW(FB_Rectangle);
                iShape := pRectangle^;
                
                //Return the object
                IF iShape <> 0 THEN
                    M_GetShapeObject := iShape;
                END_IF
                
                IF (pRectangle <> 0) THEN
                    __DELETE(pRectangle);
                    pRectangle := 0;
                END_IF
                
                eShape := E_Shape.init;	
            // TODO: others
        END_CASE
    END_METHOD

    METHOD M_ReleaseMemory : BOOL
    END_METHOD
    METHOD FB_exit : BOOL
    END_METHOD
END_FUNCTION_BLOCK

PROGRAM MAIN
VAR
	//fbShapeCreator : FB_ShapeCreator;
	fbShapeCreator : FB_ShapeCreatorEX;
	eShape : E_Shape := E_Shape.init;
	
	iShape : I_Shape;
END_VAR

    fbShapeCreator(eShape:= eShape);
    CASE eShape OF
        E_Shape.Circle:
            iShape := fbShapeCreator.M_GetShapeObject();
            IF iShape <> 0 THEN
                iShape.M_Draw();
            END_IF	
        
            eShape := E_Shape.Rectangle;
        
        E_Shape.Rectangle:
            iShape := fbShapeCreator.M_GetShapeObject();
            IF iShape <> 0 THEN
                iShape.M_Draw();
            END_IF
            
            eShape := E_Shape.Sqaure;
        // TODO: Complete rest
    END_CASE
END_PROGRAM

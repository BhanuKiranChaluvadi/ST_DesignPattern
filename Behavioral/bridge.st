FUNCTION_BLOCK ABSTRACT FB_Shape
VAR
	_color : ITF_color;
END_VAR
    METHOD FB_init : BOOL
    VAR_INPUT
        bInitRetains : BOOL; // if TRUE, the retain variables are initialized (warm start / cold start)
        bInCopyCode : BOOL;  // if TRUE, the instance afterwards gets moved into the copy code (online change)
        Color : ITF_Color;
    END_VAR
        THIS^._color := Color;
    END_METHOD

    METHOD ABSTRACT Draw : STRING
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_Square EXTENDS FB_Shape
    METHOD Draw : STRING
        ADSLOGSTR(    msgCtrlMask:=ADSLOG_MSGTYPE_LOG,
              msgFmtStr:='Drawing a %s square',
              strArg:= SUPER^._color.applyColor());
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_Circle EXTENDS FB_Shape
    METHOD Draw : STRING
        ADSLOGSTR(    msgCtrlMask:=ADSLOG_MSGTYPE_LOG,
              msgFmtStr:='Drawing a %s circle',
              strArg:= SUPER^._color.applyColor());
    END_METHOD
END_FUNCTION_BLOCK


INTERFACE ITF_Color
    METHOD applyColor : STRING
    END_METHOD
END_INTERFACE

FUNCTION_BLOCK FB_BlueColor IMPLEMENTS ITF_Color
    METHOD applyColor : STRING
        applyColor := 'blue';
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_RedColor IMPLEMENTS ITF_Color
    METHOD applyColor : STRING
        applyColor := 'red';
    END_METHOD
END_FUNCTION_BLOCK


PROGRAM MAIN
VAR
	
     fbRedColor 		: FB_RedColor;
	 fbBlueColor 		: FB_BlueColor;
	 
	 fbSquareRed 		: FB_Square(Color:= fbRedColor );
	 fbSquareBlue 		: FB_Square(Color:= fbBlueColor );
	 
	 fbCircleRed 		: FB_Circle(Color:= fbRedColor );
	 fbCircleBlue 		: FB_Circle(Color:= fbBlueColor );
	 
	 bstartDemo1		: BOOL;
	 
END_VAR
    IF bstartDemo1 THEN
        bstartDemo1 := FALSE;
        
        fbSquareRed.Draw();
        fbSquareBlue.Draw();
        
        fbCircleRed.Draw();
        fbCircleBlue.Draw();
        
    END_IF
END_PROGRAM

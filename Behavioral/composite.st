INTERFACE I_Component
    METHOD AddChild
    VAR_INPUT
        Child : I_Component;
    END_VAR
    END_METHOD

    METHOD GetChildren : ARRAY [1..Param.NumberOfChildren] OF I_Component;
    END_METHOD

    PROPERTY GetSize : INT GET
    END_PROPERTY
END_INTERFACE


FUNCTION_BLOCK ABSTRACT Component IMPLEMENTS I_component
VAR
	_name : STRING;
END_VAR
    METHOD FB_init : BOOL
    VAR_INPUT
        bInitRetains : BOOL; // if TRUE, the retain variables are initialized (warm start / cold start)
        bInCopyCode : BOOL;  // if TRUE, the instance afterwards gets moved into the copy code (online change)
        name : STRING;
    END_VAR
    THIS^._name := name;
    END_METHOD

    METHOD ABSTRACT AddChild
    VAR_INPUT
        Child : I_Component;
    END_VAR
    END_METHOD

    METHOD ABSTRACT GetChildren : ARRAY [1..Param.NumberOfChildren] OF I_Component;
    END_METHOD

    PROPERTY ABSTRACT GetSize : INT GET
    END_PROPERTY

    PROPERTY Name : STRING GET
        Name := THIS^._name;
    END_PROPERTY
END_FUNCTION_BLOCK


FUNCTION_BLOCK Archive EXTENDS Component
VAR
//	_name : STRING;
	_size : INT;
END_VAR
    METHOD FB_init : BOOL
    VAR_INPUT
        bInitRetains : BOOL; // if TRUE, the retain variables are initialized (warm start / cold start)
        bInCopyCode : BOOL;  // if TRUE, the instance afterwards gets moved into the copy code (online change)
        name : STRING;
        iSize : INT;
    END_VAR
        THIS^._name := name;
        THIS^._size := iSize
    END_METHOD

    METHOD AddChild
    VAR_INPUT
        Child : I_Component;
    END_VAR
    END_METHOD

    METHOD GetChildren : ARRAY [1..Param.NumberOfChildren] OF I_Component;
    VAR_INPUT
    END_VAR
    END_METHOD

    PROPERTY GetSize : INT GET
        GetSize := _size;
    END_PROPERTY
END_FUNCTION_BLOCK


FUNCTION_BLOCK Directory EXTENDS Component
VAR
	children 			: ARRAY [1..Param.NumberOfChildren] OF I_Component;
	childCount			: INT := 0;
END_VAR
    METHOD AddChild
    VAR_INPUT
        Child : I_Component;
    END_VAR
    VAR
        i: INT;
    END_VAR
        childCount := childCount + 1;
        children[childCount] := Child;
    END_METHOD

    METHOD GetChildren : ARRAY [1..Param.NumberOfChildren] OF I_Component;
        GetChildren := children;
    END_METHOD

    PROPERTY GetSize : INT
    VAR
        i : INT := 0;
    END_VAR
        FOR i := 1 TO childCount  DO	
            GetSize := GetSize + children[i].GetSize;
        END_FOR
    END_PROPERTY

    METHOD ResetSize
        childCount:= 0;
    END_METHOD
END_FUNCTION_BLOCK

PROGRAM MAIN
VAR
	root 		: Directory('root');
	
	archive1	: Archive('archivo1.txt', 10);			    
    archive2  	: Archive('archivo2.txt', 30);
    archive3 	: Archive('archivo3.txt', 120);
    archive4 	: Archive('archivo4.txt', 800);
    archive5 	: Archive('archivo5.txt', 340);

    archive6 	: Archive('archivo6.txt', 122);
    archive7 	: Archive('archivo7.txt', 391);

    dir1 		: Directory('dir1');
    dir2 		: Directory('dir2');
    dir3 		: Directory('dir3');

	bExecute	: BOOL;	
	sMsg 		: STRING;
END_VAR
    IF bExecute THEN
	
        bExecute := FALSE;
        
        dir1.ResetSize();
        dir2.ResetSize();
        dir3.ResetSize();
        root.ResetSize();
    
        dir1.AddChild(archive1); // 10
        dir1.AddChild(archive6); // 122
        dir2.AddChild(archive2); // 30
        dir3.AddChild(archive3); // 120
        dir3.AddChild(archive4); // 800
        dir1.AddChild(dir3); // 120+800

        root.AddChild(dir1); // dir1 = 120+800+10+122 = 1052
        root.AddChild(dir2); // dir2 = 30
        root.AddChild(archive5); // 340
        root.AddChild(archive7); // 391
        
        // root = 1052+30+340+391 = 1813
        sMsg := CONCAT(STR1:= root.Name , STR2:= CONCAT(STR1:= ' is: ' , STR2:= TO_STRING(root.GetSize) ) );
        ADSLOGSTR(msgCtrlMask:= ADSLOG_MSGTYPE_LOG, msgFmtStr:= 'The size of the directory %s ' , strArg:= sMsg);
        
        // dir1 = 10+122+120+800 = 1052
        sMsg := CONCAT(STR1:= dir1.Name , STR2:= CONCAT(STR1:= ' is: ' , STR2:= TO_STRING(dir1.GetSize) ) );
        ADSLOGSTR(msgCtrlMask:= ADSLOG_MSGTYPE_LOG, msgFmtStr:= 'The size of the directory %s ' , strArg:= sMsg);
        
        // dir2 = 30
        sMsg := CONCAT(STR1:= dir2.Name , STR2:= CONCAT(STR1:= ' is: ' , STR2:= TO_STRING(dir2.GetSize) ) );
        ADSLOGSTR(msgCtrlMask:= ADSLOG_MSGTYPE_LOG, msgFmtStr:= 'The size of the directory %s ' , strArg:= sMsg);
        
        // dir3 = 120+800 = 922
        sMsg := CONCAT(STR1:= dir3.Name , STR2:= CONCAT(STR1:= ' is: ' , STR2:= TO_STRING(dir3.GetSize) ) );
        ADSLOGSTR(msgCtrlMask:= ADSLOG_MSGTYPE_LOG, msgFmtStr:= 'The size of the directory %s ' , strArg:= sMsg);	
    END_IF
END_PROGRAM

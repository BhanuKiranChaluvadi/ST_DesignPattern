INTERFACE ITF_Writer
    METHOD WriteMessage : BOOL
    VAR_INPUT
        SomeString : STRING(80);
    END_VAR
    END_METHOD
END_INTERFACE

FUNCTION_BLOCK CSVWriter IMPLEMENTS ITF_Writer
    METHOD WriteMessage : BOOL
    VAR_INPUT
        SomeString	: STRING(80);
    END_VAR
        ADSLOGSTR(msgCtrlMask := ADSLOG_MSGTYPE_LOG, msgFmtStr := 'I wrote a CSV line with: %s',strArg := SomeString);
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK JsonWriter IMPLEMENTS ITF_Writer
    METHOD WriteMessage : BOOL
    VAR_INPUT
        SomeString	: STRING(80);
    END_VAR
        ADSLOGSTR(msgCtrlMask := ADSLOG_MSGTYPE_LOG, msgFmtStr := 'I wrote a JSON line with: %s',strArg := SomeString);
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK TextWriter IMPLEMENTS ITF_Writer
    METHOD WriteMessage : BOOL
    VAR_INPUT
        SomeString	: STRING(80);
    END_VAR
        ADSLOGSTR(msgCtrlMask := ADSLOG_MSGTYPE_LOG, msgFmtStr := 'I wrote a Text line with: %s',strArg := SomeString);
    END_METHOD
END_FUNCTION_BLOCK

FUNCTION_BLOCK SomeCyclicClass
VAR
	_myWriter : ITF_Writer;
END_VAR
    METHOD DoSomething : BOOL
        ///////Perform some operations////////
        IF _myWriter <> 0 THEN
            _myWriter.WriteMessage('I did a job :-)');
        END_IF
    END_METHOD
    PROPERTY MyWriter : ITF_Writer
        GET
            MyWriter := _myWriter;
        SET
            _myWriter := MyWriter;
    END_PROPERTY
END_FUNCTION_BLOCK



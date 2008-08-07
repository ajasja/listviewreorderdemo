unit ajLogger;

interface
uses
  SysUtils, Classes ,Windows, DbugIntf, TypInfo, DB, DBGrids;

const
  sLineBreak = #13#10;
  
procedure Log(const aStr: string = ''); overload;
procedure Log(const aStr: string; const args: array of const); overload;

procedure Log(const aStrList: TStrings; const Indent : String = '  '); overload;
procedure Log(const aStrArray: array of string; const Indent : String = ' '); overload;
procedure Log(const aDataSet: TDataSet; const Indent : String = '  '); overload;


Procedure LogIndent; inline;
procedure LogUnindent; inline;
procedure LogI; inline;
procedure LogU; inline;

procedure LogBegin(Const aName : String; Const aPrefix : String = '');
procedure LogEnd(Const aName : String; Const aPrefix : String = '');

Procedure LogOK(const Ident : String = '  '; const Prefix : String = 'OK.');
Procedure LogError(const Ident : String = '  '; const Prefix : String = 'FAILED: ');
Procedure LogException(E: Exception; const Ident : String = '  '; const Prefix : String = 'NAPAKA: ');


type
  TLogProcedure = procedure(const aStr : String);

procedure RegisterLogProcedure(aLogProc: TLogProcedure);
procedure UnregisterLogProcedure(aLogProc: TLogProcedure);
function LogProcedureRegistered(aLogProc: TLogProcedure): Boolean;

function GetLastErrorString: String;

procedure StartTiming;
procedure EndTiming;

//These two depend on EndTiming to query the counter
function GetElapsedTime_sec: Double;
function GetElapsedTime_Msec: Integer;

//These two depend query the counter each time they are called
function ElapsedTime_sec: Double;
function ElapsedTime_Msec: Integer;

procedure StartMemoryMeasure;
procedure EndMemoryMeasure;

function GetAllocatedMemory_bytes: Integer;
function GetAllocatedMemory_kB: double;
function GetAllocatedMemory_MB: double;

function GetFreedMemory_bytes: Integer;
function GetFreedMemory_kB: double;
function GetFreedMemory_MB: double;

procedure StartTimeAndMemoryMeasure;
procedure EndTimeAndMemoryMeasure;





{$DEFINE ajLOG}

{$IFDEF RELEASE}
  {$UNDEF ajLOG}
{$ENDIF}

var
 IndentStr : String = '  '; //Za eno stopnjo
 IndentLevel : Integer = 0;
 IndentLevelStr : String = '';


implementation
var
 aLogProcList : TList;



procedure Log(const aStr: string = '');
var
  I : Integer;
  aProcedure : TLogProcedure;
begin
{$IFDEF ajLOG} //Samo èe imamo definirano
  OutputDebugString(PChar(IndentLevelStr+aStr));
  SendDebug(IndentLevelStr+aStr);
  for I := 0 to aLogProcList.Count - 1 do
  begin
    aProcedure:=aLogProcList[I];
    If Assigned(aProcedure) then
      aProcedure(aStr);
  end; {for}
  

{$ENDIF}
end;

procedure Log(const aStr: string; const args: array of const);
begin
Log(Format(aStr,args));
end;


Procedure LogIndent;
begin
  Inc(IndentLevel);
  IndentLevelStr:=IndentLevelStr+IndentStr;
end;

procedure LogUnindent;
begin
  Dec(IndentLevel);
  If IndentLevel=0 then
    IndentLevelStr:=''
  else
    SetLength(IndentLevelStr,Length(IndentLevelStr)-Length(IndentStr));
end;


procedure LogI;
begin
  LogIndent;
end;
procedure LogU;
begin
  LogUnindent;
end;


procedure LogBegin(Const aName : String; Const aPrefix : String = '');
begin
  Log('*****'+aPrefix+aName+'*****');
  LogIndent;
end;

procedure LogEnd(Const aName : String; Const aPrefix : String = '');
begin
  Log('---->'+aPrefix+aName+'<----');
  LogUnindent;
  Log();
end;

procedure Log(const aStrList: TStrings; const Indent : String = '  ');
var
I : Integer;
begin
  For I:=0 to aStrList.Count-1 do
    Log(Indent+aStrList[I]);

end;

procedure Log(const aStrArray: array of string; const Indent : String = ' ');
var
I : Integer;
begin
  For I:=Low(aStrArray) to High(aStrArray) do
    Log(Indent+aStrArray[I]);

end;

procedure Log(const aDataSet: TDataSet; const Indent : String = '  ');
var
I : Integer;
begin
if aDataSet=nil then
  begin
    Log('DataSet is nil!');
    exit;
  end;
if not aDataSet.Active then
  begin
    Log('DataSet is not active!');
    exit;
  end;

  For I:=0 to aDataSet.FieldCount-1 do
  with aDataSet.Fields[I] do
  begin
    Log(Indent+'Field "%s" (Datatype %s)',[FieldName,
                                       GetEnumName(TypeInfo(TFieldType),Integer(DataType))]);
    Log(Indent+'  '+'Value: "%s" New: "%s" Old: "%s"',[Value,NewValue,OldValue]);
  end; {for}

end;


procedure RegisterLogProcedure(aLogProc: TLogProcedure);
begin
{$IFDEF ajLOG}
  if Assigned(aLogProc) and (aLogProcList.IndexOf(@aLogProc)<0) then
    aLogProcList.Add(@aLogProc);
{$ENDIF}
end;

procedure UnregisterLogProcedure(aLogProc: TLogProcedure);
var
 I : Integer;
begin
{$IFDEF LOG}
  if Assigned(aLogProc) then
    begin
      I:=aLogProcList.IndexOf(@aLogProc);
      if I>=0 then
        aLogProcList.Delete(I);
    end; {if <> nil}
{$ENDIF}
end;

function LogProcedureRegistered(aLogProc: TLogProcedure): Boolean;
begin
{$IFDEF ajLOG}
  Result := aLogProcList.IndexOf(@aLogProc)>=0;
{$ENDIF}
end;

Procedure LogOK(const Ident : String = '  '; const Prefix : String = 'OK.');
begin
  Log(Ident+Prefix);
end;

Procedure LogError(const Ident : String = '  '; const Prefix : String = 'FAILED: ');
begin
  Log(Ident+Prefix+GetLastErrorString);
end;

Procedure LogException(E: Exception; const Ident : String = '  '; const Prefix : String = 'NAPAKA: ');
begin
  Log(Ident+Prefix+E.Message);
end;

function GetLastErrorString: String;
begin
  Result:=SysErrorMessage(GetLastError);
end;

var
 startTime64, endTime64, frequency64: Int64;

procedure StartTiming;
begin
  QueryPerformanceFrequency(frequency64);
  QueryPerformanceCounter(startTime64);
end;

procedure EndTiming;
begin
  QueryPerformanceCounter(endTime64);
end;

function GetElapsedTime_sec: Double;
begin
  Result := (endTime64 - startTime64) / frequency64;
end;

function GetElapsedTime_Msec: Integer;
begin
  Result:=Round(GetElapsedTime_sec*1000);
end;

function ElapsedTime_sec: Double;
begin
  QueryPerformanceCounter(endTime64);
  Result := (endTime64 - startTime64) / frequency64;
end;

function ElapsedTime_Msec: Integer;
begin
  Result:=Round(ElapsedTime_sec*1000);
end;

Var
  startHS, endHS : THeapStatus;

procedure StartMemoryMeasure;
begin
  startHS:=GetHeapStatus;
end;

procedure EndMemoryMeasure;
begin
  endHS:=GetHeapStatus;
end;

function GetAllocatedMemory_bytes: Integer;
begin
  Result:=endHS.TotalAllocated-startHS.TotalAllocated;
end;

function GetAllocatedMemory_kB: double;
begin
  Result:=GetAllocatedMemory_bytes/1024;
end;

function GetAllocatedMemory_MB: double;
begin
  Result:=GetAllocatedMemory_bytes/1024/1024;
end;

function GetFreedMemory_bytes: Integer;
begin
  Result:=endHS.TotalFree-startHS.TotalFree;
end;

function GetFreedMemory_kB: double;
begin
  Result:=GetFreedMemory_bytes/1024;
end;

function GetFreedMemory_MB: double;
begin
  Result:=GetFreedMemory_bytes/1024/1024;
end;

procedure StartTimeAndMemoryMeasure;
begin
  StartMemoryMeasure;
  StartTiming;
end;
procedure EndTimeAndMemoryMeasure;
begin
  EndTiming;
  EndMemoryMeasure;
end;

initialization
{$IFDEF ajLOG}
 aLogProcList:=TList.Create;
{$ENDIF}

finalization
{$IFDEF ajLOG}
 FreeAndNil(aLogProcList);
 {$ENDIF}
end.

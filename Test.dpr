program Test;
{*******************************************************}
{                                                       }
{       ���������� �������� ������ �� ��������          }
{       ����������� Delphi                              }
{       ��������� �� Embarcadero� Delphi XE7            }
{       �������� ��������                               }
{                                                       }
{       val.kuznetsoff@gmail.com                        }
{       095-060-52-85                                   }
{       098-773-51-99                                   }
{*******************************************************}

{$APPTYPE CONSOLE}

uses
  WinAPI.Windows, System.SysUtils, System.Classes, Registry;

var
  str: string;
  Cancel: boolean;
  FoundKeys: TStringList;
  StartKey, SearchStr: string;

// ������������� �� Windows � DOS
function WinToDos(strWin: string): string;
begin
  Result := strWin;
  CharToOem(PChar(Result), PAnsiChar(Result));
end;

// ���������� ������ ��������� ������
function PadRight(src: string; len: Integer): string;
begin
  Result := src;
  while Length(Result) < len do
    Result := Result + ' ';
end;

// �������� ������� �������
function KeyPressed: Word;
var
  Handle: THandle;
  Buffer: TInputRecord;
  Counter: Cardinal;
begin
  Result:=0;
  Handle:=GetStdHandle(STD_INPUT_HANDLE);
  if Handle = 0 then RaiseLastOSError;
  if not GetNumberOfConsoleInputEvents(Handle, Counter) then
    RaiseLastOSError;
  if not (Counter = 0) then
  begin
    if not ReadConsoleInput(Handle, Buffer, 1, Counter) then
      RaiseLastOSError;
    if (Buffer.EventType = KEY_EVENT) and Buffer.Event.KeyEvent.bKeyDown
    then Result:=Buffer.Event.KeyEvent.wVirtualKeyCode;
  end;
end;

// ����� ����� � ������� ������� (���� ������)
procedure FindKey(key: string);
var
  i: integer;
  s: string;
  reg: TRegistry;
  subKeys: TStrings;
begin
// ���� �������� �������������
  if Cancel then Exit;

  reg := TRegistry.Create;
  reg.RootKey := HKEY_LOCAL_MACHINE;
  try
    try
// ������� ���� ��� ������
      if reg.OpenKeyReadOnly(key) then
      try
        subKeys := TStringList.Create;
        try
// ������ ���������
          reg.GetKeyNames(subKeys);
          i:=0;
// ������� ���������
          while (not Cancel) and (i < SubKeys.Count) do
          begin
            s:=IncludeTrailingPathDelimiter(key + subKeys[i]);

// ���� ������� ������ ������ - ���� ��
            if SearchStr > '' then begin
              if AnsiPos(SearchStr, AnsiLowerCase(subKeys[i])) > 0 then FoundKeys.Add(s);
            end else FoundKeys.Add(s);

            if Length(s) > 79 then s:=copy(s, 1, 79) else s:=PadRight(s, 79);
            Write(#13, s);

// ���� ������ ������� Esc
            if KeyPressed = 27 then begin
              Cancel:=true;
              WriteLn;
              WriteLn(WinToDos('��������� �������������.'));
              FoundKeys.Add('��������� �������������.');
            end;

// ����� ������ ��������
            if (not Cancel) and (subKeys[i] > '') then FindKey(IncludeTrailingPathDelimiter(key + subKeys[i]));
            inc(i);
          end;
        finally
          subKeys.Free;
        end;
      finally
        reg.CloseKey;
      end;
    except
// ��������� ����������
      on E: Exception do
      begin
        WriteLn;
        WriteLn(WinToDos('��������� �� ������: ' + E.Message));
        FoundKeys.Add('��������� �� ������: ' + E.Message);
        raise;
      end;
    end;
  finally
    reg.Free;
  end;
end;

begin
  WriteLn(WinToDos('�������������: test.exe /p:������ ������� � HKLM /s:������� ������.'));
  WriteLn(WinToDos('��� ��������� /p: ������������ ���� ������ ������� HKLM.'));
  WriteLn(WinToDos('��� ��������� /s: ��������� ������ �� �������������.'));
  WriteLn(WinToDos('Esc - ���������� �������.'));

// ��������� ��������� ������
  StartKey:=''; SearchStr:='';
  if ParamCount > 0 then begin
    str:=ParamStr(1);
    if (copy(str, 1, 3) <> '/p:') and (copy(str, 1, 3) <> '/s:') then Exit;
    if copy(str, 1, 3) = '/p:' then StartKey:=copy(str, 4, 255);
    if copy(str, 1, 3) = '/s:' then SearchStr:=AnsiLowercase(copy(str, 4, 255));

    if ParamCount > 1 then begin
      str:=ParamStr(2);
      if (copy(str, 1, 3) <> '/p:') and (copy(str, 1, 3) <> '/s:') then Exit;
      if (StartKey = '') and (copy(str, 1, 3) = '/p:')
        then StartKey:=copy(str, 4, 255);
      if (SearchStr = '') and (copy(str, 1, 3) = '/s:')
        then SearchStr:=AnsiLowercase(copy(str, 4, 255));
    end
  end;

  WriteLn;
  WriteLn(WinToDos('������ �������: '+StartKey));
  WriteLn(WinToDos('������� ������: '+SearchStr));

  StartKey := IncludeTrailingPathDelimiter(StartKey);

  Cancel:=false;
  FoundKeys:=TStringList.Create;
  try
// ����� ������
    FindKey(StartKey);
  finally
// ������ � ���� � ����������
    str:=IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));
    FoundKeys.SaveToFile(str+'Test.Log');
    FoundKeys.Free;
  end;
end.


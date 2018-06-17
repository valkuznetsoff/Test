program Test;
{*******************************************************}
{                                                       }
{       Выполнение тестовой работы на вакансию          }
{       Разработчик Delphi                              }
{       Выполнено на Embarcadero® Delphi XE7            }
{       Валентин Кузнецов                               }
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
  iCheckKeys: integer;

// Перекодировка из Windows в DOS
function WinToDos(strWin: string): string;
begin
  Result := strWin;
  CharToOem(PChar(Result), PAnsiChar(Result));
end;

// Проверка нажатия клавиши
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

// Поиск ключа с искомой строкой (если задана)
procedure FindKey(key: string);
var
  i: integer;
  s: string;
  reg: TRegistry;
  subKeys: TStrings;
begin
// Если прервано пользователем
  if Cancel then Exit;

  reg := TRegistry.Create;
  reg.RootKey := HKEY_LOCAL_MACHINE;
  try
    try
// Открыть ключ для чтения
      if reg.OpenKeyReadOnly(key) then
      try
        subKeys := TStringList.Create;
        try
// Список подключей
          reg.GetKeyNames(subKeys);
          i:=0;
// Перебор подключей
          while (not Cancel) and (i < SubKeys.Count) do
          begin
            Inc(iCheckKeys);
            s:=IncludeTrailingPathDelimiter(key + subKeys[i]);

// Проверка подключа на соответствие условиям поиска
            if SearchStr > '' then begin
              if Pos(SearchStr, LowerCase(subKeys[i])) > 0 then FoundKeys.Add(s);
            end else FoundKeys.Add(s);

            Write(#13, 'Проверено: '+IntToStr(iCheckKeys)+' ключей. Найдено соответствий: '+IntToStr(FoundKeys.Count));

// Если нажата клавиша Esc
            if KeyPressed = 27 then begin
              Cancel:=true;
              WriteLn;
              WriteLn(WinToDos('Остановка пользователем.'));
              FoundKeys.Add('Проверено: '+IntToStr(iCheckKeys)+' ключей. Найдено соответствий: '+IntToStr(FoundKeys.Count));
              FoundKeys.Add('Остановка пользователем.');
            end;

// Поиск внутри подключа
            if (not Cancel) and (subKeys[i] > '') and (reg.HasSubKeys) then FindKey(s);
            inc(i);
          end;
        finally
          subKeys.Free;
        end;
      finally
        reg.CloseKey;
      end;
    except
// Обработка исключений
      on E: Exception do
      begin
        WriteLn;
        WriteLn(WinToDos('Остановка по ошибке: ' + E.Message));
        FoundKeys.Add('Проверено: '+IntToStr(iCheckKeys)+' ключей. Найдено соответствий: '+IntToStr(FoundKeys.Count));
        FoundKeys.Add('Остановка по ошибке: ' + E.Message);
        raise;
      end;
    end;
  finally
    reg.Free;
  end;
end;

begin
  WriteLn(WinToDos('Использование: test.exe /p:раздел реестра в HKLM /s:искомая строка.'));
  WriteLn(WinToDos('Без параметра /p: используется весь раздел реестра HKLM.'));
  WriteLn(WinToDos('Без параметра /s: вхождения строки не анализируются.'));
  WriteLn(WinToDos('Esc - остановить процесс.'));

// Параметры командной строки
  StartKey:=''; SearchStr:='';
  if ParamCount > 0 then begin
    str:=ParamStr(1);
    if (copy(str, 1, 3) <> '/p:') and (copy(str, 1, 3) <> '/s:') then Exit;
    if copy(str, 1, 3) = '/p:' then StartKey:=copy(str, 4, 255);
    if copy(str, 1, 3) = '/s:' then SearchStr:=Lowercase(copy(str, 4, 255));

    if ParamCount > 1 then begin
      str:=ParamStr(2);
      if (copy(str, 1, 3) <> '/p:') and (copy(str, 1, 3) <> '/s:') then Exit;
      if (StartKey = '') and (copy(str, 1, 3) = '/p:')
        then StartKey:=copy(str, 4, 255);
      if (SearchStr = '') and (copy(str, 1, 3) = '/s:')
        then SearchStr:=Lowercase(copy(str, 4, 255));
    end
  end;

  StartKey:='\'+StartKey;
  StartKey := IncludeTrailingPathDelimiter(StartKey);

  WriteLn;
  WriteLn(WinToDos('Раздел реестра: '+StartKey));
  WriteLn(WinToDos('Искомая строка: '+SearchStr));

  Cancel:=false;
  iCheckKeys:=1;
  FoundKeys:=TStringList.Create;

// Проверка начального ключа
  if SearchStr > '' then begin
    if Pos(SearchStr, LowerCase(StartKey)) > 0 then FoundKeys.Add(StartKey);
  end else FoundKeys.Add(StartKey);

  try
// Старт поиска
    FindKey(StartKey);
  finally
// Запись в файл и завершение
    if not Cancel then begin
      WriteLn;
      WriteLn(WinToDos('Проверка окончена'));
      FoundKeys.Add('Проверено: '+IntToStr(iCheckKeys)+' ключей. Найдено соответствий: '+IntToStr(FoundKeys.Count));
      FoundKeys.Add('Проверка окончена');
    end;
    str:=IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));
    FoundKeys.SaveToFile(str+'Test.Log');
    FoundKeys.Free;
  end;
end.


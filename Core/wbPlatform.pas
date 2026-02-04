{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit wbPlatform;

interface

uses
  SysUtils
  {$IFDEF FPC}
  {$IFDEF LINUX}
  , Process
  {$ENDIF}
  {$ENDIF}
  ;

type
  TwbPlatformOutputProc = reference to procedure(const aLine: string);
  TwbPlatformProc = reference to procedure;
  TwbPlatformTerminateFunc = reference to function: Boolean;
  TwbKnownFolder = (wkDocuments, wkLocalAppData);

function wbPathCombine(const aBase, aChild: string): string;
function wbNormalizePath(const aPath: string): string;
function wbGetKnownFolderPath(const aFolder: TwbKnownFolder): string;
function wbTryReadRegistryString(
  const aCurrentUser: Boolean;
  const aRegPath, aValueName: string;
  out aValue: string
): Boolean;
function wbOpenUrl(const aUrl: string): Boolean;
function wbCreateProcessWait(
  const aFileName, aParams: string;
  const aShowWindow: Integer;
  const aTimeout: Cardinal;
  out aExitCode: Cardinal
): Boolean;
function wbGetVirtualKeyState(const aVirtualKey: Integer): SmallInt;
function wbGetSteamInstallFolder: string;
function wbIsAssociatedWithExtension(const aExt, aExecPath: string): Boolean;
function wbAssociateWithExtension(const aExt, aName, aDescr, aExecPath: string): Boolean;
function wbExecuteCaptureConsoleOutput(
  const aCommandLine: string;
  const aOnOutput: TwbPlatformOutputProc;
  const aProcessMessages: TwbPlatformProc;
  const aShouldTerminate: TwbPlatformTerminateFunc
): Cardinal;
procedure wbPlatformInitHandles(out aFileHandle, aMapHandle: THandle);
procedure wbPlatformMapFileReadOnly(
  const aFileName: string;
  out aView: Pointer;
  out aSize: Int64;
  var aFileHandle, aMapHandle: THandle
);
procedure wbPlatformUnmapFile(var aView: Pointer; var aFileHandle, aMapHandle: THandle);
procedure wbPlatformAllocReadOnlyFileBuffer(const aFileName: string; out aView: Pointer; out aSize: Int64);
procedure wbPlatformFreeBuffer(var aView: Pointer);

implementation

uses
  Classes
  {$IFDEF MSWINDOWS}
  , Windows,
  Registry,
  ShellAPI,
  ShlObj
  {$ENDIF}
  ;

function wbPathCombine(const aBase, aChild: string): string;
begin
  if aBase = '' then
    Exit(aChild);
  if aChild = '' then
    Exit(aBase);
  Result := IncludeTrailingPathDelimiter(aBase) + aChild;
end;

function wbCreateProcessWait(
  const aFileName, aParams: string;
  const aShowWindow: Integer;
  const aTimeout: Cardinal;
  out aExitCode: Cardinal
): Boolean;
{$IFDEF MSWINDOWS}
var
  lStartUpInfo: TStartUpInfo;
  lProcessInfo: TProcessInformation;
{$ENDIF}
begin
  Result := False;
  aExitCode := Cardinal(-1);

  {$IFDEF MSWINDOWS}
  FillChar(lStartUpInfo, SizeOf(TStartUpInfo), 0);
  with lStartUpInfo do begin
    cb := SizeOf(TStartUpInfo);
    dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
    wShowWindow := aShowWindow;
  end;

  if not CreateProcess(
    PWideChar(aFileName),
    PWideChar(aParams),
    nil, nil, False, NORMAL_PRIORITY_CLASS,
    nil,
    nil,
    lStartUpInfo, lProcessInfo
  ) then
    Exit(False);

  try
    WaitforSingleObject(lProcessInfo.hProcess, aTimeout);
    GetExitCodeProcess(lProcessInfo.hProcess, aExitCode);
    Result := True;
  finally
    CloseHandle(lProcessInfo.hThread);
    CloseHandle(lProcessInfo.hProcess);
  end;
  Exit;
  {$ENDIF}
end;

function wbGetVirtualKeyState(const aVirtualKey: Integer): SmallInt;
begin
  {$IFDEF MSWINDOWS}
  Result := GetKeyState(aVirtualKey);
  Exit;
  {$ENDIF}
  Result := 0;
end;

function wbNormalizePath(const aPath: string): string;
var
  lResult: string;
begin
  lResult := StringReplace(aPath, '\', PathDelim, [rfReplaceAll]);
  lResult := StringReplace(lResult, '/', PathDelim, [rfReplaceAll]);
  Result := ExcludeTrailingPathDelimiter(lResult);
end;

function wbGetKnownFolderPath(const aFolder: TwbKnownFolder): string;
{$IFDEF MSWINDOWS}
var
  lCSIDL: Integer;
  lBuffer: array[0..MAX_PATH - 1] of Char;
{$ENDIF}
{$IFDEF LINUX}
var
  lHome: string;
{$ENDIF}
begin
  Result := '';
  {$IFDEF MSWINDOWS}
  case aFolder of
    wkDocuments: lCSIDL := CSIDL_PERSONAL;
    wkLocalAppData: lCSIDL := CSIDL_LOCAL_APPDATA;
  else
    Exit;
  end;
  if SHGetSpecialFolderPath(0, lBuffer, lCSIDL, True) then
    Result := IncludeTrailingPathDelimiter(StrPas(lBuffer));
  Exit;
  {$ENDIF}

  {$IFDEF LINUX}
  lHome := GetEnvironmentVariable('HOME');
  if lHome = '' then
    Exit;
  case aFolder of
    wkDocuments: Result := wbPathCombine(lHome, 'Documents');
    wkLocalAppData: Result := wbPathCombine(lHome, '.local/share');
  end;
  if Result <> '' then
    Result := IncludeTrailingPathDelimiter(Result);
  Exit;
  {$ENDIF}
end;

function wbOpenUrl(const aUrl: string): Boolean;
{$IFDEF FPC}
{$IFDEF LINUX}
var
  lProc: TProcess;
{$ENDIF}
{$ENDIF}
begin
  Result := False;
  if Trim(aUrl) = '' then
    Exit;

  {$IFDEF MSWINDOWS}
  Result := ShellExecute(0, 'open', PChar(aUrl), nil, nil, SW_SHOWNORMAL) > 32;
  Exit;
  {$ENDIF}

  {$IFDEF FPC}
  {$IFDEF LINUX}
  lProc := TProcess.Create(nil);
  try
    lProc.Executable := '/usr/bin/xdg-open';
    lProc.Parameters.Add(aUrl);
    lProc.Options := [];
    lProc.Execute;
    Result := True;
  finally
    lProc.Free;
  end;
  Exit;
  {$ENDIF}
  {$ENDIF}
end;

function wbTryReadRegistryString(
  const aCurrentUser: Boolean;
  const aRegPath, aValueName: string;
  out aValue: string
): Boolean;
{$IFDEF MSWINDOWS}
var
  lAccess: Cardinal;
{$ENDIF}
begin
  aValue := '';
  Result := False;
  if (aRegPath = '') or (aValueName = '') then
    Exit;

  {$IFDEF MSWINDOWS}
  with TRegistry.Create do
    try
      if aCurrentUser then
        RootKey := HKEY_CURRENT_USER
      else
        RootKey := HKEY_LOCAL_MACHINE;

      lAccess := KEY_READ or KEY_WOW64_32KEY;
      Access := lAccess;
      if not OpenKey(aRegPath, False) then begin
        lAccess := KEY_READ or KEY_WOW64_64KEY;
        Access := lAccess;
        if not OpenKey(aRegPath, False) then
          Exit(False);
      end;

      aValue := StringReplace(ReadString(aValueName), '"', '', [rfReplaceAll]);
      Result := aValue <> '';
    finally
      Free;
    end;
  {$ENDIF}
end;

function wbGetSteamInstallFolder: string;
{$IFDEF MSWINDOWS}
const
  sSteamKey = '\SOFTWARE\Valve\Steam\';
  sRegKey = 'InstallPath';
var
  s: string;
{$ENDIF}
{$IFDEF LINUX}
const
  cCandidateCount = 3;
var
  lHome: string;
  lCandidates: array[0..cCandidateCount - 1] of string;
  i: Integer;
{$ENDIF}
begin
  Result := '';

  {$IFDEF MSWINDOWS}
  with TRegistry.Create do
    try
      Access := KEY_READ or KEY_WOW64_32KEY;
      RootKey := HKEY_LOCAL_MACHINE;

      if not OpenKey(sSteamKey, False) then
      begin
        Access := KEY_READ or KEY_WOW64_64KEY;
        if not OpenKey(sSteamKey, False) then
          Exit;
      end;

      s := ReadString(sRegKey);
      s := StringReplace(s, '"', '', [rfReplaceAll]);
      if DirectoryExists(s) then
        Result := s;
    finally
      Free;
    end;
  Exit;
  {$ENDIF}

  {$IFDEF LINUX}
  lHome := GetEnvironmentVariable('HOME');
  if lHome = '' then
    Exit;

  lCandidates[0] := wbPathCombine(lHome, '.steam/steam');
  lCandidates[1] := wbPathCombine(lHome, '.local/share/Steam');
  lCandidates[2] := wbPathCombine(lHome, '.var/app/com.valvesoftware.Steam/.local/share/Steam');

  for i := Low(lCandidates) to High(lCandidates) do
    if DirectoryExists(lCandidates[i]) then
      Exit(lCandidates[i]);

  Exit;
  {$ENDIF}
end;

function wbIsAssociatedWithExtension(const aExt, aExecPath: string): Boolean;
{$IFDEF MSWINDOWS}
var
  lName: string;
{$ENDIF}
begin
  Result := False;
  if aExt = '' then
    Exit;

  {$IFDEF MSWINDOWS}
  with TRegistry.Create do
    try
      RootKey := HKEY_CURRENT_USER;
      if OpenKey('\Software\Classes\' + LowerCase(aExt), False) then
      begin
        lName := ReadString('');
        if (lName <> '') and OpenKey('\Software\Classes\' + lName + '\DefaultIcon', False) then
          Result := SameText(ReadString(''), aExecPath);
      end;
    finally
      Free;
    end;
  {$ENDIF}
end;

function wbAssociateWithExtension(const aExt, aName, aDescr, aExecPath: string): Boolean;
{$IFDEF MSWINDOWS}
var
  lExt: string;
{$ENDIF}
begin
  Result := False;

  {$IFDEF MSWINDOWS}
  lExt := Trim(aExt);
  if lExt = '' then
    Exit;

  lExt := LowerCase(lExt);
  if lExt[1] <> '.' then
    lExt := '.' + lExt;

  with TRegistry.Create do
    try
      RootKey := HKEY_CURRENT_USER;

      if OpenKey('\Software\Classes\' + lExt, True) then
        WriteString('', aName)
      else
        raise Exception.Create('Not enough rights to modify the registry');

      if OpenKey('\Software\Classes\' + aName, True) then
        WriteString('', aDescr);

      if OpenKey('\Software\Classes\' + aName + '\DefaultIcon', True) then
        WriteString('', aExecPath);

      if OpenKey('\Software\Classes\' + aName + '\shell\open\command', True) then
        WriteString('', aExecPath + ' "%1"');

      Result := True;
    finally
      Free;
    end;

  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
  {$ENDIF}
end;

function wbExecuteCaptureConsoleOutput(
  const aCommandLine: string;
  const aOnOutput: TwbPlatformOutputProc;
  const aProcessMessages: TwbPlatformProc;
  const aShouldTerminate: TwbPlatformTerminateFunc
): Cardinal;
{$IFDEF FPC}
{$IFDEF LINUX}
const
  CReadBuffer = 4096;
var
  lProc: TProcess;
  lBuffer: array[0..CReadBuffer - 1] of Byte;
  lBytesRead: LongInt;
  lChunk: AnsiString;
  lCarry: AnsiString;
  i: Integer;
  procedure FlushLines(const aData: AnsiString; aFinal: Boolean);
  var
    lText: AnsiString;
    lPos: Integer;
    lLine: string;
  begin
    lText := lCarry + aData;
    lPos := Pos(#10, lText);
    while lPos > 0 do
    begin
      lLine := Trim(string(Copy(lText, 1, lPos - 1)));
      if (lLine <> '') and Assigned(aOnOutput) then
        aOnOutput(lLine);
      Delete(lText, 1, lPos);
      lPos := Pos(#10, lText);
    end;
    lCarry := lText;
    if aFinal and (Trim(string(lCarry)) <> '') and Assigned(aOnOutput) then
      aOnOutput(Trim(string(lCarry)));
  end;
{$ENDIF}
{$ENDIF}
{$IFDEF MSWINDOWS}
const
  CReadBuffer = 4096;
var
  saSecurity: TSecurityAttributes;
  hRead: THandle;
  hWrite: THandle;
  suiStartup: TStartupInfo;
  piProcess: TProcessInformation;
  pBuffer: array [0..CReadBuffer] of AnsiChar;
  pCmdLine: array [0..MAX_PATH] of Char;
  dRead, dRunning, dw: DWord;
  s: string;
{$ENDIF}
begin
  {$IFDEF FPC}
  {$IFDEF LINUX}
  lProc := TProcess.Create(nil);
  try
    lProc.Executable := '/bin/sh';
    lProc.Parameters.Add('-lc');
    lProc.Parameters.Add(aCommandLine);
    lProc.Options := [poUsePipes, poStderrToOutput];
    lProc.Execute;
    lCarry := '';

    while lProc.Running do
    begin
      if Assigned(aProcessMessages) then
        aProcessMessages();

      if Assigned(aShouldTerminate) and aShouldTerminate() then
      begin
        lProc.Terminate(1);
        Result := 1;
        Exit;
      end;

      while lProc.Output.NumBytesAvailable > 0 do
      begin
        lBytesRead := lProc.Output.Read(lBuffer[0], CReadBuffer);
        if lBytesRead <= 0 then
          Break;
        SetLength(lChunk, lBytesRead);
        for i := 1 to lBytesRead do
          lChunk[i] := AnsiChar(lBuffer[i - 1]);
        FlushLines(lChunk, False);
      end;

      Sleep(50);
    end;

    while lProc.Output.NumBytesAvailable > 0 do
    begin
      lBytesRead := lProc.Output.Read(lBuffer[0], CReadBuffer);
      if lBytesRead <= 0 then
        Break;
      SetLength(lChunk, lBytesRead);
      for i := 1 to lBytesRead do
        lChunk[i] := AnsiChar(lBuffer[i - 1]);
      FlushLines(lChunk, False);
    end;
    FlushLines('', True);

    Result := lProc.ExitStatus;
  finally
    lProc.Free;
  end;
  Exit;
  {$ENDIF}
  {$ENDIF}

  {$IFNDEF MSWINDOWS}
  raise Exception.Create('wbExecuteCaptureConsoleOutput is not implemented on this platform yet');
  {$ENDIF}

  {$IFDEF MSWINDOWS}
  saSecurity.nLength := SizeOf(TSecurityAttributes);
  saSecurity.bInheritHandle := True;
  saSecurity.lpSecurityDescriptor := nil;

  if not CreatePipe(hRead, hWrite, @saSecurity, 0) then
    RaiseLastOSError;

  try
    FillChar(suiStartup, SizeOf(TStartupInfo), #0);
    suiStartup.cb := SizeOf(TStartupInfo);
    suiStartup.hStdInput := hRead;
    suiStartup.hStdOutput := hWrite;
    suiStartup.hStdError := hWrite;
    suiStartup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    suiStartup.wShowWindow := SW_HIDE;

    StrPCopy(pCmdLine, aCommandLine);
    if not CreateProcess(nil, pCmdLine, @saSecurity, @saSecurity, True, NORMAL_PRIORITY_CLASS, nil, nil, suiStartup, piProcess) then
      RaiseLastOSError;

    try
      repeat
        dRunning := WaitForSingleObject(piProcess.hProcess, 100);
        if Assigned(aProcessMessages) then
          aProcessMessages();

        if Assigned(aShouldTerminate) and aShouldTerminate() then
        begin
          dw := Integer(TerminateProcess(piProcess.hProcess, 1));
          if dw <> 0 then
          begin
            dw := WaitForSingleObject(piProcess.hProcess, 1000);
            if dw = WAIT_FAILED then
              Result := GetLastError;
          end
          else
            Result := GetLastError;
          Exit;
        end;

        if PeekNamedPipe(hRead, nil, 0, nil, @dRead, nil) and (dRead > 0) then
          repeat
            dRead := 0;
            ReadFile(hRead, pBuffer[0], CReadBuffer, dRead, nil);
            pBuffer[dRead] := #0;
            s := Trim(string(AnsiString(pBuffer)));
            if (s <> '') and Assigned(aOnOutput) then
              aOnOutput(s);
          until dRead < CReadBuffer;
      until dRunning <> WAIT_TIMEOUT;
      GetExitCodeProcess(piProcess.hProcess, Result);
    finally
      CloseHandle(piProcess.hProcess);
      CloseHandle(piProcess.hThread);
    end;
  finally
    CloseHandle(hRead);
    CloseHandle(hWrite);
  end;
  {$ENDIF}
end;

procedure wbPlatformInitHandles(out aFileHandle, aMapHandle: THandle);
begin
  {$IFDEF MSWINDOWS}
  aFileHandle := INVALID_HANDLE_VALUE;
  aMapHandle := INVALID_HANDLE_VALUE;
  {$ELSE}
  aFileHandle := 0;
  aMapHandle := 0;
  {$ENDIF}
end;

procedure wbPlatformMapFileReadOnly(
  const aFileName: string;
  out aView: Pointer;
  out aSize: Int64;
  var aFileHandle, aMapHandle: THandle
);
{$IFDEF MSWINDOWS}
const
  FileAccessMode = GENERIC_READ;
  FileShareMode = FILE_SHARE_READ;
  PageProtection = PAGE_READONLY;
  ViewAccessMode = FILE_MAP_READ;
{$ENDIF}
begin
  aView := nil;
  aSize := 0;
  wbPlatformInitHandles(aFileHandle, aMapHandle);

  {$IFDEF MSWINDOWS}
  aFileHandle := CreateFile(
    PChar(aFileName),
    FileAccessMode,
    FileShareMode,
    nil,
    OPEN_EXISTING,
    FILE_FLAG_RANDOM_ACCESS,
    0
  );
  if (aFileHandle = INVALID_HANDLE_VALUE) or (aFileHandle = 0) then
    RaiseLastOSError;

  if not GetFileSizeEx(aFileHandle, aSize) then
    RaiseLastOSError;

  if aSize < 1 then
    raise Exception.CreateFmt('"%s" is 0 bytes in size', [aFileName]);

  aMapHandle := CreateFileMapping(
    aFileHandle,
    nil,
    PageProtection,
    0,
    0,
    nil
  );
  if (aMapHandle = INVALID_HANDLE_VALUE) or (aMapHandle = 0) then
    RaiseLastOSError;

  aView := MapViewOfFileEx(
    aMapHandle,
    ViewAccessMode,
    0,
    0,
    0,
    nil
  );
  if not Assigned(aView) then
    RaiseLastOSError;
  Exit;
  {$ENDIF}

  with TFileStream.Create(aFileName, fmOpenRead or fmShareDenyWrite) do
    try
      aSize := Size;
      if aSize < 1 then
        raise Exception.CreateFmt('"%s" is 0 bytes in size', [aFileName]);
      GetMem(aView, aSize);
      if not Assigned(aView) then
        raise Exception.Create('Out of memory while loading file');
      ReadBuffer(aView^, aSize);
    finally
      Free;
    end;
end;

procedure wbPlatformUnmapFile(var aView: Pointer; var aFileHandle, aMapHandle: THandle);
begin
  {$IFDEF MSWINDOWS}
  if Assigned(aView) then begin
    UnmapViewOfFile(aView);
    aView := nil;
  end;

  if (aMapHandle <> INVALID_HANDLE_VALUE) and (aMapHandle <> 0) then begin
    CloseHandle(aMapHandle);
    aMapHandle := INVALID_HANDLE_VALUE;
  end;

  if (aFileHandle <> INVALID_HANDLE_VALUE) and (aFileHandle <> 0) then begin
    CloseHandle(aFileHandle);
    aFileHandle := INVALID_HANDLE_VALUE;
  end;
  Exit;
  {$ENDIF}

  if Assigned(aView) then begin
    FreeMem(aView);
    aView := nil;
  end;
  aFileHandle := 0;
  aMapHandle := 0;
end;

procedure wbPlatformAllocReadOnlyFileBuffer(const aFileName: string; out aView: Pointer; out aSize: Int64);
{$IFDEF MSWINDOWS}
var
  OldProtect: Cardinal;
{$ENDIF}
begin
  aView := nil;
  with TFileStream.Create(aFileName, fmOpenRead or fmShareDenyWrite) do
    try
      aSize := Size;
      if aSize < 1 then
        Exit;
      {$IFDEF MSWINDOWS}
      aView := VirtualAlloc(nil, aSize, MEM_COMMIT, PAGE_READWRITE);
      if not Assigned(aView) then
        RaiseLastOSError;
      ReadBuffer(aView^, aSize);
      if not VirtualProtect(aView, aSize, PAGE_READONLY, OldProtect) then
        RaiseLastOSError;
      {$ELSE}
      GetMem(aView, aSize);
      if not Assigned(aView) then
        raise Exception.Create('Out of memory while loading file');
      ReadBuffer(aView^, aSize);
      {$ENDIF}
    finally
      Free;
    end;
end;

procedure wbPlatformFreeBuffer(var aView: Pointer);
begin
  if not Assigned(aView) then
    Exit;
  {$IFDEF MSWINDOWS}
  VirtualFree(aView, 0, MEM_RELEASE);
  {$ELSE}
  FreeMem(aView);
  {$ENDIF}
  aView := nil;
end;

end.

{******************************************************************************


  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

{$I xeDefines.inc}
{$DEFINE XEDIT_HEADLESS}

program xedit_core;

{$IFNDEF FPC}
{$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished]) PROPERTIES([vcPrivate, vcProtected, vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic, vcPublished])}
{$ENDIF}

uses
  SysUtils,
  xeInit in 'xEdit/xeInit.pas',
  wbInterface in 'Core/wbInterface.pas';

function HasHelpSwitch: Boolean;
var
  i: Integer;
  s: string;
begin
  Result := False;
  for i := 1 to ParamCount do begin
    s := LowerCase(ParamStr(i));
    if (s = '-h') or (s = '--help') or (s = '/?') then
      Exit(True);
  end;
end;

function HasDummySwitch: Boolean;
var
  i: Integer;
  s: string;
begin
  Result := False;
  for i := 1 to ParamCount do begin
    s := LowerCase(ParamStr(i));
    if (s = '-dummy') or (s = '--dummy') or (s = '/dummy') then
      Exit(True);
  end;
end;

function HasExplicitDataPathArg: Boolean;
var
  i: Integer;
  s: string;
begin
  Result := False;
  for i := 1 to ParamCount do begin
    s := LowerCase(ParamStr(i));
    if (Copy(s, 1, 3) = '-d:') or (Copy(s, 1, 3) = '/d:') then
      Exit(True);
  end;
end;

begin
  SysUtils.FormatSettings.DecimalSeparator := '.';

  if (ParamCount = 0) or HasHelpSwitch then begin
    WriteLn('xedit-core (headless)');
    WriteLn('Usage: xedit-core [options]');
    WriteLn('  -h, --help   Show this help');
    Halt(0);
  end;

  if HasDummySwitch and not HasExplicitDataPathArg then begin
    WriteLn('xEdit dummy init ok');
    Halt(0);
  end;

  xeInitStyles;
  if not xeDoInit then
    Halt(1);

  WriteLn(wbApplicationTitle);
end.

{******************************************************************************


  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit xeMainFormServices;

{$I xeDefines.inc}

interface

uses
  SysUtils,
  IOUtils,
  IniFiles;

procedure xePersistThemeSetting(const aSettings: TMemIniFile; const aStyleName: string);
function xeGetFileWriteStampUtc(const aFileName: string): Int64;

implementation

procedure xePersistThemeSetting(const aSettings: TMemIniFile; const aStyleName: string);
begin
  if not Assigned(aSettings) then
    Exit;

  if aSettings.ReadString('UI', 'Theme', '') = aStyleName then
    Exit;

  aSettings.WriteString('UI', 'Theme', aStyleName);
  aSettings.UpdateFile;
end;

function xeGetFileWriteStampUtc(const aFileName: string): Int64;
var
  lTime: TDateTime;
  lStamp: TTimeStamp;
begin
  if not FileExists(aFileName) then
    Exit(-1);

  lTime := TFile.GetLastWriteTimeUtc(aFileName);
  lStamp := DateTimeToTimeStamp(lTime);
  Result := Int64(lStamp.Date) * 86400000 + lStamp.Time;
end;

end.

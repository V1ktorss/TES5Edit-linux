{******************************************************************************


  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit xeMainFormServices;

{$I xeDefines.inc}

interface

uses
  Classes,
  SysUtils,
  IOUtils,
  IniFiles,
  wbStreams,
  wbInterface;

procedure xePersistThemeSetting(const aSettings: TMemIniFile; const aStyleName: string);
function xeGetFileWriteStampUtc(const aFileName: string): Int64;
function xeGetNewestFileWriteStampUtc(const aFileNames: array of string): Int64;
function xeTryReadLastCsvFields(const aFileName: string; const aMinFieldCount: Integer; aOut: TStrings): Boolean;
function xeTryReadGameLinkSelection(const aFileName: string; out aSelectedRefID, aSelectedBaseID: TwbFormID): Boolean;

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

function xeGetNewestFileWriteStampUtc(const aFileNames: array of string): Int64;
var
  i: Integer;
  lStamp: Int64;
begin
  Result := -1;
  for i := Low(aFileNames) to High(aFileNames) do begin
    lStamp := xeGetFileWriteStampUtc(aFileNames[i]);
    if lStamp > Result then
      Result := lStamp;
  end;
end;

function xeTryReadLastCsvFields(const aFileName: string; const aMinFieldCount: Integer; aOut: TStrings): Boolean;
var
  lRaw: string;
  lLines: TStringList;
  lTailOffset: Int64;
  lToRead: Integer;
begin
  Result := False;
  if not Assigned(aOut) then
    Exit;

  aOut.Clear;
  if not FileExists(aFileName) then
    Exit;

  with TBufferedFileStream.Create(aFileName, fmOpenRead or fmShareDenyNone) do
  try
    lTailOffset := Size - 2024;
    if lTailOffset < 0 then
      lTailOffset := 0;
    Position := lTailOffset;

    lToRead := Integer(Size - Position);
    if lToRead > (64 * 1024) then
      lToRead := 64 * 1024;
    if lToRead <= 0 then
      Exit;

    SetLength(lRaw, lToRead);
    lToRead := Read(lRaw[1], lToRead);
    if lToRead <= 0 then
      Exit;
    SetLength(lRaw, lToRead);
  finally
    Free;
  end;

  lLines := TStringList.Create;
  try
    lLines.Text := lRaw;
    if lLines.Count < 2 then
      Exit;

    aOut.CommaText := lLines[lLines.Count - 1];
    if aOut.Count < aMinFieldCount then
      Exit;
  finally
    lLines.Free;
  end;

  Result := True;
end;

function xeTryReadGameLinkSelection(const aFileName: string; out aSelectedRefID, aSelectedBaseID: TwbFormID): Boolean;
var
  lStream: TBufferedFileStream;
  lStrings: TStringList;
begin
  Result := False;
  aSelectedRefID := TwbFormID.Null;
  aSelectedBaseID := TwbFormID.Null;

  if not FileExists(aFileName) then
    Exit;

  lStream := TBufferedFileStream.Create(aFileName, fmOpenRead or fmShareDenyNone);
  try
    lStrings := TStringList.Create;
    try
      lStrings.LoadFromStream(lStream);
      with TMemIniFile.Create('') do
      try
        SetStrings(lStrings);
        aSelectedRefID := TwbFormID.FromStrDef(ReadString('Console', 'selectedRefID', '00000000'));
        aSelectedBaseID := TwbFormID.FromStrDef(ReadString('Console', 'selectedBaseID', '00000000'));
        Result := True;
      finally
        Free;
      end;
    finally
      lStrings.Free;
    end;
  finally
    lStream.Free;
  end;
end;

end.

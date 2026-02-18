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
  wbInterface,
  wbHelpers;

type
  TxePluggySelection = record
    FormID: TwbFormID;
    BaseFormID: TwbFormID;
    InventoryFormID: TwbFormID;
    EnchantmentFormID: TwbFormID;
    SpellFormID: TwbFormID;
  end;

  TxeGameLinkSelection = record
    RefID: TwbFormID;
    BaseID: TwbFormID;
  end;

function xeBuildPluggySelection(
  const aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID
): TxePluggySelection;
function xeBuildGameLinkSelection(const aRefID, aBaseID: TwbFormID): TxeGameLinkSelection;

procedure xePersistThemeSetting(const aSettings: TMemIniFile; const aStyleName: string);
function xeGetFileWriteStampUtc(const aFileName: string): Int64;
function xeGetNewestFileWriteStampUtc(const aFileNames: array of string): Int64;
function xeGetPluggyUserFilesFolder(const aMyGamesTheGamePath: string): string;
function xeGetGameLinkFolder(const aDataPath: string): string;
function xeGetGameLinkFilePath(const aFolder: string): string;
function xeGetGameLinkWatchStamp(const aFolder: string): Int64;
function xeGetPluggyWatchStamp(const aFolder, aAppName: string): Int64;
function xeConsumeWatchStampChange(var aLastStamp: Int64; const aCurrentStamp: Int64): Boolean;
function xeTryReadLastCsvFields(const aFileName: string; const aMinFieldCount: Integer; aOut: TStrings): Boolean;
function xeTryReadGameLinkSelection(const aFileName: string; out aSelectedRefID, aSelectedBaseID: TwbFormID): Boolean;
function xeTryReadGameLinkSelection(const aFileName: string; out aSelection: TxeGameLinkSelection): Boolean;
function xeTryReadPluggySelection(const aFolder, aAppName: string;
  out aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID): Boolean;
function xeTryReadPluggySelection(const aFolder, aAppName: string; out aSelection: TxePluggySelection): Boolean;
function xeHasPluggySelectionChanged(
  const aLastFormID, aLastBaseFormID, aLastInventoryFormID, aLastEnchantmentFormID, aLastSpellFormID: TwbFormID;
  const aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID
): Boolean;
function xeHasPluggySelectionChanged(const aLast, aCurrent: TxePluggySelection): Boolean;
procedure xeAssignPluggySelection(const aSelection: TxePluggySelection;
  var aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID);
function xeApplyPluggySelectionIfChanged(
  var aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID;
  const aSelection: TxePluggySelection
): Boolean;
function xeHasGameLinkSelectionChanged(
  const aLastRefID, aLastBaseID, aRefID, aBaseID: TwbFormID
): Boolean;
function xeHasGameLinkSelectionChanged(const aLast, aCurrent: TxeGameLinkSelection): Boolean;
procedure xeAssignGameLinkSelection(const aSelection: TxeGameLinkSelection; var aRefID, aBaseID: TwbFormID);
function xeApplyGameLinkSelectionIfChanged(var aRefID, aBaseID: TwbFormID; const aSelection: TxeGameLinkSelection): Boolean;
function xeTryUpdatePluggySelection(
  const aFolder, aAppName: string;
  var aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID;
  out aSelection: TxePluggySelection
): Boolean;
function xeTryUpdateGameLinkSelection(
  const aFileName: string;
  var aRefID, aBaseID: TwbFormID;
  out aSelection: TxeGameLinkSelection
): Boolean;
function xeParseLatestXEditVersionFromGitHubJson(const aJsonUtf8: string): TwbVersion;
function xeParseNexusVersionFromHtml(const aHtml: string): TwbVersion;
function xeTryGetLatestXEditVersionFromGitHub(out aVersion: TwbVersion): Boolean;
function xeTryGetLatestNexusVersion(const aUrl: string; out aVersion: TwbVersion): Boolean;

implementation

function xeBuildPluggySelection(
  const aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID
): TxePluggySelection;
begin
  Result.FormID := aFormID;
  Result.BaseFormID := aBaseFormID;
  Result.InventoryFormID := aInventoryFormID;
  Result.EnchantmentFormID := aEnchantmentFormID;
  Result.SpellFormID := aSpellFormID;
end;

function xeBuildGameLinkSelection(const aRefID, aBaseID: TwbFormID): TxeGameLinkSelection;
begin
  Result.RefID := aRefID;
  Result.BaseID := aBaseID;
end;

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

function xeGetPluggyUserFilesFolder(const aMyGamesTheGamePath: string): string;
begin
  Result := aMyGamesTheGamePath + 'Pluggy' + PathDelim + 'User Files' + PathDelim;
end;

function xeGetGameLinkFolder(const aDataPath: string): string;
begin
  Result := aDataPath + 'xEdit' + PathDelim;
end;

function xeGetGameLinkFilePath(const aFolder: string): string;
begin
  Result := aFolder + 'xEditLink.ini';
end;

function xeGetGameLinkWatchStamp(const aFolder: string): Int64;
begin
  Result := xeGetFileWriteStampUtc(xeGetGameLinkFilePath(aFolder));
end;

function xeGetPluggyWatchStamp(const aFolder, aAppName: string): Int64;
begin
  Result := xeGetNewestFileWriteStampUtc([
    aFolder + 'Pluggy' + aAppName + 'ViewWorld.csv',
    aFolder + 'Pluggy' + aAppName + 'ViewInventory.csv',
    aFolder + 'Pluggy' + aAppName + 'ViewSpells.csv'
  ]);
end;

function xeConsumeWatchStampChange(var aLastStamp: Int64; const aCurrentStamp: Int64): Boolean;
begin
  Result := (aCurrentStamp >= 0) and (aCurrentStamp <> aLastStamp);
  if Result then
    aLastStamp := aCurrentStamp;
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

function xeTryReadGameLinkSelection(const aFileName: string; out aSelection: TxeGameLinkSelection): Boolean;
var
  lRefID: TwbFormID;
  lBaseID: TwbFormID;
begin
  Result := xeTryReadGameLinkSelection(aFileName, lRefID, lBaseID);
  if not Result then
    Exit;
  aSelection := xeBuildGameLinkSelection(lRefID, lBaseID);
end;

function xeTryReadPluggySelection(const aFolder, aAppName: string;
  out aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID): Boolean;
const
  cViewWorldSuffix = 'ViewWorld.csv';
  cViewInventorySuffix = 'ViewInventory.csv';
  cViewSpellsSuffix = 'ViewSpells.csv';
var
  lFields: TStringList;
  lPrefix: string;
begin
  Result := False;
  aFormID := TwbFormID.Null;
  aBaseFormID := TwbFormID.Null;
  aInventoryFormID := TwbFormID.Null;
  aEnchantmentFormID := TwbFormID.Null;
  aSpellFormID := TwbFormID.Null;

  lPrefix := aFolder + 'Pluggy' + aAppName;
  lFields := TStringList.Create;
  try
    if not xeTryReadLastCsvFields(lPrefix + cViewWorldSuffix, 2, lFields) then
      Exit;
    aFormID := TwbFormID.FromStr(lFields[0]);
    aBaseFormID := TwbFormID.FromStr(lFields[1]);

    if not xeTryReadLastCsvFields(lPrefix + cViewInventorySuffix, 2, lFields) then
      Exit;
    aInventoryFormID := TwbFormID.FromStr(lFields[0]);
    aEnchantmentFormID := TwbFormID.FromStr(lFields[1]);

    if not xeTryReadLastCsvFields(lPrefix + cViewSpellsSuffix, 1, lFields) then
      Exit;
    aSpellFormID := TwbFormID.FromStr(lFields[0]);
  finally
    lFields.Free;
  end;

  Result := True;
end;

function xeTryReadPluggySelection(const aFolder, aAppName: string; out aSelection: TxePluggySelection): Boolean;
var
  lFormID: TwbFormID;
  lBaseFormID: TwbFormID;
  lInventoryFormID: TwbFormID;
  lEnchantmentFormID: TwbFormID;
  lSpellFormID: TwbFormID;
begin
  Result := xeTryReadPluggySelection(
    aFolder,
    aAppName,
    lFormID,
    lBaseFormID,
    lInventoryFormID,
    lEnchantmentFormID,
    lSpellFormID
  );
  if not Result then
    Exit;
  aSelection := xeBuildPluggySelection(lFormID, lBaseFormID, lInventoryFormID, lEnchantmentFormID, lSpellFormID);
end;

function xeHasPluggySelectionChanged(
  const aLastFormID, aLastBaseFormID, aLastInventoryFormID, aLastEnchantmentFormID, aLastSpellFormID: TwbFormID;
  const aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID
): Boolean;
begin
  Result :=
    (aFormID <> aLastFormID) or
    (aBaseFormID <> aLastBaseFormID) or
    (aInventoryFormID <> aLastInventoryFormID) or
    (aEnchantmentFormID <> aLastEnchantmentFormID) or
    (aSpellFormID <> aLastSpellFormID);
end;

function xeHasPluggySelectionChanged(const aLast, aCurrent: TxePluggySelection): Boolean;
begin
  Result := xeHasPluggySelectionChanged(
    aLast.FormID,
    aLast.BaseFormID,
    aLast.InventoryFormID,
    aLast.EnchantmentFormID,
    aLast.SpellFormID,
    aCurrent.FormID,
    aCurrent.BaseFormID,
    aCurrent.InventoryFormID,
    aCurrent.EnchantmentFormID,
    aCurrent.SpellFormID
  );
end;

procedure xeAssignPluggySelection(const aSelection: TxePluggySelection;
  var aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID);
begin
  aFormID := aSelection.FormID;
  aBaseFormID := aSelection.BaseFormID;
  aInventoryFormID := aSelection.InventoryFormID;
  aEnchantmentFormID := aSelection.EnchantmentFormID;
  aSpellFormID := aSelection.SpellFormID;
end;

function xeApplyPluggySelectionIfChanged(
  var aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID;
  const aSelection: TxePluggySelection
): Boolean;
begin
  Result := xeHasPluggySelectionChanged(
    aFormID,
    aBaseFormID,
    aInventoryFormID,
    aEnchantmentFormID,
    aSpellFormID,
    aSelection.FormID,
    aSelection.BaseFormID,
    aSelection.InventoryFormID,
    aSelection.EnchantmentFormID,
    aSelection.SpellFormID
  );
  if not Result then
    Exit;
  xeAssignPluggySelection(aSelection, aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID);
end;

function xeHasGameLinkSelectionChanged(
  const aLastRefID, aLastBaseID, aRefID, aBaseID: TwbFormID
): Boolean;
begin
  Result := (aRefID <> aLastRefID) or (aBaseID <> aLastBaseID);
end;

function xeHasGameLinkSelectionChanged(const aLast, aCurrent: TxeGameLinkSelection): Boolean;
begin
  Result := xeHasGameLinkSelectionChanged(aLast.RefID, aLast.BaseID, aCurrent.RefID, aCurrent.BaseID);
end;

procedure xeAssignGameLinkSelection(const aSelection: TxeGameLinkSelection; var aRefID, aBaseID: TwbFormID);
begin
  aRefID := aSelection.RefID;
  aBaseID := aSelection.BaseID;
end;

function xeApplyGameLinkSelectionIfChanged(var aRefID, aBaseID: TwbFormID; const aSelection: TxeGameLinkSelection): Boolean;
begin
  if aSelection.RefID.IsNull then
    Exit(False);

  Result := xeHasGameLinkSelectionChanged(aRefID, aBaseID, aSelection.RefID, aSelection.BaseID);
  if not Result then
    Exit;
  xeAssignGameLinkSelection(aSelection, aRefID, aBaseID);
end;

function xeTryUpdatePluggySelection(
  const aFolder, aAppName: string;
  var aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID;
  out aSelection: TxePluggySelection
): Boolean;
begin
  Result := False;
  if not xeTryReadPluggySelection(aFolder, aAppName, aSelection) then
    Exit;
  Result := xeApplyPluggySelectionIfChanged(
    aFormID,
    aBaseFormID,
    aInventoryFormID,
    aEnchantmentFormID,
    aSpellFormID,
    aSelection
  );
end;

function xeTryUpdateGameLinkSelection(
  const aFileName: string;
  var aRefID, aBaseID: TwbFormID;
  out aSelection: TxeGameLinkSelection
): Boolean;
begin
  Result := False;
  if not xeTryReadGameLinkSelection(aFileName, aSelection) then
    Exit;
  Result := xeApplyGameLinkSelectionIfChanged(aRefID, aBaseID, aSelection);
end;

function xeParseLatestXEditVersionFromGitHubJson(const aJsonUtf8: string): TwbVersion;
var
  J: TJsonBaseObject;
  A: TJsonArray;
  i: Integer;
  s: string;
  v: TwbVersion;
begin
  Result := '';
  J := TJsonBaseObject.ParseUtf8(aJsonUtf8);
  try
    if J is TJsonArray then begin
      A := J as TJsonArray;
      for i := 0 to Pred(A.Count) do begin
        s := A.O[i].S['tag_name'];
        if s.StartsWith('xedit-') then begin
          v := Copy(s, Succ(Length('xedit-')), High(Integer));
          if v > Result then
            Result := v;
        end;
      end;
    end;
  finally
    J.Free;
  end;
end;

function xeParseNexusVersionFromHtml(const aHtml: string): TwbVersion;
var
  i: Integer;
  lHtml: string;
const
  csCheckFor = 'property="twitter:label1" content="version"';
  csExtractAfter = 'property="twitter:data1" content="';
begin
  Result := '';
  lHtml := aHtml.ToLowerInvariant;
  if not lHtml.Contains(csCheckFor) then
    Exit;

  i := Pos(csExtractAfter, lHtml);
  if i <= 0 then
    Exit;

  Delete(lHtml, 1, i + Pred(Length(csExtractAfter)));
  i := Pos('"', lHtml);
  if i <= 0 then
    Exit;

  Delete(lHtml, i, High(Integer));
  Result := lHtml;
end;

function xeTryGetLatestXEditVersionFromGitHub(out aVersion: TwbVersion): Boolean;
begin
  Result := False;
  aVersion := '';
  try
    aVersion := xeParseLatestXEditVersionFromGitHubJson(
      GetUrlContent('https://api.github.com/repos/TES5Edit/TES5Edit/releases')
    );
    Result := True;
  except
  end;
end;

function xeTryGetLatestNexusVersion(const aUrl: string; out aVersion: TwbVersion): Boolean;
var
  lHtml: string;
begin
  Result := False;
  aVersion := '';
  if aUrl = '' then
    Exit;

  try
    lHtml := GetUrlContent(aUrl);
    aVersion := xeParseNexusVersionFromHtml(lHtml);
    Result := True;
  except
  end;
end;

end.

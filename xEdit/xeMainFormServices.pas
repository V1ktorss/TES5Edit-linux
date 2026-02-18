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
  TxeRenameModuleFunc = function(const aFrom, aTo: string; aSilent: Boolean): Boolean;
  TxeWatchStampReader = function: Int64 of object;
  TxeWatchStopPredicate = function: Boolean of object;

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
function xeEnsureBackupPath(const aBackupPath, aDataPath: string; const aUseBackup: Boolean): string;
function xeFindAvailablePath(const aInitialPath: string; const aMaxAttempts: Integer = 1000): string;
function xeBuildModuleBackupPath(const aBackupPath, aTargetFileName: string; const aNow: TDateTime): string;
function xeBuildTempSaveBackupPath(const aBackupPath, aFromFileName: string): string;
function xePrepareExistingTargetForRename(
  const aTargetFile, aBackupFile: string;
  const aDeleteInsteadOfBackup: Boolean;
  out aErrorText: string
): Boolean;
function xeTryRestoreModuleWriteTime(
  const aFileName: string;
  const aOldDateTime: TDateTime;
  const aSkipForPluginsTxtOrder: Boolean;
  out aErrorText: string
): Boolean;
function xeTryValidateSourceFileForRename(const aSourceFile: string; out aErrorText: string): Boolean;
function xeTryGetModuleWriteTime(const aFileName: string; out aDateTime: TDateTime; out aErrorText: string): Boolean;
function xeTryRenameFile(const aFromFile, aToFile: string; out aErrorText: string): Boolean;
function xeTryBackupSourceFile(
  const aSourceFile, aSourceName, aBackupPath: string;
  out aBackupFile, aErrorText: string
): Boolean;
procedure xeBuildExistingRenameTargetPlan(
  const aTargetFile, aTargetName, aBackupPath: string;
  const aDeleteInsteadOfBackup: Boolean;
  out aHasExistingTarget: Boolean;
  out aOldDateTime: TDateTime;
  out aBackupFile, aActionText, aWarningText: string
);
function xeTryFinalizeModuleRename(
  const aFromFile, aToFile: string;
  const aOldDateTime: TDateTime;
  const aSkipRestoreForPluginsTxtOrder: Boolean;
  out aErrorText, aWarningText: string
): Boolean;
procedure xeQueueModuleRename(var aFilesToRename: TStringList; const aTargetName, aSourceName: string);
function xeRenameSavedModules(const aFilesToRename: TStrings; const aRenameModule: TxeRenameModuleFunc): Boolean;
function xePopQueuedRenamesForTarget(aFilesToRename: TStrings; const aTargetName: string): TStringDynArray;
function xeGetPluggyUserFilesFolder(const aMyGamesTheGamePath: string): string;
function xeGetGameLinkFolder(const aDataPath: string): string;
function xeGetGameLinkFilePath(const aFolder: string): string;
function xeGetGameLinkWatchStamp(const aFolder: string): Int64;
function xeGetPluggyWatchStamp(const aFolder, aAppName: string): Int64;
function xeConsumeWatchStampChange(var aLastStamp: Int64; const aCurrentStamp: Int64): Boolean;
procedure xeRunWatchStampLoop(
  var aLastStamp: Int64;
  const aPollIntervalMs: Cardinal;
  const aReadStamp: TxeWatchStampReader;
  const aShouldStop: TxeWatchStopPredicate;
  const aOnChange: TNotifyEvent;
  const aSender: TObject
);
function xeTryReadLastCsvFields(const aFileName: string; const aMinFieldCount: Integer; aOut: TStrings): Boolean;
function xeTryReadGameLinkSelection(const aFileName: string; out aSelection: TxeGameLinkSelection): Boolean;
function xeTryReadPluggySelection(const aFolder, aAppName: string; out aSelection: TxePluggySelection): Boolean;
function xeHasPluggySelectionChanged(const aLast, aCurrent: TxePluggySelection): Boolean;
procedure xeAssignPluggySelection(const aSelection: TxePluggySelection;
  var aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID);
function xeApplyPluggySelectionIfChanged(
  var aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID;
  const aSelection: TxePluggySelection
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
function xeGetStaleRefCacheFiles(
  const aCachePath, aAppCrcHex, aRefCacheExt: string
): TStringDynArray;
procedure xeDeleteFilesBestEffort(const aFiles: TStringDynArray);
function xeParseLatestXEditVersionFromGitHubJson(const aJsonUtf8: string): TwbVersion;
function xeParseNexusVersionFromHtml(const aHtml: string): TwbVersion;
function xeTryGetLatestXEditVersionFromGitHub(out aVersion: TwbVersion): Boolean;
function xeTryGetLatestNexusVersion(const aUrl: string; out aVersion: TwbVersion): Boolean;

implementation

function xeTryReadGameLinkSelectionValues(
  const aFileName: string;
  out aSelectedRefID, aSelectedBaseID: TwbFormID
): Boolean;
forward;

function xeTryReadPluggySelectionValues(
  const aFolder, aAppName: string;
  out aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID: TwbFormID
): Boolean;
forward;

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

function xeEnsureBackupPath(const aBackupPath, aDataPath: string; const aUseBackup: Boolean): string;
begin
  Result := aBackupPath;
  if not aUseBackup then
    Exit;
  if not DirectoryExists(Result) and not ForceDirectories(Result) then
    Result := aDataPath;
end;

function xeFindAvailablePath(const aInitialPath: string; const aMaxAttempts: Integer = 1000): string;
var
  lTry: Integer;
begin
  Result := aInitialPath;
  lTry := 1;
  while FileExists(Result) and (lTry < aMaxAttempts) do begin
    Result := aInitialPath + '_' + lTry.ToString;
    Inc(lTry);
  end;
end;

function xeBuildModuleBackupPath(const aBackupPath, aTargetFileName: string; const aNow: TDateTime): string;
begin
  Result := aBackupPath + ExtractFileName(aTargetFileName) + '.backup.' + FormatDateTime('yyyy_mm_dd_hh_nn_ss', aNow);
  Result := xeFindAvailablePath(Result);
end;

function xeBuildTempSaveBackupPath(const aBackupPath, aFromFileName: string): string;
begin
  Result := aBackupPath + aFromFileName.Replace('.save.', '.backup.');
  Result := xeFindAvailablePath(Result);
end;

function xePrepareExistingTargetForRename(
  const aTargetFile, aBackupFile: string;
  const aDeleteInsteadOfBackup: Boolean;
  out aErrorText: string
): Boolean;
begin
  if aDeleteInsteadOfBackup then begin
    aErrorText := 'Could not delete "' + aTargetFile + '".';
    Result := SysUtils.DeleteFile(aTargetFile);
    Exit;
  end;

  aErrorText := 'Could not rename "' + aTargetFile + '" to "' + aBackupFile + '".';
  Result := RenameFile(aTargetFile, aBackupFile);
end;

function xeTryRestoreModuleWriteTime(
  const aFileName: string;
  const aOldDateTime: TDateTime;
  const aSkipForPluginsTxtOrder: Boolean;
  out aErrorText: string
): Boolean;
begin
  aErrorText := '';
  if aSkipForPluginsTxtOrder then
    Exit(True);
  if aOldDateTime = 0 then
    Exit(True);
  if not wbIsModule(aFileName) then
    Exit(True);

  try
    TFile.SetLastWriteTime(aFileName, aOldDateTime);
    Result := True;
  except
    aErrorText := 'Could not set last modified time of "' + aFileName + '".';
    Result := False;
  end;
end;

function xeTryValidateSourceFileForRename(const aSourceFile: string; out aErrorText: string): Boolean;
begin
  Result := FileExists(aSourceFile);
  if Result then begin
    aErrorText := '';
    Exit;
  end;
  aErrorText := 'Could not rename "' + aSourceFile + '". File not found.';
end;

function xeTryGetModuleWriteTime(const aFileName: string; out aDateTime: TDateTime; out aErrorText: string): Boolean;
begin
  aDateTime := 0;
  aErrorText := '';
  try
    aDateTime := wbGetLastWriteTime(aFileName);
    Result := True;
  except
    aErrorText := 'Could not get last modified time of "' + aFileName + '".';
    Result := False;
  end;
end;

function xeTryRenameFile(const aFromFile, aToFile: string; out aErrorText: string): Boolean;
begin
  Result := RenameFile(aFromFile, aToFile);
  if Result then begin
    aErrorText := '';
    Exit;
  end;
  aErrorText := 'Could not rename "' + aFromFile + '" to "' + aToFile + '".';
end;

function xeTryBackupSourceFile(
  const aSourceFile, aSourceName, aBackupPath: string;
  out aBackupFile, aErrorText: string
): Boolean;
begin
  aBackupFile := xeBuildTempSaveBackupPath(aBackupPath, aSourceName);
  Result := xeTryRenameFile(aSourceFile, aBackupFile, aErrorText);
end;

procedure xeBuildExistingRenameTargetPlan(
  const aTargetFile, aTargetName, aBackupPath: string;
  const aDeleteInsteadOfBackup: Boolean;
  out aHasExistingTarget: Boolean;
  out aOldDateTime: TDateTime;
  out aBackupFile, aActionText, aWarningText: string
);
begin
  aHasExistingTarget := FileExists(aTargetFile);
  aOldDateTime := 0;
  aBackupFile := '';
  aActionText := '';
  aWarningText := '';
  if not aHasExistingTarget then
    Exit;

  if not xeTryGetModuleWriteTime(aTargetFile, aOldDateTime, aWarningText) then
    aOldDateTime := 0;

  aBackupFile := xeBuildModuleBackupPath(aBackupPath, aTargetName, Now);
  if aDeleteInsteadOfBackup then
    aActionText := 'Deleting "' + aTargetFile + '".'
  else
    aActionText := 'Renaming "' + aTargetFile + '" to "' + aBackupFile + '".';
end;

function xeTryFinalizeModuleRename(
  const aFromFile, aToFile: string;
  const aOldDateTime: TDateTime;
  const aSkipRestoreForPluginsTxtOrder: Boolean;
  out aErrorText, aWarningText: string
): Boolean;
begin
  aWarningText := '';
  Result := xeTryRenameFile(aFromFile, aToFile, aErrorText);
  if not Result then
    Exit;

  xeTryRestoreModuleWriteTime(
    aToFile,
    aOldDateTime,
    aSkipRestoreForPluginsTxtOrder,
    aWarningText
  );
end;

procedure xeQueueModuleRename(var aFilesToRename: TStringList; const aTargetName, aSourceName: string);
begin
  if not Assigned(aFilesToRename) then
    aFilesToRename := TStringList.Create;
  aFilesToRename.AddPair(aTargetName, aSourceName);
end;

function xeRenameSavedModules(const aFilesToRename: TStrings; const aRenameModule: TxeRenameModuleFunc): Boolean;
var
  i: Integer;
begin
  Result := False;
  if not Assigned(aFilesToRename) or not Assigned(aRenameModule) then
    Exit;

  for i := 0 to Pred(aFilesToRename.Count) do
    if not aRenameModule(aFilesToRename.ValueFromIndex[i], aFilesToRename.Names[i], False) then
      Result := True;
end;

function xePopQueuedRenamesForTarget(aFilesToRename: TStrings; const aTargetName: string): TStringDynArray;
var
  i: Integer;
begin
  SetLength(Result, 0);
  if not Assigned(aFilesToRename) then
    Exit;

  for i := Pred(aFilesToRename.Count) downto 0 do
    if SameText(aTargetName, aFilesToRename.Names[i]) then begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := aFilesToRename.ValueFromIndex[i];
      aFilesToRename.Delete(i);
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

procedure xeRunWatchStampLoop(
  var aLastStamp: Int64;
  const aPollIntervalMs: Cardinal;
  const aReadStamp: TxeWatchStampReader;
  const aShouldStop: TxeWatchStopPredicate;
  const aOnChange: TNotifyEvent;
  const aSender: TObject
);
var
  lCurrentStamp: Int64;
begin
  if not Assigned(aReadStamp) or not Assigned(aShouldStop) then
    Exit;

  repeat
    wbSleepMs(aPollIntervalMs);
    lCurrentStamp := aReadStamp;
    if xeConsumeWatchStampChange(aLastStamp, lCurrentStamp) and Assigned(aOnChange) then
      aOnChange(aSender);
  until aShouldStop;
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

function xeTryReadGameLinkSelectionValues(
  const aFileName: string;
  out aSelectedRefID, aSelectedBaseID: TwbFormID
): Boolean;
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
  Result := xeTryReadGameLinkSelectionValues(aFileName, lRefID, lBaseID);
  if not Result then
    Exit;
  aSelection := xeBuildGameLinkSelection(lRefID, lBaseID);
end;

function xeTryReadPluggySelectionValues(
  const aFolder, aAppName: string;
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
  Result := xeTryReadPluggySelectionValues(
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

function xeHasPluggySelectionChanged(const aLast, aCurrent: TxePluggySelection): Boolean;
begin
  Result :=
    (aCurrent.FormID <> aLast.FormID) or
    (aCurrent.BaseFormID <> aLast.BaseFormID) or
    (aCurrent.InventoryFormID <> aLast.InventoryFormID) or
    (aCurrent.EnchantmentFormID <> aLast.EnchantmentFormID) or
    (aCurrent.SpellFormID <> aLast.SpellFormID);
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
    xeBuildPluggySelection(aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID),
    aSelection
  );
  if not Result then
    Exit;
  xeAssignPluggySelection(aSelection, aFormID, aBaseFormID, aInventoryFormID, aEnchantmentFormID, aSpellFormID);
end;

function xeHasGameLinkSelectionChanged(const aLast, aCurrent: TxeGameLinkSelection): Boolean;
begin
  Result := (aCurrent.RefID <> aLast.RefID) or (aCurrent.BaseID <> aLast.BaseID);
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

  Result := xeHasGameLinkSelectionChanged(xeBuildGameLinkSelection(aRefID, aBaseID), aSelection);
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

function xeGetStaleRefCacheFiles(
  const aCachePath, aAppCrcHex, aRefCacheExt: string
): TStringDynArray;
begin
  SetLength(Result, 0);

  if not TDirectory.Exists(aCachePath) then
    Exit;

  if Length(TDirectory.GetFiles(aCachePath, aAppCrcHex + '_*' + aRefCacheExt)) > 0 then
    Exit;

  Result := TDirectory.GetFiles(aCachePath, '*' + aRefCacheExt);
end;

procedure xeDeleteFilesBestEffort(const aFiles: TStringDynArray);
var
  i: Integer;
begin
  for i := Low(aFiles) to High(aFiles) do
    try
      TFile.Delete(aFiles[i]);
    except
      // Keep best-effort semantics for cache cleanup.
    end;
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

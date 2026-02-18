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
  wbLocalization,
  wbStreams,
  wbInterface,
  wbPlatform,
  wbHelpers;

type
  TxeRenameModuleFunc = function(const aFrom, aTo: string; aSilent: Boolean): Boolean;
  TxeBackupModuleFunc = function(const aFrom: string; aSilent: Boolean): Boolean;
  TxeProgressProc = procedure(const aText: string);
  TxeWatchStampReader = function: Int64 of object;
  TxeWatchStopPredicate = function: Boolean of object;
  TxeStopPredicate = function: Boolean;
  TxeNoArgProc = procedure;

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
function xeRequestThreadTerminate(const aThread: TThread): Boolean;
function xeFinalizeBackgroundThread(const aThread: TThread): Boolean;
function xeShouldWaitForLoaderShutdown(
  const aLoaderStarted, aLoaderDone: Boolean;
  var aForceTerminate: Boolean
): Boolean;
procedure xeFinalizeMainFormCloseState(
  var aFiles: TwbFiles;
  var aProgressCallback: TwbProgressCallback;
  const aCheckResult: Integer;
  out aExitCode: Integer
);
function xePrepareLoaderShutdownWait(
  const aLoaderStarted, aLoaderDone: Boolean;
  var aForceTerminate: Boolean;
  out aCaptionText: string;
  out aPollIntervalMs: Cardinal
): Boolean;
procedure xeWaitUntil(
  const aIsDone: TxeStopPredicate;
  const aPumpMessages: TxeNoArgProc;
  const aPollIntervalMs: Cardinal
);
procedure xePersistMainFormLayout(
  const aSettings: TMemIniFile;
  const aFormName: string;
  const aHasNavPanel: Boolean;
  const aNavPanelWidth: Integer;
  const aNavColumnWidths: array of Integer;
  const aWindowState, aLeft, aTop, aWidth, aHeight: Integer
);
function xeGetFileWriteStampUtc(const aFileName: string): Int64;
function xeGetNewestFileWriteStampUtc(const aFileNames: array of string): Int64;
function xeTryCleanupTempPath(const aTempPath: string; const aRemoveTempPath: Boolean): Boolean;
function xeEnsureBackupPath(const aBackupPath, aDataPath: string; const aUseBackup: Boolean): string;
function xeTryPrepareSourceFileForRename(
  const aDataPath, aSourceName, aBackupPath: string;
  const aUseBackup: Boolean;
  out aResolvedBackupPath, aSourceFile, aErrorText: string
): Boolean;
function xeBuildSaveStartMessage(const aRelativeName: string): string;
function xeBuildSaveErrorMessage(const aRelativeName, aErrorText: string): string;
function xeBuildElapsedLogLine(const aStartTime: TDateTime; const aMessage: string): string;
function xeBuildRenameActionMessage(const aFromFile, aToFile: string): string;
function xeTryPrepareSaveWriteTarget(
  const aFullPath, aRelativeName: string;
  out aStartMessage, aErrorText: string
): Boolean;
function xeBuildSaveUnhandledExceptionMessage(
  const aElapsed: TDateTime;
  const aExceptionClassName, aExceptionMessage: string
): string;
function xeBuildSaveFailureSummaryMessage(const aElapsed: TDateTime): string;
function xeBuildSaveSuccessSummaryMessage(const aElapsed: TDateTime): string;
function xeResolveSaveResult(
  const aElapsed: TDateTime;
  const aAnyErrors, aSavedAny: Boolean;
  out aFailureMessage, aSuccessMessage: string
): TwbSaveResult;
function xeBuildRenameFailuresDialogMessage(const aDataPath: string): string;
function xeBuildRenameBatchOutcome(
  const aAnyError, aSaveProgress, aHasMainForm: Boolean;
  const aDataPath: string;
  out aDialogMessage: string;
  out aShouldSaveLogs: Boolean
): Boolean;
procedure xeBeginShutdownRename(out aInitialAction: string);
procedure xeEndShutdownRename;
function xeRunShutdownRenameBatch(
  const aFilesToRename: TStrings;
  const aRenameModule: TxeRenameModuleFunc;
  const aSaveProgress, aHasMainForm: Boolean;
  const aDataPath: string;
  out aDialogMessage: string;
  out aShouldSaveLogs: Boolean
): Boolean;
function xeCollectRenamePreparationMessages(
  const aActionText, aWarningText: string;
  out aHasAction, aHasWarning: Boolean
): Boolean;
function xeTryPrepareShutdownRename(
  const aDontSave: Boolean;
  const aFilesToRename: TStrings;
  const aDataPath, aBackupPath: string;
  const aUseBackup: Boolean;
  out aResolvedBackupPath, aActionText: string
): Boolean;
function xeTryPrepareShutdownRenameFlow(
  const aDontSave: Boolean;
  const aFilesToRename: TStrings;
  const aDataPath: string;
  var aBackupPath: string;
  const aUseBackup: Boolean;
  out aActionText: string
): Boolean;
function xeBuildTempSaveSuffix(const aNow: TDateTime): string;
function xeTryEnsureParentDirectoryForFile(const aFullPath: string; out aErrorText: string): Boolean;
procedure xeBuildSaveTargetFileName(
  const aDataPath, aOriginalName, aSuffix: string;
  out aTargetName: string;
  out aNeedsRename: Boolean
);
procedure xePrepareLocalizationSaveNames(
  const aDataPath, aLocalizationFileName, aSuffix: string;
  out aOriginalRelativeName, aTargetRelativeName: string;
  out aNeedsRename: Boolean
);
procedure xePrepareModuleSaveNames(
  const aDataPath, aModuleFileNameOnDisk, aSuffix: string;
  out aOriginalRelativeName, aTargetRelativeName: string;
  out aNeedsRename: Boolean
);
function xeTryDiscardUnchangedTempSave(
  const aDataPath, aTempName: string;
  const aOriginalCRC, aCurrentCRC: TwbCRC32;
  var aNeedsRename, aTryDirectRename, aSavedThisOne: Boolean;
  out aInfoText: string
): Boolean;
function xeFinalizeModuleTempSaveOutcome(
  const aDataPath, aTempName: string;
  const aOriginalCRC, aCurrentCRC: TwbCRC32;
  var aNeedsRename, aTryDirectRename, aSavedThisOne, aSavedAny: Boolean;
  out aDiscardInfo: string
): Boolean;
procedure xeMarkDirectRenameCapability(
  const aIsMemoryMapped: Boolean;
  var aTryDirectRename: Boolean
);
function xeTryWriteModuleToTempFile(
  const aFile: IwbFile;
  const aFullPath: string;
  const aResetModified: TwbResetModified;
  out aCanTryDirectRename: Boolean;
  out aErrorText: string
): Boolean;
function xeTryWriteLocalizationToTempFile(
  const aFile: TwbLocalizationFile;
  const aFullPath: string;
  out aErrorText: string
): Boolean;
function xeTrySaveLocalizationToTemp(
  const aFile: TwbLocalizationFile;
  const aFullPath: string;
  var aSavedAny, aSavedThisOne, aTryDirectRename: Boolean;
  out aErrorText: string
): Boolean;
function xeTrySaveLocalizationEntry(
  const aFile: TwbLocalizationFile;
  const aDataPath, aLocalizationFileName, aSuffix: string;
  var aSavedAny, aSavedThisOne, aTryDirectRename, aNeedsRename, aAnyErrors: Boolean;
  out aOriginalName, aTempName, aStartMessage, aResultMessage: string
): Boolean;
function xeTrySaveModuleEntry(
  const aFile: IwbFile;
  const aDataPath, aModuleFileNameOnDisk, aSuffix: string;
  const aResetModified: TwbResetModified;
  var aSavedAny, aSavedThisOne, aTryDirectRename, aNeedsRename, aAnyErrors: Boolean;
  out aOriginalName, aTempName, aStartMessage, aResultMessage: string
): Boolean;
procedure xeMarkTempSaveWriteFailure(
  const aDataPath, aTempName: string;
  var aAnyErrors, aNeedsRename: Boolean
);
procedure xeMarkSaveWriteFailure(
  const aDataPath, aTempName: string;
  var aAnyErrors, aNeedsRename, aSavedThisOne: Boolean
);
function xeHandleSaveWriteException(
  const aDataPath, aTempName, aErrorText: string;
  var aAnyErrors, aNeedsRename, aSavedThisOne: Boolean
): string;
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
procedure xeBuildBackupModuleTempSavePlan(
  const aSourceFile, aSourceName, aBackupPath: string;
  out aBackupFile, aActionText: string
);
function xeTryRunBackupModuleFlow(
  const aDataPath, aFromName, aBackupPath: string;
  const aUseBackup: Boolean;
  out aResolvedBackupPath, aActionText, aErrorText: string
): Boolean;
procedure xeBuildExistingRenameTargetPlan(
  const aTargetFile, aTargetName, aBackupPath: string;
  const aDeleteInsteadOfBackup: Boolean;
  out aHasExistingTarget: Boolean;
  out aOldDateTime: TDateTime;
  out aBackupFile, aActionText, aWarningText: string
);
function xeTryHandleExistingRenameTarget(
  const aTargetFile, aTargetName, aBackupPath: string;
  const aDeleteInsteadOfBackup: Boolean;
  out aOldDateTime: TDateTime;
  out aActionText, aWarningText, aErrorText: string
): Boolean;
function xeTryFinalizeModuleRename(
  const aFromFile, aToFile: string;
  const aOldDateTime: TDateTime;
  const aSkipRestoreForPluginsTxtOrder: Boolean;
  out aErrorText, aWarningText: string
): Boolean;
function xeTryRunModuleRenameFlow(
  const aDataPath, aFromName, aToName, aBackupPath: string;
  const aUseBackup, aDeleteInsteadOfBackup, aSkipRestoreForPluginsTxtOrder: Boolean;
  out aResolvedBackupPath, aActionText, aPreWarningText, aRenameActionText, aPostWarningText, aErrorText: string
): Boolean;
procedure xeQueueModuleRename(var aFilesToRename: TStringList; const aTargetName, aSourceName: string);
function xeRenameSavedModules(const aFilesToRename: TStrings; const aRenameModule: TxeRenameModuleFunc): Boolean;
function xePopQueuedRenamesForTarget(aFilesToRename: TStrings; const aTargetName: string): TStringDynArray;
procedure xeProcessQueuedRenamesAfterDirectSave(
  aFilesToRename: TStrings;
  const aTargetName: string;
  const aDeleteInsteadOfBackup: Boolean;
  var aBackupWarningGiven: Boolean;
  const aSilent: Boolean;
  const aDataPath: string;
  const aBackupModule: TxeBackupModuleFunc;
  const aProgress: TxeProgressProc
);
procedure xeHandleDirectRenameAttempt(
  const aTryDirectRename: Boolean;
  var aNeedsRename: Boolean;
  const aFromTempName, aToFinalName: string;
  const aRenameModule: TxeRenameModuleFunc;
  var aAnyErrors: Boolean;
  const aProgress: TxeProgressProc
);
procedure xeFinalizeSavedModuleRenameFlow(
  var aFilesToRename: TStringList;
  const aFromTempName, aToFinalName, aDataPath: string;
  var aNeedsRename: Boolean;
  const aTryDirectRename: Boolean;
  const aDeleteInsteadOfBackup: Boolean;
  const aSilent: Boolean;
  var aAnyErrors, aBackupWarningGiven: Boolean;
  const aRenameModule: TxeRenameModuleFunc;
  const aBackupModule: TxeBackupModuleFunc;
  const aProgress: TxeProgressProc
);
procedure xeFinalizeSavedModuleRenameFlowIfSaved(
  const aSavedThisOne: Boolean;
  var aFilesToRename: TStringList;
  const aFromTempName, aToFinalName, aDataPath: string;
  var aNeedsRename: Boolean;
  const aTryDirectRename: Boolean;
  const aDeleteInsteadOfBackup: Boolean;
  const aSilent: Boolean;
  var aAnyErrors, aBackupWarningGiven: Boolean;
  const aRenameModule: TxeRenameModuleFunc;
  const aBackupModule: TxeBackupModuleFunc;
  const aProgress: TxeProgressProc
);
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

uses
  JsonDataObjects;

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

function xeRequestThreadTerminate(const aThread: TThread): Boolean;
begin
  Result := Assigned(aThread);
  if Result then
    aThread.Terminate;
end;

function xeFinalizeBackgroundThread(const aThread: TThread): Boolean;
begin
  Result := False;
  if not Assigned(aThread) then
    Exit;

  if aThread.Finished then begin
    Result := True;
    Exit;
  end;

  wbForceTerminateThread(aThread.Handle);
end;

function xeShouldWaitForLoaderShutdown(
  const aLoaderStarted, aLoaderDone: Boolean;
  var aForceTerminate: Boolean
): Boolean;
begin
  Result := aLoaderStarted and (not aLoaderDone);
  if Result then
    aForceTerminate := True;
end;

procedure xeFinalizeMainFormCloseState(
  var aFiles: TwbFiles;
  var aProgressCallback: TwbProgressCallback;
  const aCheckResult: Integer;
  out aExitCode: Integer
);
begin
  aFiles := nil;
  aProgressCallback := nil;
  aExitCode := aCheckResult;
end;

function xePrepareLoaderShutdownWait(
  const aLoaderStarted, aLoaderDone: Boolean;
  var aForceTerminate: Boolean;
  out aCaptionText: string;
  out aPollIntervalMs: Cardinal
): Boolean;
begin
  aCaptionText := 'Waiting for Background Loader to terminate...';
  aPollIntervalMs := 100;
  Result := xeShouldWaitForLoaderShutdown(aLoaderStarted, aLoaderDone, aForceTerminate);
end;

procedure xeWaitUntil(
  const aIsDone: TxeStopPredicate;
  const aPumpMessages: TxeNoArgProc;
  const aPollIntervalMs: Cardinal
);
begin
  if not Assigned(aIsDone) then
    Exit;

  while not aIsDone do begin
    if Assigned(aPumpMessages) then
      aPumpMessages;
    wbSleepMs(aPollIntervalMs);
  end;
end;

procedure xePersistMainFormLayout(
  const aSettings: TMemIniFile;
  const aFormName: string;
  const aHasNavPanel: Boolean;
  const aNavPanelWidth: Integer;
  const aNavColumnWidths: array of Integer;
  const aWindowState, aLeft, aTop, aWidth, aHeight: Integer
);
var
  i: Integer;
begin
  if not Assigned(aSettings) then
    Exit;

  if aHasNavPanel then
    aSettings.WriteInteger(aFormName, 'pnlNavWidth', aNavPanelWidth);

  for i := Low(aNavColumnWidths) to High(aNavColumnWidths) do
    aSettings.WriteInteger(aFormName, 'vstNavColumnWidth' + i.ToString, aNavColumnWidths[i]);

  aSettings.WriteInteger(aFormName, 'WindowState', aWindowState);
  aSettings.WriteInteger(aFormName, 'Left', aLeft);
  aSettings.WriteInteger(aFormName, 'Top', aTop);
  aSettings.WriteInteger(aFormName, 'Width', aWidth);
  aSettings.WriteInteger(aFormName, 'Height', aHeight);
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

function xeTryCleanupTempPath(const aTempPath: string; const aRemoveTempPath: Boolean): Boolean;
begin
  Result := False;
  if not aRemoveTempPath then
    Exit;
  if not DirectoryExists(aTempPath) then
    Exit;

  try
    DeleteDirectory(aTempPath);
    Result := True;
  except
    Result := False;
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

function xeTryPrepareSourceFileForRename(
  const aDataPath, aSourceName, aBackupPath: string;
  const aUseBackup: Boolean;
  out aResolvedBackupPath, aSourceFile, aErrorText: string
): Boolean;
begin
  aResolvedBackupPath := xeEnsureBackupPath(aBackupPath, aDataPath, aUseBackup);
  aSourceFile := aDataPath + aSourceName;
  Result := xeTryValidateSourceFileForRename(aSourceFile, aErrorText);
end;

function xeBuildSaveStartMessage(const aRelativeName: string): string;
begin
  Result := 'Saving: ' + aRelativeName;
end;

function xeBuildSaveErrorMessage(const aRelativeName, aErrorText: string): string;
begin
  Result := 'Error saving ' + aRelativeName + ': ' + aErrorText;
end;

function xeBuildElapsedLogLine(const aStartTime: TDateTime; const aMessage: string): string;
begin
  Result := '[' + wbFormatElapsedTime(Now - aStartTime) + '] ' + aMessage;
end;

function xeBuildRenameActionMessage(const aFromFile, aToFile: string): string;
begin
  Result := 'Renaming "' + aFromFile + '" to "' + aToFile + '".';
end;

function xeTryPrepareSaveWriteTarget(
  const aFullPath, aRelativeName: string;
  out aStartMessage, aErrorText: string
): Boolean;
begin
  Result := xeTryEnsureParentDirectoryForFile(aFullPath, aErrorText);
  if not Result then begin
    aStartMessage := '';
    Exit;
  end;
  aStartMessage := xeBuildSaveStartMessage(aRelativeName);
end;

function xeBuildSaveUnhandledExceptionMessage(
  const aElapsed: TDateTime;
  const aExceptionClassName, aExceptionMessage: string
): string;
begin
  Result := '[' + wbFormatElapsedTime(aElapsed) + '] Error "' + aExceptionClassName + '": "' + aExceptionMessage + '"';
end;

function xeBuildSaveFailureSummaryMessage(const aElapsed: TDateTime): string;
begin
  Result := '[' + wbFormatElapsedTime(aElapsed) + '] Errors have occured. At least one file was not saved.';
end;

function xeBuildSaveSuccessSummaryMessage(const aElapsed: TDateTime): string;
begin
  Result := '[' + wbFormatElapsedTime(aElapsed) + '] Done saving.';
end;

function xeResolveSaveResult(
  const aElapsed: TDateTime;
  const aAnyErrors, aSavedAny: Boolean;
  out aFailureMessage, aSuccessMessage: string
): TwbSaveResult;
begin
  aFailureMessage := '';
  aSuccessMessage := '';
  Result := srNothingToDo;

  if aAnyErrors then
    aFailureMessage := xeBuildSaveFailureSummaryMessage(aElapsed);
  if aSavedAny then begin
    aSuccessMessage := xeBuildSaveSuccessSummaryMessage(aElapsed);
    Result := srAllDone;
  end;
  if aAnyErrors then
    Result := srError;
end;

function xeBuildRenameFailuresDialogMessage(const aDataPath: string): string;
begin
  Result :=
    'One or more errors occured during renaming of saved modules.' + #13#13 +
    'Please check the files in your data path: ' + aDataPath;
end;

function xeBuildRenameBatchOutcome(
  const aAnyError, aSaveProgress, aHasMainForm: Boolean;
  const aDataPath: string;
  out aDialogMessage: string;
  out aShouldSaveLogs: Boolean
): Boolean;
begin
  aDialogMessage := '';
  aShouldSaveLogs := False;
  Result := aAnyError;
  if not Result then
    Exit;

  aDialogMessage := xeBuildRenameFailuresDialogMessage(aDataPath);
  aShouldSaveLogs := aSaveProgress and aHasMainForm;
end;

procedure xeBeginShutdownRename(out aInitialAction: string);
begin
  wbForceTerminate := False;
  wbShowStartTime := 1;
  wbStartTime := Now;
  wbCurrentTick := GetTickCount64;
  aInitialAction := 'Closing files';
  wbCurrentAction := aInitialAction;
end;

procedure xeEndShutdownRename;
begin
  wbCurrentAction := '';
end;

function xeRunShutdownRenameBatch(
  const aFilesToRename: TStrings;
  const aRenameModule: TxeRenameModuleFunc;
  const aSaveProgress, aHasMainForm: Boolean;
  const aDataPath: string;
  out aDialogMessage: string;
  out aShouldSaveLogs: Boolean
): Boolean;
var
  lAnyError: Boolean;
begin
  lAnyError := xeRenameSavedModules(aFilesToRename, aRenameModule);
  Result := xeBuildRenameBatchOutcome(
    lAnyError,
    aSaveProgress,
    aHasMainForm,
    aDataPath,
    aDialogMessage,
    aShouldSaveLogs
  );
end;

function xeCollectRenamePreparationMessages(
  const aActionText, aWarningText: string;
  out aHasAction, aHasWarning: Boolean
): Boolean;
begin
  aHasAction := aActionText <> '';
  aHasWarning := aWarningText <> '';
  Result := aHasAction or aHasWarning;
end;

function xeTryPrepareShutdownRename(
  const aDontSave: Boolean;
  const aFilesToRename: TStrings;
  const aDataPath, aBackupPath: string;
  const aUseBackup: Boolean;
  out aResolvedBackupPath, aActionText: string
): Boolean;
begin
  aResolvedBackupPath := aBackupPath;
  aActionText := '';
  if aDontSave then
    Exit(False);
  if not Assigned(aFilesToRename) then
    Exit(False);

  aResolvedBackupPath := xeEnsureBackupPath(aBackupPath, aDataPath, aUseBackup);
  aActionText := 'Renaming previously saved files';
  Result := True;
end;

function xeTryPrepareShutdownRenameFlow(
  const aDontSave: Boolean;
  const aFilesToRename: TStrings;
  const aDataPath: string;
  var aBackupPath: string;
  const aUseBackup: Boolean;
  out aActionText: string
): Boolean;
begin
  wbFileForceClosed;
  Result := xeTryPrepareShutdownRename(
    aDontSave,
    aFilesToRename,
    aDataPath,
    aBackupPath,
    aUseBackup,
    aBackupPath,
    aActionText
  );
  if Result then
    wbCurrentAction := aActionText;
end;

function xeBuildTempSaveSuffix(const aNow: TDateTime): string;
begin
  Result := '.save.' + FormatDateTime('yyyy_mm_dd_hh_nn_ss', aNow);
end;

function xeTryEnsureParentDirectoryForFile(const aFullPath: string; out aErrorText: string): Boolean;
begin
  aErrorText := '';
  try
    ForceDirectories(ExtractFilePath(aFullPath));
    Result := True;
  except
    on E: Exception do begin
      aErrorText := E.Message;
      Result := False;
    end;
  end;
end;

procedure xeBuildSaveTargetFileName(
  const aDataPath, aOriginalName, aSuffix: string;
  out aTargetName: string;
  out aNeedsRename: Boolean
);
var
  j: Integer;
begin
  aTargetName := aOriginalName;
  aNeedsRename := FileExists(aDataPath + aOriginalName);
  if not aNeedsRename then
    Exit;

  aTargetName := aOriginalName + aSuffix;
  j := 0;
  while FileExists(aDataPath + aTargetName) do begin
    Inc(j);
    aTargetName := aOriginalName + aSuffix + '_' + j.ToString;
  end;
end;

procedure xePrepareLocalizationSaveNames(
  const aDataPath, aLocalizationFileName, aSuffix: string;
  out aOriginalRelativeName, aTargetRelativeName: string;
  out aNeedsRename: Boolean
);
begin
  aOriginalRelativeName := Copy(aLocalizationFileName, Length(aDataPath) + 1, Length(aLocalizationFileName));
  aTargetRelativeName := aOriginalRelativeName;
  xeBuildSaveTargetFileName(aDataPath, aOriginalRelativeName, aSuffix, aTargetRelativeName, aNeedsRename);
end;

procedure xePrepareModuleSaveNames(
  const aDataPath, aModuleFileNameOnDisk, aSuffix: string;
  out aOriginalRelativeName, aTargetRelativeName: string;
  out aNeedsRename: Boolean
);
begin
  aOriginalRelativeName := aModuleFileNameOnDisk;
  aTargetRelativeName := aOriginalRelativeName;
  xeBuildSaveTargetFileName(aDataPath, aOriginalRelativeName, aSuffix, aTargetRelativeName, aNeedsRename);
end;

function xeTryDiscardUnchangedTempSave(
  const aDataPath, aTempName: string;
  const aOriginalCRC, aCurrentCRC: TwbCRC32;
  var aNeedsRename, aTryDirectRename, aSavedThisOne: Boolean;
  out aInfoText: string
): Boolean;
begin
  aInfoText := '';
  Result := aNeedsRename and (aOriginalCRC = aCurrentCRC);
  if not Result then
    Exit;

  DeleteFile(aDataPath + aTempName);
  aNeedsRename := False;
  aTryDirectRename := False;
  aSavedThisOne := False;
  aInfoText := 'File has not changed, removing: ' + aTempName;
end;

function xeFinalizeModuleTempSaveOutcome(
  const aDataPath, aTempName: string;
  const aOriginalCRC, aCurrentCRC: TwbCRC32;
  var aNeedsRename, aTryDirectRename, aSavedThisOne, aSavedAny: Boolean;
  out aDiscardInfo: string
): Boolean;
begin
  Result := xeTryDiscardUnchangedTempSave(
    aDataPath,
    aTempName,
    aOriginalCRC,
    aCurrentCRC,
    aNeedsRename,
    aTryDirectRename,
    aSavedThisOne,
    aDiscardInfo
  );
  if aSavedThisOne then
    aSavedAny := True;
end;

procedure xeMarkDirectRenameCapability(
  const aIsMemoryMapped: Boolean;
  var aTryDirectRename: Boolean
);
begin
  if not aIsMemoryMapped then
    aTryDirectRename := True;
end;

function xeTryWriteModuleToTempFile(
  const aFile: IwbFile;
  const aFullPath: string;
  const aResetModified: TwbResetModified;
  out aCanTryDirectRename: Boolean;
  out aErrorText: string
): Boolean;
var
  lFileStream: TBufferedFileStream;
begin
  aCanTryDirectRename := False;
  aErrorText := '';
  Result := False;

  lFileStream := TBufferedFileStream.Create(aFullPath, fmCreate, 1024 * 1024);
  try
    aFile.WriteToStream(lFileStream, aResetModified);
    xeMarkDirectRenameCapability(fsMemoryMapped in aFile.FileStates, aCanTryDirectRename);
    Result := True;
  except
    on E: Exception do
      aErrorText := E.Message;
  end;
  lFileStream.Free;
end;

function xeTryWriteLocalizationToTempFile(
  const aFile: TwbLocalizationFile;
  const aFullPath: string;
  out aErrorText: string
): Boolean;
var
  lFileStream: TBufferedFileStream;
begin
  aErrorText := '';
  Result := False;

  lFileStream := TBufferedFileStream.Create(aFullPath, fmCreate, 1024 * 1024);
  try
    aFile.WriteToStream(lFileStream);
    aFile.Modified := False;
    Result := True;
  except
    on E: Exception do
      aErrorText := E.Message;
  end;
  lFileStream.Free;
end;

function xeTrySaveLocalizationToTemp(
  const aFile: TwbLocalizationFile;
  const aFullPath: string;
  var aSavedAny, aSavedThisOne, aTryDirectRename: Boolean;
  out aErrorText: string
): Boolean;
begin
  aSavedThisOne := xeTryWriteLocalizationToTempFile(aFile, aFullPath, aErrorText);
  Result := aSavedThisOne;
  if not Result then
    Exit;
  aSavedAny := True;
  xeMarkDirectRenameCapability(False, aTryDirectRename);
end;

function xeTrySaveLocalizationEntry(
  const aFile: TwbLocalizationFile;
  const aDataPath, aLocalizationFileName, aSuffix: string;
  var aSavedAny, aSavedThisOne, aTryDirectRename, aNeedsRename, aAnyErrors: Boolean;
  out aOriginalName, aTempName, aStartMessage, aResultMessage: string
): Boolean;
var
  lErrorText: string;
begin
  aStartMessage := '';
  aResultMessage := '';

  xePrepareLocalizationSaveNames(
    aDataPath,
    aLocalizationFileName,
    aSuffix,
    aOriginalName,
    aTempName,
    aNeedsRename
  );

  if not xeTryPrepareSaveWriteTarget(aDataPath + aTempName, aTempName, aStartMessage, lErrorText) then begin
    aResultMessage := xeHandleSaveWriteException(
      aDataPath,
      aTempName,
      lErrorText,
      aAnyErrors,
      aNeedsRename,
      aSavedThisOne
    );
    Exit(False);
  end;

  Result := xeTrySaveLocalizationToTemp(
    aFile,
    aDataPath + aTempName,
    aSavedAny,
    aSavedThisOne,
    aTryDirectRename,
    lErrorText
  );
  if Result then
    Exit;

  aResultMessage := xeHandleSaveWriteException(
    aDataPath,
    aTempName,
    lErrorText,
    aAnyErrors,
    aNeedsRename,
    aSavedThisOne
  );
end;

function xeTrySaveModuleEntry(
  const aFile: IwbFile;
  const aDataPath, aModuleFileNameOnDisk, aSuffix: string;
  const aResetModified: TwbResetModified;
  var aSavedAny, aSavedThisOne, aTryDirectRename, aNeedsRename, aAnyErrors: Boolean;
  out aOriginalName, aTempName, aStartMessage, aResultMessage: string
): Boolean;
var
  lErrorText: string;
  lOriginalCRC: TwbCRC32;
begin
  aStartMessage := '';
  aResultMessage := '';

  xePrepareModuleSaveNames(
    aDataPath,
    aModuleFileNameOnDisk,
    aSuffix,
    aOriginalName,
    aTempName,
    aNeedsRename
  );

  lOriginalCRC := aFile.CRC32;

  if not xeTryPrepareSaveWriteTarget(aDataPath + aTempName, aTempName, aStartMessage, lErrorText) then begin
    aResultMessage := xeHandleSaveWriteException(
      aDataPath,
      aTempName,
      lErrorText,
      aAnyErrors,
      aNeedsRename,
      aSavedThisOne
    );
    Exit(False);
  end;

  if not xeTryWriteModuleToTempFile(
    aFile,
    aDataPath + aTempName,
    aResetModified,
    aTryDirectRename,
    lErrorText
  ) then begin
    aResultMessage := xeHandleSaveWriteException(
      aDataPath,
      aTempName,
      lErrorText,
      aAnyErrors,
      aNeedsRename,
      aSavedThisOne
    );
    Exit(False);
  end;

  aSavedThisOne := True;
  xeFinalizeModuleTempSaveOutcome(
    aDataPath,
    aTempName,
    lOriginalCRC,
    aFile.CRC32,
    aNeedsRename,
    aTryDirectRename,
    aSavedThisOne,
    aSavedAny,
    aResultMessage
  );
  Result := True;
end;

procedure xeMarkTempSaveWriteFailure(
  const aDataPath, aTempName: string;
  var aAnyErrors, aNeedsRename: Boolean
);
begin
  DeleteFile(aDataPath + aTempName);
  aAnyErrors := True;
  aNeedsRename := False;
end;

procedure xeMarkSaveWriteFailure(
  const aDataPath, aTempName: string;
  var aAnyErrors, aNeedsRename, aSavedThisOne: Boolean
);
begin
  xeMarkTempSaveWriteFailure(aDataPath, aTempName, aAnyErrors, aNeedsRename);
  aSavedThisOne := False;
end;

function xeHandleSaveWriteException(
  const aDataPath, aTempName, aErrorText: string;
  var aAnyErrors, aNeedsRename, aSavedThisOne: Boolean
): string;
begin
  xeMarkSaveWriteFailure(aDataPath, aTempName, aAnyErrors, aNeedsRename, aSavedThisOne);
  Result := xeBuildSaveErrorMessage(aTempName, aErrorText);
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

procedure xeBuildBackupModuleTempSavePlan(
  const aSourceFile, aSourceName, aBackupPath: string;
  out aBackupFile, aActionText: string
);
begin
  aBackupFile := xeBuildTempSaveBackupPath(aBackupPath, aSourceName);
  aActionText := xeBuildRenameActionMessage(aSourceFile, aBackupFile);
end;

function xeTryRunBackupModuleFlow(
  const aDataPath, aFromName, aBackupPath: string;
  const aUseBackup: Boolean;
  out aResolvedBackupPath, aActionText, aErrorText: string
): Boolean;
var
  lSourceFile: string;
  lBackupFile: string;
begin
  aActionText := '';
  if not xeTryPrepareSourceFileForRename(
    aDataPath,
    aFromName,
    aBackupPath,
    aUseBackup,
    aResolvedBackupPath,
    lSourceFile,
    aErrorText
  ) then
    Exit(False);

  xeBuildBackupModuleTempSavePlan(lSourceFile, aFromName, aResolvedBackupPath, lBackupFile, aActionText);
  Result := xeTryBackupSourceFile(lSourceFile, aFromName, aResolvedBackupPath, lBackupFile, aErrorText);
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

function xeTryHandleExistingRenameTarget(
  const aTargetFile, aTargetName, aBackupPath: string;
  const aDeleteInsteadOfBackup: Boolean;
  out aOldDateTime: TDateTime;
  out aActionText, aWarningText, aErrorText: string
): Boolean;
var
  lHasExistingTarget: Boolean;
  lBackupFile: string;
begin
  xeBuildExistingRenameTargetPlan(
    aTargetFile,
    aTargetName,
    aBackupPath,
    aDeleteInsteadOfBackup,
    lHasExistingTarget,
    aOldDateTime,
    lBackupFile,
    aActionText,
    aWarningText
  );

  if not lHasExistingTarget then
    Exit(True);

  Result := xePrepareExistingTargetForRename(
    aTargetFile,
    lBackupFile,
    aDeleteInsteadOfBackup,
    aErrorText
  );
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

function xeTryRunModuleRenameFlow(
  const aDataPath, aFromName, aToName, aBackupPath: string;
  const aUseBackup, aDeleteInsteadOfBackup, aSkipRestoreForPluginsTxtOrder: Boolean;
  out aResolvedBackupPath, aActionText, aPreWarningText, aRenameActionText, aPostWarningText, aErrorText: string
): Boolean;
var
  lFromFile: string;
  lToFile: string;
  lOldDateTime: TDateTime;
begin
  aActionText := '';
  aPreWarningText := '';
  aRenameActionText := '';
  aPostWarningText := '';
  aErrorText := '';

  if not xeTryPrepareSourceFileForRename(
    aDataPath,
    aFromName,
    aBackupPath,
    aUseBackup,
    aResolvedBackupPath,
    lFromFile,
    aErrorText
  ) then
    Exit(False);

  lToFile := aDataPath + aToName;
  if not xeTryHandleExistingRenameTarget(
    lToFile,
    aToName,
    aResolvedBackupPath,
    aDeleteInsteadOfBackup,
    lOldDateTime,
    aActionText,
    aPreWarningText,
    aErrorText
  ) then
    Exit(False);

  aRenameActionText := xeBuildRenameActionMessage(lFromFile, lToFile);
  Result := xeTryFinalizeModuleRename(
    lFromFile,
    lToFile,
    lOldDateTime,
    aSkipRestoreForPluginsTxtOrder,
    aErrorText,
    aPostWarningText
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

procedure xeProcessQueuedRenamesAfterDirectSave(
  aFilesToRename: TStrings;
  const aTargetName: string;
  const aDeleteInsteadOfBackup: Boolean;
  var aBackupWarningGiven: Boolean;
  const aSilent: Boolean;
  const aDataPath: string;
  const aBackupModule: TxeBackupModuleFunc;
  const aProgress: TxeProgressProc
);
var
  i: Integer;
  lSourceName: string;
  lQueuedRenames: TStringDynArray;
begin
  lQueuedRenames := xePopQueuedRenamesForTarget(aFilesToRename, aTargetName);
  if Length(lQueuedRenames) = 0 then
    Exit;

  if aDeleteInsteadOfBackup and (not aBackupWarningGiven) then begin
    if Assigned(aProgress) then begin
      aProgress('******** WARNING ********');
      aProgress('* Backups are disabled! *');
      aProgress('******** WARNING ********');
    end;
    aBackupWarningGiven := True;
  end;

  for i := Low(lQueuedRenames) to High(lQueuedRenames) do begin
    lSourceName := lQueuedRenames[i];
    if aDeleteInsteadOfBackup then begin
      if Assigned(aProgress) then
        aProgress('Removing previously queued save "' + aDataPath + lSourceName + '" as a direct save to "' + aDataPath + aTargetName + '" has succeeded.');
      DeleteFile(aDataPath + lSourceName);
    end else begin
      if Assigned(aProgress) then
        aProgress('Backing up previously queued save "' + aDataPath + lSourceName + '" as a direct save to "' + aDataPath + aTargetName + '" has succeeded.');
      if Assigned(aBackupModule) then
        aBackupModule(lSourceName, aSilent);
    end;
  end;
end;

procedure xeHandleDirectRenameAttempt(
  const aTryDirectRename: Boolean;
  var aNeedsRename: Boolean;
  const aFromTempName, aToFinalName: string;
  const aRenameModule: TxeRenameModuleFunc;
  var aAnyErrors: Boolean;
  const aProgress: TxeProgressProc
);
begin
  if not (aNeedsRename and aTryDirectRename) then
    Exit;
  if not Assigned(aRenameModule) then
    Exit;

  try
    if not aRenameModule(aFromTempName, aToFinalName, True) then begin
      aAnyErrors := True;
      if Assigned(aProgress) then
        aProgress('Direct save failed. Will queue save for renaming on shutdown.');
    end else
      aNeedsRename := False;
  except
    // Keep prior behavior: ignore exception and keep queued-rename path.
  end;
end;

procedure xeFinalizeSavedModuleRenameFlow(
  var aFilesToRename: TStringList;
  const aFromTempName, aToFinalName, aDataPath: string;
  var aNeedsRename: Boolean;
  const aTryDirectRename: Boolean;
  const aDeleteInsteadOfBackup: Boolean;
  const aSilent: Boolean;
  var aAnyErrors, aBackupWarningGiven: Boolean;
  const aRenameModule: TxeRenameModuleFunc;
  const aBackupModule: TxeBackupModuleFunc;
  const aProgress: TxeProgressProc
);
begin
  xeHandleDirectRenameAttempt(
    aTryDirectRename,
    aNeedsRename,
    aFromTempName,
    aToFinalName,
    aRenameModule,
    aAnyErrors,
    aProgress
  );

  if aNeedsRename then begin
    xeQueueModuleRename(aFilesToRename, aToFinalName, aFromTempName);
    if Assigned(aProgress) then
      aProgress('Queued renaming of save "' + aDataPath + aFromTempName + '" to "' + aDataPath + aToFinalName + '" on shutdown.');
    Exit;
  end;

  xeProcessQueuedRenamesAfterDirectSave(
    aFilesToRename,
    aToFinalName,
    aDeleteInsteadOfBackup,
    aBackupWarningGiven,
    aSilent,
    aDataPath,
    aBackupModule,
    aProgress
  );
end;

procedure xeFinalizeSavedModuleRenameFlowIfSaved(
  const aSavedThisOne: Boolean;
  var aFilesToRename: TStringList;
  const aFromTempName, aToFinalName, aDataPath: string;
  var aNeedsRename: Boolean;
  const aTryDirectRename: Boolean;
  const aDeleteInsteadOfBackup: Boolean;
  const aSilent: Boolean;
  var aAnyErrors, aBackupWarningGiven: Boolean;
  const aRenameModule: TxeRenameModuleFunc;
  const aBackupModule: TxeBackupModuleFunc;
  const aProgress: TxeProgressProc
);
begin
  if not aSavedThisOne then
    Exit;

  xeFinalizeSavedModuleRenameFlow(
    aFilesToRename,
    aFromTempName,
    aToFinalName,
    aDataPath,
    aNeedsRename,
    aTryDirectRename,
    aDeleteInsteadOfBackup,
    aSilent,
    aAnyErrors,
    aBackupWarningGiven,
    aRenameModule,
    aBackupModule,
    aProgress
  );
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
var
  lJson: UTF8String;
begin
  Result := False;
  aVersion := '';
  if not wbTryDownloadUrlUtf8('https://api.github.com/repos/TES5Edit/TES5Edit/releases', lJson) then
    Exit;
  try
    aVersion := xeParseLatestXEditVersionFromGitHubJson(lJson);
    Result := True;
  except
  end;
end;

function xeTryGetLatestNexusVersion(const aUrl: string; out aVersion: TwbVersion): Boolean;
var
  lHtml: UTF8String;
begin
  Result := False;
  aVersion := '';
  if aUrl = '' then
    Exit;
  if not wbTryDownloadUrlUtf8(aUrl, lHtml) then
    Exit;

  try
    aVersion := xeParseNexusVersionFromHtml(lHtml);
    Result := True;
  except
  end;
end;

end.

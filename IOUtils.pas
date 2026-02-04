unit IOUtils;

interface

uses
  SysUtils, Classes;

type
  TSearchOption = (soTopDirectoryOnly, soAllDirectories);
  TStringDynArray = array of string;

  TPath = class
  public
    class function IsRelativePath(const APath: string): Boolean; static;
  end;

  TDirectory = class
  public
    class function GetFiles(const APath, ASearchPattern: string;
      ASearchOption: TSearchOption = soTopDirectoryOnly): TStringDynArray; static;
  end;

implementation

class function TPath.IsRelativePath(const APath: string): Boolean;
begin
  if APath = '' then
    Exit(True);

  if (APath[1] = '/') or (APath[1] = '\') then
    Exit(False);

  if (Length(APath) >= 2) and (APath[2] = ':') then
    Exit(False);

  Result := True;
end;

class function TDirectory.GetFiles(const APath, ASearchPattern: string;
  ASearchOption: TSearchOption): TStringDynArray;
var
  LRoot: string;
  LList: TStringList;
  i: Integer;

  procedure AddMatchesInFolder(const AFolder: string);
  var
    SR: TSearchRec;
    LRes: Integer;
    LSubFolder: string;
  begin
    LRes := FindFirst(IncludeTrailingPathDelimiter(AFolder) + ASearchPattern, faAnyFile, SR);
    try
      while LRes = 0 do
      begin
        if (SR.Name <> '.') and (SR.Name <> '..') and ((SR.Attr and faDirectory) = 0) then
          LList.Add(IncludeTrailingPathDelimiter(AFolder) + SR.Name);
        LRes := FindNext(SR);
      end;
    finally
      FindClose(SR);
    end;

    if ASearchOption = soAllDirectories then
    begin
      LRes := FindFirst(IncludeTrailingPathDelimiter(AFolder) + '*', faDirectory, SR);
      try
        while LRes = 0 do
        begin
          if (SR.Name <> '.') and (SR.Name <> '..') and ((SR.Attr and faDirectory) <> 0) then
          begin
            LSubFolder := IncludeTrailingPathDelimiter(AFolder) + SR.Name;
            AddMatchesInFolder(LSubFolder);
          end;
          LRes := FindNext(SR);
        end;
      finally
        FindClose(SR);
      end;
    end;
  end;

begin
  SetLength(Result, 0);
  LRoot := ExcludeTrailingPathDelimiter(APath);
  LList := TStringList.Create;
  try
    if DirectoryExists(LRoot) then
      AddMatchesInFolder(LRoot);
    SetLength(Result, LList.Count);
    // Manual copy keeps compatibility with older compilers.
    for i := 0 to LList.Count - 1 do
      Result[i] := LList[i];
  finally
    LList.Free;
  end;
end;

end.

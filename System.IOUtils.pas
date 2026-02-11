unit System.IOUtils;

interface

uses
  IOUtils,
  SysUtils,
  Classes;

{$IFDEF FPC}
type
  TStringDynArray = array of string;

  TSearchOption = (soTopDirectoryOnly, soAllDirectories);

  TPath = class
  public
    class function HasExtension(const Path: string): Boolean; static;
  end;

  TFile = class
  public
    class procedure Copy(const SourceFileName, DestFileName: string; Overwrite: Boolean = False); static;
  end;

  TDirectory = class
  public
    class function Exists(const Path: string): Boolean; static;
    class function GetFiles(const Path, SearchPattern: string; SearchOption: TSearchOption): TStringDynArray; static;
  end;
{$ELSE}
type
  TStringDynArray = IOUtils.TStringDynArray;
  TSearchOption = IOUtils.TSearchOption;
  TPath = IOUtils.TPath;
  TFile = IOUtils.TFile;
  TDirectory = IOUtils.TDirectory;
{$ENDIF}

implementation

{$IFDEF FPC}
class function TPath.HasExtension(const Path: string): Boolean;
begin
  Result := ExtractFileExt(Path) <> '';
end;

class procedure TFile.Copy(const SourceFileName, DestFileName: string; Overwrite: Boolean);
var
  SourceStream: TFileStream;
  DestStream: TFileStream;
begin
  if (not Overwrite) and FileExists(DestFileName) then
    raise Exception.Create('Destination file exists: ' + DestFileName);

  SourceStream := TFileStream.Create(SourceFileName, fmOpenRead);
  try
    DestStream := TFileStream.Create(DestFileName, fmCreate);
    try
      DestStream.CopyFrom(SourceStream, 0);
    finally
      DestStream.Free;
    end;
  finally
    SourceStream.Free;
  end;
end;

class function TDirectory.Exists(const Path: string): Boolean;
begin
  Result := DirectoryExists(Path);
end;

class function TDirectory.GetFiles(const Path, SearchPattern: string; SearchOption: TSearchOption): TStringDynArray;
var
  Results: TStringList;

  procedure AddFiles(const Dir: string);
  var
    SR: TSearchRec;
    SearchPath: string;
  begin
    SearchPath := IncludeTrailingPathDelimiter(Dir);
    if FindFirst(SearchPath + SearchPattern, faAnyFile, SR) = 0 then
    try
      repeat
        if (SR.Name <> '.') and (SR.Name <> '..') then
          if (SR.Attr and faDirectory) = 0 then
            Results.Add(SearchPath + SR.Name);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;

    if SearchOption = soAllDirectories then
      if FindFirst(SearchPath + '*', faDirectory, SR) = 0 then
      try
        repeat
          if (SR.Name <> '.') and (SR.Name <> '..') then
            if (SR.Attr and faDirectory) <> 0 then
              AddFiles(SearchPath + SR.Name);
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
  end;

var
  i: Integer;
begin
  Results := TStringList.Create;
  try
    if DirectoryExists(Path) then
      AddFiles(Path);
    SetLength(Result, Results.Count);
    for i := 0 to Results.Count - 1 do
      Result[i] := Results[i];
  finally
    Results.Free;
  end;
end;
{$ENDIF}

end.

unit System.Classes;

interface

uses
  Classes;

type
  TPersistent = Classes.TPersistent;
  TComponent = Classes.TComponent;
  TDataModule = class(TComponent);

  TStream = Classes.TStream;
  TFileStream = Classes.TFileStream;
  TMemoryStream = Classes.TMemoryStream;
  TBytesStream = Classes.TBytesStream;
  TFiler = Classes.TFiler;
  TReader = Classes.TReader;
  TWriter = Classes.TWriter;

  TStrings = Classes.TStrings;
  TStringList = Classes.TStringList;

  TList = Classes.TList;
  TInterfaceList = Classes.TInterfaceList;

  TDuplicates = Classes.TDuplicates;

const
  fmCreate = Classes.fmCreate;
  fmOpenRead = Classes.fmOpenRead;
  fmOpenWrite = Classes.fmOpenWrite;
  fmOpenReadWrite = Classes.fmOpenReadWrite;

  dupIgnore = Classes.dupIgnore;
  dupAccept = Classes.dupAccept;
  dupError = Classes.dupError;

implementation

end.

unit System.SysUtils;

interface

uses
  SysUtils;

type
  TEncoding = SysUtils.TEncoding;
  EAbort = SysUtils.EAbort;
  Exception = SysUtils.Exception;
  TBytes = SysUtils.TBytes;
  TFormatSettings = SysUtils.TFormatSettings;
  TProc = procedure;
  TProc<T> = procedure(const Arg: T);

{$IFDEF FPC}
  TMonitor = class
  public
    class procedure Enter(const Obj: TObject); static;
    class procedure Exit(const Obj: TObject); static;
  end;

  TFunc<T, TResult> = function(const Arg: T): TResult;
{$ENDIF}

function SameText(const S1, S2: string): Boolean; inline;
function Format(const FormatStr: string; const Args: array of const): string; overload; inline;
function Format(const FormatStr: string; const Args: array of const; const FormatSettings: TFormatSettings): string; overload; inline;
function GetTickCount64: QWord; inline;
function Supports(const Instance: IInterface; const IID: TGUID; out Intf): Boolean; overload; inline;
function Supports(const Instance: TObject; const IID: TGUID; out Intf): Boolean; overload; inline;
function Supports(const Instance: TObject; const IID: TGUID): Boolean; overload; inline;
function Supports(const Instance: IInterface; const IID: TGUID): Boolean; overload; inline;
function IntToHex(Value: Integer; Digits: Integer): string; overload; inline;
function IntToHex(Value: Int64; Digits: Integer): string; overload; inline;
function IntToStr(Value: Integer): string; overload; inline;
function IntToStr(Value: Int64): string; overload; inline;

implementation

{$IFDEF FPC}
class procedure TMonitor.Enter(const Obj: TObject);
begin
end;

class procedure TMonitor.Exit(const Obj: TObject);
begin
end;
{$ENDIF}

function SameText(const S1, S2: string): Boolean; inline;
begin
  Result := SysUtils.SameText(S1, S2);
end;

function Format(const FormatStr: string; const Args: array of const): string; overload; inline;
begin
  Result := SysUtils.Format(FormatStr, Args);
end;

function Format(const FormatStr: string; const Args: array of const; const FormatSettings: TFormatSettings): string; overload; inline;
begin
  Result := SysUtils.Format(FormatStr, Args, FormatSettings);
end;

function GetTickCount64: QWord; inline;
begin
  Result := SysUtils.GetTickCount64;
end;

function Supports(const Instance: IInterface; const IID: TGUID; out Intf): Boolean; overload; inline;
begin
  Result := SysUtils.Supports(Instance, IID, Intf);
end;

function Supports(const Instance: TObject; const IID: TGUID; out Intf): Boolean; overload; inline;
begin
  Result := SysUtils.Supports(Instance, IID, Intf);
end;

function Supports(const Instance: TObject; const IID: TGUID): Boolean; overload; inline;
begin
  Result := SysUtils.Supports(Instance, IID);
end;

function Supports(const Instance: IInterface; const IID: TGUID): Boolean; overload; inline;
begin
  Result := SysUtils.Supports(Instance, IID);
end;

function IntToHex(Value: Integer; Digits: Integer): string; overload; inline;
begin
  Result := SysUtils.IntToHex(Value, Digits);
end;

function IntToHex(Value: Int64; Digits: Integer): string; overload; inline;
begin
  Result := SysUtils.IntToHex(Value, Digits);
end;

function IntToStr(Value: Integer): string; overload; inline;
begin
  Result := SysUtils.IntToStr(Value);
end;

function IntToStr(Value: Int64): string; overload; inline;
begin
  Result := SysUtils.IntToStr(Value);
end;

end.

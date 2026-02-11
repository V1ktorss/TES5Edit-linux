unit System.SysUtils;

interface

uses
  SysUtils;

type
  TEncoding = SysUtils.TEncoding;
  EAbort = SysUtils.EAbort;
  TBytes = SysUtils.TBytes;
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

end.

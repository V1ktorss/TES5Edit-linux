unit Threading;

{$if defined(FPC)}
  {$mode delphi}
  {$modeswitch anonymousfunctions}
{$endif}

interface

type
  TParallel = class
  public type
    TLoopState = record
    end;
    TParallelProc = reference to procedure(aIndex: Integer);
    TParallelProcWithState = reference to procedure(aIndex: Integer; aLoopState: TLoopState);
  public
    class procedure &For(aFromInclusive, aToInclusive: Integer; const aProc: TParallelProc); overload; static;
    class procedure &For(aFromInclusive, aToInclusive: Integer; const aProc: TParallelProcWithState); overload; static;
  end;

implementation

class procedure TParallel.&For(aFromInclusive, aToInclusive: Integer; const aProc: TParallelProc);
var
  i: Integer;
begin
  if not Assigned(aProc) then
    Exit;

  for i := aFromInclusive to aToInclusive do
    aProc(i);
end;

class procedure TParallel.&For(aFromInclusive, aToInclusive: Integer; const aProc: TParallelProcWithState);
var
  i: Integer;
  LState: TLoopState;
begin
  if not Assigned(aProc) then
    Exit;

  for i := aFromInclusive to aToInclusive do
    aProc(i, LState);
end;

end.

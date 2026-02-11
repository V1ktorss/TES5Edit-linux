unit System.RegularExpressions;

interface

type
  TRegEx = record
  public
    class function Replace(const Input, Pattern, Replacement: string): string; static;
  end;

implementation

uses
  RegExpr;

class function TRegEx.Replace(const Input, Pattern, Replacement: string): string;
var
  R: TRegExpr;
begin
  R := TRegExpr.Create;
  try
    R.Expression := Pattern;
    Result := R.Replace(Input, Replacement, True);
  finally
    R.Free;
  end;
end;

end.

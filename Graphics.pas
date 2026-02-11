unit Graphics;

interface

uses
  Types;

type
  TColor = Longint;
  TRGBTriple = packed record
    rgbtBlue: Byte;
    rgbtGreen: Byte;
    rgbtRed: Byte;
  end;

  TColors = record
  public
    class function Greenyellow: TColor; static; inline;
  end;

const
  clBlack      = TColor($000000);
  clMaroon     = TColor($000080);
  clGreen      = TColor($008000);
  clOlive      = TColor($008080);
  clNavy       = TColor($800000);
  clPurple     = TColor($800080);
  clTeal       = TColor($808000);
  clGray       = TColor($808080);
  clSilver     = TColor($C0C0C0);
  clRed        = TColor($0000FF);
  clLime       = TColor($00FF00);
  clYellow     = TColor($00FFFF);
  clBlue       = TColor($FF0000);
  clFuchsia    = TColor($FF00FF);
  clAqua       = TColor($FFFF00);
  clWhite      = TColor($FFFFFF);

  clDkGray     = TColor($404040);
  clMedGray    = TColor($808080);
  clLtGray     = TColor($C0C0C0);

  clWindow     = TColor($FFFFFF);
  clWindowText = TColor($000000);

  clGreenyellow = TColor($2FFFAD);

  clDefault    = TColor($20000000);

function ColorToRGB(Color: TColor): TColor; inline;

implementation

class function TColors.Greenyellow: TColor;
begin
  Result := TColor($2FFFAD);
end;

function ColorToRGB(Color: TColor): TColor;
begin
  Result := Color;
end;

end.

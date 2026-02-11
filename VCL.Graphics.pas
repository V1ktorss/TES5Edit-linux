unit VCL.Graphics;

interface

uses
  Graphics;

type
  TColor = Graphics.TColor;
  TColors = Graphics.TColors;
  TRGBTriple = Graphics.TRGBTriple;

const
  clBlack      = Graphics.clBlack;
  clMaroon     = Graphics.clMaroon;
  clGreen      = Graphics.clGreen;
  clOlive      = Graphics.clOlive;
  clNavy       = Graphics.clNavy;
  clPurple     = Graphics.clPurple;
  clTeal       = Graphics.clTeal;
  clGray       = Graphics.clGray;
  clSilver     = Graphics.clSilver;
  clRed        = Graphics.clRed;
  clLime       = Graphics.clLime;
  clYellow     = Graphics.clYellow;
  clBlue       = Graphics.clBlue;
  clFuchsia    = Graphics.clFuchsia;
  clAqua       = Graphics.clAqua;
  clWhite      = Graphics.clWhite;

  clDkGray     = Graphics.clDkGray;
  clMedGray    = Graphics.clMedGray;
  clLtGray     = Graphics.clLtGray;

  clWindow     = Graphics.clWindow;
  clWindowText = Graphics.clWindowText;

  clGreenyellow = Graphics.clGreenyellow;

  clDefault    = Graphics.clDefault;

function ColorToRGB(Color: TColor): TColor; inline;

implementation

function ColorToRGB(Color: TColor): TColor;
begin
  Result := Graphics.ColorToRGB(Color);
end;

end.

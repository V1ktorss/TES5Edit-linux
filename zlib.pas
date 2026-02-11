unit zlib;

interface

uses
  Classes;

procedure ZCompressStream(aSrc, aDst: TStream);
procedure ZDecompressStream(aSrc, aDst: TStream);

implementation

uses
  ZlibEx;

procedure ZCompressStream(aSrc, aDst: TStream);
begin
  ZlibEx.ZCompressStream(aSrc, aDst);
end;

procedure ZDecompressStream(aSrc, aDst: TStream);
begin
  ZlibEx.ZDecompressStream(aSrc, aDst);
end;

end.

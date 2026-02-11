unit zlibEx;

interface

uses
  Classes;

procedure ZCompressStream(aSrc, aDst: TStream);
procedure DecompressToUserBuf(aSrc: Pointer; aSrcSize: Integer; aDst: Pointer; aDstSize: Integer);

implementation

uses
  SysUtils, ZStream;

procedure ZCompressStream(aSrc, aDst: TStream);
var
  LComp: TCompressionStream;
begin
  aSrc.Position := 0;
  LComp := TCompressionStream.Create(clDefault, aDst);
  try
    LComp.CopyFrom(aSrc, aSrc.Size - aSrc.Position);
  finally
    LComp.Free;
  end;
end;

procedure DecompressToUserBuf(aSrc: Pointer; aSrcSize: Integer; aDst: Pointer; aDstSize: Integer);
var
  LIn: TMemoryStream;
  LDecomp: TDecompressionStream;
  LReadTotal: Integer;
  LChunk: Integer;
  LCursor: PByte;
begin
  LIn := TMemoryStream.Create;
  try
    if aSrcSize > 0 then
      LIn.WriteBuffer(aSrc^, aSrcSize);
    LIn.Position := 0;

    LDecomp := TDecompressionStream.Create(LIn);
    try
      LReadTotal := 0;
      LCursor := PByte(aDst);
      while LReadTotal < aDstSize do
      begin
        LChunk := LDecomp.Read(LCursor^, aDstSize - LReadTotal);
        if LChunk <= 0 then
          Break;
        Inc(LReadTotal, LChunk);
        Inc(LCursor, LChunk);
      end;
      if LReadTotal <> aDstSize then
        raise Exception.CreateFmt('Decompression size mismatch (%d/%d)', [LReadTotal, aDstSize]);
    finally
      LDecomp.Free;
    end;
  finally
    LIn.Free;
  end;
end;

end.

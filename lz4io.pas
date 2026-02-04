unit lz4io;

interface

uses
  Classes;

procedure lz4CompressStream(aSrc, aDst: TStream);
procedure lz4BlockCompressStream(aSrc, aDst: TStream);
procedure lz4DecompressToUserBuf(aSrc: Pointer; aSrcSize: Integer; aDst: Pointer; aDstSize: Integer);
procedure lz4BlockDecompressToUserBuf(aSrc: Pointer; aSrcSize: Integer; aDst: Pointer; aDstSize: Integer);

implementation

uses
  SysUtils;

type
  size_t = PtrUInt;
  Psize_t = ^size_t;
  LZ4F_errorCode_t = size_t;
  LZ4F_cctx = Pointer;
  LZ4F_dctx = Pointer;
  PLZ4F_cctx = ^LZ4F_cctx;
  PLZ4F_dctx = ^LZ4F_dctx;

  LZ4F_blockSizeID_t = (
    LZ4F_default = 0,
    LZ4F_max64KB = 4,
    LZ4F_max256KB = 5,
    LZ4F_max1MB = 6,
    LZ4F_max4MB = 7
  );

  LZ4F_blockMode_t = (
    LZ4F_blockLinked = 0,
    LZ4F_blockIndependent = 1
  );

  LZ4F_contentChecksum_t = (
    LZ4F_noContentChecksum = 0,
    LZ4F_contentChecksumEnabled = 1
  );

  LZ4F_frameType_t = (
    LZ4F_frame = 0,
    LZ4F_skippableFrame = 1
  );

  LZ4F_blockChecksum_t = (
    LZ4F_noBlockChecksum = 0,
    LZ4F_blockChecksumEnabled = 1
  );

  LZ4F_frameInfo_t = record
    blockSizeID: LZ4F_blockSizeID_t;
    blockMode: LZ4F_blockMode_t;
    contentChecksumFlag: LZ4F_contentChecksum_t;
    frameType: LZ4F_frameType_t;
    contentSize: QWord;
    dictID: Cardinal;
    blockChecksumFlag: LZ4F_blockChecksum_t;
  end;
  PLZ4F_frameInfo_t = ^LZ4F_frameInfo_t;

  LZ4F_preferences_t = record
    frameInfo: LZ4F_frameInfo_t;
    compressionLevel: Integer;
    autoFlush: Cardinal;
    favorDecSpeed: Cardinal;
    reserved: array[0..2] of Cardinal;
  end;
  PLZ4F_preferences_t = ^LZ4F_preferences_t;

  LZ4F_decompressOptions_t = record
    stableDst: Cardinal;
    reserved: array[0..2] of Cardinal;
  end;
  PLZ4F_decompressOptions_t = ^LZ4F_decompressOptions_t;

const
  LZ4F_VERSION = 100;
  LIBLZ4 = 'liblz4.so.1';

function LZ4_compressBound(inputSize: Integer): Integer; cdecl; external LIBLZ4;
function LZ4_compress_default(src, dst: Pointer; srcSize, dstCapacity: Integer): Integer; cdecl; external LIBLZ4;
function LZ4_decompress_safe(src, dst: Pointer; compressedSize, dstCapacity: Integer): Integer; cdecl; external LIBLZ4;

function LZ4F_isError(code: LZ4F_errorCode_t): Cardinal; cdecl; external LIBLZ4;
function LZ4F_getErrorName(code: LZ4F_errorCode_t): PAnsiChar; cdecl; external LIBLZ4;
function LZ4F_createCompressionContext(cctxPtr: PLZ4F_cctx; version: Cardinal): LZ4F_errorCode_t; cdecl; external LIBLZ4;
function LZ4F_freeCompressionContext(cctx: LZ4F_cctx): LZ4F_errorCode_t; cdecl; external LIBLZ4;
function LZ4F_compressFrameBound(srcSize: size_t; prefsPtr: PLZ4F_preferences_t): size_t; cdecl; external LIBLZ4;
function LZ4F_compressFrame(dstBuffer: Pointer; dstCapacity: size_t; srcBuffer: Pointer; srcSize: size_t;
  prefsPtr: PLZ4F_preferences_t): size_t; cdecl; external LIBLZ4;
function LZ4F_createDecompressionContext(dctxPtr: PLZ4F_dctx; version: Cardinal): LZ4F_errorCode_t; cdecl; external LIBLZ4;
function LZ4F_freeDecompressionContext(dctx: LZ4F_dctx): LZ4F_errorCode_t; cdecl; external LIBLZ4;
function LZ4F_decompress(dctx: LZ4F_dctx; dstBuffer: Pointer; dstSizePtr: Psize_t; srcBuffer: Pointer;
  srcSizePtr: Psize_t; dOptPtr: PLZ4F_decompressOptions_t): size_t; cdecl; external LIBLZ4;

procedure LZ4Check(const code: LZ4F_errorCode_t; const msg: string);
begin
  if LZ4F_isError(code) <> 0 then
    raise Exception.CreateFmt('%s: %s', [msg, string(AnsiString(LZ4F_getErrorName(code)))]);
end;

procedure lz4CompressStream(aSrc, aDst: TStream);
var
  LIn: TBytes;
  LOut: TBytes;
  LPrefs: LZ4F_preferences_t;
  LBound: size_t;
  LWritten: size_t;
begin
  SetLength(LIn, aSrc.Size);
  aSrc.Position := 0;
  if Length(LIn) > 0 then
    aSrc.ReadBuffer(LIn[0], Length(LIn));

  FillChar(LPrefs, SizeOf(LPrefs), 0);
  LPrefs.frameInfo.blockSizeID := LZ4F_max4MB;
  LPrefs.frameInfo.blockMode := LZ4F_blockIndependent;
  LPrefs.frameInfo.contentChecksumFlag := LZ4F_noContentChecksum;
  LPrefs.frameInfo.frameType := LZ4F_frame;
  LPrefs.frameInfo.contentSize := 0;
  LPrefs.frameInfo.dictID := 0;
  LPrefs.frameInfo.blockChecksumFlag := LZ4F_noBlockChecksum;

  LBound := LZ4F_compressFrameBound(Length(LIn), @LPrefs);
  SetLength(LOut, LBound);
  if Length(LIn) > 0 then
    LWritten := LZ4F_compressFrame(@LOut[0], Length(LOut), @LIn[0], Length(LIn), @LPrefs)
  else
    LWritten := LZ4F_compressFrame(@LOut[0], Length(LOut), nil, 0, @LPrefs);
  LZ4Check(LWritten, 'LZ4 frame compression failed');
  if LWritten > 0 then
    aDst.WriteBuffer(LOut[0], LWritten);
end;

procedure lz4BlockCompressStream(aSrc, aDst: TStream);
var
  LIn: TBytes;
  LOut: TBytes;
  LBound: Integer;
  LWritten: Integer;
begin
  SetLength(LIn, aSrc.Size);
  aSrc.Position := 0;
  if Length(LIn) > 0 then
    aSrc.ReadBuffer(LIn[0], Length(LIn));

  LBound := LZ4_compressBound(Length(LIn));
  if LBound <= 0 then
    raise Exception.Create('LZ4 block compression bound failed');
  SetLength(LOut, LBound);
  if Length(LIn) > 0 then
    LWritten := LZ4_compress_default(@LIn[0], @LOut[0], Length(LIn), Length(LOut))
  else
    LWritten := 0;
  if LWritten < 0 then
    raise Exception.Create('LZ4 block compression failed');
  if LWritten > 0 then
    aDst.WriteBuffer(LOut[0], LWritten);
end;

procedure lz4DecompressToUserBuf(aSrc: Pointer; aSrcSize: Integer; aDst: Pointer; aDstSize: Integer);
var
  LDctx: LZ4F_dctx;
  LRet: LZ4F_errorCode_t;
  LSrcPtr: PByte;
  LDstPtr: PByte;
  LSrcRem: size_t;
  LDstRem: size_t;
  LSrcChunk: size_t;
  LDstChunk: size_t;
  LHint: size_t;
begin
  if aDstSize = 0 then
    Exit;

  LDctx := nil;
  LRet := LZ4F_createDecompressionContext(@LDctx, LZ4F_VERSION);
  LZ4Check(LRet, 'LZ4 frame context create failed');
  try
    LSrcPtr := PByte(aSrc);
    LDstPtr := PByte(aDst);
    LSrcRem := aSrcSize;
    LDstRem := aDstSize;

    repeat
      LSrcChunk := LSrcRem;
      LDstChunk := LDstRem;
      LHint := LZ4F_decompress(LDctx, LDstPtr, @LDstChunk, LSrcPtr, @LSrcChunk, nil);
      LZ4Check(LHint, 'LZ4 frame decompression failed');

      Inc(LSrcPtr, LSrcChunk);
      Dec(LSrcRem, LSrcChunk);
      Inc(LDstPtr, LDstChunk);
      Dec(LDstRem, LDstChunk);

      if LHint = 0 then
        Break;
      if (LSrcChunk = 0) and (LDstChunk = 0) then
        Break;
    until False;

    if LDstRem <> 0 then
      raise Exception.CreateFmt('LZ4 frame decompression size mismatch (%d bytes missing)', [LDstRem]);
  finally
    LRet := LZ4F_freeDecompressionContext(LDctx);
    LZ4Check(LRet, 'LZ4 frame context free failed');
  end;
end;

procedure lz4BlockDecompressToUserBuf(aSrc: Pointer; aSrcSize: Integer; aDst: Pointer; aDstSize: Integer);
var
  LOutSize: Integer;
begin
  LOutSize := LZ4_decompress_safe(aSrc, aDst, aSrcSize, aDstSize);
  if LOutSize < 0 then
    raise Exception.Create('LZ4 block decompression failed');
  if LOutSize <> aDstSize then
    raise Exception.CreateFmt('LZ4 block decompression size mismatch (%d/%d)', [LOutSize, aDstSize]);
end;

end.

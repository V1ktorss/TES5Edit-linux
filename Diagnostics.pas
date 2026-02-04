unit Diagnostics;

interface

type
  TTimeSpan = record
  private
    FMilliseconds: QWord;
  public
    class function FromMilliseconds(aValue: QWord): TTimeSpan; static;
    function ToString: string;
  end;

  TStopwatch = record
  private
    FStartTick: QWord;
    FStopTick: QWord;
    FRunning: Boolean;
  public
    class function StartNew: TStopwatch; static;
    procedure Stop;
    function Elapsed: TTimeSpan;
  end;

implementation

uses
  SysUtils;

class function TTimeSpan.FromMilliseconds(aValue: QWord): TTimeSpan;
begin
  Result.FMilliseconds := aValue;
end;

function TTimeSpan.ToString: string;
var
  TotalSeconds: QWord;
  Hours: QWord;
  Minutes: QWord;
  Seconds: QWord;
  Millis: QWord;
begin
  TotalSeconds := FMilliseconds div 1000;
  Millis := FMilliseconds mod 1000;
  Hours := TotalSeconds div 3600;
  Minutes := (TotalSeconds mod 3600) div 60;
  Seconds := TotalSeconds mod 60;
  Result := Format('%.2d:%.2d:%.2d.%.3d', [Hours, Minutes, Seconds, Millis]);
end;

class function TStopwatch.StartNew: TStopwatch;
begin
  Result.FStartTick := GetTickCount64;
  Result.FStopTick := Result.FStartTick;
  Result.FRunning := True;
end;

procedure TStopwatch.Stop;
begin
  if FRunning then
  begin
    FStopTick := GetTickCount64;
    FRunning := False;
  end;
end;

function TStopwatch.Elapsed: TTimeSpan;
var
  EndTick: QWord;
begin
  if FRunning then
    EndTick := GetTickCount64
  else
    EndTick := FStopTick;
  Result := TTimeSpan.FromMilliseconds(EndTick - FStartTick);
end;

end.

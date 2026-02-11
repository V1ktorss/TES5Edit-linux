unit Generics.Collections;

{$mode delphi}

interface

uses
  Generics.Collections;

type
  TDictionary<TKey, TValue> = class(Generics.Collections.TDictionary<TKey, TValue>)
  end;
  TList<T> = class(Generics.Collections.TList<T>)
  end;

  THashSet<T> = class(TDictionary<T, Byte>)
  public
    procedure Add(const Value: T);
    function Contains(const Value: T): Boolean;
  end;

implementation

procedure THashSet<T>.Add(const Value: T);
begin
  inherited Add(Value, 0);
end;

function THashSet<T>.Contains(const Value: T): Boolean;
begin
  Result := inherited ContainsKey(Value);
end;

end.

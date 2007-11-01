unit EffectPNGImageList;

interface

{$R 'efficons.res'}

uses
  Classes,
  Windows,
  Graphics,
  SysUtils,
  EffectPNG,
  PNGImageList,
  BaseImageList,
  PNGImage;

type
  TCustomEffectPNGImageList = class(TCustomPNGImageList)
  private
    FEffects : array[Low(TilDrawState)..High(TilDrawState)] of TPNGEffects;
    procedure SetEffect(const Index: TilDrawState; const Value: TPNGEffects);
    function GetEffect(const Index: TilDrawState): TPNGEffects;

  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy(); override;

    procedure Draw(AIndex : Integer; ACanvas : TCanvas; APos : TPoint; AState : TilDrawStates); override;

    property EffectEnabled : TPNGEffects index ildEnabled read GetEffect write SetEffect;
    property EffectDisabled : TPNGEffects index ildDisabled read GetEffect write SetEffect;
    property EffectHighlight : TPNGEffects index ildHighlight read GetEffect write SetEffect;
    property EffectFocused : TPNGEffects index ildFocused read GetEffect write SetEffect;
    property EffectSelected : TPNGEffects index ildSelected read GetEffect write SetEffect;
  end;

  TEffectPNGImageList = class(TCustomEffectPNGImageList)
  public
    property Items;
    property Count;
  published
    property Images;

    property EffectEnabled;
    property EffectDisabled;
    property EffectHighlight;
    property EffectFocused;
    property EffectSelected;


    property OnChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Imagelists',[TEffectPNGImageList]);
end;

{ TCustomEffectPNGImageList }


constructor TCustomEffectPNGImageList.Create(AOwner: TComponent);
var
  idx : TilDrawState;
begin
  inherited;

  for idx := Low(TilDrawState) to High(TilDrawState) do
    FEffects[idx]:=TPNGEffects.Create;
end;

destructor TCustomEffectPNGImageList.Destroy;
var
  idx : TilDrawState;
begin
  for idx := Low(TilDrawState) to High(TilDrawState) do
    FEffects[idx].Free;

  inherited;
end;

procedure TCustomEffectPNGImageList.Draw(AIndex: Integer; ACanvas: TCanvas;
  APos: TPoint; AState: TilDrawStates);
var
  PNG : TPNGObject;
begin
  PNG:=TPNGObject.Create;
  try
    PNG.Assign(Items[AIndex]);

    if ildEnabled in AState then
      FEffects[ildEnabled].ApplyEffects(PNG)
    else
    if ildDisabled in AState then
      FEffects[ildDisabled].ApplyEffects(PNG);

    if ildHighlight in AState then
      FEffects[ildHighlight].ApplyEffects(PNG);

    if ildFocused in AState then
      FEffects[ildFocused].ApplyEffects(PNG);

    if ildSelected in AState then
      FEffects[ildSelected].ApplyEffects(PNG);

    ACanvas.Draw(APos.X, APos.Y, PNG);
  finally
    PNG.Free;
  end;

end;


function TCustomEffectPNGImageList.GetEffect(const Index: TilDrawState): TPNGEffects;
begin
  Result:=FEffects[Index];
end;

procedure TCustomEffectPNGImageList.SetEffect(const Index: TilDrawState;
  const Value: TPNGEffects);
begin
  FEffects[Index].Assign(Value);
end;

end.
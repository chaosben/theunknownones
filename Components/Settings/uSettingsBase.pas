unit uSettingsBase;

interface

{$DEFINE UniCode}

uses
  Classes,
  Contnrs,
  Sysutils,
  Variants,
  WideStrings,
  RegExpr;

type
  
  TSetting = class;

  TCustomSettingsCompLink = class;
  TCustomSettingsCompLinkList = class;

  TSettingName = WideString;

  TSettingValue = Variant;

  TSettingValues = array of Variant;

  TSettingNameValue = record
    Name : TSettingName;
    Value : TSettingValue;
  end;

  TSettingNameValues = array of TSettingNameValue;


//==============================================================================


  //Just a list for holding settings (for internal use)
  TSettingList = class(TList)
  protected
    function GetItem(Index: Integer): TSetting;
    procedure SetItem(Index: Integer; const Value: TSetting);

  public
    function Add(ASetting: TSetting): Integer;
    function Extract(Item: TSetting): TSetting;
    function Remove(ASetting: TSetting): Integer;
    function IndexOf(ASetting: TSetting): Integer; overload;
    function IndexOfPath(APath: TSettingName): Integer; overload;
    function IndexOfName(AName: TSettingName): Integer; overload;
    procedure Insert(Index: Integer; ASetting: TSetting);
    function First: TSetting;
    function Last: TSetting;
    function ContainsPath(APath : TSettingName) : Boolean;
    procedure AddSettings(ASettings : TSettingList);
    property Items[Index: Integer]: TSetting read GetItem write SetItem; default;
  end;


//==============================================================================


  TSetting = class
  protected
    FParent : TSetting;
    FName : TSettingName;
    FValue : TSettingValue;

    FChildren : TSettingList;

    FIndex : TWideStringList;

    function CalculatePath : TSettingName;

    procedure CreateIndex();
    procedure InitIndex();
    procedure AddSettingToIndex(ASetting : TSetting);
    procedure RemoveSettingFromIndex(ASetting : TSetting);
    procedure DestroyIndex();

    procedure SetValue(const Value: TSettingValue);
    procedure SetParent(const Value: TSetting);
    procedure SetName(const Value: TSettingName);

    procedure CreateFromPath(ARoot : TSetting; APath : TSettingName);
  public
    constructor Create(); overload;
    constructor Create(AParent : TSetting); overload;
    constructor Create(AParent : TSetting; AName : TSettingName; ANameIsPath : Boolean = false); overload;
    constructor Create(AParent : TSetting; AName : TSettingName; AValue : TSettingValue); overload;


    destructor Destroy(); override;

    procedure RegisterChild(const AChild : TSetting);
    procedure UnregisterChild(const AChild : TSetting);

    procedure Clear;

    procedure Assign(ASetting : TSetting);

    function NameMatches(APattern : TSettingName; AIsRegEx : Boolean = false) : Boolean;

    function GetPath : TSettingName;

    property Name : TSettingName read FName write SetName;
    property Value : TSettingValue read FValue write SetValue;
    property Parent : TSetting read FParent write SetParent;
    property Children : TSettingList read FChildren;
    property Index : TWideStringList read FIndex;
  end;


//==============================================================================


  TParentMode = (pmDontUse,
                 pmAddsMissing,
                 pmOverridesAll);


//==============================================================================


  TCustomSettings = class(TComponent)
  protected
    FRootSetting : TSetting;
    FParentSettings: TCustomSettings;
    FParentMode: TParentMode;

    FComponentLinks : TCustomSettingsCompLinkList;

    procedure SetParentSettings(const Value: TCustomSettings);

    procedure QuerySettings(const APath : TSettingName;
                            const AIsRegEx : Boolean;
                            const AList : TSettingList;
                            const AUseParent : Boolean);

    function DoLoad() : Boolean; virtual; abstract;
    function DoSave() : Boolean; virtual; abstract;

    procedure InformComponentLinksAboutLoad;
    procedure InformComponentLinksAboutSave;

    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Assign(ASource : TPersistent); override;

    procedure SetValue(APath : TSettingName;
                       AValue : Variant;
                       ACreateIfMissing : Boolean = true;
                       AIsRegExPath : Boolean = false);

    function GetValues(APath : TSettingName;
                       AIsRegExPath : Boolean = true) : TSettingValues;

    function GetValue(APath : TSettingName;
                      AIsRegExPath : Boolean = false) : TSettingValue;

    function GetNameValues(APath : TSettingName;
                           AIsRegExPath : Boolean = true;
                           AGetNames : Boolean = true;
                           AFullPathNames : Boolean = false;
                           AGetValues : Boolean = true) : TSettingNameValues;

    function GetNameValue(APath : TSettingName;
                          AIsRegEx : Boolean = false;
                          AGetName : Boolean = true;
                          AFullPathName : Boolean = false;
                          AGetValues : Boolean = true) : TSettingNameValue;

    function GetSubNameValues(APath : TSettingName;
                              AIsRegExPath : Boolean = false;
                              AGetNames : Boolean = true;
                              AFullPathNames : Boolean = false;
                              AGetValues : Boolean = true) : TSettingNameValues;

    function Exists(APath : TSettingName; AIsRegEx : Boolean = false) : Boolean;
    procedure Delete(APath : TSettingName; AIsRegEx : Boolean = false);

    procedure RegisterComponentLink(ALink : TCustomSettingsCompLink);
    procedure UnRegisterComponentLink(ALink : TCustomSettingsCompLink);

    property ParentSettings : TCustomSettings read FParentSettings write SetParentSettings;
    property ParentMode : TParentMode read FParentMode write FParentMode default pmAddsMissing;

    function Load() : Boolean;
    function Save() : Boolean;
  end;


//==============================================================================


  TCustomSettingsCompLinkList = class(TList)
  protected
    function GetItem(Index: Integer): TCustomSettingsCompLink;
    procedure SetItem(Index: Integer; const Value: TCustomSettingsCompLink);
  public
    function Add(ALink: TCustomSettingsCompLink): Integer;
    function Extract(Item: TCustomSettingsCompLink): TCustomSettingsCompLink;
    function Remove(ALink: TCustomSettingsCompLink): Integer;
    function IndexOf(ALink: TCustomSettingsCompLink): Integer; overload;
    procedure Insert(Index: Integer; ALink: TCustomSettingsCompLink);
    function First: TCustomSettingsCompLink;
    function Last: TCustomSettingsCompLink;
    property Items[Index: Integer]: TCustomSettingsCompLink read GetItem write SetItem; default;
  end;


//==============================================================================


  TCustomSettingsCompLink = class(TComponent)
  protected
    FComponent: TComponent;
    FSettings: TCustomSettings;
    FRootSetting: TSettingName;

    function GenerateRootSettingName(AComponent : TComponent) : TSettingName; virtual;

    procedure SetSettings(const Value: TCustomSettings);
    procedure SetComponent(const Value: TComponent);
    procedure SetRootSetting(const Value: TSettingName);

    procedure InitiateLoad; virtual;

    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    procedure DoLoadSettings; virtual; abstract;
    procedure DoSaveSettings; virtual; abstract;

    function ValidComponent(const AComponent : TComponent) : Boolean; virtual; abstract;
      //Use this to decide, which components this link handles
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure OnAfterLoadSettings; virtual;
    procedure OnBeforeSaveSettings; virtual;

    property Component : TComponent read FComponent write SetComponent;
    property Settings : TCustomSettings read FSettings write SetSettings;
    property RootSetting : TSettingName read FRootSetting write SetRootSetting;
  end;


//==============================================================================


const
  SettingsPathDelimiter = '/';
  SettingsValidValueTypes : array[0..14] of TVarType = (varEmpty,
                                                        varNull,
                                                        varSmallint,
                                                        varInteger,
                                                        varSingle,
                                                        varDouble,
                                                        varDate,
                                                        varOleStr,
                                                        varBoolean,
                                                        varShortInt,
                                                        varByte,
                                                        varWord,
                                                        varLongWord,
                                                        varInt64,
                                                        varString);
  SettingsComponentGroup = 'Settings';                                                        

var
  SettingsRegExCaseinsensitive : Boolean = true;
  SettingsRegExRussianSupport : Boolean = false;
  SettingsRegExDotMatchesLineSeperators : Boolean = true;
  SettingsRegExAllOperatorsGreedy : Boolean = true;

implementation


{ Helper }

function ExcludeTrailingSettingsPathDelimiter(APath : TSettingName) : TSettingName;
begin
  if Copy(APath, Length(APath), 1) = SettingsPathDelimiter then
    Result := Copy(APath, 1, Length(APath) - 1)
  else
    Result := APath;
end;

function IncludeLeadingSettingsPathDelimiter(APath : TSettingName) : TSettingName;
begin
  if Copy(APath, 1, 1) <> SettingsPathDelimiter then
    Result := SettingsPathDelimiter + APath
  else
    Result := APath;
end;

procedure SplitPath(APath : WideString; AList : TWideStrings);
begin
  AList.Delimiter := SettingsPathDelimiter;
  AList.StrictDelimiter := true;
  AList.QuoteChar := #0;
  AList.DelimitedText := APath;
end;

procedure InitRegEx(const ARegEx : TRegExpr);
begin
  ARegEx.ModifierI := SettingsRegExCaseinsensitive;
  ARegEx.ModifierR := SettingsRegExRussianSupport;
  ARegEx.ModifierS := SettingsRegExDotMatchesLineSeperators;
  ARegEx.ModifierG := SettingsRegExAllOperatorsGreedy;
end;

function NameStringMatches(AName, APattern : TSettingName; AIsRegEx : Boolean) : Boolean;
var
  Reg : TRegExpr;
begin
  if AIsRegEx then
  begin
    if APattern = EmptyWideStr then
      raise Exception.Create('Empty pattern not allowed');

    Reg := TRegExpr.Create();
    try
      InitRegEx(Reg);
      Reg.InputString := AName;
      Reg.Expression := APattern;
      Result := Reg.Exec;
    finally
      Reg.Free;
    end;
  end
  else
    Result := WideSameText(AName, APattern);
end;

procedure CheckSettingsValueType(AVariant : Variant); 
begin
  if not VarIsType(AVariant, SettingsValidValueTypes) then
    raise Exception.Create('Invalid value type');
end;


//==============================================================================


{ TSetting }

procedure TSetting.AddSettingToIndex(ASetting: TSetting);
var
  idx : Integer;
begin
  FIndex.AddObject(ASetting.CalculatePath, ASetting);

  for idx := 0 to ASetting.Children.Count - 1 do
    AddSettingToIndex(ASetting.Children[idx]);
end;

procedure TSetting.Assign(ASetting: TSetting);
var
  idx : Integer;
begin
  Clear;

  Name := ASetting.Name;
  Value := ASetting.Value;

  for idx := 0 to ASetting.Children.Count - 1 do
    TSetting.Create(Self).Assign(ASetting.Children[idx]);
end;

function TSetting.CalculatePath: TSettingName;
var
  Setting : TSetting;
  Path : TWideStringList;
begin
  Result := EmptyWideStr;

  Path := TWideStringList.Create;
  try
    SplitPath(EmptyWideStr, Path); //init list
    Path.Clear;

    Setting := Self;

    while Assigned(Setting) do
    begin
      Path.Insert(0, Setting.Name);

      Setting := Setting.Parent;
    end;

    Result := Path.DelimitedText; 
  finally
    Path.Free;
  end;
end;

procedure TSetting.Clear;
begin
  while FChildren.Count > 0 do
    FChildren.First.Free;

  VarClear(FValue);
end;

constructor TSetting.Create;
begin
  FParent := nil;
  FName := EmptyWideStr;
  VarClear(FValue);

  FChildren := TSettingList.Create;

  CreateIndex;
  InitIndex; 
end;

constructor TSetting.Create(AParent: TSetting);
begin
  Create;

  Parent := AParent;
end;

constructor TSetting.Create(AParent: TSetting; AName: TSettingName; ANameIsPath : Boolean);
begin
  if ANameIsPath then
    CreateFromPath(AParent, AName)
  else
  begin
    Create(AParent);

    Name := AName;
  end;
end;

constructor TSetting.Create(AParent: TSetting; AName: TSettingName;
  AValue: TSettingValue);
begin
  Create(AParent, AName);

  Value := AValue; 
end;

procedure TSetting.CreateFromPath(ARoot: TSetting; APath: TSettingName);
var
  Path : TWideStringList;
  Setting : TSetting;
  ChildIndex,
  PathIndex : Integer;
  SettingName : TSettingName;
begin
  Assert(Assigned(ARoot), 'CreateFromPath needs a valid root setting');

  Setting := ARoot;

  Path := TWideStringList.Create;
  try
    SplitPath(APath, Path);

    if not NameStringMatches(Path[0], ARoot.Name, false) then
      raise Exception.Create('Path doesnt match the root setting');

    PathIndex := 1;

    SettingName := Path[PathIndex];

    while (PathIndex < Path.Count - 1) and (Assigned(Setting)) do
    begin
      ChildIndex := Setting.Children.IndexOfName(SettingName);

      if ChildIndex > -1 then
        Setting := Setting.Children[ChildIndex]
      else
        Setting := TSetting.Create(Setting, SettingName);

      Inc(PathIndex);
      SettingName := Path[PathIndex];
    end;
  finally
    Path.Free;
  end;

  Create(Setting, SettingName);
end;

procedure TSetting.CreateIndex;
begin
  FIndex := TWideStringList.Create;
  FIndex.Sorted := true;
  FIndex.Duplicates := dupError;
end;

destructor TSetting.Destroy;
begin
  if Assigned(FParent) then
    FParent.UnregisterChild(Self);

  while FChildren.Count > 0 do
  begin
    FChildren.First.Free;
  end;

  FChildren.Free;

  if not Assigned(FParent) then //only destroy our own index
    DestroyIndex;

  inherited;
end;

procedure TSetting.DestroyIndex;
begin
  FIndex.Free;
  FIndex := nil;
end;

function TSetting.GetPath: TSettingName;
begin
  Result := Index[Index.IndexOfObject(Self)];
end;

procedure TSetting.InitIndex;
begin
  FIndex.Clear;
  AddSettingToIndex(Self);
end;

function TSetting.NameMatches(APattern: TSettingName;
  AIsRegEx: Boolean): Boolean;
begin
  Result := NameStringMatches(Name, APattern, AIsRegEx);
end;

procedure TSetting.RegisterChild(const AChild: TSetting);
begin
  if FChildren.IndexOf(AChild) = -1 then
    FChildren.Add(AChild);

  AddSettingToIndex(AChild);
end;

procedure TSetting.RemoveSettingFromIndex(ASetting: TSetting);
var
  idx : Integer;
begin
  idx := FIndex.IndexOfObject(ASetting);

  if idx > -1 then
    FIndex.Delete(idx);
end;

procedure TSetting.SetName(const Value: TSettingName);
begin
  FName := Value;

  FIndex.Delete(FIndex.IndexOfObject(Self));
  FIndex.AddObject(CalculatePath, Self);
end;

procedure TSetting.SetParent(const Value: TSetting);
var
  OldParent, NewParent : TSetting;
begin
  if Value <> FParent then
  begin
    OldParent := FParent;
    NewParent := Value;

    FParent := Value;

    if Assigned(OldParent) then
      OldParent.UnregisterChild(Self);

    if Assigned(NewParent) then
      NewParent.RegisterChild(Self);

    if Assigned(OldParent) and (not Assigned(NewParent)) then
    begin
      CreateIndex;
      InitIndex;
    end
    else
    if (not Assigned(OldParent)) and Assigned(NewParent) then
    begin
      DestroyIndex;
      FIndex := NewParent.Index;
    end
    else 
    begin
      FIndex := NewParent.Index;
    end;
  end;
  
end;

procedure TSetting.SetValue(const Value: TSettingValue);
begin
  CheckSettingsValueType(Value);
  
  FValue := Value;
end;

procedure TSetting.UnregisterChild(const AChild: TSetting);
var
  Index : Integer;
begin
  RemoveSettingFromIndex(AChild);

  Index := FChildren.IndexOf(AChild);

  if Index > -1 then
    FChildren.Delete(Index);
end;


//==============================================================================


{ TSettingList }

function TSettingList.Add(ASetting: TSetting): Integer;
begin
  Result := inherited Add(ASetting);
end;

procedure TSettingList.AddSettings(ASettings: TSettingList);
var
  idx : Integer;
begin
  for idx := 0 to ASettings.Count - 1 do
  begin
    Add(ASettings[idx]);                                                    
  end;
end;

function TSettingList.ContainsPath(APath: TSettingName): Boolean;
begin
  Result := IndexOfPath(APath) > -1;
end;

function TSettingList.Extract(Item: TSetting): TSetting;
begin
  Result := TSetting(inherited Extract(Item));
end;

function TSettingList.First: TSetting;
begin
  Result := TSetting(inherited First);
end;

function TSettingList.GetItem(Index: Integer): TSetting;
begin
  Result := TSetting(inherited Get(Index));
end;

function TSettingList.IndexOf(ASetting: TSetting): Integer;
begin
  Result := inherited IndexOf(ASetting);
end;

function TSettingList.IndexOfName(AName: TSettingName): Integer;
var
  idx : Integer;
begin
  Result := -1;

  for idx := 0 to Count - 1 do
  begin
    if NameStringMatches(Items[idx].Name, AName, false) then
    begin
      Result := idx;
      break;
    end;
  end;
end;

function TSettingList.IndexOfPath(APath: TSettingName): Integer;
var
  idx : Integer;
begin
  Result := -1;

  for idx := 0 to Count - 1 do
  begin
    if NameStringMatches(Items[idx].GetPath, APath, false) then
    begin
      Result := idx;
      break;
    end;
  end;
end;

procedure TSettingList.Insert(Index: Integer; ASetting: TSetting);
begin
  inherited Insert(Index, ASetting);
end;

function TSettingList.Last: TSetting;
begin
  Result := TSetting(inherited Last);
end;

function TSettingList.Remove(ASetting: TSetting): Integer;
begin
  Result := inherited Remove(ASetting);
end;

procedure TSettingList.SetItem(Index: Integer; const Value: TSetting);
begin
  inherited Put(Index, Value);
end;


//==============================================================================


{ TCustomSettings }

procedure TCustomSettings.Assign(ASource: TPersistent);
begin
  if ASource is TCustomSettings then
    FRootSetting.Assign(TCustomSettings(ASource).FRootSetting)
  else
    inherited;
end;

constructor TCustomSettings.Create(AOwner: TComponent);
begin
  inherited;

  FComponentLinks := TCustomSettingsCompLinkList.Create;

  FParentMode := pmAddsMissing;
  FParentSettings := nil;

  FRootSetting := TSetting.Create();
end;


procedure TCustomSettings.Delete(APath: TSettingName; AIsRegEx: Boolean);
var
  Setts : TSettingList;
  idx : Integer;
begin
  Setts := TSettingList.Create;
  try
    QuerySettings(APath, AIsRegEx, Setts, false);

    for idx := 0 to Setts.Count - 1 do
      Setts[idx].Free;
  finally
    Setts.Free;
  end;
end;

destructor TCustomSettings.Destroy;
begin
  while FComponentLinks.Count > 0 do
    FComponentLinks.First.Settings := nil;

  FComponentLinks.Free;

  FRootSetting.Free;

  inherited;
end;

function TCustomSettings.Exists(APath: TSettingName;
  AIsRegEx: Boolean): Boolean;
var
  Setts : TSettingList;
begin
  Setts := TSettingList.Create;
  try
    QuerySettings(APath, AIsRegEx, Setts, true);
    Result := Setts.Count > 0;
  finally
    Setts.Free;
  end;
end;

function TCustomSettings.GetSubNameValues(APath: TSettingName; AIsRegExPath,
  AGetNames, AFullPathNames, AGetValues: Boolean): TSettingNameValues;
var
  Setts : TSettingList;
  idx : Integer;
begin
  Setts := TSettingList.Create;
  try
    QuerySettings(APath, AIsRegExPath, Setts, true);

    for idx := Setts.Count - 1 downto 0 do
    begin
      Setts.AddSettings(Setts[idx].Children);
      Setts.Delete(idx);
    end;

    SetLength(Result, Setts.Count);

    for idx := 0 to Setts.Count - 1 do
    begin
      if AGetValues then
        Result[idx].Value := Setts[idx].Value
      else
        VarClear(Result[idx].Value);

      if AGetNames then
      begin
        if AFullPathNames then
          Result[idx].Name := Setts[idx].GetPath
        else
          Result[idx].Name := Setts[idx].Name
      end
      else
        Result[idx].Name := EmptyWideStr;
    end;

  finally
    Setts.Free;
  end;
end;

function TCustomSettings.GetNameValue(APath: TSettingName; AIsRegEx, AGetName,
  AFullPathName, AGetValues: Boolean): TSettingNameValue;
var
  NameValues : TSettingNameValues;
begin
  NameValues := GetNameValues(APath, AIsRegEx, AGetName, AFullPathName, AGetValues);

  if Length(NameValues) > 0 then
    Result := NameValues[0];
end;

function TCustomSettings.GetNameValues(APath : TSettingName;
                                       AIsRegExPath : Boolean;
                                       AGetNames : Boolean;
                                       AFullPathNames : Boolean;
                                       AGetValues : Boolean): TSettingNameValues;
var
  Setts : TSettingList;
  idx : Integer;
begin
  Setts := TSettingList.Create;
  try
    QuerySettings(APath, AIsRegExPath, Setts, true);

    SetLength(Result, Setts.Count);

    for idx := 0 to Setts.Count - 1 do
    begin
      if AGetValues then
        Result[idx].Value := Setts[idx].Value
      else
        VarClear(Result[idx].Value);

      if AGetNames then
      begin
        if AFullPathNames then
          Result[idx].Name := Setts[idx].GetPath
        else
          Result[idx].Name := Setts[idx].Name
      end
      else
        Result[idx].Name := EmptyWideStr;
    end;

  finally
    Setts.Free;
  end;
end;

  
function TCustomSettings.GetValue(APath: TSettingName;
  AIsRegExPath: Boolean): TSettingValue;
var
  vals : TSettingValues;
begin
  vals := GetValues(APath, AIsRegExPath);
  if Length(vals) > 0 then
    Result := vals[0]
  else
    VarClear(Result);
end;

function TCustomSettings.GetValues(APath: TSettingName;
  AIsRegExPath: Boolean): TSettingValues;
var
  Setts : TSettingList;
  idx : Integer;
begin
  Setts := TSettingList.Create;
  try
    QuerySettings(APath, AIsRegExPath, Setts, true);

    SetLength(Result, Setts.Count);
    for idx := 0 to Setts.Count - 1 do
      Result[idx] := Setts[idx].Value;

  finally
    Setts.Free;
  end;
end;

procedure TCustomSettings.InformComponentLinksAboutLoad;
var
  idx : Integer;
begin
  for idx := 0 to FComponentLinks.Count - 1 do
    FComponentLinks[idx].OnAfterLoadSettings;

end;

procedure TCustomSettings.InformComponentLinksAboutSave;
var
  idx : Integer;
begin
  for idx := 0 to FComponentLinks.Count - 1 do
    FComponentLinks[idx].OnBeforeSaveSettings;
end;

function TCustomSettings.Load: Boolean;
begin
  FRootSetting.Clear;
  
  Result := DoLoad;

  if Result then
    InformComponentLinksAboutLoad;
end;

procedure TCustomSettings.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if Operation = opRemove then
  begin
    if AComponent = FParentSettings then
      FParentSettings := nil;
  end;
end;

procedure TCustomSettings.QuerySettings(const APath: TSettingName;
  const AIsRegEx: Boolean; const AList: TSettingList; const AUseParent : Boolean);
var
  idx : Integer;
  Setting : TSetting;
begin
  if AUseParent and
     (FParentMode = pmOverridesAll) and
     Assigned(FParentSettings) then
    FParentSettings.QuerySettings(APath, AIsRegEx, AList, AUseParent);

  if AIsRegEx then
  begin
    for idx := 0 to FRootSetting.Index.Count - 1 do
    begin
      Setting := TSetting(FRootSetting.Index.Objects[idx]);

      if NameStringMatches(FRootSetting.Index[idx], APath, AIsRegEx) and
         (not AList.ContainsPath(Setting.GetPath))then
        AList.Add(Setting);
    end;
  end
  else
  begin
    idx := FRootSetting.Index.IndexOf(APath);
    if idx > -1 then
      AList.Add(TSetting(FRootSetting.Index.Objects[idx]));
  end;

  if AUseParent and
     (FParentMode = pmAddsMissing) and
     Assigned(FParentSettings) then
    FParentSettings.QuerySettings(APath, AIsRegEx, AList, AUseParent);

end;

procedure TCustomSettings.RegisterComponentLink(
  ALink: TCustomSettingsCompLink);
begin
  if FComponentLinks.IndexOf(ALink) = -1 then
    FComponentLinks.Add(ALink);
end;

function TCustomSettings.Save: Boolean;
begin
  InformComponentLinksAboutSave;

  Result := DoSave;
end;

procedure TCustomSettings.SetParentSettings(const Value: TCustomSettings);
begin
  if (Value <> Self) and (Value <> FParentSettings) then
  begin
    if Assigned(FParentSettings) then
      FParentSettings.RemoveFreeNotification(Self);

    FParentSettings := Value;

    if Assigned(FParentSettings) then
      FParentSettings.FreeNotification(Self);
  end;
end;

procedure TCustomSettings.SetValue(APath: TSettingName; AValue: Variant;
  ACreateIfMissing : Boolean; AIsRegExPath: Boolean);
var
  Setts : TSettingList;
  idx : Integer;
begin
  Assert(not (ACreateIfMissing and AIsRegExPath), 'Can not create non-existing settings if regular expression is supplied');

  Setts := TSettingList.Create;
  try
    QuerySettings(APath, AIsRegExPath, Setts, false);

    if (Setts.Count = 0) and ACreateIfMissing then
      Setts.Add(TSetting.Create(FRootSetting, APath, true));

    for idx := 0 to Setts.Count - 1 do
      Setts[idx].Value := AValue;
  finally
    Setts.Free;
  end;
end;


procedure TCustomSettings.UnRegisterComponentLink(
  ALink: TCustomSettingsCompLink);
var
  idx : Integer;
begin
  idx := FComponentLinks.IndexOf(ALink);

  if idx > - 1 then
    FComponentLinks.Delete(idx);
end;

//==============================================================================


{ TCustomSettingsCompLink }

constructor TCustomSettingsCompLink.Create(AOwner: TComponent);
begin
  inherited;

  FSettings := nil;
  FComponent := nil;
end;

destructor TCustomSettingsCompLink.Destroy;
begin
  Settings := nil;
  Component := nil;

  inherited;
end;

function TCustomSettingsCompLink.GenerateRootSettingName(
  AComponent: TComponent): TSettingName;
var
  Path : TWideStringList;
  Compo : TComponent;
begin
  Compo := AComponent;

  Path := TWideStringList.Create;
  try
    SplitPath(EmptyWideStr, Path); //Init the list;

    while Assigned(Compo) do
    begin
      Path.Insert(0, Compo.Name);

      if Compo = AComponent.Owner then
      begin
        Path.Insert(0, EmptyWideStr);
        break;
      end;
        
      Compo := Compo.GetParentComponent;
    end;

    Result := Path.DelimitedText;
  finally
    Path.Free;
  end;
end;

procedure TCustomSettingsCompLink.InitiateLoad;
begin
  OnAfterLoadSettings;
end;

procedure TCustomSettingsCompLink.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if Operation = opRemove then
  begin
    if AComponent = FComponent then
      FComponent := nil
    else
    if AComponent = FSettings then
      FSettings := nil;
  end;
end;

procedure TCustomSettingsCompLink.OnAfterLoadSettings;
begin
  DoLoadSettings;
end;

procedure TCustomSettingsCompLink.OnBeforeSaveSettings;
begin
  DoSaveSettings;
end;

procedure TCustomSettingsCompLink.SetComponent(const Value: TComponent);
begin
  if FComponent <> Value then
  begin
    if Assigned(Value) and (not ValidComponent(Value)) then
      raise Exception.Create('This component is invalid for this link');

    if Assigned(FComponent) then
      FComponent.RemoveFreeNotification(Self);

    FComponent := Value;

    if Assigned(FComponent) then
      FComponent.FreeNotification(Self);

    if WideSameText(FRootSetting, EmptyWideStr) then
      RootSetting := GenerateRootSettingName(FComponent);

    InitiateLoad;
  end;
end;

procedure TCustomSettingsCompLink.SetRootSetting(
  const Value: TSettingName);
begin
  if Value <> EmptyStr then
    FRootSetting := IncludeLeadingSettingsPathDelimiter(Value)
  else
    FRootSetting := Value;

  FRootSetting := ExcludeTrailingSettingsPathDelimiter(FRootSetting);
end;

procedure TCustomSettingsCompLink.SetSettings(
  const Value: TCustomSettings);
begin
  if FSettings <> Value then
  begin
    if Assigned(FSettings) then
    begin
      FSettings.UnRegisterComponentLink(Self);
      FSettings.RemoveFreeNotification(Self);
    end;

    FSettings := Value;

    if Assigned(FSettings) then
    begin
      FSettings.RegisterComponentLink(Self);
      FSettings.FreeNotification(Self);
    end;

    InitiateLoad;
  end;
end;


//==============================================================================


{ TCustomSettingsCompLinkList }

function TCustomSettingsCompLinkList.Add(
  ALink: TCustomSettingsCompLink): Integer;
begin
  Result := inherited Add(ALink);
end;

function TCustomSettingsCompLinkList.Extract(
  Item: TCustomSettingsCompLink): TCustomSettingsCompLink;
begin
  Result := inherited Extract(Item);
end;

function TCustomSettingsCompLinkList.First: TCustomSettingsCompLink;
begin
  Result := inherited First;
end;

function TCustomSettingsCompLinkList.GetItem(
  Index: Integer): TCustomSettingsCompLink;
begin
  Result := inherited Get(Index);
end;

function TCustomSettingsCompLinkList.IndexOf(
  ALink: TCustomSettingsCompLink): Integer;
begin
  Result := inherited IndexOf(ALink);
end;

procedure TCustomSettingsCompLinkList.Insert(Index: Integer;
  ALink: TCustomSettingsCompLink);
begin
  inherited Insert(Index, ALink);
end;

function TCustomSettingsCompLinkList.Last: TCustomSettingsCompLink;
begin
  Result := inherited Last;
end;

function TCustomSettingsCompLinkList.Remove(
  ALink: TCustomSettingsCompLink): Integer;
begin
  Result := inherited Remove(ALink);
end;

procedure TCustomSettingsCompLinkList.SetItem(Index: Integer;
  const Value: TCustomSettingsCompLink);
begin
  inherited Put(Index, Value);
end;

end.

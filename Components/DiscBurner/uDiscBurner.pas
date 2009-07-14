{-----------------------------------------------------------------------------
 Purpose: Implement the IMAPI as objects

 (c) by TheUnknownOnes
 see http://www.TheUnknownOnes.net
-----------------------------------------------------------------------------}

unit uDiscBurner;

interface

uses
  Classes,
  Windows,
  Sysutils,
  ActiveX,
  jwaActiveX,
  jwaIMAPI,
  jwaIMAPIError,
  ComObj,
  Variants;

type
  TDiscMaster = class;

  TDiscRecorderState = (rsUnknown,
                        rsIdle,
                        rsOpen,
                        rsBurning);

  TDiscRecorderType = (rtUnknown,
                       rtCDR,
                       rtCDRW);

  TDiscRecorderMediaType = (mtNoMedia,
                            mtCD_Extra,
                            mtCD_I,
                            mtCD_Other,
                            mtCD_ROM_XA,
                            mtCDDA_CDRROM,
                            mtSpecial);
  TDiscRecorderMediaTypes = set of TDiscRecorderMediaType;

  TDiscRecorderMediaFlag = (mfNoMedia,
                            mfBlank,
                            mfRW,
                            mfWriteable);
  TDiscRecorderMediaFlags = set of TDiscRecorderMediaFlag;

  TDiscMasterFormat = (fJoliet,
                       fRedBook);
  TDiscMasterFormats = set of TDiscMasterFormat;

  TDiscRecorder = class(TObject)
  private
    FDiscRecorder : IDiscRecorder;

    FVendor,
    FProductID,
    Frevision : String;

    FSessionCount,
    FLastTrack : Byte;
    FStartAddress,
    FNextWriteable,
    FFreeBlocks : Cardinal;


    procedure ReadNames;
    procedure ReadMediaInfo;

    function GetProductID: String;
    function GetRevision: String;
    function GetVendor: String;
    function GetState: TDiscRecorderState;
    function GetRekorderType: TDiscRecorderType;
    function GetPath: String;
    function GetMediaFlags: TDiscRecorderMediaFlags;
    function GetMediaType: TDiscRecorderMediaTypes;
    function GetProp(AName: String): Variant;
    procedure SetProp(AName: String; const Value: Variant);
    function GetGUID: TGUID;
    function GetMediaSessionCount: Byte;
    function GetLastTrack: Byte;
    function GetMediaFreeBlocks: Cardinal;
    function GetMediaNextWriteableAddress: Cardinal;
    function GetMediaSize: Cardinal;
    function GetMediaStartAddressLastTrack: Cardinal;
  public
    constructor Create(const ADiskRecorder : IDiscRecorder);
    destructor Destroy; override;

    class function GUIDFromDiscRecorder(const ADiscRecorder : IDiscRecorder) : TGUID;

    function ToString : String;
    procedure Eject;
    procedure Erase(AFull : Boolean);

    procedure ReadPropertyNames(const AProperties : TStrings);

    property DiscRecorder : IDiscRecorder read FDiscRecorder;

    property Vendor : String read GetVendor;
    property ProductID : String read GetProductID;
    property Revision : String read GetRevision;

    property GUID : TGUID read GetGUID;

    property State : TDiscRecorderState read GetState;
    property RekorderType : TDiscRecorderType read GetRekorderType;
    property Path : String read GetPath;

    property MediaType : TDiscRecorderMediaTypes read GetMediaType;
    property MediaFlags : TDiscRecorderMediaFlags read GetMediaFlags;
    property MediaSessionCount : Byte read GetMediaSessionCount;
    property MediaLastTrack : Byte read GetLastTrack;
    property MediaStartAddressLastTrack : Cardinal read GetMediaStartAddressLastTrack;
    property MediaNextWriteableAddress : Cardinal read GetMediaNextWriteableAddress;
    property MediaFreeBlocks : Cardinal read GetMediaFreeBlocks;
    property MediaSize : Cardinal read GetMediaSize;

    property Prop[AName : String] : Variant read GetProp write SetProp;
  end;



  TDiscRecorderList = class(TList)
  private
    function Get(Index: Integer): TDiscRecorder;
    procedure Put(Index: Integer; const Value: TDiscRecorder);
  public
    destructor Destroy; override;
    procedure ToStrings(const AStrings : TStrings);
    function Add(Item: TDiscRecorder): Integer;
    function Extract(Item: TDiscRecorder): TDiscRecorder;
    function First: TDiscRecorder;
    function IndexOf(Item: TDiscRecorder): Integer; overload;
    function IndexOf(Item: IDiscRecorder): Integer; overload;
    function IndexByGUID(AGUID : TGUID) : Integer;
    procedure Insert(Index: Integer; Item: TDiscRecorder);
    function Last: TDiscRecorder;
    function Remove(Item: TDiscRecorder): Integer;

    property Items[Index: Integer]: TDiscRecorder read Get write Put; default;
  end;


  TDiscMasterProgressProc = procedure(ACompleted, ATotal : Integer) of object;
  TDiscMasterEstimationProc = procedure(ASecondsEstimated : Integer) of object;
  TDiscMasterResultProc = procedure(ASucceeded : Boolean; ACode : HRESULT) of object;
  TDiscMasterPnPActivityProc = procedure() of object;
  TDiscMasterCancelActionProc = procedure(out ACancelAction : Boolean) of object;


  TDiscMasterEvents = class(TInterfacedObject, IDiscMasterProgressEvents)
  private
    FDiscMaster : TDiscMaster;
  public
    constructor Create(const ADiscMaster : TDiscMaster);

    function QueryCancel(out pbCancel: BOOL): HRESULT; stdcall;
    function NotifyPnPActivity: HRESULT; stdcall;
    function NotifyAddProgress(nCompletedSteps, nTotalSteps: Longint): HRESULT; stdcall;
    function NotifyBlockProgress(nCompleted, nTotal: Longint): HRESULT; stdcall;
    function NotifyTrackProgress(nCurrentTrack, nTotalTracks: Longint): HRESULT; stdcall;
    function NotifyPreparingBurn(nEstimatedSeconds: Longint): HRESULT; stdcall;
    function NotifyClosingDisc(nEstimatedSeconds: Longint): HRESULT; stdcall;
    function NotifyBurnComplete(status: HRESULT): HRESULT; stdcall;
    function NotifyEraseComplete(status: HRESULT): HRESULT; stdcall;
  end;


  TDiscMaster = class(TComponent)
  private
    FDiscMaster : IDiscMaster;
    FRedBookDiscMaster : IRedbookDiscMaster;
    FJolietDiscMaster : IJolietDiscMaster;

    FEvents : IDiscMasterProgressEvents;
    FEventCookie : Cardinal;
    
    FFormats : TDiscMasterFormats;
    FOnAddProgress: TDiscMasterProgressProc;
    FOnTrackProgress: TDiscMasterProgressProc;
    FOnEraseComplete: TDiscMasterResultProc;
    FOnBurnComplete: TDiscMasterResultProc;
    FOnPreparingBurn: TDiscMasterEstimationProc;
    FOnCancelAction: TDiscMasterCancelActionProc;
    FOnClosingDisc: TDiscMasterEstimationProc;
    FOnBlockProgress: TDiscMasterProgressProc;
    FOnPnPActivity: TDiscMasterPnPActivityProc;

    procedure ReadAvailableFormats;
    function GetActiveFormat: TDiscMasterFormat;
    procedure SetActiveFormat(const Value: TDiscMasterFormat);
    function GetActiveRecorder: IDiscRecorder;
    procedure SetActiveRecord(const Value: IDiscRecorder);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure GetRecorderList(const AList : TDiscRecorderList);
    procedure RefreshRecorderList(const AList : TDiscRecorderList);

    procedure ClearContent;

    property ActiveRecorder : IDiscRecorder read GetActiveRecorder write SetActiveRecord;

  published
    property ActiveFormat : TDiscMasterFormat read GetActiveFormat write SetActiveFormat default fJoliet;

    property OnCancelAction : TDiscMasterCancelActionProc read FOnCancelAction write FOnCancelAction;
    property OnPnPActivity : TDiscMasterPnPActivityProc read FOnPnPActivity write FOnPnPActivity;
    property OnAddProgress : TDiscMasterProgressProc read FOnAddProgress write FOnAddProgress;
    property OnBlockProgress : TDiscMasterProgressProc read FOnBlockProgress write FOnBlockProgress;
    property OnTrackProgress : TDiscMasterProgressProc read FOnTrackProgress write FOnTrackProgress;
    property OnPreparingBurn : TDiscMasterEstimationProc read FOnPreparingBurn write FOnPreparingBurn;
    property OnClosingDisc : TDiscMasterEstimationProc read FOnClosingDisc write FOnClosingDisc;
    property OnBurnComplete : TDiscMasterResultProc read FOnBurnComplete write FOnBurnComplete;
    property OnEraseComplete : TDiscMasterResultProc read FOnEraseComplete write FOnEraseComplete;
  end;


  EDiscBurnerException = class(Exception)
  public
    class procedure Check(AErrorCode : Integer);
  end;

const
  DISC_BLOCK_SIZE = 2048;

implementation

function PropVariantToVariant(const APropVariant : TPropVariant) : Variant;
begin
  case APropVariant.vt of
    VT_EMPTY:  VarClear(Result);
    VT_NULL : Result := null;
    VT_I2 : Result := APropVariant.iVal;
    VT_I4 : Result := APropVariant.lVal;
    VT_R4 : Result := APropVariant.fltVal;
    VT_R8 : Result := APropVariant.dblVal;
    VT_CY : Result := APropVariant.cyVal;
    VT_DATE : Result := APropVariant.date;
    VT_BSTR : Result := WideString(APropVariant.bstrVal);
    VT_ERROR : Result := APropVariant.scode;
    VT_BOOL : Result := APropVariant.bool;
    VT_I1 : Result := APropVariant.bVal;
    VT_UI1 : Result := APropVariant.bVal;
    VT_UI2 : Result := APropVariant.uiVal;
    VT_UI4 : Result := APropVariant.ulVal;
    VT_I8 : Result := Int64(APropVariant.hVal);
    VT_UI8 : Result := Int64(APropVariant.uhVal);
    VT_INT : Result := APropVariant.lVal;
    VT_UINT : Result := APropVariant.ulVal;
    VT_LPSTR : Result := StrPas(APropVariant.pszVal);
    VT_LPWSTR : Result := WideString(APropVariant.pwszVal);
  end;
end;

function VariantToPropVariant(const AVariant : Variant) : TPropVariant;
var
  i64 : Int64;
begin
  FillMemory(@Result, SizeOf(Result), 0);

  case VarType(AVariant) of
    varEmpty: Result.vt := VT_EMPTY;
    varNull: Result.vt := VT_NULL;
    varSmallInt: begin Result.vt := VT_I2; Result.iVal := AVariant end;
    varInteger: begin Result.vt := VT_I4; Result.lVal := AVariant end;
    varSingle: begin Result.vt := VT_R4; Result.fltVal := AVariant end;
    varDouble: begin Result.vt := VT_R4; Result.dblVal := AVariant end;
    varCurrency: begin Result.vt := VT_CY; Result.cyVal := AVariant end;
    varDate: begin Result.vt := VT_DATE; Result.date := AVariant end;
    varOleStr: begin Result.vt := VT_LPWSTR; Result.pwszVal := PWideChar(WideString(AVariant)) end;
    varError: begin Result.vt := VT_ERROR; Result.scode := AVariant end;
    varBoolean: begin Result.vt := VT_BOOL; Result.bool := AVariant end;
    varShortInt: begin Result.vt := VT_I1; Result.bVal := AVariant end;
    varByte: begin Result.vt := VT_I2; Result.iVal := AVariant end;
    varWord: begin Result.vt := VT_UI2; Result.uiVal := AVariant end;
    varLongWord: begin Result.vt := VT_UI4; Result.ulVal := AVariant end;
    varInt64: begin Result.vt := VT_I8; i64 := AVariant; CopyMemory(@Result.hVal, @i64, 8) end;
    varString: begin Result.vt := VT_LPSTR; Result.pszVal := PAnsiChar(AnsiString(AVariant)) end;
  end;
end;

{ TDiscRecorder }

constructor TDiscRecorder.Create(const ADiskRecorder: IDiscRecorder);
begin
  FDiscRecorder := ADiskRecorder;

  FVendor := '';
  FProductID := '';
  Frevision := '';
end;

destructor TDiscRecorder.Destroy;
begin
  inherited;
end;

procedure TDiscRecorder.Eject;
begin
  EDiscBurnerException.Check(FDiscRecorder.OpenExclusive);
  try
    EDiscBurnerException.Check(FDiscRecorder.Eject);
  finally
    FDiscRecorder.Close;
  end;
end;

procedure TDiscRecorder.Erase(AFull: Boolean);
begin
  EDiscBurnerException.Check(FDiscRecorder.OpenExclusive);
  try
    EDiscBurnerException.Check(FDiscRecorder.Erase(AFull));
  finally
    FDiscRecorder.Close;
  end;
end;

function TDiscRecorder.GetGUID: TGUID;
begin
  Result := TDiscRecorder.GUIDFromDiscRecorder(FDiscRecorder);
end;

function TDiscRecorder.GetLastTrack: Byte;
begin
  ReadMediaInfo;
  Result := FLastTrack;
end;

function TDiscRecorder.GetMediaFlags: TDiscRecorderMediaFlags;
var
  mt, mf : Integer;
begin
  Result := [];
  
  EDiscBurnerException.Check(FDiscRecorder.OpenExclusive);
  try
    EDiscBurnerException.Check(FDiscRecorder.QueryMediaType(mt, mf));

    if mf = 0 then
      Include(Result, mfNoMedia)
    else
    if MEDIA_BLANK and mf = MEDIA_BLANK then
      Include(Result, mfBlank)
    else
    if MEDIA_RW and mf = MEDIA_RW then
      Include(Result, mfRW)
    else
    if MEDIA_WRITABLE and mf = MEDIA_WRITABLE then
      Include(Result, mfWriteable);
  finally
    FDiscRecorder.Close;
  end;
end;

function TDiscRecorder.GetMediaFreeBlocks: Cardinal;
begin
  ReadMediaInfo;
  Result := FFreeBlocks;
end;

function TDiscRecorder.GetMediaNextWriteableAddress: Cardinal;
begin
  ReadMediaInfo;
  Result := FNextWriteable;
end;

function TDiscRecorder.GetMediaSessionCount: Byte;
begin
  ReadMediaInfo;
  Result := FSessionCount;
end;

function TDiscRecorder.GetMediaSize: Cardinal;
begin
  ReadMediaInfo;
  Result := FNextWriteable + FFreeBlocks;
end;

function TDiscRecorder.GetMediaStartAddressLastTrack: Cardinal;
begin
  ReadMediaInfo;
  Result := FStartAddress;
end;

function TDiscRecorder.GetMediaType: TDiscRecorderMediaTypes;
var
  mt, mf : Integer;
begin
  Result := [];

  EDiscBurnerException.Check(FDiscRecorder.OpenExclusive);
  try
    EDiscBurnerException.Check(FDiscRecorder.QueryMediaType(mt, mf));

    if mt = 0 then
      Include(Result, mtNoMedia)
    else
    if MEDIA_CDDA_CDROM and mf = MEDIA_CDDA_CDROM then
      Include(Result, mtCDDA_CDRROM)
    else
    if MEDIA_CD_ROM_XA and mf = MEDIA_CD_ROM_XA then
      Include(Result, mtCD_ROM_XA)
    else
    if MEDIA_CD_I and mf = MEDIA_CD_I then
      Include(Result, mtCD_I)
    else
    if MEDIA_CD_EXTRA and mf = MEDIA_CD_EXTRA then
      Include(Result, mtCD_Extra)
    else
    if MEDIA_CD_OTHER and mf = MEDIA_CD_OTHER then
      Include(Result, mtCD_Other)
    else
    if MEDIA_SPECIAL and mf = MEDIA_SPECIAL then
      Include(Result, mtSpecial)
  finally
    FDiscRecorder.Close;
  end;
end;

function TDiscRecorder.GetPath: String;
var
  p : PWideChar;
begin
  p := nil;
  EDiscBurnerException.Check(FDiscRecorder.GetPath(p));
  Result := P;  
end;

function TDiscRecorder.GetProductID: String;
begin
  if FProductID = '' then
    ReadNames;
  Result := FProductID;
end;

function TDiscRecorder.GetProp(AName: String): Variant;
var
  Props : IPropertyStorage;
  Spec : PROPSPEC;
  V : TPropVariant;
begin
  EDiscBurnerException.Check(FDiscRecorder.GetRecorderProperties(Props));

  Spec.ulKind := PRSPEC_LPWSTR;
  Spec.lpwstr := PWideChar(WideString(AName));

  EDiscBurnerException.Check(Props.ReadMultiple(1,@Spec, @V));

  Result := PropVariantToVariant(V);
end;

function TDiscRecorder.GetRekorderType: TDiscRecorderType;
var
  t : Integer;
begin
  EDiscBurnerException.Check(FDiscRecorder.GetRecorderType(t));

  case t of
    $01: Result := rtCDR;
    $02: Result := rtCDRW;
    else
      Result := rtUnknown;
  end;

end;

function TDiscRecorder.GetRevision: String;
begin
  if Frevision = '' then
    ReadNames;
  Result := Frevision;
end;

function TDiscRecorder.GetState: TDiscRecorderState;
var
  s : Cardinal;
begin
  EDiscBurnerException.Check(FDiscRecorder.GetRecorderState(s));

  case s of
    RECORDER_DOING_NOTHING: Result := rsIdle;
    RECORDER_OPENED: Result := rsOpen;
    RECORDER_BURNING: Result := rsBurning;
    else
      Result := rsUnknown;
  end;
end;

function TDiscRecorder.GetVendor: String;
begin
  if FVendor = '' then
    ReadNames;
  Result := FVendor;
end;

class function TDiscRecorder.GUIDFromDiscRecorder(
  const ADiscRecorder: IDiscRecorder): TGUID;
var
  Buffer : Pointer;
  Fetched : Cardinal;
begin
  Buffer := @Result;
  ADiscRecorder.GetRecorderGUID(Buffer, SizeOf(TGUID), Fetched);
end;


procedure TDiscRecorder.ReadMediaInfo;
begin
  EDiscBurnerException.Check(FDiscRecorder.OpenExclusive);
  try
    EDiscBurnerException.Check(FDiscRecorder.QueryMediaInfo(FSessionCount, FLastTrack, FStartAddress, FNextWriteable, FFreeBlocks));
  finally
    FDiscRecorder.Close;
  end;
end;

procedure TDiscRecorder.ReadNames;
var
  V, P, R : PWideChar;
begin
  V := nil;
  P := nil;
  R := nil;

  EDiscBurnerException.Check(FDiscRecorder.GetDisplayNames(V, P, R));
  
  FVendor := V;
  FProductID := P;
  Frevision := R;
end;

procedure TDiscRecorder.ReadPropertyNames(const AProperties: TStrings);
var
  Props : IPropertyStorage;
  enum : IEnumSTATPROPSTG;
  s : STATPROPSTG;
  fetched : Cardinal;
begin
  EDiscBurnerException.Check(FDiscRecorder.GetRecorderProperties(Props));

  if Succeeded(Props.Enum(enum)) then
  begin
    enum.Next(1, s, @fetched);
    while fetched > 0 do
    begin
      AProperties.AddObject(s.lpwstrName, TObject(s.propid));
      enum.Next(1, s, @fetched);
    end;
  end;
end;

procedure TDiscRecorder.SetProp(AName: String; const Value: Variant);
var
  Props : IPropertyStorage;
  Spec : PROPSPEC;
  V : TPropVariant;
begin
  EDiscBurnerException.Check(FDiscRecorder.GetRecorderProperties(Props));

  Spec.ulKind := PRSPEC_LPWSTR;
  Spec.lpwstr := PWideChar(WideString(AName));

  v := VariantToPropVariant(Value);

  EDiscBurnerException.Check(Props.WriteMultiple(1, @Spec, @V, PID_FIRST_USABLE));
  EDiscBurnerException.Check(FDiscRecorder.SetRecorderProperties(Props));
end;

function TDiscRecorder.ToString: String;
begin
  Result := Vendor + ' ' + ProductID;
end;

{ TDiscRecorderList }

function TDiscRecorderList.Add(Item: TDiscRecorder): Integer;
begin
  Result := inherited Add(Item);
end;

destructor TDiscRecorderList.Destroy;
begin
  while Count > 0 do
  begin
    First.Free;
    Delete(0);
  end;

  inherited;
end;

function TDiscRecorderList.Extract(Item: TDiscRecorder): TDiscRecorder;
begin
  Result := inherited Extract(Item);
end;

function TDiscRecorderList.First: TDiscRecorder;
begin
  Result := inherited First;
end;

function TDiscRecorderList.Get(Index: Integer): TDiscRecorder;
begin
  Result := inherited Get(Index);
end;

function TDiscRecorderList.IndexByGUID(AGUID: TGUID): Integer;
var
  idx : Integer;
begin
  Result := -1;

  for idx := 0 to Count - 1 do
  begin
    if IsEqualGUID(AGUID, Items[idx].GUID) then
    begin
      Result := idx;
      break;
    end;
  end;
end;

function TDiscRecorderList.IndexOf(Item: IDiscRecorder): Integer;
begin
  Result := IndexByGUID(TDiscRecorder.GUIDFromDiscRecorder(Item));
end;

function TDiscRecorderList.IndexOf(Item: TDiscRecorder): Integer; 
begin
  Result := inherited IndexOf(Item);
end;

procedure TDiscRecorderList.Insert(Index: Integer; Item: TDiscRecorder);
begin
  inherited Insert(Index, Item);
end;

function TDiscRecorderList.Last: TDiscRecorder;
begin
  Result := inherited Last;
end;

procedure TDiscRecorderList.Put(Index: Integer; const Value: TDiscRecorder);
begin
  inherited Put(Index, Value);
end;

function TDiscRecorderList.Remove(Item: TDiscRecorder): Integer;
begin
  Result := inherited Remove(Item);
end;

procedure TDiscRecorderList.ToStrings(const AStrings: TStrings);
var
  idx : Integer;
begin
  for idx := 0 to Count - 1 do
    AStrings.AddObject(Items[idx].ToString, Items[idx]);
end;

{ EDiscBurnerException }

class procedure EDiscBurnerException.Check(AErrorCode: Integer);
var
  msg : String;
begin
  msg := '';

  case AErrorCode of
    //IMAPI_S_PROPERTIESIGNORED: msg := 'An unknown property was passed in a property set and it was ignored.';
    IMAPI_S_BUFFER_TO_SMALL: msg := 'The output buffer is too small.';
    IMAPI_E_NOTOPENED: msg := 'A call to IDiscMaster::Open has not been made.';
    IMAPI_E_NOTINITIALIZED: msg := 'A recorder object has not been initialized.';
    IMAPI_E_USERABORT: msg := 'The user canceled the operation.';
    IMAPI_E_GENERIC: msg := 'A generic error occurred.';
    IMAPI_E_MEDIUM_NOTPRESENT: msg := 'There is no disc in the device.';
    IMAPI_E_MEDIUM_INVALIDTYPE: msg := 'The media is not a type that can be used.';
    IMAPI_E_DEVICE_NOPROPERTIES: msg := 'The recorder does not support any properties.';
    IMAPI_E_DEVICE_NOTACCESSIBLE: msg := 'The device cannot be used or is already in use.';
    IMAPI_E_DEVICE_NOTPRESENT: msg := 'The device is not present or has been removed.';
    IMAPI_E_DEVICE_INVALIDTYPE: msg := 'The recorder does not support an operation.';
    IMAPI_E_INITIALIZE_WRITE: msg := 'The drive interface could not be initialized for writing.';
    IMAPI_E_INITIALIZE_ENDWRITE: msg := 'The drive interface could not be initialized for closing.';
    IMAPI_E_FILESYSTEM: msg := 'An error occurred while enabling/disabling file system access or during auto-insertion detection.';
    IMAPI_E_FILEACCESS: msg := 'An error occurred while writing the image file.';
    IMAPI_E_DISCINFO: msg := 'An error occurred while trying to read disc data from the device.';
    IMAPI_E_TRACKNOTOPEN: msg := 'An audio track is not open for writing.';
    IMAPI_E_TRACKOPEN: msg := 'An open audio track is already being staged.';
    IMAPI_E_DISCFULL: msg := 'The disc cannot hold any more data.';
    IMAPI_E_BADJOLIETNAME: msg := 'The application tried to add a badly named element to a disc.';
    IMAPI_E_INVALIDIMAGE: msg := 'The staged image is not suitable for a burn. It has been corrupted or cleared and has no usable content.';
    IMAPI_E_NOACTIVEFORMAT: msg := 'An active format master has not been selected using  IDiscMaster::SetActiveDiscMasterFormat.';
    IMAPI_E_NOACTIVERECORDER: msg := 'An active disc recorder has not been selected using  IDiscMaster::SetActiveDiscRecorder.';
    IMAPI_E_WRONGFORMAT: msg := 'A call to IJolietDiscMaster has been made when  IRedbookDiscMaster is the active format, or vice versa. To use a different format, change the format and clear the image file contents.';
    IMAPI_E_ALREADYOPEN: msg := 'A call to IDiscMaster::Open has already been made against this object by your application.';
    IMAPI_E_WRONGDISC: msg := 'The IMAPI multi-session disc has been removed from the active recorder.';
    IMAPI_E_FILEEXISTS: msg := 'The file to add is already in the image file and the overwrite flag was not set.';
    IMAPI_E_STASHINUSE: msg := 'Another application is already using the IMAPI stash file required to stage a disc image. Try again later.';
    IMAPI_E_DEVICE_STILL_IN_USE: msg := 'Another application is already using this device, so IMAPI cannot access the device.';
    IMAPI_E_LOSS_OF_STREAMING: msg := 'Content streaming was lost; a buffer under-run may have occurred.';
    IMAPI_E_COMPRESSEDSTASH: msg := 'The stash is located on a compressed volume and cannot be read.';
    IMAPI_E_ENCRYPTEDSTASH: msg := 'The stash is located on an encrypted volume and cannot be read.';
    IMAPI_E_NOTENOUGHDISKFORSTASH: msg := 'There is not enough free space to create the stash file on the specified volume.';
    IMAPI_E_REMOVABLESTASH: msg := 'The selected stash location is on a removable media.';
    IMAPI_E_CANNOT_WRITE_TO_MEDIA: msg := 'The media cannot be written to.';
    IMAPI_E_TRACK_NOT_BIG_ENOUGH: msg := 'The track is not big enough.';
    IMAPI_E_BOOTIMAGE_AND_NONBLANK_DISC: msg := 'Attempt to create a bootable image on a non-blank disc.';
    else
      OleCheck(AErrorCode);
  end;

  if msg <> '' then
    raise EDiscBurnerException.Create(msg);
end;

{ TDiscMaster }

procedure TDiscMaster.ClearContent;
begin
  EDiscBurnerException.Check(FDiscMaster.ClearFormatContent);
end;

constructor TDiscMaster.Create(AOwner: TComponent);
begin
  inherited;

  FDiscMaster := CreateComObject(MSDiscMasterObj) as IDiscMaster;

  EDiscBurnerException.Check(FDiscMaster.Open);

  ReadAvailableFormats;

  if fRedBook in FFormats then
    FRedBookDiscMaster := FDiscMaster as IRedbookDiscMaster
  else
    FRedBookDiscMaster := nil;

  if fJoliet in FFormats then
    FJolietDiscMaster := FDiscMaster as IJolietDiscMaster
  else
    FJolietDiscMaster := nil;

  FEvents := TDiscMasterEvents.Create(Self);
  EDiscBurnerException.Check(FDiscMaster.ProgressAdvise(FEvents, FEventCookie));
end;

destructor TDiscMaster.Destroy;
begin
  FDiscMaster.ProgressUnadvise(FEventCookie);
  FEvents := nil;

  if Assigned(FDiscMaster) then
    FDiscMaster.Close;
  
  inherited;
end;
  
function TDiscMaster.GetActiveFormat: TDiscMasterFormat;
var
  fmt : TGUID;
begin
  EDiscBurnerException.Check(FDiscMaster.GetActiveDiscMasterFormat(fmt));

  if IsEqualGUID(fmt, IID_IRedbookDiscMaster) then
    Result := fRedBook
  else
  if IsEqualGUID(fmt, IID_IJolietDiscMaster) then
    Result := fJoliet;
end;                

function TDiscMaster.GetActiveRecorder: IDiscRecorder;
begin
  FDiscMaster.GetActiveDiscRecorder(Result);
end;

procedure TDiscMaster.GetRecorderList(const AList: TDiscRecorderList);
var
  e : IEnumDiscRecorders;
  rec : IDiscRecorder;
  Fetched : Cardinal;
begin
  EDiscBurnerException.Check(FDiscMaster.EnumDiscRecorders(e));

  Fetched := 1;
  e.Next(1, rec, Fetched);
  while Fetched > 0 do
  begin
    AList.Add(TDiscRecorder.Create(rec));
    e.Next(1, rec, Fetched);
  end;
end;

procedure TDiscMaster.ReadAvailableFormats;
var
  e : IEnumDiscMasterFormats;
  fmtID : TGUID;
  Fetched : Cardinal;
begin
  FFormats := [];

  EDiscBurnerException.Check(FDiscMaster.EnumDiscMasterFormats(e));

  Fetched := 1;
  e.Next(1, fmtID, Fetched);

  while Fetched > 0 do
  begin
    if IsEqualGUID(fmtID, IID_IRedbookDiscMaster) then
      Include(FFormats, fRedBook)
    else
    if IsEqualGUID(fmtID, IID_IJolietDiscMaster) then
      Include(FFormats, fJoliet);

    e.Next(1, fmtID, Fetched);
  end;
end;

procedure TDiscMaster.RefreshRecorderList(const AList: TDiscRecorderList);
var
  newlist : TDiscRecorderList;
  idx : Integer;
begin
  newlist := TDiscRecorderList.Create;
  try
    GetRecorderList(newlist);

    for idx := 0 to newlist.Count - 1 do
    begin
      if AList.IndexByGUID(newlist[idx].GUID) = -1 then
        AList.Add(TDiscRecorder.Create(newlist[idx].DiscRecorder));
    end;

    for idx := AList.Count - 1 downto 0 do
    begin
      if newlist.IndexByGUID(AList[idx].GUID) = -1 then
        AList.Extract(AList[idx]).Free;
    end;


  finally
    newlist.Free;
  end;
end;

procedure TDiscMaster.SetActiveFormat(const Value: TDiscMasterFormat);
var
  unk : IInterface;
begin
  case Value of
    fJoliet: EDiscBurnerException.Check(FDiscMaster.SetActiveDiscMasterFormat(IID_IJolietDiscMaster, unk));
    fRedBook: EDiscBurnerException.Check(FDiscMaster.SetActiveDiscMasterFormat(IID_IRedbookDiscMaster, unk));
  end;
end;

procedure TDiscMaster.SetActiveRecord(const Value: IDiscRecorder);
begin
  FDiscMaster.SetActiveDiscRecorder(Value);
end;

{ TDiscMasterEvents }

constructor TDiscMasterEvents.Create(const ADiscMaster: TDiscMaster);
begin
  FDiscMaster := ADiscMaster;
  inherited Create();
end;

function TDiscMasterEvents.NotifyAddProgress(nCompletedSteps,
  nTotalSteps: Integer): HRESULT;
begin
  if Assigned(FDiscMaster) and Assigned(FDiscMaster.FOnAddProgress) then
  begin
    FDiscMaster.FOnAddProgress(nCompletedSteps, nTotalSteps);
    Result := S_OK;
  end
  else
    Result := E_NOTIMPL;
end;

function TDiscMasterEvents.NotifyBlockProgress(nCompleted,
  nTotal: Integer): HRESULT;
begin
  if Assigned(FDiscMaster) and Assigned(FDiscMaster.FOnBlockProgress) then
  begin
    FDiscMaster.FOnBlockProgress(nCompleted, nTotal);
    Result := S_OK;
  end
  else
    Result := E_NOTIMPL;
end;

function TDiscMasterEvents.NotifyBurnComplete(status: HRESULT): HRESULT;
begin
  if Assigned(FDiscMaster) and Assigned(FDiscMaster.FOnBurnComplete) then
  begin
    FDiscMaster.FOnBurnComplete(Succeeded(status), status);
    Result := S_OK;
  end
  else
    Result := E_NOTIMPL;
end;

function TDiscMasterEvents.NotifyClosingDisc(
  nEstimatedSeconds: Integer): HRESULT;
begin
  if Assigned(FDiscMaster) and Assigned(FDiscMaster.FOnClosingDisc) then
  begin
    FDiscMaster.FOnClosingDisc(nEstimatedSeconds);
    Result := S_OK;
  end
  else
    Result := E_NOTIMPL;
end;

function TDiscMasterEvents.NotifyEraseComplete(status: HRESULT): HRESULT;
begin
  if Assigned(FDiscMaster) and Assigned(FDiscMaster.FOnEraseComplete) then
  begin
    FDiscMaster.FOnEraseComplete(Succeeded(status), status);
    Result := S_OK;
  end
  else
    Result := E_NOTIMPL;
end;

function TDiscMasterEvents.NotifyPnPActivity: HRESULT;
begin
  if Assigned(FDiscMaster) and Assigned(FDiscMaster.FOnPnPActivity) then
  begin
    FDiscMaster.FOnPnPActivity();
    Result := S_OK;
  end
  else
    Result := E_NOTIMPL;
end;

function TDiscMasterEvents.NotifyPreparingBurn(
  nEstimatedSeconds: Integer): HRESULT;
begin
  if Assigned(FDiscMaster) and Assigned(FDiscMaster.FOnPreparingBurn) then
  begin
    FDiscMaster.FOnPreparingBurn(nEstimatedSeconds);
    Result := S_OK;
  end
  else
    Result := E_NOTIMPL;
end;

function TDiscMasterEvents.NotifyTrackProgress(nCurrentTrack,
  nTotalTracks: Integer): HRESULT;
begin
  if Assigned(FDiscMaster) and Assigned(FDiscMaster.FOnTrackProgress) then
  begin
    FDiscMaster.FOnTrackProgress(nCurrentTrack, nTotalTracks);
    Result := S_OK;
  end
  else
    Result := E_NOTIMPL;
end;

function TDiscMasterEvents.QueryCancel(out pbCancel: BOOL): HRESULT;
var
  Cancel : Boolean;
begin
  if Assigned(FDiscMaster) and Assigned(FDiscMaster.FOnCancelAction) then
  begin
    Cancel := false;
    FDiscMaster.FOnCancelAction(Cancel);
    pbCancel := Cancel;
    Result := S_OK;
  end
  else
    Result := E_NOTIMPL;
end;

initialization
  CoInitFlags := COINIT_APARTMENTTHREADED;

end.

unit icLayers;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1 or LGPL 2.1 with linking exception
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * Alternatively, the contents of this file may be used under the terms of the
 * Free Pascal modified version of the GNU Lesser General Public License
 * Version 2.1 (the "FPC modified LGPL License"), in which case the provisions
 * of this license are applicable instead of those above.
 * Please see the file LICENSE.txt for additional information concerning this
 * license.
 *
 * Update Date: 24th, Mar, 2014
 *
 * The Initial Developer of this unit are
 *   Ma Xiaoguang and Ma Xiaoming < gmbros[at]hotmail[dot]com >
 *
 * Contributor(s):
 *   x2nie  < x2nie[at]yahoo[dot]com >
 *
 * ***** END LICENSE BLOCK ***** *)

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}


uses
{ Delphi }
  Classes, Contnrs,
{ Graphics32 }
  GR32, GR32_Layers,
{ externals\Graphics32_add_ons }
  GR32_Add_BlendModes,
{ miniGlue }
  icCore_Items;

type
  TicLayerPixelFeature = (lpfNone,
                          lpfNormalPixelized,   // Such layers can be editing with any tools,
                                                // example of such a layer is Normal layer.
                          lpfSpecialPixelized,  // Such layers can be editing only with its own specific tools,
                                                // example of such a layer is Gradient layer.
                          lpfNonPixelized       // Such layers have dummy pixels, and can only take
                                                // effect on the blending result of beneath layers
                          );

  // mark process stage -- on the layer or on the mask
  TicLayerProcessStage = (lpsLayer, lpsMask);

  TicLayerProcessStageChanged = procedure (ASender: TObject; const AStage: TicLayerProcessStage) of object;

  { Forward Declarations }
  TicLayer = class;
  TicClassCounter = class;

  { Event }
  TicLayerChangeEvent = procedure(Sender: TObject; ALayer: TicLayer) of object;

  TicLayer = class( TCustomLayer {TigCoreItem} )
  private
    //FOnChange: TNotifyEvent;
    FChangedRect: TRect;
    FDisplayName: string;
  protected
    FUpdateCount: Integer;
    FLayerVisible          : Boolean;
    FLayerEnabled          : Boolean;               // indicate whether the layer is currently editable
    FDuplicated            : Boolean;               // indicate whether this layer is duplicated from another one
    FSelected              : Boolean;
    FLayerThumb           : TBitmap32;
    FThumbValid            : Boolean;               // indicate thumbnail has been rebuild from layer
    FOnLayerDisabled       : TNotifyEvent;
    FOnLayerEnabled        : TNotifyEvent;
    FOnPanelDblClick      : TNotifyEvent;
    FOnThumbUpdate        : TNotifyEvent;
    FOnLayerThumbDblClick : TNotifyEvent;

    function GetEmpty: Boolean; virtual;//override;
    procedure PaintLayerThumb; virtual;
    ///procedure Paint(ABuffer: TBitmap32; DstRect: TRect); virtual;

    function GetLayerThumb: TBitmap32;
    procedure SetLayerEnabled(AValue: Boolean);
    procedure SetLayerVisible(AValue: Boolean);
  public
    constructor Create(ALayerCollection: TLayerCollection); virtual; 
    function PanelList : TLayerCollection;///TigLayerList; //ref to Owner / Collection
    procedure Changed; overload;
    procedure Changed(const ARect: TRect); overload;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;

    property DisplayName          : string               read FDisplayName write FDisplayName; 
    property ChangedRect          : TRect                read FChangedRect;  //used by collection.update
    property LayerThumbnail       : TBitmap32            read GetLayerThumb;
    property IsSelected           : Boolean              read FSelected             write FSelected;
    //property IsSelected           : Boolean              read GetIsSelected;
    property IsDuplicated         : Boolean              read FDuplicated           write FDuplicated;

    //property OnChange             : TNotifyEvent         read FOnChange             write FOnChange;
    property OnPanelDblClick      : TNotifyEvent         read FOnPanelDblClick      write FOnPanelDblClick;
    property OnLayerDisabled      : TNotifyEvent         read FOnLayerDisabled       write FOnLayerDisabled;
    property OnLayerEnabled       : TNotifyEvent         read FOnLayerEnabled        write FOnLayerEnabled;
    property OnLayerThumbDblClick : TNotifyEvent         read FOnLayerThumbDblClick write FOnLayerThumbDblClick;
  published
    //for backup/restore or undo/redo or actionlist-script
    property IsLayerEnabled       : Boolean              read FLayerEnabled         write SetLayerEnabled;
    property IsLayerVisible       : Boolean              read FLayerVisible         write SetLayerVisible;
  end;

  TicLayerPanelClass = class of TicLayer;

  { TicCustomLayerPanel }

  TicBitmapLayer = class(TicLayer)
  private
    procedure DoParentLayerChanged;
    procedure SetLayerBitmap(const Value: TBitmap32);
    procedure SetMaskBitmap(const Value: TBitmap32);
  protected
    ///FOwner                : TicLayerList;
    FLayerBitmap          : TBitmap32;
    //FLayerThumb           : TBitmap32;
    FMaskBitmap           : TBitmap32;
    FMaskThumb            : TBitmap32;
    FLogoBitmap           : TBitmap32;
    FLogoThumb            : TBitmap32;
    FLayerBlendMode       : TBlendMode32;
    FLayerBlendEvent      : TPixelCombineEvent;
    FLayerProcessStage    : TicLayerProcessStage;
    FPixelFeature         : TicLayerPixelFeature;  // the pixel feature of the layer
    //FSelected             : Boolean;
    FMaskEnabled          : Boolean;               // indicate whether this layer has a mask
    FMaskLinked           : Boolean;               // indicate whether this layer is linked to a mask
    FLayerThumbEnabled    : Boolean;               // indicate whether this layer has a layer thumbnail
    FLogoThumbEnabled     : Boolean;               // indicate whether this layer has a logo thumbnail
    FRealThumbRect        : TRect;
    FDefaultLayerName     : string;
    //FLayerName            : string;                // current layer name

    //FOnChange             : TNotifyEvent;
    FOnMaskEnabled         : TNotifyEvent;
    FOnMaskDisabled        : TNotifyEvent;
    FOnMaskThumbDblClick  : TNotifyEvent;
    FOnLogoThumbDblClick  : TNotifyEvent;
    FOnProcessStageChanged : TicLayerProcessStageChanged;

    procedure Paint(Buffer: TBitmap32); override;


    function GetLayerOpacity: Byte;

    function GetThumbZoomScale(
      const ASrcWidth, ASrcHeight, AThumbWidth, AThumbHeight: Integer): Single;

    function GetRealThumbRect(
      const ASrcWidth, ASrcHeight, AThumbWidth, AThumbHeight: Integer;
      const AMarginSize: Integer = 4): TRect;
    procedure LayerBitmapChanged(Sender : TObject);
    //procedure SetLayerEnabled(AValue: Boolean);
    //procedure SetLayerVisible(AValue: Boolean);
    procedure SetMaskEnabled(AValue: Boolean);
    procedure SetMaskLinked(AValue: Boolean);
    procedure SetLayerBlendMode(AValue: TBlendMode32);
    procedure SetLayerOpacity(AValue: Byte);
    procedure SetLayerProcessStage(AValue: TicLayerProcessStage);
    procedure LayerBlend(F: TColor32; var B: TColor32; M: TColor32); virtual;
    procedure InitMask;
    procedure PaintLayerThumb; override;
    ///procedure Paint(ABuffer: TBitmap32; DstRect: TRect); override;

  public
    constructor Create(ALayerCollection: TLayerCollection); override;
    //constructor Create(ALayerCollection: TLayerCollection;
      //const ALayerWidth, ALayerHeight: Integer;
      //const AFillColor: TColor32 = $00000000); overload; virtual;

    destructor Destroy; override;


    procedure UpdateMaskThumbnail;
    procedure UpdateLogoThumbnail; virtual;

    function EnableMask: Boolean;
    function DiscardMask: Boolean;

    //property LayerBitmap          : TBitmap32            read FLayerBitmap;
    //property LayerThumbnail       : TBitmap32            read FLayerThumb;
    //property MaskBitmap           : TBitmap32            read FMaskBitmap;
    property MaskThumbnail        : TBitmap32            read FMaskThumb;
    property LogoBitmap           : TBitmap32            read FLogoBitmap;
    property LogoThumbnail        : TBitmap32            read FLogoThumb;
    //property IsLayerEnabled        : Boolean                     read FLayerEnabled          write SetLayerEnabled;
    //property IsLayerVisible       : Boolean              read FLayerVisible         write SetLayerVisible;
    property IsMaskEnabled        : Boolean              read FMaskEnabled;
    property IsMaskLinked         : Boolean              read FMaskLinked           write SetMaskLinked;
    property IsLayerThumbEnabled  : Boolean              read FLayerThumbEnabled;
    property IsLogoThumbEnabled   : Boolean              read FLogoThumbEnabled;
    //property LayerName            : string               read FLayerName            write FLayerName;
    //property LayerBlendMode       : TBlendMode32         read FLayerBlendMode       write SetLayerBlendMode;
    //property LayerOpacity         : Byte                 read GetLayerOpacity       write SetLayerOpacity;
    property LayerProcessStage    : TicLayerProcessStage read FLayerProcessStage    write SetLayerProcessStage;
    property PixelFeature         : TicLayerPixelFeature read FPixelFeature;
    //property OnChange             : TNotifyEvent         read FOnChange             write FOnChange;
    property OnThumbnailUpdate    : TNotifyEvent         read FOnThumbUpdate        write FOnThumbUpdate;
    property OnMaskEnabled         : TNotifyEvent                read FOnMaskEnabled         write FOnMaskEnabled;
    property OnMaskDisabled        : TNotifyEvent                read FOnMaskDisabled        write FOnMaskDisabled;
    property OnMaskThumbDblClick  : TNotifyEvent         read FOnMaskThumbDblClick  write FOnMaskThumbDblClick;
    property OnLogoThumbDblClick  : TNotifyEvent         read FOnLogoThumbDblClick  write FOnLogoThumbDblClick;
    property OnProcessStageChanged : TicLayerProcessStageChanged read FOnProcessStageChanged write FOnProcessStageChanged;
  published
    //for backup/restore or undo/redo or actionlist-script
    property LayerBitmap          : TBitmap32            read FLayerBitmap write SetLayerBitmap;
    property MaskBitmap           : TBitmap32            read FMaskBitmap  write SetMaskBitmap;
    property LayerBlendMode       : TBlendMode32         read FLayerBlendMode       write SetLayerBlendMode;
    property LayerOpacity         : Byte                 read GetLayerOpacity       write SetLayerOpacity;
    
  end;

  { TicNormalLayerPanel }

  TicNormalLayerPanel = class(TicBitmapLayer)
  private
    FAsBackground : Boolean; // if this layer is a background layer
    FOnMaskApplied : TNotifyEvent;
    procedure SetAsBackground(const Value: Boolean);
  public
    constructor Create(ALayerCollection: TLayerCollection); override; 
    //constructor Create(ALayerCollection: TLayerCollection;
      //const ALayerWidth, ALayerHeight: Integer;
      //const AFillColor: TColor32 = $00000000;
      //const AsBackLayerPanel: Boolean = False); overload; virtual; 

    function ApplyMask: Boolean;

    property IsAsBackground : Boolean read FAsBackground write SetAsBackground;
    property OnMaskApplied  : TNotifyEvent read FOnMaskApplied write FOnMaskApplied;
  end;



  { TicClassRec }

  TicClassRec = class(TObject)
  private
    FName  : ShortString;
    FCount : Integer;
  public
    constructor Create(const AClassName: ShortString);

    property Name  : ShortString read FName  write FName;
    property Count : Integer     read FCount write FCount;
  end;


  { TicClassCounter }

  TicClassCounter = class(TPersistent)
  private
    FItems : TObjectList;

    function GetIndex(const AClassName: ShortString): Integer;
    function IsValidIndex(const AIndex: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Increase(const AClassName: ShortString);
    procedure Decrease(const AClassName: ShortString);
    procedure Clear;

    function GetCount(const AClassName: ShortString): Integer;
  end;


const
  LAYER_THUMB_SIZE = 36;
  LAYER_LOGO_SIZE  = 36;
  EMPTY_RECT: TRect = (Left: 0; Top: 0; Right: 0; Bottom: 0);

implementation

uses
{ Delphi }
  SysUtils, Graphics, Math,
{ Graphics32 }
  GR32_LowLevel, GR32_Resamplers, GR32_Blend,
{ miniGlue lib }
  icBase,icPaintFuncs;

{ TicBitmapLayer }

{constructor TicBitmapLayer.Create(ALayerCollection: TLayerCollection;
  const ALayerWidth, ALayerHeight: Integer;
  const AFillColor: TColor32 = $00000000);
  //we have problem of polymorphism when introducing non-uniform constructor
begin
  Create(AOwner);
  with FLayerBitmap do
  begin
    SetSize(ALayerWidth, ALayerHeight);
    Clear(AFillColor);
  end;

  FRealThumbRect := GetRealThumbRect(ALayerWidth, ALayerHeight,
                                     LAYER_THUMB_SIZE, LAYER_THUMB_SIZE);

// test
//  Self.EnableMask;
//  Self.FMaskBitmap.FillRectS( 20, 20, 120, 120, $FF7F7F7F );
//  Self.IsMaskLinked := True;
//  Self.UpdateMaskThumbnail;
end;}

destructor TicBitmapLayer.Destroy;
begin
  FLayerBlendEvent      := nil;
  ///FOwner                := nil;
  //FOnChange             := nil;
  FOnThumbUpdate        := nil;
  FOnPanelDblClick      := nil;
  FOnLayerThumbDblClick := nil;
  FOnMaskThumbDblClick  := nil;
  FOnLogoThumbDblClick  := nil;
  FOnProcessStageChanged := nil;
  
  FLayerBitmap.Free;
  FLayerThumb.Free;
  FMaskBitmap.Free;
  FMaskThumb.Free;
  FLogoBitmap.Free;
  FLogoThumb.Free;
  
  inherited;
end;

function TicBitmapLayer.GetLayerOpacity: Byte;
begin
  Result := FLayerBitmap.MasterAlpha and $FF;
end;

function TicBitmapLayer.GetThumbZoomScale(
  const ASrcWidth, ASrcHeight, AThumbWidth, AThumbHeight: Integer): Single;
var
  ws, hs : Single;
begin
  if (ASrcWidth <= AThumbWidth) and (ASrcHeight <= AThumbHeight) then
  begin
    Result := 1.0;
  end
  else
  begin
    ws := AThumbWidth  / ASrcWidth;
    hs := AThumbHeight / ASrcHeight;

    if ws < hs then
    begin
      Result := ws;
    end
    else
    begin
      Result := hs;
    end;
  end;
end;

function TicBitmapLayer.GetRealThumbRect(
  const ASrcWidth, ASrcHeight, AThumbWidth, AThumbHeight: Integer;
  const AMarginSize: Integer = 4): TRect;
var
  LThumbWidth  : Integer;
  LThumbHeight : Integer;
  LScale       : Single;
begin
  LScale := GetThumbZoomScale(ASrcWidth, ASrcHeight,
    AThumbWidth - AMarginSize, AThumbHeight - AMarginSize);

  LThumbWidth  := Round(ASrcWidth  * LScale);
  LThumbHeight := Round(ASrcHeight * LScale);

  with Result do
  begin
    Left   := (LAYER_THUMB_SIZE - LThumbWidth)  div 2;
    Top    := (LAYER_THUMB_SIZE - LThumbHeight) div 2;
    Right  := Left + LThumbWidth;
    Bottom := Top  + LThumbHeight;
  end;
end;

procedure TicLayer.SetLayerEnabled(AValue: Boolean);
begin
  if FLayerEnabled <> AValue then
  begin
    FLayerEnabled := AValue;

    if FLayerEnabled then
    begin
      if Assigned(FOnLayerEnabled) then
      begin
        FOnLayerEnabled(Self);
      end;
    end
    else
    begin
      FOnLayerDisabled(Self);
    end;
  end;
end;

procedure TicLayer.SetLayerVisible(AValue: Boolean);
begin
  if FLayerVisible <> AValue then
  begin
    FLayerVisible := AValue;
    Changed;
  end;
end;

procedure TicBitmapLayer.SetMaskEnabled(AValue: Boolean);
begin
  if FMaskEnabled <> AValue then
  begin
    FMaskEnabled := AValue;

    if FMaskEnabled then
    begin
      FLayerProcessStage := lpsMask;
      FMaskLinked        := True;
      
      InitMask;
    end
    else
    begin
      FLayerProcessStage := lpsLayer;
      FMaskLinked        := False;
      
      FreeAndNil(FMaskBitmap);
      FreeAndNil(FMaskThumb);
    end;
  end;
end;

procedure TicBitmapLayer.SetMaskLinked(AValue: Boolean);
begin
  if FMaskLinked <> AValue then
  begin
    FMaskLinked := AValue;
    Changed;
  end;
end;

procedure TicBitmapLayer.SetLayerBlendMode(AValue: TBlendMode32);
begin
  if FLayerBlendMode <> AValue then
  begin
    FLayerBlendMode  := AValue;
    FLayerBlendEvent := GetBlendMode( Ord(FLayerBlendMode) );
    
    Changed;
  end;
end;

procedure TicBitmapLayer.SetLayerOpacity(AValue: Byte);
begin
  if (FLayerBitmap.MasterAlpha and $FF) <> AValue then
  begin
    FLayerBitmap.MasterAlpha := AValue;
    Changed;
  end;
end;

procedure TicBitmapLayer.SetLayerProcessStage(
  AValue: TicLayerProcessStage);
begin
  if FLayerProcessStage <> AValue then
  begin
    FLayerProcessStage := AValue;

    if Assigned(FOnProcessStageChanged) then
    begin
      FOnProcessStageChanged(Self, FLayerProcessStage);
    end;
  end;
end;

procedure TicBitmapLayer.LayerBlend(
  F: TColor32; var B: TColor32; M: TColor32);
begin
  FLayerBlendEvent(F, B, M);
end;

procedure TicBitmapLayer.InitMask;
begin
  if not Assigned(FMaskBitmap) then
  begin
    FMaskBitmap := TBitmap32.Create;
  end;

  with FMaskBitmap do
  begin
    SetSizeFrom(FLayerBitmap);
    Clear(clWhite32);
  end;

  if not Assigned(FMaskThumb) then
  begin
    FMaskThumb := TBitmap32.Create;
  end;

  with FMaskThumb do
  begin
    SetSize(LAYER_THUMB_SIZE, LAYER_THUMB_SIZE);
  end;

  UpdateMaskThumbnail;
end;


procedure TicBitmapLayer.UpdateMaskThumbnail;
var
  LRect : TRect;
begin
  LRect := FRealThumbRect;
  
  FMaskThumb.Clear( Color32(clBtnFace) );
  FMaskThumb.Draw(LRect, FMaskBitmap.BoundsRect, FMaskBitmap);

  InflateRect(LRect, 1, 1);
  FMaskThumb.FrameRectS(LRect, clBlack32);

  if Assigned(FOnThumbUpdate) then
  begin
    FOnThumbUpdate(Self);
  end; 
end;

procedure TicBitmapLayer.UpdateLogoThumbnail;
var
  LRect : TRect;
begin
  LRect := GetRealThumbRect(FLogoBitmap.Width, FLogoBitmap.Height,
                            LAYER_LOGO_SIZE, LAYER_LOGO_SIZE);

  FLogoThumb.Clear( Color32(clBtnFace) );
  FLogoThumb.Draw(LRect, FLogoBitmap.BoundsRect, FLogoBitmap);

  InflateRect(LRect, 1, 1);
  FLogoThumb.FrameRectS(LRect, clBlack32);

  if Assigned(FOnThumbUpdate) then
  begin
    FOnThumbUpdate(Self);
  end;
end;

procedure TicLayer.Changed;
begin
  Changed(EMPTY_RECT); //I can't determine the whole bounds of vector (non raster) layer.
  
  {FThumbValid := False;
  FChangedRect := EMPTY_RECT;
  inherited Changed(False); //true = allitem, false = self

  if Assigned(Collection) then
  begin
    PanelList.BlendLayers;
  end;

  if Assigned(FOnChange) then
  begin
    FOnChange(Self);
  end;}
end;

procedure TicLayer.Changed(const ARect: TRect);
begin
  FThumbValid := False;

  if (FUpdateCount > 0) then
    Exit;

  FChangedRect := ARect;
  inherited ///{Changed(False)};
  {if Assigned(Collection) then
  begin
    PanelList.BlendLayers(ARect);
  end;

  if Assigned(FOnChange) then
  begin
    FOnChange(Self);
  end;}
end;

// enable mask, if it has not ...
function TicBitmapLayer.EnableMask: Boolean;
begin
  Result := False;

  if not FMaskEnabled then
  begin
    SetMaskEnabled(True);

    if Assigned(FOnMaskEnabled) then
    begin
      FOnMaskEnabled(Self);
    end;

    Result := FMaskEnabled;
  end;
end;

// discard the mask settings, if any
function TicBitmapLayer.DiscardMask: Boolean;
begin
  Result := False;

  if FMaskEnabled then
  begin
    SetMaskEnabled(False);
    Self.Changed;

    if Assigned(FOnMaskDisabled) then
    begin
      FOnMaskDisabled(Self);
    end;

    Result := not FMaskEnabled;
  end;

end;

procedure TicBitmapLayer.DoParentLayerChanged;
begin
  ///FOwner.DoLayerChanged(Self);
end;

procedure TicBitmapLayer.SetLayerBitmap(const Value: TBitmap32);
begin
  FLayerBitmap.Assign(Value);
  FThumbValid := False;
end;

procedure TicBitmapLayer.SetMaskBitmap(const Value: TBitmap32);
begin
  FMaskBitmap.Assign(Value);
end;


procedure TicBitmapLayer.Paint(Buffer: TBitmap32{; DstRect: TRect});
var
  i            : Integer;
  k, j, x, y : Integer;
  LRectWidth   : Integer;
  LRectHeight  : Integer;
  m            : Cardinal;
  //LLayerPanel  : TicBitmapLayer;
  LResultRow   : PColor32Array;
  LLayerRow    : PColor32Array;
  LMaskRow     : PColor32Array;
  LRect       : TRect;
  DstRect: TRect;

  ShiftX, ShiftY : TFloat;
  {LPixelCount : Integer;
  LForeBits   : PColor32;
  LBackBits   : PColor32;
  LMaskBits   : PColor32;}
begin
  // copied from procedure TCustomBitmap32.DrawTo(Dst: TCustomBitmap32; const DstRect, SrcRect: TRect);
  {
  procedure StretchTransfer(
    Dst: TCustomBitmap32; DstRect: TRect; DstClip: TRect;
    Src: TCustomBitmap32; SrcRect: TRect;
    Resampler: TCustomResampler;
    CombineOp: TDrawMode; CombineCallBack: TPixelCombineEvent);
  }
  {StretchTransfer(
    ABuffer, ABuffer.ClipRect, ABuffer.ClipRect,
    LayerBitmap, ABuffer.ClipRect,
    LayerBitmap.Resampler,
    LayerBitmap.DrawMode, LayerBlend);

Exit;}
  DstRect := Buffer.ClipRect;
  
  if FLayerBitmap.Empty then Exit;
  LayerCollection.GetViewportShift(ShiftX, ShiftY);

  LRect := MakeRect(FloatRect(ShiftX, ShiftY, ShiftX+FLayerBitmap.Width -1, ShiftY+FLayerBitmap.Height-1));

  Buffer.Draw(LRect, FLayerBitmap.BoundsRect, FLayerBitmap);
  Exit;
  
  // for sure the range check
  GR32.IntersectRect(LRect, DstRect, LRect);
  if EqualRect(LRect, EMPTY_RECT) then Exit;

  LRectWidth  := LRect.Right - LRect.Left + 1;
  LRectHeight := LRect.Bottom - LRect.Top + 1;

  for j := 0 to (LRectHeight - 1) do
  begin
    y := j + LRect.Top;

    // get entries of one line pixels on the background bitmap ...
    LResultRow := Buffer.ScanLine[y];

    // get entries of one line pixels on each layer bitmap ...
    LLayerRow := FLayerBitmap.ScanLine[y];

    if IsMaskEnabled and IsMaskLinked then
    begin
      // get entries of one line pixels on each layer mask bitmap, if any ...
      LMaskRow := FMaskBitmap.ScanLine[y];
    end;

    for k := 0 to (LRectWidth - 1) do
    begin
      x := k + LRect.Left;

      Assert(x * y < FLayerBitmap.Width * FLayerBitmap.Height, 'FLayerBitmap');
      Assert(x * y < Buffer.Width * Buffer.Height, 'ABuffer');

      if Self.Index = 0 then
      begin
        //LResultRow[x] := $00000000;
      end;

      // blending ...
      m := FLayerBitmap.MasterAlpha;

      if IsMaskEnabled and IsMaskLinked then
      begin
        // adjust the MasterAlpha with Mask setting
        m := m * (LMaskRow[x] and $FF) div 255;
      end;
      
      {$RANGECHECKS OFF}
      LayerBlend(LLayerRow[x], LResultRow[x], m);
      {$RANGECHECKS ON}
    end;
  end;

  //EMMS;


{
  LMaskBits := nil;
  //FLayerBitmap.SetSize(FLayerWidth, FLayerHeight);


  LPixelCount := LayerBitmap.Width * LayerBitmap.Height;
  LForeBits := @FLayerBitmap.Bits[0];
  LBackBits := @ABuffer.Bits[0];

  if IsMaskEnabled and IsMaskLinked then
  begin
    LMaskBits := @FMaskBitmap.Bits[0];
  end;

  for j := 1 to LPixelCount do
  begin
    m := FLayerBitmap.MasterAlpha;

    if IsMaskEnabled and IsMaskLinked then
    begin
      // adjust the MasterAlpha with Mask setting
      m := m * (LMaskBits^ and $FF) div 255;
    end;

    LayerBlend(LForeBits^, LBackBits^, m);

    Inc(LForeBits);
    Inc(LBackBits);
    if IsMaskEnabled and IsMaskLinked then
    begin
      Inc(LMaskBits);
    end;
  end;}
end;

constructor TicBitmapLayer.Create(ALayerCollection: TLayerCollection);
begin
  inherited {Create(AOwner)};///
  ///FOwner             := AOwner;
  FLayerBlendMode    := bbmNormal32;
  FLayerBlendEvent   := GetBlendMode( Ord(FLayerBlendMode) );
  FDuplicated        := False;
  FLayerVisible      := True;
  FSelected          := True;
  FLayerEnabled      := True;
  FMaskEnabled       := False;
  FMaskLinked        := False;
  FLayerThumbEnabled := False;
  FLogoThumbEnabled  := False;
  FDefaultLayerName  := '';
  //FLayerName         := '';
  FLayerProcessStage := lpsLayer;
  FPixelFeature      := lpfNone;

  //FOnChange             := nil;
  FOnThumbUpdate        := nil;
  FOnMaskEnabled         := nil;
  FOnMaskDisabled        := nil;
  FOnPanelDblClick      := nil;
  FOnLayerThumbDblClick := nil;
  FOnMaskThumbDblClick  := nil;
  FOnLogoThumbDblClick  := nil;
  FOnProcessStageChanged := nil;

  FLayerBitmap := TBitmap32.Create;
  with FLayerBitmap do
  begin
    DrawMode    := dmBlend;
    CombineMode := cmMerge;

    //SetSize(ALayerWidth, ALayerHeight);
    //Clear(AFillColor);
  end;

  FMaskBitmap := nil;
  FMaskThumb  := nil;
  FLogoBitmap := nil;
  FLogoThumb  := nil;

  FRealThumbRect := GetRealThumbRect(32,32,
                                     LAYER_THUMB_SIZE, LAYER_THUMB_SIZE);
end;

{ TicNormalLayerPanel }

{constructor TicNormalLayerPanel.Create(ALayerCollection: TLayerCollection;
  const ALayerWidth, ALayerHeight: Integer;
  const AFillColor: TColor32 = $00000000;
  const AsBackLayerPanel: Boolean = False);
    //we have problem of polymorphism when introducing non-uniform constructor
begin
  //inherited Create(AOwner, ALayerWidth, ALayerHeight, AFillColor);
  inherited Create(AOwner);

  FPixelFeature      := lpfNormalPixelized;
  FAsBackground      := AsBackLayerPanel;
  FDefaultLayerName  := 'Layer';
  FLayerThumbEnabled := True;

  if FAsBackground then
  begin
    FDefaultLayerName := 'Background';
    DisplayName       := FDefaultLayerName;
  end;

  FLayerThumb := TBitmap32.Create;
  with FLayerThumb do
  begin
    SetSize(LAYER_THUMB_SIZE, LAYER_THUMB_SIZE);
  end;

  UpdateLayerThumbnail;
end;}

// applying the mask settings to the alpha channel of each pixel on the
// layer bitmap, and then disable the mask
function TicNormalLayerPanel.ApplyMask: Boolean;
var
  i           : Integer;
  a, m        : Cardinal;
  LLayerBits  : PColor32;
  LMaskBits   : PColor32;
  LMaskLinked : Boolean;
begin
  Result := False;

  if FMaskEnabled then
  begin
    LLayerBits := @FLayerBitmap.Bits[0];
    LMaskBits  := @FMaskBitmap.Bits[0];

    for i := 1 to (FLayerBitmap.Width * FLayerBitmap.Height) do
    begin
      m := LMaskBits^ and $FF;
      a := LLayerBits^ shr 24 and $FF;
      a := a * m div 255;

      LLayerBits^ := (a shl 24) or (LLayerBits^ and $FFFFFF);

      Inc(LLayerBits);
      Inc(LMaskBits);
    end;

    LMaskLinked := Self.FMaskLinked;  // remember the mask linked state for later use
    SetMaskEnabled(False);            // disable the mask first

    // if not link with mask, after disable the mask, we need to merge layer
    // to get new blending result, otherwise we don't need to do it, because
    // the current blending result is correct 
    if not LMaskLinked then
    begin
      ///if Assigned(Collection) then
      ///begin
      ///  FOwner.BlendLayers;
      ///end;
    end;

    
    
    Result := not FMaskEnabled;

    if Assigned(FOnMaskApplied) then
    begin
      FOnMaskApplied(Self);
    end;
  end;
end;

constructor TicNormalLayerPanel.Create(ALayerCollection: TLayerCollection);
begin
  //Create(AOwner, 0,0,0, False);
  inherited {Create(AOwner)};
  FPixelFeature      := lpfNormalPixelized;
  FAsBackground      := False;//AsBackLayerPanel;
  FDefaultLayerName  := 'Layer';
  FLayerThumbEnabled := True;

  

  {FLayerThumb := TBitmap32.Create;
  with FLayerThumb do
  begin
    SetSize();
  end;}

//  UpdateLayerThumbnail;

end;


{ TicClassRec }

constructor TicClassRec.Create(const AClassName: ShortString);
begin
  inherited Create;

  FName  := AClassName;
  FCount := 1;
end;

{ TicClassCounter }

constructor TicClassCounter.Create;
begin
  inherited;

  FItems := TObjectList.Create;
end;

destructor TicClassCounter.Destroy;
begin
  FItems.Clear;
  FItems.Free;

  inherited;
end;

function TicClassCounter.GetIndex(const AClassName: ShortString): Integer;
var
  i    : Integer;
  LRec : TicClassRec;
begin
  Result := -1;

  if AClassName = '' then
  begin
    Exit;
  end;

  if FItems.Count > 0 then
  begin
    for i := 0 to (FItems.Count - 1) do
    begin
      LRec := TicClassRec(FItems.Items[i]);

      if AClassName = LRec.ClassName then
      begin
        Result := i;
        Break;
      end;
    end;
  end;
end;

function TicClassCounter.IsValidIndex(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FItems.Count);
end;

// This method will increase the number of a class name in the counter.
procedure TicClassCounter.Increase(const AClassName: ShortString);
var
  LIndex : Integer;
  LRec   : TicClassRec;
begin
  if AClassName = '' then
  begin
    Exit;
  end;

  LIndex := Self.GetIndex(AClassName);

  if Self.IsValidIndex(LIndex) then
  begin
    LRec       := TicClassRec(FItems.Items[LIndex]);
    LRec.Count := LRec.Count + 1;
  end
  else
  begin
    LRec := TicClassRec.Create(AClassName);
    FItems.Add(LRec);
  end;
end;

// This method will decrease the number of a class name in the counter.
procedure TicClassCounter.Decrease(const AClassName: ShortString);
var
  LIndex : Integer;
  LRec   : TicClassRec;
begin
  if AClassName = '' then
  begin
    Exit;
  end;

  LIndex := Self.GetIndex(AClassName);

  if Self.IsValidIndex(LIndex) then
  begin
    LRec       := TicClassRec(FItems.Items[LIndex]);
    LRec.Count := LRec.Count - 1;

    if LRec.Count = 0 then
    begin
      FItems.Delete(LIndex);
    end;
  end;
end;

procedure TicClassCounter.Clear;
begin
  FItems.Clear;
end;

function TicClassCounter.GetCount(const AClassName: ShortString): Integer;
var
  i    : Integer;
  LRec : TicClassRec;
begin
  Result := 0;

  if AClassName = '' then
  begin
    Exit;
  end;

  if FItems.Count > 0 then
  begin
    for i := 0 to (FItems.Count - 1) do
    begin
      LRec := TicClassRec(FItems.Items[i]);

      if AClassName = LRec.Name then
      begin
        Inc(Result);
      end;
    end;
  end;
end;



constructor TicLayer.Create(ALayerCollection: TLayerCollection);
begin
  inherited {Create(AOwner)};///
end;

function TicLayer.PanelList: TLayerCollection;///TigLayerList;
begin
  Result := LayerCollection;// Collection as TicLayerList;
end;

function TicLayer.GetEmpty: Boolean;
begin
  Result := True;
end;

{procedure TicLayer.Paint(ABuffer: TBitmap32; DstRect: TRect);
begin

end;}

function TicLayer.GetLayerThumb: TBitmap32;
begin
  if not Assigned(FLayerThumb) then
  begin
    FLayerThumb := TBitmap32.Create();
    FLayerThumb.SetSize( LAYER_THUMB_SIZE, LAYER_THUMB_SIZE);
  end;
    
  if not FThumbValid then
  begin
    PaintLayerThumb; // repaint only when needed
    FThumbValid := True;
  end;
  Result := FLayerThumb;
end;

procedure TicLayer.PaintLayerThumb;
begin

end;

procedure TicBitmapLayer.LayerBitmapChanged(Sender: TObject);
begin
  FThumbValid := False;
end;

procedure TicBitmapLayer.PaintLayerThumb;
var
  LRect : TRect;
  LBmp  : TBitmap32;
begin
  LRect := FRealThumbRect;

  FLayerThumb.Clear( Color32(clBtnFace) ); //maybe create
  DrawCheckerboardPattern(FLayerThumb, LRect, True);

  LBmp := TBitmap32.Create;
  try
    // The thumbnail should not shows the MasterAlpha settings of the layer.
    // The MasterAlpha only takes effect when layer blending.
    LBmp.Assign(FLayerBitmap);
    LBmp.MasterAlpha := 255;
    LBmp.ResamplerClassName := 'TLanczosKernel';

    FLayerThumb.Draw(LRect, LBmp.BoundsRect, LBmp);
  finally
    LBmp.Free;
  end;

  InflateRect(LRect, 1, 1);
  FLayerThumb.FrameRectS(LRect, clBlack32);
end;

procedure TicLayer.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TicLayer.EndUpdate;
begin
  Assert(FUpdateCount > 0, 'Unpaired TThreadPersistent.EndUpdate');
  Dec(FUpdateCount);
end;

procedure TicNormalLayerPanel.SetAsBackground(const Value: Boolean);
begin
  FAsBackground := Value;
  if FAsBackground then
  begin
    FDefaultLayerName := 'Background';
    DisplayName       := FDefaultLayerName;
  end;

end;

end.

unit igLayers;

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
  igCore_Items;

type
  TigLayerPixelFeature = (lpfNone,
                          lpfNormalPixelized,   // Such layers can be editing with any tools,
                                                // example of such a layer is Normal layer.
                          lpfSpecialPixelized,  // Such layers can be editing only with its own specific tools,
                                                // example of such a layer is Gradient layer.
                          lpfNonPixelized       // Such layers have dummy pixels, and can only take
                                                // effect on the blending result of beneath layers
                          );

  // mark process stage -- on the layer or on the mask
  TigLayerProcessStage = (lpsLayer, lpsMask);

  TigLayerProcessStageChanged = procedure (ASender: TObject; const AStage: TigLayerProcessStage) of object;

  { Forward Declarations }
  TigLayer = class;
  TigLayerList = class;
  TigClassCounter = class;

  { Event }
  TigLayerChangeEvent = procedure(Sender: TObject; ALayer: TigLayer) of object;

  TigLayer = class( TCustomLayer {TigCoreItem} )
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
    procedure Paint(ABuffer: TBitmap32; DstRect: TRect); virtual;

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

  TigLayerPanelClass = class of TigLayer;

  { TigCustomLayerPanel }

  TigBitmapLayer = class(TigLayer)
  private
    procedure DoParentLayerChanged;
    procedure SetLayerBitmap(const Value: TBitmap32);
    procedure SetMaskBitmap(const Value: TBitmap32);
  protected
    ///FOwner                : TigLayerList;
    FLayerBitmap          : TBitmap32;
    //FLayerThumb           : TBitmap32;
    FMaskBitmap           : TBitmap32;
    FMaskThumb            : TBitmap32;
    FLogoBitmap           : TBitmap32;
    FLogoThumb            : TBitmap32;
    FLayerBlendMode       : TBlendMode32;
    FLayerBlendEvent      : TPixelCombineEvent;
    FLayerProcessStage    : TigLayerProcessStage;
    FPixelFeature         : TigLayerPixelFeature;  // the pixel feature of the layer
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
    FOnProcessStageChanged : TigLayerProcessStageChanged;

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
    procedure SetLayerProcessStage(AValue: TigLayerProcessStage);
    procedure LayerBlend(F: TColor32; var B: TColor32; M: TColor32); virtual;
    procedure InitMask;
    procedure PaintLayerThumb; override;
    procedure Paint(ABuffer: TBitmap32; DstRect: TRect); override;

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
    property LayerProcessStage    : TigLayerProcessStage read FLayerProcessStage    write SetLayerProcessStage;
    property PixelFeature         : TigLayerPixelFeature read FPixelFeature;
    //property OnChange             : TNotifyEvent         read FOnChange             write FOnChange;
    property OnThumbnailUpdate    : TNotifyEvent         read FOnThumbUpdate        write FOnThumbUpdate;
    property OnMaskEnabled         : TNotifyEvent                read FOnMaskEnabled         write FOnMaskEnabled;
    property OnMaskDisabled        : TNotifyEvent                read FOnMaskDisabled        write FOnMaskDisabled;
    property OnMaskThumbDblClick  : TNotifyEvent         read FOnMaskThumbDblClick  write FOnMaskThumbDblClick;
    property OnLogoThumbDblClick  : TNotifyEvent         read FOnLogoThumbDblClick  write FOnLogoThumbDblClick;
    property OnProcessStageChanged : TigLayerProcessStageChanged read FOnProcessStageChanged write FOnProcessStageChanged;
  published
    //for backup/restore or undo/redo or actionlist-script
    property LayerBitmap          : TBitmap32            read FLayerBitmap write SetLayerBitmap;
    property MaskBitmap           : TBitmap32            read FMaskBitmap  write SetMaskBitmap;
    property LayerBlendMode       : TBlendMode32         read FLayerBlendMode       write SetLayerBlendMode;
    property LayerOpacity         : Byte                 read GetLayerOpacity       write SetLayerOpacity;
    
  end;

  { TigNormalLayerPanel }

  TigNormalLayerPanel = class(TigBitmapLayer)
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

  { TigLayerList }

  TigLayerCombinedEvent = procedure (ASender: TObject; const ARect: TRect) of object;
  TigMergeLayerEvent = procedure (AResultPanel: TigBitmapLayer) of object;

  TigLayerList = class(TigCoreCollection)
  private
    //FItems                : TObjectList;
    FSelectedPanel        : TigBitmapLayer;
    FCombineResult        : TBitmap32;
    //FLayerWidth           : Integer; use CombineResult.Width instead
    //FLayerHeight          : Integer;

    FOnLayerCombined      : TigLayerCombinedEvent;
    FOnSelectionChanged   : TNotifyEvent;
    FOnLayerOrderChanged  : TNotifyEvent;
    FOnMergeVisibleLayers : TigMergeLayerEvent;
    FOnFlattenLayers      : TigMergeLayerEvent;

    FPanelTypeCounter     : TigClassCounter;
    FOnLayerChanged: TigLayerChangeEvent;

    
    function GetPanelMaxIndex: Integer;
    function GetSelectedPanelIndex: Integer;
    function GetLayerPanel(AIndex: Integer): TigBitmapLayer;
    function GetVisbileLayerCount: Integer;
    function GetVisibleNormalLayerCount: Integer;

    procedure BlendLayers; overload;
    procedure BlendLayers(const ARect: TRect); overload;
    procedure DeleteVisibleLayerPanels;
    procedure DeselectAllPanels;
    procedure SetLayerPanelInitialName(ALayerPanel: TigBitmapLayer);
    procedure DoLayerChanged(ALayer : TigBitmapLayer);
  public
    constructor Create(AOwner: TComponent); override; 
    destructor Destroy; override;
    procedure Update(Item: TCollectionItem); override;{ COLLECTION. }

    procedure Add(ALayer: TigLayer);
    procedure SimpleAdd(ALayer: TigBitmapLayer); 
    procedure Insert(AIndex: Integer; ALayer: TigLayer);
    procedure Move(ACurIndex, ANewIndex: Integer);
    procedure SelectLayerPanel(const AIndex: Integer);
    procedure DeleteSelectedLayerPanel;
    procedure DeleteLayerPanel(AIndex: Integer);
    procedure CancelLayerPanel(AIndex: Integer);

    function CanFlattenLayers: Boolean;
    function CanMergeSelectedLayerDown: Boolean;
    function CanMergeVisbleLayers: Boolean;
    function FlattenLayers: Boolean;
    function MergeSelectedLayerDown: Boolean;
    function MergeVisibleLayers: Boolean;
    function GetHiddenLayerCount: Integer;

    property CombineResult                : TBitmap32             read FCombineResult;
    //property Count                        : Integer               read GetPanelCount;
    property MaxIndex                     : Integer               read GetPanelMaxIndex;
    property SelectedIndex                : Integer               read GetSelectedPanelIndex;
    property LayerPanels[AIndex: Integer] : TigBitmapLayer   read GetLayerPanel;
    property SelectedPanel                : TigBitmapLayer   read FSelectedPanel;
    property OnLayerChanged               : TigLayerChangeEvent   read FOnLayerChanged       write FOnLayerChanged; 
    property OnLayerCombined              : TigLayerCombinedEvent read FOnLayerCombined      write FOnLayerCombined;
    property OnSelectionChanged           : TNotifyEvent          read FOnSelectionChanged   write FOnSelectionChanged;
    property OnLayerOrderChanged          : TNotifyEvent          read FOnLayerOrderChanged  write FOnLayerOrderChanged;
    property OnMergeVisibleLayers         : TigMergeLayerEvent    read FOnMergeVisibleLayers write FOnMergeVisibleLayers;
    property OnFlattenLayers              : TigMergeLayerEvent    read FOnFlattenLayers      write FOnFlattenLayers;
  end;


  { TigClassRec }

  TigClassRec = class(TObject)
  private
    FName  : ShortString;
    FCount : Integer;
  public
    constructor Create(const AClassName: ShortString);

    property Name  : ShortString read FName  write FName;
    property Count : Integer     read FCount write FCount;
  end;


  { TigClassCounter }

  TigClassCounter = class(TPersistent)
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

  {HELPER FUNC}
  function TigNormalLayerPanel_Create(APanelList : TigLayerList;
    AWidth,AHeight: Integer; AColor : TColor32;  AsBackground : Boolean): TigNormalLayerPanel;
  
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
  igBase,igPaintFuncs;

function TigNormalLayerPanel_Create(APanelList : TigLayerList;
  AWidth,AHeight: Integer; AColor : TColor32;  AsBackground : Boolean): TigNormalLayerPanel;
begin
  Result := TigNormalLayerPanel.Create(nil);
  Result.LayerBitmap.SetSize(AWidth,AHeight);
  Result.LayerBitmap.Clear(AColor);
  Result.FAsBackground := AsBackGround;
  //Result.Collection := APanelList;
end;    

{ TigBitmapLayer }

{constructor TigBitmapLayer.Create(ALayerCollection: TLayerCollection;
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

destructor TigBitmapLayer.Destroy;
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

function TigBitmapLayer.GetLayerOpacity: Byte;
begin
  Result := FLayerBitmap.MasterAlpha and $FF;
end;

function TigBitmapLayer.GetThumbZoomScale(
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

function TigBitmapLayer.GetRealThumbRect(
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

procedure TigLayer.SetLayerEnabled(AValue: Boolean);
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

procedure TigLayer.SetLayerVisible(AValue: Boolean);
begin
  if FLayerVisible <> AValue then
  begin
    FLayerVisible := AValue;
    Changed;
  end;
end;

procedure TigBitmapLayer.SetMaskEnabled(AValue: Boolean);
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

procedure TigBitmapLayer.SetMaskLinked(AValue: Boolean);
begin
  if FMaskLinked <> AValue then
  begin
    FMaskLinked := AValue;
    Changed;
  end;
end;

procedure TigBitmapLayer.SetLayerBlendMode(AValue: TBlendMode32);
begin
  if FLayerBlendMode <> AValue then
  begin
    FLayerBlendMode  := AValue;
    FLayerBlendEvent := GetBlendMode( Ord(FLayerBlendMode) );
    
    Changed;
  end;
end;

procedure TigBitmapLayer.SetLayerOpacity(AValue: Byte);
begin
  if (FLayerBitmap.MasterAlpha and $FF) <> AValue then
  begin
    FLayerBitmap.MasterAlpha := AValue;
    Changed;
  end;
end;

procedure TigBitmapLayer.SetLayerProcessStage(
  AValue: TigLayerProcessStage);
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

procedure TigBitmapLayer.LayerBlend(
  F: TColor32; var B: TColor32; M: TColor32);
begin
  FLayerBlendEvent(F, B, M);
end;

procedure TigBitmapLayer.InitMask;
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


procedure TigBitmapLayer.UpdateMaskThumbnail;
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

procedure TigBitmapLayer.UpdateLogoThumbnail;
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

procedure TigLayer.Changed;
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

procedure TigLayer.Changed(const ARect: TRect);
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
function TigBitmapLayer.EnableMask: Boolean;
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
function TigBitmapLayer.DiscardMask: Boolean;
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

procedure TigBitmapLayer.DoParentLayerChanged;
begin
  ///FOwner.DoLayerChanged(Self);
end;

procedure TigBitmapLayer.SetLayerBitmap(const Value: TBitmap32);
begin
  FLayerBitmap.Assign(Value);
  FThumbValid := False;
end;

procedure TigBitmapLayer.SetMaskBitmap(const Value: TBitmap32);
begin
  FMaskBitmap.Assign(Value);
end;

procedure TigBitmapLayer.Paint(ABuffer: TBitmap32; DstRect: TRect);
var
  i            : Integer;
  k, j, x, y : Integer;
  LRectWidth   : Integer;
  LRectHeight  : Integer;
  m            : Cardinal;
  //LLayerPanel  : TigBitmapLayer;
  LResultRow   : PColor32Array;
  LLayerRow    : PColor32Array;
  LMaskRow     : PColor32Array;
  LRect       : TRect;

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

  if FLayerBitmap.Empty then Exit;
  LRect := Rect(0,0, FLayerBitmap.Width -1, FLayerBitmap.Height-1);

  
  // for sure the range check
  GR32.IntersectRect(LRect, DstRect, LRect);
  if EqualRect(LRect, EMPTY_RECT) then Exit;

  LRectWidth  := LRect.Right - LRect.Left + 1;
  LRectHeight := LRect.Bottom - LRect.Top + 1;

  for j := 0 to (LRectHeight - 1) do
  begin
    y := j + LRect.Top;

    // get entries of one line pixels on the background bitmap ...
    LResultRow := ABuffer.ScanLine[y];

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
      Assert(x * y < ABuffer.Width * ABuffer.Height, 'ABuffer');

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

constructor TigBitmapLayer.Create(ALayerCollection: TLayerCollection);
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

{ TigNormalLayerPanel }

{constructor TigNormalLayerPanel.Create(ALayerCollection: TLayerCollection;
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
function TigNormalLayerPanel.ApplyMask: Boolean;
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

constructor TigNormalLayerPanel.Create(ALayerCollection: TLayerCollection);
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

{ TigLayerList }

constructor TigLayerList.Create(AOwner: TComponent);
begin
  ///inherited Create(AOwner,TigLayer );
  inherited;///

  FSelectedPanel        := nil;
  FOnLayerCombined      := nil;
  FOnSelectionChanged   := nil;
  FOnLayerOrderChanged  := nil;
  FOnMergeVisibleLayers := nil;
  FOnFlattenLayers      := nil;

  //FItems            := TObjectList.Create(True);
  FPanelTypeCounter := TigClassCounter.Create;

  FCombineResult := TBitmap32.Create;
  with FCombineResult do
  begin
    DrawMode := dmBlend;
  end;
end;

destructor TigLayerList.Destroy;
begin
  //FItems.Clear;
  //FItems.Free;
  FCombineResult.Free;
  FPanelTypeCounter.Free;
  
  inherited;
end;

function TigLayerList.GetPanelMaxIndex: Integer;
begin
  Result := Count - 1;
end;

function TigLayerList.GetSelectedPanelIndex: Integer;
var
  i : Integer;
begin
  Result := -1;

  if (Count > 0) and Assigned(FSelectedPanel) then
  begin
    for i := 0 to (Count - 1) do
    begin
      if FSelectedPanel = Self.LayerPanels[i] then
      begin
        Result := i;
        Break;
      end;
    end;
  end;
end;

function TigLayerList.GetLayerPanel(AIndex: Integer): TigBitmapLayer;
begin
  Result := nil;

  if ISValidIndex(AIndex) then
  begin
    Result := TigBitmapLayer(Items[AIndex]);
  end;
end;

function TigLayerList.GetVisbileLayerCount: Integer;
var
  i : Integer;
begin
  Result := 0;

  if Count > 0 then
  begin
    for i := 0 to (Count - 1) do
    begin
      if Self.LayerPanels[i].IsLayerVisible then
      begin
        Inc(Result);
      end;
    end;
  end;
end;

// TODO: Perhaps need to rename this function
// to 'GetVisibleNormalPixelizedLayerCount'
function TigLayerList.GetVisibleNormalLayerCount: Integer;
var
  i           : Integer;
  LLayerPanel : TigBitmapLayer;
begin
  Result := 0;

  if Count > 0 then
  begin
    for i := 0 to (Count - 1) do
    begin
      LLayerPanel := Self.LayerPanels[i];

      if LLayerPanel.IsLayerVisible and
         (LLayerPanel.PixelFeature = lpfNormalPixelized) then
      begin
        Inc(Result);
      end;
    end;
  end;
end;

procedure TigLayerList.BlendLayers;
var
  i, j        : Integer;
  LPixelCount : Integer;
  m           : Cardinal;
  LLayerPanel : TigBitmapLayer;
begin
  BlendLayers(FCombineResult.BoundsRect);
  Exit;
{

  FCombineResult.BeginUpdate;
  try
    FCombineResult.Clear($00000000);

    if Count > 0 then
    begin
      LPixelCount := FLayerWidth * FLayerHeight;

      for i := 0 to (Count - 1) do
      begin
        LLayerPanel := GetLayerPanel(i);

        if (not LLayerPanel.IsLayerVisible) //or LLayerPanel.FLayerBitmap.Empty
        then
          Continue;

        //LLayerPanel.Paint(FCombineResult, LRect);
      end;
    end;

  finally
    FCombineResult.EndUpdate;
  end;

  if Assigned(FOnLayerCombined) then
  begin
    FOnLayerCombined( Self, Rect(0, 0, FLayerWidth, FLayerHeight) );
  end;  }
end;

procedure TigLayerList.BlendLayers(const ARect: TRect);
var
  LRect        : TRect;
  i            : Integer;
  x, y, xx, yy : Integer;
  LRectWidth   : Integer;
  LRectHeight  : Integer;
  m            : Cardinal;
  LLayerPanel  : TigBitmapLayer;
  LResultRow   : PColor32Array;
  LLayerRow    : PColor32Array;
  LMaskRow     : PColor32Array;
begin
{.$RANGECHECKS OFF}

  LMaskRow := nil;
  if EqualRect(ARect, EMPTY_RECT) then
  begin
    LRect := Rect(0,0, FCombineResult.Width -1, FCombineResult.Height-1);

  end
  else
  begin
    LRect.Left   := Math.Min(ARect.Left, ARect.Right);
    LRect.Right  := Math.Max(ARect.Left, ARect.Right);
    LRect.Top    := Math.Min(ARect.Top, ARect.Right);
    LRect.Bottom := Math.Max(ARect.Top, ARect.Bottom);
    GR32.IntersectRect(LRect, LRect, FCombineResult.BoundsRect);
  end;

  if (LRect.Left = LRect.Right) or
     (LRect.Top = LRect.Bottom) or
     (LRect.Left > FCombineResult.Width) or
     (LRect.Top > FCombineResult.Height) or
     (LRect.Right <= 0) or
     (LRect.Bottom <= 0) then
  begin
    Exit;
  end;

  LRectWidth  := LRect.Right - LRect.Left + 1;
  LRectHeight := LRect.Bottom - LRect.Top + 1;

  FCombineResult.BeginUpdate;
  try
    FCombineResult.ClipRect := LRect; //save to global usage


      for i := 0 to (Count - 1) do
      begin
        LLayerPanel := GetLayerPanel(i);

        if (not LLayerPanel.IsLayerVisible) {or LLayerPanel.FLayerBitmap.Empty} then
          Continue;

        LLayerPanel.Paint(FCombineResult, LRect);
      end;


    //original-------------------------------------
    {if Count > 0 then
    begin
      for y := 0 to (LRectHeight - 1) do
      begin
        yy := y + LRect.Top;

        if (yy < 0) or (yy >= FLayerHeight) then
        begin
          Continue;
        end;

        // get entries of one line pixels on the background bitmap ...
        LResultRow := FCombineResult.ScanLine[yy];

        for i := 0 to (Count - 1) do
        begin
          LLayerPanel := GetLayerPanel(i);

          if not LLayerPanel.IsLayerVisible then
          begin
            Continue;
          end;

          // get entries of one line pixels on each layer bitmap ...
          LLayerRow := LLayerPanel.FLayerBitmap.ScanLine[yy];

          if LLayerPanel.IsMaskEnabled and LLayerPanel.IsMaskLinked then
          begin
            // get entries of one line pixels on each layer mask bitmap, if any ...
            LMaskRow := LLayerPanel.FMaskBitmap.ScanLine[yy];
          end;

          for x := 0 to (LRectWidth - 1) do
          begin
            xx := x + LRect.Left;

            if (xx < 0) or (xx >= FLayerWidth) then
            begin
              Continue;
            end;

            if i = 0 then
            begin
              LResultRow[xx] := $00000000;
            end;

            // blending ...
            m := LLayerPanel.FLayerBitmap.MasterAlpha;

            if LLayerPanel.IsMaskEnabled and LLayerPanel.IsMaskLinked then
            begin
              // adjust the MasterAlpha with Mask setting
              m := m * (LMaskRow[xx] and $FF) div 255;
            end;

            LLayerPanel.LayerBlend(LLayerRow[xx], LResultRow[xx], m);
          end;
        end;
      end;
    end;}

  finally
    FCombineResult.ResetClipRect;
    FCombineResult.EndUpdate;
  end;

  if Assigned(FOnLayerCombined) then
  begin
    FOnLayerCombined(Self, LRect);
  end;

{.$RANGECHECKS ON}
end;

procedure TigLayerList.DeleteVisibleLayerPanels;
var
  i           : Integer;
  LLayerPanel : TigBitmapLayer;
begin
  if Count > 0 then
  begin
    for i := (Count - 1) downto 0 do
    begin
      LLayerPanel := Self.LayerPanels[i];

      if LLayerPanel.IsLayerVisible then
      begin
        Delete(i);
      end;
    end;
  end;
end;

procedure TigLayerList.DeselectAllPanels;
var
  i : Integer;
begin
  if Count > 0 then
  begin
    Self.FSelectedPanel := nil;

    for i := 0 to (Count - 1) do
    begin
      // NOTICE :
      //   Setting with field FSelected, not with property Selected,
      //   for avoiding the setter of property be invoked.
      GetLayerPanel(i).FSelected := False;
    end;
  end;
end;

procedure TigLayerList.SetLayerPanelInitialName(
  ALayerPanel: TigBitmapLayer);
var
  LNumber : Integer;
begin
  if Assigned(ALayerPanel) then
  begin
    if ALayerPanel is TigNormalLayerPanel then
    begin
      if TigNormalLayerPanel(ALayerPanel).IsAsBackground then
      begin
        Exit;
      end;
    end;

    LNumber := FPanelTypeCounter.GetCount(ALayerPanel.ClassName);
    ///ALayerPanel.DisplayName := ALayerPanel.FDefaultLayerName + ' ' + IntToStr(LNumber);
  end;
end;

procedure TigLayerList.Add(ALayer: TigLayer);
begin
  if Assigned(ALayer) then
  begin
    //FItems.Add(APanel);
    ///ALayer.Collection := self;


    // we don't count background layers
    if ALayer is TigNormalLayerPanel then
    begin
      if not TigNormalLayerPanel(ALayer).IsAsBackground then
      begin
        FPanelTypeCounter.Increase(ALayer.ClassName);
      end;
    end
    else
    begin
      FPanelTypeCounter.Increase(ALayer.ClassName);
    end;

    // first adding
    if (Count = 1) and (ALayer is TigBitmapLayer) then
    begin
      //FLayerWidth  := TigBitmapLayer(APanel).FLayerBitmap.Width;
      //FLayerHeight := TigBitmapLayer(APanel).FLayerBitmap.Height;

      FCombineResult.SetSizeFrom(TigBitmapLayer(ALayer).FLayerBitmap);
    end;

    BlendLayers;
    SelectLayerPanel(Count - 1);

    if not FSelectedPanel.IsDuplicated then
    begin
      SetLayerPanelInitialName(FSelectedPanel);
    end;
  end;
end;

// This procedure does the similar thing as the Add() procedure above,
// but it won't blend layers, invoke callback functions, etc.
// It simply adds a panel to a layer panel list.
procedure TigLayerList.SimpleAdd(ALayer: TigBitmapLayer);
begin
  if Assigned(ALayer) then
  begin
    //FItems.Add(APanel);
///    ALayer.Collection := Self;
    
    // first adding
    if (Count = 1) and (ALayer is TigBitmapLayer) then
    begin
      FCombineResult.SetSizeFrom(TigBitmapLayer(ALayer).FLayerBitmap);
    end;
  end;
end; 

procedure TigLayerList.Insert(AIndex: Integer;
  ALayer: TigLayer);
begin
  if Assigned(ALayer) then
  begin
    AIndex := Clamp(AIndex, 0, Count);
    //FItems.Insert(AIndex, APanel);
    ///ALayer.Collection := Self;
    ALayer.Index := AIndex;

    // we don't count background layers
    if (not ALayer.IsDuplicated) then
    if ALayer is TigNormalLayerPanel then
    begin
      if not TigNormalLayerPanel(ALayer).IsAsBackground then
      begin
        FPanelTypeCounter.Increase(ALayer.ClassName);
      end;
    end
    else
    begin
      FPanelTypeCounter.Increase(ALayer.ClassName);
    end;
    
    BlendLayers;
    SelectLayerPanel(AIndex);

    if not FSelectedPanel.IsDuplicated then
    begin
      SetLayerPanelInitialName(FSelectedPanel);
    end;
  end;
end;

procedure TigLayerList.Move(ACurIndex, ANewIndex: Integer);
begin
  if IsValidIndex(ACurIndex) and
     IsValidIndex(ANewIndex) and
     (ACurIndex <> ANewIndex) then
  begin
    //FItems.Move(ACurIndex, ANewIndex);
    LayerPanels[ACurIndex].Index := ANewIndex;
    GIntegrator.InvalidateListeners;
    BlendLayers;

    if Assigned(FOnLayerOrderChanged) then
    begin
      FOnLayerOrderChanged(Self);
    end;
  end;
end;

procedure TigLayerList.SelectLayerPanel(const AIndex: Integer);
var
  LLayerPanel : TigBitmapLayer;
begin
  LLayerPanel := GetLayerPanel(AIndex);
  if Assigned(LLayerPanel) then
  begin
    if FSelectedPanel <> LLayerPanel then
    begin
      DeselectAllPanels;

      FSelectedPanel           := LLayerPanel;
      FSelectedPanel.FSelected := True;

      if Assigned(FOnSelectionChanged) then
      begin
        FOnSelectionChanged(Self);
      end;
      GIntegrator.InvalidateListeners; // such layer listbox doesn't invalidate her self
    end;

    // always enable the layer when it is selected
    FSelectedPanel.IsLayerEnabled := True;
  end;
  GIntegrator.SelectionChanged;
  
end;

procedure TigLayerList.DeleteSelectedLayerPanel;
var
  LIndex : Integer;
begin
  LIndex := GetSelectedPanelIndex;
  DeleteLayerPanel(LIndex);
end;

procedure TigLayerList.DeleteLayerPanel(AIndex: Integer);
begin
  if (Count = 1) or ( not IsValidIndex(AIndex) ) then
  begin
    Exit;
  end;

  FSelectedPanel := nil;

  Delete(AIndex);
  BlendLayers;

  // select the previous layer ...

  AIndex := AIndex - 1;

  if AIndex < 0 then
  begin
    AIndex := 0;
  end;

  SelectLayerPanel(AIndex);
  GIntegrator.InvalidateListeners;
end;

// This method is similar to DeleteLayerPanel(), but it will also
// modifys the statistics in Panel Type Counter.
procedure TigLayerList.CancelLayerPanel(AIndex: Integer);
var
  LPanel : TigBitmapLayer;
begin
  if (Count = 1) or ( not IsValidIndex(AIndex) ) then
  begin
    Exit;
  end;

  LPanel := Self.LayerPanels[AIndex];
  ///Self.FPanelTypeCounter.Decrease(LPanel.DisplayName);

  DeleteLayerPanel(AIndex);
end;

function TigLayerList.CanFlattenLayers: Boolean;
begin
  Result := False;

  if Count > 0 then
  begin
    if Count = 1 then
    begin
      if Self.SelectedPanel is TigNormalLayerPanel then
      begin
        // If the only layer is a Normal layer but not as background layer,
        // we could flatten it as a background layer
        Result := not TigNormalLayerPanel(Self.SelectedPanel).IsAsBackground;
      end;
    end
    else
    begin
      // we could flatten layers as long as the numnber of layers
      // is greater than one
      Result := True;
    end;
  end;
end;

function TigLayerList.CanMergeSelectedLayerDown: Boolean;
var
  LPrevIndex : Integer;
  LPrevPanel : TigBitmapLayer;
begin
  Result     := False;
  LPrevIndex := Self.SelectedIndex - 1;

  if IsValidIndex(LPrevIndex) then
  begin
    LPrevPanel := Self.LayerPanels[LPrevIndex];

    // can only merge down to a visible Normal layer
    Result := FSelectedPanel.IsLayerVisible and
              LPrevPanel.IsLayerVisible and 
              (LPrevPanel.PixelFeature = lpfNormalPixelized);
  end;
end;

function TigLayerList.CanMergeVisbleLayers: Boolean;
begin
  Result := FSelectedPanel.IsLayerVisible and
            (GetVisibleNormalLayerCount > 0) and (GetVisbileLayerCount > 1);
end;

function TigLayerList.FlattenLayers: Boolean;
var
  LBackPanel : TigBitmapLayer;
begin
  Result := CanFlattenLayers;
  
  if Result then
  begin
    ///LBackPanel := TigNormalLayerPanel.Create(Self);
    LBackPanel.LayerBitmap.SetSizeFrom( FCombineResult );

    with LBackPanel do
    begin
      // Note that, if the background layer has special properties as the one
      // in Photoshop, we should draw the combined result onto a white
      // background. But for now, we haven't figure out how to do the same
      // thing as PS, so we just make the combined result as the background
      // layer.
      
      //LayerBitmap.Draw(0, 0, FCombineResult);
      LayerBitmap.Assign(FCombineResult);
    end;

    Clear;
    FPanelTypeCounter.Clear;
    Self.Add(LBackPanel);
    Self.SelectLayerPanel(0);

    if Assigned(FOnFlattenLayers) then
    begin
      FOnFlattenLayers(Self.FSelectedPanel);
    end;
  end;
end;

function TigLayerList.MergeSelectedLayerDown: Boolean;
var
  i             : Integer;
  m             : Cardinal;
  LMaskEffected : Boolean;
  LPrevIndex    : Integer;
  LPrevPanel    : TigBitmapLayer;
  LForeBits     : PColor32;
  LBackBits     : PColor32;
  LMaskBits     : PColor32;
begin
  Result := CanMergeSelectedLayerDown;

  LMaskEffected := False;
  LMaskBits     := nil;

  if Result then
  begin
    LPrevIndex := SelectedIndex - 1;
    LPrevPanel := Self.LayerPanels[LPrevIndex];

    LForeBits := @FSelectedPanel.FLayerBitmap.Bits[0];
    LBackBits := @LPrevPanel.FLayerBitmap.Bits[0];

    if (FSelectedPanel.IsMaskEnabled) and (FSelectedPanel.IsMaskLinked) then
    begin
      LMaskBits     := @FSelectedPanel.FMaskBitmap.Bits[0];
      LMaskEffected := True;
    end;

    for i := 1 to (FCombineResult.Width * FCombineResult.Height) do
    begin
      m := FSelectedPanel.FLayerBitmap.MasterAlpha;
      
      if LMaskEffected then
      begin
        // adjust the MasterAlpha with Mask setting
        m := m * (LMaskBits^ and $FF) div 255;
      end;

      FSelectedPanel.LayerBlend(LForeBits^, LBackBits^, m);

      Inc(LForeBits);
      Inc(LBackBits);

      if LMaskEffected then
      begin
        Inc(LMaskBits);
      end;
    end;


    // this routine will make the previous layer be selected automatically
    DeleteSelectedLayerPanel;
    BlendLayers;
  end;
end;

function TigLayerList.MergeVisibleLayers: Boolean;
var
  LMergedPanel  : TigBitmapLayer;
  LAsBackground : Boolean;
begin
  Result := Self.CanMergeVisbleLayers;

  if Result then
  begin
    LAsBackground := False;
    
    if FSelectedPanel is TigNormalLayerPanel then
    begin
      LAsBackground := TigNormalLayerPanel(FSelectedPanel).FAsBackground;
    end;

    LMergedPanel := TigNormalLayerPanel_Create(Self,
       FCombineResult.Width, FCombineResult.Height, $00000000, LAsBackground);

    with LMergedPanel do
    begin
      FLayerBitmap.Assign(FCombineResult);

      ///FDisplayName := FSelectedPanel.FDisplayName;
    end;
    
    DeleteVisibleLayerPanels;
    FSelectedPanel := nil;

    //FItems.Insert(0, LMergedPanel);
    LMergedPanel.Index := 0;
    Self.SelectLayerPanel(0);

    if Assigned(FOnMergeVisibleLayers) then
    begin
      FOnMergeVisibleLayers(Self.FSelectedPanel);
    end;
  end;
end;

{function TigLayerList.IsValidIndex(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Count);
end;}

function TigLayerList.GetHiddenLayerCount: Integer;
var
  i : Integer;
begin
  Result := 0;

  if Count > 0 then
  begin
    for i := 0 to (Count - 1) do
    begin
      if not Self.LayerPanels[i].IsLayerVisible then
      begin
        Inc(Result);
      end;
    end;
  end;
end;

procedure TigLayerList.DoLayerChanged(ALayer: TigBitmapLayer);
begin
  if Assigned(FOnLayerChanged) then
    FOnLayerChanged(Self, ALayer);
end;

procedure TigLayerList.Update(Item: TCollectionItem);
// this chance to invalidate the document apperance
begin
  //inherited;
  if Assigned(Item) then
    BlendLayers( TigLayer(Item).FChangedRect )
  else
    BlendLayers( EMPTY_RECT );  

end;

{ TigClassRec }

constructor TigClassRec.Create(const AClassName: ShortString);
begin
  inherited Create;

  FName  := AClassName;
  FCount := 1;
end;

{ TigClassCounter }

constructor TigClassCounter.Create;
begin
  inherited;

  FItems := TObjectList.Create;
end;

destructor TigClassCounter.Destroy;
begin
  FItems.Clear;
  FItems.Free;

  inherited;
end;

function TigClassCounter.GetIndex(const AClassName: ShortString): Integer;
var
  i    : Integer;
  LRec : TigClassRec;
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
      LRec := TigClassRec(FItems.Items[i]);

      if AClassName = LRec.ClassName then
      begin
        Result := i;
        Break;
      end;
    end;
  end;
end;

function TigClassCounter.IsValidIndex(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FItems.Count);
end;

// This method will increase the number of a class name in the counter.
procedure TigClassCounter.Increase(const AClassName: ShortString);
var
  LIndex : Integer;
  LRec   : TigClassRec;
begin
  if AClassName = '' then
  begin
    Exit;
  end;

  LIndex := Self.GetIndex(AClassName);

  if Self.IsValidIndex(LIndex) then
  begin
    LRec       := TigClassRec(FItems.Items[LIndex]);
    LRec.Count := LRec.Count + 1;
  end
  else
  begin
    LRec := TigClassRec.Create(AClassName);
    FItems.Add(LRec);
  end;
end;

// This method will decrease the number of a class name in the counter.
procedure TigClassCounter.Decrease(const AClassName: ShortString);
var
  LIndex : Integer;
  LRec   : TigClassRec;
begin
  if AClassName = '' then
  begin
    Exit;
  end;

  LIndex := Self.GetIndex(AClassName);

  if Self.IsValidIndex(LIndex) then
  begin
    LRec       := TigClassRec(FItems.Items[LIndex]);
    LRec.Count := LRec.Count - 1;

    if LRec.Count = 0 then
    begin
      FItems.Delete(LIndex);
    end;
  end;
end;

procedure TigClassCounter.Clear;
begin
  FItems.Clear;
end;

function TigClassCounter.GetCount(const AClassName: ShortString): Integer;
var
  i    : Integer;
  LRec : TigClassRec;
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
      LRec := TigClassRec(FItems.Items[i]);

      if AClassName = LRec.Name then
      begin
        Inc(Result);
      end;
    end;
  end;
end;



constructor TigLayer.Create(ALayerCollection: TLayerCollection);
begin
  inherited {Create(AOwner)};///
end;

function TigLayer.PanelList: TLayerCollection;///TigLayerList;
begin
  Result := LayerCollection;// Collection as TigLayerList;
end;

function TigLayer.GetEmpty: Boolean;
begin
  Result := True;
end;

procedure TigLayer.Paint(ABuffer: TBitmap32; DstRect: TRect);
begin

end;

function TigLayer.GetLayerThumb: TBitmap32;
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

procedure TigLayer.PaintLayerThumb;
begin

end;

procedure TigBitmapLayer.LayerBitmapChanged(Sender: TObject);
begin
  FThumbValid := False;
end;

procedure TigBitmapLayer.PaintLayerThumb;
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

procedure TigLayer.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TigLayer.EndUpdate;
begin
  Assert(FUpdateCount > 0, 'Unpaired TThreadPersistent.EndUpdate');
  Dec(FUpdateCount);
end;

procedure TigNormalLayerPanel.SetAsBackground(const Value: Boolean);
begin
  FAsBackground := Value;
  if FAsBackground then
  begin
    FDefaultLayerName := 'Background';
    DisplayName       := FDefaultLayerName;
  end;

end;

end.

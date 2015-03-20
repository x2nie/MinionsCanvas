unit icBase;

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
 * The Initial Developer of the Original Code is
 *   x2nie  < x2nie[at]yahoo[dot]com >
 *
 *
 * Contributor(s):
 *
 *
 * ***** END LICENSE BLOCK ***** *)

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

(* ***** BEGIN NOTICE BLOCK *****
 *
 * I decide to combine Tools, PaintViewer & PaintAgent into this single file
 * for increase readability and easier to integrate those objects.
 *
 * ***** END NOTICE BLOCK *****)

uses
  SysUtils, Classes,IniFiles, Controls,
{$IFDEF FPC}
  LCLIntf, LCLType, LMessages, Types,
{$ELSE}
  Windows, Messages,
{$ENDIF}
  Forms, Contnrs,
  GR32, GR32_Image, GR32_Layers,
  icLayers;

type

  { far definitions }
  TicPaintBox = class;                  // drawing canvas
  TicTool = class;                      // drawing tool
  TicToolClass = class of TicTool;
  TicIntegrator = class;
  TicAgent = class;                     // bridge for link-unlink, avoid error
  TicTheme = class;
  TicUndoRedoManager = class;
  TicCommand = class;

  TicDebugLog = procedure(Sender : TObject; const Msg : string; ident: Integer = 0) of object;

  TicChangingEvent = procedure(Sender: TObject; const Info : string) of object;
  TicMouseEvent = procedure(Sender: TicPaintBox; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; Layer: TicLayer) of object;
  TicMouseMoveEvent = procedure(Sender: TicPaintBox; Shift: TShiftState;
    X, Y: Integer; Layer: TicLayer) of object;


  TicIntegrator = class(TComponent)     // Event Organizer. hidden component
  {   An Integrator is a hidden component responsible for managing traffic
      (integration) behind all objects linked to it including (but not limited):
      * the drawing canvas,
      * corresponding active drawing tool,
      * switching between layers / picking the real bitmap of paint operation
      * switching between drawing canvas (in MDI mode)
      * undo / redo
      * debug log
  }
  private
    FListeners: TList;
    FInstancesList : TList;
    FActiveTool: TicTool;
    FActivePaintBox: TicPaintBox;
    FActiveUndoRedo: TicUndoRedoManager;
    function IsToolSwitched(ATool: TicTool):Boolean;
    function LoadTool(AToolClass: TicToolClass): TicTool;
    procedure MaintainTool(ATool : TicTool);
    function ReadyToSwitchTool : Boolean;
    procedure SetActivePaintBox(const Value: TicPaintBox);
    procedure SetActiveUndoRedo(const Value: TicUndoRedoManager);
  protected
    procedure ActivePaintBoxSwitched;
    procedure DoMouseDown(Sender: TicPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TicLayer);
    procedure DoMouseMove(Sender: TicPaintBox; Shift: TShiftState; X,
      Y: Integer; Layer: TicLayer);
    procedure DoMouseUp(Sender: TicPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TicLayer);
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure RegisterListener(AAgent: TicAgent);

  public
    constructor Create(AOwner: TComponent); override;
    function ActivateTool(AToolClass: TicToolClass):Boolean; overload;
    function ActivateTool(AToolInstance: TicTool):Boolean; overload;

    //listeners
    procedure InvalidateListeners;
    procedure SelectionChanged;

    property ActivePaintBox : TicPaintBox read FActivePaintBox
      write SetActivePaintBox;
    property ActiveTool : TicTool read FActiveTool;
    property ActiveUndoRedo : TicUndoRedoManager read FActiveUndoRedo write SetActiveUndoRedo;
  end;

  TicAgent = class(TComponent)
  { the event listener of drawing-canvas
    or redirection for such arranging layers
  }
  private
    FOnActivePaintBoxSwitched: TNotifyEvent;
    FOnInvalidateListener: TNotifyEvent;
    FOnSelectionChange: TNotifyEvent;
  protected
    //procedure DoActivePaintBoxSwitched;
  public
    constructor Create(AOwner: TComponent); override;
    procedure AfterConstruction; override;
  published
    property OnActivePaintBoxSwitch: TNotifyEvent read FOnActivePaintBoxSwitched write FOnActivePaintBoxSwitched;
    property OnInvalidateListener: TNotifyEvent read FOnInvalidateListener write FOnInvalidateListener;
    property OnSelectionChange: TNotifyEvent read FOnSelectionChange write FOnSelectionChange; 
  end;


  TicPaintBox = class(TCustomImage32)
  { the drawing-canvas object
  }
  private
    FUndoRedo: TicUndoRedoManager;
    FSelectedLayer: TicLayer;
    procedure AfterLayerCombined(ASender: TObject; const ARect: TRect);
    function GetLayerList: TLayerCollection;
    procedure SetSelectedLayer(const Value: TicLayer);

  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure SetFocus; override;

    //property LayerList : TLayerCollection read FLayerList;
    //property LayerList : TLayerCollection read GetLayerList; //deprecated, use Layers instead
    property SelectedLayer : TicLayer read FSelectedLayer write SetSelectedLayer;

    property UndoRedo : TicUndoRedoManager read FUndoRedo; 
  published
    property Align;
    property Bitmap;
    property BitmapAlign;
    property Color;
    property Constraints;
    property Cursor;
    property ParentColor;
    property ParentShowHint;
    property PopupMenu;
    property RepaintMode;
    property Scale;
    property ScaleMode;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Options default [pboAutoFocus];
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnPaintStage;
    property OnResize;    
  end;

  TicTool = class(TComponent)
  private
    FCursor: TCursor;
    //FImage32: TCustomImage32;
    FOnAfterDblClick: TNotifyEvent;
    FOnBeforeDblClick: TNotifyEvent;
    FOnFinalEdit: TNotifyEvent;
    FOnChanging: TicChangingEvent;
    //function GetToolInstance(index: TgmToolClass): TgmTool;
  protected
    FModified: Boolean; //wether this tool has success or canceled to made a modification of target.
    FOnAfterMouseDown: TicMouseEvent;
    FOnBeforeMouseUp: TicMouseEvent;
    FOnAfterMouseUp: TicMouseEvent;
    FOnBeforeMouseDown: TicMouseEvent;
    FOnBeforeMouseMove: TicMouseMoveEvent;
    FOnAfterMouseMove: TicMouseMoveEvent;

    //Events. Descendant may inherited. Polymorpism.
    function CanBeSwitched: Boolean; virtual;
    procedure MouseDown(Sender: TicPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TicLayer); virtual;
    procedure MouseMove(Sender: TicPaintBox; Shift: TShiftState; X,
      Y: Integer; Layer: TicLayer); virtual;
    procedure MouseUp(Sender: TicPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TicLayer); virtual;
    procedure KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); virtual;
    procedure KeyPress(Sender: TObject; var Key: Char); virtual;
    procedure KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState); virtual;
    procedure DblClick(Sender: TObject); virtual;
    procedure FinalEdit;virtual;


    //Events used internally. Descendant may NOT inherits. call by integrator
    procedure DoMouseDown(Sender: TicPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TicLayer); //virtual;
    procedure DoMouseMove(Sender: TicPaintBox; Shift: TShiftState; X,
      Y: Integer; Layer: TicLayer); //virtual;
    procedure DoMouseUp(Sender: TicPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TicLayer); //virtual;
    procedure DoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); //virtual;
    procedure DoKeyPress(Sender: TObject; var Key: Char); //virtual;
    procedure DoKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState); //virtual;
    procedure DoDblClick(Sender: TObject);
    procedure DoChanging(const Info : string);
  published
    property Cursor : TCursor read FCursor write FCursor; //default cursor when activated.
    property OnBeforeMouseDown : TicMouseEvent read FOnBeforeMouseDown write FOnBeforeMouseDown; 
    property OnAfterMouseDown : TicMouseEvent read FOnAfterMouseDown write FOnAfterMouseDown;
    property OnBeforeMouseUp : TicMouseEvent read FOnBeforeMouseUp write FOnBeforeMouseUp;
    property OnAfterMouseUp : TicMouseEvent read FOnAfterMouseUp write FOnAfterMouseUp;
    property OnBeforeMouseMove : TicMouseMoveEvent read FOnBeforeMouseMove write FOnBeforeMouseMove;
    property OnAfterMouseMove : TicMouseMoveEvent read FOnAfterMouseMove write FOnAfterMouseMove;
    property OnBeforeDblClick : TNotifyEvent read FOnBeforeDblClick write FOnBeforeDblClick;
    property OnAfterDblClick : TNotifyEvent read FOnAfterDblClick write FOnAfterDblClick;
    property OnChanging  : TicChangingEvent read FOnChanging write FOnChanging; //prepare undo signal
    property OnFinalEdit : TNotifyEvent read FOnFinalEdit write FOnFinalEdit; 
  end;

  TicTheme = class(TComponent)
  end;

    { it should attached to TicPaintBox
  }
  TicUndoRedoManager = class(TComponent)
  private
    FItemIndex: Integer;
    FLayers: TLayerCollection;
    function GetCount: Integer;

  protected
    FUndoList : TStrings;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function IsUndoAllowed : Boolean;
    function IsRedoAllowed : Boolean;

    procedure Undo;
    procedure Redo;
    procedure UndoTo(ATargetIndex : Integer);
    procedure RedoTo(ATargetIndex : Integer);
    procedure AddUndo(AUndo : TicCommand; AComment : string);
    function  LastCommand : TicCommand;
    //function AllocateUndo(AUndoMessage : string) : PigUndoStruct;

    property Strings :TStrings read FUndoList;
    property Count : Integer read GetCount;
    property LayerList : TLayerCollection read FLayers write FLayers;
    property ItemIndex : Integer read FItemIndex;
  published

  end;

  TicCommand = class(TComponent)
  private
    FManager: TicUndoRedoManager;
  protected
    {properties}
    function LayerList : TLayerCollection;
    property Manager : TicUndoRedoManager read FManager write FManager;
  protected
    {helper, call internally}
    procedure RestorePreviousState; virtual;
  public
    constructor Create(AOwner : TComponent); override;
    {call by outside}
    procedure Play;   virtual; abstract;        // run within action list | redo
    procedure Revert; virtual;                  // run by undo | restore
    class function Signature : string; virtual;  //do not localize!

  end;

  TicCommandClass = class of TicCommand;

  //for checkin checkout / inter-comparing between commands
  TicCmdLayer = class(TicCommand)
  private
    FLayerIndex: Integer;
    FLayerClass: TicLayerPanelClass;
  public
    property  LayerClass : TicLayerPanelClass read FLayerClass write FLayerClass;
  published
    property LayerIndex: Integer read FLayerIndex write FLayerIndex;
  end;

  //modify = edit surface, such by penTool, pencilTool, add/remove node on vectorLayer
  TicCmdLayer_Modify = class(TicCmdLayer)
  private
    FOriginalStream,
    FModifiedStream : TStream;
    FLayer: TicLayer;
  protected
    procedure RestoreFromStream(AStream: TStream);
    procedure SaveToStream(ALayer : TicLayer; AStream: TStream);
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure ChangedLayer(ALayer : TicLayer);  virtual;
    procedure ChangingLayer(ALayer : TicLayer); virtual;
    procedure Play; override;
    procedure Revert; override;
    //class function Signature : string; override; //not localized string
  published
    property Layer : TicLayer read FLayer write FLayer;
  end;

  TicCmdLayer_New = class(TicCmdLayer_Modify)
  public
    procedure Play; override;
    procedure Revert; override;
  end;

  TicCmdLayer_Delete = class(TicCmdLayer_Modify)
  public
    procedure ChangingLayer(ALayer : TicLayer); override;
    procedure Play; override;
    procedure Revert; override;
  end;

{GLOBAL SCOPE VAR}
  function  GIntegrator : TicIntegrator; //read only

{GLOBAL PROCS}
  //for later reconstruct command from stream
  procedure RegisterIgCommandHandler(ACommandClass : TicCommand);


implementation


{UNIT SCOPE}
var
  UIntegrator : TicIntegrator = nil;
  UCommandHandlers : TStrings = nil;    //List of signatures and related class for reconstruction



function  GIntegrator : TicIntegrator;
// To avoid this instance being owned by Delphi IDE (that cause error when upgrade),
// I made it only created when is needed by wrap it with this routine.
// To keep it singleton instance, I made it read only by declare variable under
// implementation.
begin
  if UIntegrator = nil then
    UIntegrator := TicIntegrator.Create(Application);
  Result := UIntegrator;
end;




procedure RegisterIgCommandHandler(ACommandClass : TicCommand);
var
  LSignature : string;
  LIndex : Integer;
begin
  if not assigned(UCommandHandlers) then
    UCommandHandlers := TStringList.Create;

  LSignature := ACommandClass.Signature;
  LIndex := UCommandHandlers.IndexOf(LSignature);
  if LIndex < 0 then
    LIndex := UCommandHandlers.Add(LSignature);
  UCommandHandlers.Objects[LIndex] := TObject(ACommandClass);

end;

{ TicAgent }

procedure TicAgent.AfterConstruction;
begin
  inherited;
  if not (csDesigning in ComponentState) then
    GIntegrator.RegisterListener(self);
end;

constructor TicAgent.Create(AOwner: TComponent);
begin
  inherited;
end;

{ TicIntegrator }

function TicIntegrator.ActivateTool(AToolClass: TicToolClass): Boolean;
var
  LTool : TicTool;
begin
  Result := Self.ReadyToSwitchTool; //ask wether current active tool is not working in progress.

  if Result then
  begin
    LTool := GIntegrator.LoadTool(AToolClass);
    Assert(Assigned(LTool)); //error should be a programatic wrong logic.

    if Assigned(ActivePaintBox) then
      ActivePaintBox.Cursor := LTool.Cursor;

    Result := Self.IsToolSwitched(LTool); //ask the new tool to be active
  end;
end;


procedure TicIntegrator.ActivePaintBoxSwitched;
var i : Integer;
begin
  for i := 0 to FListeners.Count -1 do
  begin
    with TicAgent( FListeners[i] ) do
      if Assigned(FOnActivePaintBoxSwitched) then
        FOnActivePaintBoxSwitched(Self);
  end;

end;


constructor TicIntegrator.Create(AOwner: TComponent);
var
  i : Integer;
const
  dont_manual = 'Dont create manually, it will be created automatically';
begin
  Assert(AOwner is TApplication, dont_manual);
  for i := 0 to Application.ComponentCount-1 do
  begin
    if Application.Components[i] is TicIntegrator then
    raise Exception.Create(dont_manual);
  end;

  inherited;
  FInstancesList := TList.Create;
  FListeners := TList.Create;

end;

procedure TicIntegrator.DoMouseDown(Sender: TicPaintBox;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TicLayer);
begin
  if Assigned(FActiveTool) then
    FActiveTool.DoMouseDown(Sender, Button, Shift, X,Y, Layer);
end;


procedure TicIntegrator.DoMouseMove(Sender: TicPaintBox;
  Shift: TShiftState; X, Y: Integer; Layer: TicLayer);
begin
  if Assigned(FActiveTool) then
    FActiveTool.DoMouseMove(Sender, Shift, X,Y, Layer);
end;

procedure TicIntegrator.DoMouseUp(Sender: TicPaintBox;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TicLayer);
begin
  if Assigned(FActiveTool) then
    FActiveTool.DoMouseUp(Sender, Button, Shift, X,Y, Layer);
end;

function TicIntegrator.IsToolSwitched(ATool: TicTool): Boolean;
begin
  Result := True;
  FActiveTool := ATool;

  //todo: ask the new tool wether all requirement is available
  {begin
    ///dont use FLastTool := atool  <--- we need integrated properly
    //SetLastTool(ATool); //Explicit Update Integrator's Events
    // a line above may also be replaced by using property: LastTool := ATool;
  end;}

  {make sure the active tool is under maintained}
  MaintainTool(ATool);
end;


// Find a tool instance, create one if not found
function TicIntegrator.LoadTool(AToolClass: TicToolClass): TicTool;
var i : Integer;
  //LTool : TgmTool;
begin
  Result := nil;
  for i := 0 to FInstancesList.Count -1 do
  begin
    if TicTool(FInstancesList[i]) is AToolClass then
    begin
      Result := TicTool(FInstancesList[i]);
      //We found the expected tool class.
      Exit;
    end;
  end;

  if not Assigned(Result) then
  begin
    Result := AToolClass.Create(Application); //it must by owned by something.
    MaintainTool(Result);
  end;

end;

procedure TicIntegrator.MaintainTool(ATool: TicTool);
// we want to make sure that any tool being destroyed is also deleted in our list.
begin
  if FInstancesList.IndexOf(ATool) < 0 then
  begin
    FInstancesList.Add(ATool);    //register to our maintained tool.
    ATool.FreeNotification(Self); //tell the tool to report when she were destroying
  end;
end;


procedure TicIntegrator.Notification(AComponent: TComponent;
  Operation: TOperation);
var
  LTool : TicTool; 
begin
  inherited;
  if Operation = opRemove then
  begin
    if (AComponent = ActivePaintBox) then
    begin
      ActivePaintBox := nil; //broadcast to agents
    end

    else if (AComponent is TicTool) then
    begin
      LTool := AComponent as TicTool;
      if LTool = ActiveTool then
        FActiveTool := nil;
      if FInstancesList.IndexOf(LTool) > 0 then
        FInstancesList.Delete(FInstancesList.IndexOf(LTool));
    end

  end;

end;


function TicIntegrator.ReadyToSwitchTool: Boolean;
begin
  Result := True;
  if (FActiveTool <> nil) then
    Result := FActiveTool.CanBeSwitched;
end;


procedure TicIntegrator.RegisterListener(AAgent: TicAgent);
begin
  if FListeners.IndexOf(AAgent) < 0 then
  begin
    FListeners.Add(AAgent);
    AAgent.FreeNotification(Self); //tell the agent to report when she were destroying
  end;
end;

procedure TicIntegrator.SetActivePaintBox(const Value: TicPaintBox);
begin
  if FActivePaintBox <> Value then
  begin
    FActivePaintBox := Value;

    ActivePaintBoxSwitched;
    if Assigned(Value) then
    begin
      SetActiveUndoRedo(FActivePaintBox.FUndoRedo);
      Value.FreeNotification(Self); //tell paintobx to report when she were destroying
      if Assigned(ActiveTool) then
        Value.Cursor := ActiveTool.Cursor;
    end
    else
      SetActiveUndoRedo(nil);

    SelectionChanged;

  end;
end;


{ TicTool }

//sometime a tool can't be switched automatically.
//such while working in progress or need to be approved or discharged.
function TicTool.CanBeSwitched: Boolean;
begin
  Result := True;
end;

procedure TicTool.DblClick(Sender: TObject);
begin
  if Assigned(FOnBeforeDblClick) then
    FOnBeforeDblClick(Sender);

  DblClick(Sender);

  if Assigned(FOnAfterDblClick) then
    FOnAfterDblClick(Sender);
end;

procedure TicTool.DoChanging(const Info: string);
begin
  if Assigned(FOnChanging) then
    FOnChanging(Self, Info);
end;

procedure TicTool.DoDblClick(Sender: TObject);
begin
  if Assigned(FOnBeforeDblClick) then
    FOnBeforeDblClick(Sender);

  DblClick(Sender);

  if Assigned(FOnAfterDblClick) then
    FOnAfterDblClick(Sender);
end;

procedure TicTool.DoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  KeyDown(Sender, Key, Shift);
end;

procedure TicTool.DoKeyPress(Sender: TObject; var Key: Char);
begin
  KeyPress(Sender, Key);
end;

procedure TicTool.DoKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  KeyUp(Sender, Key, Shift);
end;

procedure TicTool.DoMouseDown(Sender: TicPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TicLayer);
begin
  if Assigned(FOnBeforeMouseDown) then
    FOnBeforeMouseDown(Sender, Button, Shift, X, Y, Layer);

  MouseDown(Sender, Button, Shift, X, Y, Layer);

  if Assigned(FOnAfterMouseDown) then
    FOnAfterMouseDown(Sender, Button, Shift, X, Y, Layer);
end;

procedure TicTool.DoMouseMove(Sender: TicPaintBox; Shift: TShiftState; X,
  Y: Integer; Layer: TicLayer);
begin
  if Assigned(FOnBeforeMouseMove) then
    FOnBeforeMouseMove(Sender, Shift, X, Y, Layer);

  MouseMove(Sender, Shift, X, Y, Layer);

  if Assigned(FOnAfterMouseMove) then
    FOnAfterMouseMove(Sender, Shift, X, Y, Layer);
end;

procedure TicTool.DoMouseUp(Sender: TicPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TicLayer);
begin
  if Assigned(FOnBeforeMouseUp) then
    FOnBeforeMouseUp(Sender, Button, Shift, X, Y, Layer);

  MouseUp(Sender, Button, Shift, X, Y, Layer);

  if Assigned(FOnAfterMouseUp) then
    FOnAfterMouseUp(Sender, Button, Shift, X, Y, Layer);
end;

procedure TicTool.FinalEdit;
begin
  if Assigned(FOnFinalEdit) then
    FOnFinalEdit(Self);
end;

procedure TicTool.KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //descendant may do something
end;

procedure TicTool.KeyPress(Sender: TObject; var Key: Char);
begin
  //descendant may do something
end;

procedure TicTool.KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //descendant may do something
end;

procedure TicTool.MouseDown(Sender: TicPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TicLayer);
begin
  //descendant may do something
end;

procedure TicTool.MouseMove(Sender: TicPaintBox; Shift: TShiftState; X,
  Y: Integer; Layer: TicLayer);
begin
  //descendant may do something
end;

procedure TicTool.MouseUp(Sender: TicPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TicLayer);
begin
  //descendant may do something
end;

function TicIntegrator.ActivateTool(AToolInstance: TicTool): Boolean;
begin
  Assert(Assigned(AToolInstance),'Cannot activate a nil drawing tool'); //error should be a programatic wrong logic.
  
  Result := Self.ReadyToSwitchTool; //ask wether current active tool is not working in progress.
  if Result then
  begin
    Result := Self.IsToolSwitched(AToolInstance); //ask the new tool to be active
  end;

end;






procedure TicIntegrator.InvalidateListeners;
var i : Integer;
begin
  for i := 0 to FListeners.Count -1 do
  begin
    with TicAgent( FListeners[i] ) do
    begin
        if Assigned(FOnInvalidateListener) then
        OnInvalidateListener(Self);
    end;
  end;
end;

procedure TicIntegrator.SetActiveUndoRedo(const Value: TicUndoRedoManager);
begin
  FActiveUndoRedo := Value;
end;

procedure TicIntegrator.SelectionChanged;
var i : Integer;
begin
  for i := 0 to FListeners.Count -1 do
  begin
    with TicAgent( FListeners[i] ) do
    begin
        if Assigned(FOnSelectionChange) then
        FOnSelectionChange(Self);
    end;
  end;
end;

{ TicPaintBox }

procedure TicPaintBox.AfterLayerCombined(ASender: TObject;
  const ARect: TRect);
begin
{///  Bitmap.FillRectS(ARect, $00FFFFFF);  // must be transparent white
  Bitmap.Draw(ARect, ARect, FLayerList.CombineResult);
  Bitmap.Changed(ARect);}
end;

constructor TicPaintBox.Create(AOwner: TComponent);
var
  LLayerPanel : TicNormalLayerPanel;
begin
  inherited;
  Options := [pboAutoFocus];
  TabStop := True;
  //FAgent := TicAgent.Create(self); //autodestroy. //maybe better to use integrator directly.
  //FLayerList := TLayerCollection.Create(Self); //TPersistent is not autodestroy
  ///FLayerList.OnLayerCombined := AfterLayerCombined;

  FUndoRedo:= TicUndoRedoManager.Create(Self);
  FUndoRedo.LayerList := Layers;
  if not (csDesigning in self.ComponentState) then
  begin
    // set background size before create background layer
    Bitmap.SetSize(300,300);
    Bitmap.Clear($00000000);

    {
    // create background layer
    LLayerPanel :=  TicNormalLayerPanel.Create(FLayerList);
    LLayerPanel.IsAsBackground := True;
    LLayerPanel.LayerBitmap.SetSize(  Bitmap.Width, Bitmap.Height);
    LLayerPanel.LayerBitmap.Clear(clWhite32);
    //LLayerPanel.UpdateLayerThumbnail;
    //TigNormalLayerPanel(LLayerPanel).IsAsBackground := True;

    FLayerList.Add(LLayerPanel);
    }
  end;  
end;

destructor TicPaintBox.Destroy;
begin
  inherited;
end;

function TicPaintBox.GetLayerList: TLayerCollection;
begin
  Result := Layers;
end;

procedure TicPaintBox.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  GIntegrator.DoMouseDown(Self, Button, Shift, X, Y, self.FSelectedLayer {FLayerList.SelectedPanel});///
end;

procedure TicPaintBox.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  GIntegrator.DoMouseMove(Self, Shift, X, Y, self.FSelectedLayer {FLayerList.SelectedPanel});///
end;

procedure TicPaintBox.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  GIntegrator.DoMouseUp(Self, Button, Shift, X, Y, self.FSelectedLayer {FLayerList.SelectedPanel});///
end;

procedure TicPaintBox.SetFocus;
begin
  inherited;
  GIntegrator.ActivePaintBox := Self;
end;



procedure TicPaintBox.SetSelectedLayer(const Value: TicLayer);
var
  i : Integer;
begin
  for i := 0 to Layers.Count-1 do
  begin
    if Layers[i] is TicLayer then
    with TicLayer(Layers[i]) do
    begin
      IsSelected := False;
    end;
  end;

  FSelectedLayer := Value;
  Value.IsSelected := True;
  GIntegrator.SelectionChanged;
  //todo : multiple selection
  GIntegrator.InvalidateListeners; // such layer listbox doesn't invalidate her self
end;

{ TicUndoRedoManager }

procedure TicUndoRedoManager.AddUndo(AUndo: TicCommand; AComment: string);
var i : Integer;
  cmd : TicCommand;
begin
  //delete redo if any
  if IsRedoAllowed then
  begin
    for i := Count -1 downto FItemIndex +1  do
    begin
      cmd := TicCommand( FUndoList.Objects[i]);
      cmd.Free;
      FUndoList.Delete(i);
    end;
  end;
  i :=FUndoList.AddObject(AComment, AUndo);
  AUndo.Manager := Self;
  FItemIndex := i;
end;

constructor TicUndoRedoManager.Create(AOwner: TComponent);
begin
  inherited;
  FUndoList := TStringList.Create;
  FItemIndex := -1;
end;

destructor TicUndoRedoManager.Destroy;
begin
  FUndoList.Free;
  inherited;
end;

function TicUndoRedoManager.GetCount: Integer;
begin
  Result := FUndoList.Count;
end;

function TicUndoRedoManager.IsRedoAllowed: Boolean;
begin
  Result := ItemIndex < Count -1;
end;

function TicUndoRedoManager.IsUndoAllowed: Boolean;
begin
  Result := (ItemIndex > -1)
end;

function TicUndoRedoManager.LastCommand: TicCommand;
begin
  result := nil;
  if count > 0 then
  result :=   TicCommand(FUndoList.Objects[Count-1]);
end;

procedure TicUndoRedoManager.Redo;
var LIgCommand : TicCommand;
begin
  if not IsRedoAllowed then Exit;

  Inc(FItemIndex);

  LIgCommand := TicCommand(FUndoList.Objects[FItemIndex]);
  LIgCommand.Play;
  GIntegrator.InvalidateListeners;
end;


procedure TicUndoRedoManager.RedoTo(ATargetIndex: Integer);
var i : Integer;
  LIgCommand : TicCommand;
  LDone : Boolean; //something done
begin
  LDone := False;
  for i := FItemIndex+1 to ATargetIndex do
  begin
    if not IsRedoAllowed then Break;

    Inc(FItemIndex);

    LIgCommand := TicCommand(FUndoList.Objects[FItemIndex]);
    LIgCommand.Play;
    LDone := True;
  end;

  if LDone then
    GIntegrator.InvalidateListeners;

end;


procedure TicUndoRedoManager.Undo;
var LIgCommand : TicCommand;
begin
  if not IsUndoAllowed then Exit;

  LIgCommand := TicCommand(FUndoList.Objects[FItemIndex]);
  LIgCommand.Revert;

  Dec(FItemIndex);
  if FItemIndex < -1 then
    FItemIndex := -1;
  GIntegrator.InvalidateListeners;
end;

procedure TicUndoRedoManager.UndoTo(ATargetIndex: Integer);
var i : Integer;
  LIgCommand : TicCommand;
  LDone : Boolean; //something done
begin
  LDone := False;
  for i := FItemIndex downto ATargetIndex do
  begin
    if not IsUndoAllowed then Break;

    LIgCommand := TicCommand(FUndoList.Objects[FItemIndex]);
    LIgCommand.Revert;
    LDone := True;

    Dec(FItemIndex);
    if FItemIndex < -1 then
      FItemIndex := -1;
  end;

  if LDone then
    GIntegrator.InvalidateListeners;

end;

{ TicCommand }

constructor TicCommand.Create(AOwner: TComponent);
begin
  inherited;
  if AOwner is TicUndoRedoManager then
    FManager := TicUndoRedoManager (AOwner);
end;

function TicCommand.LayerList: TLayerCollection;
begin
  Result := nil;
  if Assigned(self.FManager) then
    Result := FManager.LayerList;
end;

procedure TicCommand.RestorePreviousState;
var LIgCommand : TicCommand;
begin
  try
    LIgCommand := TicCommand(Manager.FUndoList.Objects[Manager.FItemIndex-1]);
    LIgCommand.Play;
  except
    raise Exception.Create('Don''t use this as first action');
  end;
end;

procedure TicCommand.Revert;
begin
  RestorePreviousState;
end;

class function TicCommand.Signature: string;
begin
  result := Self.ClassName;
end;

{ TicCmdModifyLayer }

  procedure DebugSave(AStreamLayer:TStream);
  var 
    f : TFileStream;
  begin
    AStreamLayer.Seek(0, soFromBeginning);
    f := TFileStream.Create( ChangeFileExt(Application.ExeName,'.txt'),fmCreate);
    ObjectBinaryToText(AStreamLayer, f);
    f.Free;
  end;

procedure TicCmdLayer_Modify.ChangingLayer(ALayer: TicLayer);
begin
  if assigned(Manager) and ((Manager.LastCommand = nil) or
    (Manager.LastCommand is TicCmdLayer) and (TicCmdLayer(Manager.LastCommand).LayerIndex <> ALayer.Index)
    ) then
  begin
    SaveToStream(ALayer, FOriginalStream);
  end;
end;

procedure TicCmdLayer_Modify.ChangedLayer(ALayer: TicLayer);
begin
  SaveToStream(ALayer, FModifiedStream);
end;

constructor TicCmdLayer_Modify.Create(AOwner: TComponent);
begin
  inherited;
  FOriginalStream := TMemoryStream.Create;
  FModifiedStream := TMemoryStream.Create;
end;

destructor TicCmdLayer_Modify.Destroy;
begin
  FOriginalStream.Free;
  FModifiedStream.Free;
  inherited;
end;

procedure TicCmdLayer_Modify.Play;
//var LLayer : TicLayer;
begin
  RestoreFromStream( FModifiedStream );
end;

procedure TicCmdLayer_Modify.RestoreFromStream(AStream: TStream);
begin
  if AStream.Size > 0 then
  begin
    //DebugSave(FModifiedStream);

    //refresh reference to current layer object, maybe has been recreated by other command
    ///FLayer := LayerList.LayerPanels[Self.LayerIndex];

    AStream.Position := 0;
    AStream.ReadComponent(self); //restore
    FLayer.Changed; //update thumbnail
    
    // I dont know, but it required to refresh the paintobx
    //Self.Manager.LayerList.Insert(self.LayerIndex, FLayer);

  end;
end;

procedure TicCmdLayer_Modify.Revert;
begin
  if FOriginalStream.Size > 0 then
  begin
    RestoreFromStream( FOriginalStream );
  end
  else
    RestorePreviousState;

end;

procedure TicCmdLayer_Modify.SaveToStream(ALayer: TicLayer;
  AStream: TStream);
begin
  FLayerClass := TicLayerPanelClass(ALayer.ClassType);//TigLayerPanelClass(FindClass(ALayer.ClassName));//
  FLayer := ALayer;
  FLayerIndex := ALayer.Index;
  AStream.WriteComponent(self);
end;

{ TicCmdLayer_New }

procedure TicCmdLayer_New.Play;
begin
  if FLayer = nil then
  begin
    //FLayer := TicNormalLayerPanel.Create( Self.PanelList, 300,300); //its work
    FLayer := FLayerClass.Create(self.LayerList);
    FLayer.IsDuplicated := true; //dont increment the layer name
    ///self.LayerList.Insert(self.LayerIndex, FLayer);
  end;
  //inherited;
  RestoreFromStream( FModifiedStream );
end;

procedure TicCmdLayer_New.Revert;
begin
  ///LayerList.DeleteLayerPanel(self.FLayerIndex);
  FLayer := nil;
end;



{ TicCmdLayer_Delete }

procedure TicCmdLayer_Delete.ChangingLayer(ALayer: TicLayer);
begin
  SaveToStream(ALayer, FOriginalStream);
end;

procedure TicCmdLayer_Delete.Play; //redo
begin
  ///LayerList.DeleteLayerPanel(self.FLayerIndex);
  FLayer := nil;
end;

procedure TicCmdLayer_Delete.Revert; //undo
begin
  if FLayer = nil then
  begin
    //FLayer := TicNormalLayerPanel.Create( Self.PanelList, 300,300); //its work
    FLayer := FLayerClass.Create(self.LayerList);
    FLayer.IsDuplicated := true; //dont increment the layer name    
    ///self.LayerList.Insert(self.LayerIndex, FLayer);
  end;
  RestoreFromStream(FOriginalStream);
end;

initialization
  //UIntegrator := TicIntegrator.Create(Application);
finalization
  //if UIntegrator <> nil then
    //FreeAndNil(UIntegrator); //explicite remove for package recompile
end.

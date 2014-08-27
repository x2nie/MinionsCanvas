unit igBase;

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
  igLayers;

type

  { far definitions }
  TigPaintBox = class;                  // drawing canvas
  TigTool = class;                      // drawing tool
  TigToolClass = class of TigTool;
  TigIntegrator = class;
  TigAgent = class;                     // bridge for link-unlink, avoid error
  TigTheme = class;
  TigUndoRedoManager = class;
  TigCommand = class;

  TigDebugLog = procedure(Sender : TObject; const Msg : string; ident: Integer = 0) of object;

  TigChangingEvent = procedure(Sender: TObject; const Info : string) of object;
  TigMouseEvent = procedure(Sender: TigPaintBox; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel) of object;
  TigMouseMoveEvent = procedure(Sender: TigPaintBox; Shift: TShiftState;
    X, Y: Integer; Layer: TigCustomLayerPanel) of object;


  TigIntegrator = class(TComponent)     // Event Organizer. hidden component
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
    FActiveTool: TigTool;
    FActivePaintBox: TigPaintBox;
    function IsToolSwitched(ATool: TigTool):Boolean;
    function LoadTool(AToolClass: TigToolClass): TigTool;
    procedure MaintainTool(ATool : TigTool);
    function ReadyToSwitchTool : Boolean;
    procedure SetActivePaintBox(const Value: TigPaintBox);
  protected
    procedure ActivePaintBoxSwitched;
    procedure DoMouseDown(Sender: TigPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel);
    procedure DoMouseMove(Sender: TigPaintBox; Shift: TShiftState; X,
      Y: Integer; Layer: TigCustomLayerPanel);
    procedure DoMouseUp(Sender: TigPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel);
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure RegisterListener(AAgent: TigAgent);

  public
    constructor Create(AOwner: TComponent); override;
    function ActivateTool(AToolClass: TigToolClass):Boolean; overload;
    function ActivateTool(AToolInstance: TigTool):Boolean; overload;
    procedure InvalidateListeners;

    property ActivePaintBox : TigPaintBox read FActivePaintBox
      write SetActivePaintBox;
    property ActiveTool : TigTool read FActiveTool;
  end;

  TigAgent = class(TComponent)
  { the event listener of drawing-canvas
    or redirection for such arranging layers
  }
  private
    FOnActivePaintBoxSwitched: TNotifyEvent;
    FOnInvalidateListener: TNotifyEvent;
  protected
    //procedure DoActivePaintBoxSwitched;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property OnActivePaintBoxSwitch: TNotifyEvent read FOnActivePaintBoxSwitched write FOnActivePaintBoxSwitched;
    property OnInvalidateListener: TNotifyEvent read FOnInvalidateListener write FOnInvalidateListener;
  end;


  TigPaintBox = class(TCustomImage32)
  { the drawing-canvas object
  }
  private
    FLayerList: TigLayerPanelList;
    FUndoRedo: TigUndoRedoManager;
    procedure AfterLayerCombined(ASender: TObject; const ARect: TRect);

  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure SetFocus; override;

    property LayerList : TigLayerPanelList read FLayerList;
    property UndoRedo : TigUndoRedoManager read FUndoRedo; 
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
  end;

  TigTool = class(TComponent)
  private
    FCursor: TCursor;
    //FImage32: TCustomImage32;
    FOnAfterDblClick: TNotifyEvent;
    FOnBeforeDblClick: TNotifyEvent;
    FOnFinalEdit: TNotifyEvent;
    FOnChanging: TigChangingEvent;
    //function GetToolInstance(index: TgmToolClass): TgmTool;
  protected
    FModified: Boolean; //wether this tool has success or canceled to made a modification of target.
    FOnAfterMouseDown: TigMouseEvent;
    FOnBeforeMouseUp: TigMouseEvent;
    FOnAfterMouseUp: TigMouseEvent;
    FOnBeforeMouseDown: TigMouseEvent;
    FOnBeforeMouseMove: TigMouseMoveEvent;
    FOnAfterMouseMove: TigMouseMoveEvent;

    //Events. Descendant may inherited. Polymorpism.
    function CanBeSwitched: Boolean; virtual;
    procedure MouseDown(Sender: TigPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel); virtual;
    procedure MouseMove(Sender: TigPaintBox; Shift: TShiftState; X,
      Y: Integer; Layer: TigCustomLayerPanel); virtual;
    procedure MouseUp(Sender: TigPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel); virtual;
    procedure KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); virtual;
    procedure KeyPress(Sender: TObject; var Key: Char); virtual;
    procedure KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState); virtual;
    procedure DblClick(Sender: TObject); virtual;
    procedure FinalEdit;virtual;


    //Events used internally. Descendant may NOT inherits. call by integrator
    procedure DoMouseDown(Sender: TigPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel); //virtual;
    procedure DoMouseMove(Sender: TigPaintBox; Shift: TShiftState; X,
      Y: Integer; Layer: TigCustomLayerPanel); //virtual;
    procedure DoMouseUp(Sender: TigPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel); //virtual;
    procedure DoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); //virtual;
    procedure DoKeyPress(Sender: TObject; var Key: Char); //virtual;
    procedure DoKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState); //virtual;
    procedure DoDblClick(Sender: TObject);
    procedure DoChanging(const Info : string);
  published
    property Cursor : TCursor read FCursor write FCursor; //default cursor when activated.
    property OnBeforeMouseDown : TigMouseEvent read FOnBeforeMouseDown write FOnBeforeMouseDown; 
    property OnAfterMouseDown : TigMouseEvent read FOnAfterMouseDown write FOnAfterMouseDown;
    property OnBeforeMouseUp : TigMouseEvent read FOnBeforeMouseUp write FOnBeforeMouseUp;
    property OnAfterMouseUp : TigMouseEvent read FOnAfterMouseUp write FOnAfterMouseUp;
    property OnBeforeMouseMove : TigMouseMoveEvent read FOnBeforeMouseMove write FOnBeforeMouseMove;
    property OnAfterMouseMove : TigMouseMoveEvent read FOnAfterMouseMove write FOnAfterMouseMove;
    property OnBeforeDblClick : TNotifyEvent read FOnBeforeDblClick write FOnBeforeDblClick;
    property OnAfterDblClick : TNotifyEvent read FOnAfterDblClick write FOnAfterDblClick;
    property OnChanging  : TigChangingEvent read FOnChanging write FOnChanging; //prepare undo signal
    property OnFinalEdit : TNotifyEvent read FOnFinalEdit write FOnFinalEdit; 
  end;

  TigTheme = class(TComponent)
  end;

    { it should attached to TigPaintBox
  }
  TigUndoRedoManager = class(TComponent)
  private
    FItemIndex: Integer;
    FPanelList: TigLayerPanelList;
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
    procedure AddUndo(AUndo : TigCommand; AComment : string);
    function  LastCommand : TigCommand;
    //function AllocateUndo(AUndoMessage : string) : PigUndoStruct;

    property Strings :TStrings read FUndoList;
    property Count : Integer read GetCount;
    property PanelList : TigLayerPanelList read FPanelList write FPanelList;
    property ItemIndex : Integer read FItemIndex;
  published

  end;

  TigCommand = class(TComponent)
  private
    FManager: TigUndoRedoManager;
  protected
    {properties}
    function PanelList : TigLayerPanelList;
    property Manager : TigUndoRedoManager read FManager write FManager;
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

  TigCommandClass = class of TigCommand;

  //for checkin checkout / inter-comparing between commands
  TigCmdLayer = class(TigCommand)
  private
    FLayerIndex: Integer;
    FLayerClass: TigLayerPanelClass;
  public
    property  LayerClass : TigLayerPanelClass read FLayerClass write FLayerClass;
  published
    property LayerIndex: Integer read FLayerIndex write FLayerIndex;
  end;

  //modify = edit surface, such by penTool, pencilTool, add/remove node on vectorLayer
  TigCmdLayer_Modify = class(TigCmdLayer)
  private
    FOriginalStream,
    FModifiedStream : TStream;
    FLayer: TigLayerPanel;
    procedure RestoreFromStream(AStream: TStream);
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure ChangedLayer(ALayer : TigLayerPanel);
    procedure ChangingLayer(ALayer : TigLayerPanel);
    procedure Play; override;
    procedure Revert; override;
    //class function Signature : string; override; //not localized string
  published
    property Layer : TigLayerPanel read FLayer write FLayer;
  end;

  TigCmdLayer_New = class(TigCmdLayer_Modify)
  public
    procedure Play; override;
    procedure Revert; override;
  end;

{GLOBAL SCOPE VAR}
  function  GIntegrator : TigIntegrator; //read only

{GLOBAL PROCS}
  //for later reconstruct command from stream
  procedure RegisterIgCommandHandler(ACommandClass : TigCommand);


implementation


{UNIT SCOPE}
var
  UIntegrator : TigIntegrator = nil;
  UCommandHandlers : TStrings = nil;    //List of signatures and related class for reconstruction



function  GIntegrator : TigIntegrator;
// To avoid this instance being owned by Delphi IDE (that cause error when upgrade),
// I made it only created when is needed by wrap it with this routine.
// To keep it singleton instance, I made it read only by declare variable under
// implementation.
begin
  if UIntegrator = nil then
    UIntegrator := TigIntegrator.Create(Application);
  Result := UIntegrator;
end;




procedure RegisterIgCommandHandler(ACommandClass : TigCommand);
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

{ TigAgent }

constructor TigAgent.Create(AOwner: TComponent);
begin
  inherited;
  GIntegrator.RegisterListener(Self);
end;

{procedure TigAgent.DoActivePaintBoxSwitched;
begin
  if Assigned(FOnActivePaintBoxSwitched) then
    FOnActivePaintBoxSwitched(Self);
end;}


{ TigIntegrator }

function TigIntegrator.ActivateTool(AToolClass: TigToolClass): Boolean;
var
  LTool : TigTool;
begin
  Result := Self.ReadyToSwitchTool; //ask wether current active tool is not working in progress.

  if Result then
  begin
    LTool := GIntegrator.LoadTool(AToolClass);
    Assert(Assigned(LTool)); //error should be a programatic wrong logic.

    Result := Self.IsToolSwitched(LTool); //ask the new tool to be active
  end;
end;


procedure TigIntegrator.ActivePaintBoxSwitched;
var i : Integer;
begin
  for i := 0 to FListeners.Count -1 do
  begin
    with TigAgent( FListeners[i] ) do
      if Assigned(FOnActivePaintBoxSwitched) then
        FOnActivePaintBoxSwitched(Self);
  end;

end;


constructor TigIntegrator.Create(AOwner: TComponent);
var
  i : Integer;
const
  dont_manual = 'Dont create manually, it will be created automatically';
begin
  Assert(AOwner is TApplication, dont_manual);
  for i := 0 to Application.ComponentCount-1 do
  begin
    if Application.Components[i] is TigIntegrator then
    raise Exception.Create(dont_manual);
  end;

  inherited;
  FInstancesList := TList.Create;
  FListeners := TList.Create;

end;

procedure TigIntegrator.DoMouseDown(Sender: TigPaintBox;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TigCustomLayerPanel);
begin
  if Assigned(FActiveTool) then
    FActiveTool.DoMouseDown(Sender, Button, Shift, X,Y, Layer);
end;


procedure TigIntegrator.DoMouseMove(Sender: TigPaintBox;
  Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel);
begin
  if Assigned(FActiveTool) then
    FActiveTool.DoMouseMove(Sender, Shift, X,Y, Layer);
end;

procedure TigIntegrator.DoMouseUp(Sender: TigPaintBox;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TigCustomLayerPanel);
begin
  if Assigned(FActiveTool) then
    FActiveTool.DoMouseUp(Sender, Button, Shift, X,Y, Layer);
end;

function TigIntegrator.IsToolSwitched(ATool: TigTool): Boolean;
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
function TigIntegrator.LoadTool(AToolClass: TigToolClass): TigTool;
var i : Integer;
  //LTool : TgmTool;
begin
  Result := nil;
  for i := 0 to FInstancesList.Count -1 do
  begin
    if TigTool(FInstancesList[i]) is AToolClass then
    begin
      Result := TigTool(FInstancesList[i]);
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

procedure TigIntegrator.MaintainTool(ATool: TigTool);
// we want to make sure that any tool being destroyed is also deleted in our list.
begin
  if FInstancesList.IndexOf(ATool) < 0 then
  begin
    FInstancesList.Add(ATool);    //register to our maintained tool.
    ATool.FreeNotification(Self); //tell the tool to report when she were destroying
  end;
end;


procedure TigIntegrator.Notification(AComponent: TComponent;
  Operation: TOperation);
var
  LTool : TigTool;
  i : Integer;
begin
  inherited;
  if Operation = opRemove then
  begin
    if (AComponent = ActivePaintBox) then
    begin
      ActivePaintBox := nil; //broadcast to agents
    end

    else if (AComponent is TigTool) then
    begin
      LTool := AComponent as TigTool;
      if LTool = ActiveTool then
        FActiveTool := nil;
      if FInstancesList.IndexOf(LTool) > 0 then
        FInstancesList.Delete(FInstancesList.IndexOf(LTool));
    end

  end;

end;


function TigIntegrator.ReadyToSwitchTool: Boolean;
begin
  Result := True;
  if (FActiveTool <> nil) then
    Result := FActiveTool.CanBeSwitched;
end;


procedure TigIntegrator.RegisterListener(AAgent: TigAgent);
begin
  if FListeners.IndexOf(AAgent) < 0 then
  begin
    FListeners.Add(AAgent);
    AAgent.FreeNotification(Self); //tell the agent to report when she were destroying
  end;
end;

procedure TigIntegrator.SetActivePaintBox(const Value: TigPaintBox);
begin
  if FActivePaintBox <> Value then
  begin
    FActivePaintBox := Value;
    ActivePaintBoxSwitched;
    if Assigned(Value) then
      Value.FreeNotification(Self); //tell paintobx to report when she were destroying
  end;
end;


{ TigTool }

//sometime a tool can't be switched automatically.
//such while working in progress or need to be approved or discharged.
function TigTool.CanBeSwitched: Boolean;
begin
  Result := True;
end;

procedure TigTool.DblClick(Sender: TObject);
begin
  if Assigned(FOnBeforeDblClick) then
    FOnBeforeDblClick(Sender);

  DblClick(Sender);

  if Assigned(FOnAfterDblClick) then
    FOnAfterDblClick(Sender);
end;

procedure TigTool.DoChanging(const Info: string);
begin
  if Assigned(FOnChanging) then
    FOnChanging(Self, Info);
end;

procedure TigTool.DoDblClick(Sender: TObject);
begin
  if Assigned(FOnBeforeDblClick) then
    FOnBeforeDblClick(Sender);

  DblClick(Sender);

  if Assigned(FOnAfterDblClick) then
    FOnAfterDblClick(Sender);
end;

procedure TigTool.DoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  KeyDown(Sender, Key, Shift);
end;

procedure TigTool.DoKeyPress(Sender: TObject; var Key: Char);
begin
  KeyPress(Sender, Key);
end;

procedure TigTool.DoKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  KeyUp(Sender, Key, Shift);
end;

procedure TigTool.DoMouseDown(Sender: TigPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel);
begin
  if Assigned(FOnBeforeMouseDown) then
    FOnBeforeMouseDown(Sender, Button, Shift, X, Y, Layer);

  MouseDown(Sender, Button, Shift, X, Y, Layer);

  if Assigned(FOnAfterMouseDown) then
    FOnAfterMouseDown(Sender, Button, Shift, X, Y, Layer);
end;

procedure TigTool.DoMouseMove(Sender: TigPaintBox; Shift: TShiftState; X,
  Y: Integer; Layer: TigCustomLayerPanel);
begin
  if Assigned(FOnBeforeMouseMove) then
    FOnBeforeMouseMove(Sender, Shift, X, Y, Layer);

  MouseMove(Sender, Shift, X, Y, Layer);

  if Assigned(FOnAfterMouseMove) then
    FOnAfterMouseMove(Sender, Shift, X, Y, Layer);
end;

procedure TigTool.DoMouseUp(Sender: TigPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel);
begin
  if Assigned(FOnBeforeMouseUp) then
    FOnBeforeMouseUp(Sender, Button, Shift, X, Y, Layer);

  MouseUp(Sender, Button, Shift, X, Y, Layer);

  if Assigned(FOnAfterMouseUp) then
    FOnAfterMouseUp(Sender, Button, Shift, X, Y, Layer);
end;

procedure TigTool.FinalEdit;
begin
  if Assigned(FOnFinalEdit) then
    FOnFinalEdit(Self);
end;

procedure TigTool.KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //descendant may do something
end;

procedure TigTool.KeyPress(Sender: TObject; var Key: Char);
begin
  //descendant may do something
end;

procedure TigTool.KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //descendant may do something
end;

procedure TigTool.MouseDown(Sender: TigPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel);
begin
  //descendant may do something
end;

procedure TigTool.MouseMove(Sender: TigPaintBox; Shift: TShiftState; X,
  Y: Integer; Layer: TigCustomLayerPanel);
begin
  //descendant may do something
end;

procedure TigTool.MouseUp(Sender: TigPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TigCustomLayerPanel);
begin
  //descendant may do something
end;

function TigIntegrator.ActivateTool(AToolInstance: TigTool): Boolean;
begin
  Assert(Assigned(AToolInstance),'Cannot activate a nil drawing tool'); //error should be a programatic wrong logic.
  
  Result := Self.ReadyToSwitchTool; //ask wether current active tool is not working in progress.
  if Result then
  begin
    Result := Self.IsToolSwitched(AToolInstance); //ask the new tool to be active
  end;

end;






procedure TigIntegrator.InvalidateListeners;
var i : Integer;
begin
  for i := 0 to FListeners.Count -1 do
  begin
    with TigAgent( FListeners[i] ) do
    begin
        if Assigned(FOnInvalidateListener) then
        OnInvalidateListener(Self);
    end;
  end;
end;

{ TigPaintBox }

procedure TigPaintBox.AfterLayerCombined(ASender: TObject;
  const ARect: TRect);
begin
  Bitmap.FillRectS(ARect, $00FFFFFF);  // must be transparent white
  Bitmap.Draw(ARect, ARect, FLayerList.CombineResult);
  Bitmap.Changed(ARect);
end;

constructor TigPaintBox.Create(AOwner: TComponent);
var
  LLayerPanel : TigCustomLayerPanel;
begin
  inherited;
  Options := [pboAutoFocus];
  TabStop := True;
  //FAgent := TigAgent.Create(self); //autodestroy. //maybe better to use integrator directly.
  FLayerList := TigLayerPanelList.Create(Self); //TPersistent is not autodestroy
  FLayerList.OnLayerCombined := AfterLayerCombined;

  FUndoRedo:= TigUndoRedoManager.Create(Self);
  FUndoRedo.PanelList := FLayerList;
  if not (csDesigning in self.ComponentState) then
  begin
    // set background size before create background layer
    Bitmap.SetSize(300,300);
    Bitmap.Clear($00000000);

    // create background layer
    LLayerPanel :=  TigNormalLayerPanel.Create(FLayerList);
    LLayerPanel.LayerBitmap.SetSize(  Bitmap.Width, Bitmap.Height);
    LLayerPanel.LayerBitmap.Clear(clWhite32);
    LLayerPanel.UpdateLayerThumbnail;
    //TigNormalLayerPanel(LLayerPanel).IsAsBackground := True;

    FLayerList.Add(LLayerPanel);
  end;  
end;

destructor TigPaintBox.Destroy;
begin
  FLayerList.Free;
  inherited;
end;

procedure TigPaintBox.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  GIntegrator.DoMouseDown(Self, Button, Shift, X, Y, FLayerList.SelectedPanel);
end;

procedure TigPaintBox.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  GIntegrator.DoMouseMove(Self, Shift, X, Y, FLayerList.SelectedPanel);
end;

procedure TigPaintBox.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  GIntegrator.DoMouseUp(Self, Button, Shift, X, Y, FLayerList.SelectedPanel);
end;

procedure TigPaintBox.SetFocus;
begin
  inherited;
  GIntegrator.ActivePaintBox := Self;
end;



{ TigUndoRedoManager }

procedure TigUndoRedoManager.AddUndo(AUndo: TigCommand; AComment: string);
var i : Integer;
  cmd : TigCommand;
begin
  //delete redo if any
  if IsRedoAllowed then
  begin
    for i := Count -1 downto FItemIndex +1  do
    begin
      cmd := TigCommand( FUndoList.Objects[i]);
      cmd.Free;
      FUndoList.Delete(i);
    end;
  end;
  i :=FUndoList.AddObject(AComment, AUndo);
  AUndo.Manager := Self;
  FItemIndex := i;
end;

constructor TigUndoRedoManager.Create(AOwner: TComponent);
begin
  inherited;
  FUndoList := TStringList.Create;
  FItemIndex := -1;
end;

destructor TigUndoRedoManager.Destroy;
begin
  FUndoList.Free;
  inherited;
end;

function TigUndoRedoManager.GetCount: Integer;
begin
  Result := FUndoList.Count;
end;

function TigUndoRedoManager.IsRedoAllowed: Boolean;
begin
  Result := ItemIndex < Count -1;
end;

function TigUndoRedoManager.IsUndoAllowed: Boolean;
begin
  Result := (ItemIndex > -1)
end;

function TigUndoRedoManager.LastCommand: TigCommand;
begin
  result := nil;
  if count > 0 then
  result :=   TigCommand(FUndoList.Objects[Count-1]);
end;

procedure TigUndoRedoManager.Redo;
var LIgCommand : TigCommand;
begin
  if not IsRedoAllowed then Exit;

  Inc(FItemIndex);
  
  LIgCommand := TigCommand(FUndoList.Objects[FItemIndex]);
  LIgCommand.Play;
  GIntegrator.InvalidateListeners;
end;

procedure TigUndoRedoManager.Undo;
var LIgCommand : TigCommand;
begin
  if not IsUndoAllowed then Exit;

  LIgCommand := TigCommand(FUndoList.Objects[FItemIndex]);
  LIgCommand.Revert;

  Dec(FItemIndex);
  if FItemIndex < -1 then
    FItemIndex := -1;
  GIntegrator.InvalidateListeners;
end;

{ TigCommand }

constructor TigCommand.Create(AOwner: TComponent);
begin
  inherited;
  if AOwner is TigUndoRedoManager then
    FManager := TigUndoRedoManager (AOwner);
end;

function TigCommand.PanelList: TigLayerPanelList;
begin
  Result := nil;
  if Assigned(self.FManager) then
    Result := FManager.PanelList;
end;

procedure TigCommand.RestorePreviousState;
var LIgCommand : TigCommand;
begin
  try
    LIgCommand := TigCommand(Manager.FUndoList.Objects[Manager.FItemIndex-1]);
    LIgCommand.Play;
  except
    raise Exception.Create('Don''t use this as first action');
  end;
end;

procedure TigCommand.Revert;
begin
  RestorePreviousState;
end;

class function TigCommand.Signature: string;
begin
  result := Self.ClassName;
end;

{ TigCmdModifyLayer }

  procedure DebugSave(AStreamLayer:TStream);
  var 
    f : TFileStream;
  begin
    AStreamLayer.Seek(0, soFromBeginning);
    f := TFileStream.Create( ChangeFileExt(Application.ExeName,'.txt'),fmCreate);
    ObjectBinaryToText(AStreamLayer, f);
    f.Free;
  end;

procedure TigCmdLayer_Modify.ChangingLayer(ALayer: TigLayerPanel);
begin
  if assigned(Manager) and ((Manager.LastCommand = nil) or
    (Manager.LastCommand is TigCmdLayer) and (TigCmdLayer(Manager.LastCommand).LayerIndex <> ALayer.Index)
    ) then
  begin
    FLayerClass := TigLayerPanelClass(ALayer.ClassType);//TigLayerPanelClass(FindClass(ALayer.ClassName));//
    FLayer := ALayer;
    FLayerIndex := ALayer.Index;
    FOriginalStream.WriteComponent(self);
  end;
//  DebugSave();
end;

procedure TigCmdLayer_Modify.ChangedLayer(ALayer: TigLayerPanel);
begin
  FLayerClass := TigLayerPanelClass(ALayer.ClassType);//TigLayerPanelClass(FindClass(ALayer.ClassName));//
  FLayer := ALayer;
  FLayerIndex := ALayer.Index;
  FModifiedStream.WriteComponent(self);
//  DebugSave();
end;

constructor TigCmdLayer_Modify.Create(AOwner: TComponent);
begin
  inherited;
  FOriginalStream := TMemoryStream.Create;
  FModifiedStream := TMemoryStream.Create;
end;

destructor TigCmdLayer_Modify.Destroy;
begin
  FOriginalStream.Free;
  FModifiedStream.Free;
  inherited;
end;

procedure TigCmdLayer_Modify.Play;
//var LLayer : TigLayerPanel;
begin
  RestoreFromStream( FModifiedStream );
end;

{ TigCmdLayer_New }

procedure TigCmdLayer_New.Play;
begin
  if FLayer = nil then
  begin
    //FLayer := TigNormalLayerPanel.Create( Self.PanelList, 300,300); //its work
    FLayer := FLayerClass.Create(self.PanelList);
    self.PanelList.Add(FLayer);
  end;
  inherited;
end;

procedure TigCmdLayer_New.Revert;
begin
  PanelList.DeleteLayerPanel(self.FLayerIndex);
  FLayer := nil;
end;

procedure TigCmdLayer_Modify.RestoreFromStream(AStream: TStream);
begin
  if AStream.Size > 0 then
  begin
    //DebugSave(FModifiedStream);

    //refresh reference to current layer object, maybe has been recreated by other command
    FLayer := PanelList.LayerPanels[Self.LayerIndex];

    AStream.Position := 0;
    AStream.ReadComponent(self); //restore
    FLayer.Changed; //update thumbnail
    
    // I dont know, but it required to refresh the paintobx
    Self.Manager.PanelList.Insert(self.LayerIndex, FLayer);

  end;
end;

procedure TigCmdLayer_Modify.Revert;
begin
  if FOriginalStream.Size > 0 then
  begin
    RestoreFromStream( FOriginalStream );
  end
  else
    RestorePreviousState;

end;

initialization
  //UIntegrator := TigIntegrator.Create(Application);
finalization
  //if UIntegrator <> nil then
    //FreeAndNil(UIntegrator); //explicite remove for package recompile
end.

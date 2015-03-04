unit igLiquidCrystal;

interface

uses
  GR32,
  igLayers;

type
  TigLiquidCrystal = class(TigBitmapLayer)
  private
    FBlocksSize: TPoint;
    FABlockSize: TPoint; //bit size
    FACharPixel : TPoint; //pixel
    FDotSize: TPoint;
    FBitPlane: TBitmap32;
    FGapSize: TPoint;
    FMargin: TPoint;
    FBacklightColor: TColor32;
    FBitOnColor: TColor32;
    FBitOffColor: TColor32;
    FDotPadding: TPoint;
    FAreaChanged: TRect;
    procedure SetBlockSize(const Value: TPoint);
    procedure SetABlockSize(const Value: TPoint);
    procedure SetBitPlane(const Value: TBitmap32);
    procedure SetGapSize(const Value: TPoint);
    procedure SetDotSize(const Value: TPoint);

    procedure BitPlaneAreaChanged(Sender: TObject; const Area: TRect;
      const Info: Cardinal);
    function DotPixelRect(X, Y: Integer): TRect;
    function DotColor(X, Y: Integer): TColor32;


  protected
    procedure RecalculateSize;
    procedure RebuildLCD; //all
    procedure RepaintBackground; //background, frame, accessories PCB, etc.
    procedure PaintBlock(ACol, ARow: Integer);
    procedure PaintDotCoordinate(X,Y: Integer; C:TColor32);
    procedure PaintDotRect(X,Y: Integer; C:TColor32);
    function BlockStartPixelLocation(ACol, ARow: Integer) : TPoint;
  public
    constructor Create(AOwner: TigLayerList); override;
    destructor Destroy; override;
    function BlockCoordinateLocation(X,Y: Integer;
      AllowOutsideRange:Boolean = False) : TRect; // result.topleft = char, result.bottomright = dots
    function DotIndex(CoordinateLocation : TRect) : TPoint; // whole dot together
    procedure LoadFromFile(AFileName : string);

    property AreaChanged : TRect read FAreaChanged; //using LayerBitmap coordinate

  published
    property BitPlane : TBitmap32 read FBitPlane write SetBitPlane;
    property BacklightColor : TColor32 read FBacklightColor write FBacklightColor;
    property BitOnColor : TColor32 read FBitOnColor write FBitOnColor;
    property BitOffColor: TColor32 read FBitOffColor write FBitOffColor;

    { chars. for 1602 (16x2 chars), X=16,Y=2, for bitmap LCD, it should be 1x1}
    //property BlocksX : Integer read FBlocksX write FBlocksX;
    //property BlocksY : Integer read FBlocksY write FBlocksY;
    property BlocksSize : TPoint read FBlocksSize write SetBlockSize;
    
    { Bit per block. for 1602, X=5,Y=8 }
    //property DotsX : Integer read FDotsX write FDotsX;
    //property DotsY : Integer read FDotsY write FDotsY;
    property ABlockSize : TPoint read FABlockSize write SetABlockSize;


    { pixel bitmap coordinat system }
    //property CellW : Integer read FDotW write FDotW;
    //property DotH :
    property DotSize : TPoint read FDotSize write SetDotSize;       //
    property DotPadding : TPoint read FDotPadding write FDotPadding; //between dot
    property GapSize : TPoint read FGapSize write SetGapSize; //between char
    property Margin : TPoint read FMargin write FMargin;  // LCD Padding into first char's pixel
  end;

var
  GInvalidRect : TRect = (Left: -1; Top: -1; Right: -1; Bottom: -1); // signal as impossible LCD range ;


implementation

uses
  Forms, //for debug : application.mainform
  SysUtils;

{ TigLiquidCrystal }


procedure TigLiquidCrystal.BitPlaneAreaChanged(Sender: TObject;
  const Area: TRect; const Info: Cardinal);
var x,y : Integer;
  R : TRect;
begin
  IntersectRect(R, Area, BitPlane.BoundsRect);
  for y := R.Top to R.Bottom-1 do
  for x := R.Left to R.Right-1 do
  begin
    PaintDotCoordinate(X,Y, DotColor(X,Y) );
  end;

  //with R do Application.MainForm.Caption := format('BitPlan Area: X:%d,  Y:%d    cx:%d, cy:%d',[Left, Top, Right, Bottom]);

  //LayerBitmap.Draw(BitPlane.BoundsRect, BitPlane.BoundsRect, BitPlane);

  FAreaChanged.TopLeft := DotPixelRect(R.Left, R.Top).TopLeft;
  FAreaChanged.BottomRight := DotPixelRect(R.Right, R.Bottom).BottomRight;


end;

function TigLiquidCrystal.BlockCoordinateLocation(X, Y: Integer;
  AllowOutsideRange:Boolean = False): TRect;
var
  //P : TPoint;
  i,
  lc,lr, //lcd
  cc,cr,
  dotX,dotY : integer;
  R : TRect;
begin


  //P := img1.ControlToBitmap(Point(X,Y));
  Dec(X, Margin.X);
  Dec(Y, Margin.Y);

  //test is valid coordinate
  if not AllowOutsideRange then
  begin
    R := MakeRect(0,0, FACharPixel.X * FABlockSize.X, FACharPixel.Y * FABlockSize.Y);
    if not PtInRect(R, Point(X,Y)) then
    begin
      Result := GInvalidRect;
      Exit;
    end;
  end;


  //LCD Col/Row
    //lc := P.X div (DOT_PX * (CHAR_COLS+1) );
  Result.Left := X div FACharPixel.X;
  Result.Top  := Y div FACharPixel.Y;

  //Char Col/Row
  //dotX := (P.X - lc*FACharPixel.X) div DOT_PX;
  //dotY := (P.Y - lr*FACharPixel.Y) div DOT_PY;
  Result.Right  := ((X mod FACharPixel.X) {-FGapSize.X}) div DotSize.X ;
  Result.Bottom := ((Y mod FACharPixel.Y) {-FGapSize.Y}) div DotSize.Y;

  if not AllowOutsideRange
  and not (
    (Result.Left in [0..FBlocksSize.X -1])
    and (Result.Top in [0..FBlocksSize.Y -1])
    and (Result.Right in [0..FABlockSize.X -1])
    and (Result.Bottom in [0..FABlockSize.Y -1])
  ) then
  begin
    Result := GInvalidRect;
  end;  


  {if (P.X > 0) and (lc < LCD_COLS) and (dotX < CHAR_COLS )
  and (P.Y > 0) and (lr < LCD_ROWS) and (dotY < CHAR_ROWS ) then
    Caption := Format('X:%d,  Y:%d    cx:%d, cy:%d',[lc,lr, dotX, dotY])
  else
  begin
    Caption := '-';
    Exit;
  end;}
end;

function TigLiquidCrystal.BlockStartPixelLocation(ACol, ARow: Integer): TPoint;
begin
  //Result.X := FMargin.X + (ABlockSize.X * FDotSize.X + FGapSize.X) * ACol;
  //Result.Y := FMargin.Y + (ABlockSize.Y * FDotSize.Y + FGapSize.Y) * ARow;
  Result.X := FMargin.X + FACharPixel.X * ACol;
  Result.Y := FMargin.Y + FACharPixel.Y * ARow;
end;

constructor TigLiquidCrystal.Create(AOwner: TigLayerList);
begin
  inherited;
  FBitPlane := TBitmap32.Create;
  FBitPlane.OnAreaChanged := BitPlaneAreaChanged;
  FBlocksSize := Point(16,2);
  FABlockSize := Point(5,8);
  FDotSize := Point(9,11);
  FDotPadding := Point(1,1);
  FGapSize := Point(5,5);
  FMargin := Point(30,30);
  FBacklightColor := $FF9FEF02;
  FBitOnColor := $FF387800;
  FBitOffColor:= $FF87DA0C;

  //debug test
  //LayerBitmap.SetSize(100,100);
  //RepaintBackground;
  RecalculateSize;
  RebuildLCD;
end;

destructor TigLiquidCrystal.Destroy;
begin
  FBitPlane.Free;
  inherited;
end;

function TigLiquidCrystal.DotColor(X,Y : Integer) : TColor32;
var B : TColor32;
begin
  B := BitPlane.PixelS[x,y];
  if B = 0 then
    Result := BitOffColor
  else
    Result := BitOnColor;
end;

function TigLiquidCrystal.DotIndex(CoordinateLocation: TRect): TPoint;
begin
  with CoordinateLocation do
  begin
    Result.X := Left * FABlockSize.X + Right;
    Result.Y := Top * FABlockSize.Y + Bottom;
  end;
end;

function TigLiquidCrystal.DotPixelRect(X, Y: Integer): TRect ; //whole dot index, not per char
var LRow,LCol, LDotX, LDotY : Integer;
  P : TPoint;
begin
  LCol := X div FABlockSize.X;
  LRow := Y div FABlockSize.Y;

  LDotX:= X mod FABlockSize.X;
  LDotY:= Y mod FABlockSize.Y;
  
  P := BlockStartPixelLocation(LCol, LRow);
  Result.TopLeft := Point(P.X + DotSize.X * LDotX , P.Y + DotSize.Y * LDotY);
  Result.Right := Result.Left + FDotSize.X - FDotPadding.X;
  Result.Bottom := Result.Top + FDotSize.Y - FDotPadding.Y;

end;

procedure TigLiquidCrystal.LoadFromFile(AFileName: string);
var bmp : TBitmap32;
  X,Y : Integer;
  firstCharX, firstCharY : Integer;
  H, W : Integer;
  CharW, CharH : Integer;
  firstC,C : TColor32;
  P : TPoint;
begin
  bmp := TBitmap32.Create;
  bmp.LoadFromFile(AFileName);

  BeginUpdate;

  BacklightColor := bmp.Pixel[0,0];
  C := $1;// clNone;

  //find first point
  for y := 0 to bmp.Height-1 do
  begin
    for x := 0 to bmp.Width div 4 -1 do
    begin
      C := bmp.Pixel[x,y];
      if c <> BacklightColor then
      begin
        firstCharX := X;
        firstCharY := Y;
        Break;
      end;

    end;
    if c <> BacklightColor then
    Break;
  end;
  Margin := Point(firstCharX, firstCharY);


  firstC := C;

  //find cell dimension

  H := 1;
  for y := firstCharY+1 to bmp.Height-1 do
  begin
    C := bmp.Pixel[firstCharX,y];
    if c = BacklightColor then
    begin
      Break;
    end;
    Inc(H);
  end;
  FDotSize.Y := H;

  W :=1;
  for x := firstCharX+1 to bmp.Width-1 do
  begin
    C := bmp.Pixel[x,firstCharY];
    if c = BacklightColor then
    begin
      Break;
    end;
    Inc(W);
  end;
  FDotSize.X := W;

  //find padding
  H := 1;
  for y := firstCharY+1 + FDotSize.Y to bmp.Height-1 do
  begin
    C := bmp.Pixel[firstCharX,y];
    if c <> BacklightColor then
    begin
      Break;
    end;
    Inc(H);
  end;
  FDotPadding.Y := H;
  inc(FDotSize.Y, H);

  W :=1;
  for x := firstCharX+1 + FDotSize.X to bmp.Width-1 do
  begin
    C := bmp.Pixel[x,firstCharY];
    if c <> BacklightColor then
    begin
      Break;
    end;
    Inc(W);
  end;
  FDotPadding.X := W;
  inc(FDotSize.X, W);

  //find ABlockSize
  W := 1;
  while W < bmp.Width do
  begin
    X := FMargin.X + FDotSize.X * W +1;
    if bmp.Pixel[x,firstCharY] = BacklightColor then
      Break;
    Inc(W);
  end;
  FABlockSize.X := W;

  W := 1;
  while W < bmp.Height do
  begin
    Y := FMargin.Y + FDotSize.Y * W +1;
    if bmp.Pixel[firstCharX, Y] = BacklightColor then
      Break;
    Inc(W);
  end;
  FABlockSize.Y := W;

  //find gap
  H := 1;
  for y := firstCharY + FABlockSize.Y * FDotSize.Y  + 1 to bmp.Height-1 do
  begin
    C := bmp.Pixel[firstCharX,y];
    if c <> BacklightColor then
    begin
      Break;
    end;
    Inc(H);
  end;
  FGapSize.Y := H;

  W :=1;
  for x := firstCharX + FABlockSize.X * FDotSize.X +1 to bmp.Width-1 do
  begin
    C := bmp.Pixel[x,firstCharY];
    if c <> BacklightColor then
    begin
      Break;
    end;
    Inc(W);
  end;
  FGapSize.X := W;

  //find LCD cols & rows
  W := 1;
  repeat
    X := FMargin.X + (FABlockSize.X * FDotSize.X + FGapSize.X )* W +1;
    if (X < bmp.Width) and (bmp.Pixel[x,firstCharY] = BacklightColor) then
      Break;
    Inc(W);
  until X >= bmp.Width;
  FBlocksSize.X := W;


  W := 1;
  repeat
    Y := FMargin.Y + (FABlockSize.Y * FDotSize.Y + FGapSize.Y )* W +1;
    if (Y < bmp.Height) and (bmp.Pixel[firstCharX,Y] = BacklightColor) then
      Break;
    Inc(W);
  until Y >= bmp.Height;
  FBlocksSize.Y := W;

  Self.EndUpdate;
  RecalculateSize;
  
  //Parse
  FBitPlane.BeginUpdate;

  FBitOffColor := firstC;
  for H := 0 to FBlocksSize.Y-1 do
  for W := 0 to FBlocksSize.X-1 do
  begin
    P := BlockStartPixelLocation(W,H);
    for Y := 0 to FABlockSize.Y-1 do
    for X := 0 to FABlockSize.X-1 do
    begin
      C := bmp.Pixel[
        P.X + X * FDotSize.X,
        P.Y + Y * FDotSize.Y];
      if C =  FBitOffColor then
        C := 0
      else
      begin
        FBitOnColor := C;
        C := $FF;
      end;
      with DotIndex( MakeRect(W,H,X,Y)) do
        BitPlane[X,Y] := C;
    end;
  end;

  FBitPlane.EndUpdate;
  bmp.Free;

  Self.RebuildLCD;
  //TigLayerList( Self.Collection).Update(nil); //rebuild all
end;

procedure TigLiquidCrystal.PaintBlock(ACol, ARow: Integer);
var P : TPoint;
  x,y : Integer;
  B,C : TColor32;
begin
  P := BlockStartPixelLocation(ACol, ARow);
  for y := 0 to FABlockSize.Y -1 do
  for x := 0 to FABlockSize.X -1 do
  begin
    {B := LayerBitmap.PixelS[x,y];
    if B = 0 then
      C := BitOffColor
    else
      C := BitOnColor;}
    C := DotColor(X,Y);
    PaintDotRect(
      P.X + DotSize.X * X ,
      P.Y + DotSize.Y * Y , C);
  end;
end;

procedure TigLiquidCrystal.PaintDotCoordinate(X, Y: Integer; C: TColor32); //whole dot index, not per char
var LRow,LCol, LDotX, LDotY : Integer;
  P : TPoint;
  R : TRect;
begin
  {LCol := X div FABlockSize.X;
  LRow := Y div FABlockSize.Y;

  LDotX:= X mod FABlockSize.X;
  LDotY:= Y mod FABlockSize.Y;

  P := BlockStartPixelLocation(LCol, LRow);
  PaintDotRect(P.X + DotSize.X * LDotX , P.Y + DotSize.Y * LDotY , C);}

  R := DotPixelRect(X,Y);
  PaintDotRect(R.Left, R.Top, C);

end;

procedure TigLiquidCrystal.PaintDotRect(X, Y: Integer; C:TColor32); //direct pixel
begin
  LayerBitmap.FillRectS(X,Y,
    X+ FDotSize.X - FDotPadding.X ,
    Y+ FDotSize.Y - FDotPadding.Y,
    C);
end;

procedure TigLiquidCrystal.RebuildLCD;
var x,y : Integer;
begin
  RepaintBackground;
  for y := 0 to FBlocksSize.Y -1 do
  for x := 0 to FBlocksSize.X -1 do
  begin
    PaintBlock(X,Y);
  end;

end;

procedure TigLiquidCrystal.RecalculateSize;
begin
  if FUpdateCount > 0 then
    Exit;
  {f FBlocksSize.X * FBlocksSize.Y = 1 then
    FACharSize := FABlockSize
  else
    FACharSize := Point(FABlockSize.X +1, FABlockSize.Y+1);}
  FACharPixel.X := ABlockSize.X * FDotSize.X + FGapSize.X;
  FACharPixel.Y := ABlockSize.Y * FDotSize.Y + FGapSize.Y;

  FBitPlane.SetSize( ABlockSize.X * FBlocksSize.X,
                     ABlockSize.Y * FBlocksSize.Y );

  LayerBitmap.SetSize( FMargin.X + FACharPixel.X * FBlocksSize.X -FGapSize.X +FMargin.X,
                     FMargin.Y + FACharPixel.Y * FBlocksSize.Y -FGapSize.Y +FMargin.Y )
end;

procedure TigLiquidCrystal.RepaintBackground;
begin
  LayerBitmap.Clear(FBacklightColor);
end;


procedure TigLiquidCrystal.SetABlockSize(const Value: TPoint);
begin
  FABlockSize := Value;
end;

procedure TigLiquidCrystal.SetBitPlane(const Value: TBitmap32);
begin
  FBitPlane.Assign(Value);
end;

procedure TigLiquidCrystal.SetBlockSize(const Value: TPoint);
begin
  FBlocksSize := Value;
end;

procedure TigLiquidCrystal.SetDotSize(const Value: TPoint);
begin
  FDotSize := Value;
end;

procedure TigLiquidCrystal.SetGapSize(const Value: TPoint);
begin
  FGapSize := Value;
end;



end.

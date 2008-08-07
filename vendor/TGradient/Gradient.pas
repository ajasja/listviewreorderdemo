{------------------------------------------------------------------------------}
{                                                                              }
{  TGradient v2.61                                                             }
{  by Kambiz R. Khojasteh                                                      }
{                                                                              }
{  kambiz@delphiarea.com                                                       }
{  http://www.delphiarea.com                                                   }
{                                                                              }
{------------------------------------------------------------------------------}

{$I DELPHIAREA.INC}

unit Gradient;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, Forms, Dialogs, Menus;

type

  PRGBQuadArray = ^TRGBQuadArray;
  TRGBQuadArray = array[0..1024] of TRGBQuad;

  TGradientColors = array[0..255] of TRGBQuad;

  TGradientShift = -100..100;
  TGradientRotation = -100..100;

  {$IFNDEF COMPILER4_UP}
  TBorderWidth = 0..MaxInt;
  {$ENDIF}

  TGradientStyle = (gsCustom, gsRadialC, gsRadialT, gsRadialB, gsRadialL,
    gsRadialR, gsRadialTL, gsRadialTR, gsRadialBL, gsRadialBR, gsLinearH,
    gsLinearV, gsReflectedH, gsReflectedV, gsDiagonalLF, gsDiagonalLB,
    gsDiagonalRF, gsDiagonalRB, gsArrowL, gsArrowR, gsArrowU, gsArrowD,
    gsDiamond, gsButterfly, gsRadialRect);

  TCustomGradientEvent = procedure(Sender: TObject; const Colors: TGradientColors;
    Pattern: TBitmap) of object;

  TGradient = class(TGraphicControl)
  private
    fColorBegin: TColor;
    fColorEnd: TColor;
    fUseSysColors: Boolean;
    fStyle: TGradientStyle;
    fShift: TGradientShift;
    fRotation: TGradientRotation;
    fReverse: Boolean;
    fPattern: TBitmap;
    fBorderColor: TColor;
    fBorderWidth: TBorderWidth;
    fOnCustom: TCustomGradientEvent;
    fOnMouseEnter: TNotifyEvent;
    fOnMouseLeave: TNotifyEvent;
    UpdateCount: Integer;
    UpdatePended: Boolean;
    Dirty: Boolean;
    procedure SetColorBegin(Value: TColor);
    procedure SetColorEnd(Value: TColor);
    procedure SetUseSysColors(Value: Boolean);
    procedure SetStyle(Value: TGradientStyle);
    procedure SetShift(Value: TGradientShift);
    procedure SetRotation(Value: TGradientRotation);
    procedure SetReverse(Value: Boolean);
    procedure SetBorderColor(Value: TColor);
    procedure SetBorderWidth(Value: TBorderWidth);
    function IsColorBeginSaved: Boolean;
    function IsColorEndSaved: Boolean;
    procedure WMSettingChange(var Message: TMessage); message WM_SETTINGCHANGE;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
    procedure Loaded; override;
    procedure UpdatePattern; virtual;
    procedure UpdateSysColors; virtual;
    property Pattern: TBitmap read fPattern;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CopyPatternTo(Bitmap: TBitmap): Boolean;
    procedure InvalidatePattern;
    procedure BeginUpdate;
    procedure EndUpdate;
  published
    property Align;
    {$IFDEF COMPILER4_UP}
    property Anchors;
    {$ENDIF}
    property BorderColor: TColor read fBorderColor write SetBorderColor default clActiveBorder;
    property BorderWidth: TBorderWidth read fBorderWidth write SetBorderWidth default 0;
    property ColorBegin: TColor read fColorBegin write SetColorBegin stored IsColorBeginSaved;
    property ColorEnd: TColor read fColorEnd write SetColorEnd stored IsColorEndSaved;
    {$IFDEF COMPILER4_UP}
    property Constraints;
    {$ENDIF}
    property DragCursor;
    {$IFDEF COMPILER4_UP}
    property DragKind;
    {$ENDIF}
    property DragMode;
    property Enabled;
    property Height default 100;
    property ParentShowHint;
    property PopupMenu;
    property Reverse: Boolean read fReverse write SetReverse default False;
    property Rotation: TGradientRotation read fRotation write SetRotation default 0;
    property Shift: TGradientShift read fShift write SetShift default 0;
    property ShowHint;
    property Style: TGradientStyle read fStyle write SetStyle default gsRadialC;
    property UseSysColors: Boolean read fUseSysColors write SetUseSysColors default False;
    property Visible;
    property Width default 100;
    property OnClick;
    property OnCustom: TCustomGradientEvent read fOnCustom write fOnCustom;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    {$IFDEF COMPILER4_UP}
    property OnEndDock;
    {$ENDIF}
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseEnter: TNotifyEvent read fOnMouseEnter write fOnMouseEnter;
    property OnMouseLeave: TNotifyEvent read fOnMouseLeave write fOnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    {$IFDEF COMPILER4_UP}
    property OnStartDock;
    {$ENDIF}
    property OnStartDrag;
  end;

procedure Register;

implementation

procedure RadialRect(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  pRGB: PRGBQuad;
  Row1, Row2: PRGBQuadArray;
begin
  Pattern.Width := 512;
  Pattern.Height := 512;

  for Y := 0 to 255 do
  begin

    // Top & Bottom
    Row1 := PRGBQuadArray(Pattern.ScanLine[Y]);
    Row2 := PRGBQuadArray(Pattern.ScanLine[511-Y]);

    pRGB := @Colors[y];
    for x:=Y to 511-y do
    begin
      Row1[X] := pRGB^;
      Row2[X] := pRGB^;
    end;

    for x:=0 to y do
    begin
      pRGB := @Colors[x];

      Row1[X] := pRGB^;     // Left
      Row2[X] := pRGB^;

      Row1[511-X] := pRGB^; // Right
      Row2[511-X] := pRGB^;
     end
  end;

end;

procedure RadialCentral(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y, rX: Integer;
  pRGB: PRGBQuad;
  Row1, Row2: PRGBQuadArray;
  PreCalcXs: array[0..180] of Integer;
begin
  Pattern.Width := 362;
  Pattern.Height := 362;

  rX := 0;
  for X := 180 downto 0 do
  begin
    PreCalcXs[rX] := X * X;
    Inc(rX);
  end;

  for Y := 180 downto 0 do
  begin
    Row1 := PRGBQuadArray(Pattern.ScanLine[Y]);
    Row2 := PRGBQuadArray(Pattern.ScanLine[361-Y]);
    for X := 180 downto 0 do
    begin
      rX := 361 - X;
      pRGB := @Colors[Round(Sqrt(PreCalcXs[X] + PreCalcXs[Y]))];
      Row1[X] := pRGB^;
      Row1[rX] := pRGB^;
      Row2[X] := pRGB^;
      Row2[rX] := pRGB^;
    end;
  end;

  { Not optimized code
  for Y := 0 to 361 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(Sqr(180 - X) + Sqr(180 - Y)))];
    for X := 181 to 361 do
      Row[X] := Colors[Round(Sqrt(Sqr(X - 181) + Sqr(180 - Y)))];
  end;
  }
end;

procedure RadialTop(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y, rX, rY: Integer;
  pRGB: PRGBQuad;
  Row: PRGBQuadArray;
  PreCalcY: Integer;
  PreCalcXs: array[0..180] of Integer;
begin
  Pattern.Width := 362;
  Pattern.Height := 181;

  rX := 0;
  for X := 180 downto 0 do
  begin
    PreCalcXs[rX] := X * X;
    Inc(rX);
  end;

  rY := 0;
  for Y := 180 downto 0 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    PreCalcY := PreCalcXs[rY];
    rX := 181;
    for X := 180 downto 0 do
    begin
      pRGB := @Colors[Round(Sqrt(PreCalcXs[X] + PreCalcY))];
      Row[X] := pRGB^;
      Row[rX] := pRGB^;
      Inc(rX);
    end;
    Inc(rY);
  end;

  { Not optimized code
  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(Sqr(180 - X) + Sqr(Y)))];
    for X := 181 to 361 do
      Row[X] := Colors[Round(Sqrt(Sqr(X - 181) + Sqr(Y)))];
  end;
  }
end;

procedure RadialBottom(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y, rX: Integer;
  pRGB: PRGBQuad;
  Row: PRGBQuadArray;
  PreCalcY: Integer;
  PreCalcXs: array[0..180] of Integer;
begin
  Pattern.Width := 362;
  Pattern.Height := 181;

  rX := 0;
  for X := 180 downto 0 do
  begin
    PreCalcXs[rX] := X * X;
    Inc(rX);
  end;

  for Y := 180 downto 0 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    PreCalcY := PreCalcXs[Y];
    rX := 181;
    for X := 180 downto 0 do
    begin
      pRGB := @Colors[Round(Sqrt(PreCalcXs[X] + PreCalcY))];
      Row[X] := pRGB^;
      Row[rX]:= pRGB^;
      Inc(rX);
    end;
  end;

  { Not optimized code
  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(Sqr(180 - X) + Sqr(180 - Y)))];
    for X := 181 to 361 do
      Row[X] := Colors[Round(Sqrt(Sqr(X - 181) + Sqr(180 - Y)))];
  end;
  }
end;

procedure RadialLeft(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y, rY: Integer;
  pRGB: PRGBQuad;
  Row1, Row2: PRGBQuadArray;
  PreCalcY: Integer;
  PreCalcXs: array[0..180] of Integer;
begin
  Pattern.Width := 181;
  Pattern.Height := 362;

  for X := 180 downto 0 do
    PreCalcXs[X] := X * X;

  rY := 180;
  for Y := 0 to 180 do
  begin
    Row1 := PRGBQuadArray(Pattern.ScanLine[Y]);
    Row2 := PRGBQuadArray(Pattern.ScanLine[361-Y]);
    PreCalcY := PreCalcXs[rY];
    for X := 0 to 180 do
    begin
      pRGB := @Colors[Round(Sqrt(PreCalcXs[X] + PreCalcY))];
      Row1[X] := pRGB^;
      Row2[X] := pRGB^;
    end;
    Dec(rY);
  end;

  { Not optimized code
  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(Sqr(X) + Sqr(180 - Y)))];
  end;
  for Y := 181 to 361 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(Sqr(X) + Sqr(Y - 181)))];
  end;
  }
end;

procedure RadialRight(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y, rX: Integer;
  pRGB: PRGBQuad;
  Row1, Row2: PRGBQuadArray;
  PreCalcXs: array[0..180] of Integer;
begin
  Pattern.Width := 181;
  Pattern.Height := 362;

  rX := 0;
  for X := 180 downto 0 do
  begin
    PreCalcXs[rX] := X * X;
    Inc(rX);
  end;

  for Y := 0 to 180 do
  begin
    Row1 := PRGBQuadArray(Pattern.ScanLine[Y]);
    Row2 := PRGBQuadArray(Pattern.ScanLine[361-Y]);
    for X := 0 to 180 do
    begin
      pRGB := @Colors[Round(Sqrt(PreCalcXs[X] + PreCalcXs[Y]))];
      Row1[X] := pRGB^;
      Row2[X] := pRGB^;
    end;
  end;

  { Not optimized code
  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(Sqr(180 - X) + Sqr(180 - Y)))];
  end;
  for Y := 181 to 361 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(Sqr(180 - X) + Sqr(Y - 181)))];
  end;
  }
end;

procedure RadialTopLeft(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  Row: PRGBQuadArray;
  PreCalcY: Integer;
  PreCalcXs: array[0..180] of Integer;
begin
  Pattern.Width := 181;
  Pattern.Height := 181;

  for X := 180 downto 0 do
    PreCalcXs[X] := X * X;

  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    PreCalcY := PreCalcXs[Y];
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(PreCalcXs[X] + PreCalcY))];
  end;

  { Not optimized code
  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(Sqr(X) + Sqr(Y)))];
  end;
  }
end;

procedure RadialTopRight(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y, rX, rY: Integer;
  Row: PRGBQuadArray;
  PreCalcY: Integer;
  PreCalcXs: array[0..180] of Integer;
begin
  Pattern.Width := 181;
  Pattern.Height := 181;

  rX :=0;
  for X := 180 downto 0 do
  begin
    PreCalcXs[rX] := X * X;
    Inc(rX);
  end;

  rY := 180;
  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    PreCalcY := PreCalcXs[rY];
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(PreCalcXs[X] + PreCalcY))];
    Dec(rY);
  end;

  { Not optimized code
  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(Sqr(180 - X) + Sqr(Y)))];
  end;
  }
end;

procedure RadialBottomLeft(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y, rY: Integer;
  Row: PRGBQuadArray;
  PreCalcY: Integer;
  PreCalcXs: array[0..180] of Integer;
begin
  Pattern.Width := 181;
  Pattern.Height := 181;

  for X := 180 downto 0 do
    PreCalcXs[X] := X * X;

  rY := 180;
  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    PreCalcY := PreCalcXs[rY];
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(PreCalcXs[X] + PreCalcY))];
    Dec(rY);
  end;

  { Not optimized code
  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(Sqr(X) + Sqr(180 - Y)))];
  end;
  }
end;

procedure RadialBottomRight(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y, rX: Integer;
  Row: PRGBQuadArray;
  PreCalcY: Integer;
  PreCalcXs: array[0..180] of Integer;
begin
  Pattern.Width := 181;
  Pattern.Height := 181;

  rX := 0;
  for X := 180 downto 0 do
  begin
    PreCalcXs[rX] := X * X;
    Inc(rX);
  end;

  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    PreCalcY := PreCalcXs[Y];
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(PreCalcXs[X] + PreCalcY))];
  end;

  { Not optimized code
  for Y := 0 to 180 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 180 do
      Row[X] := Colors[Round(Sqrt(Sqr(180 - X) + Sqr(180 - Y)))];
  end;
  }
end;

procedure LinearHorizontal(const Colors: TGradientColors; Pattern: TBitmap);
var
  X: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 256;
  Pattern.Height := 1;
  Row := PRGBQuadArray(Pattern.ScanLine[0]);
  for X := 0 to 255 do
    Row[X] := Colors[X];
end;

procedure LinearVertical(const Colors: TGradientColors; Pattern: TBitmap);
var
  Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 1;
  Pattern.Height := 256;
  for Y := 0 to 255 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    Row[0] := Colors[Y];
  end;
end;

procedure ReflectedHorizontal(const Colors: TGradientColors; Pattern: TBitmap);
var
  Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 1;
  Pattern.Height := 512;
  for Y := 0 to 255 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    Row[0] := Colors[255 - Y];
    Row := PRGBQuadArray(Pattern.ScanLine[511 - Y]);
    Row[0] := Colors[255 - Y];
  end;
end;

procedure ReflectedVertical(const Colors: TGradientColors; Pattern: TBitmap);
var
  X: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 512;
  Pattern.Height := 1;
  Row := PRGBQuadArray(Pattern.ScanLine[0]);
  for X := 0 to 255 do
  begin
    Row[X] := Colors[255 - X];
    Row[511 - X] := Colors[255 - X];
  end;
end;

procedure DiagonalLinearForward(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 128;
  Pattern.Height := 129;
  for Y := 0 to 128 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 127 do
      Row[X] := Colors[X + Y];
  end;
end;

procedure DiagonalLinearBackward(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 128;
  Pattern.Height := 129;
  for Y := 0 to 128 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 127 do
      Row[X] := Colors[127 + (Y - X)];
  end;
end;

procedure DiagonalReflectedForward(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 256;
  Pattern.Height := 256;
  for Y := 0 to 255 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 255 do
      if X + Y < 255 then
        Row[X] := Colors[255 - (X + Y)]
      else
        Row[X] := Colors[(Y + X) - 255];
  end;
end;

procedure DiagonalReflectedBackward(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 256;
  Pattern.Height := 256;
  for Y := 0 to 255 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 255 do
      if X > Y then
        Row[X] := Colors[X - Y]
      else
        Row[X] := Colors[Y - X];
  end;
end;

procedure ArrowLeft(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 129;
  Pattern.Height := 256;
  for Y := 0 to 127 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 128 do
      Row[X] := Colors[255 - (X + Y)];
  end;
  for Y := 128 to 255 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 128 do
      Row[X] := Colors[Y - X];
  end;
end;

procedure ArrowRight(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 129;
  Pattern.Height := 256;
  for Y := 0 to 127 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 128 do
      Row[X] := Colors[(X - Y) + 127];
  end;
  for Y := 128 to 255 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 128 do
      Row[X] := Colors[(X + Y) - 128];
  end;
end;

procedure ArrowUp(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 256;
  Pattern.Height := 129;
  for Y := 0 to 128 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 127 do
      Row[X] := Colors[255 - (X + Y)];
    for X := 128 to 255 do
      Row[X] := Colors[X - Y];
  end;
end;

procedure ArrowDown(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 256;
  Pattern.Height := 129;
  for Y := 0 to 128 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 127 do
      Row[X] := Colors[127 + (Y - X)];
    for X := 128 to 255 do
      Row[X] := Colors[(X + Y) - 128];
  end;
end;

procedure Diamond(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 256;
  Pattern.Height := 256;
  for Y := 0 to 127 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 127 do
      Row[X] := Colors[255 - (X + Y)];
    for X := 128 to 255 do
      Row[X] := Colors[X - Y];
  end;
  for Y := 128 to 255 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 127 do
      Row[X] := Colors[Y - X];
    for X := 128 to 255 do
      Row[X] := Colors[(X + Y) - 255];
  end;
end;

procedure Butterfly(const Colors: TGradientColors; Pattern: TBitmap);
var
  X, Y: Integer;
  Row: PRGBQuadArray;
begin
  Pattern.Width := 256;
  Pattern.Height := 256;
  for Y := 0 to 127 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 127 do
      Row[X] := Colors[(X - Y) + 128];
    for X := 128 to 255 do
      Row[X] := Colors[383 - (X + Y)];
  end;
  for Y := 128 to 255 do
  begin
    Row := PRGBQuadArray(Pattern.ScanLine[Y]);
    for X := 0 to 127 do
      Row[X] := Colors[(X + Y) - 128];
    for X := 128 to 255 do
      Row[X] := Colors[128 + (Y - X)];
  end;
end;

{ TGradient }

type
  TPatternBuilder = procedure(const Colors: TGradientColors; Pattern: TBitmap);

const
  PatternBuilder: array[TGradientStyle] of TPatternBuilder = (nil,
    RadialCentral, RadialTop, RadialBottom, RadialLeft, RadialRight,
    RadialTopLeft, RadialTopRight, RadialBottomLeft, RadialBottomRight,
    LinearHorizontal, LinearVertical, ReflectedHorizontal, ReflectedVertical,
    DiagonalLinearForward, DiagonalLinearBackward, DiagonalReflectedForward,
    DiagonalReflectedBackward, ArrowLeft, ArrowRight, ArrowUp, ArrowDown,
    Diamond, Butterfly, RadialRect);

constructor TGradient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  Width := 100;
  Height := 100;
  fColorBegin := clWhite;
  fColorEnd := clBtnFace;
  fStyle := gsRadialC;
  fBorderColor := clActiveBorder;
  fBorderWidth := 0;
  fShift := 0;
  fRotation := 0;
  fReverse := False;
  fUseSysColors := False;
  fPattern := TBitmap.Create;
  fPattern.PixelFormat := pf32bit;
  UpdatePattern;
end;

destructor TGradient.Destroy;
begin
  fPattern.Free;
  inherited Destroy;
end;

procedure TGradient.Loaded;
begin
  inherited Loaded;
  UpdatePattern;
end;

procedure TGradient.Paint;
var
  Rect: TRect;
begin
 if not Dirty then
 begin
   if BorderWidth > 0 then
   begin
     Rect := ClientRect;
     Canvas.Pen.Width := BorderWidth;
     Canvas.Pen.Color := BorderColor;
     Canvas.Pen.Style := psInsideFrame;
     Canvas.Brush.Style := bsClear;
     Canvas.Rectangle(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
     InflateRect(Rect, -BorderWidth, -BorderWidth);
     Canvas.StretchDraw(Rect, Pattern);
   end
   else
    Canvas.StretchDraw(ClientRect, Pattern);
 end;
end;

procedure TGradient.BeginUpdate;
begin
  Inc(UpdateCount);
end;

procedure TGradient.EndUpdate;
begin
  Dec(UpdateCount);
  if (UpdateCount = 0) and UpdatePended then
    UpdatePattern;
end;

function TGradient.CopyPatternTo(Bitmap: TBitmap): Boolean;
begin
  Result := False;
  if not Dirty and (UpdateCount = 0) and Assigned(Bitmap) then
  begin
    Bitmap.Assign(Pattern);
    Result := True;
  end;
end;

procedure TGradient.InvalidatePattern;
begin
  UpdatePattern;
end;

procedure TGradient.WMSettingChange(var Message: TMessage);
begin
  inherited;
  if UseSysColors then
    UpdateSysColors;
end;

procedure TGradient.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  if Assigned(fOnMouseEnter) then
    fOnMouseEnter(Self);
end;

procedure TGradient.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if Assigned(fOnMouseLeave) then
    fOnMouseLeave(Self);
end;

procedure TGradient.SetColorBegin(Value: TColor);
begin
  if fColorBegin <> Value then
  begin
    fColorBegin := Value;
    fUseSysColors := False;
    UpdatePattern;
  end;
end;

procedure TGradient.SetColorEnd(Value: TColor);
begin
  if fColorEnd <> Value then
  begin
    fColorEnd := Value;
    fUseSysColors := False;
    UpdatePattern;
  end;
end;

procedure TGradient.SetBorderColor(Value: TColor);
begin
  if fBorderColor <> Value then
  begin
    fBorderColor := Value;
    Invalidate;
  end;
end;

procedure TGradient.SetBorderWidth(Value: TBorderWidth);
begin
  if fBorderWidth <> Value then
  begin
    fBorderWidth := Value;
    Invalidate;
  end;
end;

procedure TGradient.SetUseSysColors(Value: Boolean);
begin
  if fUseSysColors <> Value then
  begin
    fUseSysColors := Value;
    if fUseSysColors then
      UpdateSysColors;
  end;
end;

procedure TGradient.SetStyle(Value: TGradientStyle);
begin
  if fStyle <> Value then
  begin
    fStyle := Value;
    UpdatePattern;
  end;
end;

procedure TGradient.SetShift(Value: TGradientShift);
begin
  if Value < Low(TGradientShift) then
    Value := Low(TGradientShift)
  else if Value > High(TGradientShift) then
    Value := High(TGradientShift);

  if fShift <> Value then
  begin
    fShift := Value;
    UpdatePattern;
  end;
end;

procedure TGradient.SetRotation(Value: TGradientRotation);
begin
  if Value < Low(TGradientRotation) then
    Value := Low(TGradientRotation)
  else if Value > High(TGradientRotation) then
    Value := High(TGradientRotation);

  if fRotation <> Value then
  begin
    fRotation := Value;
    UpdatePattern;
  end;
end;

procedure TGradient.SetReverse(Value: Boolean);
begin
  if fReverse <> Value then
  begin
    fReverse := Value;
    UpdatePattern;
  end;
end;

function TGradient.IsColorBeginSaved: Boolean;
begin
  Result := not UseSysColors and (ColorBegin <> clWhite);
end;

function TGradient.IsColorEndSaved: Boolean;
begin
  Result := not UseSysColors and (ColorBegin <> clBtnFace);
end;

procedure TGradient.UpdateSysColors;
{$IFNDEF COMPILER4_UP}
const
  COLOR_GRADIENTACTIVECAPTION = 27;
{$ENDIF}
begin
  BeginUpdate;
  try
    ColorBegin := GetSysColor(COLOR_ACTIVECAPTION);
    try
      ColorEnd := GetSysColor(COLOR_GRADIENTACTIVECAPTION);
      fUseSysColors := True;
    except
      // This windows version doesn't support gradient colors...
      ColorEnd := ColorBegin;
      fUseSysColors := False;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TGradient.UpdatePattern;
var
  Colors: TGradientColors;
  dRed, dGreen, dBlue: Integer;
  RGBColor1, RGBColor2: TColor;
  RGB1, RGB2: TRGBQuad;
  UpdatedRect: TRect;
  Index, rIndex: Integer;
  M, rM: Integer;
begin
  UpdatePended := True;

  if (csLoading in ComponentState) or (UpdateCount <> 0) then Exit;

  UpdatePended := False;

  if Reverse then
  begin
    RGBColor1 := ColorToRGB(ColorEnd);
    RGBColor2 := ColorToRGB(ColorBegin);
  end
  else
  begin
    RGBColor1 := ColorToRGB(ColorBegin);
    RGBColor2 := ColorToRGB(ColorEnd);
  end;

  RGB1.rgbRed := GetRValue(RGBColor1);
  RGB1.rgbGreen := GetGValue(RGBColor1);
  RGB1.rgbBlue := GetBValue(RGBColor1);
  RGB1.rgbReserved := 0;

  RGB2.rgbRed := GetRValue(RGBColor2);
  RGB2.rgbGreen := GetGValue(RGBColor2);
  RGB2.rgbBlue := GetBValue(RGBColor2);
  RGB2.rgbReserved := 0;

  if Shift > 0 then
  begin
    RGB1.rgbRed := Byte(RGB1.rgbRed + MulDiv(RGB2.rgbRed - RGB1.rgbRed, Shift, 100));
    RGB1.rgbGreen := Byte(RGB1.rgbGreen + MulDiv(RGB2.rgbGreen - RGB1.rgbGreen, Shift, 100));
    RGB1.rgbBlue := Byte(RGB1.rgbBlue + MulDiv(RGB2.rgbBlue - RGB1.rgbBlue, Shift, 100));
  end
  else if Shift < 0 then
  begin
    RGB2.rgbRed := Byte(RGB2.rgbRed + MulDiv(RGB2.rgbRed - RGB1.rgbRed, Shift, 100));
    RGB2.rgbGreen := Byte(RGB2.rgbGreen + MulDiv(RGB2.rgbGreen - RGB1.rgbGreen, Shift, 100));
    RGB2.rgbBlue := Byte(RGB2.rgbBlue + MulDiv(RGB2.rgbBlue - RGB1.rgbBlue, Shift, 100));
  end;

  dRed := RGB2.rgbRed - RGB1.rgbRed;
  dGreen := RGB2.rgbGreen - RGB1.rgbGreen;
  dBlue := RGB2.rgbBlue - RGB1.rgbBlue;

  M := MulDiv(255, Rotation, 100);
  if M = 0 then
    for Index := 0 to 255 do
      with Colors[Index] do
      begin
        rgbRed := RGB1.rgbRed + (Index * dRed) div 255;
        rgbGreen := RGB1.rgbGreen + (Index * dGreen) div 255;
        rgbBlue := RGB1.rgbBlue + (Index * dBlue) div 255;
      end
  else if M > 0 then
  begin
    M := 255 - M;
    for Index := 0 to M - 1 do
      with Colors[Index] do
      begin
        rgbRed := RGB1.rgbRed + (Index * dRed) div M;
        rgbGreen := RGB1.rgbGreen + (Index * dGreen) div M;
        rgbBlue := RGB1.rgbBlue + (Index * dBlue) div M;
      end;
    for Index := M to 255 do
      with Colors[Index] do
      begin
        rIndex := 255 - Index;
        rM := 255 - M;
        rgbRed := RGB1.rgbRed + ((rIndex) * dRed) div (rM);
        rgbGreen := RGB1.rgbGreen + ((rIndex) * dGreen) div (rM);
        rgbBlue := RGB1.rgbBlue + ((rIndex) * dBlue) div (rM);
      end;
  end
  else if M < 0 then
  begin
    M := -M;
    for Index := 0 to M do
      with Colors[Index] do
      begin
        rgbRed := RGB2.rgbRed - (Index * dRed) div M;
        rgbGreen := RGB2.rgbGreen - (Index * dGreen) div M;
        rgbBlue := RGB2.rgbBlue - (Index * dBlue) div M;
      end;
    for Index := M + 1 to 255 do
      with Colors[Index] do
      begin
        rIndex := 255 - Index;
        rM := 255 - M;
        rgbRed := RGB2.rgbRed - ((rIndex) * dRed) div (rM);
        rgbGreen := RGB2.rgbGreen - ((rIndex) * dGreen) div (rM);
        rgbBlue := RGB2.rgbBlue - ((rIndex) * dBlue) div (rM);
      end;
  end;

  Dirty := True;
  try
    if @PatternBuilder[Style] <> nil then
      PatternBuilder[Style](Colors, Pattern)
    else if Assigned(fOnCustom) then
      fOnCustom(Self, Colors, Pattern)
    else
    begin
      Pattern.Width := 2;
      Pattern.Height := 2;
      Pattern.Canvas.Pixels[0, 0] := RGBColor1;
      Pattern.Canvas.Pixels[0, 1] := RGBColor2;
      Pattern.Canvas.Pixels[1, 0] := RGBColor2;
      Pattern.Canvas.Pixels[1, 1] := RGBColor1;
    end;
  finally
    Dirty := False;
  end;

  if (Parent <> nil) and Parent.HandleAllocated then
  begin
    UpdatedRect := BoundsRect;
    InvalidateRect(Parent.Handle, @UpdatedRect, False);
    if csDesigning in ComponentState then Parent.Update;
  end
  else
    Invalidate;
end;

procedure Register;
begin
  RegisterComponents('Samples', [TGradient]);
end;

end.
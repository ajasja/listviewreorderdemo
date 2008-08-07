unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Gradient, Menus;

type
  TMainForm = class(TForm)
    AnimTimer: TTimer;
    Toolbar: TPanel;
    GradientStyles: TComboBox;
    Label1: TLabel;
    Panel: TPanel;
    Gradient: TGradient;
    AnimShift: TCheckBox;
    AnimRotation: TCheckBox;
    Image: TImage;
    ShowImage: TCheckBox;
    ProcessTime: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure GradientStylesChange(Sender: TObject);
    procedure ShowImageClick(Sender: TObject);
    procedure AnimShiftClick(Sender: TObject);
    procedure AnimRotationClick(Sender: TObject);
    procedure AnimTimerTimer(Sender: TObject);
    procedure GradientCustom(Sender: TObject;
      const Colors: TGradientColors; Pattern: TBitmap);
  private
    ShiftStep: Integer;
    RotateStep: Integer;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

{$I DELPHIAREA.INC}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  { if Delphi 4 or higher is in use, we turn on double buffering for the  }
  { parent control of the Gradient control to prevent flickering on the   }
  { non-windowed controls, which are placed over the gradient control.    }
  { This flickering is expected, because TGradient is a non-windowed      }
  { control and uses its parent's canvas for drawing. If in your program, }
  { you have not placeed non-windowed controls over TGradient, or you are }
  { not going to animate the gradient colors, you do not need to turn on  }
  { double buffering.                                                     }

  {$IFDEF COMPILER4_UP}
  Panel.DoubleBuffered := True;
  {$ELSE}
  ShowImage.Enabled := False; { older versions do not supprt double buffering }
  {$ENDIF}

  GradientStyles.ItemIndex := Ord(Gradient.Style);

  ShiftStep := 1;
  RotateStep := 1;
end;

procedure TMainForm.GradientStylesChange(Sender: TObject);
begin
  with Gradient do
  begin
    BeginUpdate; { Perevents updating the screen }
    try
      Style := TGradientStyle(GradientStyles.ItemIndex);
      Shift := 0;
      Rotation := 0;
    finally
      EndUpdate; { Updates the screen, if it is necessary }
    end;
  end;
end;

procedure TMainForm.ShowImageClick(Sender: TObject);
begin
  if ShowImage.Checked then
  begin
    Image.Left := Gradient.Left + (Gradient.Width - Image.Width) div 2;
    Image.Top := Gradient.Top + (Gradient.Height - Image.Height) div 2;
  end;
  Image.Visible := ShowImage.Checked;
end;

procedure TMainForm.AnimShiftClick(Sender: TObject);
begin
  AnimTimer.Enabled := AnimShift.Checked or AnimRotation.Checked;
  ProcessTime.Visible := AnimTimer.Enabled;
end;

procedure TMainForm.AnimRotationClick(Sender: TObject);
begin
  AnimTimer.Enabled := AnimShift.Checked or AnimRotation.Checked;
  ProcessTime.Visible := AnimTimer.Enabled;
end;

procedure TMainForm.AnimTimerTimer(Sender: TObject);
var
  StartTime, EndTime: DWORD;
begin
  StartTime := GetTickCount;
  with Gradient do
  begin
    BeginUpdate; { Perevents updating the screen }
    try
      if AnimShift.Checked then
      begin
        if Shift = Low(TGradientShift) then
          ShiftStep := +1
        else if Shift = High(TGradientShift) then
          ShiftStep := -1;
        Shift := Shift + ShiftStep;
      end;
      if AnimRotation.Checked then
      begin
        if Rotation = Low(TGradientRotation) then
          RotateStep := +1
        else if Rotation = High(TGradientRotation) then
          RotateStep := -1;
        Rotation := Rotation + RotateStep;
      end;
    finally
      EndUpdate; { Updates the screen, if it is necessary }
    end;
  end;
  EndTime := GetTickCount;
  if StartTime = EndTime then
    ProcessTime.Caption := 'Process Time: < 1ms'
  else
    ProcessTime.Caption := Format('Process Time: %u ms', [EndTime - StartTime]);
  ProcessTime.Update;
end;

procedure TMainForm.GradientCustom(Sender: TObject;
  const Colors: TGradientColors; Pattern: TBitmap);
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
      Row[X] := Colors[Random(256)];
  end;
end;

end.

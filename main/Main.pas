unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, XPMan, ActnMan, ActnColorMaps, ImgList, ActnList, XPStyleActnCtrls,
  Buttons, AppEvnts, Gradient;

type
  TForm1 = class(TForm)
    gbGragDrop: TGroupBox;
    ListView: TListView;
    XPManifest: TXPManifest;
    btnUp: TBitBtn;
    btnDown: TBitBtn;
    ActionManager: TActionManager;
    acMoveListItemUp: TAction;
    acMoveListItemDown: TAction;
    ImageList: TImageList;
    ApplicationEvents: TApplicationEvents;
    Gradient: TGradient;
    gbInstructions: TGroupBox;
    Memo: TMemo;
    procedure acMoveListItemDownExecute(Sender: TObject);
    procedure acMoveListItemUpExecute(Sender: TObject);
    procedure ApplicationEventsIdle(Sender: TObject; var Done: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure ListViewDblClick(Sender: TObject);
    procedure ListViewDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure ListViewDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept:
        Boolean);
    procedure ListViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
uses
  TypInfo;

procedure TForm1.acMoveListItemDownExecute(Sender: TObject);
var
  SelectedItem, TempItem, DownItem : TListItem;
  Idx : Integer;
begin
  SelectedItem:=ListView.Selected;

  If not Assigned(SelectedItem) then exit;
  Idx:=SelectedItem.Index;
  If Idx=ListView.Items.Count-1 then exit; //If last item then exit

  ListView.Items.BeginUpdate;
  try
    TempItem:=TListItem.Create(ListView.Items);
    DownItem:=ListView.Items[idx+1];
    TempItem.Assign(DownItem);
    DownItem.Assign(SelectedItem);
    SelectedItem.Assign(TempItem);
    SelectedItem.Selected:=False;
    DownItem.Selected:=true;
    DownItem.Focused:=True;
  finally
    TempItem.Free;
    ListView.Items.EndUpdate;
  end; {finally}
end;

procedure TForm1.acMoveListItemUpExecute(Sender: TObject);
var
  SelectedItem, TempItem, UpItem : TListItem;
  Idx : Integer;
begin
  SelectedItem:=ListView.Selected;

  If not Assigned(SelectedItem) then exit;
  Idx:=SelectedItem.Index;
  If Idx=0 then exit;

  ListView.Items.BeginUpdate;
  try
    TempItem:=TListItem.Create(ListView.Items);
    UpItem:=ListView.Items[idx-1];
    TempItem.Assign(UpItem);
    UpItem.Assign(SelectedItem);
    SelectedItem.Assign(TempItem);
    SelectedItem.Selected:=False;
    UpItem.Selected:=true;
    UpItem.Focused:=True;
  finally
    TempItem.Free;
    ListView.Items.EndUpdate;
  end; {finally}
end;

procedure TForm1.ApplicationEventsIdle(Sender: TObject; var Done: Boolean);
begin
  acMoveListItemUp.Enabled:=(ListView.Selected<>nil);
  acMoveListItemDown.Enabled:=acMoveListItemUp.Enabled;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
 aListItem : TListItem;
 I : Integer;
begin
  ListView.DragMode := dmAutomatic;
  //ListView.RowSelect := true;
  //ListView.MultiSelect := true;
  ListView.ViewStyle := vsReport;

  For I:=1 to 10 do
   begin
     aListItem:=ListView.Items.Add;
     aListItem.Caption:='My Item '+IntToStr(I);

   end;

end;

procedure TForm1.ListViewDblClick(Sender: TObject);
var
  hts : THitTests;
  ht : THitTest;
  sht : string;
  ListViewCursosPos : TPoint;

begin
  //position of the mouse cursor related to ListView
  ListViewCursosPos := ListView.ScreenToClient(Mouse.CursorPos) ;

  //double click where?
  hts := ListView.GetHitTestInfoAt(ListViewCursosPos.X, ListViewCursosPos.Y) ;

  //"debug" hit test
  Caption := '';
  for ht in hts do
  begin
    sht := GetEnumName(TypeInfo(THitTest), Integer(ht)) ;
    Caption := Format('%s %s | ',[Caption, sht]) ;
  end;

  //locate the double-clicked item
  if hts <= [htOnIcon, htOnItem, htOnLabel, htOnStateIcon] then
    if Assigned(ListView.Selected) then
      ListView.Selected.EditCaption;



end;

procedure TForm1.ListViewDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  currentItem, nextItem, dragItem, dropItem : TListItem;
begin
  if Sender = Source then
  begin
    with TListView(Sender) do
    begin
      dropItem := GetItemAt(X, Y) ;
      currentItem := Selected;
      while currentItem <> nil do
      begin
        nextItem := GetNextItem(currentItem, SdAll, [IsSelected]) ;
        if Assigned(dropItem) then
          dragItem := Items.Insert(dropItem.Index)
        else
          dragItem := Items.Add;
        dragItem.Assign(currentItem) ;
        dragItem.Selected:=true;
        currentItem.Free;
        currentItem := nextItem;
      end;
    end;
  end;
end;

procedure TForm1.ListViewDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var
    Accept: Boolean);
begin
  Accept := Sender = ListView;
end;

procedure TForm1.ListViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F2 then
    if Assigned(ListView.Selected) then
      ListView.Selected.EditCaption;
  if (Key = VK_UP) and (ssCtrl in Shift) then
    If acMoveListItemUp.Enabled then
    begin
      acMoveListItemUp.Execute;
      Key:=0; //So the focus doesn't go up
    end;
  if (Key = VK_Down) and (ssCtrl in Shift) then
    If acMoveListItemDown.Enabled then
    begin
      acMoveListItemDown.Execute;
      Key:=0; //So the focus doesn't go up
    end;

end;



end.

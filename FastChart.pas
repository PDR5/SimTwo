unit FastChart;

{$MODE Delphi}

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IniFiles, Menus, ProjConfig,
  ComCtrls, IniPropStorage, TAGraph, TASeries;

type
  TSeriesFunction =  function(r,i: integer): Double;

  TSeriesDef = class(TComponent)
  public
    RobotNum: integer;
    AxisNum: integer;
    func: TSeriesFunction;
  end;

type

  { TFChart }

  TFChart = class(TForm)
    Chart: TChart;
    CBFreeze: TCheckBox;
    IniPropStorage: TIniPropStorage;
    Label1: TLabel;
    EditMaxPoints: TEdit;
    BSet: TButton;
    BSave: TButton;
    EditFileName: TEdit;
    PageControl: TPageControl;
    PanelChart: TPanel;
    TabUserCharts: TTabSheet;
    TabTimeChart: TTabSheet;
    TreeView: TTreeView;
    ILCheckBox: TImageList;
    BChartRefresh: TButton;
    BSaveLog: TButton;
    BClear: TButton;
    procedure FormCreate(Sender: TObject);
    procedure BSetClick(Sender: TObject);
    procedure CBFreezeClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BSaveClick(Sender: TObject);
    procedure TreeViewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BChartRefreshClick(Sender: TObject);
    procedure BSaveLogClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BClearClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    procedure FillTreeView(tree: TTreeView);
    procedure FillRobotTreeView(r: integer; root: TTreeNode; tree: TTreeView);
    procedure FillTreeViewItem(r, i: integer; str: string;  func: TSeriesFunction; root: TTreeNode; tree: TTreeView);
    procedure RefreshChart(tree: TTreeView);
    function GetNodePathText(tree: TTreeView; node: TTreeNode): string;
    procedure RemoveAllSeries(tree: TTreeView);
  public
    SeriesNameList: TStringList;
    MaxPoints : integer;
    physTime_zero: double;


    procedure AddSeriesValue(var Series: TLineSeries; X, Y: double);
    procedure AddPoint(x, r, y, u: double);
    procedure AddSample(r: integer; t: double);

    procedure FormSave(ProjMemIni : TMemIniFile);
    procedure FormLoad(ProjMemIni : TMemIniFile);
  end;

procedure ExpandNodePath(node: TTreeNode);

var
  FChart: TFChart;
  UserCharts: array of TChart;
  UserChartsCount: integer;

implementation


uses Params, ODERobotsPublished, Viewer, ODERobots;

{$R *.lfm}


function RandColor(i: integer): TColor;
begin
  RandSeed:=i;
  random(256);
  result:=random(128) or (random(128) shl 8) or (random(128) shl 16);
end;


procedure TFChart.FormSave(ProjMemIni : TMemIniFile);
begin
  //ProjMemIni.WriteInteger('Chart','ActiveTab',PageControl.ActivePageIndex);

  ProjMemIni.WriteString('Chart','MaxPoints',EditMaxPoints.text);
  //SaveFormGeometryToMemIni(ProjMemIni,FChart);
end;

procedure TFChart.FormLoad(ProjMemIni : TMemIniFile);
begin
  //PageControl.ActivePageIndex := ProjMemIni.ReadInteger('Main','ActiveTab',PageControl.ActivePageIndex);

  EditMaxPoints.text:= ProjMemIni.ReadString('Chart','MaxPoints',EditMaxPoints.text);
  //LoadFormGeometryFromMemIni(ProjMemIni,FChart);
end;


procedure TFChart.FormCreate(Sender: TObject);
var i: integer;
begin
  SeriesNameList := TStringList.Create;
  IniPropStorage.IniFileName := GetIniFineName;
  physTime_zero := 0;

  UserChartsCount := 16;
  setlength(UserCharts, UserChartsCount);
  for i := 0 to UserChartsCount -1 do begin
    UserCharts[i] := TChart.Create(FChart);
    UserCharts[i].Align := alClient;
  end;
  UserCharts[0].Parent := PanelChart;
end;

procedure TFChart.AddSeriesValue(var Series: TLineSeries; X,Y: double);
begin
  if Series.Count > MaxPoints then begin
    Series.Delete(0);
  end;
  Series.AddXY(X, Y);
end;

procedure TFChart.AddPoint(x,r,y,u: double);
begin
  if CBFreeze.Checked then exit;
end;

procedure TFChart.BSetClick(Sender: TObject);
begin
  MaxPoints := strtointdef(EditMaxPoints.Text, MaxPoints);
end;

procedure TFChart.CBFreezeClick(Sender: TObject);
var i: integer;
begin
  Chart.ZoomFull();
  if not CBFreeze.Checked then begin
    for i := 0 to Chart.SeriesCount -1 do begin
      (Chart.Series[i] as TLineSeries).Clear;
    end;
    physTime_zero := WorldODE.physTime;
  end;
end;

procedure TFChart.FormShow(Sender: TObject);
var fname: string;
begin
  MaxPoints := strtointdef(EditMaxPoints.Text, 400);
  fname := ChangeFileExt(IniPropStorage.IniFileName,'.LogSeries.txt');
  if fileexists(fname) then
    SeriesNameList.LoadFromFile(fname);
  FillTreeView(TreeView);
  RefreshChart(TreeView);
end;

procedure TFChart.AddSample(r: integer; t: double);
var i: integer;
    v: double;
    df: TSeriesDef;
    LS: TLineSeries;
begin
  if CBFreeze.Checked then exit;
  for i := 0 to Chart.SeriesCount - 1 do begin
    LS := Chart.Series[i] as TLineSeries;
    with LS do begin
      if tag = 0 then continue;
      df := TSeriesDef(Tag);
      if df.RobotNum = r then begin
        v := df.func(df.RobotNum, df.AxisNum);
        AddXY(t - physTime_zero, v);
        while Count > MaxPoints do Delete(0);
      end;
    end;
  end;
end;

procedure TFChart.BSaveClick(Sender: TObject);
var s: string;
begin
  //Chart.PrintResolution := -100;
  s := ChangeFileExt(EditFileName.Text, '.emf');
  Chart.SaveToBitmapFile(s);
  //Chart.PrintResolution := 0;
end;


procedure TFChart.FillTreeViewItem(r, i: integer; str: string; func:TSeriesFunction; root: TTreeNode; tree: TTreeView);
var node: TTreeNode;
    df: TSeriesDef;
begin
  df := TSeriesDef.Create(tree); //Warning: the TSeriesDef is being owned by the tree
  df.RobotNum := R;
  df.AxisNum := i;
  df.func := func;

  node:= tree.Items.AddChild(root, str);
  node.Data:=df;
end;


procedure TFChart.FillRobotTreeView(r: integer; root: TTreeNode; tree: TTreeView);
var node, sub_nonde: TTreeNode;
    i: integer;
begin
  with tree.Items do begin
    node:=AddChild(root,'State');
    node.Data:=nil;
    //FillRobotStateTreeView(num,node,tree);
    FillTreeViewItem(r, 0, 'x', @GetSolidX, node, tree);
    FillTreeViewItem(r, 0, 'y', @GetSolidY, node, tree);
    FillTreeViewItem(r, 0, 'z', @GetSolidZ, node, tree);
    FillTreeViewItem(r, 0, 'theta', @GetSolidTheta, node, tree);
    FillTreeViewItem(r, 0, 'Vx', @GetSolidVx, node, tree);
    FillTreeViewItem(r, 0, 'Vy', @GetSolidVy, node, tree);
    FillTreeViewItem(r, 0, 'Vz', @GetSolidVz, node, tree);

    node:=AddChild(root,'Axes');
    node.Data:=nil;
    for i := 0 to WorldODE.Robots[r].Axes.Count - 1 do begin
      sub_nonde:=AddChild(node, WorldODE.Robots[r].Axes[i].ParentLink.description);
      sub_nonde.Data:=nil;
      //FillRobotLinksStateTreeView(num, i,sub_nonde,tree);
      FillTreeViewItem(r, i, 'Pos', @GetAxisPosDeg, sub_nonde, tree);
      FillTreeViewItem(r, i, 'Speed', @GetAxisSpeedDeg, sub_nonde, tree);
      FillTreeViewItem(r, i, 'T', @GetAxisTorque, sub_nonde, tree);

      FillTreeViewItem(r, i, 'I', @GetAxisI, sub_nonde, tree);
      FillTreeViewItem(r, i, 'U', @GetAxisU, sub_nonde, tree);
      FillTreeViewItem(r, i, 'Power', @GetAxisUIPower, sub_nonde, tree);
      //FillTreeViewItem(r, i, 'Mech Power', @GetAxisTWPower, sub_nonde, tree);
      FillTreeViewItem(r, i, 'Pos ref', @GetAxisPosRefDeg, sub_nonde, tree);
      FillTreeViewItem(r, i, 'Speed ref', @GetAxisSpeedRefDeg, sub_nonde, tree);
      FillTreeViewItem(r, i, 'Motor Speed', @GetAxisMotorSpeed, sub_nonde, tree);
      FillTreeViewItem(r, i, 'Motor Pos', @GetAxisMotorPosDeg, sub_nonde, tree);
    end;
  end;
end;


procedure TFChart.FillTreeView(tree: TTreeView);
var node: TTreeNode;
    i: integer;
begin
  tree.Items.Clear;
  with tree.Items do begin
    //node:=Add(nil,'General');
    //node.Data:=nil;
    //FillGeneralTreeView(node,tree);
    //node:=Add(nil,'Ball');
    //node.Data:=nil;
    //FillBallTreeView(node,tree);
    for i:=0 to WorldODE.Robots.Count-1 do begin
      //node:=Add(nil,'Robot '+inttostr(i+1));
      node:=Add(nil,WorldODE.Robots[i].ID);
      node.Data:=nil;
      FillRobotTreeView(i,node,tree);
    end;

    for i:=0 to Count-1 do begin
      if tree.Items[i].Data=nil then begin
        tree.Items[i].ImageIndex:=2
      end else begin
        tree.Items[i].ImageIndex:=0;
      end;
      tree.Items[i].SelectedIndex := tree.Items[i].ImageIndex;
      tree.Items[i].StateIndex:=-1;
      if SeriesNameList.IndexOf(GetNodePathText(tree, tree.Items[i])) >= 0 then begin
        tree.Items[i].ImageIndex:=1;
        //tree.Items[i].Expand(true);
        ExpandNodePath(tree.Items[i]);
      end;
    end;
  end;
end;


procedure TFChart.TreeViewMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var node: TTreeNode;
    HT: THitTests;
begin
  node:=(Sender as TTreeView).GetNodeAt(X,Y);
  if node=nil then exit;

  if Button=mbLeft then begin
    HT:=(Sender as TTreeView).GetHitTestInfoAt(X,Y);
    if htOnIndent in HT then exit;
    if node.ImageIndex=0 then begin
      node.ImageIndex:=1;
      node.SelectedIndex:=1;
    end else begin
      if node.ImageIndex=1 then begin
        node.ImageIndex:=0;
        node.SelectedIndex:=0;
      end;
    end;
  end else begin
    if node.Count=0 then begin
        if pos('''',node.Text)<>0 then begin
          node.Text:=copy(node.Text,1,length(node.Text)-1);
        end else begin
          node.Text:=node.Text+'''';
        end;
      {PointerToOffsetType(node.Data,offset,tipo);
      if tipo=logDouble then begin
        if pos('''',node.Text)<>0 then begin
          node.Text:=copy(node.Text,1,length(node.Text)-1);
        end else begin
          node.Text:=node.Text+'''';
        end;
      end;}
    end;
  end;
  TreeView.Refresh;
end;

function TFChart.GetNodePathText(tree: TTreeView; node: TTreeNode): string;
begin
  result := '';
  while node <> nil do begin
    result := node.Text + '.' + result;
    node := node.Parent;
  end;
end;



procedure ExpandNodePath(node: TTreeNode);
begin
  while node <> nil do begin
    node.Expand(false);
    node := node.Parent;
  end;
end;


procedure TFChart.RemoveAllSeries(tree: TTreeView);
var i: integer;
    cs: TBasicChartSeries;
//    df: TSeriesDef;
//    node: TTreeNode;
//    derivative: boolean;
begin
  SeriesNameList.Clear;

  // clear chart series
  with Chart do begin
    While Series.Count>0 do begin
      cs:=Series[0];
      RemoveSeries(cs);
      cs.Free;
    end;
  end;

  with tree.Items do begin
    for i:=0 to Count-1 do begin
      if tree.Items[i].ImageIndex=1 then begin
        tree.Items[i].ImageIndex :=0 ;
        tree.Items[i].SelectedIndex := 0;
      end;
    end;
  end;
end;


procedure TFChart.RefreshChart(tree: TTreeView);
var i{, cnt}: integer;
    cs: TLineSeries;
    df: TSeriesDef;
//    node: TTreeNode;
//    derivative: boolean;
begin
  SeriesNameList.Clear;

  with tree.Items do begin

    // clear chart series
    with Chart do begin
      While Series.Count>0 do begin
        RemoveSeries(Series[0]);
        cs.Free;
      end;
    end;

    //cnt:=0;
    for i:=0 to Count-1 do begin
      if tree.Items[i].ImageIndex=1 then begin
        //Inc(cnt);

        // create new chart series for each variable
        cs:=TLineSeries.Create(FChart);
        cs.SeriesColor:=RandColor(i);
        cs.Title := GetNodePathText(tree, tree.Items[i]);
        df := TSeriesDef(tree.Items[i].Data);
        cs.Tag := integer(df);

        Chart.AddSeries(cs);
        SeriesNameList.Add(cs.Title);
      end;
    end;
  end;
end;


procedure TFChart.BChartRefreshClick(Sender: TObject);
begin
  RefreshChart(TreeView);
end;

procedure TFChart.BSaveLogClick(Sender: TObject);
var cs: TLineSeries;
    i, c, TotLines, TotCols: integer;
    str: string;
    sl: TStringList;
begin
  with Chart do begin
    if Series.Count <= 0 then exit;
    //if SaveDialogLog.Execute then begin
    //  SaveDialogLog.InitialDir:=ExtractFilePath(SaveDialogLog.FileName);
    TotCols := Series.Count;
    TotLines := (Series[0] as TLineSeries).Count;
    sl:=TStringList.Create;
    try
      for i := 0 to TotLines - 1 do begin
        str := '';
        for c := 0 to TotCols - 1 do begin
          cs:=Series[c] as TLineSeries;
          str := str + format('%g ',[cs.YValue[i]]);
        end;
        sl.Add(str);
      end;
      sl.SaveToFile(ChangeFileExt(EditFileName.Text, '.log'));
      //sl.SaveToFile(SaveDialogLog.FileName);
    finally
      sl.Free;
    end;
  end;
end;


procedure TFChart.FormDestroy(Sender: TObject);
begin
  SeriesNameList.SaveToFile(ChangeFileExt(IniPropStorage.IniFileName,'.LogSeries.txt'));
  SeriesNameList.Free;
end;

procedure TFChart.BClearClick(Sender: TObject);
begin
  RemoveAllSeries(TreeView);
end;

procedure TFChart.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (ssctrl in Shift) then begin
    if (ssShift in Shift) and (key = ord('T')) then CBFreeze.Checked := not CBFreeze.Checked;
  end;
end;

end.

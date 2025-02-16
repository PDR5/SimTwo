unit Editor;

{$MODE Delphi}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SynEdit, SynEditHighlighter, SynHighlighterPas, StdCtrls, SynMemo,
  ExtCtrls, ComCtrls, SynEditTypes, Menus, math,
  uPSComponent, uPSUtils, uPSRuntime, SynCompletion, uPSComponent_Default,
  uPSComponent_StdCtrls, uPSComponent_Controls, uPSComponent_Forms, ProjConfig,
  SynEditMiscClasses, PrintersDlgs, uPSCompiler, Clipbrd, lNetComponents,
  IniPropStorage, Rlan, SynEditMarks, process, LCLIntf, Types, LCLType, lnet;


type

  { TFEditor }

  TFEditor = class(TForm)
    IniPropStorage: TIniPropStorage;
    MenuIncreaseFont: TMenuItem;
    MenuDecreaseFont: TMenuItem;
    MenuResetFont: TMenuItem;
    MenuItem2: TMenuItem;
    SynPasSyn: TSynPasSyn;
    PageControl: TPageControl;
    TabProject: TTabSheet;
    TabControl: TTabSheet;
    Splitter: TSplitter;
    SynEditST: TSynEdit;
    PageControlBottom: TPageControl;
    TabOutput: TTabSheet;
    TabErrors: TTabSheet;
    LBErrors: TListBox;
    TabPascal: TTabSheet;
    SynEditPascal: TSynEdit;
    SynMemoHeader: TSynMemo;
    StatusBar: TStatusBar;
    MainMenu: TMainMenu;
    MenuFile: TMenuItem;
    MenuNew: TMenuItem;
    MenuOpen: TMenuItem;
    N2: TMenuItem;
    MenuSave: TMenuItem;
    MenuSaveAs: TMenuItem;
    N3: TMenuItem;
    MenuPrintSource: TMenuItem;
    N1: TMenuItem;
    MenuExit: TMenuItem;
    MenuEdit: TMenuItem;
    MenuUndo: TMenuItem;
    MenuRedo: TMenuItem;
    N4: TMenuItem;
    MenuFind: TMenuItem;
    MenuReplace: TMenuItem;
    MenuPascal: TMenuItem;
    MenuProgram: TMenuItem;
    MenuCompile: TMenuItem;
    MenuRun: TMenuItem;
    MenuStop: TMenuItem;
    MenuWindow: TMenuItem;
    MenuChart: TMenuItem;
    MenuControl: TMenuItem;
    MenuLog: TMenuItem;
    MenuCalculator: TMenuItem;
    MenuHelp: TMenuItem;
    MenuAbout: TMenuItem;
    MenuLocalHelp: TMenuItem;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    FindDialog: TFindDialog;
    ReplaceDialog: TReplaceDialog;
    PrintDialog: TPrintDialog;
    PSScript: TPSScriptDebugger;
    MenuTest: TMenuItem;
    TabVariables: TTabSheet;
    LBVariables: TListBox;
    MenuSetResetInspector: TMenuItem;
    N5: TMenuItem;
    MenuShowLocalVariables: TMenuItem;
    MenuShowGlobalVariables: TMenuItem;
    SynCompletionProposal: TSynCompletion;
    PSImport_Classes: TPSImport_Classes;
    PSImport_Forms: TPSImport_Forms;
    PSImport_Controls: TPSImport_Controls;
    PSImport_StdCtrls: TPSImport_StdCtrls;
    CBSaveOnRun: TCheckBox;
    PopupMenuOutput: TPopupMenu;
    PopUpClearAll: TMenuItem;
    Label3: TLabel;
    MemoDescription: TMemo;
    LBResult: TListBox;
    MenuCopy: TMenuItem;
    MenuCut: TMenuItem;
    N6: TMenuItem;
    MenuPaste: TMenuItem;
    procedure FindDialogFind(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MenuCopyClick(Sender: TObject);
    procedure MenuCutClick(Sender: TObject);
    procedure MenuDecreaseFontClick(Sender: TObject);
    procedure MenuIncreaseFontClick(Sender: TObject);
    procedure MenuPasteClick(Sender: TObject);
    procedure MenuResetFontClick(Sender: TObject);
    procedure MenuShowGlobalVariablesClick(Sender: TObject);
    procedure MenuShowLocalVariablesClick(Sender: TObject);
    procedure PopUpClearAllClick(Sender: TObject);
    procedure PSScriptBreakpoint(Sender: TObject; const FileName: tbtstring;
      Position, Row, Col: Cardinal);
    function PSScriptNeedFile(Sender: TObject; const OrginFileName: tbtstring;
      var FileName, Output: tbtstring): Boolean;
    procedure ReplaceDialogFind(Sender: TObject);
    procedure ReplaceDialogReplace(Sender: TObject);
    procedure SynCompletionProposalCodeCompletion(var Value: string;
      SourceValue: string; var SourceStart, SourceEnd: TPoint;
      KeyChar: TUTF8Char; Shift: TShiftState);
    procedure SynCompletionProposalSearchPosition(var APosition: integer);
    procedure SynEditSTGutterClick(Sender: TObject; X, Y, Line: integer;
      mark: TSynEditMark);
    procedure SynEditSTMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure SynEditSTSpecialLineColors(Sender: TObject; Line: integer;
      var Special: boolean; var FG, BG: TColor);
    procedure SynEditSTStatusChange(Sender: TObject;
      Changes: TSynStatusChanges);
    procedure LBErrorsDblClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
    procedure MenuCompileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuSaveAsClick(Sender: TObject);
    procedure MenuUndoClick(Sender: TObject);
    procedure MenuRedoClick(Sender: TObject);
    procedure MenuAboutClick(Sender: TObject);
    procedure MenuFindClick(Sender: TObject);
    procedure MenuReplaceClick(Sender: TObject);
    procedure MenuCalculatorClick(Sender: TObject);
    procedure MenuSaveClick(Sender: TObject);
    procedure MenuNewClick(Sender: TObject);
    procedure MenuOpenClick(Sender: TObject);
    procedure MenuRunClick(Sender: TObject);
    procedure MenuStopClick(Sender: TObject);
    procedure MenuLocalHelpClick(Sender: TObject);
    procedure PSScript_Compile(Sender: TPSScript);
    procedure PSScript_Execute(Sender: TPSScript);
    procedure MenuTestClick(Sender: TObject);
    procedure MenuSetResetInspectorClick(Sender: TObject);
  private
    FuncList, InsertList: TStringList;
    TypeList: TStringList;

    procedure writeLn(S: string);
    procedure BuildRegFuncList(Sender: TPSScript);
    function ReadUDPData: string;
    procedure WriteUDPData(ToIP: string; ToPort: integer; s: string);
    procedure ProjectSave(FileName: string);
    function ProjectOpen(FileName: string): boolean;
    procedure BuildRegTypeList(Sender: TPSScript);
    procedure BuildRegTypeListEx(Sender: TPSPascalCompiler);
    function ReadUDPPacket: string;
    function GetUDPPacketCount: integer;
  public
    ProgCyclesCount: integer;
    ProgTime: double;
    //ScriptState : TScriptState;     //ProgRunning: boolean;
    ScriptStartTime, ScriptLastTime, ScriptTotalRunTime: LongWord;
    ProgramStartTime, ScriptCyclesCount: LongWord;
    SimLevel: Dword;
//    IOControl: TIOControl;
    compiled, LocalInspector: boolean;
    LocalInspectorLine: integer;
    SimTwoCloseRequested: boolean;

    procedure RunOnce;
    function Compile: boolean;
    procedure UpdateStatusLine;

    function ReadComPort: string;
    procedure WriteComPort(s: string);
  end;

type
  TProjectConfig = record
    FileName : string;
    //Modified: boolean; // Always compile
    //Author: string;
    //Comments: string;
  end;



var
  FEditor: TFEditor;
  Project: TProjectConfig;


implementation

//uses Viewer, ProjManage, Params, FastChart, uPSDebugger;
uses uPSDebugger, Sheets, Viewer, Utils, Params, uPSI_ODERobotsPublished, uPSI_PathFinder, uPSI_dynmatrix,
     uPSI_user_charts;

{$R *.lfm}

procedure TFEditor.SynEditSTMouseMove(Sender: TObject; Shift: TShiftState;  X, Y: Integer);
var ScreenCoord: TPoint;
    BufCoord: TPoint;
    //varname, varvalue: string;
    len: integer;
begin
  //ScreenCoord:=SynEditST.PixelsToRowColumn(point(X,Y));
  //BufCoord:= SynEditST.DisplayToBufferPos(ScreenCoord);

  //if (BufCoord.Line >= 1) and (BufCoord.Line <= SynEditST.Lines.Count) then  begin
  //  Len := Length(SynEditST.Lines[BufCoord.Line - 1]);
  //  if BufCoord.Char <= Len then begin

     { varname:=SynEditST.GetWordAtRowCol(BufCoord);
      varvalue:= GetStringValueFromAnyVarName(varname);

      if varvalue<>'' then
        StatusBar.Panels[4].text:=varname+': '+varvalue;}
   // end;
  //end else begin
  //    StatusBar.Panels[4].text:='';
  // end;
end;



procedure TFEditor.SynEditSTStatusChange(Sender: TObject;
  Changes: TSynStatusChanges);
begin
  if (scCaretX in Changes) or (scCaretY in Changes) then
    StatusBar.Panels[0].Text := format('%6d: %3d',[SynEditST.CaretY, SynEditST.CaretX]);

  if scInsertMode in Changes then begin
    if SynEditST.InsertMode then begin
      StatusBar.Panels[2].Text := 'Insert';
    end else begin
      StatusBar.Panels[2].Text := 'Overwrite';
    end;
  end;

  if scModified in Changes then begin
    if SynEditST.Modified then begin
      StatusBar.Panels[1].Text := 'Modified';
    end else begin
      StatusBar.Panels[1].Text := '';
    end;
  end;
  StatusBar.Invalidate;
end;


function FixLineColInErrorLine(const txt : string; var LC: TPoint; offset: integer): string;
var p1, p2, p3 : integer;
    s: string;
begin
  LC.x:=-1;
  LC.y:=-1;

  p1:= pos('(',txt);
  p2:= pos(':',txt);
  p3:= pos(')',txt);
  if (p1>0) and (p2>0) and (p3>0) then begin
    s:=copy(txt, p1+1, p2-(p1+1));
    LC.y:=strToIntdef(s,-1);
    s:=copy(txt,p2+1,p3-(p2+1));
    LC.x:=strToIntdef(s,-1);
    //result:=copy(txt,1,p1+6)+IntToStr(LC.y+offset)+', column: '+IntToStr(LC.x)+copy(txt,p3,length(txt));
    result:=copy(txt,p3+1,maxint);
  end;
end;


procedure TFEditor.LBErrorsDblClick(Sender: TObject);
var txt: string;
    LinCol: TPoint;
    i: integer;
begin
  i:= LBErrors.ItemIndex;
  if i<0 then exit;
  txt:=LBErrors.Items[i];
  FixLineColInErrorLine(txt, LinCol, 0);
  if (LinCol.x<>-1) and (LinCol.y<>-1) then begin
    SynEditST.caretX:=LinCol.x;
    SynEditST.caretY:=LinCol.y - SynMemoHeader.Lines.Count;
    //TODO SynEditST.UpdateCaret;
    SynEditST.setfocus;
  end;
end;



procedure TFEditor.writeLn(S: string);
begin
  while LBResult.Items.Count > 1000 do begin
    LBResult.Items.Delete(0);
  end;
  LBResult.Items.Add(S);
  LBResult.ItemIndex := LBResult.Items.Count-1;
end;


procedure TFEditor.RunOnce;
var i64_start, i64_end, i64_freq: int64;
    //Saved8087CW: Word;
    i: integer;
    var_name, txt: string;
    tp: TPSVariantIFC;
    FPUExceptionMask: TFPUExceptionMask;
begin
  if PSScript.Exec.Status <> isLoaded then exit;

  ScriptCyclesCount:=0;
  queryperformancecounter(i64_start);

  ClearExceptions(false);
  //Saved8087CW := Get8087CW;
  //Set8087CW(Default8087CW);

  FPUExceptionMask := GetExceptionMask;
  //FPUExceptionMask := [];
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  ////SetExceptionMask([exInvalidOp, exDenormalized, exOverflow, exUnderflow, exPrecision]);

  ProgTime := ProgCyclesCount * WorldODE.Ode_dt;
  LocalInspector := false;
  try
    if ProgCyclesCount = 0 then
      PSScript.ExecuteFunction([],'Initialize');
  except
    on E: Exception do begin //ErrorDialog(E.Message, E.HelpContext);
      FParams.RGControlBlock.itemindex := 0;
      LBErrors.Items.Add('Error while executing script: ' + E.Message);
      ClearExceptions(false);
      SetExceptionMask(FPUExceptionMask);
      //Set8087CW(Saved8087CW);
      exit;
    end;
  end;


  try
    if PSScript.Execute then begin

      if MenuShowGlobalVariables.Checked then begin
        LBVariables.Items.BeginUpdate;
        if (not MenuShowLocalVariables.Checked) or (not LocalInspector) then LBVariables.Clear;
        for i := 0 to PSScript.Exec.GlobalVarNames.Count -1 do begin
          tp := NewTPSVariantIFC(PSScript.Exec.GetGlobalVar(i), false);
          var_name := PSScript.Exec.GlobalVarNames[i];
          txt := format('%s: %s',[ var_name , PSVariantToString(tp,'')]);
          LBVariables.Items.Add(txt);
        end;
        LBVariables.Items.EndUpdate;
      end;
      //EditDebug.Text := txt;

    end else begin
      FParams.RGControlBlock.itemindex := 0;
    //  LBErrors.Items.clear;
      LBErrors.Items.Add('Error while executing script: ' + PSScript.ExecErrorToString);
      //PSScript.Exec.Clear;
    end;
  except
    on E: Exception do begin //ShowMessage(E.Message);
      FParams.RGControlBlock.itemindex := 0;
      LBErrors.Items.Add('Error while executing script: ' + E.Message);
      ClearExceptions(false);
      SetExceptionMask(FPUExceptionMask);
      //Set8087CW(Saved8087CW);
      exit;
    end;
  end;

  ClearExceptions(false);
  SetExceptionMask(FPUExceptionMask);
  //Set8087CW(Saved8087CW);


  PSScript.Exec.RaiseCurrentException;
  //StatusBar.Panels[4].Text := inttostr(PSScript.Exec.ExceptionPos);

  queryperformancecounter(i64_end);

  inc(ProgCyclesCount);

  QueryPerformanceFrequency(i64_freq);
  StatusBar.Panels[3].Text := format('%f',[1000*(i64_end-i64_start)/i64_freq]);

end;

function TFEditor.Compile: boolean;
var i: integer;
  i64_start, i64_end, i64_freq: int64;
begin

  SynEditPascal.Text := SynMemoHeader.Text + crlf + SynEditST.text + crlf + crlf + 'begin Control; end.';
  queryperformancecounter(i64_start);

  PSScript.Comp.Clear;
  PSScript.Script.Text := SynEditPascal.Text;
  Compiled := PSScript.Compile;

  LBErrors.Items.clear;
  LBErrors.Items.Add('Compile Messages:'+inttostr(PSScript.CompilerMessageCount));
  for i := 0 to PSScript.CompilerMessageCount -1 do begin
    LBErrors.Items.Add(PSScript.CompilerMessages[i].MessageToString);
  end;

  if not Compiled then begin
    PageControlBottom.ActivePageIndex:=1; // Select Errors Tab
    result := false;

  end else begin
    queryperformancecounter(i64_end);
    QueryPerformanceFrequency(i64_freq);
    //EditDebug.Text:=format('%f',[1000*(i64_end-i64_start)/i64_freq]);

    LBErrors.Items.clear;
    LBErrors.Items.Append(format('Compile OK in %f ms',[1000*(i64_end-i64_start)/i64_freq]));
    result := true;
  end;

end;


procedure TFEditor.MenuExitClick(Sender: TObject);
begin
  if SynEditST.Modified then begin
    if MessageDlg('Program was changed.'+crlf+
                  'Exit anyway?',
                  mtConfirmation , [mbOk,mbCancel], 0)
       = mrCancel then exit;
  end;
  FViewer.close;
end;

procedure TFEditor.MenuCompileClick(Sender: TObject);
begin
  FParams.RGControlBlock.ItemIndex := 0; // none
  if not compile then exit;
  SynEditST.Refresh;
end;

procedure TFEditor.FormCreate(Sender: TObject);
var Plugin, PathPlugin, MatrixPlugin, ChartPlugin: TPSPlugin;
begin
  IniPropStorage.IniFileName := GetIniFineName;
  //TabPascal.TabVisible:=false;
  FuncList := TStringList.Create;
  InsertList := TStringList.Create;
  TypeList := TStringList.Create;

  LocalInspectorLine := -1;

  MatrixPlugin := TPSImport_dynmatrix.Create(Self);
  TPSPluginItem(PSScript.Plugins.add).Plugin := MatrixPlugin;

  Plugin := TPSImport_ODERobotsPublished.Create(Self);
  TPSPluginItem(PSScript.Plugins.add).Plugin := Plugin;

  PathPlugin := TPSImport_PathFinder.Create(Self);
  TPSPluginItem(PSScript.Plugins.add).Plugin := PathPlugin;

  ChartPlugin := TPSImport_user_charts.Create(Self);
  TPSPluginItem(PSScript.Plugins.add).Plugin := ChartPlugin;


  try
    with PrintDialog do begin
      Collate := True;
      Copies := 1;
      Options := [poPageNums];
    end;
  except on E: Exception do begin
    showmessage(E.Message);
  end;
  end;

end;

procedure TFEditor.UpdateStatusLine;
begin
  SynEditSTStatusChange(FEditor,[scCaretX, scCaretY,scInsertMode,scModified]);
  StatusBar.Invalidate;
end;


procedure TFEditor.ProjectSave(FileName: string);
begin
  Project.FileName := ExtractFileName(FileName);

  SynEditST.Lines.SaveToFile(FileName);
  IniPropStorage.WriteString('LastProjectName', Project.FileName);
  MemoDescription.Lines.SaveToFile('info.txt');

  SynEditST.Modified:=False;
  caption := FormEditorCaption + Project.FileName;
  UpdateStatusLine;
end;


procedure TFEditor.MenuSaveAsClick(Sender: TObject);
var CurDir: string;
begin
  if SaveDialog.initialDir ='' then SaveDialog.initialDir := GetCurrentDir;
  SaveDialog.FileName := Project.FileName;
  CurDir := GetCurrentDir;
  if not SaveDialog.Execute then exit;
  SetCurrentDir(CurDir);
  ProjectSave(SaveDialog.FileName);
end;

procedure TFEditor.MenuUndoClick(Sender: TObject);
begin
  SynEditST.Undo;
end;

procedure TFEditor.MenuRedoClick(Sender: TObject);
begin
  SynEditST.Redo;
end;



procedure TFEditor.MenuAboutClick(Sender: TObject);
begin
  ShowMessage(SimTwoVersion + crlf + crlf+
              'Copyright (C) 2008-2009 Paulo Costa' + crlf + crlf+
              'Special thanks to:' + crlf+
              'José Luís Lima, José Alexandre Gonçalves,' + crlf+
              'Paulo Malheiros, Paulo Marques,' + crlf+
              'Armando Sousa, António Paulo Moreira and the' + crlf+
              'ODE, GLScene, SynEdit and PascalScript Teams,' + crlf+
              crlf+
              'Compiled: ' + DateToStr(FileDateToDateTime(FileAge(Application.ExeName))));
end;

procedure TFEditor.MenuFindClick(Sender: TObject);
begin
  FindDialog.Execute;
end;

procedure TFEditor.MenuReplaceClick(Sender: TObject);
begin
  ReplaceDialog.Execute;
end;

procedure TFEditor.MenuCalculatorClick(Sender: TObject);
//begin
//   OpenDocument('Calc.exe'); { *Converted from ShellExecute* }
//end;
var
  Process: TProcess;
  i: Integer;
begin
  Process := TProcess.Create(nil);
  try
    Process.InheritHandles := False;
    Process.Options := [];
    Process.ShowWindow := swoShow;

    // Copy default environment variables including DISPLAY variable for GUI application to work
    for i := 1 to GetEnvironmentVariableCount do
      Process.Environment.Add(GetEnvironmentString(I));

    Process.Executable := 'Calc.exe';
    Process.Execute;
  finally
    Process.Free;
  end;
end;


procedure TFEditor.MenuSaveClick(Sender: TObject);
var CurDir: string;
begin
  //FileName:= Project.FileName;
  if Project.FileName = 'Untitled' then begin
    if SaveDialog.initialDir ='' then SaveDialog.initialDir := GetCurrentDir;
    SaveDialog.FileName := Project.FileName;
    CurDir := GetCurrentDir;
    if not SaveDialog.Execute then exit;
    SetCurrentDir(CurDir);
    Project.FileName := ExtractFileName(SaveDialog.FileName);
  end;
  ProjectSave(Project.FileName);
end;

{
procedure TFEditor.FormSave(ProjMemIni : TMemIniFile);
begin
  SaveStringsToMemIni(ProjMemIni, 'Main','STText',SynEditST.lines);
  ProjMemIni.WriteInteger('Main','ActiveTab',PageControl.ActivePageIndex);
  ProjMemIni.WriteInteger('Main','MessagesHeight',max(PageControlBottom.Height,Splitter1.MinSize));  // corrige bug splitter nulo

  ProjMemIni.WriteString('Main','ProjectAuthor',Project.Author);
  ProjMemIni.WriteString('Main','ProjectComments',Project.Comments);
  ProjMemIni.WriteBool('Main','SaveOnRun', CBSaveOnRun.Checked);

  SaveFormGeometryToMemIni(ProjMemIni,FEditor);
end;

procedure TFEditor.FormLoad(ProjMemIni : TMemIniFile);
begin
  LoadStringsFromMemIni(ProjMemIni, 'Main','STText',SynEditST.lines);
  PageControl.ActivePageIndex := ProjMemIni.ReadInteger('Main','ActiveTab',PageControl.ActivePageIndex);
  PageControlBottom.Height := ProjMemIni.ReadInteger('Main','MessagesHeight',PageControlBottom.Height);

  Project.Author:= ProjMemIni.ReadString('Main','ProjectAuthor',Project.Author);
  Project.Comments := ProjMemIni.ReadString('Main','ProjectComments',Project.Comments);
  CBSaveOnRun.Checked := ProjMemIni.ReadBool('Main','SaveOnRun', CBSaveOnRun.Checked);

  LoadFormGeometryFromMemIni(ProjMemIni,FEditor);
end;
}

procedure TFEditor.MenuNewClick(Sender: TObject);
begin
  if SynEditST.Modified then begin
    if MessageDlg('Old project was changed.'+crlf+
                  'Start a new project ?',
                  mtConfirmation , [mbOk,mbCancel], 0)
       = mrCancel then exit;
  end;

//  ProjectNew;
  with Project do begin
    FileName:='Untitled';
  end;

//  EditAuthors.text:='';
//  EditDescription.Text:='';
  MemoDescription.Text:='';
  SynEditST.Modified:=False;

  UpdateStatusLine;
  caption := FormEditorCaption + Project.FileName;
end;

function TFEditor.ProjectOpen(FileName: string): boolean;
begin
  result := false;
  if not fileexists(FileName) then exit;
  SynEditST.Lines.LoadFromFile(FileName);

  Project.FileName := ExtractFileName(FileName);
  SynEditST.ReadOnly := false;
  SynEditST.Modified := false;
//  SynEditST.Modified := (GetCurrentDir + '\' + Project.FileName) <> OpenDialog.FileName;

  if FileExists('info.txt') then
    MemoDescription.Lines.LoadFromFile('info.txt');

  UpdateStatusLine;
  Caption := FormEditorCaption + ExtractFileName(Project.FileName);
  result := true;
end;


procedure TFEditor.MenuOpenClick(Sender: TObject);
var curdir: string;
begin
  if SynEditST.Modified then
    if MessageDlg('Project Modified.'+crlf+
                  'Loading will lose changes since last save.'+crlf+
                  'Open Project ?',
                  mtConfirmation , [mbOk,mbCancel], 0)
       = mrCancel then exit;

  curdir := GetCurrentDir;
  if OpenDialog.initialDir ='' then OpenDialog.initialDir := GetCurrentDir;
  if not OpenDialog.Execute then exit;
  SetCurrentDir(curdir);

{  if not fileexists(OpenDialog.FileName) then exit; // TODO: queixar ao utilizador
  SynEditST.Lines.LoadFromFile(OpenDialog.FileName);

  SynEditST.ReadOnly:=False;
  sname := ExtractFileName(OpenDialog.FileName);

  txt := GetCurrentDir + '\' + sname;
  SynEditST.Modified := txt <> OpenDialog.FileName;
//  SynEditST.Modified := GetCurrentDir + '\' + sname <> OpenDialog.FileName;

  with Project do begin
    fileName:= sname;
    //EditAuthors.text:=Author;
    //EditComments.Text:=Comments;
  end;

  UpdateStatusLine;
  Caption := FormEditorCaption+ExtractFileName(Project.FileName);}

  if not ProjectOpen(OpenDialog.FileName) then begin
    ShowMessage('Could not open File: ' + OpenDialog.FileName);
  end;
  //if not ProjectOpen(OpenDialog.FileName) then ProjectNew;
end;

procedure TFEditor.MenuRunClick(Sender: TObject);
begin
  if not compile then exit;
  if CBSaveOnRun.Checked then begin
    ProjectSave(Project.FileName);
  end;
  FParams.RGControlBlock.ItemIndex := 1; // script
  ProgCyclesCount := 0;
  SynEditST.Refresh;
end;

procedure TFEditor.MenuStopClick(Sender: TObject);
begin
  FParams.RGControlBlock.ItemIndex := 0; // none
  SynEditST.Refresh;
end;

procedure TFEditor.MenuLocalHelpClick(Sender: TObject);
begin
   OpenDocument('funclist.txt'); { *Converted from ShellExecute* }
end;

procedure TFEditor.BuildRegFuncList(Sender: TPSScript);
var i, j, typ: integer;
    SaveFunclist: TStringList;
    S: string;
begin
  FuncList.Clear;
  InsertList.Clear;
  for i := 0 to Sender.Comp.GetRegProcCount-1 do  begin
    //procedure Getdecl(decl : TPSParametersDecl; var T,v :string);
    s:= Sender.Comp.GetRegProc(i).OrgName;
    if (s <> '') and (s[1] <> '_') and (UpperCase(s) <> s) then begin
      if Sender.Comp.GetRegProc(i).Decl.Result <> nil then begin
        //s := 'function ' + s;
        typ := 0;
      end else begin
        //s := 'procedure ' + s;
        typ := 1;
      end;

      Insertlist.Add(s);

      s := s + '(';
      for j := 0 to Sender.Comp.GetRegProc(i).Decl.ParamCount - 1 do begin
        if j <> 0 then s := s + ' ';
        s := s + Sender.Comp.GetRegProc(i).Decl.Params[j].OrgName;
        if Sender.Comp.GetRegProc(i).Decl.Params[j].aType <> nil then begin
          s := s + ': ' + Sender.Comp.GetRegProc(i).Decl.Params[j].aType.OriginalName;
          if j <> Sender.Comp.GetRegProc(i).Decl.ParamCount - 1 then s := s + ';';
        end;
      end;
      if Sender.Comp.GetRegProc(i).Decl.Result <> nil then begin
        s := s + '): ' + Sender.Comp.GetRegProc(i).Decl.Result.OriginalName + ';';
      end else begin
        s := s + ');';
      end;
      Funclist.AddObject(S, TObject(typ));

    end;
  end;

  //Insertlist.Sort;
  //Funclist.Sort;

  for i := 0 to Funclist.Count -1 do begin
    if integer(Funclist.Objects[i]) = 1 then begin
      Funclist.Strings[i] := ' procedure ' + Funclist.Strings[i];
    end else begin
      Funclist.Strings[i] := ' function ' + Funclist.Strings[i];
    end;
  end;

  SaveFunclist := TStringList.Create;
  try
    SaveFunclist.AddStrings(Funclist);
    SaveFunclist.SaveToFile('funclist.txt');
  finally
    SaveFunclist.Free;
  end;
end;



procedure TFEditor.BuildRegTypeList(Sender: TPSScript);
var i, j: integer;
    SaveList: TStringList;
    S: string;
begin
  for i := 0 to Sender.Comp.GetTypeCount - 1 do  begin
    s := Sender.Comp.GetType(i).OriginalName;
    if (s <> '') {and (s[1] <> '_') and (UpperCase(s) <> s)} then begin

      for j := 0 to Sender.Comp.GetType(i).Attributes.Count - 1 do begin
        if j <> 0 then s := s + ' ';

        //s := s + Sender.Comp.GetType(i).Attributes.Items[j].AType.OrgName;
        if Sender.Comp.GetType(i).Attributes.Items[j].aType <> nil then begin
          s := s + ': ' + Sender.Comp.GetType(i).Attributes.Items[j].aType.OrgName;
          //if j <> Sender.Comp.GetRegProc(i).Decl.ParamCount - 1 then s := s + ';';
        end;
      end;
      TypeList.Add(s);
    end;
  end;

  TypeList.Sort;

  SaveList := TStringList.Create;
  try
    SaveList.AddStrings(TypeList);
    SaveList.SaveToFile('TypeList.txt');
  finally
    SaveList.Free;
  end;
end;


procedure TFEditor.BuildRegTypeListEx(Sender: TPSPascalCompiler);
var i, j: integer;
    SaveList: TStringList;
    S: string;
begin
  //showmessage(inttostr(Sender.FindClass('TTIMER').Items[0].));
  //exit;

  for i := 0 to Sender.GetTypeCount - 1 do  begin
    //procedure Getdecl(decl : TPSParametersDecl; var T,v :string);
    s := Sender.GetType(i).OriginalName;
    if (s <> '') {and (s[1] <> '_') and (UpperCase(s) <> s)} then begin
      {if Sender.Comp.GetType(i). Decl.Result <> nil then begin
        //s := 'function ' + s;
        typ := 0;
      end else begin
        //s := 'procedure ' + s;
        typ := 1;
      end;}

      //TypeList.Add(s); TPSCompileTimeClass
      //Sender.Comp.GetType(i).Attributes.Items[j].
      s := s + '(' + inttostr(Sender.GetType(i).Attributes.Count);

      for j := 0 to Sender.GetType(i).Attributes.Count - 1 do begin
        if j <> 0 then s := s + ' ';

        //s := s + Sender.Comp.GetType(i).Attributes.Items[j].AType.OrgName;
        if Sender.GetType(i).Attributes.Items[j].aType <> nil then begin
          s := s + ': ' + Sender.GetType(i).Attributes.Items[j].aType.OrgName;
          //if j <> Sender.Comp.GetRegProc(i).Decl.ParamCount - 1 then s := s + ';';
        end;
      end;
      {if Sender.Comp.GetRegProc(i).Decl.Result <> nil then begin
        s := s + '): ' + Sender.Comp.GetRegProc(i).Decl.Result.OriginalName + ';';
      end else begin
        s := s + ');';
      end;
      Funclist.AddObject(S, TObject(typ));}
      TypeList.Add(s);
    end;
  end;

  TypeList.Sort;

{  for i := 0 to Funclist.Count -1 do begin
    if integer(Funclist.Objects[i]) = 1 then begin
      Funclist.Strings[i] := ' procedure ' + Funclist.Strings[i];
    end else begin
      Funclist.Strings[i] := ' function ' + Funclist.Strings[i];
    end;
  end;}

  SaveList := TStringList.Create;
  try
    SaveList.AddStrings(TypeList);
    SaveList.SaveToFile('TypeList.txt');
  finally
    SaveList.Free;
  end;
end;



function FillTypes(Sender: TPSPascalCompiler): Boolean;
begin
  FEditor.BuildRegTypeListEx(Sender);
  result := true;
end;

function random01: double;
begin
  result := random;
end;

procedure CloseSimTwo;
begin
  FEditor.SimTwoCloseRequested := true;
end;

function ScriptPeriod: double;
begin
  result := WorldODE.DecPeriod;
end;

function SqrD(X: double): double;
begin
  result := Sqr(X);
end;

function ExpD(X: double): double;
begin
  result := exp(X);
end;

function LnD(X: double): double;
begin
  result := ln(X);
end;


procedure TFEditor.PSScript_Compile(Sender: TPSScript);
var i: integer;
    s: string;
begin
  Sender.AddFunction(@arcsin, 'function arcsin(x: Extended): Extended');
  Sender.AddFunction(@arccos, 'function arccos(x: Extended): Extended');
  Sender.AddFunction(@tan, 'function tan(x: Extended): Extended');
  Sender.AddFunction(@ATan2, 'function ATan2(y,x: double): double');
  Sender.AddFunction(@ACos2, 'function ACos2(y,x: double): double');
  Sender.AddFunction(@ASin2, 'function ASin2(y,x: double): double');

  Sender.AddFunction(@Power, 'function Power(const Base, Exponent: Extended): Extended');
  Sender.AddFunction(@Log10, 'function Log10(const X: Extended): Extended');
  Sender.AddFunction(@LogN, 'function LogN(const Base, X: Extended): Extended');
  Sender.AddFunction(@SqrD, 'function Sqr(X: double): double');

  Sender.AddFunction(@ExpD, 'function Exp(X: double): double');
  Sender.AddFunction(@LnD, 'function Ln(X: double): double');


  Sender.AddFunction(@DiffAngle, 'function DiffAngle(a1,a2: double): double;');
  Sender.AddFunction(@Dist, 'function Dist(x,y: double): double');
  Sender.AddFunction(@Sign, 'function Sign(a: double): double');
  Sender.AddFunction(@Sat, 'function Sat(a,limit: double): double');
  Sender.AddFunction(@NormalizeAngle, 'function NormalizeAngle(ang: double): double');
  Sender.AddFunction(@TranslateAndRotate, 'function TranslateAndRotate(var rx,ry: double; px,py,tx,ty,teta: double): double');
  Sender.AddFunction(@RotateAndTranslate, 'function RotateAndTranslate(var rx,ry: double; px,py,tx,ty,teta: double): double');
  Sender.AddFunction(@RotateAroundPoint, 'function RotateAroundPoint(var rx,ry: double; px,py,cx,cy,teta: double): double');
  Sender.AddFunction(@RandG, 'function RandG(Mean, StdDev: Extended): Extended;');
  Sender.AddFunction(@random01, 'function random01: double;');
  Sender.AddFunction(@Randomize, 'procedure Randomize;');
  Sender.AddFunction(@BiLinInterp, 'function BiLinInterp(Surf: matrix; xmin, xmax, ymin, ymax, x,y: double): double;');

  //Sender.AddFunction(@IntToHex, 'function IntToHex(Value: Int64; Digits: Integer): string;');
  Sender.AddFunction(@IntToHex, 'function IntToHex(Value: integer; Digits: Integer): string;');

  Sender.AddMethod(Self, @TFEditor.Writeln, 'procedure WriteLn(S: string)');
//  Sender.AddMethod(Self, @TFEditor.myformat, 'function Format(const sFormat: string; const Args: array of const): string;');
  Sender.AddFunction(@format, 'function Format(const sFormat: string; const Args: array of const): string;');
  Sender.AddMethod(Self, @TFEditor.ReadComPort, 'function ReadComPort: string;');
  Sender.AddMethod(Self, @TFEditor.WriteComPort, 'procedure WriteComPort(s: string);');

  Sender.AddMethod(Self, @TFEditor.ReadUDPData, 'function ReadUDPData: string;');
  Sender.AddMethod(Self, @TFEditor.WriteUDPData, 'procedure WriteUDPData(ToIP: string; ToPort: integer; s: string);');

  Sender.AddMethod(Self, @TFEditor.ReadUDPPacket, 'function ReadUDPPacket: string;');
  Sender.AddMethod(Self, @TFEditor.GetUDPPacketCount, 'function GetUDPPacketCount: integer;');

  Sender.AddFunction(@SetRCValue, 'procedure SetRCValue(r, c: integer; s: string);');
  Sender.AddFunction(@GetRCValue, 'function GetRCValue(r, c: integer): double;');
  Sender.AddFunction(@GetRCText, 'function GetRCText(r, c: integer): string;');

  Sender.AddFunction(@RCButtonPressed, 'function RCButtonPressed(r, c: integer): boolean;');
  Sender.AddFunction(@RangeToMatrix, 'function RangeToMatrix(r, c, rows, cols: integer): Matrix;');
  Sender.AddFunction(@MatrixToRange, 'procedure MatrixToRange(r, c: integer; const M: Matrix);');
  Sender.AddFunction(@MatrixToRangeF, 'procedure MatrixToRangeF(r, c: integer; const M: Matrix; FormatString: string);');

  Sender.AddFunction(@ClearButtons, 'procedure ClearButtons;');

  Sender.AddFunction(@RefreshSheets, 'procedure RefreshSheets;');

  Sender.AddFunction(@CloseSimTwo, 'procedure CloseSimTwo;');
  Sender.AddFunction(@ScriptPeriod, 'function ScriptPeriod: double;');

  Sender.AddFunction(@Now, 'function Now: double;');
  Sender.AddFunction(@GetTickCount, 'function GetTickCount: LongWord;');

  Sender.AddFunction(@SetRCBackColor, 'procedure SetRCBackColor(r, c: integer; newColor: TColor);');
  Sender.AddFunction(@RGBToColor, 'function RGBToColor(R, G, B: Byte): TColor; ');


  //RLan Functions
  Sender.AddFunction(@Test, 'procedure Test(var B: double);');

  Sender.comp.AddTypeS('TUDPBuffer', 'record data: array[0..1499] of byte; MessSize: integer; ReadDisp: integer;  end').ExportName := true;
  Sender.AddFunction(@ClearUDPBuffer, 'procedure ClearUDPBuffer(var Buf: TUDPBuffer);');

  //Sender.AddFunction(@NetPutBuffer, 'procedure NetPutBuffer(var Buf: TUDPBuffer; var data; size_it: integer);');
  Sender.AddFunction(@NetBufferSeek, 'procedure NetBufferSeek(var Buf: TUDPBuffer; disp: integer);');
  //Sender.AddFunction(@NetGetBuffer, 'procedure NetGetBuffer(var Buf: TUDPBuffer; var data; size_it: integer);');
  Sender.AddFunction(@NetStringBuffer, 'function NetStringBuffer(var Buf: TUDPBuffer): string;');

  Sender.AddFunction(@NetPutByte, 'procedure NetPutByte(var Buf: TUDPBuffer; value: byte);');
  Sender.AddFunction(@NetPutWord, 'procedure NetPutWord(var Buf: TUDPBuffer; value: word);');
  Sender.AddFunction(@NetPutShort, 'procedure NetPutShort(var Buf: TUDPBuffer; value: SmallInt);');
  Sender.AddFunction(@NetPutInt, 'procedure NetPutInt(var Buf: TUDPBuffer; value: integer);');
  Sender.AddFunction(@NetPutFloat, 'procedure NetPutFloat(var Buf: TUDPBuffer; value: single);');
  Sender.AddFunction(@NetPutString, 'procedure NetPutString(var Buf: TUDPBuffer; str: string);');
  Sender.AddFunction(@NetPutAngle, 'procedure NetPutAngle(var Buf: TUDPBuffer; value: double);');

  Sender.AddFunction(@NetPeekByte, 'function NetPeekByte(var Buf: TUDPBuffer): byte;');
  Sender.AddFunction(@NetGetByte, 'function NetGetByte(var Buf: TUDPBuffer): byte;');
  Sender.AddFunction(@NetGetWord, 'function NetGetWord(var Buf: TUDPBuffer): word;');
  Sender.AddFunction(@NetGetShort, 'function NetGetShort(var Buf: TUDPBuffer): SmallInt;');
  Sender.AddFunction(@NetGetInt, 'function NetGetInt(var Buf: TUDPBuffer): integer;');
  Sender.AddFunction(@NetGetFloat, 'function NetGetFloat(var Buf: TUDPBuffer): single;');
  Sender.AddFunction(@NetGetString, 'function NetGetString(var Buf: TUDPBuffer): string;');
  Sender.AddFunction(@NetGetAngle, 'function NetGetAngle(var Buf: TUDPBuffer): double;');

  Sender.AddFunction(@getModbusCoil, 'function getModbusCoil(bit_addr: integer): boolean;');
  Sender.AddFunction(@getModbusInput, 'function getModbusInput(bit_addr: integer): boolean;');
  Sender.AddFunction(@setModbusCoil, 'procedure setModbusCoil(bit_addr: integer; new_state: boolean);');
  Sender.AddFunction(@setModbusInput, 'procedure setModbusInput(bit_addr: integer; new_state: boolean);');

  Sender.AddRegisteredPTRVariable('Time', 'Double');
  Sender.AddRegisteredPTRVariable('UDPDataRead', 'TMemoryStream');
  Sender.AddRegisteredPTRVariable('HUDStrings', 'TStringList');

  Sender.AddRegisteredPTRVariable('RandSeed', 'LongInt');

{  Sender.comp.AddTypeS('TMotVoltArray', 'array[1..4] of integer').ExportName := true;
  Sender.AddRegisteredPTRVariable('U', 'TMotVoltArray');

  Sender.AddRegisteredPTRVariable('ScannerAngle', 'Double');

  Sender.comp.AddTypeS('TOdosArray', 'array[1..4] of integer').ExportName := true;
  Sender.AddRegisteredPTRVariable('Odos', 'TOdosArray');

  Sender.comp.AddTypeS('TScanner', 'array[1..64] of byte').ExportName := true;
  Sender.AddRegisteredPTRVariable('Scanner', 'TScanner');
}

{  for i := 1 to 8 do begin
    Sender.AddRegisteredPTRVariable('IO'+inttostr(i), 'TCheckBox');
  end;
}
  SynCompletionProposal.ItemList.BeginUpdate;
  SynCompletionProposal.ItemList.Clear;

  //SynCompletionProposal.InsertList.BeginUpdate;
  //SynCompletionProposal.InsertList.Clear;

  for i := 0 to PSScript.Exec.GlobalVarNames.Count - 1 do begin
    s:= PSScript.Exec.GlobalVarNames.Items[i];
    if s <> '' then begin
      SynCompletionProposal.ItemList.Add(s);
      //SynCompletionProposal.InsertList.Add(s);
    end;
  end;

//  SynCompletionProposal.ItemList.Add('test_proc(var x: integer)');
//  SynCompletionProposal.InsertList.Add('test_proc()');

  BuildRegFuncList(Sender);
  SynCompletionProposal.ItemList.AddStrings(FuncList);
  //SynCompletionProposal.InsertList.AddStrings(InsertList);

  SynCompletionProposal.ItemList.EndUpdate;
  //SynCompletionProposal.InsertList.EndUpdate;

  //sender.Comp.OnBeforeCleanup := @FillTypes;
  BuildRegTypeList(Sender);
end;


procedure TFEditor.PSScript_Execute(Sender: TPSScript);
//var pScriptArray: PIFTypeRec;
//    i: integer;
//    Comp: TComponent;
begin
  //TmpSystemState := SystemState;

//  pScriptArray := PSScript.Exec.GetTypeNo(PSScript.Exec.GetType('TMotVoltArray'));
//  PSScript.SetPointerToData('U', @(RemControl.U), pScriptArray);

//  pScriptArray := PSScript.Exec.GetTypeNo(PSScript.Exec.GetType('TOdosArray'));
//  PSScript.SetPointerToData('Odos', @(RemState.robot.odos), pScriptArray);

//  pScriptArray := PSScript.Exec.GetTypeNo(PSScript.Exec.GetType('TScanner'));
//  PSScript.SetPointerToData('Scanner', @(RemState.robot.Scanner), pScriptArray);

  PSScript.SetPointerToData('Time', @(ProgTime), PSScript.FindBaseType(btDouble));
  PSScript.SetPointerToData('UDPDataRead', @(FParams.UDPGenData), PSScript.FindNamedType('TMemoryStream'));
  PSScript.SetPointerToData('HUDStrings', @(FViewer.HUDStrings), PSScript.FindNamedType('TStringList'));
  PSScript.SetPointerToData('RandSeed', @RandSeed, PSScript.FindBaseType(btS32));

//  PSScript.SetPointerToData('ScannerAngle', @(RemState.Robot.ScannerAngle), PSScript.FindBaseType(btDouble));

{  PSScript.SetPointerToData('IO1', @(FParams.CBIO1), PSScript.FindNamedType('TCheckBox'));
  PSScript.SetPointerToData('IO2', @(FParams.CBIO2), PSScript.FindNamedType('TCheckBox'));
  PSScript.SetPointerToData('IO3', @(FParams.CBIO3), PSScript.FindNamedType('TCheckBox'));
  PSScript.SetPointerToData('IO4', @(FParams.CBIO4), PSScript.FindNamedType('TCheckBox'));
  PSScript.SetPointerToData('IO5', @(FParams.CBIO5), PSScript.FindNamedType('TCheckBox'));
  PSScript.SetPointerToData('IO6', @(FParams.CBIO6), PSScript.FindNamedType('TCheckBox'));
  PSScript.SetPointerToData('IO7', @(FParams.CBIO7), PSScript.FindNamedType('TCheckBox'));
  PSScript.SetPointerToData('IO8', @(FParams.CBIO8), PSScript.FindNamedType('TCheckBox'));}
 // exit;
{  for i := 1 to 1 do begin
    Comp := Fmain.FindComponent('CBIO'+inttostr(i));
    if Comp = nil then continue;
    PSScript.SetPointerToData('IO'+inttostr(i), comp, PSScript.FindNamedType('TCheckBox'));
  end;}
end;

procedure TFEditor.MenuTestClick(Sender: TObject);
begin
//  PSScript.Exec.ExceptionCode
  LBErrors.Items.Append('Status: ' + PSScript.About);
end;

procedure TFEditor.MenuSetResetInspectorClick(Sender: TObject);
var Line: Longint;
begin
  //PSScript.Exec.DebugEnabled := true;
  if LocalInspectorLine <> SynEditST.CaretY then begin
    LocalInspectorLine := SynEditST.CaretY;
    Line := SynEditST.CaretY + SynMemoHeader.Lines.Count;
    PSScript.ClearBreakPoints;
    PSScript.SetBreakPoint(PSScript.MainFileName, Line);
  end else begin
    LocalInspectorLine := -1;
    PSScript.ClearBreakPoints;
  end;
  SynEditST.Refresh;
end;

procedure TFEditor.SynEditSTGutterClick(Sender: TObject; X, Y, Line: integer;
  mark: TSynEditMark);
var RealLine: Longint;
begin
  //PSScript.Exec.DebugEnabled := true;
  if LocalInspectorLine <> SynEditST.CaretY then begin
    LocalInspectorLine := SynEditST.CaretY;
    RealLine := SynEditST.CaretY + SynMemoHeader.Lines.Count;
    PSScript.ClearBreakPoints;
    PSScript.SetBreakPoint(PSScript.MainFileName, RealLine);
  end else begin
    LocalInspectorLine := -1;
    PSScript.ClearBreakPoints;
  end;
  SynEditST.Refresh;
end;

function TFEditor.PSScriptNeedFile(Sender: TObject;
  const OrginFileName: tbtstring; var FileName, Output: tbtstring): Boolean;
//begin

//end;



//function TFEditor.PSScriptNeedFile(Sender: TObject; const OrginFileName: String; var FileName, Output: String): Boolean;
var path: string;
    f: TFileStream;
begin
  //if aFile <> '' then
  //  Path := ExtractFilePath(aFile)
  //else


  Path := ExtractFilePath(ParamStr(0));
  Path := Path + FileName;
  try
    F := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);
  except
    Result := false;
    exit;
  end;
  try
    SetLength(Output, f.Size);
    f.Read(Output[1], Length(Output));
  finally
    f.Free;
  end;
  Result := True;
end;

procedure TFEditor.ReplaceDialogFind(Sender: TObject);
var k: integer;
    opt: TSynSearchOptions;
begin
  with Sender as TReplaceDialog do begin
    if frEntireScope in  Options then begin
      opt := [ssoEntireScope];
    end else begin
      opt := [];//[ssoFindContinue];
    end;

    if frWholeWord in Options then
      opt := opt + [ssoWholeWord];

    k := SynEditST.SearchReplace(FindText, '', opt);
  end;
end;

{  TSynSearchOption =
    ( ssoMatchCase, ssoWholeWord,
      ssoBackwards,
      ssoEntireScope, ssoSelectedOnly,
      ssoReplace, ssoReplaceAll,
      ssoPrompt,
      ssoSearchInReplacement,    // continue search-replace in replacement (with ssoReplaceAll) // replace recursive
      ssoRegExpr, ssoRegExprMultiLine,
      ssoFindContinue      // Assume the current selection is the last match, and start search behind selection
                           // (before if ssoBackward) // Default is to start at caret (Only SearchReplace / SearchReplaceEx has start/end param)
    );

    TFindOption = (frDown, frFindNext, frHideMatchCase, frHideWholeWord,
                   frHideUpDown, frMatchCase, frDisableMatchCase, frDisableUpDown,
                   frDisableWholeWord, frReplace, frReplaceAll, frWholeWord, frShowHelp,
                   frEntireScope, frHideEntireScope, frPromptOnReplace, frHidePromptOnReplace,
                   frButtonsAtBottom);
    TFindOptions = set of TFindOption;
    }

procedure TFEditor.ReplaceDialogReplace(Sender: TObject);
var k: integer;
    opt: TSynSearchOptions;
    rp: TReplaceDialog;
begin
  rp := Sender as TReplaceDialog;
  with rp do begin
    if frEntireScope in  Options then begin
      opt := [ssoEntireScope];
    end else begin
      opt := [];//[ssoFindContinue];
    end;

    if frWholeWord in Options then
      opt := opt + [ssoWholeWord];

    if frReplace in Options then
      opt := opt + [ssoReplace];
    if frReplaceAll in Options then
      opt := opt + [ssoReplaceAll];
    k := SynEditST.SearchReplace(FindText, ReplaceText, opt);
    //k := SynEditST.SearchReplace('begi', 'BEGIN', opt);

    //if k>=0 then
    //  TSynEdit1.SetFocus()
    //else
    //  Beep();
  end;
end;

procedure TFEditor.SynCompletionProposalCodeCompletion(var Value: string;
  SourceValue: string; var SourceStart, SourceEnd: TPoint; KeyChar: TUTF8Char;
  Shift: TShiftState);
var i: integer;
begin
  // Find the stripped keyword
  for i := 0 to FuncList.Count - 1 do begin
    if pos(lowercase(value), lowercase(FuncList[i])) <> 0 then begin
      value := InsertList[i];
      break;
    end;
  end;
end;

procedure TFEditor.SynCompletionProposalSearchPosition(var APosition: integer);
var i: integer;
begin
  // Rebuild the list only with matching keywords
  SynCompletionProposal.ItemList.Clear;
  for i := 0 to FuncList.Count - 1 do begin
    if pos(lowercase(SynCompletionProposal.CurrentString), lowercase(FuncList[i])) <> 0 then
      SynCompletionProposal.ItemList.Add(FuncList[i]);
  end;
  APosition := 0;  //??
end;

procedure TFEditor.PSScriptBreakpoint(Sender: TObject;
  const FileName: tbtstring; Position, Row, Col: Cardinal);
//  showmessage('Break Point' + format('%d,%d',[Row,col]));
//  PSScript.Exec.Pause;
var i: integer;
    txt: string;
    tp: TPSVariantIFC;
begin
  if MenuShowLocalVariables.Checked then begin
    LocalInspector := true;
    LBVariables.Items.BeginUpdate;
    LBVariables.Clear;
    for i := 0 to PSScript.Exec.CurrentProcVars.Count -1 do begin
      tp := NewTPSVariantIFC(PSScript.Exec.GetProcVar(i), false);
      //PSVariantToString
      txt := format('%s: %s',[ PSScript.Exec.CurrentProcVars[i] , PSVariantToString(tp,'')]);
      LBVariables.Items.Add(txt);
    end;
    LBVariables.Items.EndUpdate;
  end;
  //EditDebug.Text := inttostr(PSScript.Exec.CurrentProcVars.Count);
end;

procedure TFEditor.MenuShowLocalVariablesClick(Sender: TObject);
begin
  MenuShowLocalVariables.Checked := not MenuShowLocalVariables.Checked;
  LBVariables.Clear;
end;

procedure TFEditor.MenuShowGlobalVariablesClick(Sender: TObject);
begin
  MenuShowGlobalVariables.Checked := not MenuShowGlobalVariables.Checked;
  LBVariables.Clear;
end;

procedure TFEditor.SynEditSTSpecialLineColors(Sender: TObject;
  Line: Integer; var Special: Boolean; var FG, BG: TColor);
begin
  if (Line = LocalInspectorLine) and (FParams.RGControlBlock.ItemIndex = 1) then begin
    Special := True;
    BG := cllime;
    FG := clRed;
  end;
end;

procedure TFEditor.FormShow(Sender: TObject);
var //i: integer;
    s: string;
begin
  s := IniPropStorage.ReadString('LastProjectName','');
  if not ProjectOpen(s) then begin
    Project.FileName := 'Untitled';
    UpdateStatusLine;
    Caption := FormEditorCaption + ExtractFileName(Project.FileName);
  end;

  compile;

{  SynCompletionProposal.ItemList.BeginUpdate;
  SynCompletionProposal.ItemList.Clear;
  for i := 0 to PSScript.Exec.GlobalVarNames.Count - 1 do begin
    s:= PSScript.Exec.GlobalVarNames.Items[i];
    if s <> '' then SynCompletionProposal.ItemList.Add(s);
  end;
  for i := 0 to PSScript.Exec.ProcNames.Count - 1 do begin
    s:= PSScript.Exec.ProcNames.Items[i];
    if s <> '' then SynCompletionProposal.ItemList.Add(s);
  end;
  //SynCompletionProposal.ItemList.Add('Sek');
  SynCompletionProposal.ItemList.EndUpdate;}
end;

procedure TFEditor.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if SynEditST.Modified then begin
    if MessageDlg('Program was changed.'+crlf+
                  'Exit anyway?',
                  mtConfirmation , [mbOk,mbCancel], 0)
       = mrCancel then CanClose:=false;
  end;
end;

procedure TFEditor.PopUpClearAllClick(Sender: TObject);
begin
  if PopupMenuOutput.PopupComponent is TListBox then begin
    TListBox(PopupMenuOutput.PopupComponent).Items.Clear;
  end;
end;

procedure TFEditor.FindDialogFind(Sender: TObject);
var SynSearchOptions: TSynSearchOptions;
begin
  //TODO: SynEditST.SearchEngine := SynEditSearch;
  SynSearchOptions := [];
  if not (frDown in FindDialog.Options) then
    SynSearchOptions := SynSearchOptions + [ssoBackwards];
  if (frWholeWord in FindDialog.Options) then
    SynSearchOptions := SynSearchOptions + [ssoWholeWord];
  if (frMatchCase in FindDialog.Options) then
    SynSearchOptions := SynSearchOptions + [ssoMatchCase];
  SynEditST.SearchReplace(FindDialog.FindText, '', SynSearchOptions)

//  TFindOption = (frDown, frFindNext, frHideMatchCase, frHideWholeWord,
//    frHideUpDown, frMatchCase, frDisableMatchCase, frDisableUpDown,
//    frDisableWholeWord, frReplace, frReplaceAll, frWholeWord, frShowHelp);

//  TSynSearchOption = (ssoMatchCase, ssoWholeWord, ssoBackwards,
//    ssoEntireScope, ssoSelectedOnly, ssoReplace, ssoReplaceAll, ssoPrompt);

//  FindDialog.Options
end;

procedure TFEditor.WriteComPort(s: string);
begin
  if not FParams.SerialCom.Active then exit;
  FParams.SerialCom.WriteData(s);
end;

function TFEditor.ReadComPort: string;
begin
  result := FParams.SerialData;
  FParams.SerialData := '';
end;

procedure TFEditor.WriteUDPData(ToIP: string; ToPort: integer; s: string);
begin
  //if not (Fparams.UDPGeneric.Connected and Fparams.UDPGeneric.Active)then exit;
  Fparams.UDPGeneric.SendMessage(s, ToIP + ':' + IntToStr(ToPort));
end;

function TFEditor.ReadUDPData: string;
begin
  result := '';
  with FParams do begin
    UDPGenData.Position := 0;
    SetLength(result, UDPGenData.Size);
    UDPGenData.ReadBuffer(Pointer(result)^, UDPGenData.Size);
    UDPGenData.Clear;
  end;
end;


function TFEditor.ReadUDPPacket: string;
begin
  result := '';
  with FParams do begin
    if UDPGenPackets.Count > 0 then begin
      result := UDPGenPackets.strings[0];
      UDPGenPackets.Delete(0);
    end;
  end;
end;

function TFEditor.GetUDPPacketCount: integer;
begin
  result := FParams.UDPGenPackets.Count;
end;

procedure TFEditor.FormDestroy(Sender: TObject);
begin
  TypeList.Free;
  FuncList.Free;
  InsertList.Free;
end;

procedure CopySelectedToClipboard(LB: TListBox);
var s: string;
    i: integer;
begin
  s := '';
  for i := 0 to LB.Count - 1 do begin
    if LB.Selected[i] then begin
      s := s + LB.Items[i] + #$0D + #$0A;
    end;
  end;
  clipboard.AsText := s;
end;

procedure TFEditor.MenuCopyClick(Sender: TObject);
begin
  CopySelectedToClipboard(LBResult);
end;

procedure TFEditor.MenuCutClick(Sender: TObject);
begin
  CopySelectedToClipboard(LBResult);
  LBResult.DeleteSelected;
end;

procedure TFEditor.MenuDecreaseFontClick(Sender: TObject);
begin
  if SynEditST.Font.Size >= 8 then
    SynEditST.Font.Size := SynEditST.Font.Size - 1;
end;

procedure TFEditor.MenuIncreaseFontClick(Sender: TObject);
begin
  if SynEditST.Font.Size <= 24 then
    SynEditST.Font.Size := SynEditST.Font.Size + 1;
end;

procedure TFEditor.MenuPasteClick(Sender: TObject);
begin
  SynEditST.Refresh;
end;

procedure TFEditor.MenuResetFontClick(Sender: TObject);
begin
  SynEditST.Font.Size := 8;
end;


end.




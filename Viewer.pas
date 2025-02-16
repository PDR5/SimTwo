unit Viewer;

{$MODE Delphi}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, GLScene, GLObjects, {GLMisc,} GLCadencer, ODEImport,
  GLShadowPlane, GLVectorGeometry, GLGeomObjects, ExtCtrls, ComCtrls,
  GLWindowsFont, keyboard, GLTexture, math, GLSpaceText, Remote,
  GLShadowVolume, GLSkydome, GLGraph, OmniXML, OmniXMLUtils,  ODERobots,
  ProjConfig, GLHUDObjects, Menus, IniPropStorage, GLVectorFileObjects,
  GLFireFX, GlGraphics, OpenGL1x, SimpleParser, GLBitmapFont,
  GLMesh, GLWaterPlane, glzbuffer, GLLCLViewer, GLMaterial, GLColor,
  GLKeyboard;

type
  TRemoteImage = packed record
    id, Number, size, NumPackets, ActPacket: integer;
    data: array[0..511] of byte;
  end;

  TRGBfloat = record
    r, g, b: single;
  end;

  TSolidDef = record
    ID: string;
    sizeX, sizeY, SizeZ, radius: double;
    posX, posY, posZ: double;
    angX, angY, angZ: double;  // XYZ seq
  end;

  TSolidXMLProperties = record
    radius, sizeX, sizeY, sizeZ, posX, posY, posZ, angX, angY, angZ, mass: double;
    I11, I22, I33, I12, I13, I23: double;
    BuoyantMass, Drag, StokesDrag, RollDrag: double;
    BuoyanceX, BuoyanceY, BuoyanceZ: double;
    colorR, colorG, colorB: double;
    ID: string;
    descr: string;
    TextureName: string;
    TextureScale: double;
    MeshFile, MeshShadowFile: string;
    MeshScale: double;
    MeshCastsShadows: boolean;
    Surf: TdSurfaceParameters;
    dMass: TdMass;
    MatterProps: TMatterProperties;
    hasCanvas, isLiquid: boolean;
    CanvasWidth, CanvasHeigth: integer;
    MotherSolidId: string;
    SolidIdx: integer;
    NewPos, ActPos: TdVector3;
    GravityMode: integer;
    transparency: double;
end;

//Physic World ODE
type
  TWorld_ODE = class
    //SampleCount: integer;
    Ode_dt, TimeFactor: double;
    Ode_ERP, Ode_CFM: double;
    Ode_QuickStepIters: integer;
    OdeScene: TGLBaseSceneObject;
    MaxWorldX, MaxWorldY, MinWorldX, MinWorldY: double;
    world: PdxWorld;
    space: PdxSpace;
    contactgroup: TdJointGroupID;
    default_n_mu: double;
    AirDensity: double;
    WindSpeed: TdVector3;

    Walls: TSolidList;
    Environment: TSolid;
    Robots: TRobotList;
    Obstacles: TSolidList;
    Things: TSolidList;
    Sensors: TSensorList;

    OldPick : TGLCustomSceneObject;
    PickSolid: TSolid;
    PickJoint: TdJointID;
    PickPoint, TargetPickPoint: TVector;
    PickDist, PickLinDamping, PickAngularDamping: double;
    TestBody: TSolid;

    ground_box : PdxGeom;
    ground_box2 : PdxGeom;

    ODEEnable : boolean;
    physTime : double;
    SecondsCount, DecPeriod: double;
    Ode_UseQuickStep: boolean;

    XMLFiles, XMLErrors: TStringList;
    Parser: TSimpleParser;

    MemCameraSolid: TSolid;
    RemoteImage: TRemoteImage;
    RemoteImageDecimation: integer;

    destructor destroy; override;
    constructor create;
    procedure WorldUpdate;
  private
    //procedure CreateSubGeomBox(var body: PdxBody; var geom: PdxGeom; xsize, ysize, zsize, x, y, z: double);
    //procedure CreateGlBox(var GLCube: TGLCube; var geom: PdxGeom);

    procedure CreateHingeJoint(var Link: TSolidLink; Solid1, Solid2: TSolid;
      anchor_x, anchor_y, anchor_z, axis_x, axis_y, axis_z: double);
    procedure SetHingeLimits(var Link: TSolidLink; LimitMin, LimitMax: double);

    procedure CreateBoxObstacle(var Obstacle: TSolid; sizeX, sizeY, sizeZ, posX, posY, posZ: double);

    procedure CreateShellBox(var Solid: TSolid; motherbody: PdxBody; posX, posY, posZ, L, W, H: double);
    procedure CreateShellCylinder(var Solid: TSolid; motherbody: PdxBody; posX, posY, posZ, R, H: double);

    procedure UpdateOdometry(Axis: TAxis);
    procedure CreateWheel(Robot: TRobot; Wheel: TWheel; const Pars: TWheelPars; const wFriction: TFriction; const wMotor: TMotor);
    function CreateOneRaySensor(motherbody: PdxBody; Sensor: TSensor; SensorLength: double): TSensorRay;

    procedure LoadObstaclesFromXML(XMLFile: string; OffsetDef: TSolidDef; Parser: TSimpleParser);
    procedure LoadSensorsFromXML(Robot: TRobot; const root: IXMLNode; Parser: TSimpleParser);
    //procedure LoadHumanoidJointsFromXML(Robot: TRobot; XMLFile: string);
    procedure LoadLinksFromXML(Robot: TRobot; const root: IXMLNode; Parser: TSimpleParser);
    procedure ReadFrictionFromXMLNode(var Friction: TFriction; sufix: string; const prop: IXMLNode; Parser: TSimpleParser);
    procedure ReadSpringFromXMLNode(var Spring: TSpring; sufix: string; const prop: IXMLNode; Parser: TSimpleParser);
    procedure ReadMotorFromXMLNode(var Motor: TMotor; sufix: string; const prop: IXMLNode; Parser: TSimpleParser);

    procedure CreateUniversalJoint(var Link: TSolidLink; Solid1,
      Solid2: TSolid; anchor_x, anchor_y, anchor_z, axis_x, axis_y, axis_z,
      axis2_x, axis2_y, axis2_z: double);
    procedure SetUniversalLimits(var Link: TSolidLink; LimitMin, LimitMax,
      Limit2Min, Limit2Max: double);
    procedure LoadSolidsFromXML(SolidList: TSolidList; const root: IXMLNode; Parser: TSimpleParser);
//    procedure CreateBall(bmass, radius, posX, posY, posZ: double);
    procedure LoadWheelsFromXML(Robot: TRobot; const root: IXMLNode; Parser: TSimpleParser);
    procedure LoadShellsFromXML(Robot: TRobot;  const root: IXMLNode; Parser: TSimpleParser);
    procedure LoadSceneFromXML(XMLFile: string);
    function LoadRobotFromXML(XMLFile: string; Parser: TSimpleParser): TRobot;
    procedure CreateSliderJoint(var Link: TSolidLink; Solid1, Solid2: TSolid; axis_x, axis_y, axis_z: double);
    procedure SetSliderLimits(var Link: TSolidLink; LimitMin, LimitMax: double);
    procedure UpdatePickJoint;
    procedure LoadThingsFromXML(XMLFile: string; Parser: TSimpleParser);
    procedure CreateFixedJoint(var Link: TSolidLink; Solid1,  Solid2: TSolid);
    function GetNodeAttrRealParse(parentNode: IXMLNode; attrName: string; defaultValue: double; const Parser: TSimpleParser): double;
    procedure LoadDefinesFromXML(Parser: TSimpleParser; const root: IXMLNode);
    procedure LoadTrackFromXML(XMLFile: string; Parser: TSimpleParser);
    procedure LoadPolygonFromXML(const root: IXMLNode; Parser: TSimpleParser);
    procedure LoadArcFromXML(const root: IXMLNode; Parser: TSimpleParser);
    procedure LoadLineFromXML(const root: IXMLNode; Parser: TSimpleParser);
    procedure CreateShellSphere(var Solid: TSolid; motherbody: PdxBody; posX, posY, posZ, R: double);
    procedure LoadGlobalSensorsFromXML(tag: string; XMLFile: string; Parser: TSimpleParser);
    procedure CreateSensorBody(Sensor: TSensor; GLBaseObject: TGLBaseSceneObject; SensorHeight,
      SensorRadius, posX, posY, posZ: double);
    function CreateGLPolygoLine(aWinColor: longWord; a: double; posX, posY, posZ,
      lineLength, lineWidth, angle: double; s_tag: string): TGLPolygon;
    function CreateGLArc(aWinColor: longWord; a: double; Xc, Yc, Zc, angX, angY, AngZ, StartAngle,
      StopAngle, step, innerRadius, outerRadius: double; s_tag: string): TGLPolygon;
    //procedure CreateInvisiblePlane(Plane: TSolid; dirX, dirY, dirZ, offset: double);
    function CreateInvisiblePlane(planeKind: TSolidKind; dirX, dirY, dirZ, offset: double): TSolid;
    procedure CreateSensorBeamGLObj(Sensor: TSensor; SensorLength, InitialWidth, FinalWidth: double);
    function SolidDefProcessXMLNode(var SolidDef: TSolidDef; prop: IXMLNode; Parser: TSimpleParser): boolean;
    procedure SolidDefSetDefaults(var SolidDef: TSolidDef);
    procedure CreateSphereObstacle(var Obstacle: TSolid; radius, posX,
      posY, posZ: double);
//    procedure LoadSolidXMLProperties(XMLSolid: IXMLNode; Parser: TSimpleParser);
    procedure InitSolidXMLProperties(
      var SolidXMLProperties: TSolidXMLProperties);
    procedure CreateSensorRanger2dGLObj(Sensor: TSensor);
    procedure CreateBallJoint(var Link: TSolidLink; Solid1, Solid2: TSolid;
      anchor_x, anchor_y, anchor_z: double);
//    procedure AxisGLCreate(axis: Taxis; aRadius, aHeight: double);
//    procedure AxisGLSetPosition(axis: Taxis);
  public
    procedure CreateSolidBox(var Solid: TSolid; bmass, posX, posY, posZ, L, W, H: double);
    procedure CreateSolidCylinder(var Solid: TSolid; cmass, posX, posY, posZ: double; c_radius, c_length: double);
    procedure CreateSolidSphere(var Solid: TSolid; bmass, posX, posY, posZ: double; c_radius: double);
    procedure DeleteSolid(Solid: TSolid);
    procedure LoadSolidMesh(newSolid: TSolid; MeshFile, MeshShadowFile: string; MeshScale: double;
      MeshCastsShadows: boolean);

    procedure exportGLPolygonsText(St: TStringList; tags: TStrings);
    procedure getGLPolygonsTags(TagsList: TStrings);

    procedure LoadJointWayPointsFromXML(XMLFile: string; r: integer);
    procedure SaveJointWayPointsToXML(XMLFile: string; r: integer);
    procedure SetCameraTarget(r: integer);

    procedure CreatePickJoint(Solid: TSolid; anchor_x, anchor_y, anchor_z: double);
    procedure MovePickJoint(anchor_x, anchor_y, anchor_z: double);
    procedure DestroyPickJoint;
    //function InsideGLPolygonsTaged(x, y: double; tags: TStrings): boolean;
  end;


//Form
type

  { TFViewer }

  TFViewer = class(TForm)
    GLScene: TGLScene;
    GLCadencer: TGLCadencer;
    GLSceneViewer: TGLSceneViewer;
    GLCamera: TGLCamera;
    GLLightSource: TGLLightSource;
    GLDummyTargetCam: TGLDummyCube;
    GLWindowsBitmapFont: TGLWindowsBitmapFont;
    IniPropStorage: TIniPropStorage;
    ODEScene: TGLDummyCube;
    Timer: TTimer;
    GLShadowVolume: TGLShadowVolume;
    GLPlaneFloor: TGLPlane;
    GLMaterialLibrary: TGLMaterialLibrary;
    GLCylinder1: TGLCylinder;
    GLEarthSkyDome: TGLEarthSkyDome;
    GLXYZGrid: TGLXYZGrid;
    GLDummyCamPos: TGLDummyCube;
    GLDummyCamPosRel: TGLDummyCube;
    GLDummyTargetCamRel: TGLDummyCube;
    GLDummyCubeAxis: TGLDummyCube;
    GLFlatText_X: TGLFlatText;
    GLFlatText_Y: TGLFlatText;
    GLFlatTextOrigin: TGLFlatText;
    GLPolygonArrowX: TGLPolygon;
    GLPolygonArrowY: TGLPolygon;
    GLCylinder2: TGLCylinder;
    GLLinesXY: TGLLines;
    GLHUDTextObjName: TGLHUDText;
    PopupMenu: TPopupMenu;
    MenuConfig: TMenuItem;
    MenuChart: TMenuItem;
    MenuEditor: TMenuItem;
    GLMaterialLibrary3ds: TGLMaterialLibrary;
    GLFireFXManager: TGLFireFXManager;
    GLDummyCFire: TGLDummyCube;
    GLCube1: TGLCube;
    MenuScene: TMenuItem;
    GLHUDTextGeneric: TGLHUDText;
    GLDTrails: TGLDummyCube;
    MenuSheets: TMenuItem;
    MenuSnapshot: TMenuItem;
    MenuChangeScene: TMenuItem;
    GLCone1: TGLCone;
    N1: TMenuItem;
    MenuAbort: TMenuItem;
    GLPlaneTex: TGLPlane;
    GLPlane1: TGLPlane;
    GLLineMeasure: TGLLines;
    GLHUDTextMeasure: TGLHUDText;
    N2: TMenuItem;
    MenuCameras: TMenuItem;
    TimerCadencer: TTimer;
    GLWaterPlane1: TGLWaterPlane;
    GLCameraMem: TGLCamera;
    MenuQuit: TMenuItem;
    GLDisk1: TGLDisk;
    procedure FormCreate(Sender: TObject);
    procedure GLSceneViewerMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure GLSceneViewerMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure GLCadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormShow(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure GLSceneViewerMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MenuChartClick(Sender: TObject);
    procedure MenuConfigClick(Sender: TObject);
    procedure MenuEditorClick(Sender: TObject);
    procedure MenuSceneClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuSheetsClick(Sender: TObject);
    procedure MenuSnapshotClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MenuChangeSceneClick(Sender: TObject);
    procedure MenuAbortClick(Sender: TObject);
    procedure MenuCamerasClick(Sender: TObject);
    procedure TimerCadencerTimer(Sender: TObject);
    procedure MenuQuitClick(Sender: TObject);
  private
    { Private declarations }

    my,mx: integer;
    t_delta, t_last, t_act: int64;
    KeyVals: TKeyVals;
    procedure UpdateCamPos(CMode: integer);
    procedure FillRemote(r: integer);
    procedure UpdateGLScene;
    function GLSceneViewerPick(X, Y: Integer): TGLCustomSceneObject;
    procedure TestTexture;
    procedure ShowOrRestoreForm(Fm: TForm);
    procedure TestSaveTexture;
    function GetMeasureText: string;
    procedure HandleMeasureKeys(var Key: Word; Shift: TShiftState);
    procedure UpdateGLCameras;
  public
    HUDStrings: TStringList;
    TrailsCount: integer;
    CurrentProject: string;
    frameCount: longword;

    procedure SetTrailCount(NewCount, NodeCount: integer);
    procedure AddTrailNode(T: integer; x, y, z: double);
    procedure DelTrailNode(T: integer);
  end;


function LoadXML(XMLFile: string; ErrorList: TStringList): IXMLDocument;

var
  FViewer: TFViewer;
  WorldODE: TWorld_ODE;
  RemControl: TRemControl;
  RemState: TRemState;

implementation

{$R *.lfm}

uses ODEGL, Params, Editor, FastChart, utils, StdCtrls, VerInfo,
  SceneEdit, Sheets, cameras, ChooseScene;



// this is called by dSpaceCollide when two objects in space are
// potentially colliding.

procedure nearCallback (data : pointer; o1, o2 : PdxGeom); cdecl;
var
  i,n : integer;
  b1, b2: PdxBody;
  c : TdJointID;
  contact : array[0..MAX_CONTACTS-1] of TdContact;
  n_mode: cardinal;
  n_mu, n_mu2, n_soft_cfm, tmp: double;
  n_fdir1 : TdVector3;
  n_motion1: double;
begin
  //exit;
  b1 := dGeomGetBody(o1);
  b2 := dGeomGetBody(o2);
  // do not collide static objects
  //if not assigned(b1) and not assigned(b2) then exit;

  if assigned(b1) and assigned(b2) then begin
    //exit without doing anything if the two bodies are connected by a joint
    //if (dAreConnected(b1, b2)<>0) then exit;
    if (dGeomGetClass(o1) <> dRayClass) and (dGeomGetClass(o2) <> dRayClass) then
      if (dAreConnectedExcluding(b1, b2, dJointTypeContact)<>0) then exit;
  end;

  n := dCollide(o1, o2, MAX_CONTACTS, contact[0].geom, sizeof(TdContact));
  if (n > 0) then  begin
    //FParams.EditDEbug2.Text := '';
    //if((dGeomGetClass(o1) = dRayClass) or (dGeomGetClass(o2) = dRayClass)) then begin

    if dGeomGetClass(o1) = dRayClass then begin
      if (o1.data <> nil) then begin
        with TSensorRay(o1.data).Measure do begin
          {pos := contact[0].geom.pos;
          normal := contact[0].geom.normal;
          dist := contact[0].geom.depth;
          //measure := min(measure, contact[0].geom.depth);
          has_measure:= true;
          HitSolid := o2.data;}
          if (dist < 0) or (contact[0].geom.depth < dist) then begin
            pos := contact[0].geom.pos;
            normal := contact[0].geom.normal;
            dist := contact[0].geom.depth;
            has_measure:= true;
            HitSolid := o2.data;
          end;
        end;
      end;
      //FParams.EditDEbug2.Text := format('%.2f, %.2f %.2f',[contact[0].geom.pos[0], contact[0].geom.pos[1], contact[0].geom.pos[2]]);;
      exit;
    end;
    if dGeomGetClass(o2) = dRayClass then begin
      if (o2.data <> nil) then begin
        with TSensorRay(o2.data).Measure do begin
          {pos := contact[0].geom.pos;
          normal := contact[0].geom.normal;
          dist := contact[0].geom.depth;
          //measure := min(measure, contact[0].geom.depth);
          has_measure:= true;
          HitSolid := o1.data;}
          if (dist < 0) or (contact[0].geom.depth < dist) then begin
            pos := contact[0].geom.pos;
            normal := contact[0].geom.normal;
            dist := contact[0].geom.depth;
            has_measure:= true;
            HitSolid := o1.data;
          end;
        end;
      end;
      exit;
    end;

    n_mode := dContactBounce or
              dContactSoftCFM or
              dContactApprox1;

    n_mu := WorldODE.default_n_mu;
    n_mu2 := n_mu;
    //n_soft_cfm := 0.001;
    n_soft_cfm := 1e-5;

    n_motion1 := 0;
    if (o1.data <> nil) and (TSolid(o1.data).ParSurface.mode <> 0) then begin
      n_mu := TSolid(o1.data).ParSurface.mu;
      n_mu2 := TSolid(o1.data).ParSurface.mu2;
      //n_soft_cfm := max(n_soft_cfm, TSolid(o1.data).ParSurface.soft_cfm);
      n_soft_cfm := TSolid(o1.data).ParSurface.soft_cfm;
    end;
    if (o2.data <> nil) and (TSolid(o2.data).ParSurface.mode <> 0) then begin
      n_mu := sqrt(n_mu * TSolid(o2.data).ParSurface.mu);
      n_mu2 := sqrt(n_mu2 * TSolid(o2.data).ParSurface.mu2);
      n_soft_cfm := max(n_soft_cfm, TSolid(o2.data).ParSurface.soft_cfm);
    end;

    {if((dGeomGetClass(o1) = dSphereClass) and (dGeomGetClass(o2) <> dPlaneClass)) or
      ((dGeomGetClass(o2) = dSphereClass) and (dGeomGetClass(o1) <> dPlaneClass)) then begin
      //n_mode := 0.9;
      n_mu2 := 0.0;
      n_mu := 0.1;
      zeromemory(@n_fdir1[0], sizeof(n_fdir1));
    end else}

    //FParams.EditDebug.Text := format('%d- %.2f %.2f %.2f',[n, n_fdir1[0], n_fdir1[1], n_fdir1[2]]);
    if (o1.data <> nil) and (TSolid(o1.data).kind in [skOmniWheel, skOmniSurface]) then begin
        n_mode := n_mode or cardinal(dContactMu2 or dContactFDir1);
        if TSolid(o1.data).kind = skOmniWheel then begin
          dBodyVectorToWorld(b1, 0, 0, 1, n_fdir1);
          tmp := n_mu2;
          n_mu2 := n_mu;
          n_mu := tmp; //0.001;
        end else begin
          dBodyVectorToWorld(b1, 0, 1, 0, n_fdir1);
        end;
    end else if (o2.data <> nil) and (TSolid(o2.data).kind in [skOmniWheel, skOmniSurface]) then begin
        n_mode := n_mode or cardinal(dContactMu2 or dContactFDir1);
        //dBodyVectorToWorld(b2, 0, 0, 1, n_fdir1);
        if TSolid(o2.data).kind = skOmniWheel then begin
          dBodyVectorToWorld(b2, 0, 0, 1, n_fdir1);
          tmp := n_mu2;
          n_mu2 := n_mu;
          n_mu := tmp; //0.001;
        end else begin
          dBodyVectorToWorld(b2, 0, 1, 0, n_fdir1);
        end;
    end;

    // Conveyor belt case
    if (o1.data <> nil) and (TSolid(o1.data).kind = skMotorBelt) then begin
        n_mode := n_mode or cardinal(dContactMu2 or dContactFDir1 or dContactMotion1);
        dBodyVectorToWorld(b1, -1, 0, 0, n_fdir1);
        n_mu2 := n_mu; //0.9
        n_motion1 := TSolid(o1.data).BeltSpeed;
    end else if (o2.data <> nil) and (TSolid(o2.data).kind = skMotorBelt) then begin
        n_mode := n_mode or cardinal(dContactMu2 or dContactFDir1 or dContactMotion1);
        dBodyVectorToWorld(b2, 1, 0, 0, n_fdir1);
        n_mu2 := n_mu;
        n_motion1 := TSolid(o2.data).BeltSpeed;
    end;

    for i := 0 to n-1 do begin
      with contact[i].surface do begin
        mode := n_mode;
        mu := n_mu;
        mu2 := n_mu2;
        contact[i].fdir1 := n_fdir1;

        //soft_cfm := 0.001;
        soft_cfm := n_soft_cfm;
        bounce := 0.6;
        bounce_vel := 0.001;
        motion1 := n_motion1;
      end;
      c := dJointCreateContact(WorldODE.world, WorldODE.contactgroup, @contact[i]);
      dJointAttach(c, dGeomGetBody(contact[i].geom.g1), dGeomGetBody(contact[i].geom.g2));
    end;
  end;
end;



function CalcPID(var PID: TMotController; ref, ek: double): double;
var {ek,} dek, mk: double;
begin
  result := 0;
  if not PID.active then exit;

  //ek := ref - yk;
  dek := ek - PID.ek_1;
  PID.Sek := PID.Sek + ek;
  mk := PID.Kp * ek + PID.Ki * PID.Sek + PID.Kd * dek + PID.Kf * ref;

  // Anti Windup
  if abs(mk) >= PID.y_sat then begin
    PID.Sek := PID.Sek - ek;
    mk := max(-PID.y_sat, min(PID.y_sat, mk));
  end;

  PID.ek_1 := ek;
  result := mk;
end;

function CalcPD(var PID: TMotController; ref, refw, yk, ywk: double): double;
var ek, ewk, mk: double;
begin
  result := 0;
  if not PID.active then exit;

  ek := ref - yk;
  PID.Sek := PID.Sek + ek;
  //if abs(ek) < degtorad(1) then exit;
  ewk := refw - ywk;
  mk := PID.Ki * PID.Sek + PID.Kp * ek + PID.Kd * ewk + PID.Kf * ref;

  // Anti Windup
 { if abs(mk) >= PID.y_sat then begin
    PID.Sek := PID.Sek - ek;
    mk := max(-PID.y_sat, min(PID.y_sat, mk));
  end;}

  result := mk;
end;


procedure JointGLPosition(var joint: TdJointID; var jointGL: TGLCylinder);
var vtmp: TdVector3;
begin
    with TGLCylinder(jointGL) do begin
      dJointGetHingeAnchor(joint,vtmp);
      Position.x := vtmp[0];
      Position.y := vtmp[1];
      Position.z := vtmp[2];

      dJointGetHingeAxis(joint,vtmp);
      up.x := vtmp[0];
      up.y := vtmp[1];
      up.z := vtmp[2];
    end;
end;

{
function GetNodeAttrRealExpr(parentNode: IXMLNode; attrName: string; defaultValue: real): real;
var attrValue, s: WideString;
begin
  if not GetNodeAttr(parentNode, attrName, attrValue) then begin
    Result := defaultValue;
  end else begin
    s := StringReplace(attrValue, DEFAULT_DECIMALSEPARATOR, DecimalSeparator, [rfReplaceAll]);
    try
      Result := SimpleCalc(s);
    except on E: Exception do
      Result := defaultValue;
    end;
  end;
end; // GetNodeAttrReal }


function TWorld_ODE.GetNodeAttrRealParse(parentNode: IXMLNode; attrName: string; defaultValue: double; const Parser: TSimpleParser): double;
var attrValue, s: string;
    err: string;
begin
  if not GetNodeAttr(parentNode, attrName, attrValue) then begin
    Result := defaultValue;
  end else begin
    s := StringReplace(attrValue, DEFAULT_DECIMALSEPARATOR, DefaultFormatSettings.DecimalSeparator, [rfReplaceAll]);
    try
      Result := Parser.Calc(s);
    except on E: Exception do begin
      Result := defaultValue;
      err := '[Expression error] ' + format('%s(%d): ', [XMLFiles[XMLFiles.count - 1], -1]) + #$0d+#$0A
             + E.Message + ': ' +#$0d+#$0A
             + '"'+ s + '"';

      if XMLErrors <> nil then begin
        XMLErrors.Add(err);
      end else begin
        showmessage(err);
      end;
      end;
    end;
  end;
end; { GetNodeAttrReal }

{
procedure TWorld_ODE.CreateSubGeomBox(var body: PdxBody; var geom: PdxGeom; xsize, ysize, zsize: double; x,y,z: double);
begin
  // create geom in current space
  geom := dCreateBox(space, xsize, ysize, zsize);
  dGeomSetBody(geom, body);
  dGeomSetOffsetPosition(geom, x, y, z);
end;


procedure TWorld_ODE.CreateGlBox(var GLCube: TGLCube; var geom: PdxGeom);
begin
  // gutter_base GLScene
  GLCube := TGLCube(ODEScene.AddNewChild(TGLCube));
  geom.data := GLCube;
  CopyCubeSizeFromBox(GLCube, geom);
  (OdeScene as TGLShadowVolume).Occluders.AddCaster(GLCube);
//  PositionSceneObject(GLCube, geom);
end;
}

procedure TWorld_ODE.CreateSolidBox(var Solid: TSolid; bmass, posX, posY, posZ, L, W, H: double);
var m: TdMass;
begin
  Solid.kind := skDefault;
  Solid.Body := dBodyCreate(world);
  dBodySetPosition(Solid.Body, posX, posY, posZ);

  //dRFromAxisAndAngle (R,0,1,0,0);
  //dBodySetRotation (Solid.Body, R);

  dMassSetBox(m, 1, L, W, H);
  dMassAdjust(m, bmass);
  dBodySetMass(Solid.Body, @m);

  Solid.Geom := dCreateBox(space, L, W, H);
  dGeomSetBody(Solid.Geom, Solid.Body);
  Solid.Geom.data := Solid;

  Solid.Volume := L * W * H;
  Solid.Ax := W * H;
  Solid.Ay := L * H;
  Solid.Az := L * W;
  dBodySetDamping(Solid.Body, Solid.StokesDrag, Solid.RollDrag); // TODO anisotripic rolldrag
//  dBodySetDamping(Solid.Body, Solid.StokesDrag * (L + W + H), Solid.RollDrag * (L + W + H));
//  dBodySetDamping(Solid.Body, 1e-1, 1e-1);

  Solid.GLObj := TGLSceneObject(ODEScene.AddNewChild(TGLCube));

  PositionSceneObject(Solid.GLObj, Solid.Geom);
  with (Solid.GLObj as TGLCube) do begin
    TagObject := Solid;
    //Scale.x := L;
    //Scale.y := W;
    //Scale.z := H;
    CubeDepth := H;
    CubeHeight := W;
    CubeWidth := L;
    Material.MaterialLibrary := FViewer.GLMaterialLibrary;
    //Material.FrontProperties.Diffuse.AsWinColor := clyellow;
  end;
  (OdeScene as TGLShadowVolume).Occluders.AddCaster(Solid.GLObj);
end;


procedure TWorld_ODE.CreateSolidCylinder(var Solid: TSolid; cmass, posX, posY, posZ: double; c_radius, c_length: double);
var m: TdMass;
//    R: TdMatrix3;
begin
  Solid.kind := skDefault;
  Solid.Body := dBodyCreate(world);
  dBodySetPosition(Solid.Body, posX, posY, posZ);

  dMassSetCylinder(m, 1, 3, c_radius, c_length);
  dMassAdjust(m, cmass);
  dBodySetMass(Solid.Body, @m);

  Solid.Geom := dCreateCylinder(space, c_radius, c_length);
  dGeomSetBody(Solid.Geom, Solid.Body);
  Solid.Geom.data := Solid;

  Solid.Volume :=  Pi* sqr(c_radius) * c_length;
  //TODO falta acertar ax, ay, az
  Solid.Ax := 2 * c_radius * c_length;
  Solid.Ay := 2 * c_radius * c_length;
  Solid.Az := pi * sqr(c_radius);
  dBodySetDamping(Solid.Body, Solid.StokesDrag, Solid.RollDrag); // TODO anisotripic drag
//  dBodySetDamping(Solid.Body, Solid.StokesDrag * (c_radius + c_length), Solid.RollDrag * (c_radius + c_length));
//  dRFromAxisAndAngle(R,1,0,0,pi/2);
//  dGeomSetOffsetRotation(Solid.Geom, R);
//  dBodySetRotation(Solid.Body, R);

  Solid.GLObj := TGLSceneObject(ODEScene.AddNewChild(TGLCylinder));

  with (Solid.GLObj as TGLCylinder) do begin
    Slices := 64;
    TagObject := Solid;
    TopRadius := c_radius;
    BottomRadius := c_radius;
    Height := c_length;
    //Material.FrontProperties.Diffuse.AsWinColor := clyellow;
    Material.MaterialLibrary := FViewer.GLMaterialLibrary;
    //Material.LibMaterialName := 'LibMaterialBumps';
    //Material.LibMaterialName := 'LibMaterialFeup';
  end;
  (OdeScene as TGLShadowVolume).Occluders.AddCaster(Solid.GLObj);

  //PositionSceneObject(Solid.GLObj, Solid.Geom);
  //if Solid.GLObj is TGLCylinder then Solid.GLObj.pitch(90);
end;


procedure TWorld_ODE.CreateSolidSphere(var Solid: TSolid; bmass, posX, posY, posZ, c_radius: double);
var m: TdMass;
begin
  Solid.kind := skDefault;
  Solid.Body := dBodyCreate(world);
  dBodySetPosition(Solid.Body, posX, posY, posZ);

  dMassSetSphereTotal(m, bmass, c_radius);
  dBodySetMass(Solid.Body, @m);

  Solid.Geom := dCreateSphere(space, c_radius);
  dGeomSetBody(Solid.Geom, Solid.Body);
  Solid.Geom.data := Solid;

  Solid.Volume :=  4/3 * Pi * sqr(c_radius) * c_radius;
  Solid.Ax := pi * sqr(c_radius);
  Solid.Ay := pi * sqr(c_radius);
  Solid.Az := pi * sqr(c_radius);
  Solid.GLObj := TGLSceneObject(ODEScene.AddNewChild(TGLSphere));
  dBodySetDamping(Solid.Body, Solid.StokesDrag, Solid.RollDrag);
//  dBodySetDamping(Solid.Body, Solid.StokesDrag * pi * sqr(c_radius), Solid.RollDrag * c_radius);
  
  with (Solid.GLObj as TGLSphere) do begin
    TagObject := Solid;
    Radius := c_radius;
    //Material.FrontProperties.Diffuse.AsWinColor := clyellow;
    Material.MaterialLibrary := FViewer.GLMaterialLibrary;
    //Material.LibMaterialName := 'LibMaterialBumps';
    //Material.LibMaterialName := 'LibMaterialFeup';
    slices := 64;
    //stacks := 32;
  end;
  (OdeScene as TGLShadowVolume).Occluders.AddCaster(Solid.GLObj);

  //PositionSceneObject(Solid.GLObj, Solid.Geom);
end;



procedure TWorld_ODE.CreateShellBox(var Solid: TSolid; motherbody: PdxBody; posX, posY, posZ, L, W, H: double);
begin
  Solid.kind := skDefault;
  Solid.Body := motherbody;

  Solid.Geom := dCreateBox(space, L, W, H);
  dGeomSetBody(Solid.Geom, Solid.Body);
  Solid.Geom.data := Solid;

  dGeomSetOffsetPosition(Solid.Geom, posX, posY, posZ);

  Solid.GLObj := TGLSceneObject(ODEScene.AddNewChild(TGLCube));

  with (Solid.GLObj as TGLCube) do begin
    TagObject := Solid;
    Scale.x := L;
    Scale.y := W;
    Scale.z := H;
    //Material.FrontProperties.Diffuse.AsWinColor := clyellow;
  end;
  (OdeScene as TGLShadowVolume).Occluders.AddCaster(Solid.GLObj);
end;



procedure TWorld_ODE.CreateShellCylinder(var Solid: TSolid; motherbody: PdxBody; posX, posY, posZ, R, H: double);
begin
  Solid.kind := skDefault;
  Solid.Body := motherbody;

  Solid.Geom := dCreateCylinder(space, R, H);
  dGeomSetBody(Solid.Geom, Solid.Body);
  Solid.Geom.data := Solid;

  dGeomSetOffsetPosition(Solid.Geom, posX, posY, posZ);

  Solid.GLObj := TGLSceneObject(ODEScene.AddNewChild(TGLCylinder));

  with (Solid.GLObj as TGLCylinder) do begin
    TagObject := Solid;
    TopRadius := R;
    BottomRadius := R;
    Height := H;
    //Material.FrontProperties.Diffuse.AsWinColor := clyellow;
  end;
  (OdeScene as TGLShadowVolume).Occluders.AddCaster(Solid.GLObj);
end;


procedure TWorld_ODE.CreateShellSphere(var Solid: TSolid; motherbody: PdxBody; posX, posY, posZ, R: double);
begin
  Solid.kind := skDefault;
  Solid.Body := motherbody;

  Solid.Geom := dCreateSphere(space, R);
  dGeomSetBody(Solid.Geom, Solid.Body);
  Solid.Geom.data := Solid;

  dGeomSetOffsetPosition(Solid.Geom, posX, posY, posZ);

  Solid.GLObj := TGLSceneObject(ODEScene.AddNewChild(TGLSphere));

  with (Solid.GLObj as TGLSphere) do begin
    TagObject := Solid;
    Radius := R;
    //Material.FrontProperties.Diffuse.AsWinColor := clyellow;
    slices := 64;
  end;
  (OdeScene as TGLShadowVolume).Occluders.AddCaster(Solid.GLObj);
end;


function TWorld_ODE.CreateOneRaySensor(motherbody: PdxBody; Sensor: TSensor; SensorLength: double): TSensorRay;
var newRay: TSensorRay;
begin
  newRay := TSensorRay.Create;
  newRay.ParentSensor := Sensor;
  newRay.Geom := dCreateRay(space, SensorLength);
  dGeomSetBody(newRay.Geom, motherbody);
  newRay.Geom.data := newRay;
  Sensor.Rays.Add(newRay);
  result := newRay;
end;

procedure TWorld_ODE.CreateSensorBeamGLObj(Sensor: TSensor; SensorLength, InitialWidth, FinalWidth: double);
begin
  Sensor.GLObj := TGLSceneObject(ODEScene.AddNewChild(TGLCylinder));

  with (Sensor.GLObj as TGLCylinder) do begin
    TopRadius := InitialWidth;
    BottomRadius := FinalWidth;
    Height := SensorLength;
    Alignment := caTop;
    Material.FrontProperties.Diffuse.AsWinColor := clred;
    Material.FrontProperties.Diffuse.Alpha := 0.5;
    Material.BlendingMode := bmTransparency;
  end;

end;


procedure TWorld_ODE.CreateSensorRanger2dGLObj(Sensor: TSensor);
begin
  Sensor.GLObj := TGLSceneObject(ODEScene.AddNewChild(TGLDisk));

  with (Sensor.GLObj as TGLDisk) do begin
    OuterRadius := Sensor.MaxDist;
    InnerRadius := Sensor.MinDist;
    StartAngle := 90 - deg(Sensor.StartAngle);
    SweepAngle := -deg(Sensor.StartAngle - Sensor.EndAngle);

    Material.FrontProperties.Diffuse.AsWinColor := clred;
    Material.FrontProperties.Diffuse.Alpha := 0.5;
    Material.BlendingMode := bmTransparency;
    Material.BackProperties.Diffuse.AsWinColor := clred;
    Material.BackProperties.Diffuse.Alpha := 0.5;
    Material.FaceCulling := fcNoCull;
  end;

end;



procedure TWorld_ODE.CreateSensorBody(Sensor: TSensor; GLBaseObject: TGLBaseSceneObject; SensorHeight, SensorRadius, posX, posY, posZ: double);
begin
  Sensor.GLObj := TGLSceneObject(GLBaseObject.AddNewChild(TGLCylinder));
  with (Sensor.GLObj as TGLCylinder) do begin
    TopRadius := SensorRadius;
    BottomRadius := SensorRadius;
    Height := SensorHeight;
    Alignment := caTop;
    if GLBaseObject is TGLCylinder then begin
      Sensor.GLObj.Position.SetPoint(posX, -posZ, posY); // 90 degree rotation makes this ugly thing (TODO?)
    end else begin
      Sensor.GLObj.Position.SetPoint(posX, posY, posZ);
      PitchAngle := 90;
    end;
  end;
end;

procedure TWorld_ODE.CreateBoxObstacle(var Obstacle: TSolid; sizeX, sizeY, sizeZ, posX, posY, posZ: double);
//var R: TdMatrix3;
begin
  Obstacle.kind := skDefault;
  // Create 1 GLSCube and a box space.
  Obstacle.Geom := dCreateBox(space, sizeX, sizeY, sizeZ);
//  dRFromAxisAndAngle(R, 0, 0, 1, obs_teta);
//  dGeomSetRotation(Obstacle.Geom,R);
  dGeomSetPosition(Obstacle.Geom, posX, posY, posZ);
  Obstacle.GLObj := TGLCube(ODEScene.AddNewChild(TGLCube));
  Obstacle.GLObj.TagObject := Obstacle;
  Obstacle.Geom.data := Obstacle;

  dGeomSetCategoryBits(Obstacle.Geom, $00000001);
  dGeomSetCollideBits(Obstacle.Geom, $FFFFFFFE);

  CopyCubeSizeFromBox(TGLCube(Obstacle.GLObj), Obstacle.Geom);
  TGLCube(Obstacle.GLObj).Material.MaterialLibrary := FViewer.GLMaterialLibrary;
  PositionSceneObject(Obstacle.GLObj, Obstacle.Geom);
//  PositionSceneObject(TGLBaseSceneObject(PdxGeom(ground_box).data), ground_box);
  (OdeScene as TGLShadowVolume).Occluders.AddCaster(Obstacle.GLObj);
end;

procedure TWorld_ODE.CreateSphereObstacle(var Obstacle: TSolid; radius, posX, posY, posZ: double);
begin
  Obstacle.kind := skDefault;
  // Create 1 GLSCube and a box space.
  Obstacle.Geom := dCreateSphere(space, radius);
  dGeomSetPosition(Obstacle.Geom, posX, posY, posZ);
  Obstacle.GLObj := TGLSphere(ODEScene.AddNewChild(TGLSphere));
  Obstacle.GLObj.TagObject := Obstacle;
  Obstacle.Geom.data := Obstacle;

  TGLSphere(Obstacle.GLObj).radius := radius;
  TGLSphere(Obstacle.GLObj).Material.MaterialLibrary := FViewer.GLMaterialLibrary;
  TGLSphere(Obstacle.GLObj).slices := 64;


  PositionSceneObject(Obstacle.GLObj, Obstacle.Geom);
  (OdeScene as TGLShadowVolume).Occluders.AddCaster(Obstacle.GLObj);
end;

{
  Solid.kind := skDefault;
  Solid.Body := motherbody;

  Solid.Geom := dCreateSphere(space, R);
  dGeomSetBody(Solid.Geom, Solid.Body);
  Solid.Geom.data := Solid;

  dGeomSetOffsetPosition(Solid.Geom, posX, posY, posZ);

  Solid.GLObj := TGLSceneObject(ODEScene.AddNewChild(TGLSphere));

  with (Solid.GLObj as TGLSphere) do begin
    TagObject := Solid;
    Radius := R;
    //Material.FrontProperties.Diffuse.AsWinColor := clyellow;
  end;
  (OdeScene as TGLShadowVolume).Occluders.AddCaster(Solid.GLObj);
}

//procedure TWorld_ODE.CreateInvisiblePlane(Plane: TSolid; dirX, dirY, dirZ, offset: double);
function TWorld_ODE.CreateInvisiblePlane(planeKind: TSolidKind; dirX, dirY, dirZ, offset: double): TSolid;
//var plane: TSolid;
begin
  result := TSolid.Create;
  result.kind := planeKind;
  result.Geom := dCreatePlane(space, dirX, dirY, dirZ, offset);
  result.GLObj := nil;
  result.Geom.data := result;
end;


{procedure TWorld_ODE.AxisGLCreate(axis: TAxis; aRadius, aHeight: double);
begin
  axis.GLObj := TGLCylinder(ODEScene.AddNewChild(TGLCylinder));
  with TGLCylinder(axis.GLObj) do begin
    BottomRadius := aRadius;
    TopRadius := aRadius;
    height := aHeight;
    Material.FrontProperties.Diffuse.AsWinColor := clred;
  end;

//  AxisGLSetPosition(axis);
end;

procedure TWorld_ODE.AxisGLSetPosition(axis: Taxis);
var vtmp: TdVector3;
begin
  with TGLCylinder(axis.GLObj) do begin
    axis.GetAnchor(vtmp);
    Position.x := vtmp[0];
    Position.y := vtmp[1];
    Position.z := vtmp[2];

    axis.GetDir(vtmp);
    up.x := vtmp[0];
    up.y := vtmp[1];
    up.z := vtmp[2];
  end;
end;}


procedure TWorld_ODE.CreateBallJoint(var Link: TSolidLink; Solid1, Solid2: TSolid; anchor_x, anchor_y,
  anchor_z: double);
begin
  Link.joint:= dJointCreateBall(world, nil);
  dJointAttach(Link.joint, Solid1.body, Solid2.body);
  dJointSetBallAnchor(Link.joint, anchor_x, anchor_y, anchor_z);

  dJointSetBallParam(Link.joint, dParamStopCFM, 1e-5);
end;


procedure TWorld_ODE.CreateHingeJoint(var Link: TSolidLink; Solid1, Solid2: TSolid; anchor_x, anchor_y,
  anchor_z, axis_x, axis_y, axis_z: double);
begin
  Link.joint:= dJointCreateHinge(world, nil);
  dJointAttach(Link.joint, Solid1.body, Solid2.body);
  dJointSetHingeAnchor(Link.joint, anchor_x, anchor_y, anchor_z);
  dJointSetHingeAxis(Link.joint, axis_x, axis_y, axis_z);
//  JointGLCreate(idx);

//  dJointSetHingeParam (joint[idx], dParamStopERP, );
//  dJointSetHingeParam(Link.joint, dParamCFM, 1e-8);
//  dJointSetHingeParam(Link.joint, dParamFudgeFactor, 0.1);

  dJointSetHingeParam(Link.joint, dParamStopCFM, 1e-5);
end;

procedure TWorld_ODE.SetHingeLimits(var Link: TSolidLink; LimitMin, LimitMax: double);
begin
  dJointSetHingeParam(Link.joint, dParamLoStop, DegToRad(LimitMin));
  dJointSetHingeParam(Link.joint, dParamHiStop, DegToRad(LimitMax));
end;


procedure TWorld_ODE.CreateSliderJoint(var Link: TSolidLink; Solid1, Solid2: TSolid; axis_x, axis_y, axis_z: double);
begin
  Link.joint:= dJointCreateSlider(world, nil);
  dJointAttach(Link.joint, Solid1.body, Solid2.body);
  //dJointSetHingeAnchor(Link.joint, anchor_x, anchor_y, anchor_z);
  dJointSetSliderAxis(Link.joint, axis_x, axis_y, axis_z);

//  dJointSetHingeParam (joint[idx], dParamStopERP, );
  dJointSetSliderParam(Link.joint, dParamStopCFM, 1e-5);
end;

procedure TWorld_ODE.SetSliderLimits(var Link: TSolidLink; LimitMin, LimitMax: double);
begin
  dJointSetSliderParam(Link.joint, dParamLoStop, LimitMin);
  dJointSetSliderParam(Link.joint, dParamHiStop, LimitMax);
end;

procedure TWorld_ODE.CreateFixedJoint(var Link: TSolidLink; Solid1, Solid2: TSolid);
begin
  Link.joint:= dJointCreateFixed(world, nil);
  dJointAttach(Link.joint, Solid1.body, Solid2.body);
  dJointSetFixed(Link.joint);

//  dJointSetHingeParam (joint[idx], dParamStopERP, );
//  dJointSetF Param(Link.joint, dParamStopCFM, 1e-5);
end;


procedure TWorld_ODE.CreateUniversalJoint(var Link: TSolidLink; Solid1, Solid2: TSolid; anchor_x, anchor_y,
  anchor_z, axis_x, axis_y, axis_z, axis2_x, axis2_y, axis2_z: double);
begin
  Link.joint:= dJointCreateUniversal(world, nil);
  dJointAttach(Link.joint, Solid1.body, Solid2.body);
  dJointSetUniversalAnchor(Link.joint, anchor_x, anchor_y, anchor_z);
  dJointSetUniversalAxis1(Link.joint, axis_x, axis_y, axis_z);
  dJointSetUniversalAxis2(Link.joint, axis2_x, axis2_y, axis2_z);
//  JointGLCreate(idx);

//  dJointSetUniversalParam(joint[idx], dParamStopERP, );
  dJointSetUniversalParam(Link.joint, dParamStopCFM, 1e-5);
end;

procedure TWorld_ODE.SetUniversalLimits(var Link: TSolidLink; LimitMin, LimitMax, Limit2Min, Limit2Max: double);
begin
  dJointSetUniversalParam(Link.joint, dParamLoStop, DegToRad(LimitMin));
  dJointSetUniversalParam(Link.joint, dParamHiStop, DegToRad(LimitMax));

  dJointSetUniversalParam(Link.joint, dParamLoStop2, DegToRad(Limit2Min));
  dJointSetUniversalParam(Link.joint, dParamHiStop2, DegToRad(Limit2Max));
end;

procedure TWorld_ODE.CreatePickJoint(Solid: TSolid; anchor_x, anchor_y, anchor_z: double);
begin
  if Solid = nil then exit;
  if Solid.Body = nil then exit;
  if PickJoint <> nil then dJointDestroy(PickJoint);

  PickJoint:= dJointCreateBall(world, nil);
  makevector(PickPoint, anchor_x, anchor_y, anchor_z);
  makevector(TargetPickPoint, anchor_x, anchor_y, anchor_z);

  dJointAttach(PickJoint, Solid.body, nil);
  dJointSetBallAnchor(PickJoint, anchor_x, anchor_y, anchor_z);
  dJointSetBallParam(PickJoint, dParamCFM, 5e-2);
  PickLinDamping := dBodyGetLinearDamping(Solid.Body);
  PickAngularDamping := dBodyGetAngularDamping(Solid.Body);
  dBodySetDamping(Solid.Body, 1e-2, 1e-1);
//  JointGLCreate(idx);

//  dJointSetBallParam(PickJoint, dParamStopERP, );
//  dJointSetBallParam(PickJoint, dParamStopCFM, 1e-5);
end;

procedure TWorld_ODE.MovePickJoint(anchor_x, anchor_y, anchor_z: double);
begin
  if PickJoint = nil then exit;
  if PickSolid = nil then exit;
  if PickSolid.Body = nil then exit;

  MakeVector(targetPickPoint, anchor_x, anchor_y, anchor_z);
end;

procedure TWorld_ODE.UpdatePickJoint;
var //R: TdMatrix3;
    P: TdVector3;
    oP: TdVector3;
    lambda: double;
    anchor_x, anchor_y, anchor_z: double;
begin
  if PickJoint = nil then exit;
  if PickSolid = nil then exit;
  if PickSolid.Body = nil then exit;

  //R := PickSolid.GetRotation;
  P := PickSolid.GetPosition;
  dJointGetBallAnchor(PickJoint, oP);

  lambda := 0.6;

  anchor_x := (1-lambda) * targetPickPoint.v[0] + lambda * oP[0];
  anchor_y := (1-lambda) * targetPickPoint.v[1] + lambda * oP[1];
  anchor_z := (1-lambda) * targetPickPoint.v[2] + lambda * oP[2];

  PickSolid.SetPosition(P[0] + (anchor_x - oP[0]), P[1] + (anchor_y - oP[1]), P[2] + (anchor_z - oP[2]));

  dJointSetBallAnchor(PickJoint, anchor_x, anchor_y, anchor_z);
  PickSolid.SetPosition(P[0], P[1], P[2]);
  //PickSolid.SetRotation(R);
end;


procedure TWorld_ODE.DestroyPickJoint;
begin
  //dJointAttach(PickJoint, nil, nil);
  if PickJoint <> nil then begin
    //dJointAttach(PickJoint, nil, nil);
    dJointDestroy(PickJoint);
    dBodySetDamping(PickSolid.Body, PickLinDamping, PickAngularDamping);
    PickJoint := nil;
    PickSolid := nil;
  end;
end;

{
procedure TPlayer_Ragdoll.JointGLCreate(idx: integer);
begin
  jointGL[idx] := TGLCylinder(frmRagdoll.ODEScene.AddNewChild(TGLCylinder));
  with TGLCylinder(jointGL[idx]) do begin
    BottomRadius := 0.2*uHead;
    TopRadius := 0.2*uHead;
    height := 0.7*uHead;
    Material.FrontProperties.Diffuse.AsWinColor := clRed;
  end;

  JointGLPosition(idx);
end;


procedure TPlayer_Ragdoll.JointGLPosition(idx: integer);
var vtmp: TdVector3;
begin
    with TGLCylinder(jointGL[idx]) do begin
      dJointGetHingeAnchor(joint[idx],vtmp);
      Position.x := vtmp[0];
      Position.y := vtmp[1];
      Position.z := vtmp[2];

      dJointGetHingeAxis(joint[idx],vtmp);
      up.x := vtmp[0];
      up.y := vtmp[1];
      up.z := vtmp[2];
    end;
end;
}

procedure TWorld_ODE.UpdateOdometry(Axis: TAxis);
var rot: double;
begin
  with Axis do begin
    Odo.LastAngle := Odo.Angle;
    Odo.Angle := Axis.GetPos;
    rot := Odo.Angle - Odo.LastAngle;
    if rot > pi then rot := rot - 2*pi;
    if rot <= -pi then rot := rot + 2*pi;

    Odo.Residue :=  Odo.Residue + Motor.Encoder.PPR * rot / (2*pi);// + randg(0,OdoNoise);
    Odo.LastValue := Odo.Value;
    odo.Value := floor(Odo.Residue);
    //odo.Value := round(Odo.Residue);
    Odo.Residue := Odo.Residue - Odo.Value;
    Odo.AccValue := Odo.AccValue + odo.Value;
    //FParams.editdebug2.Text := format('%d %d',[odo.Value, Odo.AccValue]);
  end;
end;



procedure TWorld_ODE.CreateWheel(Robot: TRobot; Wheel: TWheel; const Pars: TWheelPars; const wFriction: TFriction; const wMotor: TMotor);
var wdx,wdy: double;
    newTyre: TSolid;
    newLink: TSolidLink;
begin
  wdx := Pars.CenterDist * cos(Pars.Angle);
  wdy := Pars.CenterDist * sin(Pars.Angle);

  newTyre := TSolid.Create;
  Robot.Solids.Add(newTyre);
  newTyre.ID := 'Tyre '+inttostr(round(deg(Pars.Angle)));
  // The cylinder is created with its axis vertical (Z alligned)
  CreateSolidCylinder(newTyre, Pars.mass, wdx, wdy, Pars.Radius, Pars.Radius, Pars.Width);
  newTyre.SetRotation(-sin(Pars.Angle), cos(Pars.Angle), 0, pi/2);
  newTyre.MovePosition(Pars.offsetX, Pars.offsetY, Pars.offsetZ);
  newTyre.SetZeroState();

  if Pars.omni then begin
    newTyre.kind := skOmniWheel;
  end;
  newTyre.ParSurface.mode := $FF;
  newTyre.ParSurface.mu := Pars.Mu;
  newTyre.ParSurface.mu2 := Pars.Mu2;
  newTyre.ParSurface.soft_cfm := Pars.soft_cfm;

  newLink := TSolidLink.Create;
  Robot.Links.Add(newLink);
  CreateHingeJoint(newLink, newTyre, Robot.MainBody,
                   Pars.offsetX + wdx, Pars.offsetY + wdy, Pars.offsetZ + Pars.Radius,
                   -wdx, -wdy, 0);

  newLink.ID := inttostr(Robot.Links.Count);
  newLink.description := 'Wheel' + newLink.ID;
  newLink.Axis[0] := TAxis.Create;
  newLink.Axis[0].ParentLink := newLink;
  Robot.Axes.Add(newLink.Axis[0]);

  with newLink.Axis[0] do begin
    Friction := wFriction;
    Motor := wMotor;
    //Odo :=  wAxis.Odo;
  end;

  Wheel.Pars := Pars;
  Wheel.active := true;
  Wheel.Tyre := newTyre;
  Wheel.Axle := newLink;
end;

{function LoadXMLattrXYZ(const node: IXMLNode; var x,y,z: double): boolean;
var at: IXMLNode;
begin
  result := false;
  at := prop.Attributes.GetNamedItem('x');
  if at <> nil then exit;
  x := strtofloatdef(at.NodeValue, x);
  //if not TryStrToFloat(at.NodeValue, x) then exit;
end;


type TSolidXMLProperties = record
    radius, sizeX, sizeY, sizeZ, posX, posY, posZ, angX, angY, angZ, mass: double;
    I11, I22, I33, I12, I13, I23: double;
    BuoyantMass, Drag, StokesDrag, RollDrag: double;
    colorR, colorG, colorB: double;
    ID: string;
    descr: string;
    TextureName: string;
    TextureScale: double;
    MeshFile, MeshShadowFile: string;
    MeshScale: double;
    MeshCastsShadows: boolean;
    Surf: TdSurfaceParameters;
    dMass: TdMass;
    MatterProps: TMatterProperties;
    hasCanvas, isLiquid: boolean;
    CanvasWidth, CanvasHeigth: integer;
    MotherSolidId: string;
    SolidIdx: integer;
    NewPos, ActPos: TdVector3;
    GravityMode: integer;
    transparency: double;
end;}

procedure TWorld_ODE.InitSolidXMLProperties(var SolidXMLProperties: TSolidXMLProperties);
begin
  with SolidXMLProperties do begin
    GravityMode := 1;
    mass := 1;  ID := '-1';
    I11 := -1; I22 := -1; I33 := -1; I12 := 0; I13 := 0; I23 := 0;
    MatterProps := [];
    MeshFile := '';
    MeshShadowFile := '';
    MeshScale := 1;
    MeshCastsShadows := true;
    BuoyantMass := 0;
    Drag := 0; StokesDrag := 1e-5; RollDrag := 1e-3;
    BuoyanceX := 0; BuoyanceY := 0; BuoyanceZ := 0;
    radius := 1;
    sizeX := 1; sizeY := 1; sizeZ := 1;
    posX := 0; posY := 0; posZ := 0;
    angX := 0; angY := 0; angZ := 0;
    colorR := 128/255; colorG := 128/255; colorB := 128/255;
    TextureName := ''; TextureScale := 1;
    transparency := 1;
    //descr := XMLSolid.NodeName + inttostr(SolidList.Count);
    Surf.mu := -1; Surf.mu2 := -1;
    Surf.soft_cfm := 1e-5;
    //Surf.soft_erp := 0.2;
    Surf.bounce := 0; Surf.bounce_vel := 0;
    hasCanvas := false;
    isLiquid := false;
    CanvasWidth := 128; CanvasHeigth := 128;
    MotherSolidId := '';
  end;
end;

{
procedure TWorld_ODE.LoadSolidXMLProperties(XMLSolid: IXMLNode; Parser: TSimpleParser);
var prop: IXMLNode;
    R: TdMatrix3;
    newSolid: TSolid;
    SolidXMLProperties: TSolidXMLProperties;
begin

  if pos(XMLSolid.NodeName, 'cuboid <> cylinder <> sphere <> belt <> propeller') <> 0 then begin // Tsolid

    prop := XMLSolid.FirstChild;
    // default values
    InitSolidXMLProperties(SolidXMLProperties);
    //SolidXMLProperties.descr := XMLSolid.NodeName + inttostr(SolidList.Count);

    while prop <> nil do with SolidXMLProperties do begin
      if prop.NodeName = 'solid' then begin
        MotherSolidId := GetNodeAttrStr(prop, 'id', MotherSolidId);
      end;
      if prop.NodeName = 'transparency' then begin
        transparency := GetNodeAttrRealParse(prop, 'alpha', transparency, Parser);
      end;
      if prop.NodeName = 'liquid' then begin
        isLiquid := true;
        //CanvasWidth := round(GetNodeAttrRealParse(prop, 'width', CanvasWidth, Parser));
        //CanvasHeigth := round(GetNodeAttrRealParse(prop, 'heigth', CanvasHeigth, Parser));
      end;
      if prop.NodeName = 'canvas' then begin
        hasCanvas := true;
        CanvasWidth := round(GetNodeAttrRealParse(prop, 'width', CanvasWidth, Parser));
        CanvasHeigth := round(GetNodeAttrRealParse(prop, 'heigth', CanvasHeigth, Parser));
      end;
      if prop.NodeName = 'metallic' then begin
        MatterProps := MatterProps + [smMetallic];
      end;
      if prop.NodeName = 'ferromagnetic' then begin
        MatterProps := MatterProps + [smFerromagnetic];
      end;
      if prop.NodeName = 'surface' then begin
        Surf.mu := GetNodeAttrRealParse(prop, 'mu', Surf.mu, Parser);
        Surf.mu2 := GetNodeAttrRealParse(prop, 'mu2', Surf.mu2, Parser);
        Surf.soft_cfm := GetNodeAttrRealParse(prop, 'softness', Surf.soft_cfm, Parser);
        Surf.bounce := GetNodeAttrRealParse(prop, 'bounce', Surf.bounce, Parser);
        Surf.bounce_vel := GetNodeAttrRealParse(prop, 'bounce_tresh', Surf.bounce_vel, Parser);
      end;
      if prop.NodeName = 'mesh' then begin
        MeshFile := GetNodeAttrStr(prop, 'file', MeshFile);
        MeshShadowFile := GetNodeAttrStr(prop, 'shadowfile', MeshShadowFile);
        MeshScale := GetNodeAttrRealParse(prop, 'scale', MeshScale, Parser);
        MeshCastsShadows := GetNodeAttrBool(prop, 'shadow', MeshCastsShadows);
      end;
      if prop.NodeName = 'drag' then begin
        Drag := GetNodeAttrRealParse(prop, 'coefficient', Drag, Parser);
        StokesDrag := GetNodeAttrRealParse(prop, 'stokes', StokesDrag, Parser);
        RollDrag := GetNodeAttrRealParse(prop, 'roll', RollDrag, Parser);
      end;
      if (prop.NodeName = 'buoyant') or (prop.NodeName = 'buoyance') then begin
        BuoyantMass := GetNodeAttrRealParse(prop, 'mass', BuoyantMass, Parser);
        BuoyanceX := GetNodeAttrRealParse(prop, 'x', BuoyanceX, Parser);
        BuoyanceY := GetNodeAttrRealParse(prop, 'y', BuoyanceY, Parser);
        BuoyanceZ := GetNodeAttrRealParse(prop, 'z', BuoyanceZ, Parser);
      end;
      if prop.NodeName = 'nogravity' then begin
        GravityMode := 0;
      end;
      if prop.NodeName = 'radius' then begin
        radius := GetNodeAttrRealParse(prop, 'value', radius, Parser);
      end;
      if prop.NodeName = 'size' then begin
        sizeX := GetNodeAttrRealParse(prop, 'x', sizeX, Parser);
        sizeY := GetNodeAttrRealParse(prop, 'y', sizeY, Parser);
        sizeZ := GetNodeAttrRealParse(prop, 'z', sizeZ, Parser);
        radius := GetNodeAttrRealParse(prop, 'radius', radius, Parser);
      end;
      if prop.NodeName = 'pos' then begin
        posX := GetNodeAttrRealParse(prop, 'x', posX, Parser);
        posY := GetNodeAttrRealParse(prop, 'y', posY, Parser);
        posZ := GetNodeAttrRealParse(prop, 'z', posZ, Parser);
      end;
      if prop.NodeName = 'rot_deg' then begin
        angX := degToRad(GetNodeAttrRealParse(prop, 'x', angX, Parser));
        angY := degToRad(GetNodeAttrRealParse(prop, 'y', angY, Parser));
        angZ := degToRad(GetNodeAttrRealParse(prop, 'z', angZ, Parser));
      end;
      if prop.NodeName = 'color_rgb' then begin
        colorR := GetNodeAttrInt(prop, 'r', 128)/255;
        colorG := GetNodeAttrInt(prop, 'g', 128)/255;
        colorB := GetNodeAttrInt(prop, 'b', 128)/255;
      end;
      if prop.NodeName = 'mass' then begin
        mass := GetNodeAttrRealParse(prop, 'value', mass, Parser);
        //I11, I22, I33, I12, I13, I23
        I11 := GetNodeAttrRealParse(prop, 'I11', I11, Parser);
        I22 := GetNodeAttrRealParse(prop, 'I22', I22, Parser);
        I33 := GetNodeAttrRealParse(prop, 'I33', I33, Parser);
        I12 := GetNodeAttrRealParse(prop, 'I12', I12, Parser);
        I13 := GetNodeAttrRealParse(prop, 'I13', I13, Parser);
        I23 := GetNodeAttrRealParse(prop, 'I23', I23, Parser);
      end;
      if prop.NodeName = 'ID' then begin
        ID := GetNodeAttrStr(prop, 'value', ID);
      end;
      if prop.NodeName = 'texture' then begin
        TextureName := GetNodeAttrStr(prop, 'name', TextureName);
        TextureScale := GetNodeAttrRealParse(prop, 'scale', TextureScale, Parser);
      end;
      prop := prop.NextSibling;
    end;


  end else begin // Unused Tag Generate warning
    if (XMLErrors <> nil) and (XMLSolid.NodeName <> '#text') and (XMLSolid.NodeName <> '#comment') then begin
      XMLErrors.Add('[Warning]: Tag <'+ XMLSolid.NodeName + '> not recognised!');
    end;
  end;

end;
}
procedure TWorld_ODE.LoadSolidMesh(newSolid: TSolid; MeshFile, MeshShadowFile: string; MeshScale: double; MeshCastsShadows: boolean);
begin
  // create mesh file
  if MeshFile <> '' then begin
    //newSolid.GLObj.Visible := false;
    newSolid.AltGLObj := TGLSceneObject(ODEScene.AddNewChild(TGLFreeForm));
    with (newSolid.AltGLObj as TGLFreeForm) do begin
      TagObject := newSolid;
      MaterialLibrary := FViewer.GLMaterialLibrary3ds;
      //Material.MaterialLibrary := FViewer.GLMaterialLibrary3ds; //???
      //LightmapLibrary := FViewer.GLMaterialLibrary3ds;
      try
        LoadFromFile(MeshFile);
      except on e: Exception do
        showmessage(E.Message);
      end;
      Scale.x := MeshScale;
      Scale.y := MeshScale;
      Scale.z := MeshScale;
    end;
    PositionSceneObject(newSolid.AltGLObj, newSolid.Geom);

    if MeshCastsShadows and (MeshShadowFile = '') then
      (OdeScene as TGLShadowVolume).Occluders.AddCaster(newSolid.AltGLObj);
  end;

  // create shadow mesh file
  if MeshShadowFile <> '' then begin
    newSolid.ShadowGlObj := TGLSceneObject(ODEScene.Parent.AddNewChild(TGLFreeForm));
    //newSolid.ShadowGlObj := TGLSceneObject(ODEScene.AddNewChild(TGLFreeForm));
    with (newSolid.ShadowGlObj as TGLFreeForm) do begin
      Visible := false;
      TagObject := newSolid;
      MaterialLibrary := FViewer.GLMaterialLibrary3ds;
      try
        LoadFromFile(MeshShadowFile);
      except on e: Exception do
        showmessage(E.Message);
      end;
      Scale.x := MeshScale;
      Scale.y := MeshScale;
      Scale.z := MeshScale;
    end;
    PositionSceneObject(newSolid.ShadowGlObj, newSolid.Geom);
    with (OdeScene as TGLShadowVolume).Occluders.AddCaster(newSolid.ShadowGlObj) do begin
      CastingMode := scmParentVisible;// scmAlways; //scmVisible;
    end;
  end;
end;


//procedure TWorld_ODE.LoadHumanoidBonesFromXML(Robot: TRobot; XMLFile: string);
//procedure TWorld_ODE.LoadSolidsFromXML(Robot: TRobot; const root: IXMLNode);
procedure TWorld_ODE.LoadSolidsFromXML(SolidList: TSolidList; const root: IXMLNode; Parser: TSimpleParser);
var XMLSolid, prop: IXMLNode;
    radius, sizeX, sizeY, sizeZ, posX, posY, posZ, angX, angY, angZ, mass: double;
    I11, I22, I33, I12, I13, I23: double;
    BuoyantMass, Drag, StokesDrag, RollDrag: double;
    BuoyanceX, BuoyanceY, BuoyanceZ: double;
    colorR, colorG, colorB: double;
    ID: string;
    R: TdMatrix3;
    newSolid: TSolid;
    descr: string;
    TextureName: string;
    TextureScale: double;
    MeshFile, MeshShadowFile: string;
    MeshScale: double;
    MeshCastsShadows: boolean;
    Surf: TdSurfaceParameters;
    dMass: TdMass;
    MatterProps: TMatterProperties;
    hasCanvas, isLiquid: boolean;
    CanvasWidth, CanvasHeigth: integer;
    MotherSolidId: string;
    SolidIdx: integer;
    NewPos, ActPos: TdVector3;
    GravityMode: integer;
    transparency: double;
    thrust: double;
begin
  if root = nil then exit;

  XMLSolid := root.FirstChild;
  while XMLSolid <> nil do begin
    if XMLSolid.NodeName = 'defines' then begin
      LoadDefinesFromXML(Parser, XMLSolid);
    end else if pos(XMLSolid.NodeName, 'cuboid <> cylinder <> sphere <> belt <> propeller') <> 0 then begin // Tsolid
      prop := XMLSolid.FirstChild;
      // default values
      GravityMode := 1;
      mass := 1;  ID := '-1';
      I11 := -1; I22 := -1; I33 := -1; I12 := 0; I13 := 0; I23 := 0;
      MatterProps := [];
      MeshFile := '';
      MeshShadowFile := '';
      MeshScale := 1;
      MeshCastsShadows := true;
      BuoyantMass := 0;
      BuoyanceX := 0; BuoyanceY := 0; BuoyanceZ := 0;
      Drag := 0; StokesDrag := 1e-5; RollDrag := 1e-3;
      radius := 1;
      sizeX := 1; sizeY := 1; sizeZ := 1;
      posX := 0; posY := 0; posZ := 0;
      angX := 0; angY := 0; angZ := 0;
      colorR := 128/255; colorG := 128/255; colorB := 128/255;
      TextureName := ''; TextureScale := 1;
      transparency := 1;
      descr := XMLSolid.NodeName + inttostr(SolidList.Count);
      Surf.mu := -1; Surf.mu2 := -1;
      Surf.soft_cfm := 1e-5;
      //Surf.soft_erp := 0.2;
      Surf.bounce := 0; Surf.bounce_vel := 0;
      hasCanvas := false;
      isLiquid := false;
      CanvasWidth := 128; CanvasHeigth := 128;
      MotherSolidId := '';
      thrust := 0.1;    // 0.01 ???

      while prop <> nil do begin
        if prop.NodeName = 'solid' then begin
          MotherSolidId := GetNodeAttrStr(prop, 'id', MotherSolidId);
        end;
        if prop.NodeName = 'transparency' then begin
          transparency := GetNodeAttrRealParse(prop, 'alpha', transparency, Parser);
        end;
        if prop.NodeName = 'liquid' then begin
          isLiquid := true;
          //CanvasWidth := round(GetNodeAttrRealParse(prop, 'width', CanvasWidth, Parser));
          //CanvasHeigth := round(GetNodeAttrRealParse(prop, 'heigth', CanvasHeigth, Parser));
        end;
        if prop.NodeName = 'canvas' then begin
          hasCanvas := true;
          CanvasWidth := round(GetNodeAttrRealParse(prop, 'width', CanvasWidth, Parser));
          CanvasHeigth := round(GetNodeAttrRealParse(prop, 'heigth', CanvasHeigth, Parser));
        end;
        if prop.NodeName = 'metallic' then begin
          MatterProps := MatterProps + [smMetallic];
        end;
        if prop.NodeName = 'ferromagnetic' then begin
          MatterProps := MatterProps + [smFerromagnetic];
        end;
        if prop.NodeName = 'rfidtag' then begin
          MatterProps := MatterProps + [smRFIDTag];
        end;
        if prop.NodeName = 'surface' then begin
          Surf.mu := GetNodeAttrRealParse(prop, 'mu', Surf.mu, Parser);
          Surf.mu2 := GetNodeAttrRealParse(prop, 'mu2', Surf.mu2, Parser);
          Surf.soft_cfm := GetNodeAttrRealParse(prop, 'softness', Surf.soft_cfm, Parser);
          Surf.bounce := GetNodeAttrRealParse(prop, 'bounce', Surf.bounce, Parser);
          Surf.bounce_vel := GetNodeAttrRealParse(prop, 'bounce_tresh', Surf.bounce_vel, Parser);
        end;
        if prop.NodeName = 'mesh' then begin
          MeshFile := GetNodeAttrStr(prop, 'file', MeshFile);
          MeshShadowFile := GetNodeAttrStr(prop, 'shadowfile', MeshShadowFile);
          MeshScale := GetNodeAttrRealParse(prop, 'scale', MeshScale, Parser);
          MeshCastsShadows := GetNodeAttrBool(prop, 'shadow', MeshCastsShadows);
        end;
        if prop.NodeName = 'drag' then begin
          Drag := GetNodeAttrRealParse(prop, 'coefficient', Drag, Parser);
          StokesDrag := GetNodeAttrRealParse(prop, 'stokes', StokesDrag, Parser);
          RollDrag := GetNodeAttrRealParse(prop, 'roll', RollDrag, Parser);
        end;
        if prop.NodeName = 'thrust' then begin
          thrust := GetNodeAttrRealParse(prop, 'coefficient', thrust, Parser);
        end;
        if (prop.NodeName = 'buoyant') or (prop.NodeName = 'buoyance') then begin
          BuoyantMass := GetNodeAttrRealParse(prop, 'mass', BuoyantMass, Parser);
          BuoyanceX := GetNodeAttrRealParse(prop, 'x', BuoyanceX, Parser);
          BuoyanceY := GetNodeAttrRealParse(prop, 'y', BuoyanceY, Parser);
          BuoyanceZ := GetNodeAttrRealParse(prop, 'z', BuoyanceZ, Parser);
        end;
        if prop.NodeName = 'nogravity' then begin
          GravityMode := 0;
        end;
        if prop.NodeName = 'radius' then begin
          radius := GetNodeAttrRealParse(prop, 'value', radius, Parser);
        end;
        if prop.NodeName = 'size' then begin
          sizeX := GetNodeAttrRealParse(prop, 'x', sizeX, Parser);
          sizeY := GetNodeAttrRealParse(prop, 'y', sizeY, Parser);
          sizeZ := GetNodeAttrRealParse(prop, 'z', sizeZ, Parser);
          radius := GetNodeAttrRealParse(prop, 'radius', radius, Parser);
        end;
        if prop.NodeName = 'pos' then begin
          posX := GetNodeAttrRealParse(prop, 'x', posX, Parser);
          posY := GetNodeAttrRealParse(prop, 'y', posY, Parser);
          posZ := GetNodeAttrRealParse(prop, 'z', posZ, Parser);
        end;
        if prop.NodeName = 'rot_deg' then begin
          angX := degToRad(GetNodeAttrRealParse(prop, 'x', angX, Parser));
          angY := degToRad(GetNodeAttrRealParse(prop, 'y', angY, Parser));
          angZ := degToRad(GetNodeAttrRealParse(prop, 'z', angZ, Parser));
        end;
        if prop.NodeName = 'color_rgb' then begin
          colorR := GetNodeAttrInt(prop, 'r', 128)/255;
          colorG := GetNodeAttrInt(prop, 'g', 128)/255;
          colorB := GetNodeAttrInt(prop, 'b', 128)/255;
        end;
        if prop.NodeName = 'mass' then begin
          mass := GetNodeAttrRealParse(prop, 'value', mass, Parser);
          //I11, I22, I33, I12, I13, I23
          I11 := GetNodeAttrRealParse(prop, 'I11', I11, Parser);
          I22 := GetNodeAttrRealParse(prop, 'I22', I22, Parser);
          I33 := GetNodeAttrRealParse(prop, 'I33', I33, Parser);
          I12 := GetNodeAttrRealParse(prop, 'I12', I12, Parser);
          I13 := GetNodeAttrRealParse(prop, 'I13', I13, Parser);
          I23 := GetNodeAttrRealParse(prop, 'I23', I23, Parser);
        end;
        if prop.NodeName = 'ID' then begin
          ID := GetNodeAttrStr(prop, 'value', ID);
        end;
        if prop.NodeName = 'texture' then begin
          TextureName := GetNodeAttrStr(prop, 'name', TextureName);
          TextureScale := GetNodeAttrRealParse(prop, 'scale', TextureScale, Parser);
        end;
        prop := prop.NextSibling;
      end;

      if ID <> '-1' then begin
        // Create and position the solid
        newSolid := TSolid.Create;
        SolidList.Add(newSolid);
        newSolid.ID := ID;
        newSolid.BuoyantMass := BuoyantMass;
        newSolid.Drag := Drag;
        newSolid.StokesDrag := StokesDrag;
        newSolid.RollDrag := RollDrag;
        newSolid.BuoyanceCenter[0] := BuoyanceX;
        newSolid.BuoyanceCenter[1] := BuoyanceY;
        newSolid.BuoyanceCenter[2] := Buoyancez;

        if (XMLSolid.NodeName = 'cuboid') or (XMLSolid.NodeName = 'belt') or (XMLSolid.NodeName = 'propeller')then begin
          CreateSolidBox(newSolid, mass, posX, posY, posZ, sizeX, sizeY, sizeZ);
          //if TextureName <> '' then begin
          //  newSolid.SetTexture(TextureName, TextureScale); //'LibMaterialFeup'
          //end;
          if (XMLSolid.NodeName = 'cuboid') and HasCanvas then begin
            (newSolid.GLObj as TGLCube).Parts := (newSolid.GLObj as TGLCube).Parts - [cpfront];  // remove the side where the canvas will be placed
            newSolid.CanvasGLObj := TGLSceneObject(newSolid.GLObj.AddNewChild(TGLPlane));
            with (newSolid.CanvasGLObj as TGLPlane) do begin
             position.Z := sizeZ/2;
             width := sizeX;
             Height := sizeY;
             Material.Texture.Disabled := false;
             Material.Texture.TextureMode := tmModulate;
            end;
            newSolid.PaintBitmap := TBitmap.Create;
            newSolid.PaintBitmap.Width := CanvasWidth;
            newSolid.PaintBitmap.Height := CanvasHeigth;
            newSolid.PaintBitmap.PixelFormat := pf24bit;
            newSolid.PaintBitmap.Canvas.Brush.Color := clblack;
            newSolid.PaintBitmap.Canvas.pen.Color := clblack;
            //newSolid.PaintBitmap.Canvas.TextOut(0,0,'Hello World!');
            //newSolid.PaintBitmap.Canvas.Ellipse(0,0,127,127);

            with newSolid do begin
              PaintBitmapCorner[0] := sizeX/2;
              PaintBitmapCorner[1] := sizeY/2;
              PaintBitmapCorner[2] := sizeZ/2;
            end;
          end;
          if (XMLSolid.NodeName = 'cuboid') and isLiquid then begin
            (newSolid.GLObj as TGLCube).Parts := (newSolid.GLObj as TGLCube).Parts - [cpfront];  // remove the side where the liquid surface will be placed
            newSolid.extraGLObj := TGLSceneObject(newSolid.GLObj.AddNewChild(TGLWaterPlane));
            with (newSolid.extraGLObj as TGLWaterPlane) do begin
              if transparency < 1 then begin
                Material.BlendingMode := bmTransparency;
                Material.FrontProperties.Diffuse.SetColor(colorR, colorG, colorB, transparency);
              end;
              position.Z := sizeZ/2;
              up.SetVector(0, 0, 1);
              Resolution := 128;
              RainForce := 5000;
              scale.SetVector(sizeX, sizeY, 1);
            end;
          end;
        end else if XMLSolid.NodeName = 'sphere' then begin
          CreateSolidSphere(newSolid, mass, posX, posY, posZ, radius);
        end else if XMLSolid.NodeName = 'cylinder' then begin
          if abs(radius-1) > 1e-6 then begin
            CreateSolidCylinder(newSolid, mass, posX, posY, posZ, radius, sizeZ);
          end else begin
            CreateSolidCylinder(newSolid, mass, posX, posY, posZ, sizeX, sizeZ);
          end;
          //if TextureName <> '' then begin
          //  newSolid.SetTexture(TextureName, TextureScale); //'LibMaterialFeup'
          //end;
        end;
        if (I11 > 0) and (I22 > 0) and (I33 > 0)  then begin
          dMass := newSolid.Body.mass;
          dMassSetParameters(dmass, dmass.mass,
                             dmass.c[0],
                             dmass.c[1],
                             dmass.c[2],
                             I11, I22, I33, I12, I13, I23);
          dBodySetMass(newSolid.Body, @dMass);
        end;

        if TextureName <> '' then begin
          newSolid.SetTexture(TextureName, TextureScale); //'LibMaterialFeup'
        end;

        if (GravityMode = 0) then begin
          dBodySetGravityMode(newSolid.Body, 0);
        end;
        if XMLSolid.NodeName = 'belt' then newSolid.kind := skMotorBelt;
        if XMLSolid.NodeName = 'propeller' then begin
          newSolid.kind := skPropeller;
          newSolid.Thrust := thrust;
        end;

        newSolid.MatterProperties := MatterProps;

        LoadSolidMesh(newSolid, MeshFile, MeshShadowFile, MeshScale, MeshCastsShadows);

        if Surf.mu >= 0 then begin
          newSolid.ParSurface.mode := $FF;
          newSolid.ParSurface.mu := Surf.mu;
          if Surf.mu2 >= 0 then newSolid.ParSurface.mu2 := Surf.mu2;
          newSolid.ParSurface.soft_cfm := Surf.soft_cfm;
          newSolid.ParSurface.bounce := Surf.bounce;
          newSolid.ParSurface.bounce_vel := Surf.bounce_vel;
        end;

        RFromZYXRotRel(R, angX, angY, AngZ);
        dBodySetRotation(newSolid.Body, R);

        SolidIdx := SolidList.IndexFromID(MotherSolidId);
        if SolidIdx <> -1 then begin // If the position is relative we have to add the parent body position/rotation
          //Rotation
          dMULTIPLY0_333(R, dBodyGetRotation(SolidList[SolidIdx].Body)^, dBodyGetRotation(newSolid.Body)^);
          dBodySetRotation(newSolid.Body, R);

          //Position
          ActPos := dBodyGetPosition(newSolid.Body)^;
          dBodyGetRelPointPos(SolidList[SolidIdx].Body, ActPos[0], ActPos[1], ActPos[2], NewPos); //To rotate with the parent body
          dBodySetPosition(newSolid.Body, NewPos[0], NewPos[1], NewPos[2]);
        end;

        newSolid.SetZeroState();
        newSolid.SetColor(colorR, colorG, colorB, transparency);
        //PositionSceneObject(newSolid.GLObj, newSolid.Geom);
      end;

    end else begin // Unused Tag Generate warning
      if (XMLErrors <> nil) and (XMLSolid.NodeName <> '#text') and (XMLSolid.NodeName <> '#comment') then begin
        XMLErrors.Add('[Warning]: Tag <'+ XMLSolid.NodeName + '> not recognised!');
      end;
    end;

    XMLSolid := XMLSolid.NextSibling;
  end;
end;

{
  <joint>
    <ID value='8'/>
    <Pos x='-55' y='32' z='-103'/>
    <Axis x='1' y='0' z='0'/>      <!-- lateral-->
    <Axis2 x='0' y='0' z='1'/>     <!-- rotação-->
    <Connect B1='6' B2='7'/>
	<Limits Min='-16' Max='53'/>     <!-- lateral-->
    <Limits2 Min='-75' Max='11'/>    <!-- rotação-->
    <Type value='Universal'/>
    <Descr Pt='Anca Esq Lat/Rot'/>
    <Descr Eng='Left Lat/Rot Buttock'/>
  </joint>}

//procedure TWorld_ODE.LoadHumanoidJointsFromXML(Robot: TRobot; XMLFile: string);
procedure TWorld_ODE.LoadLinksFromXML(Robot: TRobot; const root: IXMLNode; Parser: TSimpleParser);
var JointNode, prop: IXMLNode;
    posX, posY, posZ: double;
    axisX, axisY, axisZ: double;
    axis2X, axis2Y, axis2Z: double;
    aGL, DefaGL: TAxisGLPars;
    LimitMin, LimitMax: double;
    Limit2Min, Limit2Max: double;
    LinkBody1, LinkBody2: string;
    LinkType: string;
    //colorR, colorG, colorB: double;
    SolidIndex1, SolidIndex2: integer;
    Solid1, Solid2: TSolid;
    i: integer;
    IDvalue: string;
    newLink: TSolidLink;
    newAxis: TAxis;
    Friction, DefFriction: TFriction;
    Friction2: TFriction;
    Spring, DefSpring: TSpring;
    Spring2: TSpring;
    Motor, DefMotor: TMotor;
    Motor2: TMotor;
    descr: string;
    AxisCanWrap, AxisCanWrap2: boolean;
    MotherSolidId: string;
    SolidIdx: integer;
    NewPos, ActPos: TdVector3;
begin
  if root = nil then exit;

  // Initialize default parameters
  DefaGL.Radius := -1;
  DefaGL.height:= 0.05;
  DefaGL.Color := RGB(0, 0, $80);

  AxisCanWrap := true;
  AxisCanWrap2 := true;

  with DefMotor do begin
    active := true;
    simple := false;
    Encoder.PPR := 1000;
    Encoder.NoiseMean := 0;
    Encoder.NoiseStDev := -1;
    Ri := 1;
    Li := 0;
    Ki := 1.4e-2;
    Imax := 4;
    Vmax := 24;

    GearRatio := 10;

    JRotor := 0;
    BRotor := 1e-3;

    KGearBox := 5e-1 / Motor.GearRatio;
    BGearBox := 1e-1 / Motor.GearRatio;

    KGearBox2 := 0;
    BGearBox2 := 0;

    Controller.active := false;
    //Controller.active := true;
    with Controller do begin
      Kp := 1;
      Ki := 0;
      Kd := 0;
      Kf := 0;
      Y_sat := 24;
      ticks := 0;
      Sek := 0;
      controlPeriod := 10;
      ControlMode := cmPIDSpeed;
    end;
  end;

  with DefFriction do begin
    Bv := 1e-5;
    Fc := 1e-3;
//    CoulombLimit := 1e-2;
  end;

  with DefSpring do begin
    K := 0;
    ZeroPos := 0;
  end;

  JointNode := root.FirstChild;
  while JointNode <> nil do begin
    if (JointNode.NodeName = 'joint') or (JointNode.NodeName = 'default') then begin //'joint'
      prop := JointNode.FirstChild;
      // default values
      posX := 0; posY := 0; posZ := 0;
      axisX := 0; axisY := 0; axisZ := 1;
      axis2X := 0; axis2Y := 0; axis2Z := 1;
      aGL := DefaGL;
      LimitMin:= -360; LimitMax := 360;
      Limit2Min:= -360; Limit2Max := 360;
      LinkBody1 := '-1'; LinkBody2 := '-1';
      LinkType :=' ';
      descr := '';
      IDvalue := '-1';
      //colorR := 128/255; colorG := 128/255; colorB := 128/255;
      newLink := nil;
      motor := DefMotor;
      motor2 := DefMotor;
      Friction := DefFriction;
      Friction2 := DefFriction;
      Spring := DefSpring;
      Spring2 := DefSpring;
      MotherSolidId := '';

      while prop <> nil do begin
        if prop.NodeName = 'solid' then begin
          MotherSolidId := GetNodeAttrStr(prop, 'id', MotherSolidId);
        end;
        if prop.NodeName = 'pos' then begin
          posX := GetNodeAttrRealParse(prop, 'x', posX, Parser);
          posY := GetNodeAttrRealParse(prop, 'y', posY, Parser);
          posZ := GetNodeAttrRealParse(prop, 'z', posZ, Parser);
        end;
        if prop.NodeName = 'axis' then begin
          axisX := GetNodeAttrRealParse(prop, 'x', axisX, Parser);
          axisY := GetNodeAttrRealParse(prop, 'y', axisY, Parser);
          axisZ := GetNodeAttrRealParse(prop, 'z', axisZ, Parser);
          AxisCanWrap := GetNodeAttrBool(prop, 'wrap', AxisCanWrap);
        end;
        if prop.NodeName = 'axis2' then begin
          axis2X := GetNodeAttrRealParse(prop, 'x', axis2X, Parser);
          axis2Y := GetNodeAttrRealParse(prop, 'y', axis2Y, Parser);
          axis2Z := GetNodeAttrRealParse(prop, 'z', axis2Z, Parser);
          AxisCanWrap2 := GetNodeAttrBool(prop, 'wrap', AxisCanWrap2);
        end;
        if prop.NodeName = 'limits' then begin
          LimitMin := GetNodeAttrRealParse(prop, 'Min', LimitMin, Parser);
          LimitMax := GetNodeAttrRealParse(prop, 'Max', LimitMax, Parser);
        end;
        if prop.NodeName = 'limits2' then begin
          Limit2Min := GetNodeAttrRealParse(prop, 'Min', Limit2Min, Parser);
          Limit2Max := GetNodeAttrRealParse(prop, 'Max', Limit2Max, Parser);
        end;
        if prop.NodeName = 'connect' then begin
          LinkBody1 := GetNodeAttrStr(prop, 'B1', LinkBody1);
          LinkBody2 := GetNodeAttrStr(prop, 'B2', LinkBody2);

          LinkBody1 := GetNodeAttrStr(prop, 'S1', LinkBody1); //Alternate sintax
          LinkBody2 := GetNodeAttrStr(prop, 'S2', LinkBody2);
        end;
        //<draw radius='0.01' height='0.1' rgb24='8F0000'/>
        if prop.NodeName = 'draw' then begin
          aGL.Radius := GetNodeAttrRealParse(prop, 'radius', aGL.Radius, Parser);
          aGL.height := GetNodeAttrRealParse(prop, 'height', aGL.height, Parser);
          aGL.Color := StrToIntDef('$'+GetNodeAttrStr(prop, 'rgb24', inttohex(aGL.color,6)), aGL.color);
        end;
        {if prop.NodeName = 'color_rgb' then begin
          colorR := GetNodeAttrInt(prop, 'r', 128)/255;
          colorG := GetNodeAttrInt(prop, 'g', 128)/255;
          colorB := GetNodeAttrInt(prop, 'b', 128)/255;
        end;}
        if prop.NodeName = 'type' then begin
          LinkType := GetNodeAttrStr(prop, 'value', LinkType);
        end;
        if prop.NodeName = 'desc' then begin
          descr := GetNodeAttrStr(prop, 'Eng', descr);
        end;
        if prop.NodeName = 'ID' then begin
          IDValue := GetNodeAttrStr(prop, 'value', IDValue);
        end;

        ReadFrictionFromXMLNode(Friction, '', prop, Parser);
        //Friction2 := Friction;
        ReadFrictionFromXMLNode(Friction2, '2', prop, Parser);

        ReadSpringFromXMLNode(Spring, '', prop, Parser);
        //Spring2 := Spring;
        ReadSpringFromXMLNode(Spring2, '2', prop, Parser);

        ReadMotorFromXMLNode(Motor, '', prop, Parser);
        //Motor2 := Motor;
        ReadMotorFromXMLNode(Motor2, '2', prop, Parser);

        prop := prop.NextSibling;
      end;

      if JointNode.NodeName = 'default' then begin
        // Set the new default Link parameters
        DefFriction := Friction;
        DefSpring := Spring;
        DefMotor := Motor;
        DefaGL := aGL;
      end else begin
        // Create a new Link
        if (LinkBody1 <> '-1') and (LinkBody2 <> '-1') then begin
          // Find the solids with this IDs
          SolidIndex1 := -1;
          SolidIndex2 := -1;
          for i := 0 to Robot.Solids.Count-1 do begin
            if Robot.Solids[i].ID = LinkBody1 then SolidIndex1 := i;
            if Robot.Solids[i].ID = LinkBody2 then SolidIndex2 := i;
          end;

          // ID = '0' or 'world' means: the world;
          if LinkBody1 = 'world' then LinkBody1 := '0';
          if LinkBody2 = 'world' then LinkBody2 := '0';
          if (((SolidIndex1 <> -1) or (LinkBody1 = '0')) and (SolidIndex2 <> -1)) or
             (((SolidIndex2 <> -1) or (LinkBody2 = '0')) and (SolidIndex1 <> -1)) then begin

            if LinkBody1 = '0' then begin // It only works when the SECOND body is the Environment
              Solid1 := Robot.Solids[SolidIndex2];
              Solid2 := Environment;
            end else if LinkBody2 = '0' then begin
              Solid1 := Robot.Solids[SolidIndex1];
              Solid2 := Environment;
            end else begin
              Solid1 := Robot.Solids[SolidIndex1];
              Solid2 := Robot.Solids[SolidIndex2];
            end;
            newLink := TSolidLink.Create;
            Robot.Links.Add(newLink);

            SolidIdx := Robot.Solids.IndexFromID(MotherSolidId);
            if SolidIdx <> -1 then begin // If the position is relative we have to add the parent body position/rotation
              //First the position
              dBodyGetRelPointPos(Robot.Solids[SolidIdx].Body, posX, posY, posZ, NewPos); //To rotate with the parent body
              posX :=  NewPos[0];
              posY :=  NewPos[1];
              posZ :=  NewPos[2];

              //Then the rotation
              dBodyGetRelPointPos(Robot.Solids[SolidIdx].Body, axisX, axisY, axisZ, NewPos); //To rotate with the parent body
              dBodyGetRelPointPos(Robot.Solids[SolidIdx].Body, 0, 0, 0, ActPos); //Rotated origin
              axisX :=  NewPos[0] - ActPos[0];
              axisY :=  NewPos[1] - ActPos[1];
              axisZ :=  NewPos[2] - ActPos[2];
            end;

            if LinkType ='Ball' then begin
              CreateBallJoint(newLink, Solid1, Solid2, posX, posY, posZ);
              aGL.height := -1;
            end;

            if LinkType ='Hinge' then begin
              CreateHingeJoint(newLink, Solid1, Solid2, posX, posY, posZ, axisX, axisY, axisZ);
              SetHingeLimits(newLink, LimitMin, LimitMax);
              if Friction.Fc > 0 then begin
                dJointSetHingeParam(newLink.joint, dParamVel , 0);
                dJointSetHingeParam(newLink.joint, dParamFMax, Friction.Fc);
              end;
            end;

            if LinkType ='Slider' then begin
              CreateSliderJoint(newLink, Solid1, Solid2, axisX,axisY,axisZ);
              SetSliderLimits(newLink, LimitMin, LimitMax);
              if Friction.Fc > 0 then begin
                dJointSetSliderParam(newLink.joint, dParamVel , 0);
                dJointSetSliderParam(newLink.joint, dParamFMax, Friction.Fc);
              end;
            end;

            if LinkType ='Fixed' then begin
              CreateFixedJoint(newLink, Solid1, Solid2);
              aGL.height := -1;
            end;

            if LinkType ='Universal' then begin
              if SolidIdx <> -1 then begin // If the position is relative we have to rotate the second axis also
                dBodyGetRelPointPos(Robot.Solids[SolidIdx].Body, axis2X, axis2Y, axis2Z, NewPos); //To rotate with the parent body
                dBodyGetRelPointPos(Robot.Solids[SolidIdx].Body, 0, 0, 0, ActPos); //Rotated origin
                axis2X :=  NewPos[0] - ActPos[0];
                axis2Y :=  NewPos[1] - ActPos[1];
                axis2Z :=  NewPos[2] - ActPos[2];
              end;
              CreateUniversalJoint(newLink, Solid1, Solid2, posX, posY, posZ, axisX, axisY, axisZ, axis2X, axis2Y, axis2Z);
              SetUniversalLimits(newLink, LimitMin, LimitMax, Limit2Min, Limit2Max);

              if Friction.Fc > 0 then begin
                dJointSetUniversalParam(newLink.joint, dParamVel , 0);
                dJointSetUniversalParam(newLink.joint, dParamFMax, Friction.Fc);
              end;

              if Friction2.Fc > 0 then begin
                dJointSetUniversalParam(newLink.joint, dParamVel2 , 0);
                dJointSetUniversalParam(newLink.joint, dParamFMax2, Friction2.Fc);
              end;

              newAxis := TAxis.Create;
              Robot.Axes.Add(newAxis);
              newAxis.ParentLink := newLink;
              newAxis.Friction := Friction2;
              newAxis.Spring := Spring2;
              newAxis.Motor := Motor2;
              newAxis.canWrap := AxisCanWrap2;
              newLink.Axis[1] := newAxis;

              if aGL.height > 0 then begin
                newAxis.GLCreateCylinder(OdeScene, aGL.Radius, aGL.height);
                (newAxis.GLObj as TGLSceneObject).Material.FrontProperties.Diffuse.AsWinColor := aGL.color;
                newAxis.GLSetPosition;
                newAxis.GLObj.TagObject := newAxis;
              end;
            end;

            if (LinkType = 'Hinge') or (LinkType ='Universal') or (LinkType ='Slider') or (LinkType ='Fixed') or (LinkType ='Ball') then begin
              newAxis := TAxis.Create;
              Robot.Axes.Add(newAxis);
              newAxis.ParentLink := newLink;
              newAxis.Friction := Friction;
              newAxis.Spring := Spring;
              newAxis.Motor := Motor;
              newAxis.canWrap := AxisCanWrap;
              newLink.Axis[0] := newAxis;
            end;

            if aGL.height > 0 then begin
              newAxis.GLCreateCylinder(OdeScene, aGL.Radius, aGL.height);
              (newAxis.GLObj as TGLSceneObject).Material.FrontProperties.Diffuse.AsWinColor := aGL.color;
              newAxis.GLSetPosition;
              newAxis.GLObj.TagObject := newAxis;
            end else if aGL.radius > 0 then begin
              newAxis.GLCreateBall(OdeScene, aGL.Radius);
              (newAxis.GLObj as TGLSceneObject).Material.FrontProperties.Diffuse.AsWinColor := aGL.color;
              newAxis.GLSetPosition;
              newAxis.GLObj.TagObject := newAxis;
            end;

            if newLink <> nil then begin
              newLink.ID := IDValue;
              newLink.description := IDValue;
            end;
          end;
        end;
      end;

    end;

    JointNode := JointNode.NextSibling;
  end;

end;

function LoadXML(XMLFile: string; ErrorList: TStringList): IXMLDocument;
var XML: IXMLDocument;
    err, sep: string;
begin
  result := nil;
  XML:=CreateXMLDoc;
  XML.Load(XMLFile);
  if XML.ParseError.Reason <> '' then begin
    //with FParams.MemoDebug.Lines do begin
      //Add('XML file error:' + XMLFile);
      //Add(XML.ParseError.Reason);
    //end;
    if ErrorList <> nil then begin
      sep := #$0d+#$0A;
    end else begin
      sep := ' ';
    end;

    err := '[XML error] ' + format('%s(%d): ', [XMLFile, XML.ParseError.Line]) + sep
    //err := format('%s(%d): ', [XMLFile, XML.ParseError.Line]) + #$0d+#$0A
           + format('"%s": ',[trim(XML.ParseError.SrcText)]) + sep
           + XML.ParseError.Reason ;

    if ErrorList <> nil then begin
      ErrorList.Add(err);
    end else begin
      showmessage(err);
    end;
    exit;
  end;
  result := XML;
end;


procedure TWorld_ODE.SaveJointWayPointsToXML(XMLFile: string; r: integer);
var XML: IXMLDocument;
    root, node, prop: IXMLElement;
    PI: IXMLProcessingInstruction;
    wp_idx, j, axis_idx: integer;
    eps: double;
begin
  if (r < 0) or (r >= Robots.Count) then exit;
  if Robots[r].Axes.Count = 0 then exit;

  XML := CreateXMLDoc;
  //PI := XML.CreateProcessingInstruction('xml', 'version="1.0" encoding="UTF-8"');
  PI := XML.CreateProcessingInstruction('xml', 'version="1.0"');
  XML.InsertBefore(PI, XML.DocumentElement);

  root := XML.CreateElement('joint_waypoints');
  XML.DocumentElement := root;
  for wp_idx := 0 to Robots[r].AxesWayPointsIDs.Count - 1 do begin
    //  <state ID='1' final_time='1'>
    node := XML.CreateElement('state');
    node.SetAttribute('ID', Robots[r].AxesWayPointsIDs[wp_idx]);
    node.SetAttribute('final_time', format('%g',[Robots[r].Axes[0].WayPoints[wp_idx].t]));
    root.AppendChild(node);

    eps := 1e-8;
    for j := 0 to Robots[r].Axes.Count -1 do begin
      with Robots[r].Axes[j] do begin
        if wp_idx > 0 then begin
          if (abs(WayPoints[wp_idx - 1].pos - WayPoints[wp_idx].pos) < eps) and
             (abs(WayPoints[wp_idx - 1].speed - WayPoints[wp_idx].speed) < eps) then continue;
        end;
        //  <joint ID='0' axis='1' theta='0' w='0'/>
        prop := XML.CreateElement('joint');
        prop.SetAttribute('ID', ParentLink.ID);

        // Find which axis is this
        axis_idx := 0;
        while axis_idx < MaxAxis do begin
          if ParentLink.Axis[axis_idx] = Robots[r].Axes[j] then break;
          inc(axis_idx);
        end;
        if axis_idx <> 0 then
          prop.SetAttribute('axis', format('%d',[axis_idx + 1]));

        prop.SetAttribute('theta', format('%g',[radtodeg(WayPoints[wp_idx].pos)]));
        prop.SetAttribute('w', format('%g',[radtodeg(WayPoints[wp_idx].speed)]));
        node.AppendChild(prop);
      end;
    end;
  end;
  XML.Save(XMLFile, ofIndent);
end;

procedure TWorld_ODE.LoadJointWayPointsFromXML(XMLFile: string; r: integer);
var XML: IXMLDocument;
    root, node, prop: IXMLNode;
    ang, speed, final_time: double;
    i, j, axis_idx: integer;
    jointID, trajID: string;
    NewPoint: TAxisTraj;
    way_point_idx: integer;
begin
  if (r < 0) or (r >= Robots.Count) then exit;

  ang := 0;
  speed := 0;

{  XML:=CreateXMLDoc;
  XML.Load(XMLFile);
  if XML.ParseError.Reason<>'' then begin
    exit;
  end;}
  XML := LoadXML(XMLFile, XMLErrors);
  if XML = nil then exit;

  root:=XML.SelectSingleNode('/joint_waypoints');
  if root = nil then exit;

  node := root.FirstChild;
  while node <> nil do begin
    if node.NodeName = 'state' then begin

      trajID := GetNodeAttrStr(node, 'ID', '');
      final_time := GetNodeAttrReal(node, 'final_time', 0);

      prop := node.FirstChild;
      while prop <> nil do begin
        // default values
        ang := 0; speed := 0;
        axis_idx := 1;

        if prop.NodeName = 'joint' then begin
          jointID := GetNodeAttrStr(prop, 'ID', '-1');
          axis_idx := GetNodeAttrInt(prop, 'axis', axis_idx) - 1;
          ang := DegToRad(GetNodeAttrReal(prop, 'theta', ang));
          speed := DegToRad(GetNodeAttrReal(prop, 'w', speed));

          i :=  Robots[r].Links.IndexOf(jointID);
          if i >= 0 then begin
            if Robots[r].Links[i].Axis[axis_idx] <> nil then begin
              // Create and insert the point
              NewPoint := TAxisTraj.Create;
              NewPoint.pos := ang;
              NewPoint.speed := speed;
              NewPoint.t := final_time;
              Robots[r].Links[i].Axis[axis_idx].WayPoints.Add(NewPoint)
            end;
          end;
        end;

        prop := prop.NextSibling;
      end;

      WorldODE.Robots[r].AxesWayPointsIDs.Add(trajID);
      // insert the remaining points that weren't specified in this state
      for i := 0 to Robots[r].Axes.Count -1 do begin
        way_point_idx := Robots[r].Axes[i].WayPoints.Count -1;
        if (way_point_idx >= 0) then begin
          if abs(Robots[r].Axes[i].WayPoints[way_point_idx].t - final_time) < 1e-5 then
            continue;

          ang := Robots[r].Axes[i].WayPoints[way_point_idx].pos;
          speed := Robots[r].Axes[i].WayPoints[way_point_idx].speed;
        end else begin
          ang := 0;
          speed := 0;
        end;
        // Create and insert the point
        NewPoint := TAxisTraj.Create;
        NewPoint.pos := ang;
        NewPoint.speed := speed;
        NewPoint.t := final_time;
        Robots[r].Axes[i].WayPoints.Add(NewPoint)
      end;
    end;

    node := node.NextSibling;
  end;

  FParams.ComboWayPointNameUpdate(Robots[r]);

  for i := 0 to Robots[r].Links.Count -1 do begin
    for j := 0 to Robots[r].Links[i].Axis[0].WayPoints.Count -1 do begin
      with Robots[r].Links[i].Axis[0].WayPoints[j] do
        FParams.MemoDebug.Lines.Add(format('[%d,%d] %.2f: %.2f %.2f',[i,j, t, pos, speed]));
    end;
  end;

end;

{  TSolidDef = record
    ID: string;
    sizeX, sizeY, SizeZ, radius: double;
    posX, posY, posZ: double;
    angX, angY, angZ: double;  // XYZ seq
  end;}

procedure TWorld_ODE.SolidDefSetDefaults(var SolidDef: TSolidDef);
begin
  // default values
  with SolidDef do begin
    ID := '';
    sizeX := 1; sizeY := 1; sizeZ := 1;
    posX := 0; posY := 0; posZ := 0;
    angX := 0; angY := 0; angZ := 0;
    radius := 0;
  end;
end;



function TWorld_ODE.SolidDefProcessXMLNode(var SolidDef: TSolidDef; prop: IXMLNode; Parser: TSimpleParser): boolean;
begin
  with SolidDef do begin
    result := true;
    if prop.NodeName = 'ID' then begin
      ID := GetNodeAttrStr(prop, 'name', ID);
      ID := GetNodeAttrStr(prop, 'value', ID);
    end else if prop.NodeName = 'size' then begin
      sizeX := GetNodeAttrRealParse(prop, 'x', sizeX, Parser);
      sizeY := GetNodeAttrRealParse(prop, 'y', sizeY, Parser);
      sizeZ := GetNodeAttrRealParse(prop, 'z', sizeZ, Parser);
      sizeX := GetNodeAttrRealParse(prop, 'radius', sizeX, Parser);
    end else if prop.NodeName = 'radius' then begin
      radius := GetNodeAttrRealParse(prop, 'value', radius, Parser);
    end else if prop.NodeName = 'pos' then begin
      posX := GetNodeAttrRealParse(prop, 'x', posX, Parser);
      posY := GetNodeAttrRealParse(prop, 'y', posY, Parser);
      posZ := GetNodeAttrRealParse(prop, 'z', posZ, Parser);
    end else if prop.NodeName = 'rot_deg' then begin
      angX := degToRad(GetNodeAttrRealParse(prop, 'x', angX, Parser));
      angY := degToRad(GetNodeAttrRealParse(prop, 'y', angY, Parser));
      angZ := degToRad(GetNodeAttrRealParse(prop, 'z', angZ, Parser));
    end else begin
      result := false;
    end;
  end;
end;



procedure TWorld_ODE.LoadObstaclesFromXML(XMLFile: string; OffsetDef: TSolidDef; Parser: TSimpleParser);
var XML: IXMLDocument;
    root, obstacle, prop: IXMLNode;
    SolidDef: TSolidDef;
    //sizeX, sizeY, sizeZ, posX, posY, posZ, angX, angY, angZ: double;
    colorR, colorG, colorB: double;
    //prefixID : string;

    TextureName: string;
    TextureScale: double;
    transparency: double;
    R, Roff, RFinal: TdMatrix3;
    Vec: TDVector3;
    NewObstacle: TSolid;

    Surf: TdSurfaceParameters; //TOD=: unify with solids
begin
  XML := LoadXML(XMLFile, XMLErrors);
  if XML = nil then exit;

  root:=XML.SelectSingleNode('/obstacles');
  if root = nil then exit;

  obstacle := root.FirstChild;
  while obstacle <> nil do begin
    if obstacle.NodeName = 'defines' then begin
      LoadDefinesFromXML(Parser, obstacle);
    end;
    if pos(obstacle.NodeName, 'cuboid<>sphere') <> 0 then begin
    //if obstacle.NodeName = 'cuboid' then begin
      prop := obstacle.FirstChild;
      // default values
      SolidDefSetDefaults(SolidDef);
      colorR := 128/255; colorG := 128/255; colorB := 128/255;
      TextureName := ''; TextureScale := 1;
      transparency := 1;

      Surf.mu := -1; Surf.mu2 := -1;
      Surf.soft_cfm := 1e-5;
      //Surf.soft_erp := 0.2;
      Surf.bounce := 0; Surf.bounce_vel := 0;

      while prop <> nil do begin
        SolidDefProcessXMLNode(SolidDef, prop, Parser);
        if prop.NodeName = 'color_rgb' then begin
          colorR := GetNodeAttrInt(prop, 'r', 128)/255;
          colorG := GetNodeAttrInt(prop, 'g', 128)/255;
          colorB := GetNodeAttrInt(prop, 'b', 128)/255;
        end;
        if prop.NodeName = 'texture' then begin
          TextureName := GetNodeAttrStr(prop, 'name', TextureName);
          TextureScale := GetNodeAttrRealParse(prop, 'scale', TextureScale, Parser);
        end;
        if prop.NodeName = 'transparency' then begin
          transparency := GetNodeAttrRealParse(prop, 'alpha', transparency, Parser);
        end;
        if prop.NodeName = 'surface' then begin
          Surf.mu := GetNodeAttrRealParse(prop, 'mu', Surf.mu, Parser);
          Surf.mu2 := GetNodeAttrRealParse(prop, 'mu2', Surf.mu2, Parser);
          Surf.soft_cfm := GetNodeAttrRealParse(prop, 'softness', Surf.soft_cfm, Parser);
          Surf.bounce := GetNodeAttrRealParse(prop, 'bounce', Surf.bounce, Parser);
          Surf.bounce_vel := GetNodeAttrRealParse(prop, 'bounce_tresh', Surf.bounce_vel, Parser);
        end;
        prop := prop.NextSibling;
      end;
      // Create and position the obstacle
      NewObstacle := TSolid.Create;
      Obstacles.Add(NewObstacle);
      with SolidDef do begin
        if ID = '' then begin
          NewObstacle.ID := format('Obstacle at (%.1f, %.1f, %.1f)',[posX, posY, posZ]);
        end else begin
          NewObstacle.ID := OffsetDef.ID + ID;
        end;
        if obstacle.NodeName = 'cuboid' then begin
          CreateBoxObstacle(NewObstacle, sizeX, sizeY, sizeZ, posX, posY, posZ);
        end else if obstacle.NodeName = 'sphere' then begin
          CreateSphereObstacle(NewObstacle, radius, posX, posY, posZ);
        end;

        if Surf.mu >= 0 then begin
          NewObstacle.ParSurface.mode := $FF;
          NewObstacle.ParSurface.mu := Surf.mu;
          if Surf.mu2 >= 0 then NewObstacle.ParSurface.mu2 := Surf.mu2;
          NewObstacle.ParSurface.soft_cfm := Surf.soft_cfm;
          NewObstacle.ParSurface.bounce := Surf.bounce;
          NewObstacle.ParSurface.bounce_vel := Surf.bounce_vel;
        end;

        RFromZYXRotRel(R, angX, angY, AngZ);
        dGeomSetRotation(NewObstacle.Geom, R);  // Set local rotation

        RFromZYXRotRel(Roff, OffsetDef.angX, OffsetDef.angY, OffsetDef.AngZ);
        dMULTIPLY0_333(RFinal, R, Roff);        // Global rotation changes the position
        dMULTIPLY0_331(Vec, Roff, dGeomGetPosition(NewObstacle.Geom)^);
        dGeomSetPosition(NewObstacle.Geom, Vec[0] + OffsetDef.posX, Vec[1] + OffsetDef.posY, Vec[2] + OffsetDef.posZ);

        dGeomSetRotation(NewObstacle.Geom, RFinal); // And the orientation
      end;
      if TextureName <> '' then begin
        NewObstacle.SetTexture(TextureName, TextureScale); //'LibMaterialFeup'
      end;
      NewObstacle.SetColor(colorR, colorG, colorB, transparency);
      PositionSceneObject(NewObstacle.GLObj, NewObstacle.Geom);
    end;

    obstacle := obstacle.NextSibling;
  end;

end;


procedure TWorld_ODE.LoadSensorsFromXML(Robot: TRobot; const root: IXMLNode; Parser: TSimpleParser);
var sensor, prop: IXMLNode;
    IDValue: string;
    SLen, SInitialWidth, SFinalWidth, posX, posY, posZ, angX, angY, angZ: double;
    Noise: TSensorNoise;
    colorR, colorG, colorB: double;
    R: TdMatrix3;
    newSensor: TSensor;

    MotherSolidId: string;
    MotherSolid: TSolid;
    MotherBody: PdxBody;
    MotherGLObj : TGLBaseSceneObject;

    SolidIdx: integer;
    AbsoluteCoords: boolean;
    stags, s: string;
    st : TStringList;
    sensor_period: double;
    newRay: TSensorRay;
    BeamAngle, md: double;
    i, row, col, side, NumRays: integer;
    fmax, k1, k2: double;
    MaxDist, MinDist, StartAngle, EndAngle: double;
begin
  if root = nil then exit;

  st := TStringList.Create;
  try
  sensor := root.FirstChild;
  while sensor <> nil do begin
    if (sensor.NodeName = 'IR') or
       (sensor.NodeName = 'IRSharp') or
       (sensor.NodeName = 'capacitive') or
       (sensor.NodeName = 'inductive') or
       (sensor.NodeName = 'floorline') or
       (sensor.NodeName = 'ranger2d') or
       (sensor.NodeName = 'pentip') or
       (sensor.NodeName = 'imu') or
       (sensor.NodeName = 'solenoid') or
       (sensor.NodeName = 'RFID') or
       (sensor.NodeName = 'beacon') then begin
      // default values
      IDValue := '';
      MotherSolidId := '';
      SLen := 0.8; SInitialWidth := 0.01; SFinalWidth := 0.015;
      AbsoluteCoords := false;
      with Noise do begin
        var_k := 0; var_d := 0; offset := 0; gain := 1; active := false;
        std_a := 0; std_p := 0;
      end;
      posX := 0; posY := 0; posZ := 0;
      angX := 0; angY := 0; angZ := 0;
      colorR := 128/255; colorG := 128/255; colorB := 128/255;
      stags := '';
      sensor_period := 0.01;
      BeamAngle := rad(30);
      NumRays := 9;
      fmax := 1; k1 := 0; k2 := 1;
      MaxDist := 1;
      MinDist := 0;
      StartAngle := rad(-90);
      EndAngle := rad(90);

      prop := sensor.FirstChild;
      while prop <> nil do begin
        if prop.NodeName = 'ID' then begin
          IDValue := GetNodeAttrStr(prop, 'value', IDValue);
          IDValue := GetNodeAttrStr(prop, 'name', IDValue);
        end;
        if prop.NodeName = 'absolute_coords' then begin
          AbsoluteCoords := true;
        end;
        if prop.NodeName = 'solid' then begin
          MotherSolidId := GetNodeAttrStr(prop, 'id', MotherSolidId);
        end;
        if prop.NodeName = 'beam' then begin
          SLen := GetNodeAttrRealParse(prop, 'length', SLen, Parser);
          SInitialWidth := GetNodeAttrRealParse(prop, 'initial_width', SInitialWidth, Parser);
          SFinalWidth := GetNodeAttrRealParse(prop, 'final_width', SFinalWidth, Parser);
          BeamAngle := rad(GetNodeAttrRealParse(prop, 'angle', deg(BeamAngle), Parser));
          NumRays := round(GetNodeAttrRealParse(prop, 'rays', NumRays, Parser));
        end;
        if prop.NodeName = 'pos' then begin
          posX := GetNodeAttrRealParse(prop, 'x', posX, Parser);
          posY := GetNodeAttrRealParse(prop, 'y', posY, Parser);
          posZ := GetNodeAttrRealParse(prop, 'z', posZ, Parser);
        end;
        if prop.NodeName = 'rot_deg' then begin
          angX := degToRad(GetNodeAttrRealParse(prop, 'x', angX, Parser));
          angY := degToRad(GetNodeAttrRealParse(prop, 'y', angY, Parser));
          angZ := degToRad(GetNodeAttrRealParse(prop, 'z', angZ, Parser));
        end;
        if prop.NodeName = 'noise' then with Noise do begin
          active := true;  // if the tag 'noise' is present then it is active
          var_k := GetNodeAttrRealParse(prop, 'var_k', var_k, Parser);
          var_d := GetNodeAttrRealParse(prop, 'var_d', var_d, Parser);
          offset := GetNodeAttrRealParse(prop, 'offset', offset, Parser);
          gain := GetNodeAttrRealParse(prop, 'gain', gain, Parser);
          std_a := GetNodeAttrRealParse(prop, 'stdev', std_a, Parser);
          std_p := GetNodeAttrRealParse(prop, 'stdev_p', std_p, Parser);
        end;
        if prop.NodeName = 'tag' then begin
          //stags := stags + ';' + prop.Text;
          s := GetNodeAttrStr(prop, 'value', '');
          //if s <> '' then stags := stags + ';' + s;
          if s <> '' then st.Add(s);
        end;
        if prop.NodeName = 'period' then begin
          sensor_period := GetNodeAttrRealParse(prop, 'value', sensor_period, Parser);
        end;
        if prop.NodeName = 'force' then begin
          fmax := GetNodeAttrRealParse(prop, 'fmax', fmax, Parser);
          k1 := GetNodeAttrRealParse(prop, 'k1', k1, Parser);
          k2 := GetNodeAttrRealParse(prop, 'k2', k2, Parser);
        end;
        if prop.NodeName = 'color_rgb' then begin
          colorR := GetNodeAttrInt(prop, 'r', 128)/255;
          colorG := GetNodeAttrInt(prop, 'g', 128)/255;
          colorB := GetNodeAttrInt(prop, 'b', 128)/255;
        end;
        prop := prop.NextSibling;
      end;
      // Create and position the sensor
      if sensor.NodeName = 'ranger2d' then begin
        newSensor := TSensor.Create(NumRays);
      end else begin
        newSensor := TSensor.Create;
      end;

      newSensor.ID := IDValue;
      newSensor.kind := skGeneric;
      if sensor.NodeName = 'IRSharp' then newSensor.kind := skIRSharp
      else if sensor.NodeName = 'capacitive' then newSensor.kind := skCapacitive
      else if sensor.NodeName = 'inductive' then newSensor.kind := skInductive
      else if sensor.NodeName = 'beacon' then newSensor.kind := skBeacon
      else if sensor.NodeName = 'floorline' then newSensor.kind := skFloorLine
      else if sensor.NodeName = 'pentip' then newSensor.kind := skPenTip
      else if sensor.NodeName = 'ranger2d' then newSensor.kind := skRanger2D
      else if sensor.NodeName = 'imu' then newSensor.kind := skIMU
      else if sensor.NodeName = 'solenoid' then newSensor.kind := skSolenoid
      else if sensor.NodeName = 'RFID' then newSensor.kind := skRFID;

      //newSensor.Tags.Delimiter := ';';
      //newSensor.Tags.DelimitedText := stags;
      newSensor.Tags.AddStrings(st);

      newSensor.Noise := Noise;
      newSensor.Period := sensor_period;
      newSensor.Fmax := fmax;
      newSensor.k1 := k1;
      newSensor.k2 := k2;

      Sensors.Add(newSensor);

      if Robot <> nil then begin // It is a Robot sensor
        Robot.Sensors.Add(newSensor);

        SolidIdx := Robot.Solids.IndexFromID(MotherSolidId);
        if SolidIdx = -1 then  begin
          MotherSolid := Robot.MainBody;
        end else begin
          MotherSolid := Robot.Solids[SolidIdx];
        end;
        MotherBody := MotherSolid.Body;
        MotherGLObj := MotherSolid.GLObj;

      end else begin // It is a global sensor
        MotherBody := nil;
        MotherGLObj := ODEScene;
      end;

      if newSensor.kind in [skIRSharp, skCapacitive, skInductive, skPenTip, skIMU, skSolenoid, skRFID] then begin
        newRay := CreateOneRaySensor(MotherBody, newSensor, SLen);
        newRay.Place(posX, posY, posZ, angX, angY, AngZ, AbsoluteCoords);
        CreateSensorBeamGLObj(newSensor, SLen, SInitialWidth, SFinalWidth);
        if newSensor.kind = skIMU then begin // No collisions for the IMU  (???)
          dGeomDisable(newRay.Geom);
        end;
      end else if newSensor.kind in [skBeacon] then begin
        CreateSensorBody(newSensor, MotherGLObj, 0.1, 0.02, posX, posY, posZ);
      end else if newSensor.kind in [skFloorLine] then begin
        side := round(sqrt(NumRays));
        for col := 0 to side - 1 do begin
          for row := 0 to side - 1 do begin
            newRay := CreateOneRaySensor(MotherBody, newSensor, SLen); //TODO: beamangle
            newRay.Place(posX + (row - (side - 1) /2) * SFinalWidth/2,
                         posY + (col - (side - 1) /2) * SFinalWidth/2, posZ, angX, angY, AngZ, AbsoluteCoords);
          end;
        end;
        CreateSensorBeamGLObj(newSensor, SLen, SInitialWidth, SFinalWidth);
      end else if newSensor.kind in [skRanger2D] then begin
        newSensor.MaxDist := MaxDist;
        newSensor.MinDist := MinDist;
        newSensor.StartAngle := - BeamAngle / 2;
        newSensor.EndAngle := BeamAngle / 2;

        NumRays := max(3, NumRays);
        for i := 0 to NumRays - 1 do begin
          newRay := CreateOneRaySensor(MotherBody, newSensor, SLen);
          md := (NumRays - 1) / 2;
          newRay.Place(posX, posY, posZ, angX, angY, AngZ + 0.5 * BeamAngle *(i - md)/md, AbsoluteCoords);
          //GeomDisable(NewRay.Geom);
        end;
        //CreateSensorRanger2dGLObj(newSensor);
        CreateSensorBeamGLObj(newSensor, SLen, SInitialWidth, SFinalWidth);
      end;

      newSensor.SetColor(colorR, colorG, colorB);
    end;

    sensor := sensor.NextSibling;
  end;



  finally
  st.Free;
  end;

end;

procedure TWorld_ODE.ReadFrictionFromXMLNode(var Friction: TFriction; sufix: string; const prop: IXMLNode; Parser: TSimpleParser);
begin
  with Friction do begin
    if prop.NodeName = 'friction' + sufix then begin
      Bv := GetNodeAttrRealParse(prop, 'bv', Bv, Parser);
      Fc := GetNodeAttrRealParse(prop, 'fc', Fc, Parser);
      //CoulombLimit := GetNodeAttrReal(prop, 'coulomblimit', CoulombLimit);
    end;
  end;
end;

procedure TWorld_ODE.ReadSpringFromXMLNode(var Spring: TSpring; sufix: string; const prop: IXMLNode; Parser: TSimpleParser);
begin
  with Spring do begin
    if prop.NodeName = 'spring' + sufix then begin
      K := GetNodeAttrRealParse(prop, 'k', K, Parser);
      ZeroPos := degtorad(GetNodeAttrRealParse(prop, 'zeropos', ZeroPos, Parser));
    end;
  end;
end;


procedure TWorld_ODE.ReadMotorFromXMLNode(var Motor: TMotor; sufix: string; const prop: IXMLNode; Parser: TSimpleParser);
var str: string;
begin
  with Motor do begin
    if prop.NodeName = 'motor' + sufix then begin
      Ri := GetNodeAttrRealParse(prop, 'ri', Ri, Parser);
      Li := GetNodeAttrRealParse(prop, 'li', Li, Parser);
      Ki := GetNodeAttrRealParse(prop, 'ki', Ki, Parser);
      Vmax := GetNodeAttrRealParse(prop, 'vmax', Vmax, Parser);
      Controller.y_sat := Vmax;
      Imax := GetNodeAttrRealParse(prop, 'imax', Imax, Parser);
      active := GetNodeAttrBool(prop, 'active', active);
      simple := GetNodeAttrBool(prop, 'simple', simple);

    end else if prop.NodeName = 'rotor' + sufix then begin
      JRotor := GetNodeAttrRealParse(prop, 'J', JRotor, Parser);
      JRotor := GetNodeAttrRealParse(prop, 'j', JRotor, Parser);
      BRotor := GetNodeAttrRealParse(prop, 'bv', BRotor, Parser);
      QRotor := GetNodeAttrRealParse(prop, 'fc', QRotor, Parser);

    end else if prop.NodeName = 'gear' + sufix then begin
      GearRatio := GetNodeAttrRealParse(prop, 'ratio', GearRatio, Parser);
      KGearBox  := GetNodeAttrRealParse(prop, 'ke', KGearBox, Parser);
      BGearBox  := GetNodeAttrRealParse(prop, 'bv', BGearBox, Parser);
      KGearBox2 := GetNodeAttrRealParse(prop, 'ke2', KGearBox, Parser);
      BGearBox2 := GetNodeAttrRealParse(prop, 'kv2', BGearBox, Parser);

    end else if prop.NodeName = 'encoder' + sufix then begin
      Encoder.PPR := GetNodeAttrInt(prop, 'ppr', Encoder.PPR);
      Encoder.NoiseMean := GetNodeAttrRealParse(prop, 'mean', Encoder.NoiseMean, Parser);
      Encoder.NoiseStDev := GetNodeAttrRealParse(prop, 'stdev', Encoder.NoiseStDev, Parser);

    end else if prop.NodeName = 'controller' + sufix then begin
      with Controller do begin
        Kp := GetNodeAttrRealParse(prop, 'kp', Kp, Parser);
        Ki := GetNodeAttrRealParse(prop, 'ki', Ki, Parser);
        Kd := GetNodeAttrRealParse(prop, 'kd', Kd, Parser);
        Kf := GetNodeAttrRealParse(prop, 'kf', Kf, Parser);
        //Y_sat := GetNodeAttrRealParse(prop, 'ysat', Y_sat, Parser);
        controlPeriod := GetNodeAttrRealParse(prop, 'period', 1000 * controlPeriod, Parser)/1000;
        str := GetNodeAttrStr(prop, 'mode', 'pidspeed');
        if str = 'pidspeed' then ControlMode := cmPIDSpeed
        else if str = 'pidposition' then ControlMode := cmPIDPosition
        else if str = 'state' then ControlMode := cmState;
        active := GetNodeAttrBool(prop, 'active', active);
      end;
    end;
  end;
end;

procedure TWorld_ODE.LoadWheelsFromXML(Robot: TRobot; const root: IXMLNode; Parser: TSimpleParser);
var wheelnode, prop: IXMLNode;
    //offX, offY, offZ,
    angX, angY, angZ: double;
    //R, Rx, Ry, Rz, Ryx: TdMatrix3;
    newWheel: TWheel;
    Pars, DefPars: TWheelPars;
    Friction, DefFriction: TFriction;
    Motor, DefMotor: TMotor;
    RGB, DefRGB: TRGBfloat;
    ID: string;
begin
  if root = nil then exit;

  // Initialize default parameters
  with DefPars do begin
    offsetX := 0;
    offsetY := 0;
    offsetZ := 0;
    Radius := 0.09;
    Width := 0.03;
    mass := 0.13;
    CenterDist := 0.2;
    Mu := 1;
    Mu2:= 0.001;
    soft_cfm := 0.001;
    Omni := false;
  end;

  with DefMotor do begin
    active := true;
    Encoder.PPR := 1000;
    Encoder.NoiseMean := 0;
    Encoder.NoiseStDev := -1;
    Ri := 1;
    Li := 0;
    Ki := 1.4e-2;
    Imax := 4;
    Vmax := 24;
    GearRatio := 10;

    GearRatio := 10;

    JRotor := 0;
    BRotor := 1e-3;

    KGearBox := 5e-1 / Motor.GearRatio;
    BGearBox := 1e-1 / Motor.GearRatio;

    KGearBox2 := 0;
    BGearBox2 := 0;

    Controller.active := false;
    //Controller.active := true;
    with Controller do begin
      Kp := 0.5;
      Ki := 0;
      Kd := 0;
      Kf := 0.5;
      Y_sat := 24;
      ticks := 0;
      Sek := 0;
      controlPeriod := 10;
      ControlMode := cmPIDSpeed;
    end;
  end;

  with DefFriction do begin
    Bv := 1e-5;
    Fc := 1e-3;
//    CoulombLimit := 1e-2;
  end;

  with RGB do begin
    R := 128/255;
    G := 128/255;
    B := 128/255;
  end;

{ <wheel>
    <omni/>
*    <tyre mass='0.1' radius='0.1' width='0.01' centerdist='0.015'/>
*    <axis angle='-90'/>
*    <motor ri='0' ki='0.3' vmax='0' imax='0' active='1'/>
*    <gear ratio='10'/>
    <friction bv='0' fc='0' coulomblimit='0'/>
-    <encoder ppr='1000' mean='0' stdev='0'/>
*    <controller type='PIDspeed' ki='1' ki='0' kd='0.1' kf='1' active='1' period='10'/>
*    <color_rgb r='128' g='0' b='0'/>
  </wheel> }

  wheelnode := root.FirstChild;
  while wheelnode <> nil do begin
    if (wheelnode.NodeName = 'wheel') or (wheelnode.NodeName = 'default') then begin
      // default values
      //offX := 0; offY := 0; offZ := 0;
      angX := 0; angY := 0; angZ := 0;
      Pars := DefPars;
      Friction := DefFriction;
      Motor := DefMotor;
      RGB := DefRGB;
      ID := 'W';

      prop := wheelnode.FirstChild;
      while prop <> nil do begin
        if prop.NodeName = 'ID' then begin
          ID := GetNodeAttrStr(prop, 'value', ID);
        end;
        if prop.NodeName = 'omni' then begin
          Pars.omni := true;
        end;
        if prop.NodeName = 'tyre' then begin
          Pars.mass := GetNodeAttrRealParse(prop, 'mass', Pars.mass, Parser);
          Pars.Radius := GetNodeAttrRealParse(prop, 'radius', Pars.Radius, Parser);
          Pars.Width := GetNodeAttrRealParse(prop, 'width', Pars.Width, Parser);
          Pars.CenterDist := GetNodeAttrRealParse(prop, 'centerdist', Pars.CenterDist, Parser);
          //Pars.Mu := GetNodeAttrReal(prop, 'mu', Pars.mu);
          //Pars.Mu2 := GetNodeAttrReal(prop, 'mu2', Pars.mu2);
        end;

        if prop.NodeName = 'surface' then begin
          Pars.Mu := GetNodeAttrRealParse(prop, 'mu', Pars.mu, Parser);
          Pars.Mu2 := GetNodeAttrRealParse(prop, 'mu2', Pars.mu2, Parser);
          Pars.soft_cfm := GetNodeAttrRealParse(prop, 'softness', Pars.soft_cfm, Parser);
        end;

        ReadFrictionFromXMLNode(Friction, '', prop, Parser);

        ReadMotorFromXMLNode(Motor, '', prop, Parser);

        if prop.NodeName = 'offset' then begin
          Pars.offsetX := GetNodeAttrRealParse(prop, 'x', Pars.offsetX, Parser);
          Pars.offsetY := GetNodeAttrRealParse(prop, 'y', Pars.offsetY, Parser);
          Pars.offsetZ := GetNodeAttrRealParse(prop, 'z', Pars.offsetZ, Parser);
        end;

        if prop.NodeName = 'axis' then begin
          angX := degToRad(GetNodeAttrRealParse(prop, 'x', angX, Parser));
          angY := degToRad(GetNodeAttrRealParse(prop, 'y', angY, Parser));
          angZ := degToRad(GetNodeAttrRealParse(prop, 'angle', angZ, Parser));
        end;

        if prop.NodeName = 'color_rgb' then begin
          RGB.R := GetNodeAttrInt(prop, 'r', 128)/255;
          RGB.G := GetNodeAttrInt(prop, 'g', 128)/255;
          RGB.B := GetNodeAttrInt(prop, 'b', 128)/255;
        end;
        prop := prop.NextSibling;
      end;

      Pars.Angle := angZ;
      if wheelnode.NodeName = 'default' then begin
        // Set the new default wheel
        DefPars := Pars;
        DefFriction := Friction;
        DefMotor := Motor;
        DefRGB := RGB;
      end else begin
        // Create and position the wheel
        newWheel := TWheel.Create;
        Robot.Wheels.Add(newWheel);
        CreateWheel(Robot, newWheel, Pars, Friction, Motor);
        newWheel.Tyre.SetTexture('MatBumps', 4); //TODO
        if ID = 'W' then begin
          newWheel.Axle.ID := ID + inttostr(Robot.Wheels.Count);
        end else begin
          newWheel.Axle.ID := ID;
        end;
      end;

    end;

    wheelnode := wheelnode.NextSibling;
  end;

end;


procedure TWorld_ODE.LoadShellsFromXML(Robot: TRobot; const root: IXMLNode; Parser: TSimpleParser);
var ShellNode, prop: IXMLNode;
    sizeX, sizeY, sizeZ, posX, posY, posZ, angX, angY, angZ: double;
    mass, radius: double;
    colorR, colorG, colorB: double;
    R: TdMatrix3;
    newShell: TSolid;
    MotherSolidId: string;
    MotherSolid: TSolid;
    SolidIdx: integer;
    IDValue: string;
    CompMass, NewMass: TdMass;
    PGeomPos: PdVector3;
    i: integer;
    MatterProps: TMatterProperties;
    Surf: TdSurfaceParameters;
    focalLength: double;
    decimation: integer;
    actRemGLCamera: TGLCamera;
    transparency: double;
begin
  if root = nil then exit;

  ShellNode := root.FirstChild;
  while ShellNode <> nil do begin
    if pos(ShellNode.NodeName, 'cuboid<>cylinder<>sphere<>camera') <> 0 then begin
      prop := ShellNode.FirstChild;
      // default values
      mass := 0;
      sizeX := 1; sizeY := 1; sizeZ := 1;
      radius := 1;
      IDValue := '';
      posX := 0; posY := 0; posZ := 0;
      angX := 0; angY := 0; angZ := 0;
      colorR := 128/255; colorG := 128/255; colorB := 128/255;
      MatterProps := [];

      Surf.mu := -1; Surf.mu2 := -1;
      Surf.soft_cfm := 1e-5;
      //Surf.soft_erp := 0.2;
      Surf.bounce := 0; Surf.bounce_vel := 0;

      focalLength := 50;
      decimation := 4;
      MotherSolidId := '';
      transparency := 1;
      while prop <> nil do begin
        if prop.NodeName = 'ID' then begin
          IDValue := GetNodeAttrStr(prop, 'value', IDValue);
        end;
        if prop.NodeName = 'solid' then begin
          MotherSolidId := GetNodeAttrStr(prop, 'id', MotherSolidId);
        end;
        if prop.NodeName = 'mass' then begin
          mass := GetNodeAttrRealParse(prop, 'value', mass, Parser);
        end;
        if prop.NodeName = 'radius' then begin
          radius := GetNodeAttrRealParse(prop, 'value', radius, Parser);
        end;
        if prop.NodeName = 'focal' then begin
          focalLength := GetNodeAttrRealParse(prop, 'length', focalLength, Parser);
        end;
        if prop.NodeName = 'frame' then begin
          decimation := GetNodeAttrInt(prop, 'decimation', decimation);
        end;
        if prop.NodeName = 'size' then begin
          sizeX := GetNodeAttrRealParse(prop, 'x', sizeX, Parser);
          sizeY := GetNodeAttrRealParse(prop, 'y', sizeY, Parser);
          sizeZ := GetNodeAttrRealParse(prop, 'z', sizeZ, Parser);
          radius := GetNodeAttrRealParse(prop, 'radius', radius, Parser);
        end;
        if prop.NodeName = 'pos' then begin
          posX := GetNodeAttrRealParse(prop, 'x', posX, Parser);
          posY := GetNodeAttrRealParse(prop, 'y', posY, Parser);
          posZ := GetNodeAttrRealParse(prop, 'z', posZ, Parser);
        end;
        if prop.NodeName = 'rot_deg' then begin
          angX := degToRad(GetNodeAttrRealParse(prop, 'x', angX, Parser));
          angY := degToRad(GetNodeAttrRealParse(prop, 'y', angY, Parser));
          angZ := degToRad(GetNodeAttrRealParse(prop, 'z', angZ, Parser));
        end;
        if prop.NodeName = 'color_rgb' then begin
          colorR := GetNodeAttrInt(prop, 'r', 128)/255;
          colorG := GetNodeAttrInt(prop, 'g', 128)/255;
          colorB := GetNodeAttrInt(prop, 'b', 128)/255;
        end;
        if prop.NodeName = 'transparency' then begin
          transparency := GetNodeAttrRealParse(prop, 'alpha', transparency, Parser);
        end;
        if prop.NodeName = 'metallic' then begin
          MatterProps := MatterProps + [smMetallic];
        end;
        if prop.NodeName = 'ferromagnetic' then begin
          MatterProps := MatterProps + [smFerromagnetic];
        end;
        if prop.NodeName = 'rfidtag' then begin
          MatterProps := MatterProps + [smRFIDTag];
        end;
        if prop.NodeName = 'surface' then begin
          Surf.mu := GetNodeAttrRealParse(prop, 'mu', Surf.mu, Parser);
          Surf.mu2 := GetNodeAttrRealParse(prop, 'mu2', Surf.mu2, Parser);
          Surf.soft_cfm := GetNodeAttrRealParse(prop, 'softness', Surf.soft_cfm, Parser);
          Surf.bounce := GetNodeAttrRealParse(prop, 'bounce', Surf.bounce, Parser);
          Surf.bounce_vel := GetNodeAttrRealParse(prop, 'bounce_tresh', Surf.bounce_vel, Parser);
        end;
        prop := prop.NextSibling;
      end;
      // Create and position the shell
      newShell := TSolid.Create;
      Robot.Shells.Add(newShell);
      if IDValue = '' then begin
        newShell.ID := 'Shell';
      end else begin
        newShell.ID := IDValue;
      end;

      SolidIdx := Robot.Solids.IndexFromID(MotherSolidId);
      if SolidIdx = -1 then  begin
        MotherSolid := Robot.MainBody;
      end else begin
        MotherSolid := Robot.Solids[SolidIdx];
      end;

      if mass > 0 then begin  // Offset from previous compositions
        PGeomPos := dGeomGetOffsetPosition(MotherSolid.Geom);
        posX := posX + PGeomPos^[0];
        posY := posY + PGeomPos^[1];
        posZ := posZ + PGeomPos^[2];
      end;

      if ShellNode.NodeName = 'cuboid' then begin
        CreateShellBox(newShell, MotherSolid.Body, posX, posY, posZ, sizeX, sizeY, sizeZ);
        if mass > 0 then dMassSetBoxTotal(NewMass, mass, sizeX, sizeY, sizeZ);
      end else if ShellNode.NodeName = 'cylinder' then begin
        CreateShellCylinder(newShell, MotherSolid.Body, posX, posY, posZ, sizeX, sizeZ);
        if mass > 0 then dMassSetCylinderTotal(NewMass, mass, 1, sizeX, sizeZ);
      end else if ShellNode.NodeName = 'sphere' then begin
        CreateShellSphere(newShell, MotherSolid.Body, posX, posY, posZ, radius);
        if mass > 0 then dMassSetSphereTotal(NewMass, mass, radius);
      end else if ShellNode.NodeName = 'camera' then begin
        CreateShellBox(newShell, MotherSolid.Body, posX, posY, posZ, sizeX, sizeY, sizeZ);
        if mass > 0 then dMassSetBoxTotal(NewMass, mass, sizeX, sizeY, sizeZ);
        MemCameraSolid := newShell;
        //actRemGLCamera := TGLCamera(OdeScene.Scene.cameras.FindChild('GLCameraMem', true));
        actRemGLCamera := TGLCamera(OdeScene.FindChild('GLCameraMem', true));
        if assigned(actRemGLCamera) then begin
          actRemGLCamera.FocalLength := focalLength;
          actRemGLCamera.tag := decimation; // Latter a propper storage for the cameras
        end;
      end;
      newShell.MatterProperties := MatterProps;

      if Surf.mu >= 0 then begin
        newShell.ParSurface.mode := $FF;
        newShell.ParSurface.mu := Surf.mu;
        if Surf.mu2 >= 0 then newShell.ParSurface.mu2 := Surf.mu2;
        newShell.ParSurface.soft_cfm := Surf.soft_cfm;
        newShell.ParSurface.bounce := Surf.bounce;
        newShell.ParSurface.bounce_vel := Surf.bounce_vel;
      end;

      RFromZYXRotRel(R, angX, angY, AngZ);
      dGeomSetOffsetRotation(newShell.Geom, R);

      if mass > 0 then begin  // Affect the body center of mass and Inertia matrix
        CompMass := MotherSolid.Body.mass;
        dMassTranslate(NewMass, posX, posY, posZ);
        dMassRotate(NewMass, R);
        dMassAdd(CompMass, NewMass);

        // Reposition the objects to set a center of gravity to 0,0,0
        //dGeomSetOffsetPosition(newShell.Geom, posX - CompMass.c[0],
        //                                      posY - CompMass.c[1],
        //                                      posZ - CompMass.c[2]);
        PGeomPos := dGeomGetOffsetPosition(MotherSolid.Geom);
        dGeomSetOffsetPosition(MotherSolid.Geom, PGeomPos^[0] - CompMass.c[0],
                                                 PGeomPos^[1] - CompMass.c[1],
                                                 PGeomPos^[2] - CompMass.c[2]);
        // Update offset of all connected geoms
        for i:= 0 to Robot.Shells.count-1 do begin
          if Robot.Shells[i].Body = MotherSolid.Body then begin
            PGeomPos := dGeomGetOffsetPosition(Robot.Shells[i].Geom);
            dGeomSetOffsetPosition(Robot.Shells[i].Geom, PGeomPos^[0] - CompMass.c[0],
                                                         PGeomPos^[1] - CompMass.c[1],
                                                         PGeomPos^[2] - CompMass.c[2]);
          end;
        end;

        MotherSolid.MovePosition(CompMass.c[0], CompMass.c[1], CompMass.c[2]);
        MotherSolid.SetZeroState;

        dMassTranslate(CompMass, -CompMass.c[0], - CompMass.c[1], - CompMass.c[2]);
        dBodySetMass(MotherSolid.Body, @CompMass);
      end;

      with newShell.GLObj as TGLSceneObject do begin
        Material.FrontProperties.Diffuse.SetColor(colorR, colorG, colorB);
        if transparency < 1 then begin
          Material.BlendingMode := bmTransparency;
          Material.FrontProperties.Diffuse.SetColor(colorR, colorG, colorB, transparency);
        end;
      end;
      PositionSceneObject(newShell.GLObj, newShell.Geom);
    end;

    ShellNode := ShellNode.NextSibling;
  end;

end;


procedure TWorld_ODE.LoadThingsFromXML(XMLFile: string; Parser: TSimpleParser);
var XML: IXMLDocument;
    root: IXMLNode;
    LocalParser: TSimpleParser;
begin
  XML := LoadXML(XMLFile, XMLErrors);
  if XML = nil then exit;


  root:=XML.SelectSingleNode('/things');
  if root = nil then exit;

  LocalParser:= TSimpleParser.Create;
  try
    LocalParser.CopyVarList(Parser);
    LoadSolidsFromXML(Things, root, LocalParser);
  finally
    LocalParser.Free;
  end;
end;


procedure TWorld_ODE.LoadGlobalSensorsFromXML(tag: string; XMLFile: string; Parser: TSimpleParser);
var XML: IXMLDocument;
    root: IXMLNode;
    LocalParser: TSimpleParser;
begin
  XML := LoadXML(XMLFile, XMLErrors);
  if XML = nil then exit;


  root:=XML.SelectSingleNode('/' + tag);
  if root = nil then exit;

  LocalParser:= TSimpleParser.Create;
  try
    LocalParser.CopyVarList(Parser);
    LoadSensorsFromXML(nil, root, LocalParser);
  finally
    LocalParser.Free;
  end;
end;


procedure TWorld_ODE.LoadTrackFromXML(XMLFile: string; Parser: TSimpleParser);
var XML: IXMLDocument;
    root, objNode: IXMLNode;
    LocalParser: TSimpleParser;
begin
  XML := LoadXML(XMLFile, XMLErrors);
  if XML = nil then exit;

  root:=XML.SelectSingleNode('/track');
  if root = nil then exit;

  LocalParser:= TSimpleParser.Create;
  LocalParser.CopyVarList(Parser);

  try
    objNode := root.FirstChild;
    while objNode <> nil do begin

      if objNode.NodeName = 'defines' then begin
        LoadDefinesFromXML(LocalParser, objnode);
      end else if objNode.NodeName = 'polygon' then begin
        LoadPolygonFromXML(objNode, LocalParser);
      end else if objNode.NodeName = 'line' then begin
        LoadLineFromXML(objNode, LocalParser);
      end else if objNode.NodeName = 'arc' then begin
        LoadArcFromXML(objNode, LocalParser);
      end;

      objNode := objNode.NextSibling;
    end;

  finally
    LocalParser.Free;
  end;
end;

procedure TWorld_ODE.exportGLPolygonsText(St: TStringList; tags: TStrings);
var i, n: integer;
    GLPolygon: TGLPolygon;
    GLFloor: TGLBaseSceneObject;
begin
  GLFloor := OdeScene.FindChild('GLPlaneFloor', false);
  if GLFloor = nil then exit;
  for i := 0 to GLFloor.Count - 1 do begin
    if not (GLFloor.Children[i] is TGLPolygon) then continue;
    GLPolygon := TGLPolygon(GLFloor.Children[i]);
    if tags <> nil then
      if tags.IndexOf(GLPolygon.Hint) < 0 then continue;
    St.Add(GLPolygon.Hint);
    St.Add(inttostr(GLPolygon.Nodes.Count));
    for n := 0 to GLPolygon.Nodes.Count - 1 do begin
      St.Add(format('%g',[GLPolygon.Nodes[n].x]));
      St.Add(format('%g',[GLPolygon.Nodes[n].y]));
    end;
    St.Add('');
  end;
end;


procedure TWorld_ODE.getGLPolygonsTags(TagsList: TStrings);
var i: integer;
    GLPolygon: TGLPolygon;
    GLFloor: TGLBaseSceneObject;
begin
  GLFloor := OdeScene.FindChild('GLPlaneFloor', false);
  if GLFloor = nil then exit;
  for i := 0 to GLFloor.Count - 1 do begin
    if not (GLFloor.Children[i] is TGLPolygon) then continue;
    GLPolygon := TGLPolygon(GLFloor.Children[i]);
    if TagsList.IndexOf(GLPolygon.Hint) < 0 then begin
      TagsList.Add(GLPolygon.Hint);
    end;
  end;
end;

{
function TWorld_ODE.InsideGLPolygonsTaged(x, y: double; tags: TStrings): boolean;
var n, i, j: integer;
    GLPolygon: TGLPolygon;
    GLFloor: TGLBaseSceneObject;
begin
  result := false;
  GLFloor := OdeScene.FindChild('GLPlaneFloor', false);
  if GLFloor = nil then exit;
  for n := 0 to GLFloor.Count - 1 do begin
    if not (GLFloor.Children[n] is TGLPolygon) then continue;
    GLPolygon := TGLPolygon(GLFloor.Children[n]);
    if tags <> nil then
      if tags.IndexOf(GLPolygon.Hint) < 0 then continue;

    result := false;
    j := GLPolygon.Nodes.Count - 1;
    for i := 0 to GLPolygon.Nodes.Count - 1 do begin
      //result := false;
      // test if point is inside polygon
      with GLPolygon do begin
        if ((((Nodes[i].Y <= Y) and (Y < Nodes[j].Y)) or ((Nodes[j].Y <= Y) and (Y < Nodes[i].Y)) )
             and (X < (Nodes[j].X - Nodes[i].X) * (Y - Nodes[i].Y) / (Nodes[j].Y - Nodes[i].Y) + Nodes[i].X))
        //if ((Nodes[i].Y > y) <> (Nodes[j].Y > y)) and
        //   (x < (Nodes[j].X - Nodes[i].X) * (Y - Nodes[i].Y) / (Nodes[j].Y - Nodes[i].Y) + Nodes[i].X)
        then result := not result;
        j := i;
      end;
    end;
    if result then break;
  end;
end;
}


function TWorld_ODE.CreateGLArc(aWinColor: longWord; a: double; Xc, Yc, Zc, angX, angY, AngZ, StartAngle, StopAngle, step, innerRadius, outerRadius: double; s_tag: string): TGLPolygon;
var GLPolygon: TGLPolygon;
    ang: double;
    over: boolean;
    i: integer;
begin

  StartAngle := DegToRad(StartAngle);
  StopAngle := DegToRad(StopAngle);
  step := DegToRad(step);

  // Start a new contour
  //GLPolygon := TGLPolygon.CreateAsChild(FViewer.GLPlaneFloor);
  GLPolygon := TGLPolygon.CreateAsChild(OdeScene.FindChild('GLPlaneFloor',false));
  //GLPolygon := TGLPolygon.CreateAsChild(OdeScene);

  GLPolygon.Position.Z := 0;
  GLPolygon.Material.FrontProperties.Diffuse.AsWinColor := aWinColor;
  if a < 1 then GLPolygon.Material.BlendingMode := bmTransparency;
  GLPolygon.Material.FrontProperties.Diffuse.Alpha := a;
  GLPolygon.Hint := s_tag;

  // Draw outer arc
  GLPolygon.BeginUpdate;
  ang := StartAngle;
  over := false;
  while true do begin
    GLPolygon.AddNode(outerRadius * cos(ang), outerRadius * sin(ang), ang); // Z stores the angle temporarily
    if over then break;
    ang := ang + step;
    if ang > StopAngle then begin
      ang :=  StopAngle;
      over := true;
    end;
  end;

  // Draw inner arc
  if innerRadius <= 0 then begin
    GLPolygon.AddNode(0, 0, 0);
  end else begin
    for i := GLPolygon.Nodes.Count-1 downto 0 do begin
      ang := GLPolygon.Nodes[i].Z;
      GLPolygon.Nodes[i].Z := 0;
      GLPolygon.AddNode(innerRadius * cos(ang), innerRadius * sin(ang), 0);
    end;
  end;

   //GLPolygon.RotateAbsolute(angX, angY, AngZ); //TODO: implement Node Rotation

  for i := 0 to GLPolygon.Nodes.Count-1 do begin
    GLPolygon.Nodes[i].X := GLPolygon.Nodes[i].X + xc;
    GLPolygon.Nodes[i].Y := GLPolygon.Nodes[i].Y + yc;
    GLPolygon.Nodes[i].Z := GLPolygon.Nodes[i].Z + zc;
  end;


  GLPolygon.EndUpdate;

  result := GLPolygon;
end;

procedure TWorld_ODE.LoadArcFromXML(const root: IXMLNode; Parser: TSimpleParser);
var PolyNode: IXMLNode;
    Xc, Yc, Zc, angX, angY, angZ: double;
    innerRadius, outerRadius: double;
    StartAngle, StopAngle, step: double;
    aWinColor: longWord;
    a: double;
    x_disp, y_disp, angle_disp: double;
    repeat_times: integer;
    i: integer;
    clone_hflip, clone_vflip, clone_hvflip: boolean;
    s_tag: string;
    GLMyArc: TGLPolygon;
    R: TdMatrix3;
begin
  if root = nil then exit;

  PolyNode := root.FirstChild;
  if PolyNode = nil then exit;

  // default values
  Xc := 0; Yc := 0; Zc := 0;
  angX := 0; angY := 0; angZ := 0;
  aWinColor := $808080; a := 1;
  innerRadius := 0; outerRadius := 1;
  StartAngle := 0; StopAngle := 180; step := 15;
  x_disp := 0; y_disp := 0; angle_disp := 0;
  repeat_times := 0;
  clone_hflip := false; clone_vflip := false; clone_hvflip := false;
  s_tag := '';

  while PolyNode <> nil do begin
    if PolyNode.NodeName = 'center' then begin
      Xc := GetNodeAttrRealParse(PolyNode, 'x', Xc, Parser);
      Yc := GetNodeAttrRealParse(PolyNode, 'y', Yc, Parser);
      Zc := GetNodeAttrRealParse(PolyNode, 'z', Zc, Parser);
    end else if PolyNode.NodeName = 'rot_deg' then begin
      angX := GetNodeAttrRealParse(PolyNode, 'x', angX, Parser);
      angY := GetNodeAttrRealParse(PolyNode, 'y', angY, Parser);
      angZ := GetNodeAttrRealParse(PolyNode, 'z', angZ, Parser);
    end else if PolyNode.NodeName = 'radius' then begin
      innerRadius := GetNodeAttrRealParse(PolyNode, 'inner', innerRadius, Parser);
      outerRadius := GetNodeAttrRealParse(PolyNode, 'outer', outerRadius, Parser);
    end else if PolyNode.NodeName = 'angle_deg' then begin
      StartAngle := GetNodeAttrRealParse(PolyNode, 'start', StartAngle, Parser);
      StopAngle := GetNodeAttrRealParse(PolyNode, 'stop', StopAngle, Parser);
      step := GetNodeAttrRealParse(PolyNode, 'step', step, Parser);
    end else if PolyNode.NodeName = 'color' then begin
      aWinColor := StrToIntDef('$'+GetNodeAttrStr(PolyNode, 'rgb24', inttohex(aWinColor,6)), aWinColor);
      a := GetNodeAttrRealParse(PolyNode, 'alpha', 1, Parser);
    end else if PolyNode.NodeName = 'repeat' then begin
      repeat_times := GetNodeAttrInt(PolyNode, 'times', repeat_times);
      x_disp := GetNodeAttrRealParse(PolyNode, 'x_disp', x_disp, Parser);
      y_disp := GetNodeAttrRealParse(PolyNode, 'y_disp', y_disp, Parser);
      angle_disp := GetNodeAttrRealParse(PolyNode, 'angle_disp', angle_disp, Parser);
    end else if PolyNode.NodeName = 'clone_hflip' then begin
      clone_hflip := true;
    end else if PolyNode.NodeName = 'clone_vflip' then begin
      clone_vflip := true;
    end else if PolyNode.NodeName = 'clone_hvflip' then begin
      clone_hvflip := true;
    end else if PolyNode.NodeName = 'tag' then begin
      s_tag := GetNodeAttrStr(PolyNode, 'value', s_tag);
    end;

    PolyNode := PolyNode.NextSibling;
  end;

  //CreateGLArc(aWinColor, Xc, Yc, Zc, StartAngle, StopAngle, step, innerRadius, outerRadius);
  for i:= 0 to repeat_times do begin
    GLMyArc := CreateGLArc(aWinColor, a, Xc, Yc, Zc, angX, angY, AngZ, StartAngle, StopAngle, step, innerRadius, outerRadius, s_tag);

    if clone_hvflip then begin
      GLMyArc := CreateGLArc(aWinColor, a, -Xc, -Yc, Zc, angX, angY, AngZ, StartAngle - 180, StopAngle - 180, step, innerRadius, outerRadius, s_tag);
    end;
    if clone_hflip then begin
      GLMyArc := CreateGLArc(aWinColor, a, Xc, -Yc, Zc, angX, angY, AngZ, -StopAngle, -StartAngle, step, innerRadius, outerRadius, s_tag);
    end;
    if clone_vflip then begin
      GLMyArc := CreateGLArc(aWinColor, a, -Xc, Yc, Zc, angX, angY, AngZ, 180 - StopAngle, 180 - StartAngle, step, innerRadius, outerRadius, s_tag);
    end;

    //GLArc.RotateAbsolute(angX, angY, AngZ);
   // GLArc.RotateAbsolute(0, 90, 0);
//    RFromZYXRotRel(R, angX, angY, AngZ);

//    dBodySetRotation(newSolid.Body, R);

    Xc := Xc + x_disp;
    Yc := Yc + y_disp;
    StartAngle := StartAngle + angle_disp;
    StopAngle := StopAngle + angle_disp;
  end;
end;

procedure TWorld_ODE.LoadPolygonFromXML(const root: IXMLNode; Parser: TSimpleParser);
var PolyNode: IXMLNode;
    posX, posY, posZ: double;
    aWinColor: longWord;
    GLPolygon: TGLPolygon;
    s_tag: string;
    a: double;
begin
  if root = nil then exit;

  PolyNode := root.FirstChild;
  if PolyNode = nil then exit;

  s_tag := '';

  // Start a new contour
  //GLPolygon := TGLPolygon.CreateAsChild(FViewer.GLPlaneFloor);
  GLPolygon := TGLPolygon.CreateAsChild(OdeScene.FindChild('GLPlaneFloor',false));
  GLPolygon.Position.Z := 0.0;

  while PolyNode <> nil do begin
    // default values
    posX := 0; posY := 0; posZ := 0;
    aWinColor := $808080;

    if PolyNode.NodeName = 'vertice' then begin
      posX := GetNodeAttrRealParse(PolyNode, 'x', posX, Parser);
      posY := GetNodeAttrRealParse(PolyNode, 'y', posY, Parser);
      posZ := GetNodeAttrRealParse(PolyNode, 'z', posZ, Parser);
      GLPolygon.AddNode(posX, posY, posZ);
    end else if PolyNode.NodeName = 'color' then begin
      aWinColor := StrToIntDef('$'+GetNodeAttrStr(PolyNode, 'rgb24', inttohex(aWinColor,6)), aWinColor);
      a := GetNodeAttrRealParse(PolyNode, 'alpha', 1, Parser);
      GLPolygon.Material.FrontProperties.Diffuse.AsWinColor := aWinColor;
      if a < 1 then GLPolygon.Material.BlendingMode := bmTransparency;
      GLPolygon.Material.FrontProperties.Diffuse.Alpha := a;

    end else if PolyNode.NodeName = 'tag' then begin
      s_tag := GetNodeAttrStr(PolyNode, 'value', s_tag);
    end;

    PolyNode := PolyNode.NextSibling;
  end;

  GLPolygon.Hint := s_tag;
end;

{  <line>
    <color rgb24='8F8F8F'/>
    <position x='0' y='0' z='0' angle='0'/>
    <size width='0' lenght='0'/>
  </line>
}

function TWorld_ODE.CreateGLPolygoLine(aWinColor: longWord; a: double; posX, posY, posZ, lineLength, lineWidth, angle: double; s_tag: string): TGLPolygon;
var GLPolygon: TGLPolygon;
    x, y: double;
begin
  // Start a new contour
  //GLPolygon := TGLPolygon.CreateAsChild(FViewer.GLPlaneFloor);
  GLPolygon := TGLPolygon.CreateAsChild(OdeScene.FindChild('GLPlaneFloor',false));
  GLPolygon.Hint := s_tag;
  with GLPolygon do begin
    Position.Z := 0.0;
    Material.FrontProperties.Diffuse.AsWinColor := aWinColor;
    if a < 1 then Material.BlendingMode := bmTransparency;
    Material.FrontProperties.Diffuse.Alpha := a;

    angle := DegToRad(angle);

    x := posX;
    y := posY;
    GLPolygon.AddNode(x, y, posZ);

    x := x + lineLength * cos(angle);
    y := y + lineLength * sin(angle);
    GLPolygon.AddNode(x, y, posZ);

    x := x - lineWidth * sin(angle);
    y := y + lineWidth * cos(angle);
    GLPolygon.AddNode(x, y, posZ);

    x := posX - lineWidth * sin(angle);
    y := posY + lineWidth * cos(angle);
    GLPolygon.AddNode(x, y, posZ);

    {AddNode(0, 0, 0);
    AddNode(lineLength, 0, 0);
    AddNode(lineLength, lineWidth, 0);
    AddNode(0, lineWidth, 0);

    RotateAbsolute(zvector, -angle);
    Position.SetPoint(posX, posY, posZ);}
  end;
  result := GLPolygon;
end;

procedure TWorld_ODE.LoadLineFromXML(const root: IXMLNode; Parser: TSimpleParser);
var PolyNode: IXMLNode;
    posX, posY, posZ, angle: double;
    lineWidth, lineLength: double;
    aWinColor: longWord;
    a: double;
    x_disp, y_disp, angle_disp: double;
    repeat_times: integer;
    i: integer;
    clone_hflip, clone_vflip, clone_hvflip: boolean;
    s_tag: string;
    GLLine: TGLPolygon;
begin
  if root = nil then exit;

  PolyNode := root.FirstChild;
  if PolyNode = nil then exit;

  // default values
  posX := 0; posY := 0; posZ := 0; angle := 0;
  lineWidth := 0.1; lineLength := 1;
  aWinColor := $808080; a := 1;
  x_disp := 0; y_disp := 0; angle_disp := 0;
  repeat_times := 0;
  clone_hflip := false; clone_vflip := false; clone_hvflip := false;
  s_tag := '';

  while PolyNode <> nil do begin
    if PolyNode.NodeName = 'position' then begin
      posX := GetNodeAttrRealParse(PolyNode, 'x', posX, Parser);
      posY := GetNodeAttrRealParse(PolyNode, 'y', posY, Parser);
      posZ := GetNodeAttrRealParse(PolyNode, 'z', posZ, Parser);
      angle := GetNodeAttrRealParse(PolyNode, 'angle', angle, Parser);
    end else if PolyNode.NodeName = 'size' then begin
      lineWidth := GetNodeAttrRealParse(PolyNode, 'width', lineWidth, Parser);
      lineLength := GetNodeAttrRealParse(PolyNode, 'length', lineLength, Parser);
    end else if PolyNode.NodeName = 'color' then begin
      aWinColor := StrToIntDef('$'+GetNodeAttrStr(PolyNode, 'rgb24', inttohex(aWinColor,6)), aWinColor);
      a := GetNodeAttrRealParse(PolyNode, 'alpha', 1, Parser);
    end else if PolyNode.NodeName = 'repeat' then begin
      repeat_times := GetNodeAttrInt(PolyNode, 'times', repeat_times);
      x_disp := GetNodeAttrRealParse(PolyNode, 'x_disp', x_disp, Parser);
      y_disp := GetNodeAttrRealParse(PolyNode, 'y_disp', y_disp, Parser);
      angle_disp := GetNodeAttrRealParse(PolyNode, 'angle_disp', angle_disp, Parser);
    end else if PolyNode.NodeName = 'clone_hflip' then begin
      clone_hflip := true;
    end else if PolyNode.NodeName = 'clone_vflip' then begin
      clone_vflip := true;
    end else if PolyNode.NodeName = 'clone_hvflip' then begin
      clone_hvflip := true;
    end else if PolyNode.NodeName = 'tag' then begin
      s_tag := GetNodeAttrStr(PolyNode, 'value', s_tag);
    end;

    PolyNode := PolyNode.NextSibling;
  end;

  //angle := DegToRad(angle);

  {x := posX;
  y := posY;
  GLPolygon.AddNode(x, y, posZ);

  x := x + lineLength * cos(angle);
  y := y + lineLength * sin(angle);
  GLPolygon.AddNode(x, y, posZ);

  x := x - lineWidth * sin(angle);
  y := y + lineWidth * cos(angle);
  GLPolygon.AddNode(x, y, posZ);

  x := posX - lineWidth * sin(angle);
  y := posY + lineWidth * cos(angle);
  GLPolygon.AddNode(x, y, posZ);}
  {
  GLPolygon.AddNode(0, 0, 0);
  GLPolygon.AddNode(lineLength, 0, 0);
  GLPolygon.AddNode(lineLength, lineWidth, 0);
  GLPolygon.AddNode(0, lineWidth, 0);

  GLPolygon.RotateAbsolute(zvector, -angle);
  GLPolygon.Position.SetPoint(posX, posY, posZ);
  }

  for i:= 0 to repeat_times do begin
    CreateGLPolygoLine(aWinColor, a, posX, posY, posZ, lineLength, lineWidth, angle, s_tag);
    if clone_hvflip then begin
      CreateGLPolygoLine(aWinColor, a, -posX, -posY, posZ, lineLength, lineWidth, angle - 180, s_tag);
    end;
    if clone_hflip then begin
      CreateGLPolygoLine(aWinColor, a, posX, -posY, posZ, lineLength, lineWidth, -angle, s_tag);
    end;
    if clone_vflip then begin
      CreateGLPolygoLine(aWinColor, a, -posX, posY + lineWidth, posZ, lineLength, lineWidth, 180 - angle, s_tag);
    end;

    posX := posX + x_disp;
    posY := posY + y_disp;
    angle := angle + angle_disp;
  end;

 { GLPolygon.Material.Texture.Image.LoadFromFile('..\grad.jpg');
  if lineWidth > 1e-10 then begin
    GLPolygon.Material.Texture.MappingSCoordinates.X := 0;
    GLPolygon.Material.Texture.MappingSCoordinates.Y := 1/lineWidth;
  end;
  GLPolygon.Material.Texture.MappingMode := tmmObjectLinear;
  GLPolygon.Material.Texture.TextureWrap := twNone;
  GLPolygon.Material.Texture.Disabled := false;}
end;


procedure TWorld_ODE.LoadDefinesFromXML(Parser: TSimpleParser; const root: IXMLNode);
var prop: IXMLNode;
    ConstName: string;
    ConstValue: double;
begin
  if root = nil then exit;

  // default values
  ConstName:='';
  ConstValue := 0;

  prop := root.FirstChild;
  while prop <> nil do begin

    if prop.NodeName = 'const' then begin
      ConstName := GetNodeAttrStr(prop, 'name', ConstName);
      ConstValue := GetNodeAttrRealParse(prop, 'value', ConstValue, Parser);
      if ConstName <> '' then
        Parser.RegisterConst(ConstName, ConstValue);

    end else if prop.NodeName = 'arg' then begin
      ConstName := GetNodeAttrStr(prop, 'name', ConstName);
      ConstValue := GetNodeAttrRealParse(prop, 'value', ConstValue, Parser);
      if ConstName <> '' then begin
        if not Parser.ConstIsDefined(ConstName) then
          Parser.RegisterConst(ConstName, ConstValue);
      end;
    end;

    prop := prop.NextSibling;
  end;
end;


procedure TWorld_ODE.LoadSceneFromXML(XMLFile: string);
var XML: IXMLDocument;
    root, objNode, prop: IXMLNode;
    SolidDef: TSolidDef;
    newRobot: TRobot;
    filename: string;
    //Parser: TSimpleParser; // Now is a member of TWorld_ODE
begin

  XMLFiles.Add(XMLFile);
  XML := LoadXML(XMLFile, XMLErrors);
  if XML = nil then exit;

  root:=XML.SelectSingleNode('/scene');
  if root = nil then exit;

  //Parser := TSimpleParser.Create;
  try
    objNode := root.FirstChild;
    while objNode <> nil do begin
      if objNode.NodeName = 'robot' then begin
        prop := objNode.FirstChild;
        // default values
        SolidDefSetDefaults(SolidDef);
        SolidDef.ID := 'robot' + inttostr(Robots.count);
        filename := '';
        while prop <> nil do begin
          if prop.NodeName = 'defines' then begin
            LoadDefinesFromXML(Parser, prop);
          end else if prop.NodeName = 'body' then begin
            filename := GetNodeAttrStr(prop, 'file', filename);
          end;
          SolidDefProcessXMLNode(SolidDef, prop, Parser);
          prop := prop.NextSibling;
        end;

        //if filename <> '' then begin
        if fileexists(filename) then begin
          XMLFiles.Add(filename);
          newRobot := LoadRobotFromXML(filename, Parser);
          if newRobot <> nil then begin
            newRobot.ID := SolidDef.ID;
            with SolidDef do newRobot.SetXYZTeta(posX, posY, posZ, angZ);
          end;
        end;

      end else if objNode.NodeName = 'defines' then begin
        LoadDefinesFromXML(Parser, objnode);

      end else if (objNode.NodeName = 'obstacles') or (objNode.NodeName = 'obstacle') then begin
        prop := objNode.FirstChild;
        // default values
        SolidDefSetDefaults(SolidDef);
        filename := '';
        while prop <> nil do begin
          if prop.NodeName = 'body' then begin
            filename := GetNodeAttrStr(prop, 'file', filename);
          end;
          SolidDefProcessXMLNode(SolidDef, prop, Parser);
          prop := prop.NextSibling;
        end;

        // Create static obstacles
        filename := GetNodeAttrStr(objNode, 'file', filename);
        if fileexists(filename) then begin
          XMLFiles.Add(filename);
          LoadObstaclesFromXML(filename, SolidDef, Parser);
        end;

      end else if objNode.NodeName = 'things' then begin
        // Create things

        prop := objNode.FirstChild;
        while prop <> nil do begin
          if prop.NodeName = 'defines' then begin
            LoadDefinesFromXML(Parser, prop);
          end;
          prop := prop.NextSibling;
        end;

        filename := GetNodeAttrStr(objNode, 'file', filename);
        if fileexists(filename) then begin
          XMLFiles.Add(filename);
          LoadThingsFromXML(filename, Parser);
        end;

      end else if objNode.NodeName = 'track' then begin
        // Create track
        filename := GetNodeAttrStr(objNode, 'file', filename);
        if fileexists(filename) then begin
          XMLFiles.Add(filename);
          LoadTrackFromXML(filename, Parser);
        end;

      end else if (objNode.NodeName = 'sensors') or (objNode.NodeName = 'tools') then begin
        filename := GetNodeAttrStr(objNode, 'file', filename);
        if fileexists(filename) then begin
          XMLFiles.Add(filename);
          LoadGlobalSensorsFromXML(objNode.NodeName, filename, Parser);
        end;

      end else begin // Unused Tag Generate warning
        if (XMLErrors <> nil) and (objNode.NodeName <> '#text') and (objNode.NodeName <> '#comment') then begin
          XMLErrors.Add('[Warning] ' + format('(%s): ', [XMLFile]) + 'Tag <'+ objNode.NodeName + '> not recognised!');
        end;
      end;

      objNode := objNode.NextSibling;
    end;

  finally
    //Parser.Free;
  end;

end;


function TWorld_ODE.LoadRobotFromXML(XMLFile: string; Parser: TSimpleParser): TRobot;
var XML: IXMLDocument;
    root, objNode: IXMLNode;
    newRobot: TRobot;
    str: string;
    LocalParser: TSimpleParser;
begin
  result := nil;

  XML := LoadXML(XMLFile, XMLErrors);
  if XML = nil then exit;

  root:=XML.SelectSingleNode('/robot');
  if root = nil then exit;

  LocalParser:= TSimpleParser.Create;
  LocalParser.CopyVarList(Parser);

  try
    newRobot := TRobot.Create;
    Robots.Add(newRobot);

    objNode := root.FirstChild;
    while objNode <> nil do begin
      if objNode.NodeName = 'kind' then begin
        str := GetNodeAttrStr(objNode, 'value', '');
        if lowercase(str)='omni3' then newRobot.Kind := rkOmni3
        else if lowercase(str)='omni4' then newRobot.Kind := rkOmni4
        else if lowercase(str)='wheelchair' then newRobot.Kind := rkWheelChair
        else if lowercase(str)='humanoid' then newRobot.Kind := rkHumanoid
        else if lowercase(str)='belt' then newRobot.Kind := rkConveyorBelt;
      end else if objNode.NodeName = 'defines' then begin
        LoadDefinesFromXML(LocalParser, objnode);
      end else if objNode.NodeName = 'solids' then begin
        LoadSolidsFromXML(newRobot.Solids, objNode, LocalParser);
        if newRobot.Solids.Count = 0 then exit;
        newRobot.MainBody := newRobot.Solids[0];
      end else if objNode.NodeName = 'wheels' then begin
        LoadWheelsFromXML(newRobot, objNode, LocalParser);
      end else if objNode.NodeName = 'shells' then begin
        LoadShellsFromXML(newRobot, objNode, LocalParser);
      end else if objNode.NodeName = 'sensors' then begin
        LoadSensorsFromXML(newRobot, objNode, LocalParser);
      end else if objNode.NodeName = 'tools' then begin
        LoadSensorsFromXML(newRobot, objNode, LocalParser);
      end else if objNode.NodeName = 'articulations' then begin
        LoadLinksFromXML(newRobot, objNode, LocalParser);
      end else begin // Unused Tag Generate warning
        if (XMLErrors <> nil) and (objNode.NodeName <> '#text') and (objNode.NodeName <> '#comment') then begin
          XMLErrors.Add('[Warning] ' + format('(%s): ', [XMLFile]) + 'Tag <'+ objNode.NodeName + '> not recognised!');
        end;
      end;

      objNode := objNode.NextSibling;
    end;

  finally
    LocalParser.Free;
  end;

  result := newRobot;
end;


constructor TWorld_ODE.create;
var plane: TSolid;
    Center, Extents : TdVector3;
begin
  AirDensity := 1.293; //kg/m3
  default_n_mu := 0.95;
  Ode_dt := 1/1000;
  TimeFactor := 1;
  ODEEnable := False;
  PhysTime := 0;

  SecondsCount := 0;
  DecPeriod := 0.04;

  OdeScene := FViewer.GLShadowVolume;

  Walls := TSolidList.Create;

  Environment := TSolid.Create;
  Environment.Body := nil;

  Robots := TRobotList.Create;
  Obstacles := TSolidList.Create;
  Things := TSolidList.Create;
  Sensors := TSensorList.Create;

  XMLFiles := TStringList.Create;
  XMLErrors := TStringList.Create;
  Parser := TSimpleParser.Create;

  MaxWorldX := 12;
  MinWorldX := -12;
  MaxWorldY := 12;
  MinWorldY := -12;

  //Create physic
  world := dWorldCreate();
//  dWorldSetQuickStepNumIterations(world, 10);
  Ode_QuickStepIters := 10;
  dWorldSetQuickStepNumIterations(world, Ode_QuickStepIters);
  space := dSimpleSpaceCreate(nil);
  //space := dHashSpaceCreate(nil);
  //dHashSpaceSetLevels(space, -5, 1);
  {Center[0] := 0;
  Center[1] := 0;
  Center[2] := 0;
  Extents[0] := MaxWorldX;
  Extents[1] := MaxWorldY;
  Extents[2] := MaxWorldX + MaxWorldY;

  space := dQuadTreeSpaceCreate(nil, Center, Extents, 5);}
  contactgroup := dJointGroupCreate(0);
  dWorldSetGravity(world, 0, 0, -9.81);

  Ode_CFM := 1e-5;
  Ode_ERP := 0.4;
  dWorldSetCFM(world, Ode_CFM);
  dWorldSetERP(world, Ode_ERP);

  //dWorldSetAngularDamping(world, 0.8);
  //dWorldSetLinearDamping(world, 0.8);

  if FileExists('ground.jpg') then begin
    FViewer.GLMaterialLibrary.AddTextureMaterial('Ground', 'ground.jpg');
  end;

  LoadSceneFromXML('scene.xml');

  SetCameraTarget(0);

  //Floor
  //dCreatePlane(space, 0, 0, 1, 0);
  plane := CreateInvisiblePlane(skFloor, 0, 0, 1, 0);
  plane.AltGLObj := FViewer.GLPlaneFloor;
  Walls.Add(plane);

  //Box wall limit
  //dCreatePlane(space,  0, 1, 0, -MaxWorldY);
  //dCreatePlane(space,  1, 0, 0, -MaxWorldX);
  //dCreatePlane(space,  0,-1, 0, MinWorldY);
  //dCreatePlane(space, -1, 0, 0, MinWorldX);

  Walls.Add(CreateInvisiblePlane(skWall,  0, 1, 0, -MaxWorldY));
  Walls.Add(CreateInvisiblePlane(skWall,  1, 0, 0, -MaxWorldX));
  Walls.Add(CreateInvisiblePlane(skWall,  0,-1, 0, MinWorldY));
  Walls.Add(CreateInvisiblePlane(skWall, -1, 0, 0, MinWorldX));

{  if Robots[0] <> nil then begin
    if Robots[0].MainBody.GLObj<>nil then begin
      FViewer.GLDummyCamPosRel.MoveTo(Robots[0].MainBody.GLObj);
      FViewer.GLDummyTargetCamRel.MoveTo(Robots[0].MainBody.GLObj);
    end;
  end;}
 {
  //CreateSolidCylinder(TestBody, 1, 1.12, -0.1, 1.5, 0.1, 1);
  //RotateSolid(TestBody, 0, 1, 0, pi/2);
}

end;

destructor TWorld_ODE.Destroy;
begin
  //Destroy the physic
  dJointGroupDestroy(contactgroup);

  Sensors.ClearAll;
  Sensors.Free;

  Things.ClearAll;
  Things.Free;

  Robots.ClearAll;
  Robots.Free;

  Obstacles.ClearAll;
  Obstacles.Free;

  Environment.Free;

  Walls.ClearAll;
  Walls.Free;

  dSpaceDestroy(space);
  //TODO Destroy the bodies
  dWorldDestroy(world);

  Parser.Free;
  XMLErrors.Free;
  XMLFiles.Free;

  inherited;
end;

procedure TWorld_ODE.WorldUpdate;
begin
  //Update the physic
  dSpaceCollide(space, nil, nearCallback);
  if FParams.CBWorldQuickStep.Checked then begin
    dWorldQuickStep(world, Ode_dt);
  end else begin
    dWorldStep(world, Ode_dt);
  end;
  physTime := physTime + Ode_dt;

  // remove all contact joints
  dJointGroupEmpty (contactgroup);
end;

procedure TFViewer.FormCreate(Sender: TObject);
var s, fl: string;
    Slist: TStringList;
begin
  // Lazarus catch WM_SETTINGCHANGE and calls Application.IntfSettingChange
  // which calls GetFormatSettings in SysUtils
  // It can be switched off by setting Application.UpdateFormatSettings:=False;
  Application.UpdateFormatSettings := false;
  DefaultFormatSettings.DecimalSeparator := '.';

  SetCurrentDir(ExtractFilePath(Application.ExeName));

  if ParamCount > 0 then begin
    s := ParamStr(1);
  end else begin
    s := 'default';
    fl := extractfilepath(application.exename) + 'Scene.cfg';
    if fileexists(extractfilepath(application.exename) + 'Scene.cfg') then begin
      Slist := TStringList.Create;
      try
        try
          Slist.LoadFromFile(fl);
          if Slist.Count > 0 then begin
            s := Slist[0];
          end;
        finally
          Slist.Free;
        end;
      except
        on E: Exception do showmessage(E.Message);
      end;
    end;
  end;

  //showmessage(getCurrentDir + ' ' + s);
  if DirectoryExists(s) then begin
    SetCurrentDir(s);
    CurrentProject := s;
  end else begin
    //FSceneEdit.MenuChange.Click;
    SetCurrentDir('base');
    FChooseScene := TFChooseScene.Create(FViewer);
    try
      FChooseScene.showmodal;

      if FChooseScene.ModalResult = mrCancel then halt(1);
      if FChooseScene.SelectedDir = '' then halt(1);

      SetCurrentDir('../' + FChooseScene.SelectedDir);
      CurrentProject := FChooseScene.SelectedDir;
    finally
      FChooseScene.Free;
    end;

  end;

  IniPropStorage.IniFileName := GetIniFineName;
//  GetProcessAffinityMask(
//  SetThreadAffinityMask(GetCurrentThreadId(), 1);
//  SetThreadAffinityMask(GetCurrentProcessId(), 1);
  QueryPerformanceFrequency(t_delta);
  t_delta := t_delta div 1000;

  //Execute Create physic
  WorldODE := TWorld_ODE.create;

  //WorldODE.SampleCount := 0;
  WorldODE.ODEEnable := True;

  GLHUDTextObjName.Text := '';
  GLHUDTextObjName.BitmapFont := GLWindowsBitmapFont; // Doing this at design time seems to crash Lazarus (1.8.2)
  HUDStrings := TStringlist.Create;
  GetVersionInfo;
  SimTwoVersion := 'SimTwo v' + InfoData[3];

  frameCount := 0;

  Timer.Enabled := true;
end;

procedure TFViewer.GLSceneViewerMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var pick : TGLCustomSceneObject;
    vs, CamPos, hitPoint: TVector;
    hit: boolean;
    t: double;
begin
  if not (Button = mbLeft) then exit; // Ignore Right(PopUpMenu) and middle buttons
  pick := GLSceneViewerPick(x, y);
  if Assigned(pick) and not (ssCtrl in shift) and (Button = mbLeft) then begin
    vs :=  GLSceneViewer.Buffer.ScreenToVector(x, GLSceneViewer.Buffer.ViewPort.Height - y);
    NormalizeVector(vs);
    CamPos := GLSceneViewer.Buffer.Camera.Position.AsVector;
    //if pick.Name = 'GLPlaneFloor' then begin
    if vs.v[2] <> 0 then begin
      t := - Campos.v[2] / vs.v[2];
      FParams.Edit3DProjection.Text := format('%.3f,%.3f,%.3f', [Campos.v[0] + t * vs.v[0], Campos.v[1] + t * vs.v[1], Campos.v[2] + t * vs.v[2]]);
    end;
    if pick.TagObject is TSolid then with WorldODE do begin
      hit := Pick.RayCastIntersect(CamPos, vs, @hitPoint.v[0]);
//      FParams.Edit3DProjection.Text := format('%.2f,%.2f,%.2f', [hitPoint[0], hitPoint[1], hitPoint[2]]);
      if hit then begin
        makevector(PickPoint, hitPoint);
      end;
      if TSolid(pick.TagObject).Body <> nil then begin
        PickSolid := TSolid(pick.TagObject);
        if hit then begin
          CreatePickJoint(PickSolid, hitPoint.v[0], hitPoint.v[1], hitPoint.v[2]);
          PickDist := sqrt(sqr(hitPoint.v[0]-CamPos.v[0])+sqr(hitPoint.v[1]-CamPos.v[1])+sqr(hitPoint.v[2]-CamPos.v[2]));
        end;
      end;
    end;
  end;

  my := y;
  mx := x;
end;

procedure TFViewer.GLSceneViewerMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if [ssShift, ssleft, ssCtrl] <= shift then begin
    //GLScene.CurrentGLCamera.MoveTargetInEyeSpace(0, -0.03*(mx-x), 0.03*(my-y));
    GLCamera.MoveTargetInEyeSpace(0, -0.03*(mx-x), 0.03*(my-y));
    //GLDummyTargetCam.Position := GLScene.CurrentGLCamera.TargetObject.Position;
    //UpdateCamPos(FParams.RGCamera.ItemIndex);
    my := y;
    mx := x;
  end else if [ssleft, ssCtrl] <= shift then begin
    //GLScene.CurrentGLCamera.MoveAroundTarget(my-y,mx-x);
    //GLDummyCamPos.Position := GLScene.CurrentGLCamera.Position;
    GLCamera.MoveAroundTarget(my-y,mx-x);
    GLDummyCamPos.Position := GLCamera.Position;
    //UpdateCamPos(FParams.RGCamera.ItemIndex);
    my := y;
    mx := x;
  end;

//  if WorldODE.PickSolid = nil then begin
//    GLSceneViewerPick(x, y);
//  end;

end;

procedure TFViewer.GLSceneViewerMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  WorldODE.DestroyPickJoint;
end;

function TFViewer.GLSceneViewerPick(X, Y: Integer): TGLCustomSceneObject;
var pick : TGLCustomSceneObject;
    Pos: TdVector3;
begin
  pick:=(GLSceneViewer.Buffer.GetPickedObject(x, y) as TGLCustomSceneObject);

  if Assigned(pick) then begin
    if pick.TagObject is TSolid then begin
      Pos := dGeomGetPosition(TSolid(pick.TagObject).Geom)^;
      GLHUDTextObjName.Text := TSolid(pick.TagObject).ID + format(' (%.3f, %.3f, %.3f)', [Pos[0], Pos[1], Pos[2]]);
      GLHUDTextObjName.TagFloat := 10;
      if Assigned(WorldODE.OldPick) then WorldODE.OldPick.Material.FrontProperties.Emission.Color:=clrBlack;
      pick.Material.FrontProperties.Emission.Color:=clrRed;
      WorldODE.OldPick := Pick;
    end else begin
      GLHUDTextObjName.Text := '';
      GLHUDTextObjName.TagFloat := 0;
      if Assigned(WorldODE.OldPick) then WorldODE.OldPick.Material.FrontProperties.Emission.Color:=clrBlack;
      WorldODE.OldPick := nil;
    end;
    if pick.TagObject is TAxis then begin
      GLHUDTextObjName.Text := TAxis(pick.TagObject).ParentLink.description;
      GLHUDTextObjName.TagFloat := 10;
    end;
  end;
  result := pick;
end;

procedure AxisTorqueModel(axis: TAxis; Theta, w, dt: double; var T: double);
var old_Im, dI, err: double;
    max_delta_Im: double;
    minLim, maxLim: double;
    ev, ebt: double;
    Td, dtheta, TB, TK, tau: double;
begin
  max_delta_Im := 0.15; // A/ms
  with Axis do begin
    // If active use PID controller
    if Motor.active then begin
      with Motor.Controller do begin
        if active then begin

          ticks := ticks + WorldODE.Ode_dt;
          if ticks >= ControlPeriod then begin
            ticks := ticks - ControlPeriod;
            case ControlMode of
              cmPIDPosition: begin
                if axis.isCircular then begin   // If it is a circular joint
                  axis.GetLimits(minLim, maxLim);
                  if (minlim < -pi) and (maxlim > pi) and axis.canWrap then begin  // and it has no limits
                    err := DiffAngle(ref.theta, theta);           // Use the shortest path solution
                  end else begin
                    err := ref.theta - theta;                     // Else use the standard path
                  end;
                end else begin
                  err := ref.theta - theta;
                end;
                ref.volts := CalcPID(Motor.Controller, ref.theta, err);
              end;

              cmPIDSpeed: begin
                //ref.volts := CalcPID(Motor.Controller, ref.w, w);
                ref.volts := CalcPID(Motor.Controller, ref.w, ref.w - filt_speed);
              end;

              cmState: begin
                //ref.volts := CalcPD(Motor.Controller, ref.theta, ref.w, theta, w);
                ref.volts := CalcPD(Motor.Controller, ref.theta, ref.w, theta, filt_speed);
              end;
            end;
          end;
        end;
      end;
      // Voltage with saturation
      Motor.voltage := max(-Motor.Vmax, min(Motor.Vmax, ref.volts));
      // Motor Model
      {if Motor.Vmax <> 0 then begin
        duty := abs(Motor.voltage / Motor.Vmax);
      end else begin
        duty := 0;
      end;}

      old_Im := Motor.Im;

      if not Motor.simple then begin
        if Motor.JRotor > 0 then begin
          ev := Motor.w * Motor.Ki ;
        end else begin
          ev := w * Motor.GearRatio * Motor.Ki ;
        end;

        if Motor.Li <> 0 then begin
          if Motor.Ri <> 0 then begin
            ebt := exp(-dt*Motor.Ri / Motor.Li);
            Motor.Im := ebt * Motor.Im + (1 - ebt) * (Motor.voltage - ev) / Motor.Ri;
          end else begin
            dI := dt / Motor.Li * (Motor.voltage - ev);
            Motor.Im := Motor.Im + dI;
          end;
        end else begin
          if Motor.Ri <> 0 then begin
            Motor.Im := (Motor.voltage - ev) / Motor.Ri;
          end else begin
            Motor.Im := Motor.Imax * sign(Motor.voltage);
          end;
        end;
      end else begin
        Motor.Im := Motor.voltage / Motor.Ri;
      end;


      if Motor.Im > old_Im + max_delta_Im then Motor.Im := old_Im + max_delta_Im;
      if Motor.Im < old_Im - max_delta_Im then Motor.Im := old_Im - max_delta_Im;

      //if abs(Motor.voltage)>1e-3 then begin
        //iw := max(-Pars.Imax , min(Pars.Imax , iw));
        // this limit is dependent on the current sensor placement
        // Here is assumed that it is only active on the "on" time of the PWM
        //Motor.Im := max(-Motor.Imax / duty, min(Motor.Imax / duty, Motor.Im));
        Motor.Im := max(-Motor.Imax, min(Motor.Imax, Motor.Im));
      //end;
    end else begin
      Motor.Im := 0;
    end;

    Motor.PowerDrain := Motor.Im * Motor.voltage * WorldODE.Ode_dt;
    if Motor.PowerDrain > 0 then begin
      Motor.EnergyDrain := Motor.EnergyDrain + Motor.PowerDrain;
    end;

    // coulomb friction
    // Tq := Friction.Fc * sign(w);
    // Limit it to avoid instability
    //if Friction.CoulombLimit >= 0 then
    //  Tq := max(-Friction.CoulombLimit * abs(w), min(Friction.CoulombLimit * abs(w), Tq));

{    with motor do begin
      JRotor := 1e-4;
      //JRotor := 0;
      BRotor := 1e-3;

      KGearBox := 5e-2; //GearRatio = 500
      BGearBox := 1e-5;
      //KGearBox := 5e-1; //GearRatio = 12
      //BGearBox := 1e-2;

      KGearBox2 := 0;
      BGearBox2 := 0;
    end;
}
    if Motor.JRotor > 0 then begin
      tau :=  Motor.JRotor / WorldODE.Ode_dt;
      dtheta := diffangle(Motor.teta, Theta);

      TB := Motor.BGearBox  * (Motor.w - filt_speed *  Motor.GearRatio);
      // TB limit: it avoids some crashes when BGearBox is to high
      if 0.2 * abs(Motor.JRotor / TB) < WorldODE.Ode_dt then begin
        if TB > 0 then TB := 0.2 * tau
        else TB := -0.2 * tau
      end;

      TK := (Motor.KGearBox + Motor.KGearBox2 * sign(dtheta) * dtheta ) * dtheta;

      Td := TK + TB;

      {if abs(Motor.JRotor / Td) < WorldODE.Ode_dt then begin
        if Td > 0 then Td := 0.5 *Motor.JRotor / WorldODE.Ode_dt
        else Td := -0.5 *Motor.JRotor / WorldODE.Ode_dt
      end;}
  //  ebt := exp(-dt*Motor.Ri / Motor.Li);
  //  Motor.Im := ebt * Motor.Im + (1 - ebt) * (Motor.voltage - ev) / Motor.Ri;

      Motor.w := Motor.w + (Motor.Im * Motor.Ki - Motor.BRotor * Motor.w - Td) * WorldODE.Ode_dt / Motor.JRotor;
      Motor.teta := Motor.teta  + Motor.w * WorldODE.Ode_dt / Motor.GearRatio;

      T := Td * Motor.GearRatio - Friction.Bv * filt_speed - Spring.K * (Theta - Spring.ZeroPos);;
    end else begin
      //T := Motor.Im * Motor.Ki * Motor.GearRatio - Friction.Bv * w - Spring.K * diffangle(Theta, Spring.ZeroPos);
      T := Motor.Im * Motor.Ki * Motor.GearRatio - Friction.Bv * filt_speed - Spring.K * (Theta - Spring.ZeroPos);
      //T := Motor.Im * Motor.Ki * Motor.GearRatio - Friction.Bv * w - Spring.K * (Theta - Spring.ZeroPos);
    end;
  end;
end;



procedure ReadKeyVals(var KeyVals: TKeyVals);
begin
  if IsKeyDown(VK_UP) then begin
    KeyVals[0] := 1;
    KeyVals[1] := -1;
  end;

  if IsKeyDown(VK_DOWN) then begin
    KeyVals[0] := -1;
    KeyVals[1] := 1;
  end;

  if IsKeyDown(VK_RIGHT) then begin
    if not IsKeyDown(VK_LCONTROL) then begin
      KeyVals[0] := -1;
      KeyVals[1] := -1;
      KeyVals[2] := -1;
    end else begin
      KeyVals[0] := 0.16;
      KeyVals[1] := 0.16;
      KeyVals[2] := -0.83;
    end;
  end;

  if IsKeyDown(VK_LEFT) then begin
    if not IsKeyDown(VK_LCONTROL) then begin
      KeyVals[0] := 1;
      KeyVals[1] := 1;
      KeyVals[2] := 1;
    end else begin
      KeyVals[0] := -0.16;
      KeyVals[1] := -0.16;
      KeyVals[2] := 0.83;
    end;
  end;
end;

procedure TFViewer.FillRemote(r: integer);
var i: integer;
  v1, v2: TdVector3;
begin
  if (r < 0) or (r >= WorldODE.Robots.Count) then exit;
  with WorldODE.Robots[r], RemState do begin
    id:=$5db0;
    // Calculate robot position and orientation
    if (MainBody <> nil) and
       (MainBody.Body <> nil) then begin
      v1 := dBodyGetPosition(MainBody.Body)^;
      dBodyGetRelPointPos(MainBody.Body, 1,0,0, v2);
      Robot.x := v1[0];
      Robot.y := v1[1];
      Robot.teta := atan2(v2[1]-v1[1], v2[0]-v1[0]);
    end;

    // Fill Remote Odometry
    for i := 0 to min(MaxRemWheels, Wheels.Count) - 1 do begin
      Robot.Odos[i] := Wheels[i].Axle.Axis[0].Odo.Value;
    end;

    // Fill remote IR sensors
    for i:=0 to min(Sensors.Count, MaxRemIrSensors)-1 do begin
      if Sensors[i].Measures[0].has_measure then begin
        Robot.IRSensors[i] := Sensors[i].Measures[0].value;
        if Robot.IRSensors[i] = 0 then Robot.IRSensors[i] := 1e6;
      end else begin
        Robot.IRSensors[i] := 0;
      end;
    end;

  end;
end;

procedure TFViewer.UpdateGLScene;
var r, i, n: integer;
begin
    if GLHUDTextObjName.TagFloat > 0 then begin
      GLHUDTextObjName.TagFloat := GLHUDTextObjName.TagFloat - GLCadencer.FixedDeltaTime;
      GLHUDTextObjName.ModulateColor.Alpha := max(0, min(1, GLHUDTextObjName.TagFloat / 2));
    end else begin
      GLHUDTextObjName.Text := '';
    end;
    GLHUDTextGeneric.Text := HUDStrings.Text;

    for r := 0 to WorldODE.Robots.Count-1 do begin
      with WorldODE.Robots[r] do begin
        // Shells
        for i := 0 to Shells.Count-1 do begin
          if Shells[i].GLObj = nil then continue;
          PositionSceneObject(Shells[i].GLObj, Shells[i].Geom);
          if Shells[i].GLObj is TGLCylinder then Shells[i].GLObj.pitch(90);
          //Shells[i].UpdateGLCanvas;
        end;

        // Solids
        for i := 0 to Solids.Count-1 do begin
          if Solids[i].GLObj <> nil then begin
            if Solids[i].kind = skMotorBelt then begin  // make the texture slide if there is a belt speed <> 0
              if Solids[i].GLObj.Material.TextureEx.Count > 0 then begin
                with Solids[i].GLObj.Material.TextureEx.Items[0] do begin
                  TextureOffset.Y := TextureOffset.Y - TextureScale.Y * GLCadencer.FixedDeltaTime * WorldODE.TimeFactor * Solids[i].BeltSpeed;
                  if TextureOffset.Y > 1 then TextureOffset.Y := TextureOffset.Y - 1;
                  if TextureOffset.Y < -1 then TextureOffset.Y := TextureOffset.Y + 1;
                end;
              end;
            end;
            PositionSceneObject(Solids[i].GLObj, Solids[i].Geom);
            if Solids[i].GLObj is TGLCylinder then Solids[i].GLObj.pitch(90);
          end;

          if Solids[i].AltGLObj <> nil then begin
            PositionSceneObject(Solids[i].AltGLObj, Solids[i].Geom);
          end;
          if Solids[i].ShadowGlObj <> nil then begin
            PositionSceneObject(Solids[i].ShadowGlObj, Solids[i].Geom);
          end;
          //TODO:Crash Solids[i].UpdateGLCanvas;

          {if Solids[i].CanvasGLObj <> nil then begin
            //Solids[i].PaintBitmap.Canvas.TextOut(0,0,floattostr(WorldODE.physTime));
            //Solids[i].CanvasGLObj.Material.Texture.Image.Invalidate;
            Solids[i].CanvasGLObj.Material.Texture.Image.BeginUpdate;
            img := Solids[i].CanvasGLObj.Material.Texture.Image.GetBitmap32(GL_TEXTURE_2D);
            img.AssignFromBitmap24WithoutRGBSwap(Solids[i].PaintBitmap);
            Solids[i].CanvasGLObj.Material.Texture.Image.endUpdate;
          end;}
        end;

        // Axis
        for i := 0 to Axes.Count-1 do begin
          if Axes[i].GLObj = nil then continue;
          Axes[i].GLSetPosition;
        end;

        //PositionSceneObject(WorldODE.TestBody.GLObj, WorldODE.TestBody.Geom);
        //if WorldODE.testBody.GLObj is TGLCylinder then WorldODE.testBody.GLObj.pitch(90);
      end;
    end;

    // Global Objects
    with WorldODE do begin
      // Things
      for i := 0 to Things.Count-1 do begin
        if assigned(Things[i].GLObj) then begin
          PositionSceneObject(Things[i].GLObj, Things[i].Geom);
          if Things[i].GLObj is TGLCylinder then Things[i].GLObj.pitch(90);
        end;

        if assigned(Things[i].AltGLObj) then begin
          PositionSceneObject(Things[i].AltGLObj, Things[i].Geom);
        end;

        if assigned(Things[i].ShadowGlObj) then begin
          PositionSceneObject(Things[i].ShadowGlObj, Things[i].Geom);
        end;

        Things[i].UpdateGLCanvas;
      end;

      //Sensors
      for i := 0 to Sensors.Count-1 do begin
        if Sensors[i].GLObj = nil then continue;
        n := Sensors[i].Rays.Count;
        if Sensors[i].Rays.Count > 0 then begin
          PositionSceneObject(Sensors[i].GLObj, Sensors[i].Rays[random(n-1)].Geom);
          //PositionSceneObject(Sensors[i].GLObj, Sensors[i].Rays[0].Geom);
          if (Sensors[i].GLObj is TGLCylinder) then Sensors[i].GLObj.pitch(90);
          //if (Sensors[i].GLObj is TGLDisk) then Sensors[i].GLObj.Turn(90);
          if Sensors[i].Measures[0].value = 0 then begin
            Sensors[i].GLObj.Material.FrontProperties.Emission.SetColor(0, 0, 0);
          end else begin
            Sensors[i].GLObj.Material.FrontProperties.Emission.SetColor(0.2, 0.2, 0.2);
          end;
        end;
      end;

    end;
end;



procedure TFViewer.GLCadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
var theta, w, Tq: double;
    i, r: integer;
    t_start, t_end, t_end_gl: int64;
    t_i1, t_i2, t_itot: int64;
    v1, v2: TdVector3;
//    txt: string;
    vs: TVector;
    Curpos: TPoint;
    newFixedTime: double;
    rx, ry, rz, rteta, arx, ary: double;
    RobotBound: double;
begin
  //GLScene.CurrentGLCamera.Position := GLDummyCamPos.Position;
  GLCamera.Position := GLDummyCamPos.Position;
  if WorldODE.ODEEnable <> False then begin
    QueryPerformanceCounter(t_start);
    t_itot := 0;

    t_last := t_act;
    QueryPerformanceCounter(t_act);

    // while WorldODE.physTime < newtime do begin
    newFixedTime := WorldODE.physTime + GLCadencer.FixedDeltaTime * WorldODE.TimeFactor;
    while WorldODE.physTime < newFixedTime do begin
      if FParams.CBEndlessWorld.Checked then begin
        RobotBound := 1; //TODO get it from the robot
        for i := 0 to WorldODE.Robots.Count - 1 do begin
          WorldODE.Robots[i].GetXYZTeta(rx, ry, rz, rteta);
          arx := 0;
          ary := 0;
          if rx > WorldODE.MaxWorldX - RobotBound then arx := WorldODE.MinWorldX - WorldODE.MaxWorldX + 3 * RobotBound;
          if rx < WorldODE.MinWorldX + RobotBound then arx := WorldODE.MaxWorldX - WorldODE.MinWorldX - 3 * RobotBound;

          if ry > WorldODE.MaxWorldY - RobotBound then ary := WorldODE.MinWorldY - WorldODE.MaxWorldY + 3 * RobotBound;
          if ry < WorldODE.MinWorldY + RobotBound then ary := WorldODE.MaxWorldY - WorldODE.MinWorldY - 3 * RobotBound;
          WorldODE.Robots[i].addXY(arx, ary);
        end;
      end;
      // Higher level controller (subsampled)
      WorldODE.SecondsCount := WorldODE.SecondsCount + WorldODE.Ode_dt;
      if WorldODE.SecondsCount > WorldODE.DecPeriod then begin
        WorldODE.SecondsCount := WorldODE.SecondsCount - WorldODE.DecPeriod;

        //t_last := t_act;
        //QueryPerformanceCounter(t_act);

        // Before control block
        for r := 0 to WorldODE.Robots.Count-1 do begin
          with WorldODE.Robots[r] do begin

            // Read Odometry
            for i := 0 to Axes.Count-1 do begin
              WorldODE.UpdateOdometry(Axes[i]);
            end;

            //for i := 0 to Sensors.Count - 1 do begin
            //  Sensors[i].NoiseModel;
            //end;

            // Fill RemState
            if r = Fparams.LBRobots.ItemIndex then begin
              //UDP.RemoteHost:=EditIP.text;
              FillRemote(r);
            end;

            FParams.ShowRobotPosition(r);

            // Default Control values are zero
            for i := 0 to Axes.Count-1 do begin
              Axes[i].ref.volts := 0;
              Axes[i].ref.w := 0;
              Axes[i].ref.Torque := 0;
            end;

          end;
        end;

        // Model Sensor Noise
        //with WorldODE do begin
        //  for i := 0 to Sensors.Count - 1 do begin
        //    Sensors[i].NoiseModel;
        //  end;
        //end;
        FParams.ShowGlobalState;

        if Fparams.RGControlBlock.ItemIndex = 1 then begin  // Script controller
          FEditor.RunOnce; // One call to the script, in the begining, for all robots
          if FEditor.SimTwoCloseRequested then begin
            close;
            exit;
          end;
        end;

        for r := 0 to WorldODE.Robots.Count-1 do begin
          with WorldODE.Robots[r] do begin

            // Call the selected Decision System
            if Fparams.RGControlBlock.ItemIndex = 0 then begin
              zeromemory(@KeyVals[0], sizeof(KeyVals));
              ReadKeyVals(KeyVals);
              if r = Fparams.LBRobots.ItemIndex then begin
                for i := 0 to WorldODE.Robots[r].Wheels.Count-1 do begin
                  Wheels[i].Axle.Axis[0].ref.volts := Keyvals[i] * Wheels[i].Axle.Axis[0].Motor.Vmax;
                  Wheels[i].Axle.Axis[0].ref.w := Keyvals[i]*30; //TODO: angular speed constant
                end;
              end;
            {end else if Fparams.RGControlBlock.ItemIndex = 1 then begin  // Script controller
              if r = 0 then FEditor.RunOnce; // One call to the script, in the begining, for all robots
              if FEditor.SimTwoCloseRequested then begin
                close;
                exit;
              end;}
            end else if Fparams.RGControlBlock.ItemIndex = 2 then begin  // LAN controller
              {TODO Fparams.UDPServer.SendBuffer(Fparams.EditRemoteIP.Text, 9801, RemState, sizeof(RemState));
              // Test if A new position was requested
              if RemControl.num = r+1 then begin
                SetXYZTeta(RemControl.x, RemControl.y, RemControl.z, RemControl.teta);
              end;
              // Copy Remote Control values to Wheel Structs
              for i := 0 to Wheels.Count-1 do begin
                Wheels[i].Axle.Axis[0].ref.volts := RemControl.u[i];
                Wheels[i].Axle.Axis[0].ref.w := RemControl.Wref[i];
              end;
              // Default Remote Control values is zero
              ZeroMemory(@RemControl,sizeof(RemControl));
              }
            end;
            //Sleep(1);


            FChart.AddSample(r, WorldODE.physTime);
          end;
        end;
        Fparams.ShowRobotState;
      end;
      // End of High level (and subsampled) control

      //Use motors and frictions to calculate axis torques and forces
      for r := 0 to WorldODE.Robots.Count-1 do begin
        //if WorldODE.Robots[r].ForceMoved then begin
          //WorldODE.Robots[r].ForceMoved := false;
          //GLCadencer.Mode := cmManual;
          //continue;
        //end;

        // Motores no eixo das rodas e atritos
        for i := 0 to WorldODE.Robots[r].Axes.Count-1 do begin
          with WorldODE.Robots[r] do begin
            //if not active then continue; //TODO
            theta := Axes[i].GetPos();
            w := Axes[i].GetSpeed();
            //if not Axes[i].Motor.active then continue; //TODO

            //AxisTorqueModel(Axes[i], Theta, Axes[i].filt_speed, Tq);
            AxisTorqueModel(Axes[i], Theta, w, WorldODE.Ode_dt ,Tq);
            // Apply it to the axis
            Axes[i].AddTorque(Tq);
            // Apply Extra torque
            Axes[i].AddTorque(Axes[i].ref.Torque);
          end;
        end;

        // Robot Main Body extra Frictions
        {if (WorldODE.Robots[r].MainBody <> nil) and
           (WorldODE.Robots[r].MainBody.Body <> nil) then begin
          // Robot Body Linear Friction
          v2 := Vector3ScalarMul(WorldODE.Robots[r].MainBody.Body.lvel, -1e-2);
          dBodyAddForce(WorldODE.Robots[r].MainBody.Body, v2[0], v2[1], v2[2]);

          // Robot Body Angular Friction
          v1 := Vector3ScalarMul(WorldODE.Robots[r].MainBody.Body.avel, -1e-2);
          dBodyAddTorque(WorldODE.Robots[r].MainBody.Body, v1[0], v1[1], v1[2]);
        end;}

        // Drag
        for i:=0 to WorldODE.Robots[r].Solids.Count-1 do begin
          with WorldODE.Robots[r].Solids[i] do begin
            if Drag <> 0 then begin
               v1 := dBodyGetLinearVel(Body)^;
               v1 := Vector3SUB(v1, WorldODE.WindSpeed);
               dBodyVectorFromWorld(Body, v1[0], v1[1], v1[2], v2);
               // Air Drag
               v1[0] := -0.5 * WorldODE.AirDensity * v2[0] * abs(v2[0])* Ax * Drag;
               v1[1] := -0.5 * WorldODE.AirDensity * v2[1] * abs(v2[1])* Ay * Drag;
               v1[2] := -0.5 * WorldODE.AirDensity * v2[2] * abs(v2[2])* Az * Drag;
               dBodyAddRelForce(Body, v1[0], v1[1], v1[2]);
                  //dBodyVectorToWorld(Body, v1[0], v1[1], v1[2], v2);
                  //dBodyAddForce(Body, -v2[0], -v2[1], -v2[2]);
               v1 := dBodyGetAngularVel(Body)^;
               dBodyVectorFromWorld(Body, v1[0], v1[1], v1[2], v2);
               v1[0] := -0.5 * WorldODE.AirDensity * v2[0] * abs(v2[0])* Ax * RollDrag;
               v1[1] := -0.5 * WorldODE.AirDensity * v2[1] * abs(v2[1])* Ay * RollDrag;
               v1[2] := -0.5 * WorldODE.AirDensity * v2[2] * abs(v2[2])* Az * RollDrag;

               dBodyVectorToWorld(Body, v1[0], v1[1], v1[2], v2);
               v2[0] := max(-100,min(100,v2[0]));
               v2[1] := max(-100,min(100,v2[1]));
               v2[2] := max(-100,min(100,v2[2]));
               dBodyAddTorque(Body, v2[0], v2[1], v2[2]);
               //dBodyAddRelTorque(Body, v1[0], v1[1], v1[2]);
            end;
          end;
        end;

        // Buoyancy
        dWorldGetGravity(WorldODE.world, v1);
        for i:=0 to WorldODE.Robots[r].Solids.Count-1 do begin
          with WorldODE.Robots[r].Solids[i] do begin
            if BuoyantMass <> 0 then begin
               v2 := Vector3ScalarMul(v1, BuoyantMass);
               dBodyAddForceAtRelPos(Body, v2[0], v2[1], v2[2], BuoyanceCenter[0], BuoyanceCenter[1], BuoyanceCenter[2]);
            end;
          end;
        end;

        // Thrusters
        for i:=0 to WorldODE.Robots[r].Solids.Count-1 do begin
          with WorldODE.Robots[r].Solids[i] do begin
            if kind = skPropeller then begin
               v1 := dBodyGetAngularVel(Body)^;
               //dBodyVectorFromWorld(Body, v1[0], v1[1], v1[2], v2);
               //dBodyAddRelForce(Body, 0.01*v2[0], 0, 0);
               dBodyAddForce(Body, Thrust * v1[0], Thrust * v1[1], Thrust * v1[2]);
            end;
          end;
        end;

      end; //end robot loop

      // Reset sensors measure
      with WorldODE do begin
        for i:=0 to Sensors.Count - 1 do begin
          Sensors[i].PreProcess(WorldODE.Ode_dt);
        end;
      end;

      if WorldODE.PickSolid <> nil then with WorldODE do begin
        if Focused then begin
          if IsKeyDown('q') then begin
            PickDist := PickDist * 1.001;
          end else if IsKeyDown('a') then begin
            PickDist := PickDist / 1.001;
          end;
        end;
        Curpos:= ScreenToClient(Mouse.CursorPos);
        vs :=  GLSceneViewer.Buffer.ScreenToVector(Curpos.X, GLSceneViewer.Buffer.ViewPort.Height - Curpos.y);
        NormalizeVector(Vs);
        scalevector(Vs, PickDist);
        AddVector(Vs, GLSceneViewer.Buffer.Camera.Position.AsVector);
        WorldODE.movePickJoint(vs.v[0], vs.v[1], vs.v[2]);
        WorldODE.UpdatePickJoint;
      end;

      // ODE in action Now!
      QueryPerformanceCounter(t_i1);
      WorldODE.WorldUpdate;
      QueryPerformanceCounter(t_i2);
      t_itot := t_itot + t_i2 - t_i1;

      // Post Process Sensors
      for i := 0 to WorldODE.Sensors.Count - 1 do begin
        with WorldODE.Sensors[i] do begin
          PostProcess;
          TimeFromLastMeasure := TimeFromLastMeasure + WorldODE.Ode_dt;
          if TimeFromLastMeasure > Period then begin
            TimeFromLastMeasure := TimeFromLastMeasure - Period;
            UpdateMeasures;
            NoiseModel;
          end;
        end;
      end;

    end;
    //End Physics Loop

    QueryPerformanceCounter(t_end);
    //FParams.EditDebug.text := format('%.2f (%.2f)[%.2f]',[(t_end - t_start)/t_delta, t_itot/t_delta, (t_act - t_last)/t_delta]);

    // GLScene

    //Update all GLscene Parts.
    UpdateGLScene;

    // Update Camera Position
    UpdateCamPos(FParams.RGCamera.ItemIndex);

    FParams.ShowCameraConfig(GLCamera);

    if assigned(WorldODE.MemCameraSolid) then begin
      GLCameraMem.Position := WorldODE.MemCameraSolid.GLObj.Position;
      GLCameraMem.Direction := WorldODE.MemCameraSolid.GLObj.Direction;
      GLCameraMem.up := WorldODE.MemCameraSolid.GLObj.up;
    end;
    //UpdateGLCameras;

   // In scene camera
   // GLMemoryViewer.Render(nil);
   // GLBmp32 := GLMemoryViewer.Buffer.CreateSnapShot;
    //FDimensions.GLSceneViewer.Refresh;

    QueryPerformanceCounter(t_end_gl);
    FParams.EditDebug.text := format('%6.2f (%6.2f) %0.2f [%0.2f]',[(t_end_gl - t_start)/t_delta, t_itot/t_delta, (t_end_gl - t_end)/t_delta, (t_act - t_last)/t_delta]);

    //GLSceneViewer.Invalidate;

  end;
end;


procedure TFViewer.UpdateGLCameras;
var GLBmp32: TGLBitmap32;
    Bmp32: TBitmap;
    JpegImage: TJpegImage;
    Stream: TMemoryStream;
    i, sz, MTU: integer;
begin
  //Fcameras.UpdateGLCameras;
  exit;
  {
  if FCameras.Visible then begin
    with WorldODE do begin
      inc(RemoteImageDecimation);
      if RemoteImageDecimation >= GLCameraMem.Tag then begin
        RemoteImageDecimation := 0;
      end else exit;
    end;

    GLBmp32 := FCameras.GLSceneViewer.Buffer.CreateSnapShot;
    Bmp32 := GLBmp32.Create32BitsBitmap;
    //FDimensions.ImageCam.Canvas.Draw(0,0, Bmp32);
    Stream := TMemoryStream.Create;
    JpegImage := TJpegImage.Create;
    JpegImage.Smoothing := true;
    JpegImage.Performance := jpBestQuality;
    JpegImage.CompressionQuality := FCameras.SBQuality.Position;

    JpegImage.Assign(Bmp32);
    JpegImage.Compress;
    JpegImage.SaveToStream(Stream);
    FCameras.EditJPGSize.Text := inttostr(Stream.Position);

    if FCameras.CBSendImage.Checked then begin
      MTU := 512;
      with WorldODE do begin
        RemoteImage.id := $5241;
        inc(RemoteImage.Number);
        RemoteImage.size := Stream.Position;
        RemoteImage.NumPackets := (RemoteImage.size + MTU - 1) div MTU;
        RemoteImage.ActPacket := 0;

        Stream.Seek(0, soFromBeginning);

        for i := 0 to RemoteImage.NumPackets - 1 do begin
          RemoteImage.ActPacket := i;
          sz := min(RemoteImage.size - (i * MTU), MTU);
          Stream.readBuffer(RemoteImage.data[0], sz);
          Fparams.UDPServer.SendBuffer(Fparams.EditRemoteIP.Text, 9898, RemoteImage, sizeof(RemoteImage) - 512 + sz);
        end;
      end;
    end;      
    if FCameras.CBShowJpeg.Checked then begin
      Stream.Seek(0, soFromBeginning);
      JpegImage.LoadFromStream(Stream);
      FCameras.ImageCam.Canvas.Draw(0,0, JpegImage);
    end;
    Stream.Free;
    JpegImage.Free;
    Bmp32.free;
    GLBmp32.Free;
  end;
  }
end;


procedure TFViewer.UpdateCamPos(CMode: integer);
begin
  case CMode of
    0: begin
         GLCamera.TargetObject := GLDummyTargetCam;
         GLCamera.Position := GLDummyCamPos.Position;
       end;
    1: begin
         GLCamera.TargetObject := GLDummyTargetCamRel;
         GLCamera.Position := GLDummyCamPos.Position;
       end;
    2: begin
         GLCamera.TargetObject := GLDummyTargetCamRel;
         GLCamera.Position.X := GLCamera.TargetObject.AbsolutePosition.v[0] + GLDummyCamPosRel.Position.X;
         GLCamera.Position.Y := GLCamera.TargetObject.AbsolutePosition.v[1] + GLDummyCamPosRel.Position.Y;
       end;
    3: begin
         GLCamera.TargetObject := GLDummyTargetCamRel;
         with RemState do begin
           GLCamera.Position.X := GLCamera.TargetObject.AbsolutePosition.v[0] - 3*cos(Robot.teta);
           GLCamera.Position.Y := GLCamera.TargetObject.AbsolutePosition.v[1] - 3*sin(Robot.teta);
         end;
       end;
    4: begin
         GLCamera.TargetObject := GLDummyTargetCam;
         GLCamera.Position.x := 0;
         GLCamera.Position.y := -0.001;
         //GLCamera.Position.z := 2;
       end;
  end;
end;

function PosLastChar(c: char; S: string): Integer;
var i: integer;
begin
//  result := 0;
  i := length(s);
  while i > 0 do begin
    if s[i] = c then break;
  end;
  result := i;
end;


procedure TFViewer.FormClose(Sender: TObject; var Action: TCloseAction);
var fl: string;
    Slist: TStringList;
    i: integer;
begin
  // Save the forms z-order so it can be later restored
  Slist := TStringList.Create;
  try
    for i := 0 to Screen.FormCount - 1 do begin
      Slist.add(Screen.Forms[i].Name);
    end;
    Slist.SaveToFile('Zorder.txt');
  finally
    Slist.Free;
  end;

  FSheets.Close;
  FSceneEdit.Close;
  FParams.Close;
  
  //Execute Destroy Physics
  GLCadencer.Enabled := False;
  WorldODE.ODEEnable := False;
  WorldODE.destroy;
  WorldODE := nil;

  fl := extractfilepath(application.exename) + 'Scene.cfg';
  Slist := TStringList.Create;
  try
    try
      Slist.Add(extractfilename(GetCurrentDir));
      Slist.SaveToFile(fl);
    finally
      Slist.Free;
    end;
  except
    on E: Exception do showmessage(E.Message);
  end;

  FSceneEdit.ReSpawn;
end;

procedure TFViewer.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  //Mouse wheel zoom + -
  if (WorldODE.PickSolid = nil) or (WorldODE.PickJoint = nil ) then begin
    //GLScene.CurrentGLCamera.AdjustDistanceToTarget(Power(1.1, WheelDelta / 120));
    //GLDummyCamPos.Position := GLScene.CurrentGLCamera.Position;
    GLCamera.AdjustDistanceToTarget(Power(1.1, WheelDelta / 120));
    GLDummyCamPos.Position := GLCamera.Position;
    UpdateCamPos(FParams.RGCamera.ItemIndex);
  //Mouse wheel object distance + -
  end else with WorldODE do begin
    PickDist := PickDist * Power(1.1, WheelDelta / 120);
  end;
end;

procedure TFViewer.FormShow(Sender: TObject);
var SL: TStringList;
    i, j, n: integer;
begin
  // Recover the forms z-order
  if FileExists('zorder.txt') then begin
    SL := TStringList.Create;
    try
      SL.LoadFromFile('zorder.txt');
      // show them from back to front
      for i := SL.Count - 1 downto 0 do begin
        if pos(SL[i], 'FParams|FEditor|FChart|FSheets|FSceneEdit') <> 0 then begin
          for j := 0 to Screen.FormCount - 1 do begin
            if SL[i] = Screen.Forms[j].Name then begin
              Screen.Forms[j].Show;
            end;
          end;
        end;
      end;
    finally
      SL.Free;
    end;
  end else begin   // if there is no z-order file then use the default sequence
    FParams.show;
    FEditor.show;
    FChart.show;
    FSheets.show;
    FSceneEdit.Show;
  end;

  if WorldODE.XMLErrors.Count > 0 then begin
    FSceneEdit.LBErrors.Items.AddStrings(WorldODE.XMLErrors);
  end;

  //SetTrailCount(strtointdef(FParams.EditTrailsCount.Text, 8), strtointdef(FParams.EditTrailSize.Text, 200));
  FParams.BSetTrailParsClick(Sender);

  FParams.ShowParsedScene;

  MakeFullyVisible();
  UpdateGLScene;

  GLCadencer.enabled := true;
  //TODO TestTexture;
  //GLHUDTextGeneric.Text := 'Test' + #13 + '2nd line?';
  TestSaveTexture;

  n := WorldODE.Sensors.Count;
  for i := 0 to n - 1 do begin
    FParams.MemoDebug.Lines.Add(format('sensor %d: %s',[i, WorldODE.Sensors[i].ID]));
  end;

end;

procedure TFViewer.TestSaveTexture;
begin
//  TOmniXMLWriter.SaveToFile(GLMaterialLibrary.Materials.Items[3], 'filename.xml', pfNodes, ofIndent);
end;



procedure TFViewer.TimerTimer(Sender: TObject);
var fps: double;
    script: string;
begin
  fps := GLSceneViewer.FramesPerSecond;
  GLSceneViewer.ResetPerformanceMonitor;
  if FParams.RGControlBlock.ItemIndex = 1 then begin
    script := ' - Script Running';
  end else begin
    script := '';
  end;
  Caption:=Format('SimTwo - v%s [%s] (%.1f FPS)%s', [InfoData[3], CurrentProject, fps, script]);
end;


procedure TFViewer.TestTexture;
var img: TGLBitmap32;
    thebmp: TBitmap;
    t_start, t_end, t_delta: int64;
begin

  thebmp := TBitmap.Create;
  thebmp.Width := 128;
  thebmp.Height := 128;
  thebmp.PixelFormat := pf24bit;
  QueryPerformanceFrequency(t_delta);
  QueryPerformanceCounter(t_start);
  thebmp.Canvas.TextOut(0,0,'Hello World!');
  thebmp.Canvas.Ellipse(0,0,127,127);
  thebmp.Canvas.TextOut(0,0,floattostr(WorldODE.physTime));

  //img := GLCube1.Material.Texture.Image.GetBitmap32(GL_TEXTURE_2D);
  //img := GLCube1.Material.TextureEx.Items[0].Texture.Image.GetBitmap32(GL_TEXTURE_2D);
  //img := GLPlaneTex.Material.Texture.Image.GetBitmap32(GL_TEXTURE_2D);
  GLPlane1.Material.Texture.Image.Invalidate;
  //GLPlane1.Material.Texture.Image.ReleaseBitmap32;
  //TODO img := GLPlane1.Material.Texture.Image.GetBitmap32(GL_TEXTURE_2D);
  img := GLPlane1.Material.Texture.Image.GetBitmap32();

  img.AssignFromBitmap24WithoutRGBSwap(thebmp);
  QueryPerformanceCounter(t_end);
  thebmp.Free;
  FParams.EditDebug2.text := format('Texture: %.2f ',[1e6*(t_end - t_start)/t_delta]);

end;

procedure TWorld_ODE.SetCameraTarget(r: integer);
begin
  if (r < 0) or (r >= Robots.Count) then exit;
  if Robots[r].MainBody <> nil then begin
    if Robots[r].MainBody.GLObj<>nil then begin
      FViewer.GLDummyCamPosRel.MoveTo(Robots[r].MainBody.GLObj);
      FViewer.GLDummyTargetCamRel.MoveTo(Robots[r].MainBody.GLObj);
    end;
  end;
end;


procedure TFViewer.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  FParams.FormCloseQuery(Sender, CanClose);
  FEditor.FormCloseQuery(Sender, CanClose);
  if CanClose then
    FSceneEdit.FormCloseQuery(Sender, CanClose);
end;

procedure TFViewer.ShowOrRestoreForm(Fm: TForm);
begin
  Fm.Show;
  if Fm.WindowState = wsMinimized then
    Fm.WindowState := wsNormal;
end;


procedure TFViewer.MenuChartClick(Sender: TObject);
begin
  ShowOrRestoreForm(FChart);
end;

procedure TFViewer.MenuConfigClick(Sender: TObject);
begin
  ShowOrRestoreForm(FParams);
end;

procedure TFViewer.MenuEditorClick(Sender: TObject);
begin
  ShowOrRestoreForm(FEditor);
end;


procedure TFViewer.MenuSceneClick(Sender: TObject);
begin
  ShowOrRestoreForm(FSceneEdit);
end;

procedure TFViewer.MenuSheetsClick(Sender: TObject);
begin
  ShowOrRestoreForm(FSheets);
end;


procedure TFViewer.FormDestroy(Sender: TObject);
begin
  HUDStrings.Free;
end;

procedure TFViewer.SetTrailCount(NewCount, NodeCount: integer);
var i, OldCount: integer;
    GLLines: TGLLines;
begin
  oldCount := GLDTrails.Count;
  if OldCount = NewCount then exit;
  if OldCount > NewCount then begin
    for i := 1 to OldCount - NewCount do begin
      GLDTrails.Children[NewCount-1].Free;
    end;
  end;
  if OldCount < NewCount then begin
    for i := 1 to NewCount - OldCount  do begin
      GLLines := TGLLines.CreateAsChild(GLDTrails);
      GLLines.LineWidth := 1;
      GLLines.NodesAspect := lnaInvisible;
      GLLines.Tag := NodeCount; //Stores maximum number of nodes
    end;
  end;
end;

procedure TFViewer.AddTrailNode(T: integer; x, y, z: double);
var GLLines: TGLLines;
begin
  GLLines := (GLDTrails.Children[T] as TGLLines);
  GLLines.AddNode(x, y, z);
  while GLLines.Nodes.Count > GLLines.Tag do GLLines.Nodes.Delete(0);
end;


procedure TFViewer.DelTrailNode(T: integer);
begin
  (GLDTrails.Children[T] as TGLLines).Nodes.Delete(0);
end;


procedure TFViewer.MenuSnapshotClick(Sender: TObject);
var GLBitmap: TBitmap;
    JPEGImage: TJPEGImage;  //Requires the "jpeg" unit added to "uses" clause.
begin
  GLBitmap := GLSceneViewer.Buffer.CreateSnapShotBitmap;
  try
    //GLBitmap.SaveToFile('snapshot.bmp');
    JPEGImage := TJPEGImage.Create;
    try
      JPEGImage.Assign(GLBitmap);
      JPEGImage.CompressionQuality := 90;
      JPEGImage.SaveToFile('snapshot.jpg');
    finally
      JPEGImage.free;
    end;
  finally
    GLBitmap.free;
  end;
end;

function TFViewer.GetMeasureText: string;
var dx, dy, dz, d: double;
begin
  with GLLineMeasure do begin
    dx := Nodes[1].X - Nodes[0].X;
    dy := Nodes[1].Y - Nodes[0].Y;
    dz := Nodes[1].Z - Nodes[0].Z;
    d := sqrt(sqr(dx) + sqr(dy) + sqr(dz));
  end;
  result := format('(%.5g, %.5g, %.5g) %.5g',[dx, dy, dz, d]);
end;


procedure TFViewer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (ssctrl in Shift) then begin
    if (key = ord('G')) then MenuConfig.Click;
    if (key = ord('T')) then MenuChart.Click;
    if (ssShift in Shift) and (key = ord('T')) then FChart.CBFreeze.Checked := not FChart.CBFreeze.Checked;
    if (key = ord('E')) then MenuEditor.Click;
    if (key = ord('S')) then MenuScene.Click;
    if (key = ord('H')) then MenuSheets.Click;
    if (key = ord('I')) then MenuSnapshot.Click;
    if (key = ord('N')) then MenuChangeScene.Click;
    if (key = ord('A')) then MenuCameras.Click;
  end;

  HandleMeasureKeys(Key, Shift);
end;


procedure TFViewer.HandleMeasureKeys(var Key: Word;  Shift: TShiftState);
begin
  if (key = ord('0')) or (key = $DC) then begin
    GLLineMeasure.Visible := not GLLineMeasure.Visible;
  end else if (key = ord('1')) then begin
    GLLineMeasure.Nodes[0].AsVector := WorldODE.PickPoint;
  end else if (key = ord('2')) then begin
    GLLineMeasure.Nodes[1].AsVector := WorldODE.PickPoint;
  end;

  if GLLineMeasure.Visible then begin
    GLHUDTextMeasure.Text := GetMeasureText;
  end else begin
    GLHUDTextMeasure.Text := '';
  end;
end;

procedure TFViewer.MenuChangeSceneClick(Sender: TObject);
//var t: Tmemorystream
begin
  FSceneEdit.MenuChange.Click;
end;

procedure TFViewer.MenuAbortClick(Sender: TObject);
begin
  if MessageDlg('Aborting means that any unsaved data will be lost!'+crlf+
                'Abort anyway?',
                 mtConfirmation , [mbOk,mbCancel], 0) = mrOk then halt(1);
end;

procedure TFViewer.MenuQuitClick(Sender: TObject);
begin
  close;
end;


procedure TWorld_ODE.DeleteSolid(Solid: TSolid);
begin
  (OdeScene as TGLShadowVolume).Occluders.RemoveCaster(Solid.GLObj);
  ODEScene.Remove(Solid.GLObj, false);
  if (Solid.GLObj = oldpick) or
     (Solid.AltGLObj = oldpick) or
     (Solid.ShadowGlObj = oldpick) or
     (Solid.CanvasGLObj = oldpick) or
     (Solid.extraGLObj = oldpick) then begin
    oldpick := nil;
  end;
  Solid.extraGLObj.Free;
  Solid.CanvasGLObj.Free;
  Solid.ShadowGlObj.Free;
  Solid.AltGLObj.Free;
  Solid.GLObj.Free;
  dGeomDestroy(Solid.Geom);
  dBodyDestroy(Solid.Body);
end;

procedure TFViewer.MenuCamerasClick(Sender: TObject);
begin
  ShowOrRestoreForm(FCameras);
end;

procedure TFViewer.TimerCadencerTimer(Sender: TObject);
begin
  GLCadencer.Progress;
end;


end.



// TODO
// lembrar o estado fechado de janelas
// Actuator: Electromagnet
// Zona morta no PID
// -Passadeiras- (falta controlar a aceleração delas)
// -Thrusters- + turbulence
// alternate globject {For TSolids only now}
// world wind
// Channels
// yasml
// Texture panel
// Scale not
// rotation only in z for the robots
// 3ds offset

// Optional/configurable walls ??
// axis turn count for better limits

// * Sensores de linha branca  1
// Sonar 1-n
// * Beacons/landmark  0
// Receptores de beacons  1-nb
//  digitais
//  analógicos
//  indicandor de direcção
//  indicandor de orientação do beacon
// Bussola       0
// Giroscopios   0
// Acelerometros 0
// Measure rate sync

// Solve color input confusion
// Show scene tree  +
// Show tags not used

// Quaternions
// charts for the spreadsheet
// multiple spreadsheets
// Decorations
// spray

// Solenoid
// F = 1/2 i^2 K/(1 + hx)^2

//http://www.ngdc.noaa.gov/geomag/magfield.shtml
//    *  Declination (D) positive east, in degrees and minutes
//      Annual change (dD) positive east, in minutes per year
//    * Inclination (I) positive down, in degrees and minutes
//      Annual change (dI) positive down, in minutes per year
//    * Horizontal Intensity (H), in nanoTesla
//      Annual change (dH) in nanoTesla per year
//    * North Component of H (X), positive north, in nanoTesla
//      Annual change (dX) in nanoTesla per year
//    * East Component of H (Y), positive east, in nanoTesla
//      Annual change (dY) in nanoTesla per year
//    * Vertical Intensity (Z), positive down, in nanoTesla
//      Annual change (dZ) in nanoTesla per year
//    * Total Field (F), in nanoTesla
//      Annual change (dF) in nanoTesla per year

//http://www.ngdc.noaa.gov/geomagmodels/struts/calcPointIGRF
//Results for date: 2010.419189453125
//Declination = -3.392° changing by 0.133 °/year
//Inclination = 56.015° changing by -0.027 °/year
//X component = 24,988.42 changing by 27.9 nT/year
//Y component = -1,481.19 changing by 56.49 nT/year
//Z component = 37,132.58 changing by -1.64 nT/year
//Horizontal Intensity = 25,032.28 changing by 24.58 nT/year
//Total Intensity = 44,782.18 changing by 12.38 nT/year

program CAS_Studio;

{$R 'images.res' 'images\images.rc'}

uses
  Vcl.Forms,

  // Main
  MainFormU     in 'src\MainFormU.pas',
  AudioManagerU in 'src\AudioManagerU.pas',
  TypesU        in 'src\TypesU.pas',
  UtilsU        in 'src\UtilsU.pas',

  // Surface classes
  PlaylistSurfaceU  in 'src\gui\PlaylistSurfaceU.pas',

  // Visual classes
  VisualObjectU in 'src\gui\VisualObjectU.pas',
  VisualTrackU  in 'src\gui\VisualTrackU.pas',
  VisualTypesU  in 'src\gui\VisualTypesU.pas',

  // Managers
  PlaylistManagerU   in 'src\bus\PlaylistManagerU.pas',

  // Frames
  InfoFrameU      in 'src\frames\InfoFrameU.pas',
  RackFrameU      in 'src\frames\RackFrameU.pas',
  PlaylistFrameU  in 'src\frames\PlaylistFrameU.pas',

  // Cas Libraries
  CasEngineU      in 'deps\CasAudioEngine\src\CasEngineU.pas',
  CasAsioU        in 'deps\CasAudioEngine\src\CasAsioU.pas',
  CasDirectSoundU in 'deps\CasAudioEngine\src\CasDirectSoundU.pas',
  CasDsThreadU    in 'deps\CasAudioEngine\src\CasDsThreadU.pas',
  CasTrackU       in 'deps\CasAudioEngine\src\CasTrackU.pas',
  CasMixerU       in 'deps\CasAudioEngine\src\CasMixerU.pas',
  CasPlaylistU    in 'deps\CasAudioEngine\src\CasPlaylistU.pas',
  CasConstantsU   in 'deps\CasAudioEngine\src\CasConstantsU.pas',
  CasTypesU       in 'deps\CasAudioEngine\src\CasTypesU.pas',
  CasDecoderU     in 'deps\CasAudioEngine\src\CasDecoderU.pas',
  CasEncoderU     in 'deps\CasAudioEngine\src\CasEncoderU.pas',
  CasDatabaseU    in 'deps\CasAudioEngine\src\CasDatabaseU.pas',
  CasBasicFxU     in 'deps\CasAudioEngine\src\CasBasicFxU.pas',
  CasUtilsU       in 'deps\CasAudioEngine\src\CasUtilsU.pas',

  // ASIO
  Asiolist      in 'deps\CasAudioEngine\Asio\AsioList.pas',
  Asio          in 'deps\CasAudioEngine\Asio\Asio.pas',

  // Acrylic Form
  AcrylicControlU    in 'deps\TAcrylicForm\src\AcrylicControlU.pas',
  AcrylicGhostPanelU in 'deps\TAcrylicForm\src\AcrylicGhostPanelU.pas',
  AcrylicFrameU      in 'deps\TAcrylicForm\src\AcrylicFrameU.pas',
  AcrylicScrollBoxU  in 'deps\TAcrylicForm\src\AcrylicScrollBoxU.pas',
  AcrylicFormU       in 'deps\TAcrylicForm\src\AcrylicFormU.pas',
  AcrylicButtonU     in 'deps\TAcrylicForm\src\AcrylicButtonU.pas',
  AcrylicLabelU      in 'deps\TAcrylicForm\src\AcrylicLabelU.pas',
  AcrylicTypesU      in 'deps\TAcrylicForm\src\AcrylicTypesU.pas',
  AcrylicUtilsU      in 'deps\TAcrylicForm\src\AcrylicUtilsU.pas',
  AcrylicTrackU      in 'deps\TAcrylicForm\src\AcrylicTrackU.pas',
  AcrylicKnobU       in 'deps\TAcrylicForm\src\AcrylicKnobU.pas',
  AcrylicTrackBarU   in 'deps\TAcrylicForm\src\AcrylicTrackBarU.pas';


{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

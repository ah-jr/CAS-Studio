unit TypesU;

interface

uses
  Winapi.Windows,
  Winapi.Messages;

const
  FID_Info        = 0;
  FID_Rack        = FID_Info + 1;
  FID_Playlist    = FID_Rack + 1;
  FID_Mixer       = FID_Playlist + 1;

  c_nMsInSec    = 1000;
  c_nSecInMin   = 60;

  c_dDefBPM     = 130;

  //////////////////////////////////////////////////////////////////////////////
  ///  Default Frame sizes
  c_dRackLeft       = 0.0;
  c_dRackTop        = 0.0;
  c_dRackWidth      = 0.25;
  c_dRackHeight     = 1;

  c_dPlaylistLeft   = 0.25;
  c_dPlaylistTop    = 0.0;
  c_dPlaylistWidth  = 0.75;
  c_dPlaylistHeight = 0.6;

  c_dMixerLeft      = 0.25;
  c_dMixerTop       = 0.6;
  c_dMixerWidth     = 0.75;
  c_dMixerHeight    = 0.4;

type
  IAudioListener = interface
    procedure UpdateBPM     (a_dOldBPM, a_dNewBPM : Double);
    procedure UpdateProgress(a_dProgress : Double);
    procedure AddClip       (a_nClipID  : Integer; a_nIndex : Integer = -1);
    procedure AddTrack      (a_nTrackID : Integer);
    procedure RemoveTrack   (a_nTrackID : Integer);
    procedure UpdateGUI;
    procedure DriverChange;
  end;

  TIntArray = Array of Integer;
  PIntArray = ^TIntArray;


implementation

end.

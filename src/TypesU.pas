unit TypesU;

interface

uses
  Winapi.Windows,
  Winapi.Messages;

const
  FID_Info        = 0;
  FID_Rack        = FID_Info + 1;
  FID_Playlist    = FID_Rack + 1;

  c_nMsInSec    = 1000;
  c_nSecInMin   = 60;

  c_dDefBPM     = 130;

type
  IAudioListener = interface
    procedure UpdateProgress(a_dProgress : Double);
    procedure AddTrack      (a_nTrackID : Integer);
    procedure RemoveTrack   (a_nTrackID  : Integer);
    procedure UpdateGUI;
    procedure DriverChange;
  end;

  TIntArray = Array of Integer;
  PIntArray = ^TIntArray;


implementation

end.

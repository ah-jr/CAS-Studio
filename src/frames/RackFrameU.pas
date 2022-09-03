unit RackFrameU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.UITypes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  AcrylicFrameU,
  AudioManagerU;


  type
  TRackFrame = class(TAcrylicFrame)
  private
    m_AudioManager : TAudioManager;

  public
    constructor Create(AOwner : TComponent; a_AudioManager : TAudioManager); reintroduce; overload;
    destructor  Destroy; override;

  end;

implementation
uses
  AcrylicLabelU;

//==============================================================================
constructor TRackFrame.Create(AOwner : TComponent; a_AudioManager : TAudioManager);
begin
  Inherited Create(AOwner);

  Name := 'RackFrame';

  m_AudioManager := a_AudioManager;

  Resisable               := False;
  Width                   := 280;
  Height                  := 350;
  Title                   := 'Track Rack';
end;

//==============================================================================
destructor  TRackFrame.Destroy;
begin
  Inherited;
end;

end.

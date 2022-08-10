unit PlaylistFrameU;

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
  PlaylistU;


  type
  TPlaylistFrame = class(TAcrylicFrame)
  private
    m_Playlist : TPlaylist;

    procedure WMNCSize(var Msg: TWMSize); message WM_SIZE;

  public
    constructor Create(AOwner : TComponent); override;
    destructor  Destroy; override;

  end;

implementation
uses
  AcrylicLabelU;

//==============================================================================
constructor TPlaylistFrame.Create(AOwner : TComponent);
begin
  Inherited;

  Name := 'PlaylistFrame';

  m_Playlist := TPlaylist.Create(Body);
  m_Playlist.Parent := Body;
  m_Playlist.Left := 0;
  m_Playlist.Top  := 0;
end;

//==============================================================================
destructor  TPlaylistFrame.Destroy;
begin
  Inherited;
end;

//==============================================================================
procedure TPlaylistFrame.WMNCSize(var Msg: TWMSize);
begin
  inherited;

  m_Playlist.Width  := Body.Width;
  m_Playlist.Height := Body.Height;
end;

end.

unit InfoFrameU;

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
  AcrylicFrameU;


  type
  TInfoFrame = class(TAcrylicFrame)
  private

  public
    constructor Create(AOwner : TComponent); override;
    destructor  Destroy; override;

  end;

implementation
uses
  AcrylicLabelU;

//==============================================================================
constructor TInfoFrame.Create(AOwner : TComponent);
var
  lblTitle : TAcrylicLabel;
  lblText  : TAcrylicLabel;
begin
  Inherited;

  Name := 'InfoFrame';

  Resisable               := False;
  Width                   := 280;
  Height                  := 350;
  Title                   := 'Information';
  Visible                 := False;

  lblTitle                := TAcrylicLabel.Create(Body);
  lblTitle.Parent         := Body;
  lblTitle.Left           := 5;
  lblTitle.Top            := 5;
  lblTitle.Width          := Width - 10;
  lblTitle.Height         := 40;
  lblTitle.Color          := Body.Color;
  lblTitle.WithBackground := True;
  lblTitle.Font.Size      := 11;
  lblTitle.Font.Style     := [fsBold];
  lblTitle.Text           := 'Cas Studio 1.0';

  lblText                 := TAcrylicLabel.Create(Body);
  lblText.Parent          := Body;
  lblText.Left            := 5;
  lblText.Top             := 45;
  lblText.Width           := Width - 10;
  lblText.Height          := Height - 10;
  lblText.Color           := Body.Color;
  lblText.Font.Size       := 9;
  lblText.WithBackground  := True;

  lblText.Texts.Add('Created by A. H. Junior - 2021');
  lblText.Texts.Add('Version 1.0');
  lblText.Texts.Add('');
  lblText.Texts.Add('Extra functionalities:');
  lblText.Texts.Add(' 1. Shift + scroll in tracks to rearrange them');
  lblText.Texts.Add(' 2. Press numbers (1-9) to jump to a specific ');
  lblText.Texts.Add('    track');
  lblText.Texts.Add(' 3. Double click in knobs to reset value (0.5)');
  lblText.Texts.Add(' 4. Press P/T button to change trackbar to');
  lblText.Texts.Add('    playlist/track mode');
  lblText.Texts.Add(' 5. Press SpaceBar to play/pause');
  lblText.Texts.Add('');
  lblText.Texts.Add('');
  lblText.Texts.Add('Add your suggestions as Issues at:');
  lblText.Texts.Add('https://github.com/ah-jr/CAS-Studio');
end;

//==============================================================================
destructor  TInfoFrame.Destroy;
begin
  Inherited;
end;

end.

unit UtilsU;

interface

uses
  Winapi.Windows,
  Winapi.Messages;

  function BpmToMpb(a_dBpm : Double) : Double;
  function MpbToBpm(a_dMpb : Double) : Double;
  function BeatsToMs(a_dBpm : Double; a_dBeats : Double) : Double;
  function MsToBeats(a_dBpm : Double; a_dMs : Double) : Double;
  function SampleCountToMs(a_nSmpCount : Integer; a_dSmpRate : Double) : Double;
  function MsToSampleCount(a_dMs : Double; a_dSmpRate : Double) : Integer;

implementation

uses
  TypesU;

//==============================================================================
function BpmToMpb(a_dBpm : Double) : Double;
begin
  Result := c_nSecInMin * (c_nMsInSec / a_dBpm);
end;

//==============================================================================
function MpbToBpm(a_dMpb : Double) : Double;
begin
  Result := c_nSecInMin * (c_nMsInSec / a_dMpb);
end;

//==============================================================================
function BeatsToMs(a_dBpm : Double; a_dBeats : Double) : Double;
begin
  Result := a_dBeats * BpmToMpb(a_dBpm);
end;

//==============================================================================
function MsToBeats(a_dBpm : Double; a_dMs : Double) : Double;
begin
  Result := a_dMs / BpmToMpb(a_dBpm);
end;

//==============================================================================
function SampleCountToMs(a_nSmpCount : Integer; a_dSmpRate : Double) : Double;
begin
  Result := c_nMsInSec * (a_nSmpCount/a_dSmpRate);
end;

//==============================================================================
function MsToSampleCount(a_dMs : Double; a_dSmpRate : Double) : Integer;
begin
  Result := Trunc(a_dSmpRate * (a_dMs/c_nMsInSec));
end;

end.

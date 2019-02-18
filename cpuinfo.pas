{$CODEPAGE UTF8}
{$MODE OBJFPC}
{$MODESWITCH AUTODEREF}
uses
  dcpuinfo;

var
  CpuInfo: TCpuInfo;

begin
  GetCpuInfo(CpuInfo);
  Writeln('Arch:    ', CpuInfo.Arch);
  Writeln('SSE:     ', CpuInfo.HasSSE);
  Writeln('SSE2:    ', CpuInfo.HasSSE2);
  Writeln('SSE3:    ', CpuInfo.HasSSE3);
  Writeln('NEON:    ', CpuInfo.HasNEON);
  Writeln('AltiVec: ', CpuInfo.HasAltiVec);
end.

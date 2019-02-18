{$MODE OBJFPC}
unit dcpuinfo;

interface

type
TCpuInfo = record
  Arch: PAnsiChar; // static const null-terminated string of name of arch family
  HasSSE: Boolean;
  HasSSE2: Boolean;
  HasSSE3: Boolean;
  HasNEON: Boolean;
  HasAltiVec: Boolean;
  //HasMips3D: Boolean;
end;

//
//  GetCpuInfo
//
//      Fills all fields of the CpuInfo structure.
//
procedure GetCpuInfo(out CpuInfo: TCpuInfo);

implementation

{$IF Defined(CPU386)}
{$ASMMODE Intel}
//
//  GetCpuId
//
//      Executes 'cpuid' instruction for EAX=Leaf, EDX=SubLeaf.
//      Stores returned eax, ebx, ecx, edx to R[0], R[1], R[2], R[3].
//
//      R must points to at least 4 Cardinals of available memory.
//
//      Undefined behaviour if 'cpuid' is not supported by the CPU.
//
procedure GetCpuId(Leaf, SubLeaf: Cardinal; R: PCardinal);
assembler; asm
  push esi
  mov esi, R
  mov eax, Leaf
  mov edx, SubLeaf
  cpuid
  mov [esi], eax
  mov [esi+4], ebx
  mov [esi+8], ecx
  mov [esi+12], edx
  pop esi
end;

//
//  GetCPUIDMax
//
//
//      Returns max possible Leaf for 'cpuid' instruction. Returns 0 if 'cpuid'
//      is not supported for the CPU.
//
//      If Ext=True, returns max possible Leaf for extended region.
//
function GetCPUIDMax(Ext: Boolean): Cardinal;
var
  _eax, _ebx: Cardinal;
  R: array[0..3] of Cardinal;
begin
  asm
    pushfd
    pushfd
    pop eax
    mov _ebx, eax
    xor eax, $200000
    push eax
    popfd
    pushfd
    pop _eax
    popfd
  end ['eax'];
  if ((_eax xor _ebx) and $200000) = 0 then
    Exit(0);
  if Ext then begin
    GetCpuId($80000000, 0, @R[0]);
  end else
    GetCpuId(0, 0, @R[0]);
  Result := R[0];
end;

procedure Impl_GetCpuInfo(out CpuInfo: TCpuInfo); inline;
var
  M: Cardinal;
  R: array[0..3] of Cardinal;
begin
  CpuInfo.Arch = 'x86';
  M := GetCPUIDMax(False);
  if M < 1 then
    Exit;
  GetCpuId(1, 0, @R[0]);
  CpuInfo.HasSSE  := (R[3] and (1 shl 25)) <> 0;
  CpuInfo.HasSSE2 := (R[3] and (1 shl 26)) <> 0;
  CpuInfo.HasSSE3 := ((R[2] and (1 shl 0)) <> 0) and
                     ((R[2] and (1 shl 9)) <> 0);
end;
{$ENDIF} // CPU386

{$IF Defined(CPUARM) or Defined(CPUARM64)}
//
//  ARM_CheckNeon
//
//      Tries to execute a NEON instruction. Returns True on success, throws
//      'illegal instruction' exception on fail.
//
function ARM_CheckNeon: Boolean; assembler; nostackframe;
asm
  .byte 80,1,32,242 // vorr q0,q0,q0
  mov r0,True // return True
end;

procedure Impl_GetCpuInfo(out CpuInfo: TCpuInfo); inline;
begin
  CpuInfo.Arch := 'ARM';
  try
    CpuInfo.HasNEON := ARM_CheckNeon;
  except
    CpuInfo.HasNEON := False;
  end;
end;
{$ENDIF}

{$IF Defined(CPUPOWERPC)}
//
//  PowerPC_CheckAltiVec
//
//      Tries to execute an AltiVec instruction. Returns True on success, throws
//      'illegal instruction' exception on fail.
//
function PowerPC_CheckAltiVec: Boolean; assembler; nostackframe;
asm
  .byte 16,0,4,132 // vor 0,0,0
  li 3,True
end;

procedure Impl_GetCpuInfo(out CpuInfo: TCpuInfo); inline;
begin
  CpuInfo.Arch := 'PowerPC';
  try
    CpuInfo.HasAltiVec := PowerPC_CheckAltiVec;
  except
    CpuInfo.HasAltiVec := False;
  end;
end;
{$ENDIF} // POWERPC

// Not tested yet
// {$IF Defined(CPUMIPS)}
// function MIPS_CheckMips3D: Boolean; assembler; nostackframe;
// asm
//   li GPR3, True
// end;
// 
// procedure Impl_GetCpuInfo(out CpuInfo: TCpuInfo); inline;
// begin
//   CpuInfo.Arch := 'MIPS';
//   CpuInfo.Mips3D := MIPS_CheckMips3D;
// end;
// {$ENDIF} // MIPS

{$IF not Declared(Impl_GetCpuInfo)}
procedure Impl_GetCpuInfo(out CpuInfo: TCpuInfo); inline;
begin
  {$IF Defined(CPU86) or Defined(CPU87)}
    CpuInfo.Arch = 'Intel 8086';
  {$ELSEIF Defined(CPUAMD64) or Defined(CPUX86_64)}
    CpuInfo.Arch = 'x86_64';
  {$ELSEIF Defined(CPUIA64)}
    CpuInfo.Arch = 'IA-64';
  {$ELSEIF Defined(CPUAMD68) or Defined(CPU68K) or Defined(CPUM68K)}
    CpuInfo.Arch = 'Motorola 68k';
  {$ELSEIF Defined(CPUM68020)}
    CpuInfo.Arch = 'Motorola 68020';
  {$ELSEIF Defined(CPUPOWERPC32)}
    CpuInfo.Arch = 'PowerPC32';
  {$ELSEIF Defined(CPUPOWERPC64)}
    CpuInfo.Arch = 'PowerPC64';
  {$ELSEIF Defined(CPUPOWERPC)}
    CpuInfo.Arch = 'PowerPC';
  {$ELSEIF Defined(CPUMIPS)}
    CpuInfo.Arch = 'MIPS';
  {$ELSEIF Defined(CPUSPARC) or Defined(CPUSPARC32)}
    CpuInfo.Arch = 'SPARCv7';
  {$ELSEIF Defined(CPUARM)}
    CpuInfo.Arch = 'ARM32';
  {$ELSEIF Defined(CPUAVR)}
    CpuInfo.Arch = 'AVR';
  {$ELSE}
    CpuInfo.Arch = 'Unknown';
  {$ENDIF}
end;
{$ENDIF}

procedure GetCpuInfo(out CpuInfo: TCpuInfo);
begin
  CpuInfo.Arch := '';
  CpuInfo.HasSSE := False;
  CpuInfo.HasSSE2 := False;
  CpuInfo.HasSSE3 := False;
  CpuInfo.HasNEON := False;
  CpuInfo.HasAltiVec := False;
  //CpuInfo.HasMips3D := False;
  Impl_GetCpuInfo(CpuInfo);
end;

end.

format PE console
entry start

include 'win32ax.inc'

section '.code' code readable executable
start:
  invoke CreateFile, ImageName, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
  mov [hFile], eax

  invoke CreateFileMapping, [hFile], 0, PAGE_READONLY, 0, 0, 0
  call CheckError
  mov [hMapping], eax

  invoke MapViewOfFile,[hMapping], FILE_MAP_READ, 0, 0, 0
  call CheckError

  mov [hView], eax

  push eax
  pop esi
  call ValidPE
  invoke ExitProcess, 0

proc CheckError
  .if eax = 0
      invoke GetLastError
      invoke printf, fmt, eax
      add esp, 8
  .endif
  ret
endp

; esi - pointer to first byte of PE image
proc ValidPE
  push esi
  pushf
  .if word [esi] = "MZ"
      add esi, [esi + 3Ch]
      .if word [esi] = "PE"
          popf
          pop esi
          mov eax, 1
          ret
      .endif
  .endif
  popf
  pop esi
  xor eax, eax
  ret
endp

section '.data' readable writeable
  fmt db '%x', 0
  ImageName db 'sample.exe', 0
  hFile dd 0
  hMapping dd 0
  hView dd 0

data import

  library kernel32, 'kernel32.dll',\
          msvcrt, 'msvcrt.dll'

  import kernel32,\
         ExitProcess, 'ExitProcess',\
         CreateFile, 'CreateFileA',\
         CreateFileMapping, 'CreateFileMappingA',\
         MapViewOfFile, 'MapViewOfFile',\
         GetLastError, 'GetLastError'
  import msvcrt,\
         printf, 'printf'
end data
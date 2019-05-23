format PE console
entry start

include 'win32ax.inc'

section '.code' code readable executable
start:
  invoke CreateFile, ImageName, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
  mov [hFile], eax

  invoke CreateFileMapping, [hFile], 0, PAGE_READONLY, 0, 0, 0
  .if eax = 0
      invoke GetLastError
  .endif
  mov [hMapping],eax

  invoke MapViewOfFile,[hMapping], FILE_MAP_READ, 0, 0, 0
  invoke ExitProcess, 0

section '.data' readable writeable
ImageName db 'sample.bin', 0
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
end data
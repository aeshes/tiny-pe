format binary as 'exe'
use32

;
; DOS header
;
mzhdr:
  dw "MZ"       ; e_magic
  dw 0          ; e_cblp     UNUSED
  dw 0          ; e_cp       UNUSED
  dw 0          ; e_crlc     UNUSED
  dw 0          ; e_cparhdr  UNUSED
  dw 0          ; e_minalloc UNUSED
  dw 0          ; e_maxalloc UNUSED
  dw 0          ; e_ss       UNUSED
  dw 0          ; e_sp       UNUSED
  dw 0          ; csum       UNUSED
  dw 0          ; e_ip       UNUSED
  dw 0          ; e_cs       UNUSED
  dw 0          ; e_lsarlc   UNUSED
  dw 0          ; e_ovno     UNUSED
  times 4 dw 0  ; e_res      UNUSED
  dw 0          ; e_oemid    UNUSED
  dw 0          ; e_oeminfo  UNUSED
  times 10 dw 0 ; e_res2     UNUSED
  dd pesig      ; e_lfanew

;
; PE header
;

filealign equ 1
sectalign equ 1

pesig:
  dd "PE"
filehdr:
  dw 0x014C      ; Machine i386
  dw 1           ; NumberOfSections
  dd 0           ; TimeDateStamp UNUSED
  dd 0           ; PointerToSymbolTable UNUSED
  dd 0           ; NumberOfSymbols UNUSED
  dw opthdrsize  ; SizeOfOptionalHeader (including data directories)
  dw 0x103       ; Characteristics (no relocs, executable, 32-bit)
opthdr:
  dw 0x10B     ; Magic (PE32)
  db 0         ; MajorLinkerVersion UNUSED
  db 0         ; MinorLinkerVersion UNUSED
  dd 0         ; SizeOfCode
  dd 0         ; SizeOfInitializedData UNUSED
  dd 0         ; SizeOfUninitializedData UNUSED
  dd start     ; AddressOfEntryPoint
  dd code      ; BaseOfCode UNUSED
  dd 0         ; BaseOfData UNUSED
  dd 0x400000  ; ImageBase
  dd sectalign ; SectionAlignment
  dd filealign ; FileAlignment
  dw 0         ; MajorOperatingSystemVersion UNUSED
  dw 0         ; MinorOperatingSystemVersion UNUSED
  dw 0         ; MajorImageVersion UNUSED
  dw 0         ; MinorImageVersion UNUSED
  dw 4         ; MajorSubsystemVersion
  dw 0         ; MinorSubsystemVersion
  dd 0         ; Win32VersionValue UNUSED
  dd (filesize + sectalign - 1) and not (sectalign - 1)   ; SizeOfImage
  dd (hdrsize + filealign -1) and not (filealign - 1)     ; SizeOfHeaders
  dd 0         ; CheckSum UNUSED
  dw 2         ; Subsystem (Win32 GUI)
  dw 0x400     ; DllCharacteristics UNUSED
  dd 0x100000  ; SizeOfStackReserve UNUSED
  dd 0x1000    ; SizeOfStackCommit
  dd 0x1000000 ; SizeOfHeapReserve
  dd 0x1000    ; SizeOfHeapCommit UNUSED
  dd 0         ; LoaderFlags UNUSED
  dd 16        ; NumberOfRvaAndSizes UNUSED

opthdrsize = $ - opthdr
hdrsize = $ - $$

code:
;
; Entry Point
;
start:
  push 42
  pop eax
  ret

codesize = $ - code
filesize = $ - $$
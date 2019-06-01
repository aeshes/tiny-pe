format binary
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
pesig:
  dd "PE"
filehdr:
  dw 0x014C  ; Machine i386
  dw 1       ; NumberOfSections
  dd 0       ; TimeDateStamp UNUSED
  dd 0       ; PointerToSymbolTable UNUSED
  dd 0       ; NumberOfSymbols UNUSED
  dw 0       ; SizeOfOptionalHeader (including data directories)
  dw 0x103   ; Characteristics (no relocs, executable, 32-bit)
opthdr:
  dw 0x10B   ; Magic (PE32)
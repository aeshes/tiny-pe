# tiny-pe
Минимальный PE файл. В этом проекте соберем руками наименьший PE файл, который не будет крашиться при загрузке системным лодером.

### FASM

`data` - директива, которая пишет начало и размер блока data в поля `IMAGE_NT_HEADERS.OptionalHeader.DataDirectory`; import, export, fixups преобразуется в соответствующий индекс директории.

### DOS заголовок
Начало Win32 PE файла это буквально DOS-программа. Есть одно требование: по смещению **3Ch (60)** находится DWORD, указывающий смещение PE-заголовка (relative virtual address) от начала PE-файла. В DOS-заголовке важны только два поля: сигнатура e_magic и смещение PE-заголовка e_lfanew.

### PE заголовок
Определен в WinNT.h как структура следующего вида:

```
typedef struct _IMAGE_NT_HEADERS64 {
    DWORD Signature;
    IMAGE_FILE_HEADER FileHeader;
    IMAGE_OPTIONAL_HEADER64 OptionalHeader;
} IMAGE_NT_HEADERS64, *PIMAGE_NT_HEADERS64;
```

Где сигнатура равна `0x5045` ("PE").

#### Файловый заголовок

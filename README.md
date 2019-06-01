# tiny-pe
Минимальный PE файл. В этом проекте соберем руками наименьший PE файл, который не будет крашиться при загрузке системным лодером. Собираем PE-шник голыми руками по байтам. Там, где это слишком неудобно, воспользуемся каменным топором (FASM).

### FASM

`data` - директива, которая пишет начало и размер блока data в поля `IMAGE_NT_HEADERS.OptionalHeader.DataDirectory`; import, export, fixups преобразуется в соответствующий индекс директории.


### DOS заголовок
Начало Win32 PE файла это буквально DOS-программа. Есть одно требование: по смещению **3Ch (60)** находится DWORD, указывающий смещение PE-заголовка (relative virtual address) от начала PE-файла. В DOS-заголовке важны только два поля: сигнатура e_magic и смещение PE-заголовка e_lfanew.

За концом old-exe DOS заголовка следует DOS-программа, которая при запуске под дос выводит разочаровывающее сообщение о том, что это программа для винды.

### PE заголовок
Описывает фундаментальные характеристики файла. Определен в WinNT.h как структура следующего вида:

```
typedef struct _IMAGE_NT_HEADERS64 {
    DWORD Signature;
    IMAGE_FILE_HEADER FileHeader;
    IMAGE_OPTIONAL_HEADER64 OptionalHeader;
} IMAGE_NT_HEADERS64, *PIMAGE_NT_HEADERS64;
```

Где сигнатура равна `0x5045` ("PE\x0\x0"). Этот заголовок может находиться в любом месте программы, хоть в середине, хоть в конце, потому что загрузчик определяет его положение по двойному слову `e_lfanew` в DOS-заголовке, смещенному на 0x3C байт от начала файла.

#### Файловый заголовок
`Machine` - тип центрального процессора, под который скомпилирован файл. Если здесь будет что-то отличное от 0x14C, на i386-машинах файл не загрузится.

`NumberOfSections` - количество секций. Очень интересное поле, значение которого можно искажать для обхода наивных дамперов и других инструментов.

`PointerToSymbolTable/NumberOfSymbols` - указатель на/размер отладочной информации в объектных файлах.

`SizeOfOptionalHeader` - размер опционального заголовка, следующего на файловым заголовком. Может использоваться для указания на первый байт таблицы секций. То есть, `e_lfanew + sizeof(IMAGE_FILE_HEADER) + SizeOfOptionalHeader = addr Section Table`

#### Опциональный заголовок
Описывает структуру страничного образа более детально (базовый адрес загрузки, размер образа, степень выравнивания, data directory и многое другое). Размер опционального заголовка хранится в файловом заголовке, так что две этих структуры очень тесно связаны.

#### Таблица секций
Следует сразу после опционального заголовка и имеет весьма условную принадлежность. Ни одному из заголовков она не принадлежит и является самостоятельным заголовком.

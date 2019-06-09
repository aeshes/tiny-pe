# tiny-pe
Минимальный PE файл. В этом проекте соберем руками наименьший PE файл, который не будет крашиться при загрузке системным лодером. Собираем PE-шник голыми руками по байтам. Там, где это слишком неудобно, воспользуемся каменным топором (FASM).

### FASM

`data` - директива, которая пишет начало и размер блока data в поля `IMAGE_NT_HEADERS.OptionalHeader.DataDirectory`; import, export, fixups преобразуется в соответствующий индекс директории.

### Заголовки и секции
Заголовки - структуры данных, необходимые для загрузки программы, а секции - блоки данных с содержимым различного размера. Заголовками PE-файла являются следующие заголовки в указанном порядке:

- DOS заголовок
- Заглушка DOS
- PE заголовок (сигнатура + файловый + опцональный)
- Таблица секций

Заголовок состоит из полей, как список состоит из пунктов. Каждое поле содержит в себе значение в виде набора байт. Не все поля нужны для загрузки файла. Несущественные поля, без которых программа и так запустится, я помечаю UNUSED.

### DOS заголовок
```
typedef struct _IMAGE_DOS_HEADER {
    USHORT e_magic;
    USHORT e_cblp;
    USHORT e_cp;
    USHORT e_crlc;
    USHORT e_cparhdr;
    USHORT e_minalloc;
    USHORT e_maxalloc;
    USHORT e_ss;
    USHORT e_sp;
    USHORT e_csum;
    USHORT e_ip;
    USHORT e_cs;
    USHORT e_lfarlc;
    USHORT e_ovno;
    USHORT e_res[4];
    USHORT e_oemid;
    USHORT e_oeminfo;
    USHORT e_res2[10];
    LONG   e_lfanew;
} IMAGE_DOS_HEADER, *PIMAGE_DOS_HEADER;
```

Нас интересуют только первое (*e_magic*) и последнее (*e_lfanew*) поле. Они самые важные и непосредственно влияют на загрузку программу. Четырехбайтовое поле *e_lfanew* хранит смещение до PE-заголовка. То есть хранит в себе количество байт, которые надо отсчитать от начала файла, чтобы попасть к PE-заголовку. Это смещение хранится в обратном порядке, ибо нет архитектуры кроме x86, и Intel пророк ее :3

За концом old-exe DOS заголовка следует DOS-программа, которая при запуске под дос выводит разочаровывающее сообщение о том, что это программа для винды.

Эта заглушка не является обязательной и мы удалим ее для уменьшения размера програмы.

### PE заголовок
Описывает фундаментальные характеристики файла. Определен в WinNT.h как структура следующего вида:

```
typedef struct _IMAGE_NT_HEADERS64 {
    DWORD Signature;                        // Сигнатура
    IMAGE_FILE_HEADER FileHeader;           // Файловый заголовок
    IMAGE_OPTIONAL_HEADER64 OptionalHeader; // Дополнительный
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

#### Директории данных
Важная часть опционального заголовка - директории данные. Они представляют собой массив указателей на подчиненные структуры данных: таблицы экспорта и импорта, отладочная информация, релоки и др.

Располагаются в самом конце опционального заголовка. Пока что у нас нет директорий данных и LordPE показывает, что здесь ничего нет. Добавим в конец опционального заголовка директиву `times 16 dd 0, 0` и наслаждаемся тем, что LordPE обнаружил нулевые записи в этой структуре, а размер исполняемого файла увеличился с 188 байт до 316. `316 - 188 = 128` - размер массива, а это как раз 16 записей (каждая запись занимает 8 байт и содержит виртуальный адрес директории и ее размер): `128 / 8 = 16`.

#### Таблица секций
Следует сразу после опционального заголовка и имеет весьма условную принадлежность. Ни одному из заголовков она не принадлежит и является самостоятельным заголовком.

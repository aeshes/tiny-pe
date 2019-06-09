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

Нас интересуют только первое (**e_magic**) и последнее (**e_lfanew**) поле. Они самые важные и непосредственно влияют на загрузку программу. Четырехбайтовое поле **e_lfanew** хранит смещение до PE-заголовка. То есть хранит в себе количество байт, которые надо отсчитать от начала файла, чтобы попасть к PE-заголовку. Это смещение хранится в обратном порядке, ибо нет архитектуры кроме x86, и Intel пророк ее :3

За концом old-exe DOS заголовка следует DOS-программа, которая при запуске под дос выводит разочаровывающее сообщение о том, что это программа для винды.

Эта заглушка не является обязательной и мы удалим ее для уменьшения размера програмы.

Чтобы попробовать навигацию по исполняемому файлу своими руками, можно открыть ее в **Hex Editor Neo**, клик **Go to Offset** -> 0x3C и мы попадаем на значение **e_lfanew = 40, 00, 00, 00**. Переворачиваем и получаем **0x00000040**или просто **40h**. Аналогично переходим на оффсет **0x40** и попадаем прямо на PE-сигнатуру.

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
Хранит в себе базовые характеристики PE-файла.

```
typedef struct _IMAGE_FILE_HEADER {
  WORD  Machine;              // Архитектура процессора
  WORD  NumberOfSections;     // Кол-во секций
  DWORD TimeDateStamp;        // Дата и время создания программы
  DWORD PointerToSymbolTable; // Указатель на таблицу символов
  DWORD NumberOfSymbols;      // Число символов в таблицу
  WORD  SizeOfOptionalHeader; // Размер дополнительного заголовка
  WORD  Characteristics;      // Характеристика
} IMAGE_FILE_HEADER, *PIMAGE_FILE_HEADER;
```

`Machine` - тип центрального процессора, под который скомпилирован файл. Если здесь будет что-то отличное от 0x14C, на i386-машинах файл не загрузится.

`NumberOfSections` - количество секций. Очень интересное поле, значение которого можно искажать для обхода наивных дамперов и других инструментов.

`SizeOfOptionalHeader` - размер опционального заголовка, следующего на файловым заголовком. Может использоваться для указания на первый байт таблицы секций. То есть, `e_lfanew + sizeof(IMAGE_FILE_HEADER) + SizeOfOptionalHeader = addr Section Table`

`Characteristics` - содержит характеристики файла. Например, exe это или dll, 32-битная это программа или 64-битная.

#### Дополнительный заголовок
Обязательный подзаголовок PE-файла. Описывает структуру страничного образа более детально и содержит информацию, необходимую для загрузки файла. Имеет два формата PE32+ для 64-битных программ и PE32 для 32-битных.

```
typedef struct _IMAGE_OPTIONAL_HEADER {
  WORD                 Magic;
  BYTE                 MajorLinkerVersion;
  BYTE                 MinorLinkerVersion;
  DWORD                SizeOfCode;
  DWORD                SizeOfInitializedData;
  DWORD                SizeOfUninitializedData;
  DWORD                AddressOfEntryPoint;
  DWORD                BaseOfCode;
  DWORD                BaseOfData;
  DWORD                ImageBase;
  DWORD                SectionAlignment;
  DWORD                FileAlignment;
  WORD                 MajorOperatingSystemVersion;
  WORD                 MinorOperatingSystemVersion;
  WORD                 MajorImageVersion;
  WORD                 MinorImageVersion;
  WORD                 MajorSubsystemVersion;
  WORD                 MinorSubsystemVersion;
  DWORD                Win32VersionValue;
  DWORD                SizeOfImage;
  DWORD                SizeOfHeaders;
  DWORD                CheckSum;
  WORD                 Subsystem;
  WORD                 DllCharacteristics;
  DWORD                SizeOfStackReserve;
  DWORD                SizeOfStackCommit;
  DWORD                SizeOfHeapReserve;
  DWORD                SizeOfHeapCommit;
  DWORD                LoaderFlags;
  DWORD                NumberOfRvaAndSizes;
  IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];
} IMAGE_OPTIONAL_HEADER32, *PIMAGE_OPTIONAL_HEADER32;
```

#### Директории данных
Важная часть опционального заголовка - директории данные. Они представляют собой массив указателей на подчиненные структуры данных: таблицы экспорта и импорта, отладочная информация, релоки и др.

Располагаются в самом конце опционального заголовка. Пока что у нас нет директорий данных и LordPE показывает, что здесь ничего нет. Добавим в конец опционального заголовка директиву `times 16 dd 0, 0` и наслаждаемся тем, что LordPE обнаружил нулевые записи в этой структуре, а размер исполняемого файла увеличился с 188 байт до 316. `316 - 188 = 128` - размер массива, а это как раз 16 записей (каждая запись занимает 8 байт и содержит виртуальный адрес директории и ее размер): `128 / 8 = 16`.

#### Таблица секций
Следует сразу после опционального заголовка и имеет весьма условную принадлежность. Ни одному из заголовков она не принадлежит и является самостоятельным заголовком.

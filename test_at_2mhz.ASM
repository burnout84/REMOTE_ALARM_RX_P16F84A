;===============================================================================================
;
; PROG : РЕГИСТРАТОР КОДОВ KEELOQ/STARLINE (64 БИТ)
; OWNER: burnout84@rambler.ru
; PROC : PIC16F84A + AUREL RX BC-NBK
; FREQ : 2 MHZ
; IDE  : MPLAB IDE 8.xx
; DATE : 12.06.2010
;
; WEB  : https://github.com/burnout84
;
;
; ЖКИ - АДРЕСА СТРОК
; 0x80 - 1 строка
; 0xC0 - 2
; 0x90 - 3
; 0xD0 - 4
;
; ТЕСТОВАЯ ВЕРСИЯ ДЛЯ ПРОВЕРКИ ЖКИ НА 3В.
;
;===============================================================================================
LIST P=16F84A

__CONFIG _XT_OSC &_PWRTE_ON &_CP_OFF &_WDT_OFF

_CP_ON              equ H'000F'
_CP_OFF             equ H'3FFF'
_PWRTE_ON           equ H'3FF7'
_PWRTE_OFF          equ H'3FFF'
_WDT_ON             equ H'3FFF'
_WDT_OFF            equ H'3FFB'
_LP_OSC             equ H'3FFC'
_XT_OSC             equ H'3FFD'
_HS_OSC             equ H'3FFE'
_RC_OSC             equ H'3FFF'

TMR0                equ 01h ; Регистр TMR0. 
OPTIONR             equ 01h ; Регистр Option - банк 1.
PC                  equ 02h ;
PCLATH              equ 0Ah ;
INTCON              equ 0Bh ; Регистр IntCon. 
INDF                equ 0   ;
PORTA               equ 5   ;
PORTB               equ 6   ;
TRISA               equ 85h ;
TRISB               equ 86h ;
OPTREG              equ 81h ;
STATUS              equ 3   ;
CARRY               equ 0   ;
GIE                 equ 7   ;
MSB                 equ 3   ; 
FSR                 equ 4h  ;
INTCON              equ 0Bh ; Регистр INTCON  
EEDATA              equ 08h ; EEPROM - данные 
EECON1              equ 08h ; EECON1 - банк1  
EEADR               equ 09h ; EEPROM - адрес 
EECON2              equ 09h ; EECON2 - банк1
W                   equ 0   ; Результат направить в аккумулятор
F                   equ 1   ; Результат направить в регистр
RP0                 equ 5   ; Бит выбора банка
Z                   equ 2   ; Флаг нулевого результата
C                   equ 0   ; Флаг переноса-заема
                            ;
LINE_RX             equ 0   ; Вход сигнала      (PORTB)
LED_1               equ 4   ; Индикатор 1       (PORTB)
BTN_1               equ 7   ; Кнопка 1          (PORTB)
BTN_2               equ 6   ; Кнопка 2          (PORTB)
BTN_3               equ 5   ; Кнопка 2          (PORTB)
SW_1                equ 4   ; Перекл. поз.1   (PORTA)

RS                  equ 1   ;
RW                  equ 2   ;
E                   equ 3   ;

RANGE_A             equ 0Ch ; Диапазон валидного уровня лог0/лог1
RANGE_B             equ 0Dh ; 
RANGE_C             equ 0Eh ; Диапазон валидного бита лог0+лог1 (+/-25%)
RANGE_D             equ 0Fh ;
RANGE_E             equ 10h ; Диапазон валидного бита (2-е логич.состояние)
RANGE_F             equ 11h ;

REG_A1              equ 12h ; ДЛЯ ПП 1 УРОВНЯ
REG_B1              equ 13h ;
REG_C1              equ 14h ; 
REG_D1              equ 15h ; 

TEMP_LCD            equ 16h ; ДЛЯ ПП ЖКИ

BIT_COUNT_ALL       equ 1Bh ; Общий счетчик битов
BIT_COUNT_8         equ 1Ch ; Счетчик битов в байте

FLAGS               equ 1Fh ; ФЛАГИ
                            ; 0 - Пакет успешно принят

BUFFER_0            equ 20h ; 1-й буфер 20h..27h
BUFFER_1            equ 28h ; 2-й буфер 28h..2Fh
BUFFER_2            equ 30h ; 3-й
BUFFER_3            equ 38h ; 4-й
BUFFER_4            equ 40h ; 5-й
BUFFER_5            equ 48h ; 6-й (временный)
;===============================================================================================
;                              НАЧАЛО ПРОГРАММЫ                                     0 - УРОВЕНЬ
;===============================================================================================
 ORG  0                     ; 
 GOTO START                 ; 
START                       ; СТАРТ ПРОГРАММЫ
 CLRF PORTA                 ; ОЧИЩАЕМ ПОРТЫ
 CLRF PORTB                 ;
 BSF STATUS,RP0             ; БАНК 1
 MOVLW 0x00                 ; PORTA - ВСЕ НА ВЫХОД
 MOVWF TRISA                ;
 MOVLW 0x01                 ; PORTB - ВСЕ НА ВЫХОД, КРОМЕ RB0
 MOVWF TRISB                ;
 MOVLW b'00000011'          ; НАСТРОЙКА ТАЙМЕРА TMR0 1:16 (16 мкс на 4Mhz)
 MOVWF OPTIONR              ;
 BCF STATUS,RP0             ; БАНК 0

 CALL INIT_LCD              ; Подпрограмма инициализации LCD
 CALL PRINT_HELLO           ; Подпрограмма вывода текста на экран

 BSF PORTB,LED_1
LOOP                        ;
 BSF PORTB,BTN_1            ;
 BSF PORTB,BTN_2            ;
 BSF PORTB,BTN_3            ;

 BTFSS PORTB,BTN_1          ;
 CALL PRINT_1               ;
 BTFSS PORTB,BTN_2          ;
 CALL PRINT_2               ;
 BTFSS PORTB,BTN_3          ;
 CALL PRINT_3               ;

GOTO LOOP                   ;
;===============================================================================================
;                              ИНИЦИАЛИЗАЦИЯ LCD                                    1 - УРОВЕНЬ
;===============================================================================================
INIT_LCD			        ;
 MOVLW .8                   ; ОБЯЗАТЕЛЬНАЯ ПОСЛЕДОВАТЕЛЬНОСТЬ
 CALL DELAY_1_MS            ;
 BCF PORTB,RS               ; RS=0
 BCF PORTB,RW               ; RW=0
 BCF PORTB,E                ; E=0
 MOVLW h'30'		        ; Настройка
 MOVWF PORTA                ;
 BSF	PORTB,E             ; контроллера
 BCF	PORTB,E             ; LCD модуля
 MOVLW .2                   ;
 CALL DELAY_1_MS            ;
 BSF	PORTB,E	            ;
 BCF	PORTB,E	            ;
 MOVLW .25                  ;
 CALL DELAY_2_MKS	        ;
 BSF	PORTB,E	            ;
 BCF	PORTB,E        	    ;
 CALL BUSY                  ;

 MOVLW 0x28                 ; ОТПРАВЛЯЕМ В LCD КОМАНДУ РАБОТЫ В 4-Х БИНОМ РЕЖИМЕ
 MOVWF TEMP_LCD             ; т.к. команда отправлется будучи в 8-битном режиме, то отправлеям только один кусок байта
 SWAPF TEMP_LCD,0           ;
 MOVWF PORTA                ;
 BCF PORTB,RS               ;
 BCF PORTB,RW               ;
 BSF PORTB,E                ;
 BCF PORTB,E                ;
 CALL BUSY                  ; ОЖИДАЕМ ГОТОВНОСТИ

 MOVLW h'28'		        ; ПОВТОРЯЕМ КОМАНДУ РАБОТЫ В 4-Х БИТНОМ РЕЖИМЕ, НО ОТПРАВЯЛЕМ 2 КУСКА (Шина-4bit, 2 строки, матрица 5х8 пикс)
 CALL WRC	                ; 
 MOVLW h'0C'	    	    ; ОТОБРАЖЕНИЕ БЕЗ КУРСОРА
 CALL WRC	                ;
 MOVLW h'06'		        ; АВТОМАТИЧЕСКОЕ ПЕРЕМЕЩЕНИЕ КУРСОРА СЛЕВА НАПРАВО
 CALL WRC	                ;
 MOVLW h'01'		        ; ОЧИСТИТЬ ДИСПЛЕЙ
 CALL WRC	                ;
RETURN                      ;
;===============================================================================================
;                              ЗАПИСЬ КОДА КОМАНД LCD                               2 - УРОВЕНЬ
;===============================================================================================
WRC                         ;
 BCF PORTB,RS               ; Установить значение линии RS = 0
 BCF PORTB,RW               ;
 MOVWF TEMP_LCD             ; Вывести значение старшей тетрады байта данных на линии шины DB4..DB7
 SWAPF TEMP_LCD,1           ; 
 MOVFW TEMP_LCD             ;
 MOVWF PORTA                ;
 BSF PORTB,E                ; Установить линию E = 1
 NOP                        ;
 BCF PORTB,E                ; Установить линию E = 0
 SWAPF TEMP_LCD,1           ; Вывести значение младшей тетрады байта данных на линии шины DB4..DB7
 MOVFW TEMP_LCD             ;
 MOVWF PORTA                ;
 BSF PORTB,E                ; Установить линию E = 1
 NOP                        ;
 BCF PORTB,E                ; Установить линию E = 0
 CALL BUSY                  ; Ожидаем готовности
RETURN                      ;
;===============================================================================================
;                             ЗАПИСЬ КОДА ДАННЫХ LCD                                2 - УРОВЕНЬ
;===============================================================================================
WRD                         ;
 BSF PORTB,RS               ; Установить значение линии RS = 0
 MOVWF TEMP_LCD             ; Вывести значение старшей тетрады байта данных на линии шины DB4..DB7
 SWAPF TEMP_LCD,1           ; 
 MOVFW TEMP_LCD             ;
 MOVWF PORTA                ;
 BSF PORTB,E                ; Установить линию E = 1
 NOP                        ;
 BCF PORTB,E                ; Установить линию E = 0
 SWAPF TEMP_LCD,1           ; Вывести значение младшей тетрады байта данных на линии шины DB4..DB7
 MOVFW TEMP_LCD             ;
 MOVWF PORTA                ;
 BSF PORTB,E                ; Установить линию E = 1
 NOP                        ;
 BCF PORTB,E                ; Установить линию E = 0
 CALL BUSY                  ; Ожидаем готовности
RETURN                      ;
;===============================================================================================
;                             ПРОВЕРКА ГОТОВНОСТИ LCD                               2 - УРОВЕНЬ
;===============================================================================================
BUSY                        ;
 BSF STATUS,RP0             ;
 MOVLW B'11111111'          ;
 MOVWF TRISA                ;
 BCF	STATUS,RP0          ;
 CALL C_READ                ;
 BTFSC TEMP_LCD,3           ;
 GOTO BUSY                  ;
 BSF STATUS,RP0             ;
 MOVLW B'00000000'          ;
 MOVWF TRISA                ;
 BCF	STATUS,RP0          ;
RETURN                      ;
;===============================================================================================
;                             ЧТЕНИЯ КОДА КОМАНД LCD                                3 - УРОВЕНЬ
;===============================================================================================
C_READ                      ;
 BCF PORTB,RS               ; Установить значение линии RS = 0
 BSF PORTB,RW               ; Установить линию RW = 1
 BSF PORTB,E                ; Установить линию E = 1
 MOVF PORTA,W               ; Считать значение старшей тетрады байта данных с линии DB4..DB7
 MOVWF TEMP_LCD             ;
 BCF PORTB,E                ; Установить линию E = 0
 BSF PORTB,E                ; Установить линию E = 1
 MOVF PORTA,W               ; Считать значение младшей тетрады байта данных с линии DB4..DB7
 BCF PORTB,E                ; Установить линию E = 0
 BCF PORTB,RW               ; Установить линию RW = 0
RETURN                      ;
;===============================================================================================
;                             ЗАДЕРЖКА (W x 2 мкс) + 2 мкс                          3 - УРОВЕНЬ
; REG_A1 - СЧЕТЧИК
;===============================================================================================
DELAY_2_MKS                 ;
 MOVWF REG_A1               ;
 NOP                        ;
 DECFSZ REG_A1,1            ;
 GOTO $-2                   ;
RETURN                      ;
;===============================================================================================
;                             ЗАДЕРЖКА (W x 1 мс)                                   3 - УРОВЕНЬ
; REG_A1 - СЧЕТЧИК
; REG_B1 - СЧЕТЧИК
;===============================================================================================
DELAY_1_MS                  ;
 MOVWF REG_B1               ;
 MOVLW .250                 ;
 MOVWF REG_A1               ;
 NOP                        ;
 NOP                        ;
 NOP                        ;
 NOP                        ;
 NOP                        ;
 DECFSZ REG_A1,1            ;
 GOTO $-6                   ;
 DECFSZ REG_B1,1            ;
 GOTO $-0x0A                ; 
RETURN                      ;
;===============================================================================================
;                              ПРИВЕТСТВИЕ
;===============================================================================================
PRINT_HELLO                 ;
 MOVLW 0x80                 ; 0 СТРОКА
 CALL WRC                   ;
 MOVLW 0x4B                 ; KEELOQ
 CALL WRD                   ;
 MOVLW 0x45                 ;
 CALL WRD                   ;
 MOVLW 0x45                 ;
 CALL WRD                   ;
 MOVLW 0x4C                 ;
 CALL WRD                   ;
 MOVLW 0x4F                 ;
 CALL WRD                   ;
 MOVLW 0x51                 ;
 CALL WRD                   ; 
 MOVLW 0x20                 ;
 CALL WRD                   ;
 MOVLW 0x20                 ; STARLINE
 CALL WRD                   ;
 MOVLW 0x53                 ;
 CALL WRD                   ;
 MOVLW 0x54                 ;
 CALL WRD                   ;
 MOVLW 0x41                 ;
 CALL WRD                   ;
 MOVLW 0x52                 ;
 CALL WRD                   ;
 MOVLW 0x4C                 ;
 CALL WRD                   ;
 MOVLW 0x49                 ;
 CALL WRD                   ;
 MOVLW 0x4E                 ;
 CALL WRD                   ;
 MOVLW 0x45                 ;
 CALL WRD                   ;

 MOVLW 0x94                 ; 2 СТРОКА
 CALL WRC                   ;
 MOVLW 0x44                 ; Decoder
 CALL WRD                   ;
 MOVLW 0x65                 ;
 CALL WRD                   ;
 MOVLW 0x63                 ;
 CALL WRD                   ;
 MOVLW 0x6F                 ;
 CALL WRD                   ;
 MOVLW 0x64                 ;
 CALL WRD                   ;
 MOVLW 0x65                 ;
 CALL WRD                   ;
 MOVLW 0x72                 ;
 CALL WRD                   ;
RETURN                      ;

PRINT_1                     ;
 MOVLW 0xD0                 ; 3 СТРОКА
 CALL WRC                   ;
 MOVLW 0x31                 ;
 CALL WRD                   ;
RETURN                      ;

PRINT_2                     ;
 MOVLW 0xD0                 ; 3 СТРОКА
 CALL WRC                   ;
 MOVLW 0x32                 ;
 CALL WRD                   ;
RETURN                      ;

PRINT_3                     ;
 MOVLW 0xD0                 ; 3 СТРОКА
 CALL WRC                   ;
 MOVLW 0x33                 ;
 CALL WRD                   ;
RETURN                      ;

END
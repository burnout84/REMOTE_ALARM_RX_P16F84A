;===============================================================================================
;
; PROG : РЕГИСТРАТОР КОДОВ KEELOQ/STARLINE (64 БИТ)
; OWNER: burnout84@rambler.ru
; PROC : PIC16F84A + AUREL RX BC-NBK
; FREQ : 4 MHZ
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

REG_A0              equ 12h ; ДЛЯ ПП 0 УРОВНЯ
REG_B0              equ 13h ;

REG_A1              equ 14h ; ДЛЯ ПП 1 УРОВНЯ
REG_B1              equ 15h ;
REG_C1              equ 16h ; 
REG_D1              equ 17h ; 

TEMP_LCD            equ 18h ; ДЛЯ ПП ЖКИ

FLAGS               equ 1Fh ; ФЛАГИ
                            ; 0 - Пакет успешно принят

BUFFER_0            equ 20h ; 1-й буфер 20h..27h
BUFFER_1            equ 28h ; 2-й буфер 28h..2Fh
BUFFER_2            equ 30h ; 3-й
BUFFER_3            equ 38h ; 4-й
BUFFER_4            equ 40h ; 5-й
BUFFER_5            equ 48h ; 6-й (временный)
;===============================================================================================
;                              НАЧАЛО ПРОГРАММЫ
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

;===============================================================================================
;                              ОСНОВНОЙ БЛОК ПРОГРАММЫ
;===============================================================================================
WAIT_FRONT                  ;

 BTFSS PORTB,LINE_RX        ; СМОТРИМ ФРОНТ
 GOTO $+6                   ;

 MOVLW .64                  ; ПРИНИМАЕМ ПАКЕТ
 CALL RX_PACKET             ;
 ADDWF PC,1                 ;
 NOP                        ;
 NOP                        ;

 BSF PORTA,SW_1             ; ВЫБОР РЕЖИМА (УСТАН.ЗНАЧЕНИЙ)
 BTFSS PORTA,SW_1           ;
 GOTO $+6                   ;
 MOVLW .6                   ; SL
 MOVWF RANGE_A              ; 
 MOVLW .46                  ;
 MOVWF RANGE_B              ;
 GOTO $+5                   ;
 MOVLW .16                  ; KL
 MOVWF RANGE_A              ; 
 MOVLW .82                  ;
 MOVWF RANGE_B              ;

GOTO WAIT_FRONT             ;
;===============================================================================================
;                              ПРИЕМ ПАКЕТА (0x01- OK  0x00- ERR)
;
; ВВОД: WREG - КОЛ-ВО СЧИТЫВАЕМЫХ БИТ                                               0 - УРОВЕНЬ
;===============================================================================================
RX_PACKET                   ;
 MOVWF REG_A0        ; ОБЩИЙ СЧЕТЧИК БИТОВ
 CLRF TMR0                  ; СБРОСИЛИ ТАЙМЕР
 BCF INTCON,2               ;
 CLRF RANGE_C               ; СБРОСИЛИ ДИАПАЗОНЫ
 CLRF RANGE_E               ;
 MOVLW BUFFER_5             ; ВЫБИР.ВРЕМЕННЫЙ БУФЕР
 MOVWF FSR                  ;
RX_PACKET_A                 ; НОВЫЙ БАЙТ
 MOVLW .8                   ;
 MOVWF REG_B0          ;
RX_PACKET_B                 ; ЦИКЛИЧ.ПРИЕМ 8 БИТ
 BCF INDF,0                 ;
 BTFSS PORTA,SW_1           ;
 CALL RX_BIT_KEELOQ         ; ПРИЕМ БИТА KEELOQ
 BTFSC PORTA,SW_1           ;
 CALL RX_BIT_STARLINE       ; ПРИЕМ БИТА STARLINE
 ADDWF PC,1                 ;
 RETLW 0x00                 ; 
 BSF INDF,0                 ;
 DECFSZ REG_A0,1     ; ДЕКРЕМЕНТ ОБЩЕГО СЧЕТЧИКА
 GOTO $+2                   ;
 GOTO RX_OK                 ;
 DECFSZ REG_B0,1       ; ДЕКРЕМЕНТ БИТОВ В БАЙТЕ
 GOTO $+3                   ;
 INCF FSR,1                 ;
 GOTO RX_PACKET_A           ; 
 RLF INDF,1                 ;
 GOTO RX_PACKET_B           ;
RX_OK                       ; ПРИЕМ УСПЕШНО ВЫПОЛНЕН
 BTFSS PORTA,SW_1           ; ONLY STARLINE
 GOTO $+0x12                ;
 MOVF RANGE_E,0             ; ЕСЛИ 2-Й ЛД НЕ ОПРЕДЕЛЕН - ERR
 XORLW 0x00                 ;
 BTFSC STATUS,Z             ;
 RETLW 0x00                 ;
 MOVF RANGE_E,0             ; ИНВЕРТИРУЕМ БИТЫ
 SUBWF RANGE_C,0            ;
 BTFSS STATUS,C             ;
 GOTO $+0x0A                ;
 MOVLW BUFFER_5             ;
 MOVWF FSR                  ;
 DECF FSR,1                 ;
 MOVLW 0x08                 ;
 MOVWF REG_A1               ;
 INCF FSR,1                 ;
 COMF INDF,1                ;
 DECFSZ REG_A1              ;
 GOTO $-3                   ;
RETLW 0x01                  ;
;===============================================================================================
;                             ПРИЕМ БИТА KEELOQ (0x01- OK  0x00- ERR)          
;
; REG_A1 - ВЫСОК.УРОВ.
; REG_B1 - НИЗК. УРОВ.
; REG_C1 - ЛОГ1+ЛОГ0
; REG_D1 - 25% ОТ (ЛОГ1+ЛОГ0)
;
; БИТ ЗАПИСЫВАЕТСЯ В РЕГИСТР INDF,0                                                 1 - УРОВЕНЬ
;===============================================================================================
RX_BIT_KEELOQ               ;
 BTFSS PORTB,LINE_RX        ; ЗАМЕРИЛИ ЛОГ 1
 GOTO $+4                   ;
 BTFSC INTCON,2             ;
 RETLW 0x00                 ;
 GOTO $-4                   ;
 MOVF TMR0,0                ; ЗАПОМНИЛИ ЛОГ 1
 MOVWF REG_A1               ;
 CLRF TMR0                  ; СБРОСИЛИ ТАЙМЕР
 BCF INTCON,2               ;
 MOVF RANGE_A,0             ; ПРОВЕРИЛИ ЛОГ 1
 SUBWF REG_A1,0             ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ;
 MOVF REG_A1,0              ;
 SUBWF RANGE_B,0            ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ;

 BTFSC PORTB,LINE_RX        ; ЗАМЕРИЛИ ЛОГ 0
 GOTO $+4                   ;
 BTFSC INTCON,2             ;
 RETLW 0x00                 ;
 GOTO $-4                   ;
 MOVF TMR0,0                ; ЗАПОМНИЛИ ЛОГ 0
 MOVWF REG_B1               ;
 CLRF TMR0                  ; СБРОСИЛИ ТАЙМЕР
 BCF INTCON,2               ;
 MOVF RANGE_A,0             ; ПРОВЕРИЛИ ЛОГ 0
 SUBWF REG_B1,0             ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ;
 MOVF REG_B1,0              ;
 SUBWF RANGE_B,0            ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ;

 MOVF REG_A1,0              ; ПОЛУЧАЕМ СУММУ УРОВНЕЙ
 ADDWF REG_B1,0             ;
 MOVWF REG_C1               ;

 MOVF RANGE_C,0             ; ЛОГИЧЕСКИЙ ДИАПАЗОН ОПРЕДЕЛЕН ? (ЛОГ1+ЛОГ0)+/-25%
 XORLW 0x00                 ;
 BTFSS STATUS,2             ;
 GOTO $+0x0C                ;
 MOVF REG_C1,0              ; ОПРЕДЕЛЯЕМ ДИАПАЗОН +/-25%
 MOVWF RANGE_C              ;
 MOVWF RANGE_D              ;
 MOVWF REG_D1               ;
 BCF STATUS,C               ;
 RRF REG_D1,1               ;
 BCF STATUS,C               ;
 RRF REG_D1,1               ;
 MOVF REG_D1,0              ;
 SUBWF RANGE_C,1            ;
 ADDWF RANGE_D,1            ;

 MOVF RANGE_C,0             ; ПРОВЕРЯЕМ (ЛОГ1+ЛОГ0) В РАМКАХ 1-ГО ДИАПАЗ.
 SUBWF REG_C1,0             ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ;
 MOVF REG_C1,0              ;
 SUBWF RANGE_D,0            ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ; 

 MOVF REG_A1,0              ; ОПРЕДЕЛЯЕМ БИТ, "ЧТО БОЛЬШЕ"
 SUBWF REG_B1,0             ; ЛОГ0 - ЛОГ1
 BTFSC STATUS,C             ;
 RETLW 0x01                 ;
RETLW 0x02                  ;
;===============================================================================================
;                             ПРИЕМ БИТА STARLINE      
;
; REG_A1 - ВЫСОК.УРОВ.
; REG_B1 - НИЗК. УРОВ.
; REG_C1 - ЛОГ1+ЛОГ0
; REG_D1 - 25% ОТ (ЛОГ1+ЛОГ0)
;
; РЕЗУЛЬТАТ В WREG:    0x00-ОШИБКА   0x01-БИТ=1   0x02-БИТ=0                        1 - УРОВЕНЬ
;===============================================================================================
RX_BIT_STARLINE             ;
 BTFSS PORTB,LINE_RX        ; ЗАМЕРИЛИ ЛОГ 1
 GOTO $+4                   ;
 BTFSC INTCON,2             ;
 RETLW 0x00                 ;
 GOTO $-4                   ;
 MOVF TMR0,0                ; ЗАПОМНИЛИ ЛОГ 1
 MOVWF REG_A1               ;
 CLRF TMR0                  ; СБРОСИЛИ ТАЙМЕР
 BCF INTCON,2               ;
 MOVF RANGE_A,0             ; ПРОВЕРИЛИ ЛОГ 1
 SUBWF REG_A1,0             ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ;
 MOVF REG_A1,0              ;
 SUBWF RANGE_B,0            ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ;

 BTFSC PORTB,LINE_RX        ; ЗАМЕРИЛИ ЛОГ 0
 GOTO $+4                   ;
 BTFSC INTCON,2             ;
 RETLW 0x00                 ;
 GOTO $-4                   ;
 MOVF TMR0,0                ; ЗАПОМНИЛИ ЛОГ 0
 MOVWF REG_B1               ;
 CLRF TMR0                  ; СБРОСИЛИ ТАЙМЕР
 BCF INTCON,2               ;
 MOVF RANGE_A,0             ; ПРОВЕРИЛИ ЛОГ 0
 SUBWF REG_B1,0             ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ;
 MOVF REG_B1,0              ;
 SUBWF RANGE_B,0            ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ;

 MOVF REG_A1,0              ; ПОЛУЧАЕМ СУММУ УРОВНЕЙ
 ADDWF REG_B1,0             ;
 MOVWF REG_C1               ;

 MOVF RANGE_C,0             ; 1-Й ЛОГИЧ. ДИАПАЗОН ЕСТЬ ?
 XORLW 0x00                 ;
 BTFSS STATUS,2             ;
 GOTO $+0x0C                ;
 MOVF REG_C1,0              ; ОПРЕДЕЛЯЕМ ДИАПАЗОН (1)
 MOVWF RANGE_C              ;
 MOVWF RANGE_D              ;
 MOVWF REG_D1               ;
 BCF STATUS,C               ;
 RRF REG_D1,1               ;
 BCF STATUS,C               ;
 RRF REG_D1,1               ;
 MOVF REG_D1,0              ;
 SUBWF RANGE_C,1            ;
 ADDWF RANGE_D,1            ;

 MOVF RANGE_C,0             ; ПРОВЕРЯЕМ (ЛОГ1+ЛОГ0) В РАМКАХ 1-ГО ДИАПАЗ.
 SUBWF REG_C1,0             ;
 BTFSS STATUS,C             ;
 GOTO $+5                   ;
 MOVF REG_C1,0              ;
 SUBWF RANGE_D,0            ;
 BTFSC STATUS,C             ;
 RETLW 0x01                 ; 

 MOVF RANGE_E,0             ; 2-Й ЛОГИЧ. ДИАПАЗОН ЕСТЬ ?
 XORLW 0x00                 ;
 BTFSS STATUS,2             ;
 GOTO $+0x0C                ;
 MOVF REG_C1,0              ; ОПРЕДЕЛЯЕМ ДИАПАЗОН (2)
 MOVWF RANGE_E              ;
 MOVWF RANGE_F              ;
 MOVWF REG_D1               ;
 BCF STATUS,C               ;
 RRF REG_D1,1               ;
 BCF STATUS,C               ;
 RRF REG_D1,1               ;
 MOVF REG_D1,0              ;
 SUBWF RANGE_E,1            ;
 ADDWF RANGE_F,1            ;

 MOVF RANGE_E,0             ; ПРОВЕРЯЕМ (ЛОГ1+ЛОГ0) В РАМКАХ 2-ГО ДИАПАЗ.
 SUBWF REG_C1,0             ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ;
 MOVF REG_C1,0              ;
 SUBWF RANGE_F,0            ;
 BTFSC STATUS,C             ;
 RETLW 0x02                 ; 

RETLW 0x00                  ;
;===============================================================================================
;                              ИНИЦИАЛИЗАЦИЯ LCD                                    0 - УРОВЕНЬ
;===============================================================================================
INIT_LCD			        ;
 MOVLW .15                  ; ОБЯЗАТЕЛЬНАЯ ПОСЛЕДОВАТЕЛЬНОСТЬ
 CALL DELAY_1_MS            ;
 BCF PORTB,RS               ; RS=0
 BCF PORTB,RW               ; RW=0
 BCF PORTB,E                ; E=0
 MOVLW h'30'		        ; Настройка
 MOVWF PORTA                ;
 BSF	PORTB,E             ; контроллера
 BCF	PORTB,E             ; LCD модуля
 MOVLW .4                   ;
 CALL DELAY_1_MS            ;
 BSF	PORTB,E	            ;
 BCF	PORTB,E	            ;
 MOVLW .50                  ;
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
;                             ВЫВОД БУФЕРА НА ЭКРАН ЖКИ
; НАЧАЛО: WREG - номер строки (0.. 3)
;         FSR  - адрес буфера (20,28,30,38,40,48)                                   0 - УРОВЕНЬ
;===============================================================================================
PRINT_BUFFER                ;
 CALL SELECT_LINE           ;
 CALL WRC                   ;
 DECF FSR,1                 ;
 MOVLW .8                   ;
 MOVWF REG_B0          ;

 INCF FSR,1                 ;
 MOVF INDF,0                ;
 MOVWF TEMP_LCD             ;
 BCF TEMP_LCD,0             ;
 BCF TEMP_LCD,1             ;
 BCF TEMP_LCD,2             ;
 BCF TEMP_LCD,3             ;
 SWAPF TEMP_LCD,1           ;
 MOVF TEMP_LCD,0            ;
 CALL HEX_TO_CHAR           ;
 CALL WRD                   ;

 MOVF INDF,0                ;
 MOVWF TEMP_LCD             ;
 BCF TEMP_LCD,4             ;
 BCF TEMP_LCD,5             ;
 BCF TEMP_LCD,6             ;
 BCF TEMP_LCD,7             ;
 MOVF TEMP_LCD,0            ;
 CALL HEX_TO_CHAR           ;
 CALL WRD                   ;
 DECFSZ REG_B0         ;
 GOTO $-0x15                ;

RETURN                      ;

;===============================================================================================
;                             КОНВЕРТИРУЕМ HEX-ЧИСЛО В СООТВ.КОД ЖКИ                1 - УРОВЕНЬ
;===============================================================================================
HEX_TO_CHAR                 ;
 ADDWF PC,1                 ;
 RETLW 0x30                 ;
 RETLW 0x31                 ;
 RETLW 0x32                 ;
 RETLW 0x33                 ;
 RETLW 0x34                 ;
 RETLW 0x35                 ;
 RETLW 0x36                 ;
 RETLW 0x37                 ;
 RETLW 0x38                 ;
 RETLW 0x39                 ;
 RETLW 0x41                 ;
 RETLW 0x42                 ;
 RETLW 0x43                 ;
 RETLW 0x44                 ;
 RETLW 0x45                 ;
RETLW 0x46                  ;
;===============================================================================================
;                             ВЫБОР СТРОКИ ЖКИ                                      1 - УРОВЕНЬ
;===============================================================================================
SELECT_LINE                 ;
 MOVLW 0x01                 ;
 MOVWF PCLATH               ;
 ADDWF PC,1                 ;
 RETLW 0x80                 ;
 RETLW 0xC0                 ;
 RETLW 0x90                 ;
RETLW 0xD0                  ;
;===============================================================================================
;                              ЗАПИСЬ КОДА КОМАНД LCD                               1 - УРОВЕНЬ
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
;                             ЗАПИСЬ КОДА ДАННЫХ LCD                                1 - УРОВЕНЬ
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
;                             ЗАДЕРЖКА (W x 2 мкс) + 2 мкс                          2 - УРОВЕНЬ
; REG_A1 - СЧЕТЧИК
;===============================================================================================
DELAY_2_MKS                 ;
 MOVWF REG_A1               ;
 NOP                        ;
 DECFSZ REG_A1,1            ;
 GOTO $-2                   ;
RETURN                      ;
;===============================================================================================
;                             ЗАДЕРЖКА (W x 1 мс)                                   2 - УРОВЕНЬ
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
;                              ПРИВЕТСТВИЕ
;===============================================================================================
PRINT_HELLO                 ;
 MOVLW 0x80                 ; 1 СТРОКА
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

END
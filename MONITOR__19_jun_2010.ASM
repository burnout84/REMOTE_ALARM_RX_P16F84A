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

RS                  equ 1   ; ЖКИ линия RS      (PORTB)
RW                  equ 2   ; ЖКИ линия RW      (PORTB)
E                   equ 3   ; ЖКИ линия E       (PORTB)

RANGE_A             equ 0Ch ; Диапазон валидного уровня лог0/лог1
RANGE_B             equ 0Dh ; 
RANGE_C             equ 0Eh ; Диапазон валидного бита лог0+лог1 (+/-25%)
RANGE_D             equ 0Fh ;
RANGE_E             equ 10h ; Диапазон валидного бита (2-е логич.состояние)
RANGE_F             equ 11h ;

REG_A0              equ 12h ; ДЛЯ ПП 0 УРОВНЯ
REG_B0              equ 13h ;
REG_C0              equ 14h ;

REG_A1              equ 15h ; ДЛЯ ПП 1 УРОВНЯ
REG_B1              equ 16h ;
REG_C1              equ 17h ; 
REG_D1              equ 18h ; 

TEMP_LCD            equ 19h ; ДЛЯ ПП ЖКИ
PACKET_COUNT        equ 1Ah ; СЧЕТЧИК ПАКЕТОВ

FLAGS               equ 1Fh ; ФЛАГИ
                            ; 0 - Пакет успешно принят
                            ; 1 - Режим приема (0-KL 1-SL)
                            ; 2 - Флаг обновления статуса
                            ; 3 - Флаг паузы
                            ; 4 - Флаг нажатой кнопки (любой)

BUFFER_0            equ 20h ; 0-й буфер 20h..27h
BUFFER_1            equ 28h ; 1-й буфер 28h..2Fh
BUFFER_2            equ 30h ; 2-й
BUFFER_3            equ 38h ; 3-й
BUFFER_4            equ 40h ; 4-й
BUFFER_5            equ 48h ; 5-й (временный)
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
 CLRF FLAGS                 ; Очищаем флаги
 CLRF PACKET_COUNT          ; Очищаем счетчик
 BSF FLAGS,2                ; Планируем отображение статуса
 CALL CLEAR_BANK_0          ; Очищаем банк 0
;===============================================================================================
;                              ОСНОВНОЕ КОЛЬЦО ПРОГРАММЫ
;===============================================================================================
 CALL PRINT_HELLO           ; ПРИВЕТСТВИЕ
 ;MOVLW 0x01                 ; ЗАДЕРЖКА
 ;CALL DELAY_1_S             ;
 MOVLW h'01'		        ; ОЧИСТКА ЭКРАНА
 CALL WRC	                ;
 CALL PRINT_STATUS          ; СТАТУС
WAIT_FRONT                  ;
 BSF PORTB,BTN_1            ; СБРАСЫВАЕМ КНОПКИ
 BSF PORTB,BTN_2            ;
 BSF PORTB,BTN_3            ;
 BSF PORTA,SW_1             ;

 BCF PORTB,LED_1            ; ГАСИМ ИНДИКАТОР

 BTFSC PORTB,BTN_3          ; КНОПКА 3
 GOTO $+8                   ;
 BSF FLAGS,4                ;
 BTFSS FLAGS,3              ;
 GOTO $+3                   ;
 BCF FLAGS,3                ;
 GOTO $+2                   ;
 BSF FLAGS,3                ;
 BSF FLAGS,2                ;

 BTFSS PORTA,SW_1           ; ВЫБОР РЕЖИМА (УСТАН.ЗНАЧЕНИЙ)
 GOTO $+9                   ;
 MOVLW .6                   ; SL
 MOVWF RANGE_A              ; MIN = 96
 MOVLW .44                  ; MAX = 704
 MOVWF RANGE_B              ;
 BTFSS FLAGS,1              ;
 BSF FLAGS,2                ;
 BSF FLAGS,1                ;
 GOTO $+8                   ;
 MOVLW .16                  ; KL
 MOVWF RANGE_A              ; MIN = 256
 MOVLW .82                  ; MAX = 2080
 MOVWF RANGE_B              ;
 BTFSC FLAGS,1              ;
 BSF FLAGS,2                ;
 BCF FLAGS,1                ;

 BTFSS FLAGS,2              ; ОБНОВЛЕНИЕ СТАТУСА
 GOTO $+3                   ;
 CALL PRINT_STATUS          ;
 BCF FLAGS,2                ;

 BTFSS FLAGS,4              ; ЗАЩИТА ОТ ДРЕБЕЗГА КОНТАКТОВ
 GOTO $+4                   ;
 MOVLW 0x01                 ;
 CALL DELAY_1_S             ;
 BCF FLAGS,4                ;

 BTFSC FLAGS,3              ; АКТИВИРОВАНА ПАУЗА
 GOTO WAIT_FRONT            ;

 BTFSS PORTB,LINE_RX        ; СМОТРИМ ФРОНТ
 GOTO WAIT_FRONT            ;

 MOVLW .64                  ; ПРИНИМАЕМ ПАКЕТ
 CALL RX_PACKET             ;
 CLRF PCLATH                ;
 ADDWF PC,1                 ;
 GOTO WAIT_FRONT            ;

 BSF PORTB,LED_1            ; ЗАЖИГАЕМ ИНДИКАТОР

 CALL CMP_BUFFER_4_5        ; СРАВНИВАЕМ 4 И 5 БУФЕР
 CLRF PCLATH                ;
 ADDWF PC,1                 ;
 GOTO WAIT_FRONT            ;

 CALL OFFSET_BUFFERS        ; СДВИГАЕМ БУФЕРЫ
 INCF PACKET_COUNT,1        ; УВЕЛИЧ.СЧЕТЧИК
 
 MOVLW BUFFER_4             ;
 MOVWF FSR                  ;
 MOVLW 0x02                 ;
 CALL PRINT_BUFFER          ;
 MOVLW BUFFER_3             ;
 MOVWF FSR                  ;
 MOVLW 0x01                 ;
 CALL PRINT_BUFFER          ;
 MOVLW BUFFER_2             ;
 MOVWF FSR                  ;
 MOVLW 0x00                 ;
 CALL PRINT_BUFFER          ; 

GOTO WAIT_FRONT             ;
;===============================================================================================
;                              ПРИЕМ ПАКЕТА (0x01- OK  0x00- ERR)
;
; ВВОД: WREG - КОЛ-ВО СЧИТЫВАЕМЫХ БИТ                                               0 - УРОВЕНЬ
;===============================================================================================
RX_PACKET                   ;
 MOVWF REG_A0               ; ОБЩИЙ СЧЕТЧИК БИТОВ
 CLRF TMR0                  ; СБРОСИЛИ ТАЙМЕР
 BCF INTCON,2               ;
 CLRF RANGE_C               ; СБРОСИЛИ ДИАПАЗОНЫ
 CLRF RANGE_E               ;
 MOVLW BUFFER_5             ; ВЫБИР.ВРЕМЕННЫЙ БУФЕР
 MOVWF FSR                  ;
RX_PACKET_A                 ; НОВЫЙ БАЙТ
 MOVLW .8                   ;
 MOVWF REG_B0               ;
RX_PACKET_B                 ; ЦИКЛИЧ.ПРИЕМ 8 БИТ
 BCF INDF,0                 ;
 BTFSS PORTA,SW_1           ;
 CALL RX_BIT_KEELOQ         ; ПРИЕМ БИТА KEELOQ
 BTFSC PORTA,SW_1           ;
 CALL RX_BIT_STARLINE       ; ПРИЕМ БИТА STARLINE
 CLRF PCLATH                ;
 ADDWF PC,1                 ;
 GOTO RX_OK                 ;
 BSF INDF,0                 ;
 DECFSZ REG_A0,1            ; ДЕКРЕМЕНТ ОБЩЕГО СЧЕТЧИКА
 GOTO $+2                   ;
 GOTO RX_OK                 ;
 DECFSZ REG_B0,1            ; ДЕКРЕМЕНТ БИТОВ В БАЙТЕ
 GOTO $+3                   ;
 INCF FSR,1                 ;
 GOTO RX_PACKET_A           ; 
 RLF INDF,1                 ;
 GOTO RX_PACKET_B           ;
RX_OK                       ; ПРИЕМ ВЫПОЛНЕН

 MOVF REG_A0                ; ЗАЧЕТ - МИНИМУМ 16 БИТ
 SUBLW .48                  ;
 BTFSS STATUS,C             ;
 RETLW 0x00                 ;

 BTFSS PORTA,SW_1           ; ПРОВЕРЯЕМ У STARLINE 2-Й ЛОГИЧ.ДИАПАЗОН
 GOTO $+0x12                ;
 MOVF RANGE_E,0             ;
 XORLW 0x00                 ;
 BTFSC STATUS,Z             ;
 RETLW 0x00                 ;

 MOVF RANGE_E,0             ; ИНВЕРТИРУЕМ БИТЫ STARLINE, ЕСЛИ ТРЕБУЕТСЯ
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
;
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

 MOVF REG_A1,0              ; ОПРЕДЕЛЯЕМ БИТ, "ЧТО БОЛЬШЕ ?"
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
 MOVLW .30                  ; ОБЯЗАТЕЛЬНАЯ ПОСЛЕДОВАТЕЛЬНОСТЬ
 CALL DELAY_1_MS            ;
 BCF PORTB,RS               ; RS=0
 BCF PORTB,RW               ; RW=0
 BCF PORTB,E                ; E=0
 MOVLW h'30'		        ; Настройка
 MOVWF PORTA                ;
 BSF	PORTB,E             ; контроллера
 BCF	PORTB,E             ; LCD модуля
 MOVLW .8                   ;
 CALL DELAY_1_MS            ;
 BSF	PORTB,E	            ;
 BCF	PORTB,E	            ;
 MOVLW .100                 ;
 CALL DELAY_2_MKS	        ;
 BSF	PORTB,E	            ;
 BCF	PORTB,E        	    ;
 CALL BUSY                  ;

 MOVLW 0x28                 ; ОТПРАВЛЯЕМ В LCD КОМАНДУ РАБОТЫ В 4-Х БИТНОМ РЕЖИМЕ
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
 CALL SELECT_LINE           ; ВЫБИРАЕМ СТРОКУ ЖКИ
 CALL WRC                   ;

 MOVF FSR,0                 ; ЗАПОМИНАЕМ FSR
 MOVWF REG_A0               ;

 MOVLW 0x08                 ; СРАВНИВАЕМ БУФЕР НА 0
 MOVWF REG_B0               ;
 MOVF INDF,0                ;
 XORLW 0x00                 ;
 BTFSS STATUS,Z             ;
 GOTO $+5                   ;
 INCF FSR                   ;
 DECFSZ REG_B0              ;
 GOTO $-6                   ;
 RETURN                     ;
 
 MOVF REG_A0,0              ; ОПРЕДЕЛЯЕМ НОМЕР ПАКЕТА
 MOVWF FSR                  ;
 CLRF REG_B0                ;
 MOVLW 0x40                 ;
 SUBWF FSR,0                ; FSR - W
 BTFSC STATUS,C             ; "+" или "0"
 GOTO $+5                   ;
 MOVLW 0x10                 ;
 ADDWF FSR,1                ;
 INCF REG_B0,1              ;
 GOTO $-7                   ;

 MOVF REG_A0,0              ; ЗАДАЕМ ЗНАЧЕНИЯ ДЛЯ ВЫВОДА
 MOVWF FSR                  ;
 MOVLW .8                   ;
 MOVWF REG_B0               ;

 MOVF INDF,0                ; ВЫВОДИМ БУФЕР НА ЭКРАН
 MOVWF REG_A0               ;
 BCF REG_A0,0               ;
 BCF REG_A0,1               ;
 BCF REG_A0,2               ;
 BCF REG_A0,3               ;
 SWAPF REG_A0,1             ;
 MOVF REG_A0,0              ;
 CALL HEX_TO_CHAR           ;
 CALL WRD                   ;
 MOVF INDF,0                ;
 MOVWF REG_A0               ;
 BCF REG_A0,4               ;
 BCF REG_A0,5               ;
 BCF REG_A0,6               ;
 BCF REG_A0,7               ;
 MOVF REG_A0,0              ;
 CALL HEX_TO_CHAR           ;
 CALL WRD                   ;
 INCF FSR,1                 ;
 DECFSZ REG_B0              ;
 GOTO $-0x15                ;

RETURN                      ;
;===============================================================================================
;                              СМЕСТИТЬ БУФЕРЫ 1->0 2->1 И Т.Д.
;===============================================================================================
OFFSET_BUFFERS              ;
 MOVLW 0x05                 ; КОЛ-ВО ПОВТОРЕНИЙ
 MOVWF REG_C0               ;
 MOVLW 0x18                 ; 0-БУФЕР
 MOVWF REG_A0               ;
 MOVLW 0x20                 ; 1-БУФЕР
 MOVWF REG_B0               ;

 MOVLW 0x08                 ; КОЛЬЦО
 ADDWF REG_A0,1             ;
 ADDWF REG_B0,1             ;
 MOVF REG_A0,0              ;
 MOVWF REG_B1               ;
 MOVF REG_B0,0              ;
 MOVWF REG_A1               ;
 CALL COPY_BUFFER           ;
 DECFSZ REG_C0              ;
 GOTO $-9                   ; 
RETURN                      ;
;===============================================================================================
;                              КОПИРОВАТЬ БУФЕР
; REG_A1 - БУФЕР АДРЕСАТ (ПЕРВЫЙ БАЙТ)
; REG_B1 - БУФЕР ПОЛУЧАТЕЛЬ
; REG_C1 - СЧЕТЧИК БАЙТОВ
; REG_D1 - ЯЧЕЙКА ХРАНЕНИЯ
;===============================================================================================
COPY_BUFFER                 ;
 MOVLW 0x08                 ;
 MOVWF REG_C1               ;
COPY_BUFFER_POINT           ;
 MOVF REG_A1,0              ;
 MOVWF FSR                  ;
 MOVF INDF,0                ;
 MOVWF REG_D1               ;
 MOVF REG_B1,0              ;
 MOVWF FSR                  ;
 MOVF REG_D1,0              ;
 MOVWF INDF                 ;
 INCF REG_A1,1              ;
 INCF REG_B1,1              ;
 DECFSZ REG_C1,1            ;
 GOTO COPY_BUFFER_POINT     ;
RETURN                      ;
;===============================================================================================
;                              ОЧИСТИТЬ БУФЕР
; REG_A1 - АДРЕС ПЕРВОГО БАЙТА БУФЕРА
; REG_C1 - СЧЕТЧИК БАЙТОВ
;===============================================================================================
CLEAR_BUFFER                ;
 MOVLW 0x08                 ;
 MOVWF REG_C1               ;
 MOVF REG_A1,0              ;
 MOVWF FSR                  ;
 CLRF INDF                  ;
 INCF FSR                   ;
 DECFSZ REG_C1,1            ;
 GOTO $-3                   ;
RETURN                      ;
;===============================================================================================
;                              СРАВНИТЬ 4 И 5 БУФЕР
; 0x00 - РАВНЫ    0x01 - НЕ РАВНЫ
;===============================================================================================
CMP_BUFFER_4_5              ;
 MOVLW BUFFER_4             ;
 MOVWF REG_A1               ;
 MOVLW BUFFER_5             ;
 MOVWF REG_B1               ;
 MOVLW 0x08                 ;
 MOVWF REG_C1               ;
 MOVF REG_A1,0              ;
 MOVWF FSR                  ;
 MOVF INDF,0                ;
 MOVWF REG_D1               ;
 MOVF REG_B1,0              ;
 MOVWF FSR                  ;
 MOVF INDF,0                ;
 XORWF REG_D1,0             ;
 BTFSS STATUS,Z             ;
 RETLW 0x01                 ;
 DECFSZ REG_C1,1            ;
 GOTO $-0x0B                ;
RETLW 0x00                  ;
;===============================================================================================
;                             КОНВЕРТИРУЕМ HEX В DEC                                1 - УРОВЕНЬ
; Число HEX должно быть не больше 0x63
;===============================================================================================
HEX_TO_DEC                  ;

RETURN                      ;
;===============================================================================================
;                             КОНВЕРТИРУЕМ HEX-ЧИСЛО В СООТВ.КОД ЖКИ                1 - УРОВЕНЬ
;===============================================================================================
HEX_TO_CHAR                 ;
 MOVWF REG_A1               ;
 MOVLW 0x01                 ;
 MOVWF PCLATH               ;
 MOVF REG_A1,0              ;
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
 MOVWF REG_A1               ;
 MOVLW 0x01                 ;
 MOVWF PCLATH               ;
 MOVF REG_A1,0              ;
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
 MOVLW .125                 ;
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
;                             ЗАДЕРЖКА (W x 1 секунду)                              2 - УРОВЕНЬ
; REG_C1 - СЧЕТЧИК
;===============================================================================================
DELAY_1_S                   ;
 MOVLW .4                   ;
 MOVWF REG_C1               ;
 MOVLW 0xFF                 ;
 CALL DELAY_1_MS            ;
 DECFSZ REG_C1              ;
 GOTO $-3                   ;
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
;                              ОЧИСТКА БАНКА 0
;===============================================================================================
CLEAR_BANK_0                ;
 MOVLW 0x0B                 ;
 MOVWF FSR                  ;
 INCF FSR,1                 ;
 CLRF INDF                  ;
 MOVLW 0x4F                 ;
 XORWF FSR,0                ;
 BTFSS STATUS,2             ;
 GOTO $-5                   ;
RETURN                      ;
;===============================================================================================
;                              ВЫВОД НА ЭКРАН ПРИВЕТСТВИЯ
;===============================================================================================
PRINT_HELLO                 ;
 MOVLW 0x90                 ; 2 СТРОКА
 CALL WRC                   ;
 MOVLW 0x34                 ; 433.92 MHZ
 CALL WRD                   ;
 MOVLW 0x33                 ;
 CALL WRD                   ;
 MOVLW 0x33                 ;
 CALL WRD                   ;
 MOVLW 0x2E                 ;
 CALL WRD                   ;
 MOVLW 0x39                 ;
 CALL WRD                   ;
 MOVLW 0x32                 ;
 CALL WRD                   ;
 MOVLW 0x20                 ;
 CALL WRD                   ;
 MOVLW 0x4D                 ;
 CALL WRD                   ;
 MOVLW 0x48                 ;
 CALL WRD                   ;
 MOVLW 0x5A                 ;
 CALL WRD                   ;
RETURN                      ;
;===============================================================================================
;                              ВЫВОД НА ЭКРАН СТАТУСА
;===============================================================================================
PRINT_STATUS                ;

 MOVLW 0xD0                 ; "прием" или "пауза"
 CALL WRC                   ;
 BTFSS FLAGS,3              ;
 GOTO PRINT_STATUS_RX       ;
 MOVLW 0xBE                 ;
 CALL WRD                   ;
 MOVLW 0x61                 ;
 CALL WRD                   ;
 MOVLW 0x79                 ;
 CALL WRD                   ;
 MOVLW 0xB7                 ;
 CALL WRD                   ;
 MOVLW 0x61                 ;
 CALL WRD                   ;
 GOTO $+0x0B                ;
PRINT_STATUS_RX             ;
 MOVLW 0xBE                 ;
 CALL WRD                   ;
 MOVLW 0x70                 ;
 CALL WRD                   ;
 MOVLW 0xB8                 ;
 CALL WRD                   ;
 MOVLW 0x65                 ;
 CALL WRD                   ;
 MOVLW 0xBC                 ;
 CALL WRD                   ;

 NOP                        ; счетчик

 MOVLW 0xD8                 ; "starline" или "keeloq"
 CALL WRC                   ;
 BTFSC PORTA,SW_1           ;
 GOTO PRINT_STATUS_SL       ;
 MOVLW 0x20                 ;
 CALL WRD                   ;
 MOVLW 0x20                 ;
 CALL WRD                   ;
 MOVLW 0x6B                 ;
 CALL WRD                   ;
 MOVLW 0x65                 ;
 CALL WRD                   ;
 MOVLW 0x65                 ;
 CALL WRD                   ;
 MOVLW 0x6C                 ;
 CALL WRD                   ;
 MOVLW 0x6F                 ;
 CALL WRD                   ;
 MOVLW 0x71                 ;
 CALL WRD                   ;
 RETURN                     ;
PRINT_STATUS_SL
 MOVLW 0x73                 ;
 CALL WRD                   ;
 MOVLW 0x74                 ;
 CALL WRD                   ;
 MOVLW 0x61                 ;
 CALL WRD                   ;
 MOVLW 0x72                 ;
 CALL WRD                   ;
 MOVLW 0x6C                 ;
 CALL WRD                   ;
 MOVLW 0x69                 ;
 CALL WRD                   ;
 MOVLW 0x6E                 ;
 CALL WRD                   ;
 MOVLW 0x65                 ;
 CALL WRD                   ;

RETURN                      ;

END
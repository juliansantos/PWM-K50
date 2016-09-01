 
 #include "config.h" ; Configuration bits
 
 #define RED LATC,1	 ;| Preprocessor directives
 #define GREEN LATC,2	 ;|
 #define BLUE LATC,0	 ;|	
 #define BUTTON PORTB,0	 ;|
 #define TRED TRISC,1    ;| 
 #define TGREEN TRISC,2  ;|
 #define TBLUE TRISC,0   ;|
 #define TBUTTON TRISB,0 ;|
 #define TPWM D'249' ; Period of PWM Signal = 4KHZ
 ;#define DTPWM D'77'
 #define TBlink ; Frecue
 
    cblock 0x60	    ;Varibles definition
    DTPWM  ; defining the duty cycle "Descarting the fraction"
    flag ; Number of times that a button has been push
    endc
    
    org 0x00 ; Origin of the program
    goto Main 
    org 0x08
    goto ISR

    org 0x100
Main:;--------------------------------------------------Main flux of the program
    call initialconfig ;Initial Configuration of the MCU
    call configINT0 ;Initial Configuration of External interrupt
    call configPWM ;Initial Configuration PWM 
    call initialstates ;Initial states of pins and vars
    bsf T2CON,TMR2ON ;Start the generation of PWM
    goto $
    
    
initialconfig: ;-----------------------Subrutine for Initial configuration (MCU)
    movlw 0x00
    movwf ANSELB ;I/O PORTB
    movwf ANSELC ;I/O PORTC  
    bcf TRED ;Setting data direction red LED
    bcf TBLUE ;Setting data direction blue LED
    bcf TGREEN ;Setting data direction green LED
    bsf TBUTTON ;Setting data direction of button
    return
configINT0:
    bcf INTCON,INT0IF ;Clearing flag
    bsf INTCON,INT0IE ;Enabling external INT0 interrupt + edge triggered
    bsf INTCON,GIE ;Enabling global interrupts
    return

configPWM: ;----------------------Subrutine for the initial configuration of PWM 
    clrf DTPWM ; Initial duty cycle =0
    movlw TPWM 
    movwf PR2   ;setting the period of the signal
    movf DTPWM,W ;Just for setting a initial state in PWM
    movwf CCPR1L
    movlw 0x00 ; No prescaler, off timer 2, no postscaler
    movwf T2CON
    clrf TMR2 ;initial value of timeh
    movlw 0x0C
    movwf CCP1CON  ;PWM operation
    return   
    
initialstates: ;------------------------Subrutine for setting the initial states
    call dirtable
    ;movlw 0x20
    ;movwf DTPWM
    clrf DTPWM ; Initial duty cycle =0
    bsf RED  ; LED red off
    bsf BLUE ; LED blue off
    bcf GREEN ; LED green on
    return
    
dirtable:
    movlw low TABLE
    movwf TBLPTRL
    movlw high TABLE
    movwf TBLPTRH
    movlw upper TABLE
    movwf TBLPTRU
    TBLRD* ;Initial value of TABLAT
    bcf flag,0 ;clear flag
    return
    
ISR: ;--------------------------------------------------Interrupt Service rutine  
    btfsc INTCON,INT0IF
    call ISR_INT0
    retfie 1 ; for restore some values from shadow registers
    
ISR_INT0: ;Interrupt Service Rutine for external interrupt 
    btfsc flag,0
    call dirtable ;if increment table after the last value reset pointer table
    TBLRD*+ ; move F(dir tblptr) -> TABLAT & PTR ++
    movlw D'248'
    cpfslt TABLAT
    bsf flag,0 ; if DC=100 set a flag
    
    movf TABLAT,W    
    movwf DTPWM
    movf DTPWM,W ;Just for setting a initial state in PWM
    movwf CCPR1L
    call debouncing
    bcf INTCON,INT0IF ;Clear the flag 
    return
    
    
debouncing: ;------------------------------------------------Avoiding debouncing
    ;Here must be the delay for avoid the bouncing in the switch
    return
    
TABLE: db D'0',D'32',D'64',D'96',D'128',D'160',D'192',D'224',D'249'  
 
    END
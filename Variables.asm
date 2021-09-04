; ================================================================
; Variables
; ================================================================

if !def(incVars)
incVars	set	1

SECTION	"Variables",WRAM0

; ================================================================
; Global variables
; ================================================================

GBCFlag:			ds	1
sys_btnHold:		ds	1	; held buttons
sys_btnPress:		ds	1	; pressed buttons

CurrentSample:		ds	1

; ================================================================

SECTION "Temporary register storage space",HRAM

tempAF:				ds	2
tempBC:				ds	2
tempDE:				ds	2
tempHL:				ds	2
tempSP:				ds	2
tempPC:				ds	2
tempIF:				ds	1
tempIE:				ds	1
OAM_DMA:			ds	8

; ================================================================

endc

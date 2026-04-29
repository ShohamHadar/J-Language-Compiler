NB. functions.ijs

translateFunction =: 3 : 0
  'fName kVars' =. y
  k =. ". kVars
  
  NB. 1. הגדרת התווית של הפונקציה [cite: 15]
  asm =. < '(', fName, ')'
  
  NB. 2. אתחול k משתנים מקומיים (local) ל-0 [cite: 5, 9]
  NB. מבצעים push constant 0 בדיוק k פעמים
  if. k > 0 do.
    for_i. i. k do.
      NB. שרשור פקודות האסמבלר של דחיפת 0 למחסנית
      asm =. asm , (' @0') ; (' D=A') ; (' @SP') ; (' A=M') ; (' M=D') ; (' @SP') ; < ' M=M+1'
    end.
  end.
  
  asm
)

translateCall =: 3 : 0
  'fName nArgs' =. y
  NB. יצירת תווית חזרה ייחודית בעזרת callCount
  retLabel =. fName , '$ret.' , ": callCount
  callCount =: callCount + 1
  
  NB. 1. דחיפת כתובת חזרה (push retLabel)
  asm =. (' @' , retLabel) ; (' D=A') ; (' @SP') ; (' A=M') ; (' M=D') ; (' @SP') ; < ' M=M+1'
  
  NB. 2. שמירת LCL, ARG, THIS, THAT (עוברים על הרשימה ודוחפים כל אחד)
  for_seg. 'LCL';'ARG';'THIS';'THAT' do.
    asm =. asm , (' @' , >seg) ; (' D=M') ; (' @SP') ; (' A=M') ; (' M=D') ; (' @SP') ; < ' M=M+1'
  end.
  NB. 3. ARG = SP - 5 - nArgs
  asm =. asm , (' @SP') ; (' D=M') ; (' @5') ; (' D=D-A') ; (' @' , nArgs) ; (' D=D-A') ; (' @ARG') ; < ' M=D'

  NB. 4. LCL = SP
  asm =. asm , (' @SP') ; (' D=M') ; (' @LCL') ; < ' M=D'
  
  NB. 5. goto fName
  asm =. asm , (' @' , fName) ; < ' 0;JMP'
  
  NB. 6. הצבת תווית החזרה
  asm =. asm , < '(', retLabel, ')'
  asm
)

translateReturn =: 3 : 0
  NB. שימוש ב-R14 כמשתנה זמני ל-FRAME וב-R15 לכתובת החזרה (RET)
  NB. FRAME = LCL
  asm =. (' @LCL') ; (' D=M') ; (' @R14') ; < ' M=D'
  
  NB. RET = *(FRAME - 5)
  asm =. asm , (' @5') ; (' A=D-A') ; (' D=M') ; (' @R15') ; < ' M=D'
  
  NB. *ARG = pop() - הנחת ערך החזרה במקום של הארגומנט הראשון
  asm =. asm , (' @SP') ; (' AM=M-1') ; (' D=M') ; (' @ARG') ; (' A=M') ; < ' M=D'
  
  NB. SP = ARG + 1
  asm =. asm , (' @ARG') ; (' D=M+1') ; (' @SP') ; < ' M=D'
  
  NB. שחזור THAT, THIS, ARG, LCL (בסדר הפוך מהדחיפה)
  NB. THAT = *(FRAME-1), THIS = *(FRAME-2)...
  for_i. 1 2 3 4 do.
    target =. > (i-1) { 'THAT';'THIS';'ARG';'LCL'
    asm =. asm , (' @R14') ; (' D=M') ; (' @' , ":i) ; (' A=D-A') ; (' D=M') ; (' @' , target) ; < ' M=D'
  end.
  
  NB. goto RET (קפיצה חזרה לקורא)
  asm =. asm , (' @R15') ; < ' A=M;JMP'
  asm
)


NB. 
translateInit =: 3 : 0
  NB. 1. אתחול ה-Stack Pointer ל-256
  asm =. (' @256') ; (' D=A') ; (' @SP') ; < ' M=D'
  
  NB. 2. קריאה ל-Sys.init 0. 
  NB. שימי לב: זה יוסיף אוטומטית את ה-push-ים וה-jump
  asm =. asm , translateCall 'Sys.init' ; '0'
  asm
)
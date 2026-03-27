NB.memory.ijs file

translatePushDirect =: 3 : 0
  NB. y היא הכתובת הישירה ב-RAM (למשל "5", "6" וכו')
  addr =. y
  (' @' , addr) ; (' D=M') ; (' @SP') ; (' A=M') ; (' M=D') ; (' @SP') ; < ' M=M+1'
)

translatePopDirect =: 3 : 0
  NB. y היא הכתובת הישירה ב-RAM
  addr =. y
  (' @SP') ; (' AM=M-1') ; (' D=M') ; (' @' , addr) ; < ' M=D'
)
translatePushPointer =: 3 : 0
  addr =. ": 3 + ". y  NB. הופך '0' ל-3 ו-'1' ל-4
  (' @' , addr) ; ' D=M' ; ' @SP' ; ' A=M' ; ' M=D' ; ' @SP' ; ' M=M+1'
)

translatePopPointer =: 3 : 0
  addr =. ": 3 + ". y
  ' @SP' ; ' AM=M-1' ; ' D=M' ; (' @' , addr) ; ' M=D'
)

translatePushSegment =: 3 : 0
  'reg index' =. y
  NB. 1. גישה לערך (base + index) ושמירה ב-D
  asm =. (' @' , index) ; (' D=A') ; (' @' , reg) ; (' A=D+M') ; < ' D=M'
  
  NB. 2. דחיפה למחסנית
  asm =. asm , (' @SP') ; (' A=M') ; (' M=D') ; (' @SP') ; < ' M=M+1'
  asm
)
translatePopSegment =: 3 : 0
  'reg index' =. y
  NB. 1. חישוב הכתובת (base + index) ושמירה ב-R13
  asm =. (' @' , index) ; (' D=A') ; (' @' , reg) ; (' D=D+M') ; (' @R13') ; < ' M=D'
  
  NB. 2. Pop מהמחסנית ל-D
  asm =. asm , (' @SP') ; (' AM=M-1') ; < ' D=M'
  
  NB. 3. העברת D לכתובת ששמורה ב-R13
  asm =. asm , (' @R13') ; (' A=M') ; < ' M=D'
  asm
)

NB. פונקציה לתרגום push constant x
NB. מקבלת את הערך x (כמחרוזת) ומחזירה רשימת שורות Assembly 
translatePushConstant =: 3 : 0
  val =. y
  NB. רצף פקודות Assembly להכנסת קבוע למחסנית
  (' @', val) ; ' D=A' ; ' @SP' ; ' A=M' ; ' M=D' ; ' @SP' ; ' M=M+1'
)

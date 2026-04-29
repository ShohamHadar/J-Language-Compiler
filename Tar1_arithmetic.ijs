NB.arithmetic.ijs file


NB. מבצעת pop לשני איברים ומחזירה את הסכום
translateAdd =: 3 : 0
  NB. 1. ניגשים לאיבר העליון (y), 2. מורידים SP, 3. מחברים לאיבר הבא (x)
  ' @SP' ; ' AM=M-1' ; ' D=M' ; ' A=A-1' ; ' M=M+D'
)

translateSub =: 3 : 0
  NB. 1. ניגשים לאיבר העליון (y), 2. מורידים SP, 3. מחסרים את האיבר הבא (x)
  ' @SP' ; ' AM=M-1' ; ' D=M' ; ' A=A-1' ; ' M=M-D'
)

translateAnd =: 3 : 0
  ' @SP' ; ' AM=M-1' ; ' D=M' ; ' A=A-1' ; ' M=M&D'
)

translateOr =: 3 : 0
  ' @SP' ; ' AM=M-1' ; ' D=M' ; ' A=A-1' ; ' M=M|D'
)

translateNeg =: 3 : 0
  NB. ניגשים לאיבר האחרון שנמצא ב-SP-1 והופכים אותו לשלילי
  ' @SP' ; ' A=M-1' ; ' M=-M'
)

translateNot =: 3 : 0
  NB. ניגשים לאיבר האחרון שנמצא ב-SP-1 והופכים אותו
  ' @SP' ; ' A=M-1' ; ' M=!M'
)

NB. פונקציה גנרית להשוואה (eq, gt, lt)
NB. type - סוג הקפיצה (JEQ, JGT, JLT)
translateComp =: 3 : 0
  type =. y
  label =. 'LABEL_' , ": labelCount
  labelCount =: labelCount + 1
  
  NB. יצירת רשימה ראשונית
  asm =. (' @SP') ; (' AM=M-1') ; (' D=M') ; (' A=A-1') ; (' D=M-D')
  
  NB. הוספת שורות חדשות לרשימת הקופסאות
  asm =. asm , (' @' , label , '_TRUE') ; (' D;' , type)
  asm =. asm , (' @SP') ; (' A=M-1') ; (' M=0') ; (' @' , label , '_END') ; (' 0;JMP')
  asm =. asm , ('(' , label , '_TRUE)') ; (' @SP') ; (' A=M-1') ; (' M=-1')
  asm =. asm , < '(' , label , '_END)'
)


NB. תרגולללללל
NB. פונקציה המתרגמת את פקודת depth ל-Assembly של Hack
  NB. 1. חישוב המרחק: D = SP - 256
  NB. 2. הכנסת הערך D לכתובת ש-SP מצביע עליה
  NB. 3. קידום ה-SP ב-1
translateDepth =: 3 : 0

  ' @SP' ; ' D=M' ; ' @256' ; ' D=D-A' ; ' @SP' ; ' A=M' ; ' M=D' ; ' @SP' ; ' M=M+1'
)
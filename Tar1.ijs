load 'files'
load 'dir'

NB. עדכון נתיבים לתיקיית הפרויקט החדשה
searchPattern =: 'C:\Users\ASUS\Desktop\nand2tetris\projects\7\MemoryAccess\StaticTest\*.vm'
outputFile =: 'C:\Users\ASUS\Desktop\nand2tetris\projects\7\MemoryAccess\StaticTest\StaticTest.asm'
'' fwrite outputFile

vmFiles =: 1 dir searchPattern
labelCount =: 0


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
  NB. רצף פקודות Assembly להכנסת קבוע למחסנית [cite: 88, 92]
  (' @', val) ; ' D=A' ; ' @SP' ; ' A=M' ; ' M=D' ; ' @SP' ; ' M=M+1'
)




NB. פונקציה לתרגום add
NB. מבצעת pop לשני איברים ומחזירה את הסכום [cite: 86, 88]
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

NB. ... (הגדרות הנתיבים והפונקציות translate נשארות כפי שהן) ...

processFiles =: 3 : 0
  for_file_path. y do.
    item =. > file_path
    
    NB. חילוץ שם הקובץ לצורך זיהוי (למשל עבור פקודות static בעתיד) [cite: 131]
    start =. 1 + item i: '/'
    end =. item i. '.' 
    fileName =. (end - start) {. start }. item
    echo 'Processing: ', fileName
    
    lines =. cutLF freads item
    
    for_line. lines do.
      lineStr =. deb > line
      if. (0 = # lineStr) +. ('//' -: 2 {. lineStr) do. continue. end.
      
      words =. cut lineStr
      cmd =. > 0 { words
      asmLines =. ''  NB. משתנה שיחזיק את תוצאת התרגום
NB. --- זיהוי פקודות PUSH ---
      if. cmd -: 'push' do.
        segment =. > 1 { words
        index =. > 2 { words
        
        if. segment -: 'constant' do.
          asmLines =. translatePushConstant index
        elseif. segment -: 'pointer' do.
          asmLines =. translatePushPointer index
        elseif. segment -: 'temp' do.
          targetAddr =. 5 + ". index
          asmLines =. translatePushDirect ": targetAddr
        elseif. segment -: 'static' do.
          NB. טיפול בסטטי: @FileName.Index
          asmLines =. (' @' , fileName , '.' , index) ; ' D=M' ; ' @SP' ; ' A=M' ; ' M=D' ; ' @SP' ; ' M=M+1'
        elseif. segment -: 'local' do.
          asmLines =. translatePushSegment 'LCL' ; index
        elseif. segment -: 'argument' do.
          asmLines =. translatePushSegment 'ARG' ; index
        elseif. segment -: 'this' do.
          asmLines =. translatePushSegment 'THIS' ; index
        elseif. segment -: 'that' do.
          asmLines =. translatePushSegment 'THAT' ; index
        end.
NB. --- זיהוי פקודות POP ---
      elseif. cmd -: 'pop' do.
        segment =. > 1 { words
        index =. > 2 { words
        
        if. segment -: 'pointer' do.
          asmLines =. translatePopPointer index
        elseif. segment -: 'temp' do.
          targetAddr =. 5 + ". index
          asmLines =. translatePopDirect ": targetAddr
        elseif. segment -: 'static' do.
          NB. טיפול בסטטי: מוציאים מהמחסנית ושומרים ב-@FileName.Index
          asmLines =. ' @SP' ; ' AM=M-1' ; ' D=M' ; (' @' , fileName , '.' , index) ; ' M=D'
        elseif. segment -: 'local' do.
          asmLines =. translatePopSegment 'LCL' ; index
        elseif. segment -: 'argument' do.
          asmLines =. translatePopSegment 'ARG' ; index
        elseif. segment -: 'this' do.
          asmLines =. translatePopSegment 'THIS' ; index
        elseif. segment -: 'that' do.
          asmLines =. translatePopSegment 'THAT' ; index
        end.

      NB. 2. זיהוי פקודות אריתמטיות בינאריות (דורשות 2 איברים מהמחסנית) [cite: 88]
      elseif. cmd -: 'add' do. asmLines =. translateAdd ''
      elseif. cmd -: 'sub' do. asmLines =. translateSub ''
      elseif. cmd -: 'and' do. asmLines =. translateAnd ''
      elseif. cmd -: 'or'  do. asmLines =. translateOr ''
      
      NB. 3. זיהוי פקודות אריתמטיות אונאריות (פועלות על איבר אחד) [cite: 89]
      elseif. cmd -: 'neg' do. asmLines =. translateNeg ''
      elseif. cmd -: 'not' do. asmLines =. translateNot ''

      elseif. cmd -: 'eq'  do. asmLines =. translateComp 'JEQ'
      elseif. cmd -: 'gt'  do. asmLines =. translateComp 'JGT'
      elseif. cmd -: 'lt'  do. asmLines =. translateComp 'JLT'
      end.

     if. 0 < # asmLines do.
        ('// ' , lineStr , LF) fappend outputFile
       NB. (; asmLines ,each <LF) fappend outputFile
        ( ; asmLines ,&.> <LF) fappend outputFile
      end.
    end.
  end.
  echo 'Translation Complete!'
  

)
NB. הרצת התהליך
processFiles vmFiles
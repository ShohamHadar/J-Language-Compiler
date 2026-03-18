load 'files'
load 'dir'

NB. עדכון נתיבים לתיקיית הפרויקט החדשה
searchPattern =: 'C:/Users/User/nand2tetris/nand2tetris/projects/07/StackArithmetic/SimpleAdd/*.vm'
outputFile =: 'C:/Users/User/nand2tetris/nand2tetris/projects/07/StackArithmetic/SimpleAdd/SimpleAdd.asm'
'' fwrite outputFile

vmFiles =: 1 dir searchPattern

NB. פונקציה לתרגום push constant x
NB. מקבלת את הערך x (כמחרוזת) ומחזירה רשימת שורות Assembly 
translatePushConstant =: 3 : 0
  val =. y
  NB. רצף פקודות Assembly להכנסת קבוע למחסנית [cite: 88, 92]
  (' @', val) ; ' D=A' ; ' @SP' ; ' A=M' ; ' M=D' ; ' @SP' ; ' M=M+1'
)

NB. x - שם המקטע (LCL, ARG וכו'), y - האינדקס
translatePushSegment =: 3 : 0
  'segment index' =. y
  NB. 1. חישוב הכתובת: addr = segmentPointer + index
  (' @' , index) ; ' D=A' ; (' @' , segment) ; ' A=M+D' ; 
  NB. 2. לקיחת הערך מהכתובת ושמירה ב-D
  ' D=M' ; 
  NB. 3. דחיפה למחסנית (כמו ב-push constant)
  ' @SP' ; ' A=M' ; ' M=D' ; ' @SP' ; ' M=M+1'
)

translatePopSegment =: 3 : 0
  'segment index' =. y
  NB. 1. חישוב כתובת יעד ושמירה ב-R13: R13 = segmentPointer + index
  (' @' , index) ; ' D=A' ; (' @' , segment) ; ' D=M+D' ; ' @R13' ; ' M=D' ;
  NB. 2. הוצאת ערך מהמחסנית ל-D
  ' @SP' ; ' AM=M-1' ; ' D=M' ;
  NB. 3. כתיבת הערך לכתובת ששמורה ב-R13
  ' @R13' ; ' A=M' ; ' M=D'
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
        elseif. segment e. 'local';'argument';'this';'that' do.
          NB. מיפוי שם המקטע לשם הרגיסטר
          regName =. (> segment e. 'local';'argument';'this';'that') { 'LCL';'ARG';'THIS';'THAT'
          asmLines =. translatePushSegment regName ; index
        end.

      NB. --- זיהוי פקודות POP ---
      elseif. cmd -: 'pop' do.
        segment =. > 1 { words
        index =. > 2 { words
        
        if. segment e. 'local';'argument';'this';'that' do.
          regName =. (> segment e. 'local';'argument';'this';'that') { 'LCL';'ARG';'THIS';'THAT'
          asmLines =. translatePopSegment regName ; index
        end.

      NB. 2. זיהוי פקודות אריתמטיות בינאריות (דורשות 2 איברים מהמחסנית) [cite: 88]
      elseif. cmd -: 'add' do. asmLines =. translateAdd ''
      elseif. cmd -: 'sub' do. asmLines =. translateSub ''
      elseif. cmd -: 'and' do. asmLines =. translateAnd ''
      elseif. cmd -: 'or'  do. asmLines =. translateOr ''
      
      NB. 3. זיהוי פקודות אריתמטיות אונאריות (פועלות על איבר אחד) [cite: 89]
      elseif. cmd -: 'neg' do. asmLines =. translateNeg ''
      elseif. cmd -: 'not' do. asmLines =. translateNot ''
      end.

     if. 0 < # asmLines do.
        ('// ' , lineStr , LF) fappend outputFile
        (; asmLines ,each <LF) fappend outputFile
      end.
    end.
  end.
  echo 'Translation Complete!'
)
NB. הרצת התהליך
processFiles vmFiles
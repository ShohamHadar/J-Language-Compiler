load 'C:\Users\User\j9.6-user\temp\tar5_tokenizer.ijs'
load 'C:\Users\User\j9.6-user\temp\tar5_symtable.ijs'
load 'C:\Users\User\j9.6-user\temp\tar5_vmwriter.ijs'


NB. =========================================================================
NB. חלק ד': Compilation Engine (מנוע ההידור)
NB. תפקיד: ניתוח המבנה התחבירי (Parsing) של האסימונים ותרגומם לקוד VM סימולטנית
NB. =========================================================================

tokenIdx =: 0                                      NB. מצביע לאסימון הנוכחי ברשימה
labelCounter =: 0                                  NB. מונה לייצור תוויות ייחודיות (L0, L1...)

NB. שליפת סוג האסימון הנוכחי (keyword, identifier, symbol וכו')
getCurrentType =: 3 : 0
  if. tokenIdx < # tokensList do. > 0 { tokenIdx { tokensList return. end.
  ''
)

NB. שליפת הערך של האסימון הנוכחי (למשל השם של המשתנה או סימן ה-'+')
getCurrentValue =: 3 : 0
  if. tokenIdx < # tokensList do. > 1 { tokenIdx { tokensList return. end.
  ''
)

NB. התקדמות לאסימון הבא בתור
advanceToken =: 3 : 0
  tokenIdx =: tokenIdx + 1
  EMPTY
)

NB. בדיקה האם האסימון הנוכחי שווה לערך מסוים (מבלי להתקדם)
checkValue =: 3 : 0
  if. tokenIdx < # tokensList do. (getCurrentValue'') -: y return. end.
  0
)

NB. הצצה קדימה: קריאת ערך של אסימון שנמצא y צעדים קדימה (Lookahead)
lookAheadValue =: 3 : 0
  if. (tokenIdx + y) < # tokensList do. > 1 { (tokenIdx + y) { tokensList return. end.
  ''
)

NB. יצירת שם תווית חדש וייחודי (למשל ללולאות ותנאים)
getNewLabel =: 3 : 0
  res =. 'L' , ": labelCounter
  labelCounter =: labelCounter + 1
  res
)

NB. הידור של מחלקה שלמה (נקודת הכניסה לקובץ Jack)
compileClass =: 3 : 0
  advanceToken''                                    NB. דילוג על המילה 'class'
  className =: getCurrentValue''                    NB. שמירת שם המחלקה
  advanceToken''                                    NB. דילוג על שם המחלקה
  advanceToken''                                    NB. דילוג על הסוגר הפותח '{'
  
  initClassTable''                                  NB. אתחול טבלת הסמלים של המחלקה
  
  NB. הידור משתני המחלקה (static ו-field) כל עוד קיימים
  while. tokenIdx < # tokensList do.
    val =. getCurrentValue''
    if. val -: 'static' do. compileClassVarDec''
    elseif. val -: 'field' do. compileClassVarDec''
    elseif. do. break. end.
  end.
  
  NB. הידור הפונקציות, המתודות והבנאים (Subroutines) של המחלקה
  while. tokenIdx < # tokensList do.
    val =. getCurrentValue''
    if. val -: 'constructor' do. compileSubroutineDec''
    elseif. val -: 'function' do. compileSubroutineDec''
    elseif. val -: 'method' do. compileSubroutineDec''
    elseif. do. break. end.
  end.
  
  advanceToken''                                    NB. דילוג על הסוגר הסוגר '}'
  EMPTY
)

NB. הידור הצהרת משתני מחלקה (למשל: field int x, y;)
compileClassVarDec =: 3 : 0
  kind =. getCurrentValue''                        NB. static או field
  advanceToken'' 
  type =. getCurrentValue''                        NB. הטיפוס (int, boolean, שם מחלקה...)
  advanceToken'' 
  
  name =. getCurrentValue''                        NB. שם המשתנה הראשון
  advanceToken'' 
  (name ; type ; kind) defineSymbol ''             NB. רישום המשתנה בטבלת הסמלים
  
  NB. טיפול ברשימת משתנים המופרדים בפסיקים (למשל: field int x, y, z;)
  while. tokenIdx < # tokensList do.
    if. checkValue ',' do.
      advanceToken'' 
      name =. getCurrentValue''
      advanceToken'' 
      (name ; type ; kind) defineSymbol ''
    else. break. end.
  end.
  
  advanceToken''                                    NB. דילוג על הנקודה-פסיק ';'
  EMPTY
)

NB. הידור פונקציות, מתודות או בנאים (Subroutine)
compileSubroutineDec =: 3 : 0
  initSubTable''                                    NB. אתחול טבלת סמלים נקודתית חדשה
  subType =. getCurrentValue''                      NB. constructor / function / method
  advanceToken''
  
  advanceToken''                                    NB. דילוג על טיפוס ההחזרה (void, int וכו')
  subName =. getCurrentValue''                      NB. שם הפונקציה
  advanceToken'' 
  
  NB. אם מדובר במתודה (method), הארגומנט הראשון הנסתר הוא תמיד המצביע לאובייקט הנוכחי (this)
  if. subType -: 'method' do.
    ('this' ; className ; 'argument') defineSymbol ''
  end.
  
  advanceToken''                                    NB. דילוג על הסוגר הפותח '(' של הפרמטרים
  compileParameterList''                            NB. הידור רשימת הארגומנטים
  advanceToken''                                    NB. דילוג על הסוגר הסוגר ')'
  
  advanceToken''                                    NB. דילוג על הסוגר הפותח '{' של גוף הפונקציה
  NB. הידור משתנים מקומיים (var) בתחילת הפונקציה
  while. tokenIdx < # tokensList do.
    if. checkValue 'var' do. compileVarDec''
    else. break. end.
  end.
  
  NB. כתיבת פקודת ה-function של ה-VM עם כמות המשתנים המקומיים
  writeFunction (className , '.' , subName) ; (varCount 'var')
  
  NB. ניהול ה-Calling Convention (פרוטוקול הקריאה):
  if. subType -: 'method' do.
    NB. במתודה: מעבירים את המצביע שחיווטנו בארגומנט 0 אל סגמנט pointer 0 (על מנת ש-this יעבוד)
    writePush 'argument' ; 0
    writePop 'pointer' ; 0
  elseif. subType -: 'constructor' do.
    NB. בבנאי: מקצים זיכרון עבור שדות המערך, ומכוונים את pointer 0 לאובייקט החדש שנוצר
    writePush 'constant' ; (varCount 'field')
    writeCall 'Memory.alloc' ; 1
    writePop 'pointer' ; 0
  end.
  
  compileStatements''                               NB. הידור פקודות גוף הפונקציה (let, if, while...)
  advanceToken''                                    NB. דילוג על הסוגר הסוגר '}'
  EMPTY
)

NB. הידור רשימת הפרמטרים של פונקציה (למשל: int x, char c)
compileParameterList =: 3 : 0
  if. -. checkValue ')' do.
    type =. getCurrentValue''
    advanceToken''
    name =. getCurrentValue''
    advanceToken''
    (name ; type ; 'argument') defineSymbol ''
    
    while. tokenIdx < # tokensList do.
      if. checkValue ',' do.
        advanceToken'' 
        type =. getCurrentValue''
        advanceToken''
        name =. getCurrentValue''
        advanceToken''
        (name ; type ; 'argument') defineSymbol ''
      else. break. end.
    end.
  end.
  EMPTY
)

NB. הידור הצהרת משתנים מקומיים בתוך פונקציה (למשל: var int i, j;)
compileVarDec =: 3 : 0
  advanceToken''                                    NB. דילוג על 'var'
  type =. getCurrentValue''
  advanceToken'' 
  
  name =. getCurrentValue''
  advanceToken'' 
  (name ; type ; 'var') defineSymbol ''
  
  while. tokenIdx < # tokensList do.
    if. checkValue ',' do.
      advanceToken'' 
      name =. getCurrentValue''
      advanceToken'' 
      (name ; type ; 'var') defineSymbol ''
    else. break. end.
  end.
  
  advanceToken''                                    NB. דילוג על ';'
  EMPTY
)

NB. הידור אוסף פקודות (Statements) בתוך בלוק
compileStatements =: 3 : 0
  while. tokenIdx < # tokensList do.
    val =. getCurrentValue''
    if. val -: 'let' do. compileLet''
    elseif. val -: 'if' do. compileIf''
    elseif. val -: 'while' do. compileWhile''
    elseif. val -: 'do' do. compileDo''
    elseif. val -: 'return' do. compileReturn''
    else. break. end.
  end.
  EMPTY
)

NB. הידור פקודת do (קריאה לפונקציה והתעלמות מערך ההחזרה שלה)
compileDo =: 3 : 0
  advanceToken''                                    NB. דילוג על 'do'
  compileSubroutineCall''                           NB. הידור הקריאה עצמה (דוחף את ערך ההחזרה למחסנית)
  advanceToken''                                    NB. דילוג על ';'
  writePop 'temp' ; 0                               NB. זריקת ערך ההחזרה ל-temp 0 כי פקודת do מתעלמת ממנו
  EMPTY
)

NB. הידור פקודת השמה (let x = expr; או let arr[i] = expr;)
compileLet =: 3 : 0
  advanceToken''                                    NB. דילוג על 'let'
  varName =. getCurrentValue''                      NB. שם משתנה היעד
  advanceToken'' 
  
  isArray =. 0
  NB. טיפול במקרה של השמה לתא במערך: let arr[i] = expr;
  if. checkValue '[' do.
    isArray =. 1
    advanceToken''                                  NB. דילוג על '['
    compileExpression''                             NB. הידור הביטוי שבתוך הסוגריים (האינדקס)
    advanceToken''                                  NB. דילוג על ']'
    sym =. lookupSymbol varName
    if. # sym do.
        writePush (> 1 { sym) ; (> 2 { sym)        NB. דחיפת כתובת הבסיס של המערך
    else.
        writePush 'local' ; 0
    end.
    writeArithmetic 'add'                           NB. חישוב כתובת היעד הסופית (בסיס + אינדקס)
    writePop 'temp' ; 1                             NB. שמירת הכתובת הזו באופן זמני ב-temp 1
  end.
  
  advanceToken''                                    NB. דילוג על הסימן '='
  compileExpression''                               NB. הידור הביטוי בצד ימין (הערך להשמה)
  advanceToken''                                    NB. דילוג על ';'
  
  NB. סנכרון ושמירת הערך במיקום הנכון
  if. isArray do.
    writePop 'temp' ; 0                             NB. שמירת תוצאת הביטוי ב-temp 0
    writePush 'temp' ; 1                            NB. החזרת כתובת היעד המחושבת
    writePop 'pointer' ; 1                          NB. הגדרת THAT שיצביע לכתובת היעד
    writePush 'temp' ; 0                            NB. החזרת הערך של הביטוי
    writePop 'that' ; 0                             NB. השמה לתוך המערך באמצעות that 0
  else.
    NB. השמה רגילה למשתנה פשוט
    sym =. lookupSymbol varName
    if. # sym do.
        writePop (> 1 { sym) ; (> 2 { sym)
    else.
        writePop 'local' ; 0
    end.
  end.
  EMPTY
)

NB. הידור לולאת while
compileWhile =: 3 : 0
  l1 =. getNewLabel''                               NB. תווית לתחילת הלולאה (בדיקת התנאי)
  l2 =. getNewLabel''                               NB. תווית ליציאה מהלולאה
  
  writeLabel l1
  advanceToken''                                    NB. דילוג על 'while'
  advanceToken''                                    NB. דילוג על '('
  compileExpression''                               NB. הידור ביטוי התנאי
  advanceToken''                                    NB. דילוג על ')'
  writeArithmetic 'not'                             NB. היפוך התוצאה (אם התנאי שקר - נצא)
  writeIf l2                                        NB. קפיצה לסוף הלולאה אם התנאי התברר כשקרי
  advanceToken''                                    NB. דילוג על '{'
  compileStatements''                               NB. גוף הלולאה
  advanceToken''                                    NB. דילוג על '}'
  writeGoto l1                                      NB. חזרה לבדיקת התנאי מחדש
  writeLabel l2                                     NB. נקודת היציאה מהלולאה
  EMPTY
)

NB. הידור פקודת החזרה (return;)
compileReturn =: 3 : 0
  advanceToken''                                    NB. דילוג על 'return'
  if. checkValue ';' do.
    writePush 'constant' ; 0                        NB. שפת Jack מחייבת שכל פונקציית void תחזיר 0 כברירת מחדל
  else.
    compileExpression''                             NB. הידור הביטוי שיוחזר
  end.
  advanceToken''                                    NB. דילוג על ';'
  writeReturn ''
  EMPTY
)

NB. הידור פקודת תנאי (if / else)
compileIf =: 3 : 0
  l1 =. getNewLabel''                               NB. תווית למקרה שהתנאי שקרי (דילוג ל-else או לסוף)
  l2 =. getNewLabel''                               NB. תווית לסוף משפט ה-if כולו
  
  advanceToken''                                    NB. דילוג על 'if'
  advanceToken''                                    NB. דילוג על '('
  compileExpression''                               NB. הידור ביטוי התנאי
  advanceToken''                                    NB. דילוג על ')'
  writeArithmetic 'not'                             NB. היפוך התוצאה
  writeIf l1                                        NB. אם התנאי לא מתקיים, דלג לבלוק ה-else / סוף
  advanceToken''                                    NB. דילוג על '{'
  compileStatements''                               NB. גוף ה-if (בלוק האמת)
  advanceToken''                                    NB. דילוג על '}'
  
  NB. טיפול במקרה שיש בלוק 'else' אופציונלי
  if. checkValue 'else' do.
    l3 =. getNewLabel''
    writeGoto l3                                    NB. אם נכנסנו לאמת, נדלג על השקר לסוף
    writeLabel l1                                   NB. תווית תחילת ה-else
    advanceToken''                                  NB. דילוג על 'else'
    advanceToken''                                  NB. דילוג על '{'
    compileStatements''                             NB. גוף ה-else
    advanceToken''                                  NB. דילוג על '}'
    writeLabel l3
  else.
    writeLabel l1                                   NB. אם אין else, פשוט מגיעים לפה כשהתנאי שקרי
  end.
  EMPTY
)

NB. הידור ביטויים (Expressions) המכילים איברים ואופרטורים (למשל x + y - z)
compileExpression =: 3 : 0
  compileTerm''                                     NB. הידור האיבר הראשון (Term)
  ops =. '+-*/&|<>='                                NB. רשימת האופרטורים המוכרים
  while. tokenIdx < # tokensList do.
    isOp =. 0
    if. (getCurrentType'') -: 'symbol' do.
      if. (getCurrentValue'') e. ops do. isOp =. 1 end.
    end.
    
    if. isOp = 0 do. break. end.                    NB. נעצר אם האסימון הבא אינו אופרטור
    
    op =. getCurrentValue''
    advanceToken''
    compileTerm''                                   NB. הידור האיבר הבא (הימני)
    
    NB. תרגום האופרטור של Jack לפקודת ה-VM המתאימה או קריאה לפונקציות מערכת של ה-OS
    if. op -: '+' do. writeArithmetic 'add'
    elseif. op -: '-' do. writeArithmetic 'sub'
    elseif. op -: '*' do. writeCall 'Math.multiply' ; 2
    elseif. op -: '/' do. writeCall 'Math.divide' ; 2
    elseif. op -: '&' do. writeArithmetic 'and'
    elseif. op -: '|' do. writeArithmetic 'or'
    elseif. op -: '<' do. writeArithmetic 'lt'
    elseif. op -: '>' do. writeArithmetic 'gt'
    elseif. op -: '=' do. writeArithmetic 'eq' end.
  end.
  EMPTY
)

NB. הידור איבר בודד (Term) - יכול להיות מספר, מחרוזת, משתנה, קריאה לפונקציה, ביטוי בסוגריים או אופרטור אונרי
compileTerm =: 3 : 0
  type =. getCurrentType''
  val =. getCurrentValue''
  
  NB. קבוע מספרי (Integer)
  if. type -: 'integerConstant' do.
    writePush 'constant' ; ". val
    advanceToken''
    
  NB. קבוע מחרוזתי (String) - מומר לקריאות String.new ו-String.appendChar
  elseif. type -: 'stringConstant' do.
    len =. # val
    writePush 'constant' ; len
    writeCall 'String.new' ; 1
    for_i. i. len do.
      writePush 'constant' ; a. i. (i { val)        NB. המרת התו לקוד האסקי שלו
      writeCall 'String.appendChar' ; 2
    end.
    advanceToken''
    
  NB. מילות מפתח מיוחדות (true, false, null, this)
  elseif. type -: 'keyword' do.
    if. val -: 'true' do. 
      writePush 'constant' ; 0 
      writeArithmetic 'not'                        NB. בשפת Jack האמת מיוצגת ע"י 1- (not 0)
    elseif. (val -: 'false') +. (val -: 'null') do. 
      writePush 'constant' ; 0
    elseif. val -: 'this' do. 
      writePush 'pointer' ; 0 
    end.
    advanceToken''
    
  NB. מזהה (Identifier) - יכול להיות משתנה פשוט, מערך או קריאה לפונקציה
  elseif. type -: 'identifier' do.
    nextSym =. lookAheadValue 1
    
    NB. גישה למערך: varName[expression]
    if. nextSym -: '[' do. 
      advanceToken'' 
      advanceToken'' NB. [
      compileExpression''
      advanceToken'' NB. ]
      sym =. lookupSymbol val
      if. # sym do.
          writePush (> 1 { sym) ; (> 2 { sym)
      else.
          writePush 'local' ; 0
      end.
      writeArithmetic 'add'                         NB. חישוב הכתובת באפקט דומה ל-Let
      writePop 'pointer' ; 1                        NB. מכוונים את THAT לתוצאה
      writePush 'that' ; 0                          NB. דוחפים את הערך שנמצא בכתובת הזו
      
    NB. קריאה לתת-שגרה (מתודה או פונקציה)
    elseif. (nextSym -: '.') +. (nextSym -: '(') do.
      compileSubroutineCall''
      
    NB. משתנה רגיל ופשוט
    else.
      sym =. lookupSymbol val
      if. # sym do.
          writePush (> 1 { sym) ; (> 2 { sym)
      else.
          writePush 'local' ; 0
      end.
      advanceToken''
    end.
    
  NB. ביטוי מקונן בתוך סוגריים (expression)
  elseif. val -: '(' do.
    advanceToken''
    compileExpression''
    advanceToken''
    
  NB. אופרטורים אונריים (מינוס - או שלילה לוגית ~)
  elseif. (val -: '-') +. (val -: '~') do.
    advanceToken''
    compileTerm''
    if. val -: '-' do. writeArithmetic 'neg' else. writeArithmetic 'not' end.
  else.
    advanceToken'' 
  end.
  EMPTY
)

NB. הידור קריאה לפונקציות ומתודות (למשל: Output.printInt(x) או print(x))
compileSubroutineCall =: 3 : 0
  name1 =. getCurrentValue''
  advanceToken'' 
  
  nArgs =. 0
  callName =. ''
  
  NB. קריאה חיצונית המכילה נקודה (למשל: Math.multiply או square.draw)
  if. checkValue '.' do.
    advanceToken'' NB. .
    name2 =. getCurrentValue''
    advanceToken'' 
    
    sym =. lookupSymbol name1
    if. 0 = # sym do.
      NB. מקרה א': קריאה לפונקציה סטטית של מחלקה אחרת (למשל Screen.drawCircle)
      callName =. name1 , '.' , name2
    else.
      NB. מקרה ב': קריאת מתודה על אובייקט קיים (למשל game.run). נדרש להעביר את האובייקט כארגומנט הראשון
      callName =. (> 0 { sym) , '.' , name2
      writePush (> 1 { sym) ; (> 2 { sym)
      nArgs =. 1
    end.
  else.
    NB. קריאה פנימית למתודה של אותה מחלקה (למשל draw()). מעבירים את this (pointer 0) כארגומנט ראשון
    callName =. className , '.' , name1
    writePush 'pointer' ; 0
    nArgs =. 1
  end.
  
  advanceToken''                                    NB. דילוג על '('
  nArgs =. nArgs + compileExpressionList''          NB. הידור הארגומנטים וספירתם
  advanceToken''                                    NB. דילוג על ')'
  
  writeCall callName ; nArgs                         NB. כתיבת פקודת הקריאה ב-VM
  EMPTY
)

NB. הידור רשימת ביטויים המופרדים בפסיקים בתוך סוגריים של קריאה לפונקציה, ומחזיר את כמותם
compileExpressionList =: 3 : 0
  count =. 0
  if. -. checkValue ')' do.
    compileExpression''
    count =. 1
    while. tokenIdx < # tokensList do.
      if. checkValue ',' do.
        advanceToken'' 
        compileExpression''
        count =. count + 1
      else. break. end.
    end.
  end.
  count                                             NB. החזרת מספר הארגומנטים שנוצרו
)

NB. הידור של קובץ .jack בודד - מפעיל את הטוקנייזר, פותח קובץ VM חדש, ומריץ את ה-Parser
compileSingleFile =: 3 : 0
  targetFile =. y
  processTokenizer targetFile                      NB. שלב אסימונים
  
  vmFile =: ((- # '.jack') }. targetFile) , '.vm'   NB. קביעת שם קובץ הפלט (החלפת סיומת ל-.vm)
  '' fwrite vmFile                                  NB. יצירת קובץ ריק או דריסת קיים
  
  tokenIdx =: 0
  labelCounter =: 0
  compileClass''                                    NB. תחילת הניתוח וההידור
  
  echo 'Generated VM for: ' , vmFile
  EMPTY
)

NB. טעינת ה-Tokenizer
load 'C:\Users\User\j9.6-user\temp\tar4_jack_tokenizer.ijs'

NB. =========================================================================
NB. חלק ב': המנתח התחבירי (Parser) 
NB. =========================================================================

NB. משתני מצב גלובליים לניהול המיקום הנוכחי ורמת ההזחה ב-XML
tokenIdx =: 0
indentLevel =: 0

NB. הגדרת קבוצות עבודה מראש למניעת שרשראות ארוכות של תנאי
STATEMENT_KEYWORDS =: 'let' ; 'do' ; 'if' ; 'while' ; 'return'
CLASS_VAR_KEYWORDS =: 'static' ; 'field'
SUBROUTINE_KEYWORDS =: 'constructor' ; 'function' ; 'method'
OP_SYMBOLS =: '+' ; '-' ; '*' ; '/' ; '&' ; '|' ; '<' ; '>' ; '='

NB. אתחול מחדש של מצב ה-Parser עבור הרצה על קובץ חדש
initParser =: 3 : 0
  tokenIdx =: 0
  indentLevel =: 0
  EMPTY
)

NB. שליפת סוג הטוקן (העמודה הראשונה במטריצה) מתוך המיקום הנוכחי
getCurrentType =: 3 : 0
  if. tokenIdx < # tokensList do. > 0 { tokenIdx { tokensList else. '' end.
)

NB. שליפת ערך הטוקן המילולי (העמודה השנייה במטריצה) מתוך המיקום הנוכחי
getCurrentValue =: 3 : 0
  if. tokenIdx < # tokensList do. > 1 { tokenIdx { tokensList else. '' end.
)

NB. קידום מצביע הקלט בצורה אימפרטיבית לטוקן הבא בתור
advanceToken =: 3 : 0
  tokenIdx =: tokenIdx + 1
  EMPTY
)

NB. יצירת מחרוזת רווחים דינמית בהתאם לעומק העץ התחבירי הנוכחי
getIndent =: 3 : 0
  (indentLevel * 2) $ ' '
)

NB. כתיבת תגית XML פותחת והעלאת רמת המדרג (Indentation)
openTag =: 3 : 0
  xmlLine =. (getIndent'') , '<' , y , '>' , LF
  xmlLine fappend parsedFile
  indentLevel =: indentLevel + 1
  EMPTY
)

NB. הורדת רמת המדרג (Indentation) וכתיבת תגית XML סוגרת
closeTag =: 3 : 0
  indentLevel =: indentLevel - 1
  xmlLine =. (getIndent'') , '</' , y , '>' , LF
  xmlLine fappend parsedFile
  EMPTY
)

NB. כתיבת אלמנט טרמינלי (עלה בעץ) לקובץ וקידום המצביע, כולל אסקייפ לתווי XML רגישים
writeTerminal =: 3 : 0
  type =. getCurrentType''
  val =. getCurrentValue''
  if. 0 = # type do. EMPTY return. end.
  
  displayVal =. val
  if. type -: 'symbol' do.
    if. val -: '<' do. displayVal =. '&lt;'
    elseif. val -: '>' do. displayVal =. '&gt;'
    elseif. val -: '"' do. displayVal =. '&quot;'
    elseif. val -: '&' do. displayVal =. '&amp;'
    end.
  end.
  
  xmlLine =. (getIndent'') , '<' , type , '> ' , displayVal , ' </' , type , '>' , LF
  xmlLine fappend parsedFile
  advanceToken''
  EMPTY
)

NB. בדיקת התאמה (Match) של ערך הטוקן הנוכחי ללא קידום המצביע
checkValue =: 3 : 0
  if. tokenIdx < # tokensList do. (getCurrentValue'') -: y else. 0 end.
)

NB. פונקציית הצצה קדימה (Lookahead) לבחינת טוקנים עתידיים ברשימה לפי היסט (Offset)
lookAheadValue =: 3 : 0
  targetIdx =. tokenIdx + y
  if. targetIdx < # tokensList do. > 1 { targetIdx { tokensList else. '' end.
)

NB. גזירת קריאה לתת-שגרה (מתודה או פונקציה) כולל טיפול בנקודה מפרידה במידת הצורך
compileSubroutineCall =: 3 : 0
  writeTerminal''  
  if. checkValue '.' do.
    writeTerminal''  
    writeTerminal''  
  end.
  writeTerminal''  
  compileExpressionList''
  writeTerminal''  
  EMPTY
)

NB. נקודת הכניסה הראשית לקובץ - גזירת מבנה ה-Class הראשי
compileClass =: 3 : 0
  openTag 'class'
  writeTerminal'' 
  writeTerminal'' 
  writeTerminal'' 
  
  NB. איסוף בלוקים של משתני מחלקה (field / static) בלולאה רציפה
  while. tokenIdx < # tokensList do.
    if. (<getCurrentValue'') e. CLASS_VAR_KEYWORDS do. compileClassVarDec'' else. break. end.
  end.
  
  NB. איסוף פונקציות, מתודות ובנאים של המחלקה
  while. tokenIdx < # tokensList do.
    if. (<getCurrentValue'') e. SUBROUTINE_KEYWORDS do. compileSubroutineDec'' else. break. end.
  end.
  
  writeTerminal'' 
  closeTag 'class'
  EMPTY
)

NB. גזירת הכרזות על משתני מחלקה, כולל תמיכה ברשימת משתנים המופרדים בפסיק
compileClassVarDec =: 3 : 0
  openTag 'classVarDec'
  writeTerminal''  
  writeTerminal''  
  writeTerminal''  
  
  while. checkValue ',' do.
    writeTerminal''  
    writeTerminal''  
  end.
  
  writeTerminal''  
  closeTag 'classVarDec'
  EMPTY
)

NB. גזירת חתימת תת-שגרה (פונקציה/מתודה) וקישור לרשימת הפרמטרים והגוף
compileSubroutineDec =: 3 : 0
  openTag 'subroutineDec'
  writeTerminal''  
  writeTerminal''  
  writeTerminal''  
  writeTerminal''  
  
  compileParameterList''
  writeTerminal''  
  
  compileSubroutineBody''
  closeTag 'subroutineDec'
  EMPTY
)

NB. גזירת רשימת הפרמטרים בחתימת הפונקציה עד להגעה לסוגר הימני
compileParameterList =: 3 : 0
  openTag 'parameterList'
  while. (checkValue ')') = 0 do.
    writeTerminal''
  end.
  closeTag 'parameterList'
  EMPTY
)

NB. גזירת גוף הפונקציה הכולל הצהרת משתנים מקומיים (var) ולאחריהם פקודות
compileSubroutineBody =: 3 : 0
  openTag 'subroutineBody'
  writeTerminal''  
  
  while. checkValue 'var' do.
    compileVarDec''
  end.
  
  compileStatements''
  writeTerminal''  
  closeTag 'subroutineBody'
  EMPTY
)

NB. גזירת שורת הכרזת משתנים מקומיים המסתיימת בנקודה-פסיק
compileVarDec =: 3 : 0
  openTag 'varDec'
  writeTerminal''  
  writeTerminal''  
  writeTerminal''  
  
  while. (checkValue ';') = 0 do.
    writeTerminal''
  end.
  
  writeTerminal''  
  closeTag 'varDec'
  EMPTY
)

NB. ניתוח וניתוב בלוק של פקודות (Statements) על בסיס מילות מפתח מוגדרות מראש
compileStatements =: 3 : 0
  openTag 'statements'
  
  while. tokenIdx < # tokensList do.
    currentVal =. getCurrentValue''
    if. (<currentVal) e. STATEMENT_KEYWORDS do.
      if. currentVal -: 'let' do. compileLet''
      elseif. currentVal -: 'do' do. compileDo''
      elseif. currentVal -: 'return' do. compileReturn''
      elseif. currentVal -: 'while' do. compileWhile''
      elseif. currentVal -: 'if' do. compileIf''
      end.
    else.
      break.
    end.
  end.
  
  closeTag 'statements'
  EMPTY
)

NB. גזירת פקודת השמה (let), כולל טיפול אופציונלי בגישה לאינדקס של מערך [ ]
compileLet =: 3 : 0
  openTag 'letStatement'
  writeTerminal''  
  writeTerminal''  
  
  if. checkValue '[' do.
    writeTerminal''  
    compileExpression''
    writeTerminal''  
  end.
  
  writeTerminal''  
  compileExpression''
  writeTerminal''  
  closeTag 'letStatement'
  EMPTY
)

NB. גזירת פקודת הפעלה (do) המפעילה קריאה לתת-שגרה
compileDo =: 3 : 0
  openTag 'doStatement'
  writeTerminal''  
  compileSubroutineCall''
  writeTerminal''  
  closeTag 'doStatement'
  EMPTY
)

NB. גזירת פקודת החזרה (return), תומך בהחזרת ערך/ביטוי או החזרה ריקה (void)
compileReturn =: 3 : 0
  openTag 'returnStatement'
  writeTerminal''  
  
  if. (checkValue ';') = 0 do.
    compileExpression''
  end.
  
  writeTerminal''  
  closeTag 'returnStatement'
  EMPTY
)

NB. גזירת לולאת תנאי (while) הכוללת ביטוי בתוך סוגריים ובלוק פקודות תחום בסוגריים מסולסלים
compileWhile =: 3 : 0
  openTag 'whileStatement'
  writeTerminal''  
  writeTerminal''  
  compileExpression''
  writeTerminal''  
  writeTerminal''  
  
  compileStatements''
  writeTerminal''  
  closeTag 'whileStatement'
  EMPTY
)

NB. גזירת פקודת תנאי (if), כולל תמיכה אופציונלית בנתיב חלופי (else)
compileIf =: 3 : 0
  openTag 'ifStatement'
  writeTerminal''  
  writeTerminal''  
  compileExpression''
  writeTerminal''  
  writeTerminal''  
  
  compileStatements''
  writeTerminal''  
  
  if. checkValue 'else' do.
    writeTerminal''  
    writeTerminal''  
    compileStatements''
    writeTerminal''  
  end.
  
  closeTag 'ifStatement'
  EMPTY
)

NB. גזירת ביטוי (Expression) המורכב מאיבר בסיס (term) ורצף אופציונלי של אופרטורים ואיברים נוספים
compileExpression =: 3 : 0
  openTag 'expression'
  compileTerm''
  
  while. tokenIdx < # tokensList do.
    if. (<getCurrentValue'') e. OP_SYMBOLS do.
      writeTerminal''  
      compileTerm''
    else.
      break.
    end.
  end.
  
  closeTag 'expression'
  EMPTY
)

NB. גזירת איבר בסיס (Term). דורש Lookahead של תו אחד קדימה כדי להבחין בין סוגי מזהים שונים
compileTerm =: 3 : 0
  openTag 'term'
  type =. getCurrentType''
  val =. getCurrentValue''
  
  NB. מקרה א': ביטוי שלם התחום בסוגריים (expression)
  if. checkValue '(' do.
    writeTerminal''  
    compileExpression''
    writeTerminal''  
    
  NB. מקרה ב': אופרטור אונארי (- או ~) המקדים איבר
  elseif. (val -: '-') +. (val -: '~') do.
    writeTerminal''  
    compileTerm''
    
  NB. מקרה ג': טיפול במזהה (Identifier) - דורש הצצה קדימה לזיהוי מערך או קריאת פונקציה
  elseif. type -: 'identifier' do.
    nextVal =. lookAheadValue 1
    
    if. nextVal -: '[' do.
      NB. גישה לאיבר במערך
      writeTerminal''  
      writeTerminal''  
      compileExpression''
      writeTerminal''  
    elseif. (nextVal -: '(') +. (nextVal -: '.') do.
      NB. קריאה למתודה או פונקציה סטטית
      compileSubroutineCall''
    else.
      NB. שם משתנה פשוט
      writeTerminal''  
    end.
    
  NB. מקרה ד': קבועים (מספר, מחרוזת, מילים שמורות כמו true/false/this)
  else.
    writeTerminal''  
  end.
  
  closeTag 'term'
  EMPTY
)

NB. גזירת רשימת ביטויים (כגון ארגומנטים הנשלחים לפונקציה) המופרדים בפסיקים
compileExpressionList =: 3 : 0
  openTag 'expressionList'
  
  if. (checkValue ')') = 0 do.
    compileExpression''
    
    while. checkValue ',' do.
      writeTerminal''  
      compileExpression''
    end.
  end.
  
  closeTag 'expressionList'
  EMPTY
)

NB. =========================================================================
NB. פונקציית עזר לעיבוד קובץ בודד
NB. =========================================================================
compileSingleFile =: 3 : 0
  targetFile =. y
  
  NB. הפעלת ה-Tokenizer
  processTokenizer targetFile
  
  NB. בניית שם קובץ הפלט (החלפת .jack ב- .xml)
  parsedFile =: ((- # '.jack') }. targetFile) , '.xml'
  '' fwrite parsedFile
  
  NB. הפעלת ה-Parser הרקורסיבי
  initParser''
  compileClass''
  
  echo 'Generated XML for: ' , parsedFile
  EMPTY
)

NB. =========================================================================
NB. הפונקציה הראשית: JackAnalyzer
NB. =========================================================================
JackAnalyzer =: 3 : 0
  source =. y
  
  NB. בדיקה האם המקור שקיבלנו הוא קובץ ג'אק בודד
  if. '.jack' -: _5 {. source do.
    compileSingleFile source
  else.
    NB. אם זו תיקייה - נדאג שהיא מסתיימת בלוכסן אחד ויחיד
    folder =. source
    if. '\' -.@:-: _1 {. folder do. folder =. folder , '\' end.
    
    
    searchPattern =. folder , '*.jack'
    jackFiles =. 1 dir searchPattern
    
    if. 0 = # jackFiles do.
      echo 'Error: No .jack files found in directory: ' , folder
      EMPTY return.
    end.
    
    NB. לולאת ריצה על כל הקבצים שנמצאו בצורה דינמית 
    for_file_path. jackFiles do.
      fullPath =. > file_path
      compileSingleFile fullPath
    end.
  end.
  echo '=== ANALYSIS COMPLETED SUCCESSFULLY ==='
  EMPTY
)
NB.===========================
NB. קריאות להרצה, כל פעם לתיקיה אחרת
NB.==========================
JackAnalyzer 'C:\Users\User\nand2tetris\nand2tetris\projects\10\Square'
NB.JackAnalyzer 'C:\Users\User\nand2tetris\nand2tetris\projects\10\ArrayTest'
NB.JackAnalyzer 'C:\Users\User\nand2tetris\nand2tetris\projects\10\ExpressionlessSquare'

load 'files'
load 'dir'

NB. =========================================================================
NB. חלק א': הגדרות וקבועים עבור שפת Jack (ה-Tokenizer)
NB. =========================================================================

NB. הגדרת רשימות המילים השמורות והסימנים כמערכי תאים (Boxed arrays)
KEYWORDS =: 'class' ; 'constructor' ; 'function' ; 'method' ; 'field' ; 'static' ; 'var'
KEYWORDS =: KEYWORDS , 'int' ; 'char' ; 'boolean' ; 'void' ; 'true' ; 'false' ; 'null' ; 'this'
KEYWORDS =: KEYWORDS , 'let' ; 'do' ; 'if' ; 'else' ; 'while' ; 'return'

SYMBOLS =: '{'; '}'; '('; ')'; '['; ']'; '.'; ','; ';'; '+'; '-'; '*'; '/'; '&'; '|'; '<'; '>'; '='; '~'

NB. יצירת טווחים וקבוצות תווים מתוך טבלת ASCII באמצעות אריתמטיקה של מערכים
DIGITS =: (48 + i.10) { a.
LETTERS =: ((65 + i.26) { a.) , ((97 + i.26) { a.) , '_'
ALPHANUMERIC =: LETTERS , DIGITS

NB. פונקציות עזר (Verbs) בסיסיות לבדיקת שייכות קבוצתית (Membership)
isSymbol =: 3 : 'y e. SYMBOLS'
isDigit =: 3 : 'y e. DIGITS'
isLetter =: 3 : 'y e. LETTERS'
isAlphaNumeric =: 3 : 'y e. ALPHANUMERIC'
isKeyword =: 3 : 'y e. KEYWORDS'

NB. המרת תווים מיוחדים לייצוג ישויות XML תקין למניעת שגיאות פורמט
escapeXmlSymbol =: 3 : 0
  if. y -: '<' do. '&lt;'
  elseif. y -: '>' do. '&gt;'
  elseif. y -: '"' do. '&quot;'
  elseif. y -: '&' do. '&amp;'
  elseif. do. y
  end.
)

NB. ניקוי הערות שורה (//) והערות בלוק (/* */) ממחרוזת הקוד הגולמית
removeComments =: 3 : 0
  txt =. y
  res =. ''
  i =. 0
  while. i < # txt do.
    remainder =. i }. txt
    
    NB. זיהוי תחילת הערת בלוק וחיתוך עד לסגירתה
    if. '/*' -: 2 {. remainder do.
      matchIdx =. ('*/' E. remainder) i. 1
      if. matchIdx = # remainder do. i =. # txt else. i =. i + matchIdx + 2 end.
      continue.
    end.
    
    NB. זיהוי הערת שורה וחיתוך עד לתו ירידת השורה (LF)
    if. '//' -: 2 {. remainder do.
      endLine =. remainder i. LF
      if. endLine = # remainder do. i =. # txt else. i =. i + endLine end.
      continue.
    end.
    
    NB. שמירת תווים שאינם חלק מהערה
    res =. res , i { txt
    i =. i + 1
  end.
  res
)

NB. הפונקציה המרכזית לניתוח הלקסיקלי ויצירת רשימת הטוקנים
processTokenizer =: 3 : 0
  NB. אתחול מטריצה גלובלית דו-ממדית ריקה (0 שורות, 2 עמודות) לאחסון זוגות [סוג, ערך]
  tokensList =: 0 2 $ <''  
  
  NB. גזירת נתיב הקובץ ובניית שם קובץ הפלט המיועד (T.xml)
  item =. > y
  dotIndex =. item i: '.'
  basePath =. dotIndex {. item
  outputFile =. basePath , 'T.xml'
  
  NB. פתיחת קובץ פלט חדש עם תגית פתיחה ראשית
  '<tokens>' fwrite outputFile
  rawText =. freads item
  cleanText =. removeComments rawText
  
  idx =. 0
  NB. לולאת סריקה ראשית על גבי מערך התווים הנקי מהערות
  while. idx < # cleanText do.
    ch =. idx { cleanText
    boxedCh =. < ch
    
    NB. נתיב א': טיפול בסימנים (Symbols)
    if. isSymbol boxedCh do.
      escapedCh =. escapeXmlSymbol ch
      xmlLine =. LF , '  <symbol> ' , escapedCh , ' </symbol>'
      xmlLine fappend outputFile
      tokensList =: tokensList , ('symbol' ; ch)
      idx =. idx + 1
      continue.
    end.
    
    NB. נתיב ב': טיפול בקבועי מספרים שלמים (Integer Constants)
    if. isDigit ch do.
      numStr =. ''
      while. idx < # cleanText do.
        nextCh =. idx { cleanText
        if. isDigit nextCh do.
          numStr =. numStr , nextCh
          idx =. idx + 1
        else.
          break.
        end.
      end.
      xmlLine =. LF , '  <integerConstant> ' , numStr , ' </integerConstant>'
      xmlLine fappend outputFile
      tokensList =: tokensList , ('integerConstant' ; numStr)
      continue.
    end.
    
    NB. נתיב ג': טיפול במחרוזות קבועות (String Constants) התחומות במרכאות
    if. ch = '"' do.
      strText =. ''
      idx =. idx + 1
      while. idx < # cleanText do.
        nextCh =. idx { cleanText
        if. nextCh = '"' do.
          idx =. idx + 1
          break.
        else.
          strText =. strText , nextCh
          idx =. idx + 1
        end.
      end.
      xmlLine =. LF , '  <stringConstant> ' , strText , ' </stringConstant>'
      xmlLine fappend outputFile
      tokensList =: tokensList , ('stringConstant' ; strText)
      continue.
    end.
    
    NB. נתיב ד': טיפול במילים שמורות (Keywords) ובמזהים (Identifiers)
    if. isLetter ch do.
      wordStr =. ''
      while. idx < # cleanText do.
        nextCh =. idx { cleanText
        if. isAlphaNumeric nextCh do.
          wordStr =. wordStr , nextCh
          idx =. idx + 1
        else.
          break.
        end.
      end.
      
      NB. פיצול לוגי בין מילה שמורה במערכת לבין שם משתנה/מחלקה של המשתמש
      if. isKeyword < wordStr do.
        xmlLine =. LF , '  <keyword> ' , wordStr , ' </keyword>'
        tokensList =: tokensList , ('keyword' ; wordStr)
      else.
        xmlLine =. LF , '  <identifier> ' , wordStr , ' </identifier>'
        tokensList =: tokensList , ('identifier' ; wordStr)
      end.
      xmlLine fappend outputFile
      continue.
    end.
    
    NB. קידום האינדקס עבור תווים שקופים (רווחים, טאבים, ירידות שורה)
    idx =. idx + 1
  end.
  
  NB. סגירת תגית ה-Tokens הראשית בסיום הקובץ
  (LF , '</tokens>' , LF) fappend outputFile
  EMPTY
)
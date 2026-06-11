
NB. =========================================================================
NB. חלק א': Tokenizer (מפרק לקסיקלי)
NB. תפקיד: לקרוא את קובץ ה-Jack, לנקות הערות, ולפרק אותו לרשימה של אסימונים (Tokens)
NB. =========================================================================

NB. הגדרת מילות המפתח והסימנים המותרים בשפת Jack
KEYWORDS =: 'class' ; 'constructor' ; 'function' ; 'method' ; 'field' ; 'static' ; 'var'
KEYWORDS =: KEYWORDS , 'int' ; 'char' ; 'boolean' ; 'void' ; 'true' ; 'false' ; 'null' ; 'this'
KEYWORDS =: KEYWORDS , 'let' ; 'do' ; 'if' ; 'else' ; 'while' ; 'return'
SYMBOLS =: '{'; '}'; '('; ')'; '['; ']'; '.'; ','; ';'; '+'; '-'; '*'; '/'; '&'; '|'; '<'; '>'; '='; '~'

NB. בניית קבוצות תווים באמצעות קוד ה-ASCII שלהם (a. הוא מערך ה-ASCII של J)
DIGITS =: (48 + i.10) { a.                         
LETTERS =: ((65 + i.26) { a.) , ((97 + i.26) { a.) , '_' 
ALPHANUMERIC =: LETTERS , DIGITS                    

NB. פונקציות עזר (פרדיקטים) לבדיקת סוג התו
isSymbol =: 3 : 'y e. SYMBOLS'                     NB. האם התו הוא סימן?
isDigit =: 3 : 'y e. DIGITS'                       NB. האם התו הוא ספרה?
isLetter =: 3 : 'y e. LETTERS'                     NB. האם התו הוא אות?
isAlphaNumeric =: 3 : 'y e. ALPHANUMERIC'           NB. האם התו הוא אלפא-נומרי?
isKeyword =: 3 : 'y e. KEYWORDS'                   NB. האם המילה היא מילת מפתח?

NB. פונקציה להסרת הערות מהטקסט
removeComments =: 3 : 0
  txt =. y                                          NB. הטקסט המקורי
  res =. ''                                         NB. הטקסט הנקי שיחזור
  i =. 0
  while. i < # txt do.
    remainder =. i }. txt                           NB. הטקסט שנותר מהאינדקס הנוכחי ואילך
    
    NB. בדיקה והסרה של הערת בלוק /* ... */
    if. '/*' -: 2 {. remainder do.
      matchIdx =. ('*/' E. remainder) i. 1          NB. מציאת סגירת ההערה
      if. matchIdx = # remainder do. i =. # txt else. i =. i + matchIdx + 2 end.
      continue.
    end.
    
    NB. בדיקה והסרה של הערת שורה //
    if. '//' -: 2 {. remainder do.
      endLine =. remainder i. LF                     NB. מציאת תו ירידת שורה
      if. endLine = # remainder do. i =. # txt else. i =. i + endLine end.
      continue.
    end.
    
    NB. אם זה לא חלק מהערה, נשמור את התו הנוכחי
    res =. res , i { txt
    i =. i + 1
  end.
  res
)

NB. פונקציית הטוקנייזר הראשית - הופכת קובץ Jack למטריצה של (סוג האסימון ; ערך האסימון)
processTokenizer =: 3 : 0
  tokensList =: 0 2 $ <''                           NB. טבלה גלובלית ריקה בת 2 עמודות עבור האסימונים
  cleanText =. removeComments freads y              NB. קריאת הקובץ והסרת הערות
  idx =. 0
  
  while. idx < # cleanText do.
    ch =. idx { cleanText
    
    NB. מקרה 1: סימנים
    if. isSymbol < ch do.
      tokensList =: tokensList , ('symbol' ; ch)
      idx =. idx + 1
      continue.
    end.
    
    NB. מקרה 2: קבועים מספריים (מספרים שלמים)
    if. isDigit ch do.
      numStr =. ''
      while. idx < # cleanText do.
        if. isDigit idx { cleanText do. numStr =. numStr , idx { cleanText
        else. break. end.
        idx =. idx + 1
      end.
      tokensList =: tokensList , ('integerConstant' ; numStr)
      continue.
    end.
    
    NB. מקרה 3: קבועים מחרוזתיים (טקסט בין מרכאות "...")
    if. ch = '"' do.
      strText =. ''
      idx =. idx + 1
      while. idx < # cleanText do.
        if. '"' = idx { cleanText do. idx =. idx + 1
        break. else. strText =. strText , idx { cleanText end.
        idx =. idx + 1
      end.
      tokensList =: tokensList , ('stringConstant' ; strText)
      continue.
    end.
    
    NB. מקרה 4: מילים (מילות מפתח או מזהים של משתנים/מחלקות)
    if. isLetter ch do.
      wordStr =. ''
      while. idx < # cleanText do.
        if. isAlphaNumeric idx { cleanText do. wordStr =. wordStr , idx { cleanText
        else. break. end.
        idx =. idx + 1
      end.
      if. isKeyword < wordStr do. tokensList =: tokensList , ('keyword' ; wordStr)
      else. tokensList =: tokensList , ('identifier' ; wordStr) end.
      continue.
    end.
    
    NB. דילוג על רווחים לבנים (רווח, טאב, ירידת שורה וכו')
    idx =. idx + 1
  end.
  EMPTY
)
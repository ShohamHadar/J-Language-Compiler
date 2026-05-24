load 'files'
load 'dir'

NB. =========================================================================
NB. הגדרות וקבועים עבור שפת Jack
NB. =========================================================================

NB. רשימת המילים השמורות בשפה [cite: 13]
KEYWORDS =: 'class' ; 'constructor' ; 'function' ; 'method' ; 'field' ; 'static' ; 'var'
KEYWORDS =: KEYWORDS , 'int' ; 'char' ; 'boolean' ; 'void' ; 'true' ; 'false' ; 'null' ; 'this'
KEYWORDS =: KEYWORDS , 'let' ; 'do' ; 'if' ; 'else' ; 'while' ; 'return'

NB. רשימת הסימנים המוכרים (תו אחר תו) [cite: 13]
SYMBOLS =: '{'; '}'; '('; ')'; '['; ']'; '.'; ','; ';'; '+'; '-'; '*'; '/'; '&'; '|'; '<'; '>'; '='; '~'

NB. קבוצה של כל הספרות מ-'0' עד '9'
DIGITS =: (48 + i.10) { a.

NB. קבוצה של כל האותיות (קטנות וגדולות) וקו תחתון [cite: 16]
LETTERS =: ((65 + i.26) { a.) , ((97 + i.26) { a.) , '_'

NB. קבוצה המשלבת אותיות, מספרים וקו תחתון (עבור המשך של מילה) [cite: 16]
ALPHANUMERIC =: LETTERS , DIGITS


NB. =========================================================================
NB. נתיבים לקבצי הבדיקה [cite: 21]
NB. =========================================================================
searchPattern =: 'C:\Users\ASUS\Desktop\nand2tetris\projects\10\ArrayTest\*.jack'
jackFiles =: 1 dir searchPattern


NB. =========================================================================
NB. פונקציות עזר לניקוי ועיבוד ראשוני של הטקסט
NB. =========================================================================

isSymbol =: 3 : 'y e. SYMBOLS'

isDigit =: 3 : 'y e. DIGITS'

NB. בודקת האם תו בודד יכול להתחיל מילה (אות או מקף תחתון) [cite: 16]
isLetter =: 3 : 'y e. LETTERS'

NB. בודקת האם תו יכול להיות המשך של מילה (אות, ספרה או מקף תחתון) [cite: 16]
isAlphaNumeric =: 3 : 'y e. ALPHANUMERIC'

NB. בודקת האם המילה שצברנו היא מילה שמורה בשפה
isKeyword =: 3 : 'y e. KEYWORDS'

escapeXmlSymbol =: 3 : 0
  if. y -: '<' do. '&lt;'
  elseif. y -: '>' do. '&gt;'
  elseif. y -: '"' do. '&quot;'
  elseif. y -: '&' do. '&amp;'
  elseif. do. y
  end.
)

removeComments =: 3 : 0
  txt =. y
  res =. ''
  i =. 0
  
  while. i < # txt do.
    remainder =. i }. txt
    
    if. '/*' -: 2 {. remainder do.
      matchIdx =. ('*/' E. remainder) i. 1
      if. matchIdx = # remainder do.
        i =. # txt
      else.
        i =. i + matchIdx + 2
      end.
      continue.
    end.
    
    if. '//' -: 2 {. remainder do.
      endLine =. remainder i. LF
      if. endLine = # remainder do.
        i =. # txt
      else.
        i =. i + endLine
      end.
      continue.
    end.
    
    res =. res , i { txt
    i =. i + 1
  end.
  
  res
)


NB. =========================================================================
NB. מנוע העיבוד הראשי - מעבר קובץ קובץ [cite: 8]
NB. =========================================================================
processTokenizer =: 3 : 0
  for_file_path. y do.
    item =. > file_path
    
    dotIndex =. item i: '.'
    basePath =. dotIndex {. item
    outputFile =. basePath , 'T.xml'
    
    echo 'Processing: ' , item , ' -> ' , outputFile
    
    '<tokens>' fwrite outputFile
    
    rawText =. freads item
    cleanText =. removeComments rawText
    
    idx =. 0
    while. idx < # cleanText do.
      ch =. idx { cleanText
      boxedCh =. < ch
      
      NB. 1. טיפול בסימבולים
      if. isSymbol boxedCh do.
        escapedCh =. escapeXmlSymbol ch
        xmlLine =. LF , '  <symbol> ' , escapedCh , ' </symbol>'
        xmlLine fappend outputFile
        idx =. idx + 1
        continue.
      end.
      
      NB. 2. טיפול במספרים שלמים (integerConstant)
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
        continue.
      end.
      
      NB. 3. טיפול במחרוזות (stringConstant)
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
        continue.
      end.
      
      NB. 4. הצעד הסופי: טיפול במילים (Keywords ו-Identifiers) [cite: 16]
      if. isLetter ch do.
        wordStr =. ''
        
        NB. נאסוף את כל האותיות/מספרים/קו תחתון הרצופים [cite: 16]
        while. idx < # cleanText do.
          nextCh =. idx { cleanText
          if. isAlphaNumeric nextCh do.
            wordStr =. wordStr , nextCh
            idx =. idx + 1
          else.
            break.
          end.
        end.
        
        NB. נבדוק האם המילה שצברנו היא מילה שמורה או מזהה [cite: 16]
        if. isKeyword < wordStr do.
          xmlLine =. LF , '  <keyword> ' , wordStr , ' </keyword>'
        else.
          xmlLine =. LF , '  <identifier> ' , wordStr , ' </identifier>'
        end.
        
        xmlLine fappend outputFile
        continue.
      end.
      
      NB. אם הגענו לכאן, זה תו לבן (רווח, טאב, אנטר) - פשוט מתקדמים [cite: 14]
      idx =. idx + 1
    end.
    
    (LF , '</tokens>' , LF) fappend outputFile
    
  end.
  
  echo 'Tokenizing Complete! All tokens generated successfully.'
)

NB. הרצת התהליך על קבצי ה-Jack שמצאנו [cite: 8]
processTokenizer jackFiles
load 'files'
load 'dir'

NB. =========================================================================
NB. הגדרות וקבועים עבור שפת Jack
NB. =========================================================================

KEYWORDS =: 'class' ; 'constructor' ; 'function' ; 'method' ; 'field' ; 'static' ; 'var'
KEYWORDS =: KEYWORDS , 'int' ; 'char' ; 'boolean' ; 'void' ; 'true' ; 'false' ; 'null' ; 'this'
KEYWORDS =: KEYWORDS , 'let' ; 'do' ; 'if' ; 'else' ; 'while' ; 'return'

SYMBOLS =: '{'; '}'; '('; ')'; '['; ']'; '.'; ','; ';'; '+'; '-'; '*'; '/'; '&'; '|'; '<'; '>'; '='; '~'

DIGITS =: (48 + i.10) { a.
LETTERS =: ((65 + i.26) { a.) , ((97 + i.26) { a.) , '_'
ALPHANUMERIC =: LETTERS , DIGITS

searchPattern =: 'C:\Users\User\nand2tetris\nand2tetris\projects\10\ArrayTest\*.jack'
jackFiles =: 1 dir searchPattern

isSymbol =: 3 : 'y e. SYMBOLS'
isDigit =: 3 : 'y e. DIGITS'
isLetter =: 3 : 'y e. LETTERS'
isAlphaNumeric =: 3 : 'y e. ALPHANUMERIC'
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
      if. matchIdx = # remainder do. i =. # txt else. i =. i + matchIdx + 2 end.
      continue.
    end.
    if. '//' -: 2 {. remainder do.
      endLine =. remainder i. LF
      if. endLine = # remainder do. i =. # txt else. i =. i + endLine end.
      continue.
    end.
    res =. res , i { txt
    i =. i + 1
  end.
  res
)

NB. =========================================================================
NB. מנוע העיבוד הראשי - מעודכן לשמירת המטריצה בזיכרון!
NB. =========================================================================
processTokenizer =: 3 : 0

  if. L. y = 0 do. y =. < y end.
  NB. יצירת/איפוס מטריצת הטוקנים הגלובלית
  tokensList =: 0 2 $ <''

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
        
        NB. שמירה למטריצה (סוג ; ערך)
        tokensList =: tokensList , ('symbol' ; ch)
        
        idx =. idx + 1
        continue.
      end.
      
      NB. 2. טיפול במספרים שלמים
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
        
        NB. שמירה למטריצה
        tokensList =: tokensList , ('integerConstant' ; numStr)
        continue.
      end.
      
      NB. 3. טיפול במחרוזות
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
        
        NB. שמירה למטריצה
        tokensList =: tokensList , ('stringConstant' ; strText)
        continue.
      end.
      
      NB. 4. טיפול במילים (Keywords ו-Identifiers)
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
      
      idx =. idx + 1
    end.
    (LF , '</tokens>' , LF) fappend outputFile
  end.
  echo 'Tokenizing Complete! All tokens generated successfully.'
)

NB. הרצה ראשונית אוטומטית
processTokenizer jackFiles
load 'C:\Users\ASUS\Desktop\principles_of_programming_languages_J\tar4part1.ijs'  NB. טעינת חלק א'



NB. =========================================================================
NB. פונקציות עזר בסיסיות לניהול המצביע והכתיבה לקובץ
NB. =========================================================================

writeLine =: 3 : 0
  spaces =. (indent * 2) $ ' '
  (LF , spaces , y) fappend outputFile
)

NB. שליפה בטוחה ב-100% לפי השיטה שעבדה לך בחלק א'
getCurrentTokenInfo =: 3 : 0
  if. pIdx >= # tokens do. '' return. end.
  row =. pIdx { tokens  NB. שליפת השורה כולה (מערך תיבות)
  > y { row            NB. פתיחת התיבה (0 לסוג, 1 לערך)
)

writeCurrentToken =: 3 : 0
  type =. getCurrentTokenInfo 0
  val =. getCurrentTokenInfo 1
  
  NB. מעקב קונסול גלוי לראות את הריצה
  echo 'Writing Token: [' , type , '] -> ' , val
  
  tagLine =. '<' , type , '> ' , val , ' </' , type , '>'
  writeLine tagLine
  
  pIdx =: pIdx + 1  NB. קידום המצביע
)

NB. =========================================================================
NB. פונקציות הניתוח התחבירי (רכיבי הדקדוק של Jack)
NB. =========================================================================

compileClassVarDec =: 3 : 0
  writeLine '<classVarDec>'
  indent =: indent + 1
  
  writeCurrentToken ''
  writeCurrentToken ''
  writeCurrentToken ''
  
  while. 1 do.
    nextVal =. getCurrentTokenInfo 1
    if. nextVal -: ',' do.
      writeCurrentToken ''  
      writeCurrentToken ''  
    else.
      break.
    end.
  end.
  
  writeCurrentToken ''  
  indent =: indent - 1
  writeLine '</classVarDec>'
)

compileParameterList =: 3 : 0
  writeLine '<parameterList>'
  indent =: indent + 1
  
  nextVal =. getCurrentTokenInfo 1
  if. nextVal -. -: ')' do.
    writeCurrentToken ''  
    writeCurrentToken ''  
    
    while. 1 do.
      nextVal =. getCurrentTokenInfo 1
      if. nextVal -: ',' do.
        writeCurrentToken ''  
        writeCurrentToken ''  
        writeCurrentToken ''  
      else.
        break.
      end.
    end.
  end.
  
  indent =: indent - 1
  writeLine '</parameterList>'
)

compileVarDec =: 3 : 0
  writeLine '<varDec>'
  indent =: indent + 1
  
  writeCurrentToken ''  NB. var
  writeCurrentToken ''  NB. type
  writeCurrentToken ''  NB. varName
  
  while. 1 do.
    nextVal =. getCurrentTokenInfo 1
    if. nextVal -: ',' do.
      writeCurrentToken ''  
      writeCurrentToken ''  
    else.
      break.
    end.
  end.
  
  writeCurrentToken ''  NB. ;
  indent =: indent - 1
  writeLine '</varDec>'
)

compileSubroutine =: 3 : 0
  echo '>>> ENTERED compileSubroutine <<<'
  writeLine '<subroutineDec>'
  indent =: indent + 1
  
  writeCurrentToken ''  NB. function
  writeCurrentToken ''  NB. void
  writeCurrentToken ''  NB. main
  writeCurrentToken ''  NB. (
  
  compileParameterList ''
  
  writeCurrentToken ''  NB. )
  
  writeLine '<subroutineBody>'
  indent =: indent + 1
  
  writeCurrentToken ''  NB. {
  
  while. 1 do.
    nextVal =. getCurrentTokenInfo 1
    echo 'Checking inside subroutine body, next token is: ' , nextVal
    if. nextVal -: 'var' do.
      compileVarDec ''
    else.
      break.
    end.
  end.
  
  indent =: indent - 1
  writeLine '</subroutineBody>'
  
  indent =: indent - 1
  writeLine '</subroutineDec>'
)

compileClass =: 3 : 0
  writeLine '<class>'
  indent =: indent + 1
  
  writeCurrentToken ''  
  writeCurrentToken ''  
  writeCurrentToken ''  
  
  while. 1 do.
    nextVal =. getCurrentTokenInfo 1
    if. (nextVal -: 'static') +. (nextVal -: 'field') do.
      compileClassVarDec ''
    else.
      break.
    end.
  end.
  
  while. 1 do.
    nextVal =. getCurrentTokenInfo 1
    echo 'Checking for subroutine, next token is: ' , nextVal
    if. (nextVal -: 'constructor') +. (nextVal -: 'function') +. (nextVal -: 'method') do.
      compileSubroutine ''
    else.
      break.
    end.
  end.
  
  writeCurrentToken ''  NB. } של ה-class
  
  indent =: indent - 1
  writeLine '</class>'
)

NB. =========================================================================
NB. פונקציית הניהול הראשית
NB. =========================================================================
parseCurrentFile =: 3 : 0
  filePath =. y
  dotIdx =. filePath i: '.'
  basePath =. dotIdx {. filePath
  outputFile =: basePath , '.xml'
  
  NB. הפעלת הפונקציה המקורית של חלק א' שמייצרת את tokensList בזיכרון
  processTokenizer filePath  
  
  NB. חיבור ישיר למטריצה שעובדת ומלאה ב-100%
  tokens =: tokensList  
  
  echo 'Total rows (tokens) in matrix: ' , ": # tokens
  
  pIdx =: 0            
  indent =: 0          
  '' fwrite outputFile  
  
  compileClass ''
  
  echo 'Parsing Step 4 Complete!'
)

NB. הרצה ישירה
firstFile =. > 0 { jackFiles , a:
parseCurrentFile firstFile

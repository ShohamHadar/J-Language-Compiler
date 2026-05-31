load 'C:\Users\User\j9.6-user\temp\tar4part1.ijs'  NB. טעינת חלק א'

NB. =========================================================================
NB. משתנים גלובליים לניהול המפרסר (Parser)
NB. =========================================================================
tokens =: 0 2 $ <''  NB. יכיל את מטריצת הטוקנים של הקובץ הנוכחי
pIdx =: 0            NB. המצביע (האינדקס) לטוקן הנוכחי שאנחנו מנתחים
indent =: 0          NB. רמת ההזחה (מספר רווחים = indent * 2)
outputFile =: ''     NB. נתיב לקובץ הפלט (למשל Main.xml)

NB. =========================================================================
NB. פונקציות עזר בסיסיות לניהול המצביע והכתיבה לקובץ
NB. =========================================================================

NB. פונקציית עזר לכתיבת שורה מוזחת לקובץ הפלט
writeLine =: 3 : 0
  spaces =. (indent * 2) $ ' '
  (LF , spaces , y) fappend outputFile
)

NB. פונקציה שכותבת את הטוקן הנוכחי ומקדמת את המצביע לטוקן הבא
writeCurrentToken =: 3 : 0
  type =. > 0 { pIdx { tokens
  val =. > 1 { pIdx { tokens
  
  NB. יצירת השורה בפורמט: <type> val </type>
  tagLine =. '<' , type , '> ' , val , ' </' , type , '>'
  writeLine tagLine
  
  pIdx =: pIdx + 1  NB. קידום המצביע ב-1
)

NB. פונקציית עזר להצצה בטוקן הנוכחי (מחזירה זוג: סוג ; ערך) בלי לקדם את המצביע
getCurrentToken =: 3 : 0
  if. pIdx >= # tokens do. ('';'') return. end.
  type =. > 0 { pIdx { tokens
  val =. > 1 { pIdx { tokens
  type ; val
)

NB. =========================================================================
NB. פונקציות הניתוח התחבירי (רכיבי הדקדוק של Jack)
NB. =========================================================================

NB. פונקציה לניתוח משתני מחלקה (static / field)
compileClassVarDec =: 3 : 0
  writeLine '<classVarDec>'
  indent =: indent + 1
  
  writeCurrentToken ''  NB. static או field
  writeCurrentToken ''  NB. סוג המשתנה (int, char, וכו')
  writeCurrentToken ''  NB. שם המשתנה הראשון
  
  NB. לולאה לטיפול במקרה שיש פסיקים (כמו: field int x, y, z;)
  while. 1 do.
    'type val' =. getCurrentToken ''
    if. val -: ',' do.
      writeCurrentToken ''  NB. כתיבת הפסיק ,
      writeCurrentToken ''  NB. כתיבת שם המשתנה הבא
    else.
      break.
    end.
  end.
  
  writeCurrentToken ''  NB. כתיבת הנקודה פסיק ;
  
  indent =: indent - 1
  writeLine '</classVarDec>'
)

NB. פונקציה לניתוח מבנה ה-Class החיצוני (כולל משתני מחלקה)
compileClass =: 3 : 0
  writeLine '<class>'
  indent =: indent + 1
  
  writeCurrentToken ''  NB. <keyword> class </keyword>
  writeCurrentToken ''  NB. <identifier> Main </identifier>
  writeCurrentToken ''  NB. <symbol> { </symbol>
  
  NB. צעד 2: בדיקה בלולאה האם יש משתני מחלקה (static או field)
  while. 1 do.
    'type val' =. getCurrentToken ''
    if. (val -: 'static') +. (val -: 'field') do.
      compileClassVarDec ''
    else.
      break.  NB. אם זה לא static ולא field, סיימנו עם משתני המחלקה ונצא מהלולאה
    end.
  end.
  
  NB. (בצעדים הבאים נכניס כאן את הניתוח של פונקציות/מתודות)
  
  indent =: indent - 1
  writeLine '</class>'
)

NB. =========================================================================
NB. פונקציית הניהול הראשית - נקודת הכניסה של חלק ב'
NB. =========================================================================
parseCurrentFile =: 3 : 0
  filePath =. y
  dotIdx =. filePath i: '.'
  basePath =. dotIdx {. filePath
  outputFile =: basePath , '.xml'  NB. קובץ הפלט של חלק ב' (Main.xml, בלי T!)
  
  echo 'Parsing: ' , filePath , ' -> ' , outputFile
  
  NB. 1. הפעלת ה-Tokenizer מחלק א' ועדכון המטריצה הגלובלית
  rawText =. freads filePath
  cleanText =. removeComments rawText
  tokens =: tokenizeText cleanText  
  
  NB. 2. איפוס המצביעים והכנת קובץ פלט נקי
  pIdx =: 0
  indent =: 0
  '' fwrite outputFile  
  
  NB. 3. תחילת הניתוח התחבירי מהרמה הגבוהה ביותר
  compileClass ''
  
  echo 'Parsing Step 2 Complete!'
)

NB. =========================================================================
NB. הרצה ניסיונית על הקובץ הראשון (Main.jack)
NB. =========================================================================
firstFile =. > 0 { jackFiles
parseCurrentFile firstFile
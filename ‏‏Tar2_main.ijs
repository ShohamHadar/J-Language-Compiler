NB.main.ijs file
load 'files'
load 'dir'
load 'C:\Users\User\j9.6-user\temp\Tar1_arithmetic.ijs'
load 'C:\Users\User\j9.6-user\temp\Tar1_memory.ijs'

NB. עדכון נתיבים לתיקיית הפרויקט החדשה
searchPattern =: 'C:\Users\User\Desktop\לימודים\עקרונות שפות תכנה\תרגול\targil1\*.vm'
outputFile =: 'C:\Users\User\Desktop\לימודים\עקרונות שפות תכנה\תרגול\targil1\helloWorld.asm'
'' fwrite outputFile

NB.מחזיר רשימה של שמות הקבצים הרלוונטיים בתיקיה
vmFiles =: 1 dir searchPattern
labelCount =: 0


processFiles =: 3 : 0

  NB. בכל סיבוב האיבר הנוכחי נקרא file_path
  for_file_path. y do.
    item =. > file_path
    
    NB. חילוץ שם הקובץ לצורך זיהוי (למשל עבור פקודות static בעתיד)
    start =. 1 + item i: '/'
    end =. item i. '.' 
    fileName =. (end - start) {. start }. item
    echo 'Processing: ', fileName
    
    NB. מפרק את האייטם הנוכחי לשורות שורות כדי שנוכל לעבוד עליהן
    lines =. cutLF freads item

  for_line. lines do.
     NB. lineStr =. deb > line
     lineRaw =. > line
     NB. 1. החלפת כל הטאבים (Tab) ברווחים רגילים
     lineNoTabs =. lineRaw rplc (9{a.) ; ' '
     NB. 2. עכשיו deb יעבוד מעולה וינקה את הרווחים מהקצוות
     lineStr =. deb lineNoTabs
     if. (0 = # lineStr) +. ('//' -: 2 {. lineStr) do. continue. end.
     NB. 3. פירוק חכם למילים - מתעלם מרווחים כפולים וטאבים
     words =. ([: -.&(<'') cut) lineStr
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
          targetAddr =. 5 + ". index  NB. מקטע temp ב-Hack מתחיל תמיד בכתובת 5.
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

      NB. 2. זיהוי פקודות אריתמטיות בינאריות (דורשות 2 איברים מהמחסנית)
      elseif. cmd -: 'add' do. asmLines =. translateAdd ''
      elseif. cmd -: 'sub' do. asmLines =. translateSub ''
      elseif. cmd -: 'and' do. asmLines =. translateAnd ''
      elseif. cmd -: 'or'  do. asmLines =. translateOr ''
      
      NB. 3. זיהוי פקודות אריתמטיות אונאריות (פועלות על איבר אחד)
      elseif. cmd -: 'neg' do. asmLines =. translateNeg ''
      elseif. cmd -: 'not' do. asmLines =. translateNot ''

      elseif. cmd -: 'eq'  do. asmLines =. translateComp 'JEQ'
      elseif. cmd -: 'gt'  do. asmLines =. translateComp 'JGT'
      elseif. cmd -: 'lt'  do. asmLines =. translateComp 'JLT'


NB. תרגיל 2
      elseif. cmd -: 'label' do.
        labelName =. > 1 { words
        asmLines =. translateLabel fileName ; labelName
      elseif. cmd -: 'goto' do.
        labelName =. > 1 { words
        asmLines =. translateGoto fileName ; labelName
      elseif. cmd -: 'if-goto' do.
        labelName =. > 1 { words
        asmLines =. translateIfGoto fileName ; labelName

      elseif. cmd -: 'function' do.
        fName =. > 1 { words  NB. שם הפונקציה 
        kVars =. > 2 { words  NB. מספר המשתנים 
        asmLines =. translateFunction fName ; kVars 
      elseif. cmd -: 'call' do.
        fName =. > 1 { words
        nArgs =. > 2 { words
        asmLines =. translateCall fName ; nArgs
      elseif. cmd -: 'return' do.
        asmLines =. translateReturn ''

      end.

     NB. אם הגענו לשורת קוד שהיא לא הערה נכתוב אותה לקובץ
     if. 0 < # asmLines do.
        ('// ' , lineStr , LF) fappend outputFile
        ( ; asmLines ,&.> <LF) fappend outputFile
      end.
    end.
  end.
  echo 'Translation Complete!'  
)

NB. הרצת התהליך
processFiles vmFiles
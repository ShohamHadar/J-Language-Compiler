NB.main.ijs file
load 'files'
load 'dir'
require 'C:\Users\User\j9.6-user\temp\arithmetic.ijs'
require 'C:\Users\User\j9.6-user\temp\memory.ijs'

NB. עדכון נתיבים לתיקיית הפרויקט החדשה
searchPattern =: 'C:\Users\User\nand2tetris\nand2tetris\projects\07\MemoryAccess\PointerTest\*.vm'
outputFile =: 'C:\Users\User\nand2tetris\nand2tetris\projects\07\MemoryAccess\PointerTest\PointerTest.asm'
'' fwrite outputFile

vmFiles =: 1 dir searchPattern
labelCount =: 0

processFiles =: 3 : 0
  for_file_path. y do.
    item =. > file_path
    
    NB. חילוץ שם הקובץ לצורך זיהוי (למשל עבור פקודות static בעתיד)
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
        elseif. segment -: 'pointer' do.
          asmLines =. translatePushPointer index
        elseif. segment -: 'temp' do.
          targetAddr =. 5 + ". index
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
      end.

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

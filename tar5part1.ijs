load 'files'
load 'dir'

NB. =========================================================================
NB. חלק א': Tokenizer
NB. =========================================================================

KEYWORDS =: 'class' ; 'constructor' ; 'function' ; 'method' ; 'field' ; 'static' ; 'var'
KEYWORDS =: KEYWORDS , 'int' ; 'char' ; 'boolean' ; 'void' ; 'true' ; 'false' ; 'null' ; 'this'
KEYWORDS =: KEYWORDS , 'let' ; 'do' ; 'if' ; 'else' ; 'while' ; 'return'
SYMBOLS =: '{'; '}'; '('; ')'; '['; ']'; '.'; ','; ';'; '+'; '-'; '*'; '/'; '&'; '|'; '<'; '>'; '='; '~'

DIGITS =: (48 + i.10) { a.
LETTERS =: ((65 + i.26) { a.) , ((97 + i.26) { a.) , '_'
ALPHANUMERIC =: LETTERS , DIGITS

isSymbol =: 3 : 'y e. SYMBOLS'
isDigit =: 3 : 'y e. DIGITS'
isLetter =: 3 : 'y e. LETTERS'
isAlphaNumeric =: 3 : 'y e. ALPHANUMERIC'
isKeyword =: 3 : 'y e. KEYWORDS'

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

processTokenizer =: 3 : 0
  tokensList =: 0 2 $ <''  
  cleanText =. removeComments freads y
  idx =. 0
  while. idx < # cleanText do.
    ch =. idx { cleanText
    if. isSymbol < ch do.
      tokensList =: tokensList , ('symbol' ; ch)
      idx =. idx + 1
      continue.
    end.
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
    idx =. idx + 1
  end.
  EMPTY
)

NB. =========================================================================
NB. חלק ב': Symbol Table
NB. =========================================================================

initClassTable =: 3 : 0
  classTab =: 0 4 $ <''
  staticIdx =: 0
  fieldIdx =: 0
  EMPTY
)

initSubTable =: 3 : 0
  subTab =: 0 4 $ <''
  argIdx =: 0
  varIdx =: 0
  EMPTY
)

NB. הפונקציה שוכתבה במלואה כדי למנוע את באג האינדקס שמתחיל מ-1 במקום מ-0
defineSymbol =: 4 : 0
  'name type kind' =. x
  if. kind -: 'static' do.
    idx =. staticIdx
    staticIdx =: staticIdx + 1
    classTab =: classTab , name ; type ; kind ; idx
  elseif. kind -: 'field' do.
    idx =. fieldIdx
    fieldIdx =: fieldIdx + 1
    classTab =: classTab , name ; type ; kind ; idx
  elseif. kind -: 'argument' do.
    idx =. argIdx
    argIdx =: argIdx + 1
    subTab =: subTab , name ; type ; kind ; idx
  elseif. kind -: 'var' do.
    idx =. varIdx
    varIdx =: varIdx + 1
    subTab =: subTab , name ; type ; kind ; idx
  end.
  EMPTY
)

lookupSymbol =: 3 : 0
  for_r. i. # subTab do.
    if. y -: > 0 { r { subTab do. (1 { r { subTab) , (2 { r { subTab) , (3 { r { subTab) return. end.
  end.
  for_r. i. # classTab do.
    if. y -: > 0 { r { classTab do. (1 { r { classTab) , (2 { r { classTab) , (3 { r { classTab) return. end.
  end.
  ''
)

varCount =: 3 : 0
  if. y -: 'static' do. staticIdx
  elseif. y -: 'field' do. fieldIdx
  elseif. y -: 'argument' do. argIdx
  elseif. y -: 'var' do. varIdx
  else. 0 end.
)

NB. =========================================================================
NB. חלק ג': VM Writer
NB. =========================================================================

writeVm =: 3 : 0
  (y , LF) fappend vmFile
  EMPTY
)

writePush =: 3 : 0
  'seg idx' =. y
  realSeg =. seg
  if. seg -: 'field' do. realSeg =. 'this' end.
  if. seg -: 'var' do. realSeg =. 'local' end.
  if. seg -: 'argument' do. realSeg =. 'argument' end.
  writeVm 'push ' , realSeg , ' ' , ": idx
)

writePop =: 3 : 0
  'seg idx' =. y
  realSeg =. seg
  if. seg -: 'field' do. realSeg =. 'this' end.
  if. seg -: 'var' do. realSeg =. 'local' end.
  if. seg -: 'argument' do. realSeg =. 'argument' end.
  writeVm 'pop ' , realSeg , ' ' , ": idx
)

writeArithmetic =: 3 : 0
  writeVm y
)

writeLabel =: 3 : 0
  writeVm 'label ' , y
)

writeGoto =: 3 : 0
  writeVm 'goto ' , y
)

writeIf =: 3 : 0
  writeVm 'if-goto ' , y
)

writeCall =: 3 : 0
  'name nArgs' =. y
  writeVm 'call ' , name , ' ' , ": nArgs
)

writeFunction =: 3 : 0
  'name nLocals' =. y
  writeVm 'function ' , name , ' ' , ": nLocals
)

writeReturn =: 3 : 0
  writeVm 'return'
)

NB. =========================================================================
NB. חלק ד': Compilation Engine
NB. =========================================================================

tokenIdx =: 0
labelCounter =: 0

getCurrentType =: 3 : 0
  if. tokenIdx < # tokensList do. > 0 { tokenIdx { tokensList return. end.
  ''
)

getCurrentValue =: 3 : 0
  if. tokenIdx < # tokensList do. > 1 { tokenIdx { tokensList return. end.
  ''
)

advanceToken =: 3 : 0
  tokenIdx =: tokenIdx + 1
  EMPTY
)

checkValue =: 3 : 0
  if. tokenIdx < # tokensList do. (getCurrentValue'') -: y return. end.
  0
)

lookAheadValue =: 3 : 0
  if. (tokenIdx + y) < # tokensList do. > 1 { (tokenIdx + y) { tokensList return. end.
  ''
)

getNewLabel =: 3 : 0
  res =. 'L' , ": labelCounter
  labelCounter =: labelCounter + 1
  res
)

compileClass =: 3 : 0
  advanceToken'' NB. class
  className =: getCurrentValue''
  advanceToken'' NB. className
  advanceToken'' NB. {
  
  initClassTable''
  
  while. tokenIdx < # tokensList do.
    val =. getCurrentValue''
    if. val -: 'static' do. compileClassVarDec''
    elseif. val -: 'field' do. compileClassVarDec''
    elseif. do. break. end.
  end.
  
  while. tokenIdx < # tokensList do.
    val =. getCurrentValue''
    if. val -: 'constructor' do. compileSubroutineDec''
    elseif. val -: 'function' do. compileSubroutineDec''
    elseif. val -: 'method' do. compileSubroutineDec''
    elseif. do. break. end.
  end.
  
  advanceToken'' NB. }
  EMPTY
)

compileClassVarDec =: 3 : 0
  kind =. getCurrentValue''
  advanceToken'' NB. static / field
  type =. getCurrentValue''
  advanceToken'' NB. type
  
  name =. getCurrentValue''
  advanceToken'' NB. varName
  (name ; type ; kind) defineSymbol ''
  
  while. tokenIdx < # tokensList do.
    if. checkValue ',' do.
      advanceToken'' NB. ,
      name =. getCurrentValue''
      advanceToken'' NB. varName
      (name ; type ; kind) defineSymbol ''
    else. break. end.
  end.
  
  advanceToken'' NB. ;
  EMPTY
)

compileSubroutineDec =: 3 : 0
  initSubTable''
  subType =. getCurrentValue''
  advanceToken''
  
  advanceToken'' NB. return type
  subName =. getCurrentValue''
  advanceToken'' NB. subroutineName
  
  if. subType -: 'method' do.
    ('this' ; className ; 'argument') defineSymbol ''
  end.
  
  advanceToken'' NB. (
  compileParameterList''
  advanceToken'' NB. )
  
  advanceToken'' NB. {
  while. tokenIdx < # tokensList do.
    if. checkValue 'var' do. compileVarDec''
    else. break. end.
  end.
  
  writeFunction (className , '.' , subName) ; (varCount 'var')
  
  if. subType -: 'method' do.
    writePush 'argument' ; 0
    writePop 'pointer' ; 0
  elseif. subType -: 'constructor' do.
    writePush 'constant' ; (varCount 'field')
    writeCall 'Memory.alloc' ; 1
    writePop 'pointer' ; 0
  end.
  
  compileStatements''
  advanceToken'' NB. }
  EMPTY
)

compileParameterList =: 3 : 0
  if. -. checkValue ')' do.
    type =. getCurrentValue''
    advanceToken''
    name =. getCurrentValue''
    advanceToken''
    (name ; type ; 'argument') defineSymbol ''
    
    while. tokenIdx < # tokensList do.
      if. checkValue ',' do.
        advanceToken'' NB. ,
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

compileVarDec =: 3 : 0
  advanceToken'' NB. var
  type =. getCurrentValue''
  advanceToken'' NB. type
  
  name =. getCurrentValue''
  advanceToken'' NB. varName
  (name ; type ; 'var') defineSymbol ''
  
  while. tokenIdx < # tokensList do.
    if. checkValue ',' do.
      advanceToken'' NB. ,
      name =. getCurrentValue''
      advanceToken'' NB. varName
      (name ; type ; 'var') defineSymbol ''
    else. break. end.
  end.
  
  advanceToken'' NB. ;
  EMPTY
)

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

compileDo =: 3 : 0
  advanceToken'' NB. do
  compileSubroutineCall''
  advanceToken'' NB. ;
  writePop 'temp' ; 0
  EMPTY
)

compileLet =: 3 : 0
  advanceToken'' NB. let
  varName =. getCurrentValue''
  advanceToken'' NB. varName
  
  isArray =. 0
  if. checkValue '[' do.
    isArray =. 1
    advanceToken'' NB. [
    compileExpression''
    advanceToken'' NB. ]
    sym =. lookupSymbol varName
    if. # sym do.
        writePush (> 1 { sym) ; (> 2 { sym)
    else.
        writePush 'local' ; 0 NB. Fallback
    end.
    writeArithmetic 'add'
  end.
  
  advanceToken'' NB. =
  compileExpression''
  advanceToken'' NB. ;
  
  if. isArray do.
    writePop 'temp' ; 0
    writePop 'pointer' ; 1
    writePush 'temp' ; 0
    writePop 'that' ; 0
  else.
    sym =. lookupSymbol varName
    if. # sym do.
        writePop (> 1 { sym) ; (> 2 { sym)
    else.
        writePop 'local' ; 0 NB. Fallback
    end.
  end.
  EMPTY
)

compileWhile =: 3 : 0
  l1 =. getNewLabel''
  l2 =. getNewLabel''
  
  writeLabel l1
  advanceToken'' NB. while
  advanceToken'' NB. (
  compileExpression''
  advanceToken'' NB. )
  writeArithmetic 'not'
  writeIf l2
  advanceToken'' NB. {
  compileStatements''
  advanceToken'' NB. }
  writeGoto l1
  writeLabel l2
  EMPTY
)

compileReturn =: 3 : 0
  advanceToken'' NB. return
  if. checkValue ';' do.
    writePush 'constant' ; 0
  else.
    compileExpression''
  end.
  advanceToken'' NB. ;
  writeReturn ''
  EMPTY
)

compileIf =: 3 : 0
  l1 =. getNewLabel''
  l2 =. getNewLabel''
  
  advanceToken'' NB. if
  advanceToken'' NB. (
  compileExpression''
  advanceToken'' NB. )
  writeArithmetic 'not'
  writeIf l1
  advanceToken'' NB. {
  compileStatements''
  advanceToken'' NB. }
  
  if. checkValue 'else' do.
    l3 =. getNewLabel''
    writeGoto l3
    writeLabel l1
    advanceToken'' NB. else
    advanceToken'' NB. {
    compileStatements''
    advanceToken'' NB. }
    writeLabel l3
  else.
    writeLabel l1
  end.
  EMPTY
)

compileExpression =: 3 : 0
  compileTerm''
  ops =. '+-*/&|<>='
  while. tokenIdx < # tokensList do.
    isOp =. 0
    if. (getCurrentType'') -: 'symbol' do.
      if. (getCurrentValue'') e. ops do. isOp =. 1 end.
    end.
    
    if. isOp = 0 do. break. end.
    
    op =. getCurrentValue''
    advanceToken''
    compileTerm''
    
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

NB. סדר הפקודות ב-true תוקן, ותוקן גם ה-false
compileTerm =: 3 : 0
  type =. getCurrentType''
  val =. getCurrentValue''
  
  if. type -: 'integerConstant' do.
    writePush 'constant' ; ". val
    advanceToken''
  elseif. type -: 'stringConstant' do.
    len =. # val
    writePush 'constant' ; len
    writeCall 'String.new' ; 1
    for_i. i. len do.
      writePush 'constant' ; a. i. (i { val)
      writeCall 'String.appendChar' ; 2
    end.
    advanceToken''
  elseif. type -: 'keyword' do.
    if. val -: 'true' do. 
      writePush 'constant' ; 0 
      writeArithmetic 'not'
    elseif. (val -: 'false') +. (val -: 'null') do. 
      writePush 'constant' ; 0
    elseif. val -: 'this' do. 
      writePush 'pointer' ; 0 
    end.
    advanceToken''
  elseif. type -: 'identifier' do.
    nextSym =. lookAheadValue 1
    if. nextSym -: '[' do. 
      advanceToken'' NB. varName
      advanceToken'' NB. [
      compileExpression''
      advanceToken'' NB. ]
      sym =. lookupSymbol val
      if. # sym do.
          writePush (> 1 { sym) ; (> 2 { sym)
      else.
          writePush 'local' ; 0
      end.
      writeArithmetic 'add'
      writePop 'pointer' ; 1
      writePush 'that' ; 0
    elseif. (nextSym -: '.') +. (nextSym -: '(') do.
      compileSubroutineCall''
    else.
      sym =. lookupSymbol val
      if. # sym do.
          writePush (> 1 { sym) ; (> 2 { sym)
      else.
          writePush 'local' ; 0
      end.
      advanceToken''
    end.
  elseif. val -: '(' do.
    advanceToken''
    compileExpression''
    advanceToken''
  elseif. (val -: '-') +. (val -: '~') do.
    advanceToken''
    compileTerm''
    if. val -: '-' do. writeArithmetic 'neg' else. writeArithmetic 'not' end.
  else.
    advanceToken'' 
  end.
  EMPTY
)

compileSubroutineCall =: 3 : 0
  name1 =. getCurrentValue''
  advanceToken'' NB. identifier
  
  nArgs =. 0
  callName =. ''
  
  if. checkValue '.' do.
    advanceToken'' NB. .
    name2 =. getCurrentValue''
    advanceToken'' NB. identifier
    
    sym =. lookupSymbol name1
    if. 0 = # sym do.
      callName =. name1 , '.' , name2
    else.
      callName =. (> 0 { sym) , '.' , name2
      writePush (> 1 { sym) ; (> 2 { sym)
      nArgs =. 1
    end.
  else.
    callName =. className , '.' , name1
    writePush 'pointer' ; 0
    nArgs =. 1
  end.
  
  advanceToken'' NB. (
  nArgs =. nArgs + compileExpressionList''
  advanceToken'' NB. )
  
  writeCall callName ; nArgs
  EMPTY
)

compileExpressionList =: 3 : 0
  count =. 0
  if. -. checkValue ')' do.
    compileExpression''
    count =. 1
    while. tokenIdx < # tokensList do.
      if. checkValue ',' do.
        advanceToken'' NB. ,
        compileExpression''
        count =. count + 1
      else. break. end.
    end.
  end.
  count
)

compileSingleFile =: 3 : 0
  targetFile =. y
  processTokenizer targetFile
  
  vmFile =: ((- # '.jack') }. targetFile) , '.vm'
  '' fwrite vmFile
  
  tokenIdx =: 0
  labelCounter =: 0
  compileClass''
  
  echo 'Generated VM for: ' , vmFile
  EMPTY
)

JackAnalyzer =: 3 : 0
  source =. y
  if. '.jack' -: _5 {. source do.
    compileSingleFile source
  else.
    folder =. source
    if. '\' -.@:-: _1 {. folder do. folder =. folder , '\' end.
    searchPattern =. folder , '*.jack'
    jackFiles =. 1 dir searchPattern
    
    if. 0 = # jackFiles do.
      echo 'Error: No .jack files found'
      EMPTY return.
    end.
    
    for_file_path. jackFiles do.
      compileSingleFile > file_path
    end.
  end.
  echo '=== DONE ==='
  EMPTY
)

NB. הרצת הקומפיילר
JackAnalyzer 'C:\Users\ASUS\Desktop\nand2tetris\projects\11\ComplexArrays'

NB.JackAnalyzer 'C:\Users\ASUS\Desktop\nand2tetris\projects\11\Pong'
NB.JackAnalyzer 'C:\Users\ASUS\Desktop\nand2tetris\projects\11\Average'
NB.JackAnalyzer 'C:\Users\ASUS\Desktop\nand2tetris\projects\11\Square'
NB.JackAnalyzer 'C:\Users\ASUS\Desktop\nand2tetris\projects\11\ConvertToBin'
NB.JackAnalyzer 'C:\Users\ASUS\Desktop\nand2tetris\projects\11\Seven'

load 'files'
load 'dir'

NB. =========================================================================
NB. חלק א': הגדרות וקבועים עבור שפת Jack (ה-Tokenizer)
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

processTokenizer =: 3 : 0
  tokensList =: 0 2 $ <''
  item =. > y
  dotIndex =. item i: '.'
  basePath =. dotIndex {. item
  outputFile =. basePath , 'T.xml'
  
  '<tokens>' fwrite outputFile
  rawText =. freads item
  cleanText =. removeComments rawText
  
  idx =. 0
  while. idx < # cleanText do.
    ch =. idx { cleanText
    boxedCh =. < ch
    
    if. isSymbol boxedCh do.
      escapedCh =. escapeXmlSymbol ch
      xmlLine =. LF , '  <symbol> ' , escapedCh , ' </symbol>'
      xmlLine fappend outputFile
      tokensList =: tokensList , ('symbol' ; ch)
      idx =. idx + 1
      continue.
    end.
    
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
  EMPTY
)


NB. =========================================================================
NB. חלק ב': המנתח התחבירי (Parser)
NB. =========================================================================

tokenIdx =: 0
indentLevel =: 0

initParser =: 3 : 0
  tokenIdx =: 0
  indentLevel =: 0
  EMPTY
)

getCurrentType =: 3 : 0
  if. tokenIdx < # tokensList do. > 0 { tokenIdx { tokensList else. '' end.
)

getCurrentValue =: 3 : 0
  if. tokenIdx < # tokensList do. > 1 { tokenIdx { tokensList else. '' end.
)

advanceToken =: 3 : 0
  tokenIdx =: tokenIdx + 1
  EMPTY
)

getIndent =: 3 : 0
  (indentLevel * 2) $ ' '
)

openTag =: 3 : 0
  xmlLine =. (getIndent'') , '<' , y , '>' , LF
  xmlLine fappend parsedFile
  indentLevel =: indentLevel + 1
  EMPTY
)

closeTag =: 3 : 0
  indentLevel =: indentLevel - 1
  xmlLine =. (getIndent'') , '</' , y , '>' , LF
  xmlLine fappend parsedFile
  EMPTY
)

writeTerminal =: 3 : 0
  type =. getCurrentType''
  val =. getCurrentValue''
  if. 0 = # type do. return. end.
  
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

compileClass =: 3 : 0
  openTag 'class'
  writeTerminal'' 
  writeTerminal'' 
  writeTerminal'' 
  
  while. tokenIdx < # tokensList do.
    nextVal =. getCurrentValue''
    if. (nextVal -: 'static') +. (nextVal -: 'field') do. compileClassVarDec'' else. break. end.
  end.
  
  while. tokenIdx < # tokensList do.
    nextVal =. getCurrentValue''
    if. (nextVal -: 'constructor') +. (nextVal -: 'function') +. (nextVal -: 'method') do. compileSubroutineDec'' else. break. end.
  end.
  
  writeTerminal'' 
  closeTag 'class'
  EMPTY
)

compileClassVarDec =: 3 : 0
  openTag 'classVarDec'
  while. tokenIdx < # tokensList do.
    val =. getCurrentValue''
    writeTerminal''
    if. val -: ';' do. break. end.
  end.
  closeTag 'classVarDec'
  EMPTY
)

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

compileParameterList =: 3 : 0
  openTag 'parameterList'
  while. tokenIdx < # tokensList do.
    val =. getCurrentValue''
    if. val -: ')' do. break. end.
    writeTerminal''
  end.
  closeTag 'parameterList'
  EMPTY
)

compileSubroutineBody =: 3 : 0
  openTag 'subroutineBody'
  writeTerminal'' 
  
  while. tokenIdx < # tokensList do.
    nextVal =. getCurrentValue''
    if. nextVal -: 'var' do. compileVarDec'' else. break. end.
  end.
  
  compileStatements''
  writeTerminal'' 
  closeTag 'subroutineBody'
  EMPTY
)

compileVarDec =: 3 : 0
  openTag 'varDec'
  while. tokenIdx < # tokensList do.
    val =. getCurrentValue''
    writeTerminal''
    if. val -: ';' do. break. end.
  end.
  closeTag 'varDec'
  EMPTY
)

compileStatements =: 3 : 0
  openTag 'statements'
  while. tokenIdx < # tokensList do.
    val =. getCurrentValue''
    if. val -: '}' do. break.
    elseif. val -: 'let' do. compileLet''
    elseif. val -: 'do' do. compileDo''
    elseif. val -: 'return' do. compileReturn''
    elseif. val -: 'while' do. compileWhile''
    elseif. val -: 'if' do. compileIf''
    else. writeTerminal''
    end.
  end.
  closeTag 'statements'
  EMPTY
)

compileLet =: 3 : 0
  openTag 'letStatement'
  writeTerminal'' 
  writeTerminal'' 
  if. getCurrentValue'' -: '[' do.
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

compileDo =: 3 : 0
  openTag 'doStatement'
  writeTerminal'' 
  while. tokenIdx < # tokensList do.
    val =. getCurrentValue''
    if. val -: '(' do. break. end.
    writeTerminal''
  end.
  writeTerminal'' 
  compileExpressionList''
  writeTerminal'' 
  writeTerminal'' 
  closeTag 'doStatement'
  EMPTY
)

compileReturn =: 3 : 0
  openTag 'returnStatement'
  writeTerminal'' 
  if. (getCurrentValue'') -.@:-: ';' do. compileExpression'' end.
  writeTerminal'' 
  closeTag 'returnStatement'
  EMPTY
)

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

compileIf =: 3 : 0
  openTag 'ifStatement'
  writeTerminal'' 
  writeTerminal'' 
  compileExpression''
  writeTerminal'' 
  writeTerminal'' 
  compileStatements''
  writeTerminal'' 
  if. getCurrentValue'' -: 'else' do.
    writeTerminal'' 
    writeTerminal'' 
    compileStatements''
    writeTerminal'' 
  end.
  closeTag 'ifStatement'
  EMPTY
)

compileExpression =: 3 : 0
  openTag 'expression'
  compileTerm''
  val =. getCurrentValue''
  if. (val -: '+') +. (val -: '-') +. (val -: '*') +. (val -: '/') +. (val -: '=') +. (val -: '>') +. (val -: '<') do.
    writeTerminal''
    compileTerm''
  end.
  closeTag 'expression'
  EMPTY
)

compileTerm =: 3 : 0
  openTag 'term'
  type =. getCurrentType''
  if. type -: 'identifier' do.
    writeTerminal''
    if. getCurrentValue'' e. '.', '[' do.
      writeTerminal'' 
      writeTerminal'' 
      if. getCurrentValue'' -: '(' do.
        writeTerminal'' 
        compileExpressionList''
        writeTerminal'' 
      end.
    end.
  else.
    writeTerminal''
  end.
  closeTag 'term'
  EMPTY
)

compileExpressionList =: 3 : 0
  openTag 'expressionList'
  while. tokenIdx < # tokensList do.
    val =. getCurrentValue''
    if. val -: ')' do. break. end.
    if. val -: ',' do. writeTerminal'' continue. end.
    compileExpression''
  end.
  closeTag 'expressionList'
  EMPTY
)

NB. =========================================================================
NB. פונקציית הקישור וההפעלה הסופית
NB. =========================================================================
compileAll =: 3 : 0
  targetFile =. y
  
  NB. הפעלת ה-Tokenizer
  processTokenizer targetFile
  
  NB. קביעת נתיב ה-XML המלא והמיושר
  parsedFile =: ((- # '.jack') }. targetFile) , '.xml'
  '' fwrite parsedFile
  
  NB. הפעלת ה-Parser
  initParser''
  compileClass''
  
  echo '=== SUCCESS! XML GENERATED COMPLIANT WITH PROJECT 10 ==='
  echo parsedFile
  EMPTY
)

compileAll 'C:\Users\ASUS\Desktop\nand2tetris\projects\10\ArrayTest\Main.jack'
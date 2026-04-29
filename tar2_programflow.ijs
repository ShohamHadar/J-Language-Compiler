NB.תרגיל 2
NB. תרגום פקודת label
translateLabel =: 3 : 0
  'fileName labelName' =. y
  < '(', fileName, '.', labelName, ')'
)

NB. תרגום פקודת goto
translateGoto =: 3 : 0
  'fileName labelName' =. y
  (' @', fileName, '.', labelName) ; < ' 0;JMP'
)

NB. תרגום פקודת if-goto
translateIfGoto =: 3 : 0
  'fileName labelName' =. y
  NB. מוציאים את הערך מהמחסנית, אם הוא לא 0 קופצים
  (' @SP') ; (' AM=M-1') ; (' D=M') ; (' @', fileName, '.', labelName) ; < ' D;JNE'
)
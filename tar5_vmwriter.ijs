
NB. =========================================================================
NB. חלק ג': VM Writer (כותב פקודות ה-VM)
NB. תפקיד: פונקציות ייעודיות לכתיבת פקודות ה-VM התקניות לקובץ הפלט
NB. =========================================================================

writeVm =: 3 : 0
  (y , LF) fappend vmFile                           NB. כתיבת שורה לקובץ ה-VM עם ירידת שורה
  EMPTY
)

NB. כתיבת פקודת דחיפה (push) תוך תרגום שמות הסגמנטים של Jack לסגמנטים של VM
writePush =: 3 : 0
  'seg idx' =. y
  realSeg =. seg
  if. seg -: 'field' do. realSeg =. 'this' end.     NB. field הופך ל-this
  if. seg -: 'var' do. realSeg =. 'local' end.       NB. var הופך ל-local
  if. seg -: 'argument' do. realSeg =. 'argument' end.
  writeVm 'push ' , realSeg , ' ' , ": idx
)

NB. כתיבת פקודת שליפה (pop) תוך תרגום שמות הסגמנטים של Jack לסגמנטים של VM
writePop =: 3 : 0
  'seg idx' =. y
  realSeg =. seg
  if. seg -: 'field' do. realSeg =. 'this' end.
  if. seg -: 'var' do. realSeg =. 'local' end.
  if. seg -: 'argument' do. realSeg =. 'argument' end.
  writeVm 'pop ' , realSeg , ' ' , ": idx
)

writeArithmetic =: 3 : 0
  writeVm y                                         NB. כתיבת פקודה אריתמטית (add, sub, not וכו')
)

writeLabel =: 3 : 0
  writeVm 'label ' , y                              NB. יצירת תווית (עבור תנאים ולולאות)
)

writeGoto =: 3 : 0
  writeVm 'goto ' , y                               NB. קפיצה לא מותנית
)

writeIf =: 3 : 0
  writeVm 'if-goto ' , y                            NB. קפיצה מותנית (אם הערך בראש המחסנית אינו 0)
)

writeCall =: 3 : 0
  'name nArgs' =. y
  writeVm 'call ' , name , ' ' , ": nArgs           NB. קריאה לפונקציה/מתודה
)

writeFunction =: 3 : 0
  'name nLocals' =. y
  writeVm 'function ' , name , ' ' , ": nLocals     NB. הצהרה על פונקציה וכמות המשתנים המקומיים שלה
)

writeReturn =: 3 : 0
  writeVm 'return'                                  NB. חזרה מפונקציה
)
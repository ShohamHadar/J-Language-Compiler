
NB. =========================================================================
NB. חלק ב': Symbol Table (טבלת סמלים)
NB. תפקיד: לנהל את המשתנים ברמת המחלקה (Class) וברמת תת-השגרה (Subroutine)
NB. מבנה הטבלה: (שם ; טיפוס ; סוג/Kind ; אינדקס רץ)
NB. =========================================================================

NB. איפוס טבלת הסמלים של המחלקה (עבור משתני static ו-field)
initClassTable =: 3 : 0
  classTab =: 0 4 $ <''
  staticIdx =: 0
  fieldIdx =: 0
  EMPTY
)

NB. איפוס טבלת הסמלים של תת-השגרה (עבור ארגומנטים argument ומשתנים מקומיים var)
initSubTable =: 3 : 0
  subTab =: 0 4 $ <''
  argIdx =: 0
  varIdx =: 0
  EMPTY
)

NB. הגדרת סמל חדש והכנסתו לטבלה המתאימה עם אינדקס מתאים
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

NB. חיפוש סמל לפי שמו. קודם כל מחפשים בטבלה המקומית (סקופ קרוב), ואז בגלובלית של המחלקה
lookupSymbol =: 3 : 0
  for_r. i. # subTab do.
    if. y -: > 0 { r { subTab do. (1 { r { subTab) , (2 { r { subTab) , (3 { r { subTab) return. end.
  end.
  for_r. i. # classTab do.
    if. y -: > 0 { r { classTab do. (1 { r { classTab) , (2 { r { classTab) , (3 { r { classTab) return. end.
  end.
  ''                                                NB. מחזיר מחרוזת ריקה אם לא נמצא
)

NB. החזרת כמות המשתנים שהוגדרו מסוג מסוים (משמש לקביעת גודל הקצאת זיכרון)
varCount =: 3 : 0
  if. y -: 'static' do. staticIdx
  elseif. y -: 'field' do. fieldIdx
  elseif. y -: 'argument' do. argIdx
  elseif. y -: 'var' do. varIdx
  else. 0 end.
)
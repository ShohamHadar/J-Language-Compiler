NB. הגדרת הנתיב לקבצי הקריאה ופתיחת קובץ לכתיבה
searchPattern =: 'C:/Temp/Tar0/*.vm'
outputFile =: 'C:/Temp/Tar0/Tar0.asm'

NB. שימוש ב-dir עם הפרמטר '1' מחזיר רק את שמות הקבצים בתוך קופסאות
vmFiles =: 1 dir searchPattern
vmFiles

item =: > 0 { vmFiles

NB. 1. מציאת האינדקסים של שם הקובץ
start =: 1 + item i: '/' NB. אחרי הסלאש האחרון
end =: item i. '.' NB. לפני הנקודה

NB. משתנים גלובליים לסכום כולל
G_totalBuy=: 0
G_totalCell=:0

NB. פונקציית עזר לחיתוך הקובץ לפי שורות
readLines =: 3 : 'cutLF freads y'


processFiles =: 3 : 0
  for_file_path. y do.
    item =. > file_path
    
    NB. מציאת האינדקסים של שם הקובץ
    NB. אחרי הסלאש האחרון
    NB. לפני הנקודה
    start =. 1 + item i: '/'
    end =. item i. '.' 
    fileName =. (end - start) {. start }. item
    (fileName, LF) fappend outputFile

    NB. קריאת השורות
    allContent =. freads item
    lines =. cutLF allContent  NB. חותך את הקובץ לשורות אמיתיות
    
    for_line. lines do.
      lineStr =. > line
      words =. cut lineStr  NB. פירוק השורה למילים
      
      if. 0 = # words do. continue. end.
      
      NB. שימוש ב-deb (Delete Extra Blanks) לביטחון
      command =. deb > 0 { words
      params =. 1 }. words
      
      if. command -: 'buy' do.
        HandleBuy params
      elseif. command -: 'cell' do.
        HandleCell params
      end.
    end.
  end.

  NB. כתיבת הסכום הסופי למסך ולקובץ
  printTotalBuy=. LF, 'TOTAL BUY: ', (":G_totalBuy)
  printTotalBuy fappend outputFile
  printTotalCell=. LF, 'TOTAL Cell: ', (": G_totalCell)
  printTotalCell fappend outputFile

  echo 'TOTAL BUY: ', (":G_totalBuy)
  echo 'TOTAL Cell: ', (":G_totalCell)
)

HandleBuy =: 3 : 0
  NB. y היא רשימה של קופסאות, אנחנו מוציאים אותן
  'name amount price' =. y

  NB. ". זה המרת מחרוזת למספר
  amount =. ". amount
  price =. ". price
  total =. amount * price
  G_totalBuy=: G_totalBuy+total

  NB. בניית המחרוזת
  NB. (": total) זה המרת מספר למחרוזת
  totalout =.LF, (": total), LF
  out =. '### BUY ', name, ' ###'
  out fappend outputFile
  totalout fappend outputFile

)

HandleCell =: 3 : 0
  NB. y היא רשימה של קופסאות, אנחנו מוציאים אותן
  'name amount price' =. y

  amount =. ". amount
  price =. ". price
  total =. amount * price
  G_totalCell=: G_totalCell+total

  NB. בניית המחרוזת
  totalout =.LF, (": total), LF
  out =. '$$$ CELL ', name, ' $$$'
  out fappend outputFile
  totalout fappend outputFile

)

processFiles vmFiles


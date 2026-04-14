NB. הגדרת הלוגיקה
process_data =: verb define
echo 'inn'
  input =. (1!:1) 3            NB. המתנה לקלט
  input =. 2 }. input          NB. דוגמה לעיבוד (הורדת תווים מיותרים)
  echo 'Result: ' , |. input   NB. הדפסת הקלט בהיפוך
)

echo 'out'
NB. קריאה לפונקציה שתתבצע מיד עם טעינת הקובץ
process_data

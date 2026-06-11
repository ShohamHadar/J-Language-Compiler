load 'files'
load 'dir'
load 'C:\Users\User\j9.6-user\temp\tar5_compiler.ijs'



NB. פונקציית העל המקבלת נתיב של קובץ או תיקייה שלמה, ומריצה את ההידור על כל קבצי ה-Jack הרלוונטיים
JackAnalyzer =: 3 : 0
  source =. y
  if. '.jack' -: _5 {. source do.
    compileSingleFile source                        NB. אם זה קובץ בודד
  else.
    NB. אם זו תיקייה - נחפש את כל קבצי ה-Jack בתוכה
    folder =. source
    if. '\' -.@:-: _1 {. folder do. folder =. folder , '\' end.
    searchPattern =. folder , '*.jack'
    jackFiles =. 1 dir searchPattern
    
    if. 0 = # jackFiles do.
      echo 'Error: No .jack files found'
      EMPTY return.
    end.
    
    for_file_path. jackFiles do.
      compileSingleFile > file_path                 NB. הידור כל קובץ שנמצא בתיקייה
    end.
  end.
  echo '=== DONE ==='
  EMPTY
)

NB. =========================================================================
NB. הרצת הקומפיילר על פרויקטי הבדיקה השונים של Nand2Tetris
NB. =========================================================================
JackAnalyzer 'C:\Users\User\nand2tetris\nand2tetris\projects\11\ComplexArrays'
NB.JackAnalyzer 'C:\Users\User\nand2tetris\nand2tetris\projects\11\Pong'
NB.JackAnalyzer 'C:\Users\User\nand2tetris\nand2tetris\projects\11\Average'
NB.JackAnalyzer 'C:\Users\User\nand2tetris\nand2tetris\projects\11\Square'
NB.JackAnalyzer 'C:\Users\User\nand2tetris\nand2tetris\projects\11\ConvertToBin'
NB.JackAnalyzer 'C:\Users\User\nand2tetris\nand2tetris\projects\11\Seven'
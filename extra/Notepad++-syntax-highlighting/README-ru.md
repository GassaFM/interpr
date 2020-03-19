# О файле pr.xml
Этот файл можно использовать для подсветки синтаксиса в коде на языке Pr в Notepad++

# Инструкции
Скачайте файл `pr.xml`.
В Notepad++, выберите `Синтаксисы` -> `Польз. Определение Синтаксиса` -> `Задать свой синтаксис`. 
В открывшемся окне нажмите кнопку `Импортир...` и выберите файл `pr.xml`.
Закройте окно `Польз. определение языка`.

Notice the label at the bottom left displaying which syntax highlighting is applied 
Заметьте надпись в левом нижнем углу окна, в которой отображается текущий язык подсветки.
(там может быть написано `normal text` или указан какой-либо язык, например `C++`, `Python`, и т.д.).
Кликните правой кнопкой мыши по этой надписи и выберите 'Pr' в нижней части меню. Настройка завершена.

# Known issues
* This UDL does not support folding in code (`if..else`, `for`, `while` blocks). Unfortunately it is 
[not implemented](https://stackoverflow.com/questions/7246004/configure-notepad-to-use-indentation-based-code-folding) 
in Notepad++'s User-Defined Languages.

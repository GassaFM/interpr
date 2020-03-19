# About pr.xml
[Читать на русском](README-ru.md)

With this file you can enable neat syntax highlighting for Pr in Notepad++.

# Instructions
Download the `pr.xml` file.
In Notepad++, choose `Language` -> `User Defined Language` -> `Define your language...`. 
In the window opened, press the `Import` button, and choose the `pr.xml` file.
Close the `User-Defined` window. 

Notice the label at the bottom left displaying which syntax highlighting is applied 
(it should say `Normal text file` or any language, such as `C++`, `Python`, etc.).
Right-click this label and choose 'Pr' at the bottom of the menu; and so you are done.

# Known issues
* This UDL does not support folding in code (`if..else`, `for`, `while` blocks). Unfortunately it is 
[not implemented](https://stackoverflow.com/questions/7246004/configure-notepad-to-use-indentation-based-code-folding) 
in Notepad++'s User-Defined Languages.

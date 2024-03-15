# Установка

(Go to [English](install.md) version)

Для **Windows** доступен готовый исполняемый файл: https://github.com/GassaFM/interpr/releases / Assets / interpr-*X.X*-win32.zip (где *X.X* обозначает последнюю release-версию).

Также возможно собрать исполняемый `interpr.exe` напрямую из иходного кода:

## Установка компилятора

### Windows

Скачайте и установите компилятор из https://dlang.org/download.html#dmd.

### Linux

Для дистрибутивов, основанных на Debian, вам нужно установить `dmd`: 
```
sudo apt install dmd
```
Если пакет не найден, то нужно установить `snap`:
```
sudo apt install snap snapd
```
Теперь можно установить `dmd`:
```
sudo snap install dmd --classic
```
Для дистрибутива Arch используйте `pacman`:
```
sudo pacman -S dmd
```

### macOS

Запустите:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew install dmd
```

## Компиляция исходников

После установки `dmd` нужно запустить:
```
git clone https://github.com/GassaFM/interpr
cd interpr
dub build
```
Или вместо последней строчки:
```
dmd -of=interpr source/*.d
```
Теперь у Вас есть исполняемый файл `interpr`.

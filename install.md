# Installation

(К [русской](install.ru.md) версии)

For **Windows** there is an executable file available on https://github.com/GassaFM/interpr/releases / Assets / interpr-*X.X*-win32.zip (where *X.X* means last release version).

Anyway it's possible to build executable `interpr.exe` with sources:

## Installing the compiler

### Windows

Download and install compiler from https://dlang.org/download.html#dmd.

### Linux

For Debian-based distributions you have to install dmd: 
```
sudo apt install dmd
```
If package is not found, you need to install `snap`:
```
sudo apt install snap snapd
```
Now you can install `dmd`:
```
sudo snap install dmd --classic
```
For Arch you may use `pacman`:
```
sudo pacman -S dmd
```

### macOS

Run:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew install dmd
```

## Compiling the sources

After installing dmd, you should run:
```
git clone https://github.com/GassaFM/interpr
cd interpr
dmd -of=interpr source/*.d
```
You also may use `dub` to build an executable:
```
dub build
```
Now you have an executable file `interpr`.

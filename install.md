# Installation

(К [русской](install.ru.md) версии)

## Downloading the source

### Windows

There is an executable file for Windows available on https://github.com/GassaFM/interpr/releases.

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

## Compiling the source

After installing dmd, you should run:
```
git clone https://github.com/GassaFM/interpr
cd interpr/source
dub build
```
Or, instead of the last line:
```
dmd -of=interpr source/*.d
```
Now you have an executable file `interpr`.

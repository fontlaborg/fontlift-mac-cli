# fontlift-mac-cli

CLI tool written in Swift for macOS to install/uninstall fonts

## Usage

### Listing installed fonts

- `fontlift list` or `fontlift list -p` lists the paths of all installed fonts, one path per line
- `fontlift list -n` lists the internal font names of all installed fonts, one name per line
- `fontlift list -n -p` or `fontlift list -n -p` lists the the paths and internal font names of all installed fonts; each line consists of the path followed by semicolon followed by the internal font name
- `l` should be a synonym for `list`

### Installing fonts

- `fontlift install FILEPATH` or `fontlift install -p FILEPATH` installs on the system the font (or all fonts in case of a .ttc or .otc) from the FILEPATH 
- `i` should be a synonym for `install`

### Uninstalling fonts while keeping the font files

- `fontlift uninstall FILEPATH` or `fontlift uninstall -p FILEPATH` uninstalls from the system the font (or all fonts in case of a .ttc or .otc) with the FILEPATH (keeps the file)
- `fontlift uninstall -n FONTNAME` uninstalls the font with the given internal font name from the system (keeps the file)
- `u` should be the synonym for `uninstall`

### Uninstalling fonts and removing the font files

- `fontlift remove FILEPATH` or `fontlift remove -p FILEPATH` uninstalls from the system the font (or all fonts in case of a .ttc or .otc) with the FILEPATH (and removes the file)
- `fontlift remove -n FONTNAME` uninstalls the font with the given internal font name from the system (and removes the file) 
- `rm` should be the synonym for `remove`

---

- Copyright 2025 by Fontlab Ltd.
- Licensed under Apache 2.0
- Repo: https://github.com/fontlaborg/fontlift-mac-cli
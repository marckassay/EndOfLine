# EndOfLine

EndOfLine is a PowerShell module that automates converting end-of-line (EOL) characters in files.

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/marckassay/EndOfLine/blob/master/LICENSE) [![PS Gallery](https://img.shields.io/badge/install-PS%20Gallery-blue.svg)](https://www.powershellgallery.com/packages/EndOfLine/)

## Features

* Imports `.gitignore` file for exclusion of files and directories
* Simulate what will happen via `WhatIf` switch
* Outputs a report on all files.  `Verbose` switch is can be used too.

## Caveat

The nature of this module may be destructive in some situations.  Please have backup plan in place before executing.

## Instructions

To install, run the following command in PowerShell.

```powershell
$ Install-Module EndOfLine
```

## Usage

### ConvertTo-LF

Converts CRLF to LF characters.

This function will recursivly read all files within the `Path` URI, unless excluded by `.gitignore` file.  If a file is not excluded it is read to see if the current EOL character is the same as requested.  If so it will not modify the file.  And if the encoding is not compatiable with UTF-8, these files will also not be modified.

Using the `WhatIf` and `Verbose` switch.

```powershell
$ ConvertTo-LF -Path C:\repos\AiT -WhatIf -Verbose
```

If you argee when prompted, files will be modified without import of `.gitignore` file.

```powershell
$ ConvertTo-LF -Path C:\repos\AiT -SkipIgnoreFile
```

If you argee when prompted, files will be modified with import of `.gitignore` file if found.

```powershell
$ ConvertTo-LF -Path C:\repos\AiT
```

### ConvertTo-CRLF

Converts LF to CRLF characters.

Besides the chracters that will be replaced, all things that apply in `ConvertTo-LF` apply to this function.
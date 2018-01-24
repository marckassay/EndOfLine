# EndOfLine

Objective of this module is conversion of end-of-line (EOL) characters in UTF-8 files: CRLF to LF or LF to CRLF

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/marckassay/EndOfLine/blob/master/LICENSE) [![PS Gallery](https://img.shields.io/badge/install-PS%20Gallery-blue.svg)](https://www.powershellgallery.com/packages/EndOfLine/)

## Features

* Imports `.gitignore` file for exclusion of files and directories.  You can use the `SkipIgnoreFile` switch to prevent importing that file.
* Simulate what will happen via `WhatIf` switch
* Outputs a report on all files.  The `Verbose` switch can be used too.

## Caveat

* The nature of this module may be destructive in some situations.  Please have backup plan in place before executing.
* Files are expected to be encoded in UTF-8.  If encoded in anything else it will not be modified.

## Instructions

To install, run the following command in PowerShell.

```powershell
$ Install-Module EndOfLine
```

This module has 'Encoding' as a dependency that should be installed automatically.

[![PS Gallery](https://img.shields.io/badge/Encoding-PS%20Gallery-blue.svg)](https://www.powershellgallery.com/packages/Encoding)

## Usage

### ConvertTo-LF

Converts CRLF to LF characters.
This function will recursively read all files within the `Path` unless excluded by `.gitignore` file.  If a file is not excluded it is read to see if the current EOL character is the same as requested.  If so it will not modify the file.

Example using the `WhatIf`, and `Verbose` switch.

```powershell
$ ConvertTo-LF -Path C:\repos\AiT -WhatIf -Verbose
```

For this example, if you agree when prompted files will be modified without import of `.gitignore` file.

```powershell
$ ConvertTo-LF -Path C:\repos\AiT -SkipIgnoreFile
```

If you agree when prompted, files will be modified with import of `.gitignore` file if found.

```powershell
$ ConvertTo-LF -Path C:\repos\AiT
```

### ConvertTo-CRLF

Converts LF to CRLF characters.
Besides the characters that will be replaced, all things that apply in `ConvertTo-LF` apply to this function too.

##
Get-PartentPath 
convert child folder and it will find parent .gitignore file.
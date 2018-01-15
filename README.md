# EndOfLine

EndOfLine is a PowerShell module that automates converting end-of-line (EOL) characters in files.
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/marckassay/EndOfLine/blob/master/LICENSE) [![PS Gallery](https://img.shields.io/badge/install-PS%20Gallery-blue.svg)](https://www.powershellgallery.com/packages/EndOfLine/)

## Features

* Imports `.gitignore` file for exclusion of files and directories.  You can use the `SkipIgnoreFile` switch to prevent importing that file.
* Simulate what will happen via `WhatIf` switch
* Outputs a report on all files.  The `Verbose` switch can be used too.

## Caveat

* The nature of this module may be destructive in some situations.  Please have backup plan in place before executing.
* Files are expected to be encoded in UTF-8.  If encoded in anything else it will not be modified unless called with `ExperimentalEncodingConversion` switch.  This switch *may* safely convert UTF-16 into UTF-8.  If it does safey convert the encoding, some diff editors (perhaps all) will show the file's bytes not decoded (which is expected) before the modification.  Until I have a better understanding of decoding and encoding Unicode files I will keep this switch as-is.

## Instructions

To install, run the following command in PowerShell.

```powershell
$ Install-Module EndOfLine
```

## Usage

### ConvertTo-LF

Converts CRLF to LF characters.
This function will recursively read all files within the `Path` unless excluded by `.gitignore` file.  If a file is not excluded it is read to see if the current EOL character is the same as requested.  If so it will not modify the file.  And if the encoding is not compatible with UTF-8 (unless called with `ExperimentalEncodingConversion` switch), these files will also not be modified.
Using the `WhatIf`, `ExperimentalEncodingConversion` and `Verbose` switch.

```powershell
$ ConvertTo-LF -Path C:\repos\AiT -WhatIf -ExperimentalEncodingConversion -Verbose
```

If you agree when prompted, files will be modified without import of `.gitignore` file.

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
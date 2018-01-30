$script:SUT = $false
$script:ReportCollection
<#
.SYNOPSIS
Converts UTF-8 encoded files with CRLF end-of-line markings to LF markings

.DESCRIPTION
With the given -Path, this function will look for a .gitignore file for exclusion unless
specified by the -SkipIgnoreFile switch.  With this ignore file you can add additional 
items using the -Exclude parameter. There are limitations with nested items being excluded,
see Examples for more info.

If a .gitignore file is found it will output in the console before the console prompts you
to proceed with conversion.  If the -WhatIf is switched, it will perform the same operations
as if it wasn't except the writing operation with the file.

After conversion operation, the report will output in the console.  The -ExportReportData 
switch is an alternative to the report mentioned.

.PARAMETER Path
Ideally the location of the repository (.git folder).  But it can be any folder too, just 
haven't tested in those circumstances much.

.PARAMETER Exclude
To exclude files or folders.  This can be used in addition to this function using the .gitignore
file or without it.  Exclusion of .gitignore file use -SkipIgnoreFile switch.

.PARAMETER SkipIgnoreFile
Skips seeking and import of .gitignore file.

.PARAMETER ExportReportData
For every file it opens, regardless if its written too, will be included in this output if switched 

.PARAMETER WhatIf
Will do the same operations as if not switched except writing to the file.

.EXAMPLE
The path being used in this example will, assume that there is a .gitignore in it or depth or two below.

ConvertTo-CRLF C:\repos\sots -WhatIf

.EXAMPLE
If the repo has a .gitignore file, skip it and just exclude modules folder that is specified in 
-Exclude parameter.

ConvertTo-CRLF C:\repos\sots -Exclude .\modules\, .\node_modules\ -SkipIgnoreFile -WhatIf

.EXAMPLE
Having the -Verbose switched it will continue the parsing a .gitignore file it there is one, and will 
prompt before proceeding to convert files.

ConvertTo-CRLF C:\repos\sots -Verbose

.NOTES
General notes
#>
function ConvertTo-LF {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Exclude,

        [switch]$SkipIgnoreFile,

        [switch]$ExportReportData,

        [switch]$WhatIf
    )
    $Path | Convert-EOL -EOL 'LF' `
        -Exclude $Exclude `
        -SkipIgnoreFile:$SkipIgnoreFile.IsPresent `
        -ExportReportData:$ExportReportData.IsPresent `
        -WhatIf:$WhatIf.IsPresent
}

<#
.SYNOPSIS
Converts UTF-8 encoded files with LF end-of-line markings to CRLF markings

.DESCRIPTION
With the given -Path, this function will look for a .gitignore file for exclusion unless
specified by the -SkipIgnoreFile switch.  With this ignore file you can add additional 
items using the -Exclude parameter. There are limitations with nested items being excluded,
see Examples for more info.

If a .gitignore file is found it will output in the console before the console prompts you
to proceed with conversion.  If the -WhatIf is switched, it will perform the same operations
as if it wasn't except the writing operation with the file.

After conversion operation, the report will output in the console.  The -ExportReportData 
switch is an alternative to the report mentioned.

.PARAMETER Path
Ideally the location of the repository (.git folder).  But it can be any folder too, just 
haven't tested in those circumstances much.

.PARAMETER Exclude
To exclude files or folders.  This can be used in addition to this function using the .gitignore
file or without it.  Exclusion of .gitignore file use -SkipIgnoreFile switch.

.PARAMETER SkipIgnoreFile
Skips seeking and import of .gitignore file.

.PARAMETER ExportReportData
For every file it opens, regardless if its written too, will be included in this output if switched 

.PARAMETER WhatIf
Will do the same operations as if not switched except writing to the file.

.EXAMPLE
The path being used in this example will, assume that there is a .gitignore in it or depth or two below.

ConvertTo-CRLF C:\repos\sots -WhatIf

.EXAMPLE
If the repo has a .gitignore file, skip it and just exclude modules folder that is specified in 
-Exclude parameter.

ConvertTo-CRLF C:\repos\sots -Exclude .\modules\, .\node_modules\ -SkipIgnoreFile -WhatIf

.EXAMPLE
Having the -Verbose switched it will continue the parsing a .gitignore file it there is one, and will 
prompt before proceeding to convert files.

ConvertTo-CRLF C:\repos\sots -Verbose

.NOTES
General notes
#>
function ConvertTo-CRLF {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Exclude,

        [switch]$SkipIgnoreFile,

        [switch]$ExportReportData,

        [switch]$WhatIf
    )
    $Path | Convert-EOL -EOL 'CRLF' `
        -Exclude $Exclude `
        -SkipIgnoreFile:$SkipIgnoreFile.IsPresent `
        -ExportReportData:$ExportReportData.IsPresent `
        -WhatIf:$WhatIf.IsPresent
}

function Convert-EOL {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false)]
        [string[]]$Exclude,

        [ValidateSet("LF", "CRLF")]
        [string]$EOL,

        [switch]$SkipIgnoreFile,

        [switch]$ExportReportData,

        [switch]$WhatIf
    )

    if ($Path | Test-Path -PathType Container) {
        Push-Location
        if ($Path -eq '.') {
            $Path = Resolve-Path '.'
        }
        $Path | Set-Location

        if (($SkipIgnoreFile.IsPresent -eq $false) -and (!$Exclude)) {
            $GitIgnoreContents = Import-GitIgnoreFile $Path
            if ($GitIgnoreContents) {
                $IgnoreHashTable = New-IgnoreHashTable $GitIgnoreContents
            }
        }
        elseif (($SkipIgnoreFile.IsPresent -eq $false) -and ($Exclude)) {
            $GitIgnoreContents = Import-GitIgnoreFile $Path
            if ($GitIgnoreContents) {
                $ArrayList = New-Object System.Collections.ArrayList
                $ArrayList.AddRange($GitIgnoreContents)
                $ArrayList.AddRange($Exclude)
                [string[]]$GitAndExcludeContents = $ArrayList.ToArray()
                $IgnoreHashTable = New-IgnoreHashTable $GitAndExcludeContents
            }
        }
        elseif ($Exclude) {
            $IgnoreHashTable = New-IgnoreHashTable $Exclude
        }
        Pop-Location
    }
    
    $ConfirmationMessage = New-ConfirmationMessage -EOL $EOL -WhatIf:$WhatIf.IsPresent
    $Decision = Request-Confirmation -Message $ConfirmationMessage -WhatIf:$WhatIf.IsPresent

    if ($Decision -eq $true) {
        Start-ConversionProcess -Path $Path `
            -EOL $EOL `
            -IgnoreHashTable $IgnoreHashTable `
            -ExportReportData:$ExportReportData.IsPresent `
            -WhatIf:$WhatIf.IsPresent
    }
    else {
        Write-Output -InputObject "Operation has been cancelled, no files have been modified."
    }
}

function Import-GitIgnoreFile {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path
    )
    # TODO: if $Exclude contains a .gitignore file (perhaps nested module repo) it needs to be ignored in this method 
    try {
        
        $IgnoreFile = Get-ChildItem -Path . -Recurse -Depth 3 -Filter ".gitignore" | Select-Object -First 1
        
        # TODO: Import-GitIgnoreFile is only called for with path being a folder. Get-ParentItem 
        # will be benefical if user drills into a specific dir but still needs the repo .gitignore
        <#
        else {
            $Path | Get-ItemPropertyValue -Name DirectoryName
            $IgnoreFile = Get-ParentItem -Path $Path -Name '.gitignore' -Recurse
        }#>

        $GitIgnoreContents = $IgnoreFile | `
            Get-Content | `
            Where-Object {($_ -match '\S+') -and ($_.StartsWith('#') -ne $true)}

        if ($IgnoreFile) {
            Write-Host ("Imported and will be using the following ignore file: " + $IgnoreFile.FullName)
        }

        $GitIgnoreContents
    }
    catch {
        Write-Error "An error occurred with importing and parsing .gitignore file."
    }
}

function New-IgnoreHashTable {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Contents
    )

    # since .git folder is not listed in .gitignore, add it here
    $Contents += '.git/'
    $FolderEntries = @()
    $FileEntries = @()
    
    Write-Verbose ("Starting to parse excluded items")

    $Contents | ForEach-Object {
        # global - if matches '*.html'
        if (($_ -match '(?<=\*)[\~\-\.\w]+') -or ($_ -match '(?<!\*)[\~\-\.\w]+(?=\*)')) {
            Write-Verbose ("  Determined the following is global file: " + $_)
            $FileEntries += $_
        }
        # relative - log.txt | LICENSE | .gitignore | main.test.ts
        elseif ($_ -match '(?<=^)[\~\-\.\w]+(?=$)') {
            if (Test-Path $_ -PathType Leaf -ErrorAction SilentlyContinue) {
                Write-Verbose ("  Determined the following is relative file: " + $_)
                $FileEntries += $_
            }
        }
        # relative - if matches '.\index-UTF16BE-CRLF-NoBOM-NoXtraLine.html'
        elseif ($_ -match '(?<=\\)[\~\-\.\w]+[.?\w]+') {
            if (Test-Path $_ -PathType Leaf -ErrorAction SilentlyContinue) {
                Write-Verbose ("  Determined the following is relative file: " + $_)
                $FileEntries += $Matches.Values
            }
            elseif (Test-Path $_ -PathType Container -ErrorAction SilentlyContinue) {
                Write-Verbose ("  Determined the following is relative folder: " + $_)
                $FolderEntries += $Matches.Values.TrimEnd('/')
            }
        }
        # relative - if matches 'out/**' | '.vscode/**' | out/www/**
        # -or
        # relative - .\resources\ | .\.vscode\ | .vscode/
        elseif (($_ -match '\.?[(\\|\/)\~\-\.\w]+(?=(?:\\|\/)\*{0,2})') -or ($_ -match '(?<=\\)\.?[\~\-\.\w]+[.?\w]+(?=\\)')) {
            $EntryCandidate = $_.TrimEnd('**').TrimEnd('/')
            # is this a sub-path entry?
            if ($_ -match '[\~\-\.\w]+[\\|\/][\~\-\.\w]+') {
                # if so does it exist?
                if (Test-Path $EntryCandidate -PathType Container -ErrorAction SilentlyContinue) {
                    Write-Verbose ("  Determined the following is a subpath folder: " + $_)
                    $FolderEntries += $EntryCandidate
                }
            }
            elseif (Test-Path $EntryCandidate -PathType Container -ErrorAction SilentlyContinue) {
                Write-Verbose ("  Determined the following is relative folder: " + $_)
                $FolderEntries += $EntryCandidate
            }
        }
        # global - if matches '**\tests' | '**/tests'
        elseif ($_ -match '(?<=\* {2}(?:\\|\/))[\~\-\.\w]+') {
            Write-Verbose ("  Determined the following is global folder: " + $_)
            $FolderEntries += $_.TrimEnd('/')
        }
        else {
            Write-Verbose ("  Undetermined item: " + $_)
        }
    }
    Write-Verbose ("Finished parsing excluded items")
    
    $IgnoreHashTable = @{
        FolderEntries = $FolderEntries
        FileEntries   = $FileEntries
    }
    $IgnoreHashTable
}

function New-ConfirmationMessage {
    [CmdletBinding()]
    Param
    (
        [ValidateSet("LF", "CRLF")]
        [string]$EOL,

        [switch]$WhatIf
    )
    
    if ($WhatIf.IsPresent -eq $false) {
        $ConfirmationMessage = @"
You have requested to convert all files to ${EOL} end-of-line (EOL) characters."
"@
    }
    else {
        $ConfirmationMessage = @"
You have requested to see what files will be converted to ${EOL} end-of-line (EOL) characters."
"@
    }

    $ConfirmationMessage
}

function Request-Confirmation {
    Param
    (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Message,

        [switch]$WhatIf
    )
    
    if ($WhatIf.IsPresent -eq $false) {
        $Question = "Do you want to proceed in modifying file(s)?"
    }
    else {
        $Question = "Since 'WhatIf' has been switched, do you want to see what file(s) would have been modified?"
    }

    $Yes = [System.Management.Automation.Host.ChoiceDescription]::new("&Yes")
    $Yes.HelpMessage = "Executes operation"
    $No = [System.Management.Automation.Host.ChoiceDescription]::new("&No")
    $No.HelpMessage = "Aborts operation"

    if ($script:SUT -eq $false) {
        [bool]$Decision = !($Host.UI.PromptForChoice($Message, $Question, @($Yes, $No), 1))
    }
    else {
        [bool]$Decision = $true
    }

    $Decision
}

function Start-ConversionProcess {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [Parameter(Mandatory = $false)]
        [object[]]$IgnoreHashTable,

        [ValidateSet("LF", "CRLF")]
        [string]$EOL,

        [switch]$ExportReportData,

        [switch]$WhatIf
    )
    
    try {
        $script:ReportCollection = @()

        Push-Location
      
        if (($Path | Test-Path) -eq $false) {
            if ($Path | Test-Path -PathType Container -IsValid) {
                throw [System.IO.DirectoryNotFoundException]::new()
            }
            elseif ($Path | Test-Path -PathType Leaf -IsValid) {
                throw [System.IO.FileNotFoundException]::new()
            }
            else {
                throw [System.IO.IOException]::new() 
            }
        }
        else {
            if ($Path | Test-Path -PathType Container) {
                Invoke-RecurseFolders -Path $Path[0] `
                    -EOL $EOL `
                    -IgnoreHashTable $IgnoreHashTable `
                    -WhatIf:$WhatIf.IsPresent
            }
            else {
                $script:ReportCollection += Get-FileObject `
                    -FilePath $Path[0] `
                    -EOL $EOL `
                    -WhatIf:$WhatIf.IsPresent | `
                    Write-File | `
                    Out-ReportData
            }
        }

        Pop-Location
        
        if ($ExportReportData.IsPresent -eq $false) {
            Format-ReportTable -EOL $EOL -WhatIf:$WhatIf.IsPresent
        }
        else {
            $script:ReportCollection
        }
    }
    catch [System.IO.DirectoryNotFoundException] {
        Write-Error -Message ("The following directory cannot be found: $Path")
        Pop-Location
    }
    catch [System.IO.FileNotFoundException] {
        Write-Error -Message ("The following file cannot be found: $Path")
        Pop-Location
    }
    catch [System.IO.IOException] {
        Write-Error -Message ("The following is invalid: $Path")
        Pop-Location
    }
}

# NOTE: Algorithm by Brian Nadjiwon:
# https://social.technet.microsoft.com/Forums/windowsserver/en-US/71a473c7-7cee-4c48-ab02-491703aa1f5f/getchilditem-with-millions-of-files
# 
function Invoke-RecurseFolders {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [string]$Path,
        
        [ValidateSet("LF", "CRLF")]
        [string]$EOL,

        [Parameter(Mandatory = $false)]
        [object[]]$IgnoreHashTable,

        [switch]$WhatIf
    )

    Set-Location -Path $Path
    # HACK: when -File and -Exclude are switched on Get-ChildItem, it doesnt return 
    # anything; hence the piped Where-Object to determine if its a file.  This
    # seems to be fixed in PowerShell Core 6.0.0
    #
    # https://github.com/PowerShell/PowerShell/issues/5699
    # https://github.com/PowerShell/PowerShell/pull/5896
    #
    [string[]]$Files = Get-ChildItem . -Exclude $IgnoreHashTable.FileEntries | Where-Object {$_.PSIsContainer -eq $false}
    ForEach ($File in $Files) {
        $script:ReportCollection += Get-FileObject `
            -FilePath $File `
            -EOL $EOL `
            -WhatIf:$WhatIf.IsPresent | `
            Write-File | `
            Out-ReportData
    }

    $RevisedFolderEntries = @()
    if ($IgnoreHashTable.FolderEntries.Length) {
        $IgnoreHashTable.FolderEntries | Foreach-Object {
            # this 'if' are for subpaths only, and check to see if we 
            # are at base directory.  If so, extract that base directory 
            # name and add in $RevisedFolderEntries 
            if ($_ -match '[\~\-\.\w]+[\\|\/][\~\-\.\w]+') {
                $($_ -match '[\~\-\.\w]+$') | Out-Null
                if (Test-Path $Matches[0]) {
                    $RevisedFolderEntries += $Matches[0]
                }
            }
            elseif (Test-Path $_) {
                $RevisedFolderEntries += $_
            }
        }
    }

    [string[]]$Folders = Get-ChildItem . -Exclude $RevisedFolderEntries | Where-Object {$_.PSIsContainer -eq $true}
    ForEach ($Folder in $Folders) {
        Invoke-RecurseFolders -Path $Folder `
            -EOL $EOL `
            -IgnoreHashTable $IgnoreHashTable `
            -WhatIf:$WhatIf.IsPresent

        Set-Location -Path '..'
    }
}

function Format-ReportTable {
    [CmdletBinding()]
    Param
    (
        [ValidateSet("LF", "CRLF")]
        [string]$EOL,

        [switch]$WhatIf
    )
    
    if ($script:ReportCollection.Count -gt 0) {
        $ModifiedCount = 0
        $script:ReportCollection | ForEach-Object {
            if ($_.Modified) {
                $ModifiedCount++
            }
        }
 
        if ($WhatIf.IsPresent) {
            $ColHeaderForModified = "Would be Modified    "
            $SummaryMessage = "A total of '$ModifiedCount' files would have been modified with " + $EOL + " end-of-line (EOL) characters."
        }
        else {
            $ColHeaderForModified = "Modified    "
            $SummaryMessage = "A total of '$ModifiedCount' files has been modified with " + $EOL + " end-of-line (EOL) characters."
        }

        $script:ReportCollection | `
            Sort-Object -property `
        @{Expression = "Modified"; Descending = $true}, `
        @{Expression = "FilePath"; Descending = $false} | `
            Format-Table `
        @{Label = "Name    "; Expression = {($_.FilePath)}}, `
        @{Label = $ColHeaderForModified; Expression = {($_.Modified)}; Alignment = "Left"}, `
        @{Label = "Reason Not Modified    "; Expression = {
                if ($_.EmptyFile) {
                    "File is empty"
                }
                elseif ($_.EncodingNotCompatiable) {
                    $mesg = "Encoding is not compatiable"
                    if ($_.FileEncoding) {
                        $mesg += " - " + $_.FileEncoding
                    }
                    $mesg
                }
                elseif ($_.SameEOLAsRequested) {
                    "Same EOL as requested"
                }
            } ; Alignment = "Left"
        } -AutoSize
    }
    else {
        if ($WhatIf.IsPresent) {
            $SummaryMessage = @"

No files would have been modified with $EOL end-of-line (EOL) characters.
"@
        }
        else {
            $SummaryMessage = @"

No files has been modified with $EOL end-of-line (EOL) characters.
"@
        }
    }
    Write-Host $SummaryMessage
}

function Get-FileObject {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [ValidateSet("LF", "CRLF")]
        [string]$EOL,
        
        [switch]$WhatIf
    )

    $Data = [PsCustomObject]@{
        EOL                    = $EOL
        FilePath               = ''
        FileItem               = $null
        FileContent            = ''
        FileEOL                = ''
        FileEncoding           = $null
        EncodingNotCompatiable = $false
        SameEOLAsRequested     = $false
        EmptyFile              = $false
        EndsWithEmptyNewLine   = $false
        Modified               = $false
        WhatIf                 = $WhatIf.IsPresent
    }
    
    Write-Verbose ("Opening: " + $FilePath)
    $Data.FilePath = Resolve-Path $FilePath -Relative
    $Data.FileItem = Get-Item -Path $FilePath
    $Data.EmptyFile = $Data.FileItem.Length -eq 0

    if ($Data.EmptyFile -eq $false) {
        # unicode: U+000D | byte (decimal): 13 | html: \r\n | powershell: `r`n
        [byte]$CR = 0x0D
        # unicode: U+000A | byte (decimal): 10 | html: \n | powershell: `n
        [byte]$LF = 0x0A
        # TODO: would be nice to pipe StreamReader into Test-Encoding...
        $Data.EncodingNotCompatiable = !(Test-Encoding -Path $Data.FileItem.FullName 'utf8')

        if ($Data.EncodingNotCompatiable -eq $false) {

            $StreamReader = New-Object -TypeName System.IO.StreamReader -ArgumentList $Data.FileItem.FullName
            
            $Data.FileEncoding = $StreamReader.CurrentEncoding
            
            if ($Data.FileEncoding -is [System.Text.UTF8Encoding]) {
            
                $Data.FileContent = $StreamReader.ReadToEnd()
            
                $FileAsBytes = [System.Text.Encoding]::UTF8.GetBytes($Data.FileContent)
                $FileAsBytesLength = $FileAsBytes.Length
            }

            $IndexOfLF = $FileAsBytes.IndexOf($LF)
            if (($IndexOfLF -ne -1) -and ($FileAsBytes[$IndexOfLF - 1] -ne $CR)) {
                $Data.FileEOL = 'LF'
                if ($FileAsBytesLength) {
                    $Data.EndsWithEmptyNewLine = ($FileAsBytes.Get($FileAsBytesLength - 1) -eq $LF) -and `
                    ($FileAsBytes.Get($FileAsBytesLength - 2) -eq $LF)
                }

                $Data.SameEOLAsRequested = $Data.FileEOL -eq $Data.EOL
            }
            elseif (($IndexOfLF -ne -1) -and ($FileAsBytes[$IndexOfLF - 1] -eq $CR)) {
                $Data.FileEOL = 'CRLF'
                if ($FileAsBytesLength) {
                    $Data.EndsWithEmptyNewLine = ($FileAsBytes.Get($FileAsBytesLength - 1) -eq $LF) -and `
                    ($FileAsBytes.Get($FileAsBytesLength - 3) -eq $LF)
                }

                $Data.SameEOLAsRequested = $Data.FileEOL -eq $Data.EOL
            }
            else {
                $Data.FileEOL = 'unknown'
            }
            
            $StreamReader.Close()
        }
    }

    $Data
}

function Write-File {
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline = $true)]
        [PSCustomObject]$Data
    )

    if (($Data.SameEOLAsRequested -eq $false) -and `
        ($Data.EmptyFile -eq $false) -and `
        ($Data.EncodingNotCompatiable -eq $false)) {
 
        if ($Data.WhatIf -eq $false) {
            New-Object -TypeName System.IO.StreamWriter -ArgumentList $Data.FileItem.FullName -OutVariable StreamWriter | Out-null

            if ($Data.EOL -eq 'LF') {
                $Data.FileContent = $Data.FileContent -replace "`r", ""
                if ($Data.EndsWithEmptyNewLine) {
                    $Data.FileContent + "`n"
                }
            }
            elseif ($Data.EOL -eq 'CRLF') {
                $Data.FileContent = $Data.FileContent -replace "`n", "`r`n"
                if ($Data.EndsWithEmptyNewLine) {
                    $Data.FileContent + "`r`n"
                }
            }

            try {
                $StreamWriter.Write($Data.FileContent)
                $StreamWriter.Flush()
                $StreamWriter.Close()
            }
            catch {
                Write-Error ("EndOfLine threw an exception when writing to: " + $Data.FileItem.FullName)
            }
        }
        $Data.Modified = $true
    }
    # free-up memory; no longer need FileContent data
    $Data.FileContent = '[removed]'
    
    $Data
}

function Out-ReportData {
    [CmdletBinding()]
    Param 
    (
        [Parameter(ValueFromPipeline = $true)]
        [PSCustomObject]$Data
    )

    if ($Data.Modified -eq $true) {
        if ($Data.WhatIf -eq $false) {
            Write-Verbose ("  Modifying file")
        }
        else {
            Write-Verbose ("  Would have modified file")
        }
    }
    else {
        if ($Data.EmptyFile) {
            Write-Verbose ("  This file has been excluded since it is empty.") 
        }
        elseif ($Data.SameEOLAsRequested) {
            Write-Verbose ("  This file has been excluded since the end-of-line characters are the same as requested to convert.") 
        }
        elseif ($Data.EncodingNotCompatiable) {
            Write-Verbose ("  This file has been excluded since it is not UTF-8 encoded.")
        }
    }

    Write-Verbose ("Closing file")

    $Data
}

Export-ModuleMember -Function ConvertTo-LF
Export-ModuleMember -Function ConvertTo-CRLF
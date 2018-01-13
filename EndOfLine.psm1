$SummaryTable = @{}

function ConvertTo-LF {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [switch]$SkipIgnoreFile,

        [switch]$WhatIf
    )

    if ($SkipIgnoreFile.IsPresent -eq $false) {
       $IgnoreTable = Import-GitIgnoreFile $Path -WhatIf:$WhatIf.IsPresent
    }

    $ConfirmationMessage = New-ConfirmationMessage -EOL "LF" -WhatIf:$WhatIf.IsPresent
    $Decision = Request-Confirmation -Message $ConfirmationMessage -WhatIf:$WhatIf.IsPresent

    if ($Decision -eq $True) {
        Start-ConversionProcess -Path $Path -EOL "LF" -IgnoreTable $IgnoreTable -WhatIf:$WhatIf.IsPresent
    }
    else {
        Write-Output -InputObject 'Procedure has been cancelled, no files have been modified.'
    }
}

function ConvertTo-CRLF {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [switch]$SkipIgnoreFile,
        
        [switch]$WhatIf
    )

    if ($SkipIgnoreFile.IsPresent -eq $false) {
       $IgnoreTable = Import-GitIgnoreFile $Path -WhatIf:$WhatIf.IsPresent
    }

    $ConfirmationMessage = New-ConfirmationMessage -EOL "CRLF" -WhatIf:$WhatIf.IsPresent
    $Decision = Request-Confirmation -Message $ConfirmationMessage -WhatIf:$WhatIf.IsPresent

    if ($Decision -eq $True) {
        Start-ConversionProcess -Path $Path -EOL "CRLF" -IgnoreTable $IgnoreTable -WhatIf:$WhatIf.IsPresent
    }
    else {
        Write-Output -InputObject 'Procedure has been cancelled, no files have been modified.'
    }
}

function New-ConfirmationMessage {
    [CmdletBinding()]
    Param
    (
        [ValidateSet("LF", "CRLF")]
        [string]$EOL,

        [switch]$WhatIf
    )
    
    if ($WhatIf.IsPresent -eq $False) {
        $ConfirmationMessage = @"
You have requested to convert all files to ${EOL} end-of-line (EOL) markings."
"@
    }
    else {
        $ConfirmationMessage = @"
You have requested to see what files will be converted to ${EOL} end-of-line (EOL) markings."
"@
    }

    $ConfirmationMessage
}

function Start-ConversionProcess {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [Parameter(Mandatory = $False)]
        [string[]]$IgnoreTable,

        [ValidateSet("LF", "CRLF")]
        [string]$EOL,

        [switch]$WhatIf


    )
    
    try {
        if ((Test-Path $Path) -eq $False) {
            if (Test-Path -PathType Container -IsValid) {
                throw [System.IO.DirectoryNotFoundException]::new()
            }
            elseif (Test-Path -PathType Leaf -IsValid) {
                throw [System.IO.FileNotFoundException]::new()
            }
            else {
                throw [System.IO.IOException]::new() 
            }
        }

        $IsContainer = Resolve-Path $Path | Test-Path -IsValid -PathType Container
        
        if ($IsContainer -eq $True) {
            Get-ChildItem -Path $Path -Recurse | ForEach-Object -Process {
                if ($_.PSIsContainer -eq $False) {
                    Get-FileObject -FilePath $_.FullName -EOL $EOL -IgnoreTable $IgnoreTable -WhatIf:$WhatIf.IsPresent | `
                        Write-File  | Write-Summary
                }
            }
        }
        else {
            Get-FileObject -FilePath $_.FullName -EOL $EOL -WhatIf:$WhatIf.IsPresent | `
                Write-File  | Write-Summary
        }

        Format-SummaryTable -WhatIf:$WhatIf.IsPresent
        # clear tables to be used again in session and free memory...
        $IgnoreTable = ''
        $SummaryTable.Clear()
    }
    catch [System.IO.DirectoryNotFoundException] {
        Write-Error -Message ("The following directory cannot be found: $Path")
    }
    catch [System.IO.FileNotFoundException] {
        Write-Error -Message ("The following file cannot be found: $Path")
    }
    catch [System.IO.IOException] {
        Write-Error -Message ("The following is invalid: $Path")
    }
    catch {
        Write-Error -Message ("An error occurred when attempting to convert the following target: $Path")
    }
}

function Set-SummaryTable {
    Param
    (
        [Parameter(Mandatory = $True)]
        [string]$FileExtension,

        [Parameter(Mandatory = $True)]
        [bool]$Modified
    )
    # TODO: perhaps Group-Object can be used in here
    if ($SummaryTable.ContainsKey($FileExtension) -eq $True) {
        ($SummaryTable[$FileExtension].Count)++
    }
    else {
        $YesNo = if ($Modified -eq $True) {'Yes'} else {'No'}
        $NewEntry = [PSCustomObject]@{Count = 1; Modified = $YesNo}
        $SummaryTable.Add($FileExtension, $NewEntry)
    }
}

function Format-SummaryTable {
    [CmdletBinding()]
    Param
    (
        [switch]$WhatIf
    )
    
    if ($WhatIf.IsPresent) {
        Write-Output @"

Since the 'WhatIf' was switched, below is the what would of happened summary:
"@
    }
    Format-Table @{Label = "Found Files"; Expression = {($_.Name)}}, `
    @{Label = "Count"; Expression = {($_.Value.Count)}}, `
    @{Label = "Modified"; Expression = {($_.Value.Modified)}}`
        -AutoSize -InputObject $SummaryTable
}

function Request-Confirmation {
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Message,

        [switch]$WhatIf
    )
    
    if ($WhatIf.IsPresent -eq $false) {
        $Question = 'Do you want to proceed in modifying file(s)?'
    }
    else {
        $Question = 'Do you want to simulate what will happen?'
    }

    $Choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
    $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&Yes"))
    $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&No"))

    [bool]$Decision = !($Host.UI.PromptForChoice($Message, $Question, $Choices, 1))
    
    $Decision
}

function Get-FileObject {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [string]$FilePath,

        [Parameter(Mandatory = $True)]
        [ValidateSet("LF", "CRLF")]
        [string]$EOL,

        [Parameter(Mandatory = $False)]
        $IgnoreTable,
        
        [switch]$WhatIf
    )

    $Data = [PsObject]@{
        EOL                  = $EOL
        FileItem             = $null
        FileAsString         = ''
        FileEOL              = ''
        IgnoredFilePath      = ''
        Encoding             = $null
        EndsWithEmptyNewLine = $false
        WhatIf               = $WhatIf.IsPresent
    }

    if ($IgnoreTable.Count) {
        $Data.FileItem = Get-Item -Path $FilePath -Exclude $IgnoreTable
        if (!$Data.FileItem) {
            $Data.IgnoredFilePath = $FilePath
        }
    }
    else {
        $Data.FileItem = Get-Item -Path $FilePath
    }

    if ($Data.FileItem) {
        New-Object -TypeName System.IO.StreamReader -ArgumentList $Data.FileItem.FullName -OutVariable StreamReader | Out-Null

        $Data.FileAsString = $StreamReader.ReadToEnd();
        $StreamReader.Dispose()

        [byte]$CR = 0x0D # 13  or  \r\n  or  `r`n
        [byte]$LF = 0x0A # 10  or  \n    or  `n
        $FileAsBytes = [System.Text.Encoding]::ASCII.GetBytes($Data.FileAsString)
        $FileAsBytesLength = $FileAsBytes.Length

        $IndexOfLF = $FileAsBytes.IndexOf($LF)
        if (($IndexOfLF -ne -1) -and ($FileAsBytes[$IndexOfLF - 1] -ne $CR)) {
            $Data.FileEOL = 'LF'
            if ($FileAsBytesLength) {
                $Data.EndsWithEmptyNewLine = ($FileAsBytes.Get($FileAsBytesLength - 1) -eq $LF) -and `
                ($FileAsBytes.Get($FileAsBytesLength - 2) -eq $LF)
            }
        }
        elseif (($IndexOfLF -ne -1) -and ($FileAsBytes[$IndexOfLF - 1] -eq $CR)) {
            $Data.FileEOL = 'CRLF'
            if ($FileAsBytesLength) {
                $Data.EndsWithEmptyNewLine = ($FileAsBytes.Get($FileAsBytesLength - 1) -eq $LF) -and `
                ($FileAsBytes.Get($FileAsBytesLength - 3) -eq $LF)
            }
        }
        else {
            $Data.FileEOL = 'unknown'
        }
    }

    $Data
}

function Write-File {
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline = $True)]
        [PsObject]$Data
    )

    # If running in destructive mode (not in WhatIf) pass just the FullName to StreamWriter.
    # If running in destructive mode then it MUST have $True passed-in as second parameter 
    # which signifies to append.  Otherwise it will delete all contents of file.
    if ($Data.FileItem) {
        if (!$Data.WhatIf) {
            $StreamWriterArguments = $Data.FileItem.FullName
        }
        else {
            $StreamWriterArguments = @($Data.FileItem.FullName, $True)
        }
        New-Object -TypeName System.IO.StreamWriter -ArgumentList $StreamWriterArguments -OutVariable StreamWriter | Out-Null

        $Data.Encoding = $StreamWriter.Encoding

        if ($Data.Encoding -is [System.Text.UTF8Encoding]) {
            # if $Data.EOL equals 'CRLF' we shouldnt have to do anything since 
            # PowerShell defaults to the same EOL markings (at least on Windows).
            # but if this file has lone LF endings, edit $HeaderPrependedToFileString
            # to have just LF endings too. 
            #
            # Although the following may be benefical here in some environments:
            #  $OutputEncoding
            #  $OFS = $Info.LineEnding
            #  $StreamWriter.NewLine = $True (although, this is a get/set prop PowerShell
            #       cant set it)
            #  $TextWriter.CoreNewLine (StreamWriter inherits from this class)
            if ($Data.EOL -eq 'LF') {
                $Data.FileAsString = $Data.FileAsString -replace "`r", ""
                if ($Data.EndsWithEmptyNewLine) {
                    $Data.FileAsString + "`n"
                }
            }
            elseif ($Data.EOL -eq 'CRLF') {
                $Data.FileAsString = $Data.FileAsString -replace "`r`n", ""
                if ($Data.EndsWithEmptyNewLine) {
                    $Data.FileAsString + "`r`n"
                }
            }

            try {
                if (!$Data.WhatIf) {
                    $StreamWriter.Write($Data.FileAsString)
                }
            
                $StreamWriter.Flush()
                $StreamWriter.Close()
            }
            catch {
                Write-Error ("EndOfLine threw an exception when writing to: " + $Data.FileItem.FullName)
            }
        }
    }

    $Data
}

function Write-Summary {
    [CmdletBinding()]
    Param 
    (
        [Parameter(ValueFromPipeline = $True)]
        [PsObject]$Data
    )

    # for files that dont have a file extension
    if ($Data.FileItem -and $Data.FileItem.Extension) {
        $SummaryTableKey = $Data.FileItem.Extension
    }
    elseif ($Data.FileItem) {
        $SummaryTableKey = $Data.FileItem.Name
    }
    else {
        if ($Data.IgnoredFilePath -match '\.\w+$') {
            $SummaryTableKey = $Matches[0]
        }
    }

    if (($Data.Encoding -is [System.Text.UTF8Encoding]) -and ($Data.FileEOL -ne $Data.EOL)) {
        $Modifiable = $True
    }
    else {
        $Modifiable = $False
    }
    
    Set-SummaryTable -FileExtension $SummaryTableKey -Modified $Modifiable

    if ($Data.IgnoredFilePath) {
        Write-Verbose ("This file has been excluded per ignore file: " + $Data.IgnoredFilePath)
    }
    elseif ($Data.Encoding -isnot [System.Text.UTF8Encoding]) {
        Write-Verbose ("This file has been excluded since it is not UTF-8 encoded: " + $Data.FileItem.FullName)
    }
    elseif ($Data.EOL -ne $Data.EOL) {
        Write-Verbose ("This file has been excluded since the line endings are the same as requested to convert to: " + $Data.FileItem.FullName)
    }
}

function Import-GitIgnoreFile {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [switch]$WhatIf
    )

    $Results = Get-ChildItem -Path $Path -Filter ".gitignore" -Recurse -OutVariable IgnoreItem | Get-Content | Where-Object { 
        (($_.length -gt 1) -and ($_.StartsWith('#') -ne $true)) 
    }
    
    if ($Results) {
        Write-Verbose ("Using the following ignore file: " + $IgnoreItem.FullName)
    }

    $Results
}
Export-ModuleMember -Function ConvertTo-LF
Export-ModuleMember -Function ConvertTo-CRLF
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
        Write-Output -InputObject "Operation has been cancelled, no files have been modified."
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
        Write-Output -InputObject "Operation has been cancelled, no files have been modified."
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
        Write-Host ("Imported and will be using the following ignore file: " + $IgnoreItem.FullName)
    }

    $Results
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
        [Parameter(Mandatory = $True, Position = 1)]
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

    [bool]$Decision = !($Host.UI.PromptForChoice($Message, $Question, @($Yes, $No), 1))

    $Decision
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

        $ReportCollection = @()

        $IsContainer = Resolve-Path $Path | Test-Path -IsValid -PathType Container
        
        if ($IsContainer -eq $True) {
            Get-ChildItem -Path $Path -Recurse | ForEach-Object -Process {
                if ($_.PSIsContainer -eq $False) {
                    $ReportData = Get-FileObject -FilePath $_.FullName -EOL $EOL -IgnoreTable $IgnoreTable -WhatIf:$WhatIf.IsPresent | `
                        Write-File  | `
                        Out-ReportData

                    $ReportCollection += $ReportData
                }
            }
        }
        else {
            $ReportData = Get-FileObject -FilePath $_.FullName -EOL $EOL -IgnoreTable $IgnoreTable -WhatIf:$WhatIf.IsPresent | `
                Write-File  | `
                Out-ReportData

            $ReportCollection += $ReportData
        }

        Format-ReportTable -WhatIf:$WhatIf.IsPresent -ReportCollection $ReportCollection
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
}

function Format-ReportTable {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        $ReportCollection,

        [switch]$WhatIf
    )
    
    $ModifiedCount = 0
    $ReportCollection | ForEach-Object {
        if ($_.Modified) {
            $ModifiedCount++
        }
    }
 
    if ($WhatIf.IsPresent) {
        $ColHeaderForModified = "Would be Modified    "
        $SummaryMessage = "A total of '$ModifiedCount' files would have been modified."
    }
    else {
        $ColHeaderForModified = "Modified    "
        $SummaryMessage = "A total of '$ModifiedCount' files has been modified."
    }

    $ReportCollection | `
        Sort-Object -property `
    @{Expression = "Modified"; Descending = $true}, `
    @{Expression = "FilePath"; Descending = $false} | `
        Format-Table `
    @{Label = "Name    "; Expression = {($_.FilePath)}}, `
    @{Label = $ColHeaderForModified; Expression = {($_.Modified)}; Alignment = "Left"}, `
    @{Label = "Reason Not Modified    "; Expression = {
            if ($_.ExcludedFromIgnoreFile) {
                "Excluded by ignore file"
            }
            elseif ($_.EncodingNotCompatiable) {
                "Encoding not compatiable"
            }
            elseif ($_.SameEOLAsRequested) {
                "Same EOL as requested"
            }
        } ; Alignment = "Left"
    } -AutoSize

    Write-Host $SummaryMessage
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

    $Data = [PsCustomObject]@{
        EOL                    = $EOL
        FilePath               = ''
        FileItem               = $null
        FileContent            = ''
        FileEOL                = ''
        FileEncoding           = $null
        ExcludedFromIgnoreFile = $false
        EncodingNotCompatiable = $false
        SameEOLAsRequested     = $false
        EndsWithEmptyNewLine   = $False
        Modified               = $False
        WhatIf                 = $WhatIf.IsPresent
    }
    
    Write-Verbose ("Opening: " + $FilePath)
    
    $Data.FilePath = Resolve-Path $FilePath -Relative

    if ($IgnoreTable.Count) {
        $Data.FileItem = Get-Item -Path $FilePath -Exclude $IgnoreTable
        if (!$Data.FileItem) {
            $Data.ExcludedFromIgnoreFile = $true
        }
    }
    else {
        $Data.FileItem = Get-Item -Path $FilePath
    }

    if ($Data.FileItem) {
        New-Object -TypeName System.IO.StreamReader -ArgumentList $Data.FileItem.FullName -OutVariable StreamReader | Out-Null

        $Data.FileContent = $StreamReader.ReadToEnd();
        $StreamReader.Dispose()

        [byte]$CR = 0x0D # 13  or  \r\n  or  `r`n
        [byte]$LF = 0x0A # 10  or  \n    or  `n
        $FileAsBytes = [System.Text.Encoding]::ASCII.GetBytes($Data.FileContent)
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

        $Data.SameEOLAsRequested = $Data.FileEOL -eq $Data.EOL
    }

    $Data
}

function Write-File {
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline = $True)]
        [PSCustomObject]$Data
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

        $Data.FileEncoding = $StreamWriter.Encoding
        $Data.EncodingNotCompatiable = ($Data.FileEncoding -isnot [System.Text.UTF8Encoding])

        if (($Data.EncodingNotCompatiable -eq $false) -and ($Data.SameEOLAsRequested -eq $false)) {
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
                $Data.FileContent = $Data.FileContent -replace "`r", ""
                if ($Data.EndsWithEmptyNewLine) {
                    $Data.FileContent + "`n"
                }
            }
            elseif ($Data.EOL -eq 'CRLF') {
                $Data.FileContent = $Data.FileContent -replace "`r`n", ""
                if ($Data.EndsWithEmptyNewLine) {
                    $Data.FileContent + "`r`n"
                }
            }

            try {
                if (!$Data.WhatIf) {
                    $StreamWriter.Write($Data.FileContent)
                }
                    
                # free memory; no longer need FileContent data
                $Data.FileContent = ''
                $Data.Modified = $True
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

function Out-ReportData {
    [CmdletBinding()]
    Param 
    (
        [Parameter(ValueFromPipeline = $True)]
        [PSCustomObject]$Data
    )

    if ($Data.Modified -eq $True) {
        if ($Data.WhatIf -eq $False) {
            Write-Verbose ("  Modifying file")
        }
        else {
            Write-Verbose ("  Would have modified file")
        }
    }
    else {
        if ($Data.ExcludedFromIgnoreFile) {
            Write-Verbose ("  This file has been excluded per ignore file: " + $Data.FilePath)
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
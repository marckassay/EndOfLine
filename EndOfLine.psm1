function ConvertTo-LF {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotnullOrEmpty()]
        [string[]]$Path,

        [switch]$SkipIgnoreFile,

        [switch]$ExperimentalEncodingConversion,

        [switch]$WhatIf
    )

    if ($SkipIgnoreFile.IsPresent -eq $false) {
        $IgnoreTable = Import-GitIgnoreFile $Path -WhatIf:$WhatIf.IsPresent
    }

    $ConfirmationMessage = New-ConfirmationMessage -EOL "LF" -WhatIf:$WhatIf.IsPresent
    $Decision = Request-Confirmation -Message $ConfirmationMessage -WhatIf:$WhatIf.IsPresent

    if ($Decision -eq $true) {
        Start-ConversionProcess -Path $Path -EOL "LF" -IgnoreTable $IgnoreTable `
            -ExperimentalEncodingConversion:$ExperimentalEncodingConversion.IsPresent -WhatIf:$WhatIf.IsPresent
    }
    else {
        Write-Output -InputObject "Operation has been cancelled, no files have been modified."
    }
}

function ConvertTo-CRLF {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotnullOrEmpty()]
        [string[]]$Path,

        [switch]$SkipIgnoreFile,
        
        [switch]$ExperimentalEncodingConversion,

        [switch]$WhatIf
    )

    if ($SkipIgnoreFile.IsPresent -eq $false) {
        $IgnoreTable = Import-GitIgnoreFile $Path -WhatIf:$WhatIf.IsPresent
    }

    $ConfirmationMessage = New-ConfirmationMessage -EOL "CRLF" -WhatIf:$WhatIf.IsPresent
    $Decision = Request-Confirmation -Message $ConfirmationMessage -WhatIf:$WhatIf.IsPresent

    if ($Decision -eq $true) {
        Start-ConversionProcess -Path $Path -EOL "CRLF" -IgnoreTable $IgnoreTable `
            -ExperimentalEncodingConversion:$ExperimentalEncodingConversion.IsPresent -WhatIf:$WhatIf.IsPresent
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
        [ValidateNotnullOrEmpty()]
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

    [bool]$Decision = !($Host.UI.PromptForChoice($Message, $Question, @($Yes, $No), 1))

    $Decision
}

function Start-ConversionProcess {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotnullOrEmpty()]
        [string[]]$Path,

        [Parameter(Mandatory = $false)]
        [string[]]$IgnoreTable,

        [ValidateSet("LF", "CRLF")]
        [string]$EOL,

        [switch]$ExperimentalEncodingConversion,

        [switch]$WhatIf
    )
    
    try {
        if ((Test-Path $Path) -eq $false) {
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
        
        if ($IsContainer -eq $true) {
            Get-ChildItem -Path $Path -Recurse | ForEach-Object -Process {
                if ($_.PSIsContainer -eq $false) {
                    $ReportData = Get-FileObject -FilePath $_.FullName -EOL $EOL -IgnoreTable $IgnoreTable `
                        -ExperimentalEncodingConversion:$ExperimentalEncodingConversion.IsPresent -WhatIf:$WhatIf.IsPresent | `
                        Write-File  | `
                        Out-ReportData

                    $ReportCollection += $ReportData
                }
            }
        }
        else {
            $ReportData = Get-FileObject -FilePath $_.FullName -EOL $EOL -IgnoreTable $IgnoreTable `
                -ExperimentalEncodingConversion:$ExperimentalEncodingConversion.IsPresent -WhatIf:$WhatIf.IsPresent | `
                Write-File  | `
                Out-ReportData

            $ReportCollection += $ReportData
        }

        Format-ReportTable -EOL $EOL -ReportCollection $ReportCollection -WhatIf:$WhatIf.IsPresent
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
        [Parameter(Mandatory = $true)]
        [ValidateNotnullOrEmpty()]
        $ReportCollection,

        [ValidateSet("LF", "CRLF")]
        [string]$EOL,

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
        $SummaryMessage = "A total of '$ModifiedCount' files would have been modified with " + $EOL + " end-of-line (EOL) characters."
    }
    else {
        $ColHeaderForModified = "Modified    "
        $SummaryMessage = "A total of '$ModifiedCount' files has been modified with " + $EOL + " end-of-line (EOL) characters."
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
                "Encoding not compatiable - " + $_.FileEncoding.WebName
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
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [ValidateSet("LF", "CRLF")]
        [string]$EOL,

        [Parameter(Mandatory = $false)]
        $IgnoreTable,
        
        [switch]$ExperimentalEncodingConversion,

        [switch]$WhatIf
    )

    $Data = [PsCustomObject]@{
        EOL                            = $EOL
        FilePath                       = ''
        FileItem                       = $null
        FileContent                    = ''
        FileEOL                        = ''
        FileEncoding                   = $null
        ExcludedFromIgnoreFile         = $false
        EncodingNotCompatiable         = $false
        SameEOLAsRequested             = $false
        EndsWithEmptyNewLine           = $false
        Modified                       = $false
        ExperimentalEncodingConversion = $ExperimentalEncodingConversion.IsPresent
        WhatIf                         = $WhatIf.IsPresent
    }
    
    Write-Verbose ("Opening: " + $FilePath)
    # ConvertTo-LF -Path E:\Temp\PSTrueCrypt -WhatIf -ExperimentalEncodingConversion
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

    if ($Data.ExcludedFromIgnoreFile -eq $false) {
        [byte]$CR = 0x0D # 13  or  \r\n  or  `r`n
        [byte]$LF = 0x0A # 10  or  \n    or  `n
      
        New-Object -TypeName System.IO.StreamReader -ArgumentList $Data.FileItem.FullName -OutVariable StreamReader | Out-null

        $Data.FileContent = $StreamReader.ReadToEnd();
        $Data.FileEncoding = $StreamReader.CurrentEncoding;
        $StreamReader.Dispose()

        if ($Data.FileEncoding -is [System.Text.UTF8Encoding]) {
            $Data.EncodingNotCompatiable = $false
            $FileAsBytes = [System.Text.Encoding]::UTF8.GetBytes($Data.FileContent)
            $FileAsBytesLength = $FileAsBytes.Length
        }
        elseif (($Data.ExperimentalEncodingConversion -eq $true) -and ($Data.FileEncoding -is [System.Text.UnicodeEncoding])) {
            $Data.EncodingNotCompatiable = $false
            $FileAsBytes = [System.Text.Encoding]::ASCII.GetBytes($Data.FileContent)
            $FileAsBytesLength = $FileAsBytes.Length
        }
        else {
            $Data.EncodingNotCompatiable = $true
        }
        
        if ($Data.EncodingNotCompatiable -eq $false) {
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

    if (($Data.ExcludedFromIgnoreFile -eq $false) -and `
        ($Data.SameEOLAsRequested -eq $false) -and `
        ($Data.EncodingNotCompatiable -eq $false)) {
 
        if ($Data.WhatIf -eq $false) {
            New-Object -TypeName System.IO.StreamWriter -ArgumentList $Data.FileItem.FullName -OutVariable StreamWriter | Out-null

            # Although the following may be benefical here in some environments:
            #  $OutputEncoding
            #  $OFS = $Info.LineEnding
            #  $StreamWriter.NewLine = $true (although, this is a get/set prop PowerShell
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
                $StreamWriter.Write($Data.FileContent)
                $StreamWriter.Flush()
                $StreamWriter.Close()
            }
            catch {
                Write-Error ("EndOfLine threw an exception when writing to: " + $Data.FileItem.FullName)
            }
        }

        $Data.Modified = $true
        # free-up memory; no longer need FileContent data
        $Data.FileContent = ''
    }
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
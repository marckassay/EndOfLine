#Import-Module "$PSScriptRoot\..\EndOfLine" -Force

<#
.SYNOPSIS
Outputs a file's bytes in decimal and/or binary notation

.DESCRIPTION
Initially created to compare files prior to UTF encoding.

.PARAMETER Path
Path to file.

.PARAMETER Format
Possible values are: DecimalOnly, BinaryOnly, Both

.EXAMPLE
C:\> Get-Bytes E:\marckassay\EndOfLine\test\resource\index-UTF8-CRLF-NoXtraLine.html -Format DecimalOnly
60
104
116
109
108
62
13
10

.EXAMPLE
C:\> $Out = Get-Bytes E:\marckassay\EndOfLine\test\resource\index-UTF8-CRLF-NoXtraLine.html -Format Both
C:\> $Out
60  : 00111100
104 : 01101000
116 : 01110100
109 : 01101101
108 : 01101100
62  : 00111110
13  : 00001101
10  : 00001010

.NOTES
General notes
#>
function Get-Bytes {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet("DecimalOnly", "BinaryOnly", "Both")]
        [string]$Format
    )
    
    # store default Output Field Separator...
    $PRESeparator = $OFS
    $OFS = ''

    if ($Format -eq "DecimalOnly") {
        Get-Item $Path | `
            Get-Content -Raw | `
            ForEach-Object {
            [System.Text.Encoding]::Default.GetBytes($_) 
        } 
    }
    else {
        Get-Item $Path | `
            Get-Content -Raw | `
            ForEach-Object {[System.Text.Encoding]::Default.GetBytes($_)} | `
            ForEach-Object {
            $DecimalByte = $_
            $buffer = [byte[]]::new(8)
            $bufferLength = $buffer.Length - 1

            while ( $bufferLength -ne 0 ) {
                $Q = $DecimalByte % 2
                $buffer[$bufferLength--] = $Q
                $DecimalByte = [Math]::Floor($DecimalByte * .5)
            }

            if ($Format -eq "BinaryOnly") {
                $Output = "$buffer"
            }
            # $Format -eq Both
            else {
                $Output = $_.ToString().PadRight(3) + " : $buffer"
            }
            $Output 
        }
    }

    $OFS = $PRESeparator
}

Describe "Test ConvertTo-LF" {
    BeforeEach {
        if ($(Test-Path -Path "$PSScriptRoot\..\out") -eq $false) {
            New-Item -Path "$PSScriptRoot\..\" -Name out -ItemType Directory -Force -WarningAction SilentlyContinue
        }
        Copy-Item -Path "$PSScriptRoot\resource\index-UTF8-CRLF-NoXtraLine.html" "$PSScriptRoot\..\out" -Force
    }

    AfterEach {
        Remove-Item -Path "$PSScriptRoot\..\out" -Force -Recurse -ErrorAction SilentlyContinue
    }

    It "Given valid -Path '<Path>'" -TestCases @(
        @{ Path                  = "$PSScriptRoot\..\out\index-UTF8-CRLF-NoXtraLine.html"; `
                SkipIgnoreFile   = $true; `
                ExportReportData = $false; `
                WhatIf           = $false `
        
        }) {
        Param($Path, $SkipIgnoreFile, $ExportReportData, $WhatIf)

        $Prior = Get-Bytes -Path $Path -Format DecimalOnly | Select-Object -First 10
        ConvertTo-LF -Path $Path -SkipIgnoreFile:$SkipIgnoreFile -ExportReportData:$ExportReportData -WhatIf:$WhatIf
        $Post = Get-Bytes -Path $Path -Format DecimalOnly | Select-Object -First 10

        $Prior[6] | Should -Be 13
        $Prior[7] | Should -Be 10
        $Prior[8] | Should -Be 13
        $Prior[9] | Should -Be 10

        $Post[6] | Should -Be 10
        $Post[7] | Should -Be 10
        $Post[8] | Should -Be 60
        $Post[9] | Should -Be 104
    }
}
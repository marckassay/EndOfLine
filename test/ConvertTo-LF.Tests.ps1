Import-Module -Name $PSScriptRoot\resource\Get-Bytes -Verbose -Force

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

    Context "with UTF-8, CRLF, No Extra Line file" {
        InModuleScope EndOfLine {
            $script:SUT = $true

            It "Should of removed Unicode 13dec chracters" -TestCases @(
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
    }
}
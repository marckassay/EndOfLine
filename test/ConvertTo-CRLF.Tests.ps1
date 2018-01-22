Import-Module -Name $PSScriptRoot\resource\Get-Bytes -Verbose -Force
Import-Module -Name $PSScriptRoot\..\EndOfLine -Verbose -Force

Describe "Test ConvertTo-CRLF" {
    Context "with UTF-8 LF file" {
        InModuleScope EndOfLine {
            $script:SUT = $true
        
            # Using Pester's TestDrive: https://github.com/pester/Pester/wiki/TestDrive
            Copy-Item -Path "resource\index-UTF8-LF-NoBOM-NoXtraLine.html" -Destination "TestDrive:\"
        
            It "Should of added Unicode 13dec chracters" -TestCases @(
                @{  Path                 = "TestDrive:\index-UTF8-LF-NoBOM-NoXtraLine.html"; `
                        SkipIgnoreFile   = $true; `
                        ExportReportData = $false; `
                        WhatIf           = $false `
                
                }) {
                Param($Path, $SkipIgnoreFile, $ExportReportData, $WhatIf)

                $Prior = Get-Bytes -Path $Path -Format DecimalOnly | Select-Object -First 10
                ConvertTo-CRLF -Path $Path `
                    -SkipIgnoreFile:$SkipIgnoreFile `
                    -ExportReportData:$ExportReportData `
                    -WhatIf:$WhatIf
                $Post = Get-Bytes -Path $Path -Format DecimalOnly | Select-Object -First 10
                
                $Prior[4] | Should -Be 108
                $Prior[5] | Should -Be 62
                $Prior[6] | Should -Be 10
                $Prior[7] | Should -Be 10
                $Prior[8] | Should -Be 60
                $Prior[9] | Should -Be 104
                
                $Post[4] | Should -Be 108
                $Post[5] | Should -Be 62
                $Post[6] | Should -Be 13
                $Post[7] | Should -Be 10
                $Post[8] | Should -Be 13
                $Post[9] | Should -Be 10
            }
        }
    }
}
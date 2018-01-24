Import-Module -Name $PSScriptRoot\resource\Get-Bytes -Verbose -Force
Import-Module -Name $PSScriptRoot\..\EndOfLine -Verbose -Force

Describe "Test ConvertTo-LF" {
    Context "with UTF-8 CRLF file" {
        InModuleScope EndOfLine {
            $script:SUT = $true
        
            # Using Pester's TestDrive: https://github.com/pester/Pester/wiki/TestDrive
            Copy-Item -Path "resource\index-UTF8-CRLF-NoBOM-NoXtraLine.html" -Destination "TestDrive:\"
        
            It "Should of removed Unicode 13dec chracters" -TestCases @(
                @{  Path                 = "TestDrive:\index-UTF8-CRLF-NoBOM-NoXtraLine.html"; `
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

                $Post -notcontains 13 | Should -Be $true
            }
        }
    }
    Context "with UTF-8 CRLF file in 'WhatIf' mode" {
        InModuleScope EndOfLine {
            $script:SUT = $true
        
            # Using Pester's TestDrive: https://github.com/pester/Pester/wiki/TestDrive
            Copy-Item -Path "resource\index-UTF8-CRLF-NoBOM-NoXtraLine.html" -Destination "TestDrive:\"
        
            It "Should of not modified file - WhatIf mode" -TestCases @(
                @{  Path                 = "TestDrive:\index-UTF8-CRLF-NoBOM-NoXtraLine.html"; `
                        SkipIgnoreFile   = $true; `
                        ExportReportData = $false; `
                        WhatIf           = $true `
                
                }) {
                Param($Path, $SkipIgnoreFile, $ExportReportData, $WhatIf)

                $Prior = Get-FileHash -Path $Path | Select-Object -ExpandProperty Hash
                ConvertTo-LF -Path $Path -SkipIgnoreFile:$SkipIgnoreFile -ExportReportData:$ExportReportData -WhatIf:$WhatIf
                $Post = Get-FileHash -Path $Path | Select-Object -ExpandProperty Hash

                $Prior -eq $Post | Should -Be $true
            }
        }
    }
    Context "with UTF-8 CRLF with extra line file" {
        InModuleScope EndOfLine {
            $script:SUT = $true
        
            # Using Pester's TestDrive: https://github.com/pester/Pester/wiki/TestDrive
            Copy-Item -Path "resource\index-UTF8-CRLF-NoBOM-XtraLine.html" -Destination "TestDrive:\"
        
            It "Should of removed Unicode 13dec chracters and preserved extra line at end" -TestCases @(
                @{  Path                 = "TestDrive:\index-UTF8-CRLF-NoBOM-XtraLine.html"; `
                        SkipIgnoreFile   = $true; `
                        ExportReportData = $false; `
                        WhatIf           = $false `
                
                }) {
                Param($Path, $SkipIgnoreFile, $ExportReportData, $WhatIf)

                $Prior = Get-Bytes -Path $Path -Format DecimalOnly | Select-Object -Last 5
                ConvertTo-LF -Path $Path -SkipIgnoreFile:$SkipIgnoreFile -ExportReportData:$ExportReportData -WhatIf:$WhatIf
                $Post = Get-Bytes -Path $Path -Format DecimalOnly | Select-Object -Last 5

                $Prior[0] | Should -Be 62
                $Prior[1] | Should -Be 13
                $Prior[2] | Should -Be 10
                $Prior[3] | Should -Be 13
                $Prior[4] | Should -Be 10

                $Post[0] | Should -Be 109
                $Post[1] | Should -Be 108
                $Post[2] | Should -Be 62
                $Post[3] | Should -Be 10
                $Post[4] | Should -Be 10

                $Post -notcontains 13 | Should -Be $true
            }
        }
    }
    Context "with directory with .gitignore file" {
        InModuleScope EndOfLine {
            $script:SUT = $true
        
            # Using Pester's TestDrive: https://github.com/pester/Pester/wiki/TestDrive
            Copy-Item -Path "resource\.gitignore" -Destination "TestDrive:\"
            # load various files
            Copy-Item -Path "resource\index-UTF8-CRLF-NoBOM-NoXtraLine.html" -Destination "TestDrive:\"
            Copy-Item -Path "resource\index-UTF16BE-CRLF-NoBOM-NoXtraLine.html" -Destination "TestDrive:\"
            Copy-Item -Path "resource\index-UTF16LE-CRLF-NoBOM-NoXtraLine.html" -Destination "TestDrive:\"
        
            It "Should of not modified file - listed in .gitignore file" -TestCases @(
                @{  Path                 = "TestDrive:\index-UTF8-CRLF-NoBOM-NoXtraLine.html"; `
                        SkipIgnoreFile   = $false; `
                        ExportReportData = $false; `
                        WhatIf           = $false `
                
                }) {
                Param($Path, $SkipIgnoreFile, $ExportReportData, $WhatIf)

                $Prior = Get-FileHash -Path $Path | Select-Object -ExpandProperty Hash
                # here we need to specify a directory and not a file.  if it was a file,
                # it would negate .gitignore
                ConvertTo-LF -Path $TestDrive -SkipIgnoreFile:$SkipIgnoreFile -ExportReportData:$ExportReportData -WhatIf:$WhatIf
                $Post = Get-FileHash -Path $Path | Select-Object -ExpandProperty Hash

                $Prior -eq $Post | Should -Be $true
            }
        }
    }
    Context "with UTF-8 LF files" {
        InModuleScope EndOfLine {
            $script:SUT = $true
        
            # Using Pester's TestDrive: https://github.com/pester/Pester/wiki/TestDrive
            Copy-Item -Path "resource\index-UTF8-LF-BOM-NoXtraLine.html" -Destination "TestDrive:\"
            Copy-Item -Path "resource\index-UTF8-LF-NoBOM-NoXtraLine.html" -Destination "TestDrive:\"
        
            It "Should of not modified file - same EOL as requested" -TestCases @(
                @{  Path                 = "TestDrive:\index-UTF8-LF-NoBOM-NoXtraLine.html"; `
                        SkipIgnoreFile   = $true; `
                        ExportReportData = $false; `
                        WhatIf           = $false `
                
                },
                @{  Path                 = "TestDrive:\index-UTF8-LF-BOM-NoXtraLine.html"; `
                        SkipIgnoreFile   = $true; `
                        ExportReportData = $false; `
                        WhatIf           = $false `
                
                }) {
                Param($Path, $SkipIgnoreFile, $ExportReportData, $WhatIf)

                $Prior = Get-FileHash -Path $Path | Select-Object -ExpandProperty Hash
                ConvertTo-LF -Path $Path -SkipIgnoreFile:$SkipIgnoreFile -ExportReportData:$ExportReportData -WhatIf:$WhatIf
                $Post = Get-FileHash -Path $Path | Select-Object -ExpandProperty Hash

                $Prior -eq $Post | Should -Be $true
            }
        }
    }
    Context "with UTF-16 files" {
        InModuleScope EndOfLine {
            $script:SUT = $true
        
            # Using Pester's TestDrive: https://github.com/pester/Pester/wiki/TestDrive
            Copy-Item -Path "resource\index-UTF16BE-CRLF-NoBOM-NoXtraLine.html" -Destination "TestDrive:\"
            Copy-Item -Path "resource\index-UTF16LE-CRLF-NoBOM-NoXtraLine.html" -Destination "TestDrive:\"
        
            It "Should of not modified file - not UTF-8 encoded file" -TestCases @(
                @{  Path                 = "TestDrive:\index-UTF16BE-CRLF-NoBOM-NoXtraLine.html"; `
                        SkipIgnoreFile   = $true; `
                        ExportReportData = $false; `
                        WhatIf           = $false `
                
                },
                @{  Path                 = "TestDrive:\index-UTF16LE-CRLF-NoBOM-NoXtraLine.html"; `
                        SkipIgnoreFile   = $true; `
                        ExportReportData = $false; `
                        WhatIf           = $false `
                
                }) {
                Param($Path, $SkipIgnoreFile, $ExportReportData, $WhatIf)

                $Prior = Get-FileHash -Path $Path | Select-Object -ExpandProperty Hash
                ConvertTo-LF -Path $Path -SkipIgnoreFile:$SkipIgnoreFile -ExportReportData:$ExportReportData -WhatIf:$WhatIf
                $Post = Get-FileHash -Path $Path | Select-Object -ExpandProperty Hash

                $Prior -eq $Post | Should -Be $true
            }
        }
    }
}
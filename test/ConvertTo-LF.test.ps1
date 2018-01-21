Import-Module "$PSScriptRoot\..\EndOfLine" -Force

Describe "Test ConvertTo-LF" {
    It "Given valid -Path '<Path>'" -TestCases @(
        @{ Path = "$PSScriptRoot\resource\index-UTF8-CRLF-NoXtraLine.html"; SkipIgnoreFile = $false; WhatIf = $false }
    ){
        Param($Path, $SkipIgnoreFile, $WhatIf)

        ConvertTo-LF -Path $Path -SkipIgnoreFile:$SkipIgnoreFile -WhatIf:$WhatIf
    }
}

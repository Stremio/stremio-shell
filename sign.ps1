param (
    [String]$pw = $( Read-Host "Password" )
)

$thread = Start-ThreadJob -InputObject ($pw) -ScriptBlock {
    $wshell = New-Object -ComObject wscript.shell;
    $pw = "$($input)~"
    while ($true) {
        while ( -not $wshell.AppActivate("Token Logon")) {
            Start-Sleep 1
        }
        Start-Sleep 1
        $wshell.SendKeys($pw, $true)
        Start-Sleep 1
    }
}

Get-AuthenticodeSignature dist-win\*.exe | Where-Object -Property Status -Value NotSigned -EQ | ForEach-Object { signtool sign /fd SHA256 /t http://timestamp.digicert.com /n "Smart Code OOD" $_.Path }
Get-AuthenticodeSignature dist-win\*.dll | Where-Object -Property Status -Value NotSigned -EQ | ForEach-Object { signtool sign /fd SHA256 /t http://timestamp.digicert.com /n "Smart Code OOD" $_.Path }

$env:package_version = (Select-String -Path .\CMakeLists.txt -Pattern '^project\(stremio VERSION "([^"]+)"\)').Matches.Groups[1].Value

&"C:\Program Files (x86)\NSIS\makensis.exe" windows\installer\windows-installer.nsi
&signtool sign /fd SHA256 /t http://timestamp.digicert.com /n "Smart Code OOD" "Stremio $env:package_version.exe"
Stop-Job -Job $thread

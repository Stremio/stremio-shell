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

Get-AuthenticodeSignature windows\*.dll | Where-Object -Property Status -Value NotSigned -EQ | % { signtool sign /fd SHA256 /t http://timestamp.digicert.com /n "Smart Code OOD" $_.Path }

Stop-Job -Job $thread

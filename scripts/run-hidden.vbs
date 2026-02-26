' run-hidden.vbs - Run a command without showing a terminal window
' Usage: wscript.exe run-hidden.vbs <executable> [arg1] [arg2] ...
'
' All arguments are joined into a single command line.
' Arguments containing spaces are automatically quoted.

Set oShell = CreateObject("WScript.Shell")

Dim cmd
cmd = ""

For i = 0 To WScript.Arguments.Count - 1
    If i > 0 Then cmd = cmd & " "
    Dim arg
    arg = WScript.Arguments(i)
    If InStr(arg, " ") > 0 And Left(arg, 1) <> Chr(34) Then
        cmd = cmd & Chr(34) & arg & Chr(34)
    Else
        cmd = cmd & arg
    End If
Next

oShell.Run cmd, 0, True

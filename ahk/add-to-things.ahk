#SingleInstance Force

^Space::
{
    todo := InputBox("", "To Do")
    if todo.Result = "Cancel"
        return

    RunFormat := Format('pwsh.exe -File "C:\Code\dotfiles\bin\AddToThings.ps1" "{}"', todo.Value)
    Run(RunFormat, ,"Hide")
}

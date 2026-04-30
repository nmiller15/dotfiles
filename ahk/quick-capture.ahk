#SingleInstance Force

^Space::
{
    input := InputBox("", "Quick Capture")
    if input.Result = "Cancel"
        return

    dotfiles := EnvGet("DOTFILES")
    if (dotfiles = "")
        dotfiles := "C:\Code\dotfiles-v2"

    RunFormat := Format('pwsh.exe -File "{}\bin\pwsh\quick-capture.ps1" "{}"', dotfiles, input.Value)
    Run(RunFormat, ,"Hide")
}

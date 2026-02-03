param(
    [Parameter(Mandatory, ValueFromRemainingArguments)]
    [string[]]$Message
)

Import-Module BurntToast -ErrorAction Stop

New-BurntToastNotification -Text ("notify"), ($Message -join ' ')


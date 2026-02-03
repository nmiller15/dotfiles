param(
    [Parameter(position=0)][string]$text
)
$envKey= [regex]::Escape("ADD_TO_THINGS_MOSAIC")
$apiKeyRegex="^$envKey=(.+)$"

$urlKey= [regex]::Escape("ADD_TO_THINGS_MOSAIC_URL")
$urlKeyRegex="^$urlKey=(.+)$"

$envPath="C:\Code\dotfiles\bin\.env"

Get-Content $envPath | ForEach-Object {
    if ($_.Trim() -match $apiKeyRegex)
    {
        $apiKey = $matches[1]
    }
    if ($_.Trim() -match $urlKeyRegex)
    {
        $baseUrl = $matches[1]
    }
}


$arr = $text -split ','
$title = $arr[0].Trim()
$description = ($arr[1] ?? "").Trim()

$todo = @{
    "Title"=$title
    "Description"=$description
}


Invoke-WebRequest -Uri "$baseUrl/Things/Add" `
    -Method POST `
    -Headers @{
    'X-Api-Key'=$apiKey 
    'Content-Type'='application/json'
} `
    -Body ($todo | ConvertTo-Json)

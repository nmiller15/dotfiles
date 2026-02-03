## Merchant
function merchantTestClientFunc { dotnet run --project "C:\Repos\Github\Merchant\Merchant.TestClient" }
Set-Alias mtc merchantTestClientFunc
function merchantApiRunFunc { dotnet run --project "C:\Repos\Github\Merchant\Merchant.API" }
Set-Alias mr merchantApiRunFunc

## Symposia
function symposiaTestClientFunc { dotnet run --project "C:\Repos\Github\Symposia\Symposia.TestClient.NetCore\" }
Set-Alias stc symposiaTestClientFunc
function symposiaApiRunFunc { dotnet run --project "C:\Repos\Github\Symposia\Symposia.API" }
Set-Alias sr symposiaApiRunFunc

## EWR
function ewrRunFunc { dotnet run --project "C:\Repos\Github\EventWebRegistration\EventWebRegistrationPublic\" }
Set-Alias ewr ewrRunFunc

## CABStaff
function cabRunFunc { dotnet run --project "C:\Repos\Github\CabStaffV2\CabStaff" }
Set-Alias cabr cabRunFunc

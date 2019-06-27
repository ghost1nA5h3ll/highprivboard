#Generating AD Users

Import-Module ActiveDirectory

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddHours(-1)
$Action = New-ScheduledTaskAction -WorkingDirectory "C:\Scripts\ADDashBoard" -Execute "powershell.exe" -Argument "-file .\add_permissions.ps1"


Register-ScheduledTask -Action $Action -Trigger $trigger -User "PSVC-LAB-01" -Password "Geheim123" -RunLevel Highest

New-ADServiceAccount -Name "PSVC-LAB-99" -DNSHostName "PSVC-LAB-99.lab.local" -PrincipalsAllowedToRetrieveManagedPassword "FUN-LAB-PATRMP-99" -Path "OU=Service,OU=Lab,DC=lab,DC=local"

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddHours(-1)
$principal = New-ScheduledTaskPrincipal -UserId "LAB\PSVC-LAB-99$" -LogonType Password
$Action = New-ScheduledTaskAction -WorkingDirectory "C:\Scripts\ADDashBoard" -Execute "powershell.exe" -Argument "-file .\modify_permissions.ps1 -SamAccountName $env:USERNAME -GroupName $Session:GroupName"

Register-ScheduledTask -Action $Action -Trigger $trigger -Principal $principal -TaskName add_priv_$env:USERNAME
$adminHost = ([Security.Principal.WindowsPrincipal] `
[Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $adminHost) {

    Write-Host "Elevate the Shell!" -ForegroundColor Red
    break
}

Import-Module UniversalDashboard.Community, ActiveDirectory



$myTheme = Get-UDTheme -Name DarkDefault

$objDomain = Get-ADDomain

$ADInfo = New-UDPage -Title "$env:USERNAME@$($objDomain.DNSRoot)" -Icon info -Name "$($objDomain.DNSRoot)" -Content{


    New-UDRow -Id "Rows1" -Columns{
        New-UDColumn -Size 4 {}
        New-UDColumn -Size 4 {
            New-UDCard -Id "Basic Info" -Title "Uebersicht"  -Size medium -Content {

                New-UDTable -Headers @(" "," ") -Style bordered -AutoRefresh -RefreshInterval 10  -Endpoint {
                    $currentUser = Get-ADUSer -Identity $env:USERNAME -Server $env:USERDNSDOMAIN
                    $RootDomain = (Get-ADForest).RootDomain
                    $EnterpriseAdmins = Get-ADGroupMember -Identity "Enterprise Admins" -Server $RootDomain
                    $SchemaAdmins = Get-ADGroupMember -Identity "Schema Admins" -Server $RootDomain
                    $DomainAdmins = Get-ADGroupMember -Identity "Domain Admins" -Server $env:USERDNSDOMAIN
                    $LABPRIV = Get-ADGroupMember -Identity "ROL-LAB-PRIV" -Server "lab.local"
                    $LABCOOL = Get-ADGroupMember -Identity "ROL-LAB-COOL" -Server "lab.local"
                    $SUBULTRA = Get-ADGroupMember -Identity "ROL-SUB-ULTRA" -Server "sub.lab.local"
                    
                    @{
                        'Member of EA' = "$($EnterpriseAdmins.SID -contains $currentUser.SID)" 
                        'Member of SA' = "$($SchemaAdmins.SID -contains $currentUser.SID)"
                        'Member of DA' = "$($DomainAdmins.SID -contains $currentUser.SID)"
                        'Member of LABPRIV' = "$($LABPRIV.SID -contains $currentUser.SID)"
                        'Member of LABCOOL' = "$($LABCOOL.SID -contains$currentUser.SID)"
                        'Member of SUBULTRA' = "$($SUBULTRA.SID -contains$currentUser.SID)"
                        

                    }.GetEnumerator() | Out-UDTableData -Property @("Name","Value")
                }

            }
        }
        New-UDColumn -Size 4 {}
    }
    New-UDRow -Id "Rows2" -Columns{
        New-UDColumn -Size 4 {}
        New-UDColumn -Size 4 {
            New-UDColumn -size 6 {
                New-UDSelect -Label "Such dir eine Gruppe aus" -Option {
                    New-UDSelectOption -Name "Choose" -Value "Choose" -Selected
                    New-UDSelectOption -Name "ROL-LAB-PRIV" -Value "ROL-LAB-PRIV"
                    New-UDSelectOption -Name "ROL-LAB-COOL" -Value "ROL-LAB-COOL"
                    New-UDSelectOption -Name "ROL-SUB-ULTRA" -Value "ROL-SUB-ULTRA"
                    
                } -OnChange {

                    
                    if($EventData -ne "Choose"){
                        $Session:GroupName = $EventData
                    }else{
                        Show-UDToast -Message "Choose a group please" -Duration 3500
                    }
                }
                

            }
            New-UDColumn -Size 6 {
                New-UDSelect -Label "Domain der Gruppe" -Option {
                    $Forest = Get-ADForest
                    New-UDSelectOption -Name "Choose" -Value "Choose" -Selected
                    foreach($domain in $Forest.domains){
                        New-UDSelectOption -Name $domain -Value $domain
                    }
                } -OnChange {
                    if($EventData -ne "Choose"){
                        $Session:Domain = $EventData
                    }else{
                        Show-UDToast -Message "Choose a Domain please" -Duration 3500
                    }

                }

            }

        }
    

    
}
    New-UDRow -id "Rows3" -Columns {
        New-UDColumn -Size 4 {}
        New-UDColumn -Size 4 {
            New-UDButton -Id "AddRights" -Text "Gib mir Rechte" -Icon plus -OnClick {
                try{
                    if($Session:GroupName -ne $null -and $Session:Domain -ne $null){

                    
                        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddHours(-1)
                        $principal = New-ScheduledTaskPrincipal -UserId "LAB\PSVC-LAB-99$" -LogonType Password
                        $Action = New-ScheduledTaskAction -WorkingDirectory "C:\Scripts\ADDashBoard" -Execute "powershell.exe" -Argument "-file .\modify_permissions.ps1 -SamAccountName $env:USERNAME -GroupName $Session:GroupName -Domain $Session:Domain -UserDomain $env:USERDNSDOMAIN"

                        Register-ScheduledTask -Action $Action -Trigger $trigger -Principal $principal -TaskName add_priv_$env:USERNAME
                        Start-Sleep 4

                        Start-ScheduledTask -TaskName add_priv_$env:USERNAME
                        Show-UDToast "Erfolgreich den Task gestartet"
                        

                        Start-Sleep 10
                        Unregister-ScheduledTask -TaskName add_priv_$env:USERNAME -Confirm:$false
                        Show-UDToast "Erfolgreich den Task beendet"
                    }
                    else{
                        Show-UDToast -Message "Choose a group and domain please!" -Duration 3500
                    }
                }
                catch{
                    Show-UDToast "FEHLER AUFGETRETEN"
                }
        }
        New-UDButton -Id "RemoveRights" -Text "Nimm mir Rechte" -Icon recycle  -OnClick {
            try{
                if($Session:GroupName -ne $null -and $Session:Domain -ne $null){
                    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddHours(-1)
                    $principal = New-ScheduledTaskPrincipal -UserId "LAB\PSVC-LAB-99$" -LogonType Password
                    $Action = New-ScheduledTaskAction -WorkingDirectory "C:\Scripts\ADDashBoard" -Execute "powershell.exe" -Argument "-file .\modify_permissions.ps1 -Remove -SamAccountName $env:USERNAME -GroupName $Session:GroupName -Domain $Session:Domain -UserDomain $env:USERDNSDOMAIN"

                    Register-ScheduledTask -Action $Action -Trigger $trigger -Principal $principal -TaskName remove_priv_$env:USERNAME
                    Start-Sleep 4

                    Start-ScheduledTask -TaskName remove_priv_$env:USERNAME
                    Show-UDToast "Erfolgreich den Task gestartet"

                    Start-Sleep 10
                    Unregister-ScheduledTask -TaskName remove_priv_$env:USERNAME -Confirm:$false
                    Show-UDToast "Erfolgreich den Task beendet"
                }
                else{
                    Show-UDToast -Message "Choose a group and domain please!" -Duration 3500
                }
            }
            catch{
                Show-UDToast "FEHLER AUFGETRETEN"
            }

        }

    }
    New-UDColumn -Size 4 {}
    }
}
function Get-FreePort {

        $PortList = 10000..11000
        $RndPort = $PortList | Get-Random
        $DashboardList = Get-UDDashboard
        if($DashboardList -eq $null) {
            
            return $RndPort
        }
        else{
            while($DashboardList.Port -contains $RndPort){

                $RndPort = $PortList | Get-Random
            }
            return $RndPort
        }

}

$dashboard = New-UDDashboard -Title "AD-Rights_$env:USERNAME" -Pages @($ADInfo) -Theme $myTheme
$Port = Get-FreePort
Start-UDDashboard -Dashboard $dashboard -Name "AD-Rights_$env:USERNAME"  -Port $Port -AutoReload

$ProcessID = (Start-Process iexplore -ArgumentList "http://localhost:$Port" -PassThru).Id

Wait-Process -id $ProcessID

Stop-UDDashboard -Port $Port 


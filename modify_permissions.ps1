param(

    [Parameter(Mandatory=$true)]$SamAccountName,
    [Parameter(Mandatory=$true)]$GroupName,
    [Parameter(Mandatory=$true)]$Domain,
    [Parameter(Mandatory=$true)]$UserDomain,
    [switch]$Remove



)

Import-Module ActiveDirectory

$objADUser = Get-ADUser -Filter {samAccountName -eq $SamAccountName} -Server $UserDomain

if($objADUser){

    if (-not $Remove){

        Add-ADGroupMember -Identity $GroupName -Members $objADUser -Server $Domain
    }
    else {
        Remove-ADGroupMember -Identity $GroupName -Members $objADUser -Server $Domain -Confirm:$false
    }
}else{

    #Log this to file. No User with Name given to paramter $SamAccountName in Domain found
}
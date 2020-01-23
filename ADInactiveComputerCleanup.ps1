<#
    Discovers and Disables AD Computer Objects that have not
    logged in in provided timeframe. Then moves disabled objects
    to the 'Disable and Delete' OU.
#>

$disableAndDeleteDN = "OU=Disable and Delete,DC=pfbiwv,DC=com"

<#
    Get list of AD Computers that aren't already in 'Disable
    and Delete' OU based on lastLogonDate.
#>

$ADComputers = Get-ADComputer -Filter * -Properties * | `
   ? lastLogonDate -lt ((Get-Date).AddDays(-21)) | `
   ? DistinguishedName -notlike "*Disable and Delete*" | `
   Select SamAccountName,LastLogonDate,DistinguishedName

ForEach($ADComputer in ($ADComputers | Sort SamAccountName)){
    $ADComputerName=$ADComputer.SamAccountName
    $CanPing=Test-Connection $ADComputerName -Count 1 -Quiet
    $ADComputerDN=$ADComputer.DistinguishedName
    If(-not $CanPing){
        Disable-ADAccount $ADComputerName
        Sleep 5
        If((Get-ADComputer $ADComputerName | Select -ExpandProperty Enabled)){
            $Status = "Disable Failed"
        }
        else{
            Move-ADObject $ADComputerDN $disableAndDeleteDN
            If((Get-ADComputer $ADComputerName | Select -ExpandProperty DistinguishedName).Split(',')[1] -like "*OU=DISABLE and Delete*"){
                $Status = "Move Successful"
            }
            Else{
                $Status = "Move Failed"
            }
        }

    }
    Write-Host "$ADComputerName `t $CanPing `t $Status `t"
    Write-HOst "$ADComputerDN"
    Write-Host ""
}
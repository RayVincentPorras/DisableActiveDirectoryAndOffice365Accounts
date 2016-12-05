#Gathers active directory account name to be disabled.
$accountName = Read-Host -Prompt 'Enter account name to disable:'
$password = Read-Host -Prompt 'Enter new password for the account:' -AsSecureString

#Disables account while resetting the password, outputting group membership to a text for archival purposes, removes all group memberships, and removes note entries.
Set-ADAccountPassword -Identity $accountName -Reset -NewPassword $password 

Get-ADUser -Identity $accountName -Properties * | Out-File c:\AccountArchiveInformation\groupmembershipinfo\$($accountName).txt -width 120 -Append

$ADGroups = Get-ADPrincipalGroupMembership -Identity $accountName | where {$_.Name -ne "Domain Users"}

Remove-ADPrincipalGroupMembership -Identity $accountName -MemberOf $ADGroups -Confirm:$false 

Set-ADUser $accountName -Replace @{Info=' '}

Disable-ADAccount -Identity $accountName

#Prompt to notify active directory account disablement completion and prompt for Office 365 credentials. 
Write-Host 'The Active Directory account terminated. Please provide credentials for the Office 365 Admin to proceed with the Office 365 termination.'

#Connects to Office 365.
Set-ExecutionPolicy RemoteSigned
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session
Connect-MsolService -Credential $UserCredential

#Gathers email account to be disabled. 
$emailAddress = Read-Host -Prompt 'Please enter the email address to disable:'

Set-MsolUserPassword -UserPrincipalName $emailAddress -NewPassword 'EnterNewPasswordHere' -ForceChangePassword $False
Set-MsolUser -UserPrincipalName $emailAddress -BlockCredential $true
Set-Mailbox $emailAddress –CustomAttribute1 “ ” 
Set-Mailbox $emailAddress -Type shared
#Run sleep to allow office 365 time to convert the mailbox to a shared mailbox.
Write-Host 'Converting mailbox to a shared mailbox. Please wait...'
Start-Sleep -s 60
Set-MsolUserLicense -UserPrincipalName $emailAddress -RemoveLicenses "ExampleINC:EXCHANGESTANDARD"
Write-Host 'The account has been terminated.' 

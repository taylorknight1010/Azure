[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$CustomerName
)

$GPO_Domain = (Get-ADDomain).Forest

# get latest download url for git-for-windows 64-bit exe
Write-Verbose "Checking if Git is installed" -Verbose
$git_install_path = "C:\Program Files\Git"
if (-not (Test-Path -Path $git_install_path)) {

Write-verbose "No Git installed - Installing..." -Verbose
$git_url = "https://api.github.com/repos/git-for-windows/git/releases/latest"
$asset = Invoke-RestMethod -Method Get -Uri $git_url | % assets | where name -like "*64-bit.exe"
# download installer
$installer = "$env:temp\$($asset.name)"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer
# run installer
$git_install_inf = "<install inf file>"
$install_args = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /LOADINF=""$git_install_inf"""
Start-Process -FilePath $installer -ArgumentList $install_args -Wait

}
else {
    Write-verbose "Git already installed" -Verbose
}

# Clone the Azure DevOps Repo
Write-Verbose "Checking if DevOps Repo is already cloned" -Verbose
$repo_clone_path = "C:\GPOBackups"
if (-not (Test-Path -Path $repo_clone_path)) {
Write-Verbose "Not cloned - continuing to clone repo..." -Verbose    
$repoUrl = "dev.azure.com/customername/IT/_git/customername-template"
$personalAccessToken =   # Ensure your PAT has repo access
$localRepoPath = "C:\GPOBackups"  # Path to clone the repo

# Create local directory if not exists
if (-not (Test-Path -Path $localRepoPath)) {
    New-Item -ItemType Directory -Path $localRepoPath
}

# Use Git to clone the repo using the PAT for authentication
$gitCommand = "git clone https://$($personalAccessToken):x-oauth-basic@$repoUrl $localRepoPath"

# Run the Git command
Invoke-Expression -Command $gitCommand

# Check if the repo was cloned successfully
if (Test-Path -Path $localRepoPath) {
    Write-Host "Repository cloned successfully to $localRepoPath"
} else {
    Write-Host "Failed to clone the repository."
    exit
}
}
else {
    Write-verbose "DevOps Repo is already cloned" -Verbose
}

# Installing MS Edge ADMX Files
Write-verbose "Installing Pre-Req ADMX files" -Verbose
$sourcePath = "${localRepoPath}\powershell\Active-Directory\GPOs\admx"
$AdmxDestPath = "C:\Windows\PolicyDefinitions"
$AdmlDestPath = "C:\Windows\PolicyDefinitions\en-US"

# Copy all .admx files and .adml subdirectories from the source to the destination
Copy-Item -Path "$sourcePath\*.admx" -Destination $AdmxDestPath -Recurse -Force
Copy-Item -Path "$sourcePath\*.adml" -Destination $AdmlDestPath -Recurse -Force

Write-verbose "Copied Pre-Req ADMX files into $AdmxDestPath" -Verbose

# Unzip GPOs
$gpoBackupPath = "C:\GPOBackups\powershell\Active-Directory\GPOs\gpos-oct24"

Write-verbose "Unzipping GPOs in cloned repo path - $gpoBackupPath" -Verbose
Expand-Archive -Path "C:\GPOBackups\powershell\Active-Directory\GPOs\gpos-oct24.zip" -DestinationPath "C:\GPOBackups\powershell\Active-Directory\GPOs" -Force

###################################################################################################################################################
###################################################################################################################################################

# Import the Group Policy module
Import-Module GroupPolicy

# List of GPO names to create - AADDC Computers GPO on purpose left out. It should get auto created as part of Entra Domain Services - below we link this gpo to the correct OUs
$gpoNames = @(
    "All - AVD Licence",
    "Event Log GPO",
    "Default Password Policy",
    "All - File Associations ",
    "All - Security Settings",
    "All - Session timeout",
    "BETA - Browser settings",
    "BETA - Local groups",
    "BETA - User AVD settings",
    "PPD - Browser settings",
    "PPD - Local groups",
    "PPD - User AVD settings",
    "PROD - Browser settings",
    "PROD - Local groups",
    "PROD - User AVD settings",
    "UAT - Browser settings",
    "UAT - Local groups",
    "UAT - User AVD settings",
    "SECURE - Local groups",
    "SECURE - Mapped Drive",
    "SZ - Edge Default",
    "All - Backinfo",
    "Default Domain Controllers Policy",
    "Default Domain Policy"      
)

foreach ($gpoName in $gpoNames) {

Import-GPO -BackupGpoName $gpoName -TargetName $gpoName -path $gpoBackupPath -CreateIfNeeded

}

###################################################################################################################################################
###################################################################################################################################################


# Create WMI Filters
# Import necessary module

Write-verbose "Starting to create WMI Filters" -Verbose
Import-Module ActiveDirectory
# Define parameters
$Name = "IMG/SH"
$Description = "WMI filter created for specific computer names via PowerShell"
$Filter = @("SELECT * FROM Win32_ComputerSystem WHERE (Name LIKE 'SH%' OR Name LIKE '%image%')")

# Generate unique identifier and date for WMI filter attributes
$wmiGuid = "{$([System.Guid]::NewGuid())}"
$creationDate = (Get-Date).ToUniversalTime().ToString("yyyyMMddhhmmss.ffffff-000")

# Format the filter string
$filterString = "{0};" -f $Filter.Count.ToString()
$Filter | ForEach-Object {
    $filterString += "3;10;{0};WQL;root\CIMv2;{1};" -f $_.Length, $_
}

# Get the naming context for AD
$namingContext = (Get-ADRootDSE).defaultNamingContext

# Define attributes for the WMI filter object
$attributes = @{
    "showInAdvancedViewOnly" = "TRUE"
    "msWMI-Name"             = $Name
    "msWMI-Parm1"            = $Description
    "msWMI-Parm2"            = $filterString
    "msWMI-Author"           = "$($env:USERNAME)@$($env:USERDNSDOMAIN)"
    "msWMI-ID"               = $wmiGuid
    "instanceType"           = 4
    "distinguishedname"      = "CN=$wmiGuid,CN=SOM,CN=WMIPolicy,CN=System,$namingContext"
    "msWMI-ChangeDate"       = $creationDate
    "msWMI-CreationDate"     = $creationDate
}

# Define parameters for the New-ADObject cmdlet
$paramNewADObject = @{
    OtherAttributes = $attributes
    Name            = $wmiGuid
    Type            = "msWMI-Som"
    Path            = "CN=SOM,CN=WMIPolicy,CN=System,$namingContext"
}

# Create the WMI filter in Active Directory
try {
    New-ADObject @paramNewADObject
    Write-Output "WMI filter '$Name' created successfully with GUID: $wmiGuid"
} catch {
    Write-Error "Failed to create WMI filter: $_"
}

# Define parameters
$Name = "Not Image or SH"
$Description = "WMI filter created for specific computer names via PowerShell"
$Filter = @("SELECT * FROM Win32_ComputerSystem WHERE NOT (Name LIKE 'SH%' OR Name LIKE '%image%')')")

# Generate unique identifier and date for WMI filter attributes
$wmiGuid = "{$([System.Guid]::NewGuid())}"
$creationDate = (Get-Date).ToUniversalTime().ToString("yyyyMMddhhmmss.ffffff-000")

# Format the filter string
$filterString = "{0};" -f $Filter.Count.ToString()
$Filter | ForEach-Object {
    $filterString += "3;10;{0};WQL;root\CIMv2;{1};" -f $_.Length, $_
}

# Get the naming context for AD
$namingContext = (Get-ADRootDSE).defaultNamingContext

# Define attributes for the WMI filter object
$attributes = @{
    "showInAdvancedViewOnly" = "TRUE"
    "msWMI-Name"             = $Name
    "msWMI-Parm1"            = $Description
    "msWMI-Parm2"            = $filterString
    "msWMI-Author"           = "$($env:USERNAME)@$($env:USERDNSDOMAIN)"
    "msWMI-ID"               = $wmiGuid
    "instanceType"           = 4
    "distinguishedname"      = "CN=$wmiGuid,CN=SOM,CN=WMIPolicy,CN=System,$namingContext"
    "msWMI-ChangeDate"       = $creationDate
    "msWMI-CreationDate"     = $creationDate
}

# Define parameters for the New-ADObject cmdlet
$paramNewADObject = @{
    OtherAttributes = $attributes
    Name            = $wmiGuid
    Type            = "msWMI-Som"
    Path            = "CN=SOM,CN=WMIPolicy,CN=System,$namingContext"
}

# Create the WMI filter in Active Directory
try {
    New-ADObject @paramNewADObject
    Write-Output "WMI filter '$Name' created successfully with GUID: $wmiGuid"
} catch {
    Write-Error "Failed to create WMI filter: $_"
}

###################################################################################################################################################
###################################################################################################################################################

### Link WMI Filters to GPOs ###

Write-verbose "Starting to link WMI Filters to GPOs" -Verbose

# Step 1: Define the Distinguished Name (DN) of the WMI filters container
$wmiFilterDN = "CN=SOM,CN=WMIPolicy,CN=System,$namingContext"

# Step 2: Get WMI filters from the specified container
$wmiFilters = Get-ADObject -SearchBase $wmiFilterDN -Filter * -Properties msWMI-Name, gPCWQLFilter

# Step 3: Prepare an array to hold the results
$results = @()

# Step 4: Loop through each WMI filter and collect details
foreach ($filter in $wmiFilters) {
    # Create a custom object for output
    $results += [PSCustomObject]@{
        Name        = $filter.Name
        ObjectGUID  = $filter.ObjectGUID
        msWMI_Name  = $filter."msWMI-Name"  # Accessing the msWMI-Name property
        gPCWQLFilter = $filter.gPCWQLFilter
    }
}

# Output the results
$results | Format-Table -AutoSize

# Step 5: Set the GPO name and retrieve its GUID
$GpoNames = @("All - File Associations ", "All - Session timeout", "BETA - Browser settings", "BETA - User AVD settings", "PPD - Browser settings", "PPD - User AVD settings", "PROD - Browser settings", "PROD - User AVD settings", "UAT - Browser settings", "UAT - User AVD settings")

# Step 6: Specify the msWMI-Name you want to use to find the corresponding WMI filter
$desiredMsWmiName = "IMG/SH"  # Example name to search for

# Step 7: Find the corresponding WMI filter GUID
$wmiFilterToLink = $results | Where-Object { $_.msWMI_Name -eq $desiredMsWmiName }

if ($null -eq $wmiFilterToLink) {
    Write-Host "WMI filter with msWMI_Name '$desiredMsWmiName' not found."
    exit
}

# Correcting this line to get the actual GUID properly formatted
$WmiFilterGuid = $wmiFilterToLink.Name -replace '[{}]', ''

# Step 8: Construct the new value for gPCWQLFilter
$gPCWQLFilterValue = "[$GPO_Domain;{$WmiFilterGuid};0]"  # Single curly braces are already set

foreach ($GpoName in $GpoNames) {
    # Retrieve the GPO's GUID
    $GpoLookup = (Get-GPO -Name $GpoName).Id

    # Define the Distinguished Name (DN) of the GPO
    $gpoDN = "CN={${GpoLookup}},CN=Policies,CN=System,$namingContext"

    # Update the gPCWQLFilter attribute for the GPO
    Set-ADObject -Identity $gpoDN -Replace @{gPCWQLFilter = $gPCWQLFilterValue}

    # Verify the update
    $updatedGPO = Get-ADObject -Identity $gpoDN -Properties gPCWQLFilter
    Write-Host "Updated gPCWQLFilter for GPO '$GpoName': $($updatedGPO.gPCWQLFilter)"
}


###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "All - backinfo" ###

# Define the path to the XML file
$GpoLookup = (get-gpo -Name "All - backinfo").Id
$xmlFilePath = "\\${GPO_Domain}\SYSVOL\${GPO_Domain}\Policies\{${GpoLookup}}\Machine\Preferences\Files\Files.xml"


# Define the old value
$backInfoExeOldPath = "\\customername.oncustomername.co.uk\SYSVOL\customername.oncustomername.co.uk\Policies\Scripts\backinfo\backinfo.exe"
$backInfoIniOldPath = "\\customername.oncustomername.co.uk\SYSVOL\customername.oncustomername.co.uk\Policies\Scripts\backinfo\backinfo.ini"


# Lookup new values
$backInfoExePath = "\\$GPO_Domain\SYSVOL\$GPO_Domain\Policies\Scripts\backinfo\backinfo.exe"
$backInfoIniPath = "\\$GPO_Domain\SYSVOL\$GPO_Domain\Policies\Scripts\backinfo\backinfo.ini"


# Check if the XML file exists
if (Test-Path $xmlFilePath) {
    # Read the contents of the XML file
    $xmlContent = Get-Content $xmlFilePath

    # Replace old SIDs with new SIDs
    $xmlContent = $xmlContent -replace [regex]::Escape($backInfoExeOldPath), $backInfoExePath
    $xmlContent = $xmlContent -replace [regex]::Escape($backInfoIniOldPath), $backInfoIniPath

    # Write the updated content back to the XML file
    Set-Content -Path $xmlFilePath -Value $xmlContent

    Write-Host "Successfully updated 'customername' to 'its' and old SIDs to new SIDs in the XML file."
} else {
    Write-Host "The specified XML file does not exist."
}

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "All - AVD License" ###

# Define variables
$GPOName = "All - AVD Licence"
# $GPO_Domain = "itsandbox.co.uk" # now passed as a parameter instead.
$RDS_Server_Name = "${CustomerName}hubmgt01.${GPO_Domain}"


# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}

# Path for Computer Configuration registry settings
$RegistryPath = "HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services"

# Set "Use the specified Remote Desktop license servers" registry setting
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath -ValueName "LicenseServers" -Type String -Value $RDS_Server_Name

# Permissions are handled separately in AD or GPO settings; to add delegation:
# Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# Print completion message
Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "Event Log GPO" ### - under review as it expects a .ps1 script to be stored in sysvol

###################################################################################################################################################
###################################################################################################################################################

# ### GPO Name - "All - Edge Policy" ### - Commented out as its not linked to anything in customername when this baseline was created - un-comment if needed.
# # Need to automate storing \edge_default.xml for this gpo.

# # Define variables
# $GPOName = "All - Edge Policy"
# # $GPO_Domain = "itsandbox.co.uk" # now passed as a parameter instead.
# $DefaultAssociationsConfig = "\\${CustomerName}hubmgt01.${GPO_Domain}\DomainScripts\edge_default.xml"


# # Create a new GPO if it doesn't exist
# $gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
# if (-not $gpo) {
#     $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
#     Write-Output "GPO '$GPOName' created."
# } else {
#     Write-Output "GPO '$GPOName' already exists."
# }

# # Path for Computer Configuration registry settings
# $RegistryPath = "HKLM\\SOFTWARE\Policies\Microsoft\Windows\System"

# # Set DefaultAssociationsConfiguration
# Set-GPRegistryValue -Name $GPOName -Key $RegistryPath -ValueName "DefaultAssociationsConfiguration" -Type String -Value $DefaultAssociationsConfig

# # Permissions are handled separately in AD or GPO settings; to add delegation:
# # Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
# Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# # Print completion message
# Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "All - File Associations" ###

# Define variables
$GPOName = "All - File Associations "
# $GPO_Domain = "itsandbox.co.uk" # now passed as a parameter instead.
$DefaultAssociationsConfig = "\\${CustomerName}hubmgt01.${GPO_Domain}\DomainScripts\DefaultFileAssociations.xml"


# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}

# Path for Computer Configuration registry settings
$RegistryPath = "HKLM\\SOFTWARE\Policies\Microsoft\Windows\System"

# Set DefaultAssociationsConfiguration
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath -ValueName "DefaultAssociationsConfiguration" -Type String -Value $DefaultAssociationsConfig

# Permissions are handled separately in AD or GPO settings; to add delegation:
# Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# Print completion message
Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "BETA - Browser settings" ###

# Define variables
$GPOName = "BETA - Browser settings"
$PopUpServer1 = "http://${CustomerName}betakfx01.${GPO_Domain}"
$PopUpServer2 = "http://${CustomerName}betakfx01"
$AppServer1 = "http://${CustomerName}betaapp01.${GPO_Domain}"
$AppServer2 = "http://${CustomerName}betaapp01"
$WebServer1 = "http://${CustomerName}betaweb01.${GPO_Domain}"
$WebServer2 = "http://${CustomerName}betaweb01"
$ssrsServer1 = "http://${CustomerName}betassrs01.${GPO_Domain}"
$ssrsServer2 = "http://${CustomerName}betassrs01"
$ssrsServer3 = "http://${CustomerName}betassrs01/Reports"

# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}


# Path for Computer Configuration registry settings
$RegistryPath1 = "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\New Windows\Allow"
$RegistryPath2 = "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"
$RegistryPath3 = "HKCU\Software\Policies\Microsoft\Edge\URLAllowlist"
$RegistryPath4 = "HKCU\Software\Policies\Microsoft\Edge"
$RegistryPath5 = "HKCU\Software\Policies\Microsoft\Edge\PopupsAllowedForUrls"


# Create an array of registry values to remove
$oldRegistryValues = @(
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameuatkfx01.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameuatkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatkfx01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatapp01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatapp01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatweb01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatweb01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatssrs01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatssrs01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatssrs01/Reports' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '1' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '2' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '9' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '10' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '22' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '24' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '25' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '26' },
    @{ Name = $GPOName; Key = $RegistryPath4; ValueName = 'HomepageLocation' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '1' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '2' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '3' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '4' }
)

# Loop through each registry value and remove it
foreach ($params in $oldRegistryValues) {
    Remove-GPRegistryValue @params
}

# MS Edge - URL Allow List
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '1' -Type String -Value "*${PopUpServer2}"
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '2' -Type String -Value $WebServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '9' -Type String -Value $WebServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '10' -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '22' -Type String -Value "${PopUpServer2}:8081"
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '24' -Type String -Value $ssrsServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '25' -Type String -Value $ssrsServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '26' -Type String -Value $ssrsServer3

# MS Edge
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath4 -ValueName 'HomepageLocation' -Type String -Value "${PopUpServer2}:8081/start/home.html"

# MS Edge - PopupsAllowedForUrls
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '1' -Type String -Value $PopUpServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '2' -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '3' -Type String -Value $WebServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '4' -Type String -Value $WebServer2

# Pop Up Internet Explorer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer1 -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer2 -Type String -Value $PopUpServer2

# Windows Components/Internet Explorer/Internet Control Panel/Security Page/Site to Zone Assignment List
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer2 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer3 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer2 -Type String -Value 2

# Permissions are handled separately in AD or GPO settings; to add delegation:
# Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# Print completion message
Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "BETA - Local groups" ###

# Define the path to the XML file
$GpoLookup = (get-gpo -Name "beta - local groups").Id
$xmlFilePath = "\\${GPO_Domain}\SYSVOL\${GPO_Domain}\Policies\{${GpoLookup}}\Machine\Preferences\Groups\Groups.xml"

# Old name and new name for replacement
$oldName = "customername"
$newName = $CustomerName

# Define the old SIDs
$customernameBetaAccessOldSID = "S-1-5-21-281918534-52708182-3417967371-2054"
$customernameBetaVMAdminsOldSID = "S-1-5-21-281918534-52708182-3417967371-1509"
$customernameITLocalAccountsOldSID = "S-1-5-21-281918534-52708182-3417967371-1488"

# Lookup new SIDs from AD
$customernameBetaAccessSID = (Get-ADGroup -Identity "customername Beta Access").SID
$customernameBetaVMAdminsSID = (Get-ADGroup -Identity "customername Beta VM Admins").SID
$customernameITLocalAccountsSID = (Get-ADGroup -Identity "customername IT Local Accounts").SID

# Check if the XML file exists
if (Test-Path $xmlFilePath) {
    # Read the contents of the XML file
    $xmlContent = Get-Content $xmlFilePath

    # Replace 'customername' with 'its'
    $xmlContent = $xmlContent -replace [regex]::Escape($oldName), $newName

    # Replace old SIDs with new SIDs
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameBetaAccessOldSID), $customernameBetaAccessSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameBetaVMAdminsOldSID), $customernameBetaVMAdminsSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameITLocalAccountsOldSID), $customernameITLocalAccountsSID

    # Write the updated content back to the XML file
    Set-Content -Path $xmlFilePath -Value $xmlContent

    Write-Host "Successfully updated 'customername' to 'its' and old SIDs to new SIDs in the XML file."
} else {
    Write-Host "The specified XML file does not exist."
}


###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "BETA - User AVD settings" ###

# Define variables
$GPOName = "BETA - User AVD settings"
$PopUpServer1 = "http://${CustomerName}betakfx01.${GPO_Domain}"
$PopUpServer2 = "http://${CustomerName}betakfx01"
$AppServer1 = "http://${CustomerName}betaapp01.${GPO_Domain}"
$AppServer2 = "http://${CustomerName}betaapp01"
$WebServer1 = "http://${CustomerName}betaweb01.${GPO_Domain}"
$WebServer2 = "http://${CustomerName}betaweb01"
$ssrsServer1 = "http://${CustomerName}betassrs01.${GPO_Domain}"
$ssrsServer2 = "http://${CustomerName}betassrs01"
$ssrsServer3 = "http://${CustomerName}betassrs01/Reports"

# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}


# Path for Computer Configuration registry settings
$RegistryPath1 = "HKCU\SOFTWARE\Policies\Microsoft\Internet Explorer\New Windows\Allow"
$RegistryPath2 = "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"


# Create an array of registry values to remove
$oldRegistryValues = @(
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameuatkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernamebetakfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernamebetakfx01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernamebetaapp01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernamebetaapp01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernamebetaweb01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernamebetaweb01.customername.oncustomername.co.uk' }
)

# Loop through each registry value and remove it
foreach ($params in $oldRegistryValues) {
    Remove-GPRegistryValue @params
}

# Pop Up Internet Explorer - needs updating to use user not computer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer2 -Type String -Value $PopUpServer2

# Windows Components/Internet Explorer/Internet Control Panel/Security Page/Site to Zone Assignment List - needs updating to use user not computer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer2 -Type String -Value 2

# Permissions are handled separately in AD or GPO settings; to add delegation:
# Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# Print completion message
Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "PPD - Browser settings" ###

# Define variables
$GPOName = "PPD - Browser settings"
$PopUpServer1 = "http://${CustomerName}ppdkfx01.${GPO_Domain}"
$PopUpServer2 = "http://${CustomerName}ppdkfx01"
$AppServer1 = "http://${CustomerName}ppdapp01.${GPO_Domain}"
$AppServer2 = "http://${CustomerName}ppdapp01"
$WebServer1 = "http://${CustomerName}ppdweb01.${GPO_Domain}"
$WebServer2 = "http://${CustomerName}ppdweb01"
$ssrsServer1 = "http://${CustomerName}ppdssrs01.${GPO_Domain}"
$ssrsServer2 = "http://${CustomerName}ppdssrs01"
$ssrsServer3 = "http://${CustomerName}ppdssrs01/Reports"

# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}


# Path for Computer Configuration registry settings
$RegistryPath1 = "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\New Windows\Allow"
$RegistryPath2 = "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"
$RegistryPath3 = "HKCU\Software\Policies\Microsoft\Edge\URLAllowlist"
$RegistryPath4 = "HKCU\Software\Policies\Microsoft\Edge"
$RegistryPath5 = "HKCU\Software\Policies\Microsoft\Edge\PopupsAllowedForUrls"


# Create an array of registry values to remove
$oldRegistryValues = @(
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameppdkfx01.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameppdtkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameppdkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameppdkfx01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameppdapp01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameppdapp01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameppdweb01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameppdweb01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameppdssrs01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameppdssrs01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameppdssrs01/Reports' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '1' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '2' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '9' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '10' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '22' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '24' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '25' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '26' },
    @{ Name = $GPOName; Key = $RegistryPath4; ValueName = 'HomepageLocation' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '1' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '2' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '3' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '4' }
)

# Loop through each registry value and remove it
foreach ($params in $oldRegistryValues) {
    Remove-GPRegistryValue @params
}

# MS Edge - URL Allow List
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '1' -Type String -Value "*${PopUpServer2}"
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '2' -Type String -Value $WebServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '9' -Type String -Value $WebServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '10' -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '22' -Type String -Value "${PopUpServer2}:8081"
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '24' -Type String -Value $ssrsServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '25' -Type String -Value $ssrsServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '26' -Type String -Value $ssrsServer3

# MS Edge
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath4 -ValueName 'HomepageLocation' -Type String -Value "${PopUpServer2}:8081/start/home.html"

# MS Edge - PopupsAllowedForUrls
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '1' -Type String -Value $PopUpServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '2' -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '3' -Type String -Value $WebServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '4' -Type String -Value $WebServer2

# Pop Up Internet Explorer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer1 -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer2 -Type String -Value $PopUpServer2

# Windows Components/Internet Explorer/Internet Control Panel/Security Page/Site to Zone Assignment List
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer2 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer3 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer2 -Type String -Value 2

# Permissions are handled separately in AD or GPO settings; to add delegation:
# Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# Print completion message
Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "PPD - Local groups" ###

# Define the path to the XML file
$GpoLookup = (get-gpo -Name "PPD - Local groups").Id
$xmlFilePath = "\\${GPO_Domain}\SYSVOL\${GPO_Domain}\Policies\{${GpoLookup}}\Machine\Preferences\Groups\Groups.xml"


# Old name and new name for replacement
$oldName = "customername"
$newName = $CustomerName

# Define the old SIDs
$customernameITLocalAccountsOldSID = "S-1-5-21-281918534-52708182-3417967371-1488"
$customernameppdAccessOldSID = "S-1-5-21-281918534-52708182-3417967371-2058"
$customernameCstDevLocalOldSID = "S-1-5-21-281918534-52708182-3417967371-1479"
$customernameppdWebAdminOldSID = "S-1-5-21-281918534-52708182-3417967371-1985"
$customernameppdVMAdminOldSID = "S-1-5-21-281918534-52708182-3417967371-1953"
$customernameServiceDeskLocalOldSID = "S-1-5-21-281918534-52708182-3417967371-1516"
$customernameBuzzLocalOldSID = "S-1-5-21-281918534-52708182-3417967371-1836"
$customernameppdVMAccessOldSID = "S-1-5-21-281918534-52708182-3417967371-1954"

# Lookup new SIDs from AD
$customernameITLocalAccountsSID = (Get-ADGroup -Identity "customername IT Local Accounts").SID.Value
$customernameppdAccessSID = (Get-ADGroup -Identity "customername ppd Access").SID.Value
$customernameCstDevLocalSID = (Get-ADGroup -Identity "customername CST Devs Local Account").SID.Value
$customernameppdWebAdminSID = (Get-ADGroup -Identity "customername ppd Web VM Admin").SID.Value
$customernameppdVMAdminSID = (Get-ADGroup -Identity "customername PPD VM Admins Access").SID.Value
$customernameServiceDeskLocalSID = (Get-ADGroup -Identity "customername ServiceDesk Local Accounts").SID.Value
$customernameBuzzLocalSID = (Get-ADGroup -Identity "customername Buzz Local Accounts").SID.Value
$customernameppdVMAccessSID = (Get-ADGroup -Identity "customername ppd VM Access").SID.Value

# Check if the XML file exists
if (Test-Path $xmlFilePath) {
    # Read the contents of the XML file
    $xmlContent = Get-Content $xmlFilePath

    # Replace 'customername' with 'its'
    $xmlContent = $xmlContent -replace [regex]::Escape($oldName), $newName

    # Replace old SIDs with new SIDs
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameppdAccessOldSID), $customernameppdAccessSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameITLocalAccountsOldSID), $customernameITLocalAccountsSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameCstDevLocalOldSID), $customernameCstDevLocalSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameppdWebAdminOldSID), $customernameppdWebAdminSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameServiceDeskLocalOldSID), $customernameServiceDeskLocalSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameBuzzLocalOldSID), $customernameBuzzLocalSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameppdVMAccessOldSID), $customernameppdVMAccessSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameppdVMAdminOldSID), $customernameppdVMAdminSID

    # Write the updated content back to the XML file
    Set-Content -Path $xmlFilePath -Value $xmlContent

    Write-Host "Successfully updated 'customername' to 'its' and old SIDs to new SIDs in the XML file."
} else {
    Write-Host "The specified XML file does not exist."
}

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "PPD - User AVD settings" ###

# Define variables
$GPOName = "PPD - User AVD settings"
$PopUpServer1 = "http://${CustomerName}ppdkfx01.${GPO_Domain}"
$PopUpServer2 = "http://${CustomerName}ppdkfx01"
$AppServer1 = "http://${CustomerName}ppdapp01.${GPO_Domain}"
$AppServer2 = "http://${CustomerName}ppdapp01"
$WebServer1 = "http://${CustomerName}ppdweb01.${GPO_Domain}"
$WebServer2 = "http://${CustomerName}ppdweb01"
$ssrsServer1 = "http://${CustomerName}ppdssrs01.${GPO_Domain}"
$ssrsServer2 = "http://${CustomerName}ppdssrs01"
$ssrsServer3 = "http://${CustomerName}ppdssrs01/Reports"

# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}


# Path for Computer Configuration registry settings
$RegistryPath1 = "HKCU\SOFTWARE\Policies\Microsoft\Internet Explorer\New Windows\Allow"
$RegistryPath2 = "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"


# Create an array of registry values to remove
$oldRegistryValues = @(
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameuatkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatkfx01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatapp01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatapp01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatweb01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatweb01.customername.oncustomername.co.uk' }
)

# Loop through each registry value and remove it
foreach ($params in $oldRegistryValues) {
    Remove-GPRegistryValue @params
}

# Pop Up Internet Explorer - needs updating to use user not computer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer2 -Type String -Value $PopUpServer2

# Windows Components/Internet Explorer/Internet Control Panel/Security Page/Site to Zone Assignment List - needs updating to use user not computer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer2 -Type String -Value 2

# Permissions are handled separately in AD or GPO settings; to add delegation:
# Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# Print completion message
Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "PROD - Browser settings" ###

# Define variables
$GPOName = "PROD - Browser settings"
$PopUpServer1 = "http://${CustomerName}prodkfx01.${GPO_Domain}"
$PopUpServer2 = "http://${CustomerName}prodkfx01"
$PopUpServer3 = "http://${CustomerName}prodkfxserver01.${GPO_Domain}"
$PopUpServer4 = "http://${CustomerName}prodkfxserver01"
$AppServer1 = "http://${CustomerName}prodapp01.${GPO_Domain}"
$AppServer2 = "http://${CustomerName}prodapp01"
$AppServer3 = "http://${CustomerName}prodappserver01.${GPO_Domain}"
$AppServer4 = "http://${CustomerName}prodappserver01"
$WebServer1 = "http://${CustomerName}prodweb01.${GPO_Domain}"
$WebServer2 = "http://${CustomerName}prodweb01"
$WebServer3 = "http://${CustomerName}prodwebserver01.${GPO_Domain}"
$WebServer4 = "http://${CustomerName}prodwebserver01"
$ssrsServer1 = "http://${CustomerName}prodssrs01.${GPO_Domain}"
$ssrsServer2 = "http://${CustomerName}prodssrs01"
$ssrsServer3 = "http://${CustomerName}prodssrs01/Reports"
$ssrsServer4 = "http://${CustomerName}prodssrsserver01.${GPO_Domain}"
$ssrsServer5 = "http://${CustomerName}prodssrsserver01"
$ssrsServer6 = "http://${CustomerName}prodssrsserver01/Reports"
$ssrsServer7 = "http://${CustomerName}prodssrsserver01.${GPO_Domain}/Reports"

# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}


# Path for Computer Configuration registry settings
$RegistryPath1 = "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\New Windows\Allow"
$RegistryPath2 = "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"
$RegistryPath3 = "HKCU\Software\Policies\Microsoft\Edge\URLAllowlist"
$RegistryPath4 = "HKCU\Software\Policies\Microsoft\Edge"
$RegistryPath5 = "HKCU\Software\Policies\Microsoft\Edge\PopupsAllowedForUrls"


# Create an array of registry values to remove
$oldRegistryValues = @(
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameprodkfx01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameprodkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameprodkfxserver01' },
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameprodkfxserver01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodkfx01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodapp01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodapp01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodweb01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodweb01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodssrs01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodssrs01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodssrs01/Reports' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodkfxserver01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodkfxserver01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodappserver01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodappserver01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodssrsserver01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodssrsserver01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodwebserver01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodwebserver01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '1' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '2' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '9' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '10' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '22' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '24' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '25' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '26' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '27' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '28' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '29' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '30' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '31' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '32' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '33' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '34' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '35' },
    @{ Name = $GPOName; Key = $RegistryPath4; ValueName = 'HomepageLocation' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '1' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '2' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '3' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '4' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '5' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '6' }
)

# Loop through each registry value and remove it
foreach ($params in $oldRegistryValues) {
    Remove-GPRegistryValue @params
}

# MS Edge - URL Allow List
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '1' -Type String -Value "*${PopUpServer2}"
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '2' -Type String -Value $WebServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '9' -Type String -Value $WebServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '10' -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '22' -Type String -Value "${PopUpServer2}:8081"
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '24' -Type String -Value $ssrsServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '25' -Type String -Value $ssrsServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '26' -Type String -Value $ssrsServer3
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '27' -Type String -Value $AppServer4
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '28' -Type String -Value $ssrsServer5
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '29' -Type String -Value $WebServer4
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '30' -Type String -Value $PopUpServer4
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '31' -Type String -Value $AppServer3
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '32' -Type String -Value $ssrsServer4
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '33' -Type String -Value $WebServer3
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '34' -Type String -Value $ssrsServer6
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '35' -Type String -Value $ssrsServer7


# MS Edge
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath4 -ValueName 'HomepageLocation' -Type String -Value "${PopUpServer2}:8081/start/home.html"

# MS Edge - PopupsAllowedForUrls
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '1' -Type String -Value $PopUpServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '2' -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '3' -Type String -Value $WebServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '4' -Type String -Value $WebServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '5' -Type String -Value $PopUpServer3
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '6' -Type String -Value $PopUpServer4

# Pop Up Internet Explorer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer1 -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer2 -Type String -Value $PopUpServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer3 -Type String -Value $PopUpServer3
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer4 -Type String -Value $PopUpServer4

# Windows Components/Internet Explorer/Internet Control Panel/Security Page/Site to Zone Assignment List
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer2 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer3 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer4 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer2 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer3 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer4 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer2 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer3 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer4 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer5 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer2 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer3 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer4 -Type String -Value 2

# Permissions are handled separately in AD or GPO settings; to add delegation:
# Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# Print completion message
Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "PROD - Local groups" ###

# Define the path to the XML file
$GpoLookup = (get-gpo -Name "PROD - Local groups").Id
$xmlFilePath = "\\${GPO_Domain}\SYSVOL\${GPO_Domain}\Policies\{${GpoLookup}}\Machine\Preferences\Groups\Groups.xml"


# Old name and new name for replacement
$oldName = "customername"
$newName = $CustomerName

# Define the old SIDs
$customernameITLocalAccountsOldSID = "S-1-5-21-281918534-52708182-3417967371-1488"
$customernameProdAccessOldSID = "S-1-5-21-281918534-52708182-3417967371-2059"
$customernameCstDevLocalOldSID = "S-1-5-21-281918534-52708182-3417967371-1479"
$customernameProdWebAdminOldSID = "S-1-5-21-281918534-52708182-3417967371-1952"
$customernameProdVMAdminOldSID = "S-1-5-21-281918534-52708182-3417967371-1648"
$customernameServiceDeskLocalOldSID = "S-1-5-21-281918534-52708182-3417967371-1516"
$customernameBuzzLocalOldSID = "S-1-5-21-281918534-52708182-3417967371-1836"
$customernameProdVMAccessOldSID = "S-1-5-21-281918534-52708182-3417967371-1649"

# Lookup new SIDs from AD
$customernameITLocalAccountsSID = (Get-ADGroup -Identity "customername IT Local Accounts").SID.Value
$customernameProdAccessSID = (Get-ADGroup -Identity "customername Prod Access").SID.Value
$customernameCstDevLocalSID = (Get-ADGroup -Identity "customername CST Devs Local Account").SID.Value
$customernameProdWebAdminSID = (Get-ADGroup -Identity "customername Prod Web VM Admin").SID.Value
$customernameProdVMAdminSID = (Get-ADGroup -Identity "customername Prod VM Admin").SID.Value
$customernameServiceDeskLocalSID = (Get-ADGroup -Identity "customername ServiceDesk Local Accounts").SID.Value
$customernameBuzzLocalSID = (Get-ADGroup -Identity "customername Buzz Local Accounts").SID.Value
$customernameProdVMAccessSID = (Get-ADGroup -Identity "customername Prod VM Access").SID.Value

# Check if the XML file exists
if (Test-Path $xmlFilePath) {
    # Read the contents of the XML file
    $xmlContent = Get-Content $xmlFilePath

    # Replace 'customername' with 'its'
    $xmlContent = $xmlContent -replace [regex]::Escape($oldName), $newName

    # Replace old SIDs with new SIDs
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameProdAccessOldSID), $customernameProdAccessSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameITLocalAccountsOldSID), $customernameITLocalAccountsSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameCstDevLocalOldSID), $customernameCstDevLocalSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameProdWebAdminOldSID), $customernameProdWebAdminSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameServiceDeskLocalOldSID), $customernameServiceDeskLocalSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameBuzzLocalOldSID), $customernameBuzzLocalSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameProdVMAccessOldSID), $customernameProdVMAccessSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameProdVMAdminOldSID), $customernameProdVMAdminSID

    # Write the updated content back to the XML file
    Set-Content -Path $xmlFilePath -Value $xmlContent

    Write-Host "Successfully updated 'customername' to 'its' and old SIDs to new SIDs in the XML file."
} else {
    Write-Host "The specified XML file does not exist."
}

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "PROD - User AVD settings" ###

# Define variables
$GPOName = "PROD - User AVD settings"
$PopUpServer1 = "http://${CustomerName}prodkfx01.${GPO_Domain}"
$PopUpServer2 = "http://${CustomerName}prodkfx01"
$AppServer1 = "http://${CustomerName}prodapp01.${GPO_Domain}"
$AppServer2 = "http://${CustomerName}prodapp01"
$WebServer1 = "http://${CustomerName}prodweb01.${GPO_Domain}"
$WebServer2 = "http://${CustomerName}prodweb01"
$ssrsServer1 = "http://${CustomerName}prodssrs01.${GPO_Domain}"
$ssrsServer2 = "http://${CustomerName}prodssrs01"
$ssrsServer3 = "http://${CustomerName}prodssrs01/Reports"

# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}


# Path for Computer Configuration registry settings
$RegistryPath1 = "HKCU\SOFTWARE\Policies\Microsoft\Internet Explorer\New Windows\Allow"
$RegistryPath2 = "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"


# Create an array of registry values to remove
$oldRegistryValues = @(
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameprodkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodkfx01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodapp01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodapp01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodweb01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameprodweb01.customername.oncustomername.co.uk' }
)

# Loop through each registry value and remove it
foreach ($params in $oldRegistryValues) {
    Remove-GPRegistryValue @params
}

# Pop Up Internet Explorer - needs updating to use user not computer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer2 -Type String -Value $PopUpServer2

# Windows Components/Internet Explorer/Internet Control Panel/Security Page/Site to Zone Assignment List - needs updating to use user not computer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer2 -Type String -Value 2

# Permissions are handled separately in AD or GPO settings; to add delegation:
# Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# Print completion message
Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "UAT - Browser settings" ###

# Define variables
$GPOName = "UAT - Browser settings"
$PopUpServer1 = "http://${CustomerName}uatkfx01.${GPO_Domain}"
$PopUpServer2 = "http://${CustomerName}uatkfx01"
$PopUpServer3 = "http://${CustomerName}uatkfxserver01.${GPO_Domain}"
$PopUpServer4 = "http://${CustomerName}uatkfxserver01"
$AppServer1 = "http://${CustomerName}uatapp01.${GPO_Domain}"
$AppServer2 = "http://${CustomerName}uatapp01"
$AppServer3 = "http://${CustomerName}uatappserver01.${GPO_Domain}"
$AppServer4 = "http://${CustomerName}uatappserver01"
$WebServer1 = "http://${CustomerName}uatweb01.${GPO_Domain}"
$WebServer2 = "http://${CustomerName}uatweb01"
$WebServer3 = "http://${CustomerName}uatwebserver01.${GPO_Domain}"
$WebServer4 = "http://${CustomerName}uatwebserver01"
$ssrsServer1 = "http://${CustomerName}uatssrs01.${GPO_Domain}"
$ssrsServer2 = "http://${CustomerName}uatssrs01"
$ssrsServer3 = "http://${CustomerName}uatssrs01/Reports"
$ssrsServer4 = "http://${CustomerName}uatssrsserver01.${GPO_Domain}"
$ssrsServer5 = "http://${CustomerName}uatssrsserver01"
$ssrsServer6 = "http://${CustomerName}uatssrsserver01/Reports"
$ssrsServer7 = "http://${CustomerName}uatssrsserver01.${GPO_Domain}/Reports"
$ssrsServer8 = "http://${CustomerName}uatssrs01.${GPO_Domain}/Reports"


# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}


# Path for Computer Configuration registry settings
$RegistryPath1 = "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\New Windows\Allow"
$RegistryPath2 = "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"
$RegistryPath3 = "HKCU\Software\Policies\Microsoft\Edge\URLAllowlist"
$RegistryPath4 = "HKCU\Software\Policies\Microsoft\Edge"
$RegistryPath5 = "HKCU\Software\Policies\Microsoft\Edge\PopupsAllowedForUrls"


# Create an array of registry values to remove
$oldRegistryValues = @(
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameuatkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameuatkfx01.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatkfx01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatapp01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatapp01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatweb01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatweb01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatssrs01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatssrs01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatssrs01/Reports' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatssrs01.customername.oncustomername.co.uk/Reports' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '1' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '2' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '9' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '10' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '22' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '24' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '25' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '26' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '27' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '28' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '29' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '30' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '31' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '32' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '33' },
    @{ Name = $GPOName; Key = $RegistryPath3; ValueName = '34' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '1' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '2' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '3' },
    @{ Name = $GPOName; Key = $RegistryPath5; ValueName = '4' }

)

# Loop through each registry value and remove it
foreach ($params in $oldRegistryValues) {
    Remove-GPRegistryValue @params
}

# MS Edge - URL Allow List
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '1' -Type String -Value "*${PopUpServer2}"
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '2' -Type String -Value $WebServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '9' -Type String -Value $WebServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '10' -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '22' -Type String -Value "${PopUpServer2}:8081"
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '24' -Type String -Value $ssrsServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '25' -Type String -Value $ssrsServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '26' -Type String -Value $ssrsServer3
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '27' -Type String -Value $AppServer4
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '28' -Type String -Value $ssrsServer5
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '29' -Type String -Value $WebServer4
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '30' -Type String -Value $PopUpServer4
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '31' -Type String -Value $AppServer3
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '32' -Type String -Value $ssrsServer4
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '33' -Type String -Value $WebServer3
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath3 -ValueName '34' -Type String -Value $ssrsServer6


# MS Edge
# Set-GPRegistryValue -Name $GPOName -Key $RegistryPath4 -ValueName 'HomepageLocation' -Type String -Value "${PopUpServer2}:8081/start/home.html"

# MS Edge - PopupsAllowedForUrls
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '1' -Type String -Value $PopUpServer2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '2' -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '3' -Type String -Value $WebServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath5 -ValueName '4' -Type String -Value $WebServer2

# Pop Up Internet Explorer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer1 -Type String -Value $PopUpServer1
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer2 -Type String -Value $PopUpServer2

# Windows Components/Internet Explorer/Internet Control Panel/Security Page/Site to Zone Assignment List
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer2 -Type String -Value 2


Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer2 -Type String -Value 2


Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer2 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer3 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $ssrsServer8 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer2 -Type String -Value 2


# Permissions are handled separately in AD or GPO settings; to add delegation:
# Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# Print completion message
Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "UAT - Local groups" ###

# Define the path to the XML file
$GpoLookup = (get-gpo -Name "UAT - Local groups").Id
$xmlFilePath = "\\${GPO_Domain}\SYSVOL\${GPO_Domain}\Policies\{${GpoLookup}}\Machine\Preferences\Groups\Groups.xml"


# Old name and new name for replacement
$oldName = "customername"
$newName = $CustomerName

# Define the old SIDs
$customernameITLocalAccountsOldSID = "S-1-5-21-281918534-52708182-3417967371-1488"
$customernameuatAccessOldSID = "S-1-5-21-281918534-52708182-3417967371-2055"
$customernameCstDevLocalOldSID = "S-1-5-21-281918534-52708182-3417967371-1479"
$customernameuatWebAdminOldSID = "S-1-5-21-281918534-52708182-3417967371-1952"
$customernameuatVMAdminOldSID = "S-1-5-21-281918534-52708182-3417967371-1514"
$customernameServiceDeskLocalOldSID = "S-1-5-21-281918534-52708182-3417967371-1516"
$customernameBuzzLocalOldSID = "S-1-5-21-281918534-52708182-3417967371-1836"
$customernameuatVMAccessOldSID = "S-1-5-21-281918534-52708182-3417967371-1515"

# Lookup new SIDs from AD
$customernameITLocalAccountsSID = (Get-ADGroup -Identity "customername IT Local Accounts").SID.Value
$customernameuatAccessSID = (Get-ADGroup -Identity "customername UAT Access").SID.Value
$customernameCstDevLocalSID = (Get-ADGroup -Identity "customername CST Devs Local Account").SID.Value
$customernameuatWebAdminSID = (Get-ADGroup -Identity "customername UAT Web VM Admin").SID.Value
$customernameuatVMAdminSID = (Get-ADGroup -Identity "customername UAT VM Admins").SID.Value
$customernameServiceDeskLocalSID = (Get-ADGroup -Identity "customername ServiceDesk Local Accounts").SID.Value
$customernameBuzzLocalSID = (Get-ADGroup -Identity "customername Buzz Local Accounts").SID.Value
$customernameuatVMAccessSID = (Get-ADGroup -Identity "customername UAT VM Access").SID.Value

# Check if the XML file exists
if (Test-Path $xmlFilePath) {
    # Read the contents of the XML file
    $xmlContent = Get-Content $xmlFilePath

    # Replace 'customername' with 'its'
    $xmlContent = $xmlContent -replace [regex]::Escape($oldName), $newName

    # Replace old SIDs with new SIDs
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameuatAccessOldSID), $customernameuatAccessSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameITLocalAccountsOldSID), $customernameITLocalAccountsSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameCstDevLocalOldSID), $customernameCstDevLocalSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameuatWebAdminOldSID), $customernameuatWebAdminSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameServiceDeskLocalOldSID), $customernameServiceDeskLocalSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameBuzzLocalOldSID), $customernameBuzzLocalSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameuatVMAccessOldSID), $customernameuatVMAccessSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameuatVMAdminOldSID), $customernameuatVMAdminSID

    # Write the updated content back to the XML file
    Set-Content -Path $xmlFilePath -Value $xmlContent

    Write-Host "Successfully updated 'customername' to 'its' and old SIDs to new SIDs in the XML file."
} else {
    Write-Host "The specified XML file does not exist."
}

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "UAT - User AVD settings" ###

# Define variables
$GPOName = "UAT - User AVD settings"
$PopUpServer1 = "http://${CustomerName}uatkfx01.${GPO_Domain}"
$PopUpServer2 = "http://${CustomerName}uatkfx01"
$AppServer1 = "http://${CustomerName}uatapp01.${GPO_Domain}"
$AppServer2 = "http://${CustomerName}uatapp01"
$WebServer1 = "http://${CustomerName}uatweb01.${GPO_Domain}"
$WebServer2 = "http://${CustomerName}uatweb01"
$ssrsServer1 = "http://${CustomerName}uatssrs01.${GPO_Domain}"
$ssrsServer2 = "http://${CustomerName}uatssrs01"
$ssrsServer3 = "http://${CustomerName}uatssrs01/Reports"

# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}


# Path for Computer Configuration registry settings
$RegistryPath1 = "HKCU\SOFTWARE\Policies\Microsoft\Internet Explorer\New Windows\Allow"
$RegistryPath2 = "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"


# Create an array of registry values to remove
$oldRegistryValues = @(
    @{ Name = $GPOName; Key = $RegistryPath1; ValueName = 'http://customernameuatkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatkfx01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatkfx01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatapp01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatapp01.customername.oncustomername.co.uk' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatweb01' },
    @{ Name = $GPOName; Key = $RegistryPath2; ValueName = 'http://customernameuatweb01.customername.oncustomername.co.uk' }
)

# Loop through each registry value and remove it
foreach ($params in $oldRegistryValues) {
    Remove-GPRegistryValue @params
}

# Pop Up Internet Explorer - needs updating to use user not computer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath1 -ValueName $PopUpServer2 -Type String -Value $PopUpServer2

# Windows Components/Internet Explorer/Internet Control Panel/Security Page/Site to Zone Assignment List - needs updating to use user not computer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $PopUpServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $AppServer2 -Type String -Value 2

Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer1 -Type String -Value 2
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath2 -ValueName $WebServer2 -Type String -Value 2

# Permissions are handled separately in AD or GPO settings; to add delegation:
# Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# Print completion message
Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################


### GPO Name - "SECURE - Local groups" ###

# Define the path to the XML file
$GpoLookup = (get-gpo -Name "SECURE - Local groups").Id
$xmlFilePath = "\\${GPO_Domain}\SYSVOL\${GPO_Domain}\Policies\{${GpoLookup}}\Machine\Preferences\Groups\Groups.xml"


# Old name and new name for replacement
$oldName = "customername"
$newName = $CustomerName

# Define the old SIDs
$customernameSzAccessOldSID = "S-1-5-21-281918534-52708182-3417967371-2006"
$customernameITLocalAccountsOldSID = "S-1-5-21-281918534-52708182-3417967371-1488"

# Lookup new SIDs from AD
$customernameSzAccessSID = (Get-ADGroup -Identity "$CustomerName Secure Zone Access").SID.Value
$customernameITLocalAccountsSID = (Get-ADGroup -Identity "customername IT Local Accounts").SID.Value

# Check if the XML file exists
if (Test-Path $xmlFilePath) {
    # Read the contents of the XML file
    $xmlContent = Get-Content $xmlFilePath

    # Replace 'customername' with 'its'
    $xmlContent = $xmlContent -replace [regex]::Escape($oldName), $newName

    # Replace old SIDs with new SIDs
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameSzAccessOldSID), $customernameSzAccessSID
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameITLocalAccountsOldSID), $customernameITLocalAccountsSID

    # Write the updated content back to the XML file
    Set-Content -Path $xmlFilePath -Value $xmlContent

    Write-Host "Successfully updated 'customername' to 'its' and old SIDs to new SIDs in the XML file."
} else {
    Write-Host "The specified XML file does not exist."
}

$xmlFilePath = "\\${GPO_Domain}\SYSVOL\${GPO_Domain}\Policies\{${GpoLookup}}\User\Preferences\Groups\Groups.xml"

# Check if the XML file exists
if (Test-Path $xmlFilePath) {
    # Read the contents of the XML file
    $xmlContent = Get-Content $xmlFilePath

    # Replace 'customername' with 'its'
    $xmlContent = $xmlContent -replace [regex]::Escape($oldName), $newName

    # Replace old SIDs with new SIDs
    $xmlContent = $xmlContent -replace [regex]::Escape($customernameITLocalAccountsOldSID), $customernameITLocalAccountsSID

    # Write the updated content back to the XML file
    Set-Content -Path $xmlFilePath -Value $xmlContent

    Write-Host "Successfully updated 'customername' to 'its' and old SIDs to new SIDs in the XML file."
} else {
    Write-Host "The specified XML file does not exist."
}



###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "SECURE - Mapped Drive" ###

# Define variables
$GPOName = "SECURE - Mapped Drive"
# $GPO_Domain = "itsandbox.co.uk" # now passed as a parameter instead.
$MappedDrive = "\\sa${CustomerName}szdatain.file.core.windows.net\data-in"
$currentUser = $Env:UserName
$currentUserSID = (Get-ADUser -Identity $currentUser).SID.Value
$newScriptName = "\\$GPO_Domain\SYSVOL\$GPO_Domain\Policies\Scripts\secureroomoutdrive.bat"

# Path for Computer Configuration registry settings
# $RegistryPath = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\$currentUserSID\Scripts\Logon\0\0"
$RegistryPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\Logon\0\0"


# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}

# # Create an array of registry values to remove
# $oldRegistryValues = @(
#     @{ Name = $GPOName; Key = $RegistryPath; ValueName = 'Script' }
# )

# # Loop through each registry value and remove it
# foreach ($params in $oldRegistryValues) {
#     Remove-GPRegistryValue @params
# }

# Pop Up Internet Explorer - needs updating to use user not computer
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath -ValueName "Script" -Type String -Value $newScriptName

# Define the path to the XML file
$GpoLookup = (get-gpo -Name "secure - mapped drive").Id
$xmlFilePath = "\\${GPO_Domain}\SYSVOL\${GPO_Domain}\Policies\{${GpoLookup}}\User\Preferences\Drives\Drives.xml"

# Old name and new name for replacement
$oldName = "customername"
$newName = $CustomerName


# Check if the XML file exists
if (Test-Path $xmlFilePath) {
    # Read the contents of the XML file
    $xmlContent = Get-Content $xmlFilePath

    # Replace 'customername' with 'its'
    $xmlContent = $xmlContent -replace [regex]::Escape($oldName), $newName

    # Write the updated content back to the XML file
    Set-Content -Path $xmlFilePath -Value $xmlContent

    Write-Host "Successfully updated 'customername' to 'its' and old SIDs to new SIDs in the XML file."
} else {
    Write-Host "The specified XML file does not exist."
}

###################################################################################################################################################
###################################################################################################################################################

### GPO Name - "SZ - Edge Default" ###

# Define variables
$GPOName = "SZ - Edge Default"
# $GPO_Domain = "itsandbox.co.uk" # now passed as a parameter instead.
$DefaultAssociationsConfig = "\\${CustomerName}hubmgt01.${GPO_Domain}\DomainScripts\edge_default.xml"


# Create a new GPO if it doesn't exist
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Domain $GPO_Domain
    Write-Output "GPO '$GPOName' created."
} else {
    Write-Output "GPO '$GPOName' already exists."
}

# Path for Computer Configuration registry settings
$RegistryPath = "HKLM\\SOFTWARE\Policies\Microsoft\Windows\System"

# Set DefaultAssociationsConfiguration
Set-GPRegistryValue -Name $GPOName -Key $RegistryPath -ValueName "DefaultAssociationsConfiguration" -Type String -Value $DefaultAssociationsConfig

# Permissions are handled separately in AD or GPO settings; to add delegation:
# Example: Grant 'Apply' permission for 'Authenticated Users' on the GPO
Set-GPPermissions -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoApply

# Print completion message
Write-Output "GPO '$GPOName' has been configured with the specified settings."

###################################################################################################################################################
###################################################################################################################################################

##--## Link GPOs to OUs ##--##

$adDomain = (Get-ADDomain).DistinguishedName

# "Event Log GPO"
New-GPLink -Name "Event Log GPO" -Target "OU=Domain Controllers,$adDomain"

# "Default Password Policy"
New-GPLink -Name "Default Password Policy" -Target "OU=beta,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "Default Password Policy" -Target "OU=uat,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "Default Password Policy" -Target "OU=prod,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "Default Password Policy" -Target "OU=ppd,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "Default Password Policy" -Target "OU=hub,$adDomain"

# "AADDC Computers GPO"
New-GPLink -Name "AADDC Computers GPO" -Target "OU=Computers,OU=beta,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "AADDC Computers GPO" -Target "OU=Computers,OU=uat,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "AADDC Computers GPO" -Target "OU=Computers,OU=prod,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "AADDC Computers GPO" -Target "OU=Computers,OU=ppd,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "AADDC Computers GPO" -Target "OU=AADDC Computers,$adDomain" # May already be linked and auto created as part of Entra Domain Services deployment

# "All - AVD Licence"
New-GPLink -Name "All - AVD Licence" -Target "OU=Computers,OU=beta,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - AVD Licence" -Target "OU=Computers,OU=uat,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - AVD Licence" -Target "OU=Computers,OU=prod,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - AVD Licence" -Target "OU=Computers,OU=ppd,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - AVD Licence" -Target "OU=AADDC Computers,$adDomain"

# "All - Backinfo"
New-GPLink -Name "All - Backinfo" -Target "OU=Computers,OU=beta,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - Backinfo" -Target "OU=Computers,OU=uat,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - Backinfo" -Target "OU=Computers,OU=prod,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - Backinfo" -Target "OU=Computers,OU=ppd,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - Backinfo" -Target "OU=Computers,OU=hub,$adDomain"
New-GPLink -Name "All - Backinfo" -Target "OU=Computers,OU=sz,$adDomain"
New-GPLink -Name "All - Backinfo" -Target "OU=AADDC Computers,$adDomain"

# "All - File Associations "
New-GPLink -Name "All - File Associations " -Target "OU=Computers,OU=beta,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - File Associations " -Target "OU=Computers,OU=uat,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - File Associations " -Target "OU=Computers,OU=prod,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - File Associations " -Target "OU=Computers,OU=ppd,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - File Associations " -Target "OU=Computers,OU=sz,$adDomain"

# "All - Security Settings"
New-GPLink -Name "All - Security Settings" -Target "OU=Computers,OU=hub,$adDomain"
New-GPLink -Name "All - Security Settings" -Target "OU=Computers,OU=sz,$adDomain"
New-GPLink -Name "All - Security Settings" -Target "OU=AADDC Computers,$adDomain"

# "All - Session timeout"
New-GPLink -Name "All - Session timeout" -Target "OU=Computers,OU=beta,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - Session timeout" -Target "OU=Computers,OU=uat,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - Session timeout" -Target "OU=Computers,OU=prod,$adDomain" # Covers both Computers & AVD OU
New-GPLink -Name "All - Session timeout" -Target "OU=Computers,OU=ppd,$adDomain" # Covers both Computers & AVD OU

# "BETA - Browser settings"
New-GPLink -Name "BETA - Browser settings" -Target "OU=Computers,OU=beta,$adDomain" # Covers both Computers & AVD OU

# "BETA - Local groups"
New-GPLink -Name "BETA - Local groups" -Target "OU=Computers,OU=beta,$adDomain" # Covers both Computers & AVD OU

# "BETA - User AVD settings"
New-GPLink -Name "BETA - User AVD settings" -Target "OU=avd,OU=Computers,OU=beta,$adDomain" # Covers both Computers & AVD OU

# "UAT - Browser settings"
New-GPLink -Name "UAT - Browser settings" -Target "OU=Computers,OU=uat,$adDomain" # Covers both Computers & AVD OU

# "UAT - Local groups"
New-GPLink -Name "UAT - Local groups" -Target "OU=Computers,OU=uat,$adDomain" # Covers both Computers & AVD OU

# "UAT - User AVD settings"
New-GPLink -Name "UAT - User AVD settings" -Target "OU=avd,OU=Computers,OU=uat,$adDomain" # Covers both Computers & AVD OU

# "PPD - Browser settings"
New-GPLink -Name "PPD - Browser settings" -Target "OU=Computers,OU=ppd,$adDomain" # Covers both Computers & AVD OU

# "PPD - Local groups"
New-GPLink -Name "PPD - Local groups" -Target "OU=Computers,OU=ppd,$adDomain" # Covers both Computers & AVD OU

# "PPD - User AVD settings"
New-GPLink -Name "PPD - User AVD settings" -Target "OU=avd,OU=Computers,OU=ppd,$adDomain" # Covers both Computers & AVD OU

# "PROD - Browser settings"
New-GPLink -Name "PROD - Browser settings" -Target "OU=avd,OU=Computers,OU=prod,$adDomain" # customername PROD different to other ENVs at current 29/10/24 can scope to computers if we need to include the prod servers.

# "PROD - Local groups"
New-GPLink -Name "PROD - Local groups" -Target "OU=Computers,OU=prod,$adDomain" # Covers both Computers & AVD OU

# "PROD - User AVD settings"
New-GPLink -Name "PROD - User AVD settings" -Target "OU=avd,OU=Computers,OU=prod,$adDomain" # Covers both Computers & AVD OU

# "SECURE - Local groups"
New-GPLink -Name "SECURE - Local groups" -Target "OU=Computers,OU=sz,$adDomain"

# "SECURE - Mapped Drive"
New-GPLink -Name "SECURE - Mapped Drive" -Target "OU=Computers,OU=sz,$adDomain"

# "SZ - Edge Default"
New-GPLink -Name "SZ - Edge Default" -Target "OU=Computers,OU=sz,$adDomain"

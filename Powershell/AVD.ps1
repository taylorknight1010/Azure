[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$SourceVmName,
    [Parameter(Mandatory)]
    [string]$resourceGroupName,
    [Parameter(Mandatory)]
    [string]$CustomerName,
    [Parameter(Mandatory)]
    [string]$DomainNetbiosName
)

# This script should be used to run maintenance for SBL & KGM (any customer that uses Active Directory Domain Services ADDS)
# This script is configured for production

Write-Verbose "Prompting for credentials for local admin password for session host creation - Line 20-22" -Verbose
Start-Sleep -Seconds 5
$creds = Get-Credential -Message "Enter VM Local admin credentials"


Write-Verbose "Prompting for credentials for domain joining session hosts - format fqdn\username" -Verbose
Start-Sleep -Seconds 5
$djcreds = Get-Credential -Message "Enter Your Domain Join Credentials"


# Powershell KQL query search for Maintenance Config run called Image
Write-Verbose -Message "Checking Image Server Patch Status" -Verbose

$imagepatchstatus = Search-AzGraph -Query 'maintenanceresources
| where type =~ "microsoft.maintenance/maintenanceconfigurations/applyupdates"
| where properties.startDateTime > ago(30d)
| where properties.maintenanceConfiguration.properties.maintenanceScope == "InGuestPatch"
| where properties.maintenanceConfiguration.name contains "Image"
| project name, properties, id
| extend joinId = tolower(properties.maintenanceConfigurationId)
| join kind=leftouter (
    resources
    | where type =~ "microsoft.maintenance/maintenanceconfigurations"
    | extend maintenanceConfigId = tolower(id)
    | project maintenanceConfigId, tags
) on $left.joinId == $right.maintenanceConfigId
| extend status = tostring(properties.status)
| extend maintenanceConfigurationName = tostring(properties.maintenanceConfiguration.name)
| extend operationStartTime = todatetime(properties.startDateTime)
| extend operationEndTime = iff(properties.status =~ "InProgress", datetime(null), todatetime(properties.endDateTime))
| extend maintenanceConfigurationId = properties.maintenanceConfigurationId
| extend scheduleRunId = properties.correlationId
| extend succeededMachinesCount = properties.resourceUpdateSummary.succeeded
| extend totalMachines = properties.resourceUpdateSummary.total
| project-rename maintenanceRunId = name
| project id, maintenanceRunId, status, maintenanceConfigurationName, operationStartTime, operationEndTime, maintenanceConfigurationId, scheduleRunId, succeededMachinesCount, totalMachines, tags
| order by operationStartTime desc'

# # Checking Windows Services on Image server
# Write-Verbose -Message "Checking Image Server Services Post Patch" -Verbose

# # Define the list of critical services - we could look at azure change tracking & inventory to carry out this test but we need it enabled.
# $criticalServices = @(
#     "frxsvc",          # FS Logix App Services
#     "Dnscache",        # DNS Client
#     "HealthService",   # Microsoft Monitoring Agent
#     "Sense",           # Windows Defender ATP
#     "EventLog",        # Windows Event Log
#     "mpssvc",          # Windows Defender Firewall
#     "rdagent"          # Azure Guest VM Agent

# )

# # Function to check the status of a service
# function Check-ServiceStatus {
#     param (
#         [string]$serviceName
#     )

#     try {
#         # Get the service object
#         $service = Get-Service -Name $serviceName -ErrorAction Stop
#         # Check if the service is running
#         if ($service.Status -eq 'Running') {
#             Write-Output "$serviceName is running."
#             return $true
#         } else {
#             Write-Warning "$serviceName is not running!"
#             return $false
#         }
#     } catch {
#         Write-Error "Service $serviceName not found or could not be accessed."
#         return $false
#     }
# }

# # Main script
# $allServicesRunning = $true

# foreach ($serviceName in $criticalServices) {
#     # Check the status of each service and accumulate the result
#     $serviceIsRunning = Check-ServiceStatus -serviceName $serviceName

#     # Update the overall status
#     if (-not $serviceIsRunning) {
#         $allServicesRunning = $false
#     }
# }

# # Evaluate the overall status after the foreach loop
# if ($allServicesRunning) {
#     Write-Output "All critical services are running. Continuing with the larger script."
#     # Add logic to continue with the larger script
# } else {
#     Write-Warning "One or more critical services are not running. The larger script will not continue."
#     # Add logic to handle the failure (e.g., exit or take corrective actions)
# }

function Test-VmStatus($vmName, $resourceGroupName) {
    $vmStatus = Get-AzVM -name $vmName -resourcegroup $resourceGroupName -Status
    return (($vmstatus.Statuses | Where-Object { $_.code -match 'Powerstate' }).DisplayStatus)
}

Write-Host "Run with '-verbose' to see more output, continuing in 5 Seconds." -ForegroundColor Red
Start-Sleep 5

# Checks if status of Maintenance Config is success or failed
Write-Verbose -Message "The patching operation was successful. Continuing with the next steps..." -Verbose
    
# get current status & info
Write-Verbose "Getting Source VM & RG info..."
$date = Get-Date -Format ddMMyy
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName
$sourcevminfo = Get-AzVm -Name $sourcevmName -ResourceGroupName $resourceGroup.ResourceGroupName

# Stopping VM for creating clean snapshot
Write-Verbose "Stopping Source VM for snapshot..."
$sourcevmstatus = Test-VmStatus -vmName $SourceVmName -resourceGroupName $resourceGroup.ResourceGroupName
if ($sourcevmstatus -ne "stopped") {
    Write-Verbose -Message "Stopping Image Server VM" -Verbose
    Stop-AzVM -name $sourcevmName -resourcegroup $resourceGroupName -Force -ErrorAction SilentlyContinue
}
else {
    Write-Verbose "Source VM already in Stopped state"
}
 
# create snapshot
$snapshotName = ("snapshot_" + $date)
$vm = Get-AzVM -ResourceGroupName $resourceGroup.ResourceGroupName -Name $SourcevmName
$snapshot = New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $resourceGroup.Location  -CreateOption Copy
Write-Verbose "Creating snapshot of disk" -Verbose
New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroup.ResourceGroupName
$snapshotinfo = Get-AzSnapshot -SnapshotName $snapshotName
Write-Verbose -Message "Snapshot now created" -Verbose

#create new disk
Write-Verbose "Creating new disk from snapshot..." -Verbose
$diskCfg = New-AzDiskConfig -SkuName "StandardSSD_LRS" -Location $resourceGroup.location -CreateOption Copy -SourceResourceId $snapshotinfo.Id
$diskName = ($snapshotName + '_OS')
try {
    $disk = New-AzDisk -Disk $diskCfg -ResourceGroupName $resourceGroup.ResourceGroupName -DiskName $diskName
}
catch {
}

# delete snapshot
Write-Verbose "Deleting snapshot..." -Verbose
Remove-AzSnapshot -ResourceGroupName $snapshotinfo.ResourceGroupName -SnapshotName $snapshotinfo.Name -Force

# start source VM after snapshot
Write-Verbose -Message "Starting image VM post snapshot taken" -Verbose
Start-AzVm -Name $sourcevmName -ResourceGroupName $resourceGroup.ResourceGroupName -NoWait
do {
    $status = Test-VmStatus -vmName $sourcevmName -resourceGroupName $resourceGroup.ResourceGroupName
    Write-Verbose "Starting source VM..."
    Start-Sleep 20
} until ($status -match "running")

Write-Verbose -Message "Image Server VM is now running" -Verbose

$virtualMachineSize = $sourcevminfo.HardwareProfile.VmSize
$virtualNetworkSubnet = (Get-AzNetworkInterface -ResourceId $sourcevminfo.NetworkProfile.NetworkInterfaces.id).IpConfigurations.subnet.id

# temp vm setup
Write-Verbose "Creating nic...." -Verbose
$NicParameters = @{
    Name              = ($snapshotName.ToLower() + '_nic')
    ResourceGroupName = $ResourceGroup.resourceGroupName
    Location          = $ResourceGroup.Location
    SubnetId          = $virtualNetworkSubnet
    Force             = $true
}
$nic = New-AzNetworkInterface @NicParameters

$TempvmName = "capturevm_" + $date

# create temp vm
$TempVm = New-AzVMConfig -VMName $TempvmName -VMSize $virtualMachineSize
$TempVm = Set-AzVMOSDisk -VM $TempVm -ManagedDiskId $disk.Id -DeleteOption Delete -CreateOption Attach -Windows
$TempVm = Add-AzVMNetworkInterface -VM $TempVm -Id $nic.Id
$TempVm | Set-AzVMBootDiagnostic -Disable #stops creation of boot diags SA

Write-Verbose "Creating Temp VM..." -Verbose
$tempvm = New-AzVM -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceGroup.Location -VM $TempVm -OSDiskDeleteOption Delete

do {
    $status = Test-VmStatus -vmName $TempvmName -resourceGroupName $resourceGroup.ResourceGroupName
    Write-Verbose "Waiting for VM to be running..." -Verbose
    Start-Sleep 20
} until ($status -match "running")

# sysprep
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup.ResourceGroupName `
    -VMName $tempvmName -CommandId 'RunPowerShellScript' `
    -ScriptString "c:\windows\system32\sysprep\sysprep.exe /generalize /oobe /shutdown /quiet"
Write-Verbose "Sysprep command started..." -Verbose

do {
    $status = Test-VmStatus -vmName $TempvmName -resourceGroupName $resourceGroup.ResourceGroupName
    Write-Verbose "Waiting for VM to Stop..." -Verbose
    Start-Sleep 30
} until ($status -match "stopped")

# set vm state to generalized
Write-Verbose "Setting VM to Generalized..." -Verbose
Set-AzVm -ResourceGroupName $resourceGroup.ResourceGroupName -Name $TempvmName -Generalized
    
    
# create image
Write-Verbose "Creating Image..." -Verbose
$vmRes = Get-AzResource -Name $TempvmName -ResourceGroupName $resourceGroup.ResourceGroupName
$imagename = "avdimage_$($date)"
$imageconfig = New-AzImageConfig -Location $resourceGroup.location -sourceVirtualMachineId $vmres.ResourceId
$image = New-AzImage -ImageName $imagename -ResourceGroupName $resourceGroup.ResourceGroupName -Image $imageconfig


# delete temp stuff
Write-Verbose "Deleting temp vm" -Verbose
Remove-AzVM -Name $TempvmName -ResourceGroupName $resourceGroup.ResourceGroupName -Force
Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $resourcegroup.ResourceGroupName -Force
    
# image creation end
Write-Output "Image Created, $($resourceGroup.ResourceGroupName) > $($image.Name)"




$hostPoolName = "vdpool-$CustomerName-prod"
$location = "uksouth"
# Define your Key Vault and secret names
$keyVaultName = "YourKeyVaultName"
$secretName = "YourSecretName-shlocaladminpw"
# Retrieve the secret from the Key Vault
##$adminsecretValue = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName).SecretValueText
# Define your username
$adminusername = "itadmin"
# Create the PSCredential object
#$admincreds = New-Object PSCredential ($adminusername, (ConvertTo-SecureString $adminsecretValue -AsPlainText -Force))


#disable scaling plan for maintenance
if ($resourceGroupName -like "*prod*" -or $resourceGroupName -like "*prd*") {
    Write-Verbose "Disabling Scaling plan for Maintenance." -Verbose
    # get the assigned SP name
    $spName = (Get-AzWvdScalingPlan -HostPoolName $hostPoolName -ResourceGroupName $resourceGroupName).Name
    # get the HP resource Id
    $hpResourceId = (Get-AzWvdHostPool -Name $hostPoolName -ResourceGroupName $resourceGroupName).Id
    # action SP change
    Update-AzWvdScalingPlan -Name $spName -ResourceGroupName $resourceGroupName -HostPoolReference @(@{'hostPoolArmPath' = $HPResourceId; 'scalingPlanEnabled' = $false; })
}
else {
    Write-Verbose "Non Production, Scaling plan action skipped." -Verbose
} 

$testvm = Get-AzVM -Name $SourceVmName -ResourceGroupName $resourceGroupName

# Get the network interface associated with the VM
$nicId = $testvm.NetworkProfile.NetworkInterfaces[0].Id
$nic = Get-AzNetworkInterface -ResourceId $nicId

# Get the subnet from the NIC's IP configuration
$subnetId = $nic.IpConfigurations[0].Subnet.Id

# Extract the VNet name from the subnet ID
$vnetName = $subnetId.Split('/')[-3]
$subnetName = $subnetId.Split('/')[-1]

####################################################################################################################
# Define the base name for session hosts and the number of VMs to create per run
$baseShvmName = "sh-$CustomerName-prod"

$vmCountToCreate = 2  # Number of VMs to create per execution

# Get a list of all VMs in the resource group that match the base session host name pattern
$existingVms = Get-AzVM -ResourceGroupName $resourceGroupName | Where-Object { $_.Name -like "$baseShvmName*" }
$shSku = $existingVms[0].HardwareProfile.VmSize


# Extract the numeric suffix from the VM names and find the highest number
$maxVmNumber = $existingVms | ForEach-Object {
    # Use regex to capture the numeric suffix
    if ($_.Name -match "$baseShvmName-(\d+)$") {
        return [int]$matches[1]  # Convert the suffix to an integer
    }
} | Sort-Object -Descending | Select-Object -First 1

# Determine the starting VM number by incrementing the highest number found
$nextVmNumber = if ($maxVmNumber) {
    $maxVmNumber + 1 
}
else {
    1 
}  # Default to 1 if no existing VMs are found

# Loop to create the desired number of VMs
for ($i = 0; $i -lt $vmCountToCreate; $i++) {
    # Ensure a fixed-width numeric suffix with leading zeros (e.g., 001, 099, 100, 1000)
    $shvmName = "$baseShvmName-{0:D3}" -f ($nextVmNumber + $i)
    
    ####################################################################################################################
    # Get all images with names that match the pattern "avdimage_"
    Write-Verbose -Message "Getting latest image for session host vm creation" -Verbose
    $avdimages = Get-AzImage | Where-Object { $_.Name -like "avdimage_*" }

    # Extract the date part, convert to datetime, and select the latest image
    $latestImage = $avdimages |
    Sort-Object { 
        # Extract the date part from the name
        $dateString = $_.Name -replace 'avdimage_', ''
            
        # Convert to datetime (assuming the format is ddMMyy)
        [datetime]::ParseExact($dateString, 'ddMMyy', $null)
    } -Descending |
    Select-Object -First 1

    # Ensure that the latest image is found
    if (-not $latestImage) {
        Write-Error "No matching AVD images found!"
        break
    }

    ####################################################################################################################
    # Define session host virtual machine configuration
    $vmtags = @{
        "WVD.Source"  = $imagename
        "environment" = "Production"
        "role"        = "Session Host"
    }
    $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
    $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet
    $nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name "$shvmName-NIC" `
        -SubnetId $subnet.Id -Force


    $vmConfig = New-AzVMConfig -VMName $shvmName -VMSize $shSku -Tags $vmtags `
    | Set-AzVMOperatingSystem -Windows -ComputerName $shvmName -Credential $creds `
    | Set-AzVMSourceImage -Id $latestImage.Id `
    | Add-AzVMNetworkInterface -Id $nic.Id -DeleteOption Delete `
    | Set-AzVMBootDiagnostic -Disable `
    | Set-AzVMOSDisk -CreateOption FromImage -DeleteOption Delete

    ####################################################################################################################
    # Creating new VM from captured image from image server
    Write-Verbose -Message "Creating $shvmName VM" -Verbose
    New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig
    Write-Verbose -Message "Created $shvmName VM" -Verbose
}


# Wait for VM to be in running status post creation
do {
    $powerstatus = get-azvm -Name $shvmName -Status | select PowerState
    Write-Verbose "Waiting for VM to be Running status..."
    Start-Sleep 30
} until ($powerstatus.PowerState -match "VM running")

Write-Output "Session hosts created"


# Domain Join Session Host
$extensionName = "DomainJoin-AVD"
$domainName = "$DomainNetbiosName.co.uk"

#$creds = Get-Credential # need to update this part as it required interactive input but it works currently as part of testing
$ouPath = "OU=avd,OU=prod,OU=computers,OU=$CustomerName,DC=$DomainNetbiosName,DC=org"


for ($i = 0; $i -lt $vmCountToCreate; $i++) {
    # Ensure a fixed-width numeric suffix with leading zeros (e.g., 001, 099, 100, 1000)
    $shvmName = "$baseShvmName-{0:D3}" -f ($nextVmNumber + $i)

    # Domain Join the VM
    Write-Verbose -Message "Domain Joining $shvmName" -Verbose
    Set-AzVMADDomainExtension -Name $extensionName -DomainName $domainName -Credential $djcreds -ResourceGroupName $resourceGroupName -VMName $shvmName -OUPath $ouPath -JoinOption 0x00000003 -Restart -Verbose
    Write-Verbose -Message "$shvmName domain joined complete" -Verbose
}

Write-Output "Session hosts are now domain joined to $domainName"


# Running AZ VM Command to create a task scheduler which will run the local Register-SessionHost.ps1 script - triggered to start 2 mins after the task is created

$script = @'
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -File C:\dsc\Register-SessionHost.ps1"
# Calculate the start time 2 minutes from now in "HH:mm" format + AM or PM
$startTime = (Get-Date).AddMinutes(2).ToString('hh:mmtt')
$trigger = New-ScheduledTaskTrigger -Once -At $startTime
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -TaskName "MyTask-AVD-SH" -Description "Register AVD Session Host Script."
'@

for ($i = 0; $i -lt $vmCountToCreate; $i++) {
    # Ensure a fixed-width numeric suffix with leading zeros (e.g., 001, 099, 100, 1000)
    $shvmName = "$baseShvmName-{0:D3}" -f ($nextVmNumber + $i)

    # Push the script to the session host using Invoke-AzVMRunCommand
    Write-Verbose -Message "Starting to create task schedule - $shvmName" -Verbose
    Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $shvmName -CommandId 'RunPowerShellScript' -ScriptString $script
}

Write-Output "New VMs registered to hostpool as session host."

Write-Host "Script paused to complete testing. Press Enter to continue..."
Read-Host -Prompt "Press any key to Continue."


# Removing old session hosts
Write-Verbose -Message "Identifying session hosts to remove" -Verbose

$oldVms = Get-AzVM -ResourceGroupName $resourceGroupName | Where-Object {
    $_.Name -like "$baseShvmName*" -and [int]($_.Name -replace "$baseShvmName-", '') -lt $nextVmNumber
}


# Stop user sessions and drain the old session hosts
Write-Verbose -Message "Stopping new user sessions & draining session hosts" -Verbose
foreach ($oldVm in $oldVms) {
    $sessionHostName = $oldVm.Name
    # Construct the full session host name including the host pool and domain name
    $fullSessionHostName = "$sessionHostName.$domainName"

    # Disable new sessions (drain mode)
    Write-Verbose -Message "Disabling new sessions for $fullSessionHostName" -Verbose
    Update-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName $hostPoolName -Name $fullSessionHostName -AllowNewSession:$false

    # Log off all current user sessions
    $sessions = Get-AzWvdUserSession -ResourceGroupName $resourceGroupName -HostPoolName $hostPoolName -SessionHostName $fullSessionHostName
    foreach ($session in $sessions) {
        Write-Verbose -Message "Logging off sessions on $sessionHostName" -Verbose
        Disconnect-AzWvdUserSession -ResourceGroupName $resourceGroupName -HostPoolName $hostPoolName -SessionHostName $fullSessionHostName -UserSessionId $session.Id -Force
    }

    Write-Output "$fullSessionHostName has been drained and all users logged off."
}

# Remove Drained Session Hosts from the Host Pool
foreach ($oldVm in $oldVms) {
    $sessionHostName = $oldVm.Name
    $fullSessionHostName = "$sessionHostName.$domainName"
    Write-Verbose -Message "Removing $fullSessionHostName from $hostPoolName" -Verbose
    Remove-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName $hostPoolName -SessionHostName $fullSessionHostName -Force
    Write-Output "$fullSessionHostName has been removed from the host pool."
}



# Delete the Old Session Hosts VMs
foreach ($oldVm in $oldVms) {
    $oldvmName = $oldVm.Name
    # Delete VM
    Write-Verbose -Message "Deleting $oldvmName" -Verbose
    Remove-AzVM -ResourceGroupName $resourceGroupName -Name $oldvmName -Force
    Write-Output "$oldvmName has been deleted."
}

#re-enable scaling plan
if ($resourceGroupName -like "*prod*" -or $resourceGroupName -like "*prd*") {
    Write-Verbose "Enabling Scaling Plan"
    Update-AzWvdScalingPlan -Name $spName -ResourceGroupName $resourceGroupName -HostPoolReference @(@{'hostPoolArmPath' = $HPResourceId; 'scalingPlanEnabled' = $true; })
}
else {
    Write-Verbose "Non Production, Scaling plan action skipped."
}

Start-Sleep -Seconds 5


### Need to get the below completed. Removing NIC & Disk once the VMs been removed.
# foreach ($oldVm in $oldVms) {
#     $oldvmName = $oldVm.Name
#     # Delete VM Disk
#     Write-Verbose -Message "Deleting $oldvnName" -Verbose
#     Get-AzVM -Name $oldvmName | Get-azdisk
#     Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $oldvmName
#     Remove-AzVM -ResourceGroupName $resourceGroupName -Name $oldvmName -Force
#     Write-Output "$oldvmName has been deleted."
# }

# Start-Sleep -Seconds 5

# # Delete the Old Session Hosts NICs
# foreach ($oldVm in $oldVms) {
#     $oldvmName = $oldVm.Name
#     # Delete NIC
#     foreach ($oldnicId in $oldvmName.NetworkProfile.NetworkInterfaces.Id) {
#         $oldnicName = ($oldnicId -split '/')[-1]  # Extract NIC name from the NIC ID
#         Write-Verbose -Message "Deleting $oldnicName" -Verbose
#         Remove-AzNetworkInterface -ResourceGroupName $resourceGroupName -Name $oldnicName -Force
#         Write-Output "NIC $oldnicName has been deleted."
#     }
# }

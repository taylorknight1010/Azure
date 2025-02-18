data "azurerm_resource_group" "rg" {
  name = "rg-${var.CustomerName}-${(var.CustomerName == "customerName" && var.tag_environment == "ppd") ? "preprod" : var.tag_environment}"
}

# # Conditional data lookup for the prod resource group
# data "azurerm_resource_group" "prod" {
#   count = contains(["prod-cdf"], var.tag_environment) ? 1 : 0
#   name  = "rg-${var.CustomerName}-prod"
# }

# # Conditional data lookup for the uat resource group
# data "azurerm_resource_group" "uat" {
#   count = contains(["uat-cdf"], var.tag_environment) ? 1 : 0
#   name  = "rg-${var.CustomerName}-uat"
# }


resource "azurerm_automation_account" "automation" {
  name                = "aa-maintenance-${var.tag_environment}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

    tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }
  
}

resource "azurerm_automation_runbook" "runbook" {
  name                    = "AVDToken"
  location                = var.location
  resource_group_name     = data.azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Runbook to update AVD Registration Token on a Session Host"

  content                 = <<-EOT
# Enable verbose logging
$VerbosePreference = "Continue"

# Connect to Azure using the Managed Identity
$account = (Get-AzContext).Account
if (-not $account) {
    Connect-AzAccount -Identity
}

# Variables for Host Pool and Resource Group
$HostPoolName = "vdpool-${var.CustomerName}-${var.tag_environment}"
$ResourceGroupName = "rg-${var.CustomerName}-${var.tag_environment}"
$CustomerName = "${var.CustomerName}"
$Environment = "${var.tag_environment}"

# Conditional logic for VMName - catering for cdf
if ($CustomerName -eq "customerName" -and ($Environment -eq "prod-cdf" -or $Environment -eq "uat-cdf")) {
    # Remove "-cdf" for both environments
    $VMName = "vm-$CustomerName-" + ($Environment -replace "-cdf", "") + "-image-01"
} elseif ($CustomerName -eq "its" -and ($Environment -eq "prod-cdf" -or $Environment -eq "uat-cdf")) {
    # Same behavior for "its" customer
    $VMName = "vm-$CustomerName-" + ($Environment -replace "-cdf", "") + "-image-01"
} elseif ($CustomerName -eq "customerName" -and $Environment -eq "ppd") {
    # customerName ppd to preprod
    $VMName = "vm-$CustomerName-preprod-image-01"
} else {
    # Default case
    $VMName = "vm-$CustomerName-$Environment-image-01"
}

# Conditional logic for imageResourceGroup - catering for cdf
if ($CustomerName -eq "customerName" -and ($Environment -eq "prod-cdf" -or $Environment -eq "uat-cdf")) {
    # Remove "-cdf" for both environments
    $imageResourceGroup = "rg-$CustomerName-" + ($Environment -replace "-cdf", "")
} elseif ($CustomerName -eq "its" -and ($Environment -eq "prod-cdf" -or $Environment -eq "uat-cdf")) {
    # Same behavior for "its" customer
    $imageResourceGroup = "rg-$CustomerName-" + ($Environment -replace "-cdf", "")
} elseif ($CustomerName -eq "customerName" -and $Environment -eq "ppd") {
    # customerName ppd to preprod
    $imageResourceGroup = "rg-$CustomerName-preprod"
} else {
    # Default case
    $imageResourceGroup = "rg-$CustomerName-$Environment"
}

# Conditional logic for HostPoolName - catering for customerNamepreprod
if ($CustomerName -eq "customerName" -and $Environment -eq "ppd") {
    # Adjusting ppd to preprod for customerName
    $HostPoolName = "vdpool-${var.CustomerName}-preprod"
} else {
    # Default case
    $HostPoolName = "vdpool-${var.CustomerName}-${var.tag_environment}"
}

# Conditional logic for RG - catering for customerNamepreprod
if ($CustomerName -eq "customerName" -and $Environment -eq "ppd") {
    # Adjusting ppd to preprod for customerName
    $ResourceGroupName = "rg-customerName-preprod"
} else {
    # Default case
    $ResourceGroupName = "rg-${var.CustomerName}-${var.tag_environment}"
}

$LocalScriptPath = "C:\dsc\Register-SessionHost.ps1"  # Path of the script on the image server

# Step 1: Generate the AVD registration token
$parameters = @{
    HostPoolName = $HostPoolName
    ResourceGroupName = $ResourceGroupName
    ExpirationTime = $((Get-Date).ToUniversalTime().AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))
}

New-AzWvdRegistrationInfo @parameters

# Get the registration token
$tokenDetails = Get-AzWvdHostPoolRegistrationToken -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName
$registrationToken = $tokenDetails.Token

# Define the script that will be run on the remote VM
$scriptBlock = {
    param(
        [string] $avdRegToken
        )    
    $scriptPath = "C:\dsc\Register-SessionHost.ps1"
    
    # Replace the registration token in the script (dummy token for testing)
    $newToken = $registrationToken
    (Get-Content $scriptPath) -replace 'registrationToken =.*', "registrationToken = `"$avdRegToken`"" | Set-Content $scriptPath

    # Output success message
    Write-Output "Script updated with new registration token."
}

$Script = [scriptblock]::create($scriptBlock)

# Run the command on the VM
Invoke-AzVMRunCommand -ResourceGroupName $imageResourceGroup -Name $VMName -CommandId 'RunPowerShellScript' -ScriptString $script -Parameter @{'avdRegToken' = $registrationToken}

Write-Output "AVD Registration Token updated successfully."
EOT

  runbook_type            = "PowerShell"

    tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }  
}

resource "azurerm_automation_runbook" "image_runbook" {
  name                    = "CreateImage"
  location                = var.location
  resource_group_name     = data.azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Runbook to create AVD Image - ${var.tag_environment}"

  content                 = <<-EOT
# Enable verbose logging 
$VerbosePreference = "Continue"

# Connect to Azure using the Managed Identity
$account = (Get-AzContext).Account
if (-not $account) {
    Connect-AzAccount -Identity
}

#Dynamic switch for customerName preprod
switch ("$CustomerName-$Environment") {
    {$_ -in "customerName-ppd"} {
        $Environment = "preprod"
        Write-Verbose "customerName ppd - Converted from ppd to preprod" -Verbose
    } 
    Default {
        $Environment = "${var.tag_environment}"
        Write-Verbose "Using Default Tag Environment - $Environment" -Verbose
    }
}

$SourceVmName = "vm-${var.CustomerName}-${var.tag_environment}-image-01"
$CustomerName = "${var.CustomerName}"

#Dynamic switch for customerName preprod
switch ("$CustomerName-$Environment") {
    {$_ -in "customerName-ppd"} {
        $resourceGroupName = "rg-$CustomerName-preprod"
        Write-Verbose "customerName ppd - Converted to preprod - $resourceGroupName" -Verbose
    } 
    Default {
        $resourceGroupName = "rg-$CustomerName-$Environment"
        Write-Verbose "Using Default Resource Group - $resourceGroupName" -Verbose
    }
}

# should this $vmName be $sourceVmName?
function Test-VmStatus($vmName, $resourceGroupName) {
    $vmStatus = Get-AzVM -name $vmName -resourcegroup $resourceGroupName -Status
    return (($vmstatus.Statuses | Where-Object { $_.code -match 'Powerstate' }).DisplayStatus)
}

# Check if Image Server is running and start if not
# Get the current status of the VM
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $SourceVmName -Status
$vmStatus = $vm.Statuses[1].Code

# Check if the VM is running
if ($vmStatus -ne "PowerState/running") {
    Write-Output "$SourceVmName is not running. Starting VM..."
    # Start the VM if it's not running
    Start-AzVM -ResourceGroupName $resourceGroupName -Name $SourceVmName
    
    # Wait for the VM to reach the "Running" state
    do {
        # Get the updated status of the VM
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $SourceVmName -Status
        $vmStatus = $vm.Statuses[1].Code
        Write-Output "Waiting for $SourceVmName to start... Current status: $vmStatus"
        Start-Sleep -Seconds 10
    } while ($vmStatus -ne "PowerState/running")
    
    Write-Output "$SourceVmName is now running!"
} else {
    Write-Output "$SourceVmName is already running."
}

# Check if image server has installed updates

$updatecheckscript = @'
$updateCheck = Get-HotFix | Where-Object { $_.InstalledOn -eq (Get-Date).Date }
if ($updateCheck) {
    Write-Output $updatecheck
} else {
    Write-Verbose "No Windows Updates installed today" -Verbose
}
'@

# Invoke the command on the Azure VM
Write-Verbose -Message "Checking if Windows Updates were installed" -Verbose
$updatecheckAzVMCommand = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $SourceVmName -CommandId 'RunPowerShellScript' -ScriptString $updatecheckscript

# Output the result
$updatecheckResult = $updatecheckAzVMCommand.Value | ForEach-Object { $_.Message.Trim() } | Out-String
$update = $updatecheckResult.Trim()

if ($update -eq "VERBOSE: No Windows Updates installed today") {
    Write-Output "No updates were installed on the server today - ending job."
} else {
    Write-Output "$SourceVmName installed Windows Updates today - proceeding with job..."

#start-sleep 5

# Starting runbook that generates AVD Session Host registration key and updates script on image server
# Start the runbook
$runbookName = "AVDToken"


switch ("$CustomerName-$Environment") {
    {$_ -in "customerName-ppd"} {
        $automationAccountName = "aa-maintenance-preprod"
        Write-Verbose "customerName ppd - Converted to preprod - $automationAccountName" -Verbose
    } 
    Default {
        $automationAccountName = "aa-maintenance-$Environment"
        Write-Verbose "Using Default Automation Account - $automationAccountName" -Verbose
    }
}

# Get today's date in the required format
$todaydate = Get-Date -Format ddMMyy
$imageName = "avdimage-$Environment-$todaydate"  # Dynamically create the image name based on today's date

# Check if the image exists
$imageExists = Get-AzImage -ResourceGroupName $resourceGroupName | Where-Object { $_.Name -eq $imageName }

# If the image exists, skip the image creation part
if ($imageExists) {
    Write-Output "Image $imageName already exists, skipping image creation process."
} else {

Write-Verbose "Starting AVD Key Generation Runbook $runbookName" -Verbose
$runbook = Start-AzAutomationRunbook -ResourceGroupName $resourceGroupName `
                                     -AutomationAccountName $automationAccountName `
                                     -Name $runbookName

# Wait for job to run (3 min wait)
#start-sleep -Seconds 180

# Output runbook details
$jobs = Get-AzAutomationJob -ResourceGroupName $resourceGroupName `
                             -AutomationAccountName $automationAccountName

# Filter for the most recent job
$lastJob = $jobs | Sort-Object -Property StartTime -Descending | Select-Object -First 1

# Check if a job was found
if ($lastJob) {
    Write-Output "Last Job ID: $($lastJob.JobId)"
    Write-Output "Runbook Name: $($lastJob.RunbookName)"
    Write-Output "Start Time: $($lastJob.StartTime)"
    Write-Output "Status: $($lastJob.Status)"
    
    # Check if the job was completed
    if ($lastJob.Status -eq 'Completed') {
        Write-Output "The last job completed successfully."
    } elseif ($lastJob.Status -eq 'Failed') {
        Write-Output "The last job failed. Check the job output for details."
    } else {
        Write-Output "The last job ended with status: $($lastJob.Status)"
    }
} else {
    Write-Output "No jobs found in the Automation Account."
    exit 1  # Exit with an error code if no jobs found
}

# get current status & info
Write-Verbose "Getting Source VM & RG info..." -Verbose
$date = Get-Date -Format ddMMyy
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName
$sourcevminfo = Get-AzVm -Name $sourcevmName -ResourceGroupName $resourceGroup.ResourceGroupName

# Stopping VM for creating clean snapshot
Write-Verbose "Stopping Source VM for snapshot..." -Verbose
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
    #start-sleep 20
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
    #start-sleep 20
} until ($status -match "running")

# sysprep
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup.ResourceGroupName `
    -VMName $tempvmName -CommandId 'RunPowerShellScript' `
    -ScriptString "c:\windows\system32\sysprep\sysprep.exe /generalize /oobe /shutdown /quiet"
Write-Verbose "Sysprep command started..." -Verbose

do {
    $status = Test-VmStatus -vmName $TempvmName -resourceGroupName $resourceGroup.ResourceGroupName
    Write-Verbose "Waiting for VM to Stop..." -Verbose
    #start-sleep 30
} until ($status -match "stopped")

# set vm state to generalized
Write-Verbose "Setting VM to Generalized..." -Verbose
Set-AzVm -ResourceGroupName $resourceGroup.ResourceGroupName -Name $TempvmName -Generalized
    
    
# create image
Write-Verbose "Creating Image..." -Verbose
$vmRes = Get-AzResource -Name $TempvmName -ResourceGroupName $resourceGroup.ResourceGroupName
$imagename = "avdimage-$Environment-$($date)"
$imageconfig = New-AzImageConfig -Location $resourceGroup.location -sourceVirtualMachineId $vmres.ResourceId
$image = New-AzImage -ImageName $imagename -ResourceGroupName $resourceGroup.ResourceGroupName -Image $imageconfig


# delete temp stuff
Write-Verbose "Deleting temp vm" -Verbose
Remove-AzVM -Name $TempvmName -ResourceGroupName $resourceGroup.ResourceGroupName -Force
Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $resourcegroup.ResourceGroupName -Force
    
# image created
Write-Output "Image Created, $($resourceGroup.ResourceGroupName) > $($image.Name)"

}

}

#Dynamic switch for customerName preprod
switch ("$CustomerName-$Environment") {
    {$_ -in "customerName-ppd"} {
        $Environment = "preprod"
        Write-Verbose "customerName ppd - Converted from ppd to preprod" -Verbose
    } 
    Default {
        $Environment = "${var.tag_environment}"
        Write-Verbose "Using Default Tag Environment - $Environment" -Verbose
    }
}

switch ("$Environment") {
    {$_ -in "ppd"} {
        Write-Verbose "PPD Environment re-adding Always Off tags" -Verbose
        $resourceIdRG = get-azresourcegroup -name "rg-${var.CustomerName}-$Environment"
        $mergeTags = @{"AutoShutdownSchedule"="Always Off"}
        Update-AzTag -ResourceId $resourceIdRG.ResourceId -Tag $mergeTags -Operation Merge
        Write-Verbose "$mergeTags - tags complete" -Verbose
    } 
    Default {
        Write-Verbose "Finishing Script as environment is not ppd and therefore doesn't need Always Off tags re-applied" -Verbose
    }
}

EOT

  runbook_type            = "PowerShell72"

    tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }  
}

#This was required when the automation account only did the AVD token part. Now we are creating an Azure VM Image, that required Contributor
# # Assigning the role to the automation account's managed identity
# resource "azurerm_role_assignment" "vm_contributor" {
#   principal_id           = azurerm_automation_account.automation.identity[0].principal_id
#   role_definition_name   = "Virtual Machine Contributor"
#   scope                  = data.azurerm_resource_group.rg.id
# }

# resource "azurerm_role_assignment" "desktop_virtualization_contributor" {
#   principal_id           = azurerm_automation_account.automation.identity[0].principal_id
#   role_definition_name   = "Desktop Virtualization Contributor"
#   scope                  = data.azurerm_resource_group.rg.id
# }


resource "azurerm_role_assignment" "contributor" {
  principal_id           = azurerm_automation_account.automation.identity[0].principal_id
  role_definition_name   = "Contributor"
  scope                  = data.azurerm_resource_group.rg.id
}



# # Role assignments for Prod CDF resource groups
# resource "azurerm_role_assignment" "vm_contributor_prod_cdf" {
#   count                = (var.CustomerName == "customerName" && contains(["prod-cdf"], var.tag_environment)) ? 1 : 0
#   principal_id         = azurerm_automation_account.automation.identity[0].principal_id
#   role_definition_name = "Virtual Machine Contributor"
#   scope                = contains(["prod-cdf"], var.tag_environment) ? data.azurerm_resource_group.prod[0].id : null
# }

# resource "azurerm_role_assignment" "desktop_virtualization_contributor_prod_cdf" {
#   count                = (var.CustomerName == "customerName" && contains(["prod-cdf"], var.tag_environment)) ? 1 : 0
#   principal_id         = azurerm_automation_account.automation.identity[0].principal_id
#   role_definition_name = "Desktop Virtualization Contributor"
#   scope                = contains(["prod-cdf"], var.tag_environment) ? data.azurerm_resource_group.prod[0].id : null
# }

# # Role assignments for UAT CDF resource groups
# resource "azurerm_role_assignment" "vm_contributor_uat_cdf" {
#   count                = (var.CustomerName == "customerName" && contains(["uat-cdf"], var.tag_environment)) ? 1 : 0
#   principal_id         = azurerm_automation_account.automation.identity[0].principal_id
#   role_definition_name = "Virtual Machine Contributor"
#   scope                = data.azurerm_resource_group.uat.id
# }

# resource "azurerm_role_assignment" "desktop_virtualization_contributor_uat_cdf" {
#   count                = (var.CustomerName == "customerName" && contains(["uat-cdf"], var.tag_environment)) ? 1 : 0
#   principal_id         = azurerm_automation_account.automation.identity[0].principal_id
#   role_definition_name = "Desktop Virtualization Contributor"
#   scope                = data.azurerm_resource_group.uat.id
# }


# #Testing purposes it sandbox
# resource "azurerm_role_assignment" "vm_contributor_its_prod_cdf" {
#   count                = (var.CustomerName == "its" && contains(["prod-cdf"], var.tag_environment)) ? 1 : 0
#   principal_id         = azurerm_automation_account.automation.identity[0].principal_id
#   role_definition_name = "Virtual Machine Contributor"
#   scope                = data.azurerm_resource_group.prod.id
# }

# resource "azurerm_role_assignment" "virtualization_contributor_its_prod_cdf" {
#   count                = (var.CustomerName == "its" && contains(["prod-cdf"], var.tag_environment)) ? 1 : 0
#   principal_id         = azurerm_automation_account.automation.identity[0].principal_id
#   role_definition_name = "Desktop Virtualization Contributor"
#   scope                = data.azurerm_resource_group.prod.id
# }

resource "azurerm_automation_runbook" "poweron-runbook" {
  count = var.ppd_poweron_runbook_create == true ? 1 : 0     
  name                    = "PowerOn-PPD"
  location                = var.location
  resource_group_name     = data.azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Runbook to turn on Pre-Prod image server to be patched"

  content                 = <<-EOT
# Login using the system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

#Dynamic switch for customerName preprod
switch ("$CustomerName-$Environment") {
    {$_ -in "customerName-ppd"} {
        $Environment = "preprod"
        Write-Verbose "customerName ppd - Converted from ppd to preprod" -Verbose
    } 
    Default {
        $Environment = "${var.tag_environment}"
        Write-Verbose "Using Default Tag Environment - $Environment" -Verbose
    }
}

# Remove always off tag
$resourceIdRG = get-azresourcegroup -name "rg-${var.CustomerName}-$Environment"
$removeTags = @{"AutoShutdownSchedule"="Always Off"}
Update-AzTag -ResourceId $resourceIdRG.ResourceId -Tag $removeTags -Operation Delete

switch ("$CustomerName-$Environment") {
    {$_ -in "customerName-ppd"} {
        $SourceVmName = "vm-${var.CustomerName}-preprod-image-01"
        Write-Verbose "customerName ppd - Converted to preprod - $automationAccountName" -Verbose
    } 
    Default {
        $SourceVmName = "vm-${var.CustomerName}-${var.tag_environment}-image-01"
    }
}

# Get Image Server
$vms = Get-AzVM -Name $SourceVmName -Status

foreach ($vm in $vms) {
    # Check if the PPD Image VM is off
    if ($vm.PowerState -eq 'VM deallocated') {
        # Shutdown the VM
        Write-Output "Powering On $($vm.Name)..."
        Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
    } else {
        Write-Output "$($vm.Name) is already running. Skipping."
    }
}

EOT

  runbook_type            = "PowerShell72"

    tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }  
}

# Install Microsoft Graph PowerShell: Install-Module Microsoft.Graph -Scope CurrentUser
# Install Azure PowerShell: Install-Module Az -Scope CurrentUser
# Authenticate to Microsoft Graph and Azure: Connect-MgGraph -TenantId "tenant-id" -Scopes "Group.ReadWrite.All", "Directory.ReadWrite.All" and Connect-AzAccount -TenantId d85302c6-7818-4c30-89c8-b6edb4fb2205 -UseDeviceAuthentication
import-module Microsoft.Graph.Groups
import-module Microsoft.Graph.Users
import-module Microsoft.Graph.Identity.Governance
import-module Microsoft.Graph.Identity.DirectoryManagement

# connect-mggraph -TenantId "tenant-id" -UseDeviceCode -Scopes "Group.ReadWrite.All", "User.ReadWrite.All", "PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup", "Domain.Read.All", "RoleManagementPolicy.ReadWrite.AzureADGroup", "PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup","PrivilegedAccess.ReadWrite.AzureADGroup","PrivilegedEligibilitySchedule.Remove.AzureADGroup", "RoleManagement.ReadWrite.Directory"
# Steps required to carry out end to end #

### IT ###
# Step 1 - Create Entra ID Groups
$teamName = "IT Team"
$groupName01 = "SG_IT_TEAM"
$pimGroupName01 = "PAG_IT_PROD"
$pimGroupName02 = "PAG_IT_NON_PROD"

$g01 = Get-MgGroup -Filter ("DisplayName eq '{0}'" -f $groupName01)

if ($null -eq $g01) {
    Write-Verbose -Message "$groupName01 group doesn't exist - now creating..." -Verbose
    $params = @{
        DisplayName = $($groupName01)
        MailEnabled = $False
        MailNickName = $($groupName01)
        SecurityEnabled = $True
        Description = "$teamName Base Group"
        IsAssignableToRole = $True
    }
    $g01 = New-MgGroup @params
} else {
    Write-Verbose -Message "$groupName01 group already exists" -Verbose
}

$pg01 = Get-MgGroup -Filter ("DisplayName eq '{0}'" -f $pimGroupName01)

if ($null -eq $pg01) {
    Write-Verbose -Message "$pimGroupName01 group doesn't exist - now creating..." -Verbose
    $params = @{
        DisplayName = $($pimGroupName01)
        MailEnabled = $False
        MailNickName = $($pimGroupName01)
        SecurityEnabled = $True
        Description = "$teamName Production Privileged Access Group"
        IsAssignableToRole = $True        
    }
    $pg01 = New-MgGroup @params
} else {
    Write-Verbose -Message "$pimGroupName01 group already exists" -Verbose
}


$pg02 = Get-MgGroup -Filter ("DisplayName eq '{0}'" -f $pimGroupName02)

if ($null -eq $pg02) {
    Write-Verbose -Message "$pimGroupName02 group doesn't exist - now creating..." -Verbose
    $params = @{
        DisplayName = $($pimGroupName02)
        MailEnabled = $False
        MailNickName = $($pimGroupName02)
        SecurityEnabled = $True
        Description = "$teamName Non-Prod Privileged Access Group"
        IsAssignableToRole = $True        
    }
    $pg02 = New-MgGroup @params
} else {
    Write-Verbose -Message "$pimGroupName02 group already exists" -Verbose
}

# Allow Never Expire Eligible assignment on PAG
# Prod PAG
$p = Get-MgPolicyRoleManagementPolicyAssignment -Filter $("scopeId eq '{0}' and scopeType eq 'Group' and RoleDefinitionId eq 'member'" -f $pg01.Id)
$unifiedRoleManagementPolicyId = $p.PolicyId
$unifiedRoleManagementPolicyRuleId = "Expiration_Admin_Eligibility"

$currentRule = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId

if ($currentRule.AdditionalProperties.isExpirationRequired -eq "True") {
    Write-Verbose -Message "$($pg01.DisplayName) PAG Member role is not set to allow never expire eligible assignment. Now changing to allow never expire..." -Verbose
$params = @{
    "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
    id = "Expiration_Admin_Eligibility"
    isExpirationRequired = $false
    target = @{
        "@odata.type" = "microsoft.graph.unifiedRoleManagementPolicyRuleTarget"
        caller = "Admin"
        operations = @(
            "All"
        )
        level = "Eligibility"
        inheritableSettings = @(
        )
        enforcedSettings = @(
        )
    }
}
Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId -BodyParameter $params
} else {
    Write-Verbose -Message "$($pg01.DisplayName) PAG Member role already set to allow never expire eligible assignment" -Verbose
}


# Non-Prod PAG
$p = Get-MgPolicyRoleManagementPolicyAssignment -Filter $("scopeId eq '{0}' and scopeType eq 'Group' and RoleDefinitionId eq 'member'" -f $pg02.Id)
$unifiedRoleManagementPolicyId = $p.PolicyId
$unifiedRoleManagementPolicyRuleId = "Expiration_Admin_Eligibility"

$currentRule = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId

if ($currentRule.AdditionalProperties.isExpirationRequired -eq "True") {
    Write-Verbose -Message "$($pg02.DisplayName) PAG Member role is not set to allow never expire eligible assignment. Now changing to allow never expire..." -Verbose
$params = @{
    "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
    id = "Expiration_Admin_Eligibility"
    isExpirationRequired = $false
    target = @{
        "@odata.type" = "microsoft.graph.unifiedRoleManagementPolicyRuleTarget"
        caller = "Admin"
        operations = @(
            "All"
        )
        level = "Eligibility"
        inheritableSettings = @(
        )
        enforcedSettings = @(
        )
    }
}
Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId -BodyParameter $params
} else {
    Write-Verbose -Message "$($pg02.DisplayName) PAG Member role already set to allow never expire eligible assignment" -Verbose
}

# Set Activation maximum duration to 2 hours on PAG
# Prod PAG
$p = Get-MgPolicyRoleManagementPolicyAssignment -Filter $("scopeId eq '{0}' and scopeType eq 'Group' and RoleDefinitionId eq 'member'" -f $pg01.Id)
$unifiedRoleManagementPolicyId = $p.PolicyId
$unifiedRoleManagementPolicyRuleId = "Expiration_EndUser_Assignment"

$currentRule = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId

if ($currentRule.AdditionalProperties.maximumDuration -ne "PT2H") {
    Write-Verbose -Message "$($pg01.DisplayName) PAG Member role is not set to 2 hours activation. Now changing Activation maximum duration to 2 hours..." -Verbose
$params = @{
    "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
    id = "Expiration_EndUser_Assignment"
    target = @{
      "@odata.type" = "microsoft.graph.unifiedRoleManagementPolicyRuleTarget"
    }
    isExpirationRequired = $true
    maximumDuration = "PT2H"
}
Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId -BodyParameter $params
} else {
    Write-Verbose -Message "$($pg01.DisplayName) PAG Member role already has Activation maximum duration set to 2 hours. Skipping this step..." -Verbose
}

# Non-Prod PAG
$p = Get-MgPolicyRoleManagementPolicyAssignment -Filter $("scopeId eq '{0}' and scopeType eq 'Group' and RoleDefinitionId eq 'member'" -f $pg02.Id)
$unifiedRoleManagementPolicyId = $p.PolicyId
$unifiedRoleManagementPolicyRuleId = "Expiration_EndUser_Assignment"

$currentRule = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId

if ($currentRule.AdditionalProperties.maximumDuration -ne "PT2H") {
    Write-Verbose -Message "$($pg02.DisplayName) PAG Member role is not set to 2 hours activation. Now changing Activation maximum duration to 2 hours..." -Verbose
$params = @{
    "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
    id = "Expiration_EndUser_Assignment"
    target = @{
      "@odata.type" = "microsoft.graph.unifiedRoleManagementPolicyRuleTarget"
    }
    isExpirationRequired = $true
    maximumDuration = "PT2H"
}
Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId -BodyParameter $params
} else {
    Write-Verbose -Message "$($pg02.DisplayName) PAG Member role already has Activation maximum duration set to 2 hours. Skipping this step..." -Verbose
}

# Enable approval required on PAGs
# Prod PAG
$p = Get-MgPolicyRoleManagementPolicyAssignment -Filter $("scopeId eq '{0}' and scopeType eq 'Group' and RoleDefinitionId eq 'member'" -f $pg01.Id)
$unifiedRoleManagementPolicyId = $p.PolicyId
$unifiedRoleManagementPolicyRuleId = "Approval_EndUser_Assignment"
$approverGroup1 = Get-MgGroup -Filter ("DisplayName eq '{0}'" -f "customerName Escalation Group")
$approverGroup2 = Get-MgGroup -Filter ("DisplayName eq '{0}'" -f "SG_IT_TEAM")

$currentRule = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId

if ($null -eq $currentRule.AdditionalProperties.setting.approvalStages.primaryApprovers) {
    Write-Verbose -Message "$($pg01.DisplayName) PAG Member role does not have any approvers set. Now adding approvers..." -Verbose
    $params = @{
        "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule"
        id = "Approval_EndUser_Assignment"
        target = @{
            "@odata.type" = "microsoft.graph.unifiedRoleManagementPolicyRuleTarget"
            caller = "EndUser"
            operations = @("All")
            level = "Assignment"
            inheritableSettings = @()
            enforcedSettings = @()
        }
        setting = @{
            "@odata.type" = "microsoft.graph.approvalSettings"
            isApprovalRequired = $true
            isApprovalRequiredForExtension = $false
            isRequestorJustificationRequired = $true
            approvalMode = "SingleStage"
            approvalStages = @(
                @{
                    "@odata.type" = "microsoft.graph.unifiedApprovalStage"
                    approvalStageTimeOutInDays = 1
                    isApproverJustificationRequired = $true
                    escalationTimeInMinutes = 0 # Set appropriate value or leave it as 0 if no escalation
                    primaryApprovers = @(
                        @{
                            "@odata.type" = "#microsoft.graph.groupMembers"
                            id = $approverGroup1.Id
                        }
                        @{
                            "@odata.type" = "#microsoft.graph.groupMembers"
                            id = $approverGroup2.Id
                        }                        
                    )
                    isEscalationEnabled = $false
                    escalationApprovers = @()
                }
            )
        }
    }
    
    Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId -BodyParameter $params    
} else {
    Write-Verbose -Message "$($pg01.DisplayName) PAG Member role already has approvers set. Skipping this step..." -Verbose
}

# Non-Prod PAG
$p = Get-MgPolicyRoleManagementPolicyAssignment -Filter $("scopeId eq '{0}' and scopeType eq 'Group' and RoleDefinitionId eq 'member'" -f $pg02.Id)
$unifiedRoleManagementPolicyId = $p.PolicyId
$unifiedRoleManagementPolicyRuleId = "Approval_EndUser_Assignment"
$approverGroup1 = Get-MgGroup -Filter ("DisplayName eq '{0}'" -f "customerName Escalation Group")
$approverGroup2 = Get-MgGroup -Filter ("DisplayName eq '{0}'" -f "SG_IT_TEAM")

$currentRule = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId

if ($null -eq $currentRule.AdditionalProperties.setting.approvalStages.primaryApprovers) {
    Write-Verbose -Message "$($pg02.DisplayName) PAG Member role does not have any approvers set. Now adding approvers..." -Verbose
    $params = @{
        "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule"
        id = "Approval_EndUser_Assignment"
        target = @{
            "@odata.type" = "microsoft.graph.unifiedRoleManagementPolicyRuleTarget"
            caller = "EndUser"
            operations = @("All")
            level = "Assignment"
            inheritableSettings = @()
            enforcedSettings = @()
        }
        setting = @{
            "@odata.type" = "microsoft.graph.approvalSettings"
            isApprovalRequired = $true
            isApprovalRequiredForExtension = $false
            isRequestorJustificationRequired = $true
            approvalMode = "SingleStage"
            approvalStages = @(
                @{
                    "@odata.type" = "microsoft.graph.unifiedApprovalStage"
                    approvalStageTimeOutInDays = 1
                    isApproverJustificationRequired = $true
                    escalationTimeInMinutes = 0 # Set appropriate value or leave it as 0 if no escalation
                    primaryApprovers = @(
                        @{
                            "@odata.type" = "#microsoft.graph.groupMembers"
                            id = $approverGroup1.Id
                        }
                        @{
                            "@odata.type" = "#microsoft.graph.groupMembers"
                            id = $approverGroup2.Id
                        }                        
                    )
                    isEscalationEnabled = $false
                    escalationApprovers = @()
                }
            )
        }
    }
    
    Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId -BodyParameter $params    
} else {
    Write-Verbose -Message "$($pg02.DisplayName) PAG Member role already has approvers set. Skipping this step..." -Verbose
}

# Assign Base group to PAGs as eligible never expire
# Prod PAG
$params = @{
    accessId = "member"
    principalId = "$($g01.Id)"
    groupId = "$($pg01.Id)"
    action = "AdminAssign"
    scheduleInfo = @{
        startDateTime = $(Get-Date)
        expiration    = @{
            type = "noExpiration"
        }
    }
    justification = "Assign eligible request."
}
New-MgIdentityGovernancePrivilegedAccessGroupEligibilityScheduleRequest -BodyParameter $params

# Non-Prod PAG
$params = @{
    accessId = "member"
    principalId = "$($g01.Id)"
    groupId = "$($pg02.Id)"
    action = "AdminAssign"
    scheduleInfo = @{
        startDateTime = $(Get-Date)
        expiration    = @{
            type = "noExpiration"
        }
    }
    justification = "Assign eligible request."
}
New-MgIdentityGovernancePrivilegedAccessGroupEligibilityScheduleRequest -BodyParameter $params

### Assign Entra ID Roles ###
# Base Group #
# Global Reader #
$roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Global Reader'"
# Check if the assignment is already in place
$existingAssignment = Get-MgRoleManagementDirectoryRoleAssignment |
    Where-Object { $_.PrincipalId -eq $g01.Id -and $_.RoleDefinitionId -eq $roleDefinition.Id }

if ($null -eq $existingAssignment) {   
    Write-Verbose -Message "$($roleDefinition.DisplayName) not assigned to $($g01.DisplayName) group. Now assigning..." -Verbose     
$params = @{
    "directoryScopeId" = "/" 
    "principalId" = $g01.Id
    "roleDefinitionId" = $roleDefinition.Id
 }
$roleAssignment = New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $params
} else {
    Write-Verbose -Message "$($g01.DisplayName) group is already assigned to $($roleDefinition.DisplayName)" -Verbose
}

# User Administrator #
$roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'User Administrator'"
# Check if the assignment is already in place
$existingAssignment = Get-MgRoleManagementDirectoryRoleAssignment |
    Where-Object { $_.PrincipalId -eq $g01.Id -and $_.RoleDefinitionId -eq $roleDefinition.Id }

if ($null -eq $existingAssignment) {   
    Write-Verbose -Message "$($roleDefinition.DisplayName) not assigned to $($g01.DisplayName) group. Now assigning..." -Verbose     
$params = @{
    "directoryScopeId" = "/" 
    "principalId" = $g01.Id
    "roleDefinitionId" = $roleDefinition.Id
 }
$roleAssignment = New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $params
} else {
    Write-Verbose -Message "$($g01.DisplayName) group is already assigned to $($roleDefinition.DisplayName)" -Verbose
}

# Prod PAG #
# Application Administrator #
$roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Application Administrator'"
# Check if the assignment is already in place
$existingAssignment = Get-MgRoleManagementDirectoryRoleAssignment |
    Where-Object { $_.PrincipalId -eq $pg01.Id -and $_.RoleDefinitionId -eq $roleDefinition.Id }

if ($null -eq $existingAssignment) {   
    Write-Verbose -Message "$($roleDefinition.DisplayName) not assigned to $($pg01.DisplayName) group. Now assigning..." -Verbose  
$params = @{
    "directoryScopeId" = "/" 
    "principalId" = $pg01.Id
    "roleDefinitionId" = $roleDefinition.Id
 }
$roleAssignment = New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $params
} else {
    Write-Verbose -Message "$($pg01.DisplayName) group is already assigned to $($roleDefinition.DisplayName)" -Verbose
}

# Privileged Authentication Administrator #
$roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Privileged Authentication Administrator'"
# Check if the assignment is already in place
$existingAssignment = Get-MgRoleManagementDirectoryRoleAssignment |
    Where-Object { $_.PrincipalId -eq $pg01.Id -and $_.RoleDefinitionId -eq $roleDefinition.Id }

if ($null -eq $existingAssignment) {   
    Write-Verbose -Message "$($roleDefinition.DisplayName) not assigned to $($pg01.DisplayName) group. Now assigning..." -Verbose  
$params = @{
    "directoryScopeId" = "/" 
    "principalId" = $pg01.Id
    "roleDefinitionId" = $roleDefinition.Id
 }
$roleAssignment = New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $params
} else {
    Write-Verbose -Message "$($pg01.DisplayName) group is already assigned to $($roleDefinition.DisplayName)" -Verbose
}

# Security Administrator #
$roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Security Administrator'"
# Check if the assignment is already in place
$existingAssignment = Get-MgRoleManagementDirectoryRoleAssignment |
    Where-Object { $_.PrincipalId -eq $pg01.Id -and $_.RoleDefinitionId -eq $roleDefinition.Id }

if ($null -eq $existingAssignment) {   
    Write-Verbose -Message "$($roleDefinition.DisplayName) not assigned to $($pg01.DisplayName) group. Now assigning..." -Verbose  
$params = @{
    "directoryScopeId" = "/" 
    "principalId" = $pg01.Id
    "roleDefinitionId" = $roleDefinition.Id
 }
$roleAssignment = New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $params
} else {
    Write-Verbose -Message "$($pg01.DisplayName) group is already assigned to $($roleDefinition.DisplayName)" -Verbose
}

# Privileged Role Administrator #
$roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Privileged Role Administrator'"
# Check if the assignment is already in place
$existingAssignment = Get-MgRoleManagementDirectoryRoleAssignment |
    Where-Object { $_.PrincipalId -eq $pg01.Id -and $_.RoleDefinitionId -eq $roleDefinition.Id }

if ($null -eq $existingAssignment) {   
    Write-Verbose -Message "$($roleDefinition.DisplayName) not assigned to $($pg01.DisplayName) group. Now assigning..." -Verbose  
$params = @{
    "directoryScopeId" = "/" 
    "principalId" = $pg01.Id
    "roleDefinitionId" = $roleDefinition.Id
 }
$roleAssignment = New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $params
} else {
    Write-Verbose -Message "$($pg01.DisplayName) group is already assigned to $($roleDefinition.DisplayName)" -Verbose
}



### Azure ###
$prodMG = Get-AzManagementGroup | Where-Object { $_.DisplayName -like "Prod" }
$nonprodMG = Get-AzManagementGroup | Where-Object { $_.DisplayName -like "Non-Prod" }
$hubMG = Get-AzManagementGroup | Where-Object { $_.DisplayName -like "connectivity" }
$customerNameMG = Get-AzManagementGroup | Where-Object { $_.DisplayName -like "customerName" }

## Assign active never expire Azure Roles ##
## Base Group ##

# Security Reader #
$roleDefinition = Get-AzRoleDefinition -Name "Security Reader"
# Check existing assignment
$existingAssignment = get-AzRoleAssignment -ObjectId $g01.Id -RoleDefinitionName $roleDefinition.Name -Scope $prodMG.Id
# assign loop
if ($null -eq $existingAssignment) {   
    Write-Verbose -Message "$($roleDefinition.Name) not assigned to $($g01.DisplayName) group at $($customerNameMG.DisplayName) MG scope. Now assigning..." -Verbose  
New-AzRoleAssignment -ObjectId $g01.Id -RoleDefinitionName $roleDefinition.Name -Scope $customerNameMG.Id
} else {
    Write-Verbose -Message "$($g01.DisplayName) group is already assigned to $($roleDefinition.Name) at $($customerNameMG.DisplayName) MG scope" -Verbose
}

# Log Analytics Reader #
$roleDefinition = Get-AzRoleDefinition -Name "Log Analytics Reader"
# Check existing assignment
$existingAssignment = get-AzRoleAssignment -ObjectId $g01.Id -RoleDefinitionName $roleDefinition.Name -Scope $prodMG.Id
# assign loop
if ($null -eq $existingAssignment) {   
    Write-Verbose -Message "$($roleDefinition.Name) not assigned to $($g01.DisplayName) group at $($customerNameMG.DisplayName) MG scope. Now assigning..." -Verbose 
New-AzRoleAssignment -ObjectId $g01.Id -RoleDefinitionName $roleDefinition.Name -Scope $customerNameMG.Id
} else {
    Write-Verbose -Message "$($g01.DisplayName) group is already assigned to $($roleDefinition.Name) at $($customerNameMG.DisplayName) MG scope" -Verbose
}

# Desktop Virtualization Power On Off Contributor #
$roleDefinition = Get-AzRoleDefinition -Name "Desktop Virtualization Power On Off Contributor"
# Check existing assignment
$existingAssignment = get-AzRoleAssignment -ObjectId $g01.Id -RoleDefinitionName $roleDefinition.Name -Scope $prodMG.Id
# assign loop
if ($null -eq $existingAssignment) {   
    Write-Verbose -Message "$($roleDefinition.Name) not assigned to $($g01.DisplayName) group at $($customerNameMG.DisplayName) MG scope. Now assigning..." -Verbose 
New-AzRoleAssignment -ObjectId $g01.Id -RoleDefinitionName $roleDefinition.Name -Scope $customerNameMG.Id
} else {
    Write-Verbose -Message "$($g01.DisplayName) group is already assigned to $($roleDefinition.Name) at $($customerNameMG.DisplayName) MG scope" -Verbose
}

# Reader #
$roleDefinition = Get-AzRoleDefinition -Name "Reader"
# Check existing assignment
$existingAssignment = get-AzRoleAssignment -ObjectId $g01.Id -RoleDefinitionName $roleDefinition.Name -Scope $prodMG.Id
# assign loop
if ($null -eq $existingAssignment) {   
    Write-Verbose -Message "$($roleDefinition.Name) not assigned to $($g01.DisplayName) group at $($customerNameMG.DisplayName) MG scope. Now assigning..." -Verbose 
New-AzRoleAssignment -ObjectId $g01.Id -RoleDefinitionName $roleDefinition.Name -Scope $customerNameMG.Id
} else {
    Write-Verbose -Message "$($g01.DisplayName) group is already assigned to $($roleDefinition.Name) at $($customerNameMG.DisplayName) MG scope" -Verbose
}

# PAGs (prod & non-prod)
# Define the list of roles to assign
$roleNames = @(
    "Storage Account Contributor",
    "Key Vault Administrator",
    "Key Vault Secrets Officer",
    "Key Vault Certificates Officer",
    "Security Admin",
    "Tag Contributor",
    "Backup Contributor",
    "Desktop Virtualization Virtual Machine Contributor",
    "SQL Managed Instance Contributor",
    "Network Contributor",
    "Virtual Machine Contributor",
    "Monitoring Contributor",
    "Log Analytics Contributor"
)

## Prod PAG ##
# Define the scopes for role assignments
$scopeIds = @($prodMG, $hubMG)

foreach ($roleName in $roleNames) {
    # Get the role definition for the current role
    $roleDefinition = Get-AzRoleDefinition -Name $roleName
    
    # Loop through each scope
    foreach ($scopeId in $scopeIds) {
        # Check if the role assignment already exists for the user, role, and scope
        $existingAssignment = Get-AzRoleAssignment -ObjectId $pg01.Id -RoleDefinitionName $roleDefinition.Name -Scope $scopeId.Id
        
        # If there is no existing assignment, create the new one
        if ($null -eq $existingAssignment) {
            Write-Verbose "Assigning role '$roleName' to group '$($pg01.DisplayName)' at scope '$($scopeId.DisplayName)'..." -Verbose
            New-AzRoleAssignment -ObjectId $pg01.Id -RoleDefinitionName $roleDefinition.Name -Scope $scopeId.Id
        } else {
            Write-Verbose "Role '$roleName' is already assigned to group '$($pg01.DisplayName)' at scope '$($scopeId.DisplayName)'. Skipping assignment." -Verbose
        }
    }
}


# ## Non-Prod PAG ##
# # Define the scopes for role assignments
$scopeIds = @($nonprodMG)

foreach ($roleName in $roleNames) {
    # Get the role definition for the current role
    $roleDefinition = Get-AzRoleDefinition -Name $roleName
    
    # Loop through each scope
    foreach ($scopeId in $scopeIds) {
        # Check if the role assignment already exists for the user, role, and scope
        $existingAssignment = Get-AzRoleAssignment -ObjectId $pg02.Id -RoleDefinitionName $roleDefinition.Name -Scope $scopeId.Id
        
        # If there is no existing assignment, create the new one
        if ($null -eq $existingAssignment) {
            Write-Verbose "Assigning role '$roleName' to group '$($pg02.DisplayName)' at scope '$($scopeId.DisplayName)'..." -Verbose
            New-AzRoleAssignment -ObjectId $pg02.Id -RoleDefinitionName $roleDefinition.Name -Scope $scopeId.Id
        } else {
            Write-Verbose "Role '$roleName' is already assigned to group '$($pg02.DisplayName)' at scope '$($scopeId.DisplayName)'. Skipping assignment." -Verbose
        }
    }
}

##################################################################################################################################################################################
##################################################################################################################################################################################


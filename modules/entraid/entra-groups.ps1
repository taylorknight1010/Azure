# Install Microsoft Graph PowerShell: Install-Module Microsoft.Graph -Scope CurrentUser
# Install Azure PowerShell: Install-Module Az -Scope CurrentUser
import-module Microsoft.Graph.Users
import-module Microsoft.Graph.Identity.Governance
import-module Microsoft.Graph.Identity.DirectoryManagement

# connect-mggraph -TenantId "tenant-id" -UseDeviceCode -Scopes "Group.ReadWrite.All"
# Steps required to carry out end to end #

# Create Entra ID Groups
# List of groups to create
# Copy this code into another text file and find and replace 'MKS' with new customer in CAPS and then 'mks' with new customer in non caps.
$groups_role_no = @(
    @{ GroupName = "non_role_group_1"; Description = "tbc"; MailNickName = "non_role_group_1" },
    @{ GroupName = "non_role_group_1"; Description = "tbc"; MailNickName = "non_role_group_2" }      
)

$groups_role_yes = @(
    @{ GroupName = "role_group_1"; Description = "tbc"; MailNickName = "role_group_1" },   
    @{ GroupName = "role_group_2"; Description = "tbc"; MailNickName = "role_group_2" }
)

# Loop through each group - Role assignable - No
foreach ($group in $groups_role_no) {
    $groupName = $group.GroupName
    $description = $group.Description
    $mailNickName = $group.MailNickName

    # Check if group exists
    $existingGroup = Get-MgGroup -Filter ("DisplayName eq '{0}'" -f $groupName)

    if ($null -eq $existingGroup) {
        Write-Verbose -Message "$groupName group doesn't exist - now creating..." -Verbose
        $params = @{
            DisplayName       = $groupName
            MailEnabled       = $False
            MailNickName      = $mailNickName
            SecurityEnabled   = $True
            Description       = $description
            IsAssignableToRole = $True
        }
        $newGroup = New-MgGroup @params
    } else {
        Write-Verbose -Message "$groupName group already exists" -Verbose
    }
}

# Loop through each group - Role assignable - Yes
foreach ($group in $groups_role_yes) {
    $groupName = $group.GroupName
    $description = $group.Description
    $mailNickName = $group.MailNickName

    # Check if group exists
    $existingGroup = Get-MgGroup -Filter ("DisplayName eq '{0}'" -f $groupName)

    if ($null -eq $existingGroup) {
        Write-Verbose -Message "$groupName group doesn't exist - now creating..." -Verbose
        $params = @{
            DisplayName       = $groupName
            MailEnabled       = $False
            MailNickName      = $mailNickName
            SecurityEnabled   = $True
            Description       = $description
            IsAssignableToRole = $True
        }
        $newGroup = New-MgGroup @params
    } else {
        Write-Verbose -Message "$groupName group already exists" -Verbose
    }
}

# Define dynamic groups array
$dynGroups = @(
    @{
        GroupName   = "customerName All Guest Accounts"
        Description = "This group must include all customerName guest accounts so they can get the tiered PIM roles available to them"
        Rule        = 'user.userType -eq "Guest" and user.mail -contains "customerName.co.uk"'
        MailNickName = "customerNameallguestaccounts"
    },
    @{
        GroupName   = "customerName All Local Accounts"
        Description = "This is for UAT, PPD, PROD access only."
        Rule        = 'user.userPrincipalName -startsWith "customerName"'
        MailNickName = "customerNamealllocalaccounts"
    }
)

# Loop through each dynamic group definition
foreach ($group in $dynGroups) {
    $groupName = $group.GroupName
    $description = $group.Description
    $rule = $group.Rule
    $mailNickName = $group.MailNickName

    # Check if the dynamic group already exists
    $existingGroup = Get-MgGroup -Filter ("DisplayName eq '{0}'" -f $groupName)

    if ($null -eq $existingGroup) {
        Write-Verbose -Message "$groupName dynamic group doesn't exist - now creating..." -Verbose
        
        # Parameters for creating dynamic group
        $params = @{
            DisplayName          = $groupName
            MailEnabled          = $False
            MailNickName         = $mailNickName
            SecurityEnabled      = $True
            Description          = $description
            GroupTypes           = @('DynamicMembership')  # For dynamic groups
            MembershipRule       = $rule
            MembershipRuleProcessingState = 'On'  # Enable membership rule processing
        }

        # Create the dynamic group
        $newGroup = New-MgGroup @params
    } else {
        Write-Verbose -Message "$groupName dynamic group already exists" -Verbose
    }
}




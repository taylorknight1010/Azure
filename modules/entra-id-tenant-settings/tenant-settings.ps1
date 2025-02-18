# ## Install modules required for executing code
# Write-Verbose -Message "Installing Powershell modules required for executing code" -Verbose

# Install-Module Microsoft.Graph -Force
# Install-Module Microsoft.Graph.Beta -AllowClobber -Force

# ## Connect to Microsoft Graph with the required permissions
# Write-Verbose -Message "Connecting to Microsoft Graph with the required permissions" -Verbose

# Connect-MgGraph -UseDeviceCode -TenantId "tenant-id" -Scopes "Policy.Read.All", "Policy.ReadWrite.ConditionalAccess", "Policy.ReadWrite.Authorization", "User.Read.all", "UserAuthenticationMethod.Read.All", "UserAuthenticationMethod.ReadWrite.All", "Policy.ReadWrite.AuthenticationMethod", "Group.Read.All", "Organization.ReadWrite.All", "Policy.ReadWrite.ExternalIdentities", "Policy.ReadWrite.AuthenticationFlows"

## Updating Security Defaults to be disabled
Write-Verbose -Message "Checking Security Defaults status" -Verbose

$SecurityDefaultsCheck = Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy

if ($SecurityDefaultsCheck.IsEnabled -eq $true) {
   Write-Verbose -Message "Security Defaults is enabled" -Verbose
   
   # Disable Security Defaults by setting IsEnabled to false
   Update-MgPolicyIdentitySecurityDefaultEnforcementPolicy -IsEnabled:$false

   Write-Verbose -Message "Security Defaults being set as disabled..." -Verbose
}
else {
   Write-Verbose -Message "Security Defaults is already disabled" -Verbose
}

# Entra ID User Settings

## Entra ID - Default User Role Permissions
Write-Verbose -Message "Checking current Entra ID - Default User Role Permissions" -Verbose

# Retrieve the current Authorization Policy
$currentUserRolePermissions = Get-MgBetaPolicyAuthorizationPolicy -AuthorizationPolicyId authorizationPolicy

# Define the desired user role permissions
$defaultUserRolePermissions = @{
    AllowedToCreateApps           = $false;
    AllowedToCreateSecurityGroups = $false;
    AllowedToCreateTenants        = $false;
    AllowedToReadOtherUsers       = $true
}

# Compare current and desired permissions
if ($currentUserRolePermissions.DefaultUserRolePermissions.AllowedToCreateApps -ne $defaultUserRolePermissions.AllowedToCreateApps -or
    $currentUserRolePermissions.DefaultUserRolePermissions.AllowedToCreateSecurityGroups -ne $defaultUserRolePermissions.AllowedToCreateSecurityGroups -or
    $currentUserRolePermissions.DefaultUserRolePermissions.AllowedToCreateTenants -ne $defaultUserRolePermissions.AllowedToCreateTenants -or
    $currentUserRolePermissions.DefaultUserRolePermissions.AllowedToReadOtherUsers -ne $defaultUserRolePermissions.AllowedToReadOtherUsers) {
    
    Write-Verbose -Message "Updating Entra ID - Default User Role Permissions" -Verbose
    
    # Update the policy with the desired permissions
    Update-MgBetaPolicyAuthorizationPolicy -AuthorizationPolicyId authorizationPolicy -DefaultUserRolePermissions $defaultUserRolePermissions
}
else {
    Write-Verbose -Message "Entra ID - Default User Role Permissions are already set correctly" -Verbose
}


## Entra ID - Guest user access
Write-Verbose -Message "Checking current Entra ID - Guest user access" -Verbose

# Retrieve the current Authorization Policy (no AuthorizationPolicyId needed)
$currentAuthorizationPolicy = Get-MgPolicyAuthorizationPolicy

# Define the desired Guest User Role ID
$desiredGuestUserRoleId = '10dae51f-b6af-4016-8d66-8c2a99b929b3'

# Compare current GuestUserRoleId with the desired one
if ($currentAuthorizationPolicy.GuestUserRoleId -ne $desiredGuestUserRoleId) {
    Write-Verbose -Message "Updating Entra ID - Guest user access" -Verbose

    # Update the GuestUserRoleId if it's different
    Update-MgPolicyAuthorizationPolicy -GuestUserRoleId $desiredGuestUserRoleId
}
else {
    Write-Verbose -Message "Entra ID - Guest user access is already set correctly" -Verbose
}


# ## Update Entra ID Password Reset (SSPR) - might have to change to manual
# Write-Verbose -Message "Update Entra ID Password Reset (SSPR)" -Verbose

# Update-MgPolicyAuthorizationPolicy -AllowedToUseSspr True


## Update the guest invite restrictions to "Only users assigned to specific admin roles can invite guest users"
Write-Verbose -Message "Checking current guest invite restrictions" -Verbose

# Retrieve the current Authorization Policy
$currentAuthorizationPolicy = Get-MgPolicyAuthorizationPolicy

# Define the desired invite restrictions
$desiredInviteRestriction = 'adminsAndGuestInviters'

# Compare current AllowInvitesFrom with the desired setting
if ($currentAuthorizationPolicy.AllowInvitesFrom -ne $desiredInviteRestriction) {
    Write-Verbose -Message "Updating the guest invite restrictions to (Only users assigned to specific admin roles can invite guest users)" -Verbose

    # Update the AllowInvitesFrom setting if it's different
    Update-MgPolicyAuthorizationPolicy -AllowInvitesFrom $desiredInviteRestriction
}
else {
    Write-Verbose -Message "Guest invite restrictions are already set correctly" -Verbose
}

###################### needs testing the rest of this. B2B colloaboation settings is main thing need to fix
## Update the collaboration restrictions to "Allow invitations only to the specified domains"
# $settings.AllowedToInviteGuestsFrom = "SpecificDomains"  # Restrict to specified domains
# $settings.AllowedDomainsForInvitations = @("example.com", "anotherexample.com")  # Replace with your allowed domains

# Entra ID - Technical Contact
Write-Verbose -Message "Checking Entra ID Technical Contact" -Verbose

$emailContact = Get-MgOrganization
$customerNameItSupportContact = "itsupport@customerName.co.uk"

# Join the array into a string, separated by commas
$techNotificationMails = $emailContact.TechnicalNotificationMails -join ", "

if ($emailContact.TechnicalNotificationMails -ne "itsupport@customerName.co.uk") {
    Write-Verbose -Message "Setting Entra ID Technical Contact to use - $customerNameItSupportContact" -Verbose
    
    $tenantinfo = Get-MgOrganization

   $techcontactparams = @{
    technicalNotificationMails = @(
    "itsupport@customerName.co.uk"
   )
   }

   Update-MgOrganization -OrganizationId $tenantinfo.Id -BodyParameter $techcontactparams
}
else {
    Write-Verbose -Message "Technical Contact is already set to $techNotificationMails" -Verbose
}

# Entra ID - Authentication Methods
Write-Verbose -Message "Importing MS Graph Module" -Verbose
Import-Module Microsoft.Graph.Identity.SignIns

# Enabled Authentication Methods

## MicrosoftAuthenticator
Write-Verbose -Message "Checking MS Authenticator Authentication Method" -Verbose
$currentMsAuthConfig = Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "MicrosoftAuthenticator"
if ($currentMsAuthConfig.State -eq "enabled") {
    Write-Verbose -Message "MS Authenticator is already enabled. Skipping to next check." -Verbose
} else {
    Write-Verbose -Message "Enabling MS Authenticator Authentication Method." -Verbose
    $msauthAppParams = @{
        "@odata.type" = "#microsoft.graph.microsoftAuthenticatorAuthenticationMethodConfiguration"
        State = "enabled"
        FeatureSettings = @{
            DisplayAppInformationRequiredState = @{
                State = "enabled"
                IncludeTarget = @{
                    TargetType = "group"
                    Id = "all_users" # Adjust as needed
                }
            }
            DisplayLocationInformationRequiredState = @{
                State = "enabled"
                IncludeTarget = @{
                    TargetType = "group"
                    Id = "all_users" # Adjust as needed
                }
            }
        }
    }
    Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "MicrosoftAuthenticator" -BodyParameter $msauthappparams
}

## Fido2
Write-Verbose -Message "Checking FIDO2 Method" -Verbose
$currentFido2Config = Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "fido2"
if ($currentFido2Config.State -eq "enabled") {
    Write-Verbose -Message "FIDO2 Method is already enabled. Skipping to next check." -Verbose
} else {
    Write-Verbose -Message "Enabling FIDO2 Method." -Verbose
    Write-Verbose -Message "Assigning BG AAD Group to FIDO2." -Verbose
    $bggroup = Get-MgGroup -Filter "displayName eq 'Critical Operations Group'"
    $bggroupId = $bggroup.Id

    $fido2params = @{
        "@odata.type" = "#microsoft.graph.fido2AuthenticationMethodConfiguration"
        id = "Fido2"
        includeTargets = @(
            @{
                id = $bggroupId
                isRegistrationRequired = $false
                targetType = "group"
            }
        )
        excludeTargets = @()
        isAttestationEnforced = $true
        isSelfServiceRegistrationAllowed = $true
        keyRestrictions = @{
            aaGuids = @()
            enforcementType = "block"
            isEnforced = $false
        }
        state = "enabled"
    }

    Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "fido2" -BodyParameter $fido2params
}

## Sms 
Write-Verbose -Message "Checking SMS Authentication Method" -Verbose
$currentSmsConfig = Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "Sms"
if ($currentSmsConfig.State -eq "enabled") {
    Write-Verbose -Message "SMS Authentication Method is already enabled. Skipping to next check." -Verbose
} else {
    Write-Verbose -Message "Enabling SMS Authentication Method." -Verbose
    $smsparams = @{
        "@odata.type" = "#microsoft.graph.smsAuthenticationMethodConfiguration"
        id = "Sms"
        state = "enabled"
    }
    Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId 'Sms' -BodyParameter $smsparams 
}

# Disabled Authentication Methods
Write-Verbose -Message "Disabling remaining Authentication Methods" -Verbose

## EmailOtp
Write-Verbose -Message "Checking Email OTP Authentication Method" -Verbose
$currentEmailConfig = Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "Email"
if ($currentEmailConfig.State -eq "disabled") {
    Write-Verbose -Message "Email OTP Authentication Method is already disabled. Skipping to next check." -Verbose
} else {
    Write-Verbose -Message "Disabling Email OTP Authentication Method." -Verbose
    $emailparams = @{
        "@odata.type" = "#microsoft.graph.emailAuthenticationMethodConfiguration"
        State = "disabled"
    }
    Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "Email" -BodyParameter $emailparams
}

## temporaryAccessPass
Write-Verbose -Message "Checking Temporary Access Pass Authentication Method" -Verbose
$currentTempAccessConfig = Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "temporaryAccessPass"
if ($currentTempAccessConfig.State -eq "disabled") {
    Write-Verbose -Message "Temporary Access Pass Authentication Method is already disabled. Skipping to next check." -Verbose
} else {
    Write-Verbose -Message "Disabling Temporary Access Pass Authentication Method." -Verbose
    $tempaccessparams = @{
        "@odata.type" = "#microsoft.graph.temporaryAccessPassAuthenticationMethodConfiguration"
        State = "disabled"
    }
    Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "temporaryAccessPass" -BodyParameter $tempaccessparams
}

## Voice
Write-Verbose -Message "Checking Voice Authentication Method" -Verbose
$currentVoiceConfig = Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "Voice"
if ($currentVoiceConfig.State -eq "disabled") {
    Write-Verbose -Message "Voice Authentication Method is already disabled. Skipping to next check." -Verbose
} else {
    Write-Verbose -Message "Disabling Voice Authentication Method." -Verbose
    $voiceparams = @{
        "@odata.type" = "#microsoft.graph.voiceAuthenticationMethodConfiguration"
        State = "disabled"
    }
    Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "Voice" -BodyParameter $voiceparams
}

## X509Certificate
Write-Verbose -Message "Checking X509 Certificate Authentication Method" -Verbose
$currentCertConfig = Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "X509Certificate"
if ($currentCertConfig.State -eq "disabled") {
    Write-Verbose -Message "X509 Certificate Authentication Method is already disabled. Skipping to next check." -Verbose
} else {
    Write-Verbose -Message "Disabling X509 Certificate Authentication Method." -Verbose
    $certparams = @{
        "@odata.type" = "#microsoft.graph.X509CertificateAuthenticationMethodConfiguration"
        State = "disabled"
    }
    Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "X509Certificate" -BodyParameter $certparams
}

## SoftwareOath
Write-Verbose -Message "Checking Software Oath Authentication Method" -Verbose
$currentSoftwareConfig = Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "SoftwareOath"
if ($currentSoftwareConfig.State -eq "disabled") {
    Write-Verbose -Message "Software Oath Authentication Method is already disabled. Skipping to next check." -Verbose
} else {
    Write-Verbose -Message "Disabling Software Oath Authentication Method." -Verbose
    $softwareparams = @{
        "@odata.type" = "#microsoft.graph.SoftwareOathAuthenticationMethodConfiguration"
        State = "disabled"
    }
    Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId "SoftwareOath" -BodyParameter $softwareparams
}


## HardwareOath
# Import the Microsoft Graph Beta module for managing Identity Sign-Ins
Write-Verbose -Message "Importing Microsoft Graph Beta Module" -Verbose
Import-Module Microsoft.Graph.Beta.Identity.SignIns

# Initialize the variable for the authentication method configuration ID
$authenticationMethodConfigurationId = "HardwareOath"  # Replace with your actual ID

# Define parameters for the authentication method configuration
$params = @{
    "@odata.type" = "#microsoft.graph.hardwareOathAuthenticationMethodConfiguration"
    id = "HardwareOath"
    includeTargets = @(
        @{
            id = "all_users"
            isRegistrationRequired = $false
            targetType = "group"
        }
    )
    excludeTargets = @()  # Add any exclude targets if necessary
    state = "disabled"
}

# Optional: Enable verbose logging
$DebugPreference = "SilentlyContinue"

# Check the current state of the Hardware Oath Authentication Method
$currentHardwareOathConfig = Get-MgBetaPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $authenticationMethodConfigurationId

if ($currentHardwareOathConfig.State -eq "disabled") {
    Write-Verbose -Message "Hardware Oath Authentication Method is already disabled. Skipping update." -Verbose
} else {
    Write-Verbose -Message "Disabling Hardware Oath Authentication Method." -Verbose
    # Update the authentication method policy configuration with error handling
    try {
        $response = Update-MgBetaPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId $authenticationMethodConfigurationId -BodyParameter $params
        Write-Host "Hardware Oath Authentication method configuration updated successfully." -ForegroundColor Green
        Write-Host "Response:" -ForegroundColor Yellow
        $response | Format-List
    } catch {
        Write-Error "An error occurred while updating the authentication method configuration: $_"
    }
}

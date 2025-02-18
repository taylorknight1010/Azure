#CAP001 Require MFA For Administrators 

resource "azuread_conditional_access_policy" "CAP001_Require_MFA_For_Administrators" {
  count = var.cap001_create == true ? 1 : 0 
  display_name = "CAP001 - Require MFA For Administrators (Report Only)"
  state        = var.cap001_state

  conditions {
    client_app_types    = ["all"]

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    locations {
      included_locations = ["All"]
    }

    platforms {
      included_platforms = ["all"]
    }

    users {
      included_roles = var.privileged_role_ids  
      excluded_users = var.breakglass_users
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }

  session_controls {
    sign_in_frequency                         = 1
    sign_in_frequency_period                  = "days"
  }
}

/*CAP002 Require phishing-resistant MFA for Administrators - Needs WHfB, FIDO2 or Certificate-based Authentication set up for Admins 

resource "azuread_conditional_access_policy" "CAP002_Require_Phishing_Resistant_MFA_For_Administrators" {
  display_name = "CAP002 - Require Phishing-Resistant MFA for Administrators (Report Only)"
  state        = "enabledForReportingButNotEnforced"

  conditions {
    client_app_types = []

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    locations {
      included_locations = ["All"]
    }

    platforms {
      included_platforms = ["all"]
    }

    users {
      included_roles = var.privileged_role_ids # Replace with actual role IDs for Global Administrator, etc.
      excluded_users = var.breakglass_users # Breakglass accounts
    }
  }

  grant_controls {
    operator = "OR"
    authentication_strength_policy_id = "00000000-0000-0000-0000-000000000004" # Replace with the actual ID of the phishing-resistant MFA policy
  }
} */


#CAP003 Sign-in & User Risk Policy for Administrators 

resource "azuread_conditional_access_policy" "CAP003_Sign-In_User_Risk_Policy_for_Administrators" {
  count = var.cap003_create == true ? 1 : 0 
  display_name = "CAP003 - Sign-In & User Risk Policy for Administrators (Report Only)"
  state = var.cap003_state

  conditions {
    sign_in_risk_levels = ["medium", "high"]
    user_risk_levels = ["medium", "high"]
     client_app_types    = ["all"]

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    locations {
      included_locations = ["All"]
    }

     platforms {
      included_platforms = ["all"]
    }

  users {
    included_roles = var.privileged_role_ids
    excluded_users = var.breakglass_users
  }

  }
  grant_controls {
    operator = "OR"
    built_in_controls = ["mfa"]
  }
  
}

#CAP004 Sign-in Session Policy for Administrators - Double check 

resource "azuread_conditional_access_policy" "CAP004_Sign_In_Session_Policy_for_Administrators" {
  count = var.cap004_create == true ? 1 : 0
  display_name = "CAP004 - Sign-In Session Policy for Administrators (Report Only)"
  state        = var.cap004_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    locations {
      included_locations = ["All"]
    }

    platforms {
      included_platforms = ["all"]
    }

    users {
      included_roles = var.privileged_role_ids 
      excluded_users = var.breakglass_users
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }

  session_controls {
    sign_in_frequency = 4
    sign_in_frequency_period = "hours"  
    persistent_browser_mode = "never"
  }
}

#CAP005 Block Unknown or Unsupported Platforms for Administrators  - Double check 


resource "azuread_conditional_access_policy" "CAP005_Block_Unsupported_Platforms_Adminstrators" {
  count = var.cap005_create == true ? 1 : 0
  display_name = "CAP005 - Block Unsupported Platforms for Administrators (Report Only)"
  state        = var.cap005_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    locations {
      included_locations = ["All"]
    }

    platforms {
      included_platforms = ["all"]
      excluded_platforms = ["android", "iOS", "macOS", "windows", "linux"]
    }

    users {
      included_roles = var.privileged_role_ids 
      excluded_users = var.breakglass_users
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}


#CAP006 Block Legacy Authentication 

resource "azuread_conditional_access_policy" "CA006_Block_Legacy_Auth" {
  count = var.cap006_create == true ? 1 : 0
  display_name = "CAP006 - Block Legacy Auth (Report Only)"
  state        = var.cap006_state

  conditions {
    client_app_types    = ["exchangeActiveSync", "other"]

    applications {
      included_applications = ["All"]
    }

    locations {
      included_locations = ["All"]
    }

    platforms {
      included_platforms = ["all"]
    }

    users {
      included_users = ["All"]
      excluded_users = ["GuestsOrExternalUsers"]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

#CAP007 Block banned locations 

resource "azuread_conditional_access_policy" "CAP007_Block_Banned_Locations" {
  count = var.cap007_create == true ? 1 : 0
  display_name = "CAP007 - Block Banned Locations (Report Only)"
  state        = var.cap007_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    locations {
      included_locations = [azuread_named_location.blacklisted_countries.id] # Ensure "Blacklisted Countries" is a named location in Entra ID
    }

    platforms {
      included_platforms = ["all"]
    }

    users {
      included_users = ["All"]
      excluded_users = var.breakglass_users # Breakglass accounts
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

#CAP008 Require MFA for All Users 

resource "azuread_conditional_access_policy" "CAP008_Require_MFA_For_All_Users" {
  count = var.cap008_create == true ? 1 : 0
  display_name = "CAP008 - Require MFA For All Users (Report Only)"
  state        = var.cap008_state

  conditions {
    client_app_types    = ["all"]

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    locations {
      included_locations = ["All"]
    }

    platforms {
      included_platforms = ["all"]
    }

    users {
      included_users = ["All"] 
      excluded_users = var.breakglass_users
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }

  session_controls {
    sign_in_frequency                         = 7
    sign_in_frequency_period                  = "days"
  }
}


# Existing Live Policies #

#LEGACY001 Require MFA for All Users (except trusted locations)
resource "azuread_conditional_access_policy" "LEGACY001" {
  count = var.legacy001_create == true ? 1 : 0  
  display_name = "LEGACY001 - Require MFA For All Users (1 Days)"
  state        = var.legacy001_state

  conditions {
    client_app_types    = ["all"]

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    locations {
      included_locations = ["All"]
      excluded_locations = [
        azuread_named_location.customerName.id,
        azuread_named_location.customer.id
       ]
    }

    platforms {
      included_platforms = ["all"]
    }

    users {
      included_users = ["All"] 
      excluded_users = var.breakglass_users
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }

  session_controls {
    sign_in_frequency                         = 1
    sign_in_frequency_period                  = "days"
  }
}

#LEGACY002 Require MFA for customerName Location
resource "azuread_conditional_access_policy" "LEGACY002" {
  count = var.legacy002_create == true ? 1 : 0  
  display_name = "LEGACY002 - Require MFA For All Users (7 Days)"
  state        = var.legacy002_state

  conditions {
    client_app_types    = ["all"]

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    locations {
      included_locations = [azuread_named_location.customerName.id]
      excluded_locations = []
    }

    platforms {
      included_platforms = ["all"]
    }

    users {
      included_users = ["All"] 
      excluded_users = var.breakglass_users
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }

  session_controls {
    sign_in_frequency                         = 7
    sign_in_frequency_period                  = "days"
  }
}

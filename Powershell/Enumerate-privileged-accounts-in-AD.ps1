# Enumerate ACLs on the DNC object 
# Run the following command: 

$ADSI=[ADSI]"LDAP://DC=fabrikam,DC=com" 
$ADSI.psbase.get_ObjectSecurity().getAccessRules($true, $true,[system.security.principal.NtAccount])

# Enumerate ACLs on the AdminSDHolder container 
# Run the following command: 

$ADSI=[ADSI]"LDAP://CN=AdminSDHolder,CN=System,DC=fabrikam,DC=com" 
$ADSI.psbase.get_ObjectSecurity().getAccessRules($true, $true,[system.security.principal.NtAccount])

# Enumerate ACLs on the MicrosoftDNS container 
# Run the following command: 

$ADSI=[ADSI]"LDAP://CN=MicrosoftDNS,CN=System,DC=fabrikam,DC=com" 
$ADSI.psbase.get_ObjectSecurity().getAccessRules($true, $true,[system.security.principal.NtAccount])

# Servers configured for Unconstrained Delegation (Excluding DC’s) 
# All the servers that are configured for Unconstrained Delegation provide escalation paths to DA or equivalent and needs to be managed from a Tier-0 
# Run the following command: 

([adsisearcher]'(&(objectCategory=computer)(!(primaryGroupID=516)(userAccountControl:1.2.840.113556.1.4.803:=524288)))').FindAll()

# User accounts with admin count set to 1
# To discover all the members that are part of a protected group. Run the following command: 

([adsisearcher]'(&(objectClass=user)(adminCount=1))').FindAll()

# Unconstatined user accounts configured

([adsisearcher]'(&(objectCategory=user)(userAccountControl:1.2.840.113556.1.4.803:=524288))').FindAll() 

# Get membership from privileged groups
# DnsAdmins
([adsisearcher]'(memberOf=cn=DnsAdmins,CN=Users,dc=fabrikam,dc=com)').FindAll() 
# Do the same for the rest of the priv groups:
# Domain Admins 
# Enterprise Admins 
# Schema Admins 
# Administrators 
# Account Operators 
# Backup Operators 
# Server Operators 
# Print Operators 
# Cert Publishers 
# Group Policy Creator Owners

# Get Local Admin membership from Tier 0 servers
# AD Connect, PKI, ADFS etc - Tier 0 examples
$LocalGroup =[ADSI]"WinNT://Server/Administrators" 
$UserNames = @($LocalGroup.psbase.Invoke("Members")) 
$UserNames | foreach {$_.GetType().InvokeMember("Name",'GetProperty', $null, $_, $null)} 




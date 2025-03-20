#Only Varible that needs updating is "CompanyName" which you put in the value of the business. Everything else is picked up from environmental varibles. 
$CompanyName = "CompanyName"
$CompanyNameOU = "OU=" + $CompanyName + "," + $DistinguishedName.DistinguishedName
$DistinguishedName = Get-ADDomain | select -Property DistinguishedName
$Tier0Path = "OU=Tier0," + $CompanyNameOU
$Tier1Path = "OU=Tier1," + $CompanyNameOU
$Tier2Path = "OU=Tier2," + $CompanyNameOU
$Tier0ServersPath = "OU=Tier0-Servers" + "," + "OU=Tier0," + $CompanyNameOU
$Tier0UsersPath = "OU=Tier0-Users" + "," + "OU=Tier0," + $CompanyNameOU
$Tier1ServersPath = "OU=Tier1-Servers" + "," + "OU=Tier1," + $CompanyNameOU
$Tier1UsersPath = "OU=Tier1-Users" + "," + "OU=Tier1," + $CompanyNameOU
$Tier1LandscapePath = "OU=Tier1-Landscape" + "," + "OU=Tier1-Servers" + "," + "OU=Tier1," + $CompanyNameOU
$Tier2ServersPath = "OU=Tier2-Servers" + "," + "OU=Tier2," + $CompanyNameOU
$Tier2UsersPath = "OU=Tier2-Users" + "," + "OU=Tier2," + $CompanyNameOU
$Tier2ComputersPath = "OU=Tier2-Computers" + "," + "OU=Tier2," + $CompanyNameOU
$Tier2ComputersAVDPath = "OU=Tier2-AVD" + "," + "OU=Tier2-Computers" + "," + "OU=Tier2," + $CompanyNameOU


###########################################################################################################################################

#Create root customer OU
New-ADOrganizationalUnit -Name $CompanyName -Path $DistinguishedName.DistinguishedName -ProtectedFromAccidentalDeletion $True

###########################################################################################################################################

    #Create t0 customer OU
New-ADOrganizationalUnit -Name "Tier0" -Path $CompanyNameOU -ProtectedFromAccidentalDeletion $True

        #Create t0 users OU
New-ADOrganizationalUnit -Name "Tier0-Users" -Path $Tier0Path -ProtectedFromAccidentalDeletion $True

            #Create t0 admin users OU
New-ADOrganizationalUnit -Name "Tier0-Admin" -Path $Tier0UsersPath -ProtectedFromAccidentalDeletion $True

            #Create t0 service accounts OU
New-ADOrganizationalUnit -Name "Tier0-ServiceAccounts" -Path $Tier0UsersPath -ProtectedFromAccidentalDeletion $True

        #Create t0 groups OU
New-ADOrganizationalUnit -Name "Tier0-Groups" -Path $Tier0Path -ProtectedFromAccidentalDeletion $True

        #Create t0 servers OU
New-ADOrganizationalUnit -Name "Tier0-Servers" -Path $Tier0Path -ProtectedFromAccidentalDeletion $True

            #Create t0 servers paws OU
New-ADOrganizationalUnit -Name "Tier0-PAW" -Path $Tier0ServersPath -ProtectedFromAccidentalDeletion $True

###########################################################################################################################################

    #Create t1 customer OU
New-ADOrganizationalUnit -Name "Tier1" -Path $CompanyNameOU -ProtectedFromAccidentalDeletion $True

        #Create t1 users OU
New-ADOrganizationalUnit -Name "Tier1-Users" -Path $Tier1Path -ProtectedFromAccidentalDeletion $True

            #Create t1 admin users OU
New-ADOrganizationalUnit -Name "Tier1-Admin" -Path $Tier1UsersPath -ProtectedFromAccidentalDeletion $True

            #Create t1 service accounts OU
New-ADOrganizationalUnit -Name "Tier1-ServiceAccounts" -Path $Tier1UsersPath -ProtectedFromAccidentalDeletion $True

        #Create t1 groups OU
New-ADOrganizationalUnit -Name "Tier1-Groups" -Path $Tier1Path -ProtectedFromAccidentalDeletion $True

        #Create t1 servers OU
New-ADOrganizationalUnit -Name "Tier1-Servers" -Path $Tier1Path -ProtectedFromAccidentalDeletion $True

            #Create t1 servers landscape OU
New-ADOrganizationalUnit -Name "Tier1-Landscape" -Path $Tier1ServersPath -ProtectedFromAccidentalDeletion $True

                #Create t1 servers landscape prod OU
New-ADOrganizationalUnit -Name "Tier1-Landscape-Prod" -Path $Tier1LandscapePath -ProtectedFromAccidentalDeletion $True

                #Create t1 servers landscape pre-prod OU
New-ADOrganizationalUnit -Name "Tier1-Landscape-PProd" -Path $Tier1LandscapePath -ProtectedFromAccidentalDeletion $True

                #Create t1 servers landscape uat OU
New-ADOrganizationalUnit -Name "Tier1-Landscape-UAT" -Path $Tier1LandscapePath -ProtectedFromAccidentalDeletion $True

                #Create t1 servers landscape beta OU
New-ADOrganizationalUnit -Name "Tier1-Landscape-Beta" -Path $Tier1LandscapePath -ProtectedFromAccidentalDeletion $True


###########################################################################################################################################

    #Create t2 customer OU
New-ADOrganizationalUnit -Name "Tier2" -Path $CompanyNameOU -ProtectedFromAccidentalDeletion $True

        #Create t2 users OU
New-ADOrganizationalUnit -Name "Tier2-Users" -Path $Tier2Path -ProtectedFromAccidentalDeletion $True

            #Create t2 admin users OU
New-ADOrganizationalUnit -Name "Tier2-Admin" -Path $Tier2UsersPath -ProtectedFromAccidentalDeletion $True

            #Create t2 service accounts OU
New-ADOrganizationalUnit -Name "Tier2-ServiceAccounts" -Path $Tier2UsersPath -ProtectedFromAccidentalDeletion $True

        #Create t2 groups OU
New-ADOrganizationalUnit -Name "Tier2-Groups" -Path $Tier2Path -ProtectedFromAccidentalDeletion $True

        #Create t2 servers OU
New-ADOrganizationalUnit -Name "Tier2-Servers" -Path $Tier2Path -ProtectedFromAccidentalDeletion $True

           #Create t2 servers securezone OU
New-ADOrganizationalUnit -Name "Tier2-SecureZone" -Path $Tier2ServersPath -ProtectedFromAccidentalDeletion $True

        #Create t2 computers OU
New-ADOrganizationalUnit -Name "Tier2-Computers" -Path $Tier2Path -ProtectedFromAccidentalDeletion $True

            #Create t2 computers avd OU
New-ADOrganizationalUnit -Name "Tier2-AVD" -Path $Tier2ComputersPath -ProtectedFromAccidentalDeletion $True

                #Create t2 avd prod OU
New-ADOrganizationalUnit -Name "Tier2-AVD-Prod" -Path $Tier2ComputersAVDPath -ProtectedFromAccidentalDeletion $True

                #Create t2 avd pre-prod OU
New-ADOrganizationalUnit -Name "Tier2-AVD-PProd" -Path $Tier2ComputersAVDPath -ProtectedFromAccidentalDeletion $True

                #Create t2 avd uat OU
New-ADOrganizationalUnit -Name "Tier2-AVD-UAT" -Path $Tier2ComputersAVDPath -ProtectedFromAccidentalDeletion $True

                #Create t2 avd uat OU
New-ADOrganizationalUnit -Name "Tier2-AVD-Beta" -Path $Tier2ComputersAVDPath -ProtectedFromAccidentalDeletion $True


###########################################################################################################################################

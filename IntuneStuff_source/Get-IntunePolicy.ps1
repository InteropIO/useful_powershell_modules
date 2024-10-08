﻿#requires -modules Microsoft.Graph.Authentication, Microsoft.Graph.Beta.Devices.CorporateManagement, Microsoft.Graph.Beta.DeviceManagement, Microsoft.Graph.Beta.DeviceManagement.Enrollment

#if (!(Get-Module -ListAvailable -Name "newtonsoft.json")) {
#    Install-Module -Name "newtonsoft.json" -Scope CurrentUser -Force
#}
#
#Import-Module "newtonsoft.json" -Scope Local

function Format-Json([Parameter(Mandatory, ValueFromPipeline)][String] $json) {
    $indent = 0;
    ($json -Split "`n" | % {
        if ($_ -match '[\}\]]\s*,?\s*$') {
            # This line ends with ] or }, decrement the indentation level
            $indent--
        }
        $line = ('  ' * $indent) + $($_.TrimStart() -replace '":  (["{[])', '": $1' -replace ':  ', ': ')
        if ($_ -match '[\{\[]\s*$') {
            # This line ends with [ or {, increment the indentation level
            $indent++
        }
        $line
    }) -Join "`n"
}

function Get-IntunePolicy1 {
    <#
    .SYNOPSIS
    Function for getting all/subset of Intune (assignable) policies using Graph API.

    .DESCRIPTION
    Function for getting all/subset of Intune (assignable) policies using Graph API.

    These policies can be retrieved:
     - Apps
     - App Configuration policies
     - App Protection policies
     - Compliance policies
     - Configuration policies
      - Administrative Templates
      - Settings Catalog
      - Templates
     - MacOS Custom Attribute Shell Scripts
     - Device Enrollment Configurations
     - Device Management PowerShell scripts
     - Device Management Shell scripts
     - Endpoint Security
        - Account Protection policies
        - Antivirus policies
        - Attack Surface Reduction policies
        - Defender policies
        - Disk Encryption policies
        - Endpoint Detection and Response policies
        - Firewall policies
        - Security baselines
     - iOS App Provisioning profiles
     - iOS Update Configurations
     - MacOS Software Update Configurations
     - Policy Sets
     - Remediation Scripts
     - S Mode Supplemental policies
     - Windows Autopilot Deployment profiles
     - Windows Feature Update profiles
     - Windows Quality Update profiles
     - Windows Update Rings

    .PARAMETER policyType
    What type of policies should be gathered.

    Possible values are:
    'ALL' to get all policies.

    'app','appConfigurationPolicy','appProtectionPolicy','compliancePolicy','configurationPolicy','customAttributeShellScript','deviceEnrollmentConfiguration','deviceManagementPSHScript','deviceManagementShellScript','endpointSecurity','iosAppProvisioningProfile','iosUpdateConfiguration','macOSSoftwareUpdateConfiguration','policySet','remediationScript','sModeSupplementalPolicy','windowsAutopilotDeploymentProfile','windowsFeatureUpdateProfile','windowsQualityUpdateProfile','windowsUpdateRing' to get just some policies subset.

    By default 'ALL' policies are selected.

    .PARAMETER basicOverview
    Switch. Just some common subset of available policy properties will be gathered (id, displayName, lastModifiedDateTime, assignments).
    Makes the result more human readable.

    .PARAMETER flatOutput
    Switch. All Intune policies will be outputted as array instead of one psobject with policies divided into separate sections/object properties.
    Policy parent "type" is added as new property 'PolicyType' to each policy for filtration purposes.

    .EXAMPLE
    Connect-MSGraph
    Get-IntunePolicy

    Get all Intune policies.

    .EXAMPLE
    Connect-MSGraph
    Get-IntunePolicy -policyType 'app', 'compliancePolicy'

    Get just Apps and Compliance Intune policies.

    .EXAMPLE
    Connect-MSGraph
    Get-IntunePolicy -policyType 'app', 'compliancePolicy' -basicOverview

    Get just Apps and Compliance Intune policies with subset of available properties (id, displayName, lastModifiedDateTime, assignments) for each policy.

    .EXAMPLE
    Connect-MSGraph
    Get-IntunePolicy -flatOutput

    Get all Intune policies, but not as one psobject, but as array of all policies.
    #>

    [CmdletBinding()]
    param (
        # if policyType values changes, don't forget to modify 'Search-IntuneAccountPolicyAssignment' accordingly!
        [ValidateSet('ALL', 'app', 'appConfigurationPolicy', 'appProtectionPolicy', 'compliancePolicy', 'configurationPolicy', 'customAttributeShellScript', 'deviceEnrollmentConfiguration', 'deviceManagementPSHScript', 'deviceManagementShellScript', 'endpointSecurity', 'iosAppProvisioningProfile', 'iosUpdateConfiguration', 'macOSSoftwareUpdateConfiguration', 'policySet', 'remediationScript', 'sModeSupplementalPolicy', 'windowsAutopilotDeploymentProfile', 'windowsFeatureUpdateProfile', 'windowsQualityUpdateProfile', 'windowsUpdateRing')]
        [string[]] $policyType = 'ALL',

        [switch] $basicOverview,

        [switch] $flatOutput
    )
    
    Write-Host "HI"

    if (!(Get-Command Get-MgContext -ErrorAction silentlycontinue) -or !(Get-MgContext)) {
        throw "$($MyInvocation.MyCommand): Authentication needed. Please call Connect-MgGraph."
    }

    if ($policyType -contains 'ALL') {
        Write-Verbose "ALL policies will be gathered"
        $all = $true
    } else {
        $all = $false
    }

    # create parameters hash for sub-functions and uri parameters for api calls
    if ($basicOverview) {
        Write-Verbose "Just subset of available policy properties will be gathered"
        $selectFilter = '&$select=id,displayName,lastModifiedDateTime,assignments' # these properties are common across all intune policies, so it is safe to use them
        $expandFilter = '&$expand=assignments'
    } else {
        $selectFilter = $null
        $expandFilter = '&$expand=assignments'
    }
    $sharedParam = @{
        all    = $true
        expand = "assignments"
    }
    if ($basicOverview) {
        Write-Verbose "Just subset of available policy properties will be gathered"
        $param.select = ('id', 'displayName', 'lastModifiedDateTime', 'assignments')
    }

    # progress variables
    $i = 0
    $policyTypeCount = $policyType.Count
    if ($policyType -eq 'ALL') {
        $policyTypeCount = (Get-Variable "policyType").Attributes.ValidValues.count - 1
    }
    $progressActivity = "Getting Intune policies"

    #region get Intune policies
    # define main PS object property hash
    $resultProperty = [ordered]@{}

    # Apps
    if ($all -or $policyType -contains 'app') {
        # https://graph.microsoft.com/beta/deviceAppManagement/mobileApps
        Write-Verbose "Processing Apps"
        Write-Progress -Activity $progressActivity -Status "Processing Apps" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $param = $sharedParam.clone()
        $param.filter = "microsoft.graph.managedApp/appAvailability eq null or microsoft.graph.managedApp/appAvailability eq 'lineOfBusiness' or isAssigned eq true"
        $app = Get-MgBetaDeviceAppManagementMobileApp @param

        $resultProperty.App = $app
    }

    # App Configuration policies
    if ($all -or $policyType -contains 'appConfigurationPolicy') {
        Write-Verbose "Processing App Configuration policies"
        Write-Progress -Activity $progressActivity -Status "Processing App Configuration policies" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $appConfigurationPolicy = @()

        # targetedManagedAppConfigurations
        Write-Verbose "`t- processing 'targetedManagedAppConfigurations'"
        $targetedManagedAppConfigurations = Get-MgBetaDeviceAppManagementTargetedManagedAppConfiguration @sharedParam
        $targetedManagedAppConfigurations | ? { $_ } | % { $appConfigurationPolicy += $_ }

        # mobileAppConfigurations
        Write-Verbose "`t- processing 'mobileAppConfigurations'"
        $param = $sharedParam.clone()
        $param.filter = "microsoft.graph.androidManagedStoreAppConfiguration/appSupportsOemConfig eq false or isof('microsoft.graph.androidManagedStoreAppConfiguration') eq false"
        $mobileAppConfigurations = Get-MgBetaDeviceAppManagementMobileAppConfiguration @param
        $mobileAppConfigurations | ? { $_ } | % { $appConfigurationPolicy += $_ }

        if ($appConfigurationPolicy) {
            $resultProperty.AppConfigurationPolicy = $appConfigurationPolicy
        } else {
            $resultProperty.AppConfigurationPolicy = $null
        }
    }

    # App Protection policies
    if ($all -or $policyType -contains 'appProtectionPolicy') {
        Write-Verbose "Processing App Protection policies"
        Write-Progress -Activity $progressActivity -Status "Processing App Protection policies" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $appProtectionPolicy = @()

        # iosManagedAppProtections
        Write-Verbose "`t- processing 'iosManagedAppProtections'"
        $iosManagedAppProtections = Get-MgBetaDeviceAppManagementiOSManagedAppProtection @sharedParam
        $iosManagedAppProtections | ? { $_ } | % { $appProtectionPolicy += $_ }

        # androidManagedAppProtections
        Write-Verbose "`t- processing 'androidManagedAppProtections'"
        $androidManagedAppProtections = Get-MgBetaDeviceAppManagementAndroidManagedAppProtection @sharedParam
        $androidManagedAppProtections | ? { $_ } | % { $appProtectionPolicy += $_ }

        # targetedManagedAppConfigurations
        Write-Verbose "`t- processing 'targetedManagedAppConfigurations'"
        $targetedManagedAppConfigurations = Get-MgBetaDeviceAppManagementTargetedManagedAppConfiguration @sharedParam
        $targetedManagedAppConfigurations | ? { $_ } | % { $appProtectionPolicy += $_ }

        # windowsInformationProtectionPolicies
        Write-Verbose "`t- processing 'windowsInformationProtectionPolicies'"
        # unable to use cmdlet because of error: Get-MgBetaDeviceAppManagementWindowsInformationProtectionPolicy_List: Object reference not set to an instance of an object.
        $uri = "https://graph.microsoft.com/beta/deviceAppManagement/windowsInformationProtectionPolicies?$expandFilter$selectFilter"
        $windowsInformationProtectionPolicies = Invoke-MgGraphRequest -Uri $uri | Get-MgGraphAllPages | select -Property * -ExcludeProperty 'assignments@odata.context'
        $windowsInformationProtectionPolicies | ? { $_ } | % { $appProtectionPolicy += $_ }

        # mdmWindowsInformationProtectionPolicies
        Write-Verbose "`t- processing 'mdmWindowsInformationProtectionPolicies'"
        $mdmWindowsInformationProtectionPolicies = Get-MgBetaDeviceAppManagementMdmWindowsInformationProtectionPolicy @sharedParam
        $mdmWindowsInformationProtectionPolicies | ? { $_ } | % { $appProtectionPolicy += $_ }

        if ($appProtectionPolicy) {
            $resultProperty.AppProtectionPolicy = $appProtectionPolicy
        } else {
            $resultProperty.AppProtectionPolicy = $null
        }
    }

    # Device Compliance
    if ($all -or $policyType -contains 'compliancePolicy') {
        Write-Verbose "Processing Compliance policies"
        Write-Progress -Activity $progressActivity -Status "Processing Compliance policies" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $compliancePolicy = Get-MgBetaDeviceManagementDeviceCompliancePolicy @sharedParam

        $resultProperty.CompliancePolicy = $compliancePolicy
    }

    # Device Configuration
    # contains all policies as can be seen in Intune web portal 'Device' > 'Device Configuration'
    if ($all -or $policyType -contains 'configurationPolicy') {
        Write-Verbose "Processing Configuration policies"
        Write-Progress -Activity $progressActivity -Status "Processing Configuration policies" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $configurationPolicy = @()

        # Templates profile type
        # api returns also Windows Update Ring policies, but they are filtered, so just policies as in GUI are returned
        Write-Verbose "`t- processing 'deviceConfigurations'"
        $param = $sharedParam.clone()
        $param.filter = "not isof('microsoft.graph.windowsUpdateForBusinessConfiguration') and not isof('microsoft.graph.iosUpdateConfiguration')"
        $dcTemplate = Get-MgBetaDeviceManagementDeviceConfiguration @param
        $dcTemplate | ? { $_ } | % { $configurationPolicy += $_ }

        # Administrative Templates
        Write-Verbose "`t- processing 'groupPolicyConfigurations'"
        $dcAdmTemplate = Get-MgBetaDeviceManagementGroupPolicyConfiguration @sharedParam
        $dcAdmTemplate | ? { $_ } | % { $configurationPolicy += $_ }

        # mobileAppConfigurations
        Write-Verbose "`t- processing 'mobileAppConfigurations'"
        $param = $sharedParam.clone()
        $param.filter = "microsoft.graph.androidManagedStoreAppConfiguration/appSupportsOemConfig eq true"
        $dcMobileAppConf = Get-MgBetaDeviceAppManagementMobileAppConfiguration @param
        $dcMobileAppConf | ? { $_ } | % { $configurationPolicy += $_ }

        # Settings Catalog profile type
        # api returns also Attack Surface Reduction Rules and Account protection policies (from Endpoint Security section), but they are filtered, so just policies as in GUI are returned
        # configurationPolicies objects have property Name instead of DisplayName
        Write-Verbose "`t- processing 'configurationPolicies'"
        $param = $sharedParam.clone()
        $param.select = $param.select -replace "displayname", "name"
        $param.expand += ",settings"
        $param.filter = "(platforms eq 'windows10' or platforms eq 'macOS' or platforms eq 'iOS') and (technologies eq 'mdm' or technologies eq 'windows10XManagement' or technologies eq 'appleRemoteManagement' or technologies eq 'mdm,appleRemoteManagement') and (templateReference/templateFamily eq 'none')"
        $dcSettingCatalog = Get-MgBetaDeviceManagementConfigurationPolicy @param
        $dcSettingCatalog | ? { $_ } | % { $configurationPolicy += $_ }

        if ($configurationPolicy) {
            $resultProperty.ConfigurationPolicy = $configurationPolicy
        } else {
            $resultProperty.ConfigurationPolicy = $null
        }
    }

    # MacOS Custom Attribute Shell scripts
    if ($all -or $policyType -contains 'customAttributeShellScript') {
        Write-Verbose "Processing Custom Attribute Shell scripts"
        Write-Progress -Activity $progressActivity -Status "Processing Custom Attribute Shell scripts" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceCustomAttributeShellScripts?$expandFilter$selectFilter"
        $customAttributeShellScript = Invoke-MgGraphRequest -Uri $uri | Get-MgGraphAllPages | select -Property * -ExcludeProperty 'assignments@odata.context'

        $resultProperty.CustomAttributeShellScript = $customAttributeShellScript
    }

    # ESP, WHFB, Enrollment Limit, Enrollment Platform Restrictions configurations
    if ($all -or $policyType -contains 'deviceEnrollmentConfiguration') {
        Write-Verbose "Processing Device Enrollment configurations: ESP, WHFB, Enrollment Limit, Enrollment Platform Restrictions"
        Write-Progress -Activity $progressActivity -Status "Processing Device Enrollment configurations: ESP, WHFB, Enrollment Limit, Enrollment Platform Restrictions" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $deviceEnrollmentConfiguration = Get-MgBetaDeviceManagementDeviceEnrollmentConfiguration @sharedParam

        $resultProperty.DeviceEnrollmentConfiguration = $deviceEnrollmentConfiguration
    }

    # Device Configuration Powershell Scripts
    if ($all -or $policyType -contains 'deviceManagementPSHScript') {
        Write-Verbose "Processing PowerShell scripts"
        Write-Progress -Activity $progressActivity -Status "Processing PowerShell scripts" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $deviceConfigPSHScript = Get-MgBetaDeviceManagementScript @sharedParam

        $resultProperty.DeviceManagementPSHScript = $deviceConfigPSHScript
    }

    # Device Configuration Shell Scripts
    if ($all -or $policyType -contains 'deviceManagementShellScript') {
        Write-Verbose "Processing Shell scripts"
        Write-Progress -Activity $progressActivity -Status "Processing Shell scripts" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $deviceConfigShellScript = Get-MgBetaDeviceManagementDeviceShellScript @sharedParam

        $resultProperty.DeviceManagementShellScript = $deviceConfigShellScript
    }

    # Security Baselines, Antivirus policies, Defender policies, Disk Encryption policies, Account Protection policies, Local User Group Membership, Firewall, Endpoint detection and response, Attack surface reduction
    if ($all -or $policyType -contains 'endpointSecurity') {
        Write-Verbose "Processing Endpoint Security policies"
        Write-Progress -Activity $progressActivity -Status "Processing Endpoint Security policies" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $endpointSecurityPolicy = @()

        #region process: Security Baselines, Antivirus policies, Defender policies, Disk Encryption policies, Account Protection policies (not 'Local User Group Membership')
        if ($basicOverview) {
            $endpointSecPol = Get-MgBetaDeviceManagementIntent @sharedParam
        } else {
            $templates = Get-MgBetaDeviceManagementIntent @sharedParam
            $endpointSecPol = @()
            foreach ($template in $templates) {
                Write-Verbose "`t- processing intent $($template.id), template $($template.templateId)"

                $settings = Get-MgBetaDeviceManagementIntentSetting -DeviceManagementIntentId $template.id | Expand-MgAdditionalProperties
                $templateDetail = Get-MgBetaDeviceManagementTemplate -DeviceManagementTemplateId $template.templateId
                $assignments = Get-MgBetaDeviceManagementIntentAssignment -DeviceManagementIntentId $template.id

                $template | Add-Member Noteproperty -Name 'platforms' -Value $templateDetail.platformType -Force # to match properties of second function region objects
                $template | Add-Member Noteproperty -Name 'type' -Value "$($templateDetail.templateType)-$($templateDetail.templateSubtype)" -Force

                $templSettings = @()
                foreach ($setting in $settings) {
                    $displayName = $setting.definitionId -replace "deviceConfiguration--", "" -replace "admx--", "" -replace "_", " "
                    if ($null -eq $setting.value) {
                        if ($setting.definitionId -eq "deviceConfiguration--windows10EndpointProtectionConfiguration_firewallRules") {
                            $v = $setting.valueJson | ConvertFrom-Json
                            foreach ($item in $v) {
                                $templSettings += [PSCustomObject]@{
                                    Name  = "FW Rule - $($item.displayName)"
                                    Value = ($item | ConvertTo-Json)
                                }
                            }
                        } else {
                            $v = ""
                            $templSettings += [PSCustomObject]@{ Name = $displayName; Value = $v }
                        }
                    } else {
                        $v = $setting.value
                        $templSettings += [PSCustomObject]@{ Name = $displayName; Value = $v }
                    }
                }

                $template | Add-Member Noteproperty -Name Settings -Value $templSettings -Force
                $template | Add-Member Noteproperty -Name 'settingCount' -Value $templSettings.count -Force # to match properties of second function region objects
                $template | Add-Member Noteproperty -Name Assignments -Value $assignments -Force
                $endpointSecPol += $template | select -Property * -ExcludeProperty templateId
            }
        }
        $endpointSecPol | ? { $_ } | % { $endpointSecurityPolicy += $_ }
        #endregion process: Security Baselines, Antivirus policies, Defender policies, Disk Encryption policies, Account Protection policies (not 'Local User Group Membership')

        #region process: Account Protection policies (just 'Local User Group Membership'), Firewall, Endpoint Detection and Response, Attack Surface Reduction
        if ($basicOverview) {
            $param = $sharedParam.clone()
            $param.select = $param.select -replace "displayname", "name"
            $param.select += ",templateReference"
            $param.expand += ",settings"
            $param.filter = "templateReference/templateFamily ne 'none'"

            $custSelectFilter = $selectFilter -replace "displayname", "name"
            $endpointSecPol2 = Get-MgBetaDeviceManagementConfigurationPolicy @param | ? { $_.templateReference.templateFamily -like "endpointSecurity*" } | select @{ n = 'id'; e = { $_.id } }, @{ n = 'displayName'; e = { $_.name } }, * -ExcludeProperty 'templateReference', 'id', 'name', 'assignments@odata.context' # id as calculated property to have it first and still be able to use *
        } else {
            $param = $sharedParam.clone()
            $param.select = ('id', 'name', 'description', 'isAssigned', 'platforms', 'lastModifiedDateTime', 'settingCount', 'roleScopeTagIds', 'templateReference')
            $param.expand += ",settings" # ,settingDefinitions"
            $param.filter = "templateReference/templateFamily ne 'none'"
            $policy = (Get-MgBetaDeviceManagementConfigurationPolicy @param)
            $param2 = @{
                expand = "settingDefinitions"
                top = 1000
            }

            $param2.expand = "settingDefinitions"
            foreach ($innerpol in $policy)
            {
                $definition = (Get-MgBetaDeviceManagementConfigurationPolicySetting @param2 -DeviceManagementConfigurationPolicyId $innerpol.id)
                $blah = @()
                foreach ($obj1 in $definition)
                {
                    foreach ($obj2 in $obj1.SettingDefinitions)
                    {
                        $blah += [pscustomobject]@{
                            Id = $obj2.Id
                            Name = $obj2.Name
                            DisplayName = $obj2.DisplayName
                            Options = [psobject]$obj2.AdditionalProperties["options"]
                        }
                        # https://github.com/PowerShell/PowerShell/issues/19185
                        #Write-Host ($obj2.AdditionalProperties.Keys)
                        #$obj2 | Add-Member options2 [psobject]$obj2.AdditionalProperties["options"]
                        #$obj2.options2 = [psobject]$obj2.AdditionalProperties["options"]
#                        $obj2.CategoryId = 
#                            [Newtonsoft.Json.JsonConvert]::SerializeObject($obj2.AdditionalProperties["options"])
#                            # (ConvertTo-Json $obj2.AdditionalProperties["options"] -Depth 20)
                        # doesn't work
                        # $obj2.CategoryId = $obj2.AdditionalProperties["options"]
                        #$obj2.CategoryId = (ConvertTo-Json $obj2.AdditionalProperties["options"] -Depth 20) | Format-Json
                        
                    }
                }
                Write-Host "HERE"
                (ConvertTo-Json $blah -Depth 20) | 
                #[Newtonsoft.Json.JsonConvert]::SerializeObject($definition) |
                Format-Json |
                Set-Content (".\\" + $innerpol.id + ".json")
                Write-Host "THERE"
            }
            # https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('d2333905-0c9b-4042-b871-c8799e321cb8')/settings?$expand=settingDefinitions&top=1000
            $endpointSecPol2 = $policy | select -Property id, @{n = 'displayName'; e = { $_.name } }, description, isAssigned, lastModifiedDateTime, roleScopeTagIds, platforms, @{n = 'type'; e = { $_.templateReference.templateFamily } }, templateReference, @{n = 'settings'; e = { $_.settings | % { [PSCustomObject]@{
                            # trying to have same settings format a.k.a. name/value as in previous function region
                            Name  = $_.settinginstance.settingDefinitionId
                            Value = $(
                                # property with setting value isn't always same, try to get the used one
                                $valuePropertyName = $_.settinginstance | Get-Member -MemberType NoteProperty | ? name -Like "*value" | select -ExpandProperty name
                                if ($valuePropertyName) {
                                    #Write-Host "Value property $valuePropertyName was found"
                                    [PSCustomObject]@{
                                        Definition = $_.settingDefinitions
                                        Value = $_.settinginstance.$valuePropertyName
                                    }
                                } else {

                                    $valuePropertyName = $_.settinginstance.AdditionalProperties.Keys -like "*value"
                                    if ($valuePropertyName)
                                    {
                                        #Write-Host "Value property wasn't found, therefore saving whole object as value"
                                        #Write-Host (ConvertTo-Json $_.settinginstance.AdditionalProperties["choiceSettingValue"] -Depth 20)
                                        #Write-Host $valuePropertyName
                                        [PSCustomObject]@{
                                            Definition = $_.settingDefinitions
                                            Value = $_.settinginstance.AdditionalProperties[$valuePropertyName]
                                        }
                                    }
                                    else {
                                    [PSCustomObject]@{
                                        Definition = $_.settingDefinitions
                                        Value = $_.settinginstance
                                    }
                                    }
                                }
                            )
                        } } }
            }, settingCount, assignments -ExcludeProperty 'assignments@odata.context', 'settings', 'settings@odata.context', 'technologies', 'name', 'templateReference'

            #endregion process: Account Protection policies (just 'Local User Group Membership'), Firewall, Endpoint Detection and Response, Attack Surface Reduction
        }
        $endpointSecPol2 | ? { $_ } | % { $endpointSecurityPolicy += $_ }

        if ($endpointSecurityPolicy) {
            $resultProperty.EndpointSecurity = $endpointSecurityPolicy
        } else {
            $resultProperty.EndpointSecurity = $null
        }
    }

    # iOS App Provisioning profiles
    if ($all -or $policyType -contains 'iosAppProvisioningProfile') {
        Write-Verbose "Processing iOS App Provisioning profiles"
        Write-Progress -Activity $progressActivity -Status "Processing iOS App Provisioning profiles" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $iosAppProvisioningProfile = Get-MgBetaDeviceAppManagementiOSLobAppProvisioningConfiguration @sharedParam

        $resultProperty.IOSAppProvisioningProfile = $iosAppProvisioningProfile
    }

    # iOS Update configurations
    if ($all -or $policyType -contains 'iosUpdateConfiguration') {
        Write-Verbose "Processing iOS Update configurations"
        Write-Progress -Activity $progressActivity -Status "Processing iOS Update configurations" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $param = $sharedParam.clone()
        $param.filter = "isof('microsoft.graph.iosUpdateConfiguration')"

        $iosUpdateConfiguration = Get-MgBetaDeviceManagementDeviceConfiguration @param

        $resultProperty.IOSUpdateConfiguration = $iosUpdateConfiguration
    }

    # macOS Update configurations
    if ($all -or $policyType -contains 'macOSSoftwareUpdateConfiguration') {
        Write-Verbose "Processing macOS Update configurations"
        Write-Progress -Activity $progressActivity -Status "Processing macOS Update configurations" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $param = $sharedParam.clone()
        $param.filter = "isof('microsoft.graph.macOSSoftwareUpdateConfiguration')"

        $macosSoftwareUpdateConfiguration = Get-MgBetaDeviceManagementDeviceConfiguration @param

        $resultProperty.MacOSSoftwareUpdateConfiguration = $macosSoftwareUpdateConfiguration
    }

    # Policy Sets
    if ($all -or $policyType -contains 'policySet') {
        Write-Verbose "Processing Policy Sets"
        Write-Progress -Activity $progressActivity -Status "Processing Policy Sets" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $policySet = @()

        $param = $sharedParam.clone()
        $param.Remove('expand')

        $policySetList = Get-MgBetaDeviceAppManagementPolicySet @param

        $param = $sharedParam.clone()
        $param.Remove('all')
        if (!$basicOverview) {
            $param.expand += ",items"
        }

        foreach ($policy in $policySetList) {
            $policyContent = Get-MgBetaDeviceAppManagementPolicySet -PolicySetId $policy.id @param

            $policySet += $policyContent
        }

        if ($policySet) {
            $resultProperty.PolicySet = $policySet
        } else {
            $resultProperty.PolicySet = $null
        }
    }

    # Remediation Scripts
    if ($all -or $policyType -contains 'remediationScript') {
        Write-Verbose "Processing Remediation (Health) scripts"
        Write-Progress -Activity $progressActivity -Status "Processing Remediation (Health) scripts" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $remediationScript = Get-MgBetaDeviceManagementDeviceHealthScript @sharedParam
        $resultProperty.RemediationScript = $remediationScript
    }

    # S mode supplemental policies
    if ($all -or $policyType -contains 'sModeSupplementalPolicy') {
        Write-Verbose "Processing S Mode Supplemental policies"
        Write-Progress -Activity $progressActivity -Status "Processing S mode supplemental policies" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $sModeSupplementalPolicy = Get-MgBetaDeviceAppManagementWdacSupplementalPolicy @sharedParam

        $resultProperty.SModeSupplementalPolicy = $sModeSupplementalPolicy
    }

    # Windows Autopilot Deployment profile
    if ($all -or $policyType -contains 'windowsAutopilotDeploymentProfile') {
        Write-Verbose "Processing Windows Autopilot Deployment profile"
        Write-Progress -Activity $progressActivity -Status "Processing Windows Autopilot Deployment profile" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $windowsAutopilotDeploymentProfile = Get-MgBetaDeviceManagementWindowsAutopilotDeploymentProfile @sharedParam

        $resultProperty.WindowsAutopilotDeploymentProfile = $windowsAutopilotDeploymentProfile
    }

    # Windows Feature Update profiles
    if ($all -or $policyType -contains 'windowsFeatureUpdateProfile') {
        Write-Verbose "Processing Windows Feature Update profiles"
        Write-Progress -Activity $progressActivity -Status "Processing Windows Feature Update profiles" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $windowsFeatureUpdateProfile = Get-MgBetaDeviceManagementWindowsFeatureUpdateProfile @sharedParam

        $resultProperty.WindowsFeatureUpdateProfile = $windowsFeatureUpdateProfile
    }

    # Windows Quality Update profiles
    if ($all -or $policyType -contains 'windowsQualityUpdateProfile') {
        Write-Verbose "Processing Windows Quality Update profiles"
        Write-Progress -Activity $progressActivity -Status "Processing Windows Quality Update profiles" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $windowsQualityUpdateProfile = Get-MgBetaDeviceManagementWindowsQualityUpdateProfile @sharedParam

        $resultProperty.WindowsQualityUpdateProfile = $windowsQualityUpdateProfile
    }

    # Update rings for Windows 10 and later is part of configurationPolicy (#microsoft.graph.windowsUpdateForBusinessConfiguration)
    if ($all -or $policyType -contains 'windowsUpdateRing') {
        Write-Verbose "Processing Windows Update rings"
        Write-Progress -Activity $progressActivity -Status "Processing Windows Update rings" -PercentComplete (($i++ / $policyTypeCount) * 100)

        $param = $sharedParam.clone()
        $param.filter = "isof('microsoft.graph.windowsUpdateForBusinessConfiguration')"

        $windowsUpdateRing = Get-MgBetaDeviceManagementDeviceConfiguration @param

        $resultProperty.WindowsUpdateRing = $windowsUpdateRing
    }
    #endregion get Intune policies

    # output result
    $result = New-Object -TypeName PSObject -Property $resultProperty

    if ($flatOutput) {
        # extract main object properties (policy types) and output the data as array of policies instead of one big object
        $result | Get-Member -MemberType NoteProperty | select -ExpandProperty name | % {
            $polType = $_

            $result.$polType | ? { $_ } | % {
                # add parent section as property
                $_ | Add-Member -MemberType NoteProperty -Name 'PolicyType' -Value $polType
                # output modified child object
                $_
            }
        }
    } else {
        $result
    }
}

@{
    RootModule        = 'TestModule.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '116b225c-d9b0-4928-813f-5d3f97d8b4ff'
    Author            = '@AndrewZtrhgf'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description       = 'Various Azure related functions. Some of them are explained at https://doitpsway.com/series/azure.
Some of the interesting functions:
- Add-AzureAppUserConsent - grant permission consent on behalf of another user
- Get-AzureAccountOccurrence - get all occurrences of specified account in your Azure environment
- Get-AzureAppVerificationStatus - get Azure app publisher verification status
- Get-AzureAppConsentRequest - get all application admin consent requests
- Get-AzureDevOpsOrganizationOverview - list of all DevOps organizations
- Grant-AzureServicePrincipalPermission - grant application/delegated permission(s) for selected resource to selected account
- New-AzureAutomationModule - import/update module with dependencies to Azure Automation Account
- Remove-AzureAccountOccurrence - remove specified account from various Azure environment sections and optionally replace it with other user and inform him. Should be used with Get-AzureAccountOccurrence.
- Remove-AzureAppUserConsent - remove user consent
- Revoke-AzureServicePrincipalPermission - revoke granted application/delegated permissions from selected account
- Set-AzureAppCertificate - create (or replace existing) authentication certificate for selected Application
- ...
'
    PowerShellVersion = '5.1'
    RequiredModules   = @('Az.Accounts','Az.Automation','Az.Resources','ExchangeOnlineManagement','Microsoft.Graph.Applications','Microsoft.Graph.Authentication','Microsoft.Graph.Beta.Applications','Microsoft.Graph.Beta.Users','Microsoft.Graph.DeviceManagement.Enrollment','Microsoft.Graph.DirectoryObjects','Microsoft.Graph.Identity.Governance','Microsoft.Graph.Groups','Microsoft.Graph.Beta.Reports','Microsoft.Graph.Identity.DirectoryManagement','Microsoft.Graph.Identity.SignIns','Microsoft.Graph.Reports','Microsoft.Graph.Beta.Identity.SignIns','Microsoft.Graph.Users','Microsoft.Graph.Users.Actions','MSAL.PS','MSGraphStuff','PnP.PowerShell')
    FunctionsToExport = '*'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
    PrivateData       = @{
        PSData = @{
            Tags       = @('Azure', 'PowerShell', 'Monitoring', 'Audit', 'Security', 'Graph', 'Runbook')
            ProjectUri = 'https://github.com/ztrhgf/useful_powershell_modules'
            ReleaseNotes = '
            * 1.0.0
                * Initial release. Some functions are migrated from now deprecated AzureADStuff module, some are completely new.'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
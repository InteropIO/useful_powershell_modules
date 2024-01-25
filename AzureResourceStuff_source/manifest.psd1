@{
    RootModule        = 'TestModule.psm1'
    ModuleVersion     = '1.0.1'
    GUID              = '6f9132bb-ec13-43d9-86ea-2bba4017e71e'
    Author            = '@AndrewZtrhgf'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description       = 'Various Azure related functions focused on resources. More details at https://doitpsway.com/series/azure.
Some of the interesting functions:
- Get-AzureResource - return resources for all or just selected Azure subscription(s)
- New-AzureAutomationModule - import new (or update existing) Azure Automation PSH module (including its dependencies)
- ...
'
    PowerShellVersion = '5.1'
    RequiredModules   = @('Az.Accounts', 'Az.Automation', 'Az.Resources')
    FunctionsToExport = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('Azure', 'PowerShell', 'Monitoring', 'Audit', 'Security', 'Graph', 'Runbook')
            ProjectUri   = 'https://github.com/ztrhgf/useful_powershell_modules'
            ReleaseNotes = '
            * 1.0.0
                * Initial release. Some functions are migrated from now deprecated AzureADStuff module, some are completely new.
            * 1.0.1
                * EDIT
                    * New-AzureAutomationModule - added support for prerelease modules
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
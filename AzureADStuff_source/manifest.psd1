@{
    RootModule        = 'TestModule.psm1'
    ModuleVersion     = '1.1.2'
    GUID              = '1f9e4f50-2cac-411b-80f8-16003b8a5542'
    Author            = '@AndrewZtrhgf'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description       = 'Various Azure related functions. Some of them are explained at https://doitpsway.com/series/azure.

This module has been DEPRECATED, because it is based on AzureAD module.
Use AzureStuff module instead (built upon Microsoft.Graph.* and AZ modules instead).
'
    PowerShellVersion = '5.1'
    RequiredModules   = @('MSGraphStuff', 'AzureAD', 'Az.Accounts', 'Az.Resources', 'MSAL.PS', 'PnP.PowerShell', 'Microsoft.Graph.Authentication', 'Microsoft.Graph.Applications', 'Microsoft.Graph.Users', 'Microsoft.Graph.Identity.SignIns', 'Microsoft.Graph.Identity.DirectoryManagement')
    FunctionsToExport = '*'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
    PrivateData       = @{
        PSData = @{
            Tags       = @('Azure', 'PowerShell', 'Monitoring', 'Audit', 'Security')
            ProjectUri = 'https://github.com/ztrhgf/useful_powershell_modules'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
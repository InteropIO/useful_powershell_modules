using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

class Program
{
    static void Main(string[] args)
    {
        var policies = ReadPolicies();

        foreach (var policy in policies.EndpointSecurity)
        {
            Console.WriteLine(policy.Id);
            Console.WriteLine(policy.DisplayName);
            Console.WriteLine(policy.IsAssigned);
            Console.WriteLine(policy.Assignments.Length);

            var settingDefinitions = ReadSettingDefinitions(policy.Id);
            
            for (var setting in policy.settings)
            {
                WriteSetting(WriteSettingLine, setting, true);
                
            }
        }
    }
    
    static void WriteSettingLine(object settingDefinitions, object setting, bool topLevel)
    {
        // by name or settingDefinitionId
        var settingDefinition = FindSettingDefinition(settingDefinitions, setting);
        
        Console.WriteLine(setting.Name);
        Console.WriteLine(settingDefinition.DisplayName);
        var valueObj = topLevel ? setting.Value.Value[0] : setting.choiceSettingValue; // simpleSettingValue, simpleSettingCollectionValue, get using reflection
        var topValue = valueObj.value;
        Console.WriteLine(topValue);
        var valueDefinition = FindValueDefinition(settingDefinition, topValue);
        Console.WriteLine(valueDefinition.displayName);
        foreach (var child of valueObj.children)
        {
            WriteSettingLine(settingDefinitions, child, false);
        }
    }
}

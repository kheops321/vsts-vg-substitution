[CmdletBinding()]
param()

# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib
Trace-VstsEnteringInvocation $MyInvocation
try {

	$env = Get-VstsInput -Name environment -Require
	$env = $env.ToUpper()
    Write-Host "Setting target environment to [$env]."
    			
	$searchPattern = Get-VstsInput -Name searchPattern -Require
    Write-Host "Setting search pattern to [$searchPattern]."
				
	$searchPattern =  [string]::Format($searchPattern, $env)				
	Write-Host "Consolidated search pattern : [$searchPattern]"
	
	$allVariables = Get-VstsTaskVariableInfo
	
	Write-Host "ALL VARIABLES : " $allVariables
	
	$targetVariables = $allVariables | Where { $_.Name -match "$searchPattern*"}
	Write-Host "Found ["$targetVariables.Count"] variable to substitute:"
	
	if($targetVariables.Count -gt 0)
	{
		Write-Host "Processing substitution..."
		
		foreach ($variableInfo in $targetVariables)
		{
		
			$cleanedName = $variableInfo.Name.Replace($searchPattern, "")
			
			$alreadySubstituedVariableLocally = $allVariables | Where { $_.Name -eq $cleanedName}
						
			if($alreadySubstituedVariableLocally.Count -ne 0)
			{
				Write-Host $variableInfo.Name " >> already defined on release definition level, substitution will be skipped"
			}
			else
			{			
				$variableObject = Get-VstsTaskVariable -Name $variableInfo.Name
				
				if($variableInfo.Secret -eq $true)
				{				
					Set-VstsTaskVariable -Name $cleanedName -Value $variableObject -Secret
				}
				else
				{
					Set-VstsTaskVariable -Name $cleanedName -Value $variableObject
				}
			
				Write-Host $variableInfo.Name" >> [$cleanedName]"
			}
		}
	}
	
	Write-Host "Substitution complete!"
	
    # Output the message to the log.
    Write-Host (Get-VstsInput -Name msg)
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}

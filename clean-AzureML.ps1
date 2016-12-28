Unblock-File .\AzureMLPS.dll
Import-Module .\AzureMLPS.dll

# Returns the metadata of a Workspace
$ws = Get-AmlWorkspace
# Display the Workspace Name
$ws.FriendlyName

# Delete Web service endpoints, then web services, then experiments
Get-AmlWebServiceEndpoint
$webSvc = Get-AmlWebService
$webSvc.Length
$webSvc[0]
for ($i=0;$i -lt $webSvc.Length; $i++) {
	$webSvc[$i].Id
    $endpoints = Get-AmlWebServiceEndpoint -WebServiceId $webSvc[$i].Id
    for ($j=0;$j -lt $endpoints.Length; $j++) {
	    $endpoints[$j].Name
        Remove-AmlWebServiceEndpoint -WebServiceId $webSvc[$i].Id -EndpointName $endpoints[$j].Name
    
    }
    Remove-AmlWebService -WebServiceId $webSvc[$i].Id
}

# Get all Experiments in the Workspace
$exps = Get-AmlExperiment
# Display all Experiments in a table format
$exps | Format-Table
for ($i=0;$i -lt $exps.Length; $i++) {
    # delete experiments
    Remove-AmlExperiment -ExperimentId $exps[$i].ExperimentId
}

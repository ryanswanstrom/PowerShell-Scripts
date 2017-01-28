#### Manual Config: These top lines need to be configured manually ######

# authenticate
Login-AzureRmAccount

# list of available locations
$resources = Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute
$resources.ResourceTypes.Where{($_.ResourceTypeName -eq 'virtualMachines')}.Locations

# Specify the subscription
Get-AzureRmSubscription 

### End of Manual Config ####

# set variables for name and number of VMs, location
$subscriptionName = ""  # this will need to be specified after running the above steps
$location = "Central US" # change this based upon the above steps if you like
$instructorName = ""  #use lowercase only, this could also represent the training engagement, i.e. chicago
$vmUser = "someuser"
$vmPassword = "Very-Strong45" # change this


$numOfVMs = 3

$randnum = get-random -minimum 1 -maximum 10000

Set-AzureRmContext -SubscriptionName $subscriptionName 

# create a resource group
$resourceGroup = ( $($instructorName) + "-RG-" + $($randnum) )
$resourceGroup
New-AzureRmResourceGroup -Name $resourceGroup -Location $location




# create storage account
$myStorageAccountName = ( $($instructorName) + $($randnum) + "stor")
while( !(Get-AzureRmStorageAccountNameAvailability $myStorageAccountName).NameAvailable ) {
    $myStorageAccountName = ($($myStorageAccountName) + (get-random -minimum 1 -maximum 10) )
}
$myStorageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $myStorageAccountName -Type "Standard_LRS" -Location $location

# loop to create VMs
for ($i = 0; $i -lt $numOfVMs; $i++) {
    "creating VM $i"
    $mySubnet = New-AzureRmVirtualNetworkSubnetConfig -Name ($($instructorName) + "Subnet" + $($i) ) -AddressPrefix 10.0.0.0/24
    $myVnet = New-AzureRmVirtualNetwork -Name ($($instructorName) + "Vnet" + $($i) ) -ResourceGroupName $resourceGroup `
        -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $mySubnet
    $myPublicIp = New-AzureRmPublicIpAddress -Name ($($instructorName) + "PublicIp" + $($i) ) -ResourceGroupName $resourceGroup `
        -Location $location -AllocationMethod Dynamic
    $myNIC = New-AzureRmNetworkInterface -Name ($($instructorName) + "NIC" + $($i) ) -ResourceGroupName $resourceGroup `
        -Location $location -SubnetId $myVnet.Subnets[0].Id -PublicIpAddressId $myPublicIp.Id

    
    $vmSecurePassword = ConvertTo-SecureString $vmPassword -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($vmUser, $vmSecurePassword); 

    $vmname = ( $($instructorName) + $($i) )
    $myVm = New-AzureRmVMConfig -VMName $vmname -VMSize "Standard_DS3_v2" 
    $myVM = Set-AzureRmVMOperatingSystem -VM $myVM -Windows -ComputerName $vmname -Credential $cred `
        -ProvisionVMAgent -EnableAutoUpdate
    $myVM = Set-AzureRmVMSourceImage -VM $myVM -PublisherName "microsoft-ads" `
        -Offer "standard-data-science-vm" -Skus "standard-data-science-vm" -Version "latest"
    $myVM = Add-AzureRmVMNetworkInterface -VM $myVM -Id $myNIC.Id
    $osDisk = ("disk" + $($vmname))
    $blobPath = ("vhds/" + $($osDisk) + ".vhd")
    $osDiskUri = $myStorageAccount.PrimaryEndpoints.Blob.ToString() + $blobPath
    $myVM = Set-AzureRmVMOSDisk -VM $myVM -Name $osDisk -VhdUri $osDiskUri -CreateOption fromImage
    Set-AzureRmVMPlan -VM $myVM -Publisher "microsoft-ads" -Product "standard-data-science-vm" -Name "standard-data-science-vm"
    New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $myVM
}
    
Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup | Select IpAddress,  @{N="Username";E={$vmUser}},  @{N="Password";E={$vmPassword}}




#### Manual Config: These top lines need to be configured manually ######

# authenticate
Login-AzureRmAccount

# list of available locations
$resources = Get-AzureRmResourceProvider -ProviderNamespace Microsoft.DataFactory
$resources.ResourceTypes.Where{($_.ResourceTypeName -eq 'dataFactories')}.Locations

# Specify the subscription
Get-AzureRmSubscription 

### End of Manual Config ####

# set variables for name and location
$subscriptionName = ""  # this will need to be specified after running the above steps
$location = "West US" # change this based upon the above steps if you like
$instructorName = "ryan"  # this could also represent the training engagement, i.e. chicago

$randnum = get-random -minimum 1 -maximum 10000
$currentFolder = (split-path -parent $psISE.CurrentFile.Fullpath)
$ContainerName = "adfgetstarted"
$scriptFolder = "script"
$inputFolder = "inputdata"
$outputFolder = "partitioneddata"
$dfNAme = ("ADFbasicTutorial-" + $($randnum))

Set-AzureRmContext -SubscriptionName $subscriptionName 

# create a resource group
$resourceGroup = ( $($instructorName) + "-ADF_RG-" + $($randnum) )
New-AzureRmResourceGroup -Name $resourceGroup -Location $location
"Resource Group created: $resourceGroup"


# create storage account and upload file
$myStorageAccountName = ( $($instructorName) + $($randnum) + "stor")
while( !(Get-AzureRmStorageAccountNameAvailability $myStorageAccountName).NameAvailable ) {
    $myStorageAccountName = ($($myStorageAccountName) + (get-random -minimum 1 -maximum 10) )
}
$myStorageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $myStorageAccountName -Type "Standard_LRS" -Location $location
"Storage Account created: $myStorageAccountName"

### Obtain the Storage Account authentication keys using Azure Resource Manager (ARM)
$Keys = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroup -Name $myStorageAccountName;

### Use the Azure.Storage module to create a Storage Authentication Context
$StorageContext = New-AzureStorageContext -StorageAccountName $myStorageAccountName -StorageAccountKey $Keys[0].Value;
### Create a Blob Container in the Storage Account
New-AzureStorageContainer -Context $StorageContext -Name $ContainerName;
### Upload a input.log to the Microsoft Azure Storage Blob Container 
$UploadFile = @{
    Context = $StorageContext;
    Container = $ContainerName;
    File = ($currentFolder +  "\ADFGetStarted\input.log");
    }
Set-AzureStorageBlobContent @UploadFile -Blob ($($inputFolder) + "\input.log");
$UploadFile = @{
    Context = $StorageContext;
    Container = $ContainerName;
    File = ($currentFolder +  "\ADFGetStarted\partitionweblogs.hql");
    }
Set-AzureStorageBlobContent @UploadFile -Blob ($($scriptFolder) + "\partitionweblogs.hql");


# Create the Data Factory
$df = New-AzureRmDataFactory -ResourceGroupName $resourceGroup -Name $dfName –Location $location
"Data Factory $dfName created in $resourceGroup"

# Create the Linked Services
# update the doc with storage account name and key
$a = Get-Content ($currentFolder + "\ADFGetStarted\AzureStorageLinkedService.txt") -raw | ConvertFrom-Json
$a.properties.typeProperties.connectionString = ("DefaultEndpointsProtocol=https;AccountName=" + $($myStorageAccountName) + ";AccountKey=" + $($Keys[0].Value))
$a | ConvertTo-Json  | set-content ($currentFolder + "\ADFGetStarted\AzureStorageLinkedService.txt")
New-AzureRmDataFactoryLinkedService $df -File ($currentFolder + "\ADFGetStarted\AzureStorageLinkedService.txt")
New-AzureRmDataFactoryLinkedService $df -File ($currentFolder + "\ADFGetStarted\HDInsightOnDemandLinkedService.txt")


# Create the DataSets
New-AzureRmDataFactoryDataset $df -File ($currentFolder + "\ADFGetStarted\AzureBlobInput.txt")
New-AzureRmDataFactoryDataset $df -File ($currentFolder + "\ADFGetStarted\AzureBlobOutput.txt")

# Create the Pipeline
(Get-Content ($currentFolder + "\ADFGetStarted\MyFirstPipeline.txt")).replace('<storageaccountname>', $myStorageAccountName) | Set-Content ($currentFolder + "\ADFGetStarted\MyFirstPipeline2.txt")
New-AzureRmDataFactoryPipeline $df -File ($currentFolder + "\ADFGetStarted\MyFirstPipeline.txt")


# Monitor the Pipleline
Get-AzureRmDataFactorySlice $df -DatasetName AzureBlobOutput -StartDateTime 2016-04-01
Get-AzureRmDataFactoryRun $df -DatasetName AzureBlobOutput -StartDateTime 2016-04-01


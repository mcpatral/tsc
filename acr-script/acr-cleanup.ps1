[CmdletBinding()]
Param(
    # Define ACR Name
    [Parameter (Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $AzureRegistryName
)

$credential = New-Object System.Management.Automation.PSCredential ("${env:servicePrincipalId}", (ConvertTo-SecureString ${env:servicePrincipalKey} -AsPlainText -Force))
Connect-AzAccount -Credential $Credential -Tenant ${env:tenantId} -ServicePrincipal

$REPOS = Get-AzContainerRegistryRepository -RegistryName $AzureRegistryName
foreach ($REPO in $REPOS) {
    $Attributes = (Get-AzContainerRegistryManifest -RegistryName $AzureRegistryName -RepositoryName $REPO).ManifestsAttributes
    Write-Host $Attributes.Count
    foreach ($ITEM in $Attributes){
        Write-Host "Listing tags for manifest"
        if ("" -eq $ITEM.Tags){
            Write-Host "No tags"
            $tmpDate = $ITEM.LastUpdateTime 
            $date = $tmpDate.split("T")[0]
            $LastModified = [System.DateTime]::ParseExact($date,'yyyy-MM-dd',$null) 
            Write-Host $LastModified
            $CurrentDate = Get-Date -Format "yyyy-MM-dd"
            if ($LastModified.addDays(2) -lt $CurrentDate) {
                Write-Host "Older than 2 days, removing"
                Remove-AzContainerRegistryManifest -RegistryName $AzureRegistryName -RepositoryName $REPO -Manifest $ITEM.digest
            } else {
                Write-Host "Still fresh"
            }
        } else {
            Write-Host $ITEM.Tags
        }        
    }   
}
[CmdletBinding()]
param(
[Parameter(Mandatory = $True)]
[string]$webappname,
[Parameter(Mandatory = $True)]
[string]$location,
[Parameter(Mandatory = $True)]
[string]$ResourceGroupName
)


Trace-VstsEnteringInvocation $MyInvocation
try {
    # Get inputs.
# Get publishing profile for the web app
$xml = [xml](Get-AzureRmWebAppPublishingProfile -Name $webappname `
-ResourceGroupName $ResourceGroupName `
-OutputFile null)

# Extracts connection information from publishing profile
$username = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userName").value
$password = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userPWD").value
$url = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@publishUrl").value

Write-Output "$username"
Write-Output "$password"
Write-Output "$url"

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
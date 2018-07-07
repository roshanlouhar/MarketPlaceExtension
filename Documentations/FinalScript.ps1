[CmdletBinding()]
param()

# Get inputs for the task
$appdirectory = Get-VstsInput -Name appdirectory -Require
$webappname = Get-VstsInput -Name webappname -Require
$location = Get-VstsInput -Name location -Require
$ResourceGroupName = Get-VstsInput -Name ResourceGroupName -Require
$PlainPassword= Get-VstsInput -Name PlainPassword -Require
$PlainUsername=Get-VstsInput -Name PlainUsername -Require
$TenentId= Get-VstsInput -Name TenentId -Require
$SubscriptionId = Get-VstsInput -Name SubscriptionId -Require
$Environment= Get-VstsInput -Name Environment -Require

# printing variable here to check values
Write-output "$appdirectory"
Write-output "$webappname"
Write-output "$location"
Write-output "$ResourceGroupName"
Write-output "$PlainPassword"
Write-output "$PlainUsername"
Write-output "$TenentId"
Write-output "$SubscriptionId"
Write-output "$Environment"

#$appdirectory = "D:\WorkCode\GoogleGeoAppServiceDemo"
#$webappname = "CustomTaskTest"
#$location = "East US"
#$ResourceGroupName = "GroupA"
#$PlainPassword="Tupa89221"
#$PlainUsername="levan@eyugi.com"
#$TenentId="684745db-d373-4ec0-9c93-573a6c316669"
#$SubscriptionId ="c0bf7a1e-93d9-42ee-8357-1063f170b20d"
#$Environment="AzureCloud"


# creating PS credential and securing over here.
$SecurePassword = ConvertTo-SecureString $PlainPassword -AsPlainText -Force
$MyCredentials = New-Object System.Management.Automation.PSCredential ($PlainUsername, $SecurePassword)

Write-Output $SecurePassword.ToString()
Write-Output $MyCredentials.ToString()

Trace-VstsEnteringInvocation $MyInvocation
try {
    #connect azure portal account with subscriptions
    Connect-AzureRmAccount -Credential $MyCredentials -Environment $Environment -Subscription $SubscriptionId -TenantId $TenentId

	#check credential after encrpting
    Write-Output $SecurePassword.ToString()
    Write-Output $MyCredentials.ToString()

    # Get publishing profile for the web app
    $xml = [xml](Get-AzureRmWebAppPublishingProfile -Name $webappname -ResourceGroupName $ResourceGroupName -OutputFile null)

	#print XML file here 
    Write-Output "$xml".ToString()

    # Extracts connection information from publishing profile
    $username = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userName").value
    $password = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userPWD").value
    $url = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@publishUrl").value

	# check username and password is retrieved here or not from publish profiles.
    Write-Output $username
    Write-Output $password
    Write-Output $url

	# start uploadig files from directory here.
    Set-Location $appdirectory
    $webclient = New-Object -TypeName System.Net.WebClient
    $webclient.Credentials = New-Object System.Net.NetworkCredential($username,$password)
    $files = Get-ChildItem -Path $appdirectory -Recurse | Where-Object{!($_.PSIsContainer)}
    foreach ($file in $files)
    {
        $relativepath = (Resolve-Path -Path $file.FullName -Relative).Replace(".\", "").Replace('\', '/')
        $uri = New-Object System.Uri("$url/$relativepath")
        "Uploading to " + $uri.AbsoluteUri
        $webclient.UploadFile($uri, $file.FullName)
    } 
} 
finally {
	# closing connecting and tracnf here.
    $webclient.Dispose()
    Trace-VstsLeavingInvocation $MyInvocation	
}
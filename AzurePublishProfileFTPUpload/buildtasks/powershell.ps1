[CmdletBinding()]
param()

# Get inputs for the task
$appdirectory = (Get-VstsInput -Name appdirectory -Require)
$webappname = Get-VstsInput -Name webappname -Require
$location = Get-VstsInput -Name location -Require
$ResourceGroupName = Get-VstsInput -Name ResourceGroupName -Require
$PlainPassword= Get-VstsInput -Name PlainPassword -Require
$PlainUsername=Get-VstsInput -Name PlainUsername -Require
$TenentId= Get-VstsInput -Name TenentId -Require
$Subscription = Get-VstsInput -Name SubscriptionId -Require
$Environment= Get-VstsInput -Name Environment -Require

#printing variable here to check values
Write-output "$appdirectory"
Write-output "$webappname"
Write-output "$location"
Write-output "$ResourceGroupName"
Write-output "$PlainPassword"
Write-output "$PlainUsername"
Write-output "$TenentId"
Write-output "$SubscriptionId"
Write-output "$Environment"

# creating PS credential and securing over here.
$SecurePassword = ConvertTo-SecureString $PlainPassword -AsPlainText -Force
$MyCredentials = New-Object System.Management.Automation.PSCredential ($PlainUsername, $SecurePassword)

#check credential after encrpting
Write-Output $SecurePassword.ToString()
Write-Output $MyCredentials.ToString()

try {

    #connect azure portal account with subscriptions
    Login-AzureRmAccount -Credential $MyCredentials -EnvironmentName $Environment -SubscriptionId $Subscription -TenantId $TenentId
    Write-Output "Successfully connected to azure account..."
   

    # Get publishing profile for the web app
    $xml =[xml] (Get-AzureRmWebAppPublishingProfile -Name $webappname -ResourceGroupName $ResourceGroupName -OutputFile null)
    Write-Output "Successfully fetched XML publish profile..."
	#print XML file here     

    # Extracts connection information from publishing profile
    $FTPUser = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userName").value
    $FTPPass = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userPWD").value
    $FTPHost = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@publishUrl").value
    Write-Output "Successfully Extracting FTP information from XML..."

	# check username and password is retrieved here or not from publish profiles.
    Write-Output $FTPUser
    Write-Output $FTPPass
    Write-Output $FTPHost
	
	
	$webclient = New-Object System.Net.WebClient 
	$webclient.Credentials = New-Object System.Net.NetworkCredential($FTPUser,$FTPPass)  
	 
	$SrcEntries = Get-ChildItem $appdirectory -Recurse
	$Srcfolders = $SrcEntries | Where-Object{$_.PSIsContainer}
	$SrcFiles = $SrcEntries | Where-Object{!$_.PSIsContainer}

	 
	Write-Output  "Create FTP Directory/SubDirectory If Needed - Start"
	foreach($folder in $Srcfolders)
	{    
		$SrcFolderPath = $appdirectory  -replace "\\","\\" -replace "\:","\:"   
		$DesFolder = $folder.Fullname -replace $SrcFolderPath,$FTPHost
		$DesFolder = $DesFolder -replace "\\", "/"
		Write-Output  "Write-Output $DesFolder"
	 
		try
			{
				$makeDirectory = [System.Net.WebRequest]::Create($DesFolder);
				$makeDirectory.Credentials = New-Object System.Net.NetworkCredential($FTPUser,$FTPPass);
				$makeDirectory.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory;
				$makeDirectory.GetResponse();
				Write-Output  "folder created successfully"
			}
		catch [Net.WebException]
			{
				try {
					Write-Output "if there was an error returned, check if folder already existed on server"
					$checkDirectory = [System.Net.WebRequest]::Create($DesFolder);
					$checkDirectory.Credentials = New-Object System.Net.NetworkCredential($FTPUser,$FTPPass);
					$checkDirectory.Method = [System.Net.WebRequestMethods+FTP]::PrintWorkingDirectory;
					$response = $checkDirectory.GetResponse();
					Write-Output  "folder already exists!"
				}
				catch [Net.WebException] {
					#if the folder didn't exist
				}
			}
	}
	Write-Output "Create FTP Directory/SubDirectory If Needed - Stop"

	Write-Output "Upload Files - Start"
	foreach($entry in $SrcFiles)
	{
		$SrcFullname = $entry.fullname
		$SrcName = $entry.Name
		$SrcFilePath = $appdirectory -replace "\\","\\" -replace "\:","\:"
		$DesFile = $SrcFullname -replace $SrcFilePath,$FTPHost
		$DesFile = $DesFile -replace "\\", "/"
		# Write-Output $DesFile
	 
		$uri = New-Object System.Uri($DesFile) 
		$webclient.UploadFile($uri, $SrcFullname)
	}
	Write-Output "All files uploaded successfully"	
    $webclient.Dispose()	
} 
catch{
	$err = Write-Host $Error.exception.message continue
}
finally {
	# closing connecting and tracnf here.
    #Disconnect-AzureRmAccount -Username $PlainUsername
    #$webclient.Dispose()	
}
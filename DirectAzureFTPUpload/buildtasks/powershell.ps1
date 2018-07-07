[CmdletBinding()]
param()

# Get inputs for the task
$appdirectory = (Get-VstsInput -Name SourcePath -Require)
$FTPUser = Get-VstsInput -Name FTPUserName -Require
$FTPPass = Get-VstsInput -Name FTPPassword -Require
$FTPHost = Get-VstsInput -Name FTPHost -Require

#printing variable here to check values
Write-output "$PlainUsername"
Write-output "$TenentId"
Write-output "$SubscriptionId"
Write-output "$Environment"

try {
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
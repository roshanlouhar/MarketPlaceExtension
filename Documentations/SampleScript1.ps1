$webappname="CustomTaskTest" ##"mywebapp$(Get-Random)"
$location="East US"
$ResourceGroupName="GroupA"

# Get publishing profile for the web app
$xml = [xml](Get-AzureRmWebAppPublishingProfile -Name $webappname `
-ResourceGroupName $ResourceGroupName `
-OutputFile null)

# Extracts connection information from publishing profile
$username = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userName").value
$password = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userPWD").value
$url = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@publishUrl").value

#Write-Output "$username"
#Write-Output "$password"
#Write-Output "$url"

# ftp test 5
# create the FtpWebRequest and configure it
$ftp = [System.Net.FtpWebRequest]::Create("$url//file.png")
$ftp = [System.Net.FtpWebRequest]$ftp
$ftp.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$ftp.Credentials = new-object System.Net.NetworkCredential("$username","$password")
$ftp.UseBinary = $true
$ftp.UsePassive = $true

# read in the file to upload as a byte array
$content = [System.IO.File]::ReadAllBytes("C:\tmp\file.png")
$ftp.ContentLength = $content.Length

# get the request stream, and write the bytes into it
$rs = $ftp.GetRequestStream()
$rs.Write($content, 0, $content.Length)

# Cleanup connection
$rs.Close()
$rs.Dispose()
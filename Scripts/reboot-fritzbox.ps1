﻿<#
.SYNOPSIS
	reboot-fritzbox.ps1 [<username>] [<password>]
.DESCRIPTION
	Reboots the FRITZ!Box device
.EXAMPLE
	PS> .\reboot-fritzbox.ps1 
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author:  Markus Fleschutz
	License: CC0
#>

param([string]$USERNAME = "", [string]$PASSWORD = "")
if ($USERNAME -eq "") {
	$USERNAME = read-host "Enter username for FRITZ!Box"
}
if ($PASSWORD -eq "") {
	$PASSWORD = read-host "Enter password for FRITZ!Box"
}
$FB_FQDN = "fritz.box"

if ($PSVersionTable.PSVersion.Major -lt 3) {
	write-host "ERROR: Minimum Powershell Version 3.0 is required!" -F Yellow
	return
}

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12'

[xml]$serviceinfo = Invoke-RestMethod -Method GET -Uri "http://$($FB_FQDN):49000/tr64desc.xml"
[System.Xml.XmlNamespaceManager]$ns = new-Object System.Xml.XmlNamespaceManager $serviceinfo.NameTable
$ns.AddNamespace("ns",$serviceinfo.DocumentElement.NamespaceURI)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }


function Execute-SOAPRequest { param([Xml]$SOAPRequest, [string]$soapactionheader, [String]$URL)
    try {
        $wr = [System.Net.WebRequest]::Create($URL)
        $wr.Headers.Add('SOAPAction',$soapactionheader)
        $wr.ContentType = 'text/xml; charset="utf-8"'
        $wr.Accept      = 'text/xml'
        $wr.Method      = 'POST'
        $wr.PreAuthenticate = $true
        $wr.Credentials = [System.Net.NetworkCredential]::new($USERNAME,$PASSWORD)

        $requestStream = $wr.GetRequestStream()
        $SOAPRequest.Save($requestStream)
        $requestStream.Close()
        [System.Net.HttpWebResponse]$wresp = $wr.GetResponse()
        $responseStream = $wresp.GetResponseStream()
        $responseXML = [Xml]([System.IO.StreamReader]($responseStream)).ReadToEnd()
        $responseStream.Close()
        return $responseXML
    } catch {
        if ($_.Exception.InnerException.Response){
            throw ([System.IO.StreamReader]($_.Exception.InnerException.Response.GetResponseStream())).ReadToEnd()
        } else {
            throw $_.Exception.InnerException
        }
    }
}

function New-Request {
    param(
        [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$urn,
        [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$action,
        [hashtable]$parameter = @{},
        $Protocol = 'https'
    )
        # SOAP Request Body Template
        [xml]$request = @"
<?xml version="1.0"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <s:Body>
    </s:Body>
</s:Envelope>
"@
    $service = $serviceinfo.SelectNodes('//ns:service',$ns) | ?{$_.ServiceType -eq $URN}
    if(!$service){throw "URN does not exist."}
    $actiontag = $request.CreateElement('u',$action,$service.serviceType)
    $parameter.GetEnumerator() | %{
          $el = $request.CreateElement($_.Key)
          $el.InnerText = $_.Value
          $actiontag.AppendChild($el)| out-null
    }
    $request.GetElementsByTagName('s:Body')[0].AppendChild($actiontag) | out-null
    $resp = Execute-SOAPRequest $request "$($service.serviceType)#$($action)" "$($Protocol)://$($FB_FQDN):$(@{$true=$script:secport;$false=49000}[($Protocol -eq 'https')])$($service.controlURL)"
    return $resp
}

$script:secport = (New-Request -urn "urn:dslforum-org:service:DeviceInfo:1" -action 'GetSecurityPort' -proto 'http').Envelope.Body.GetSecurityPortResponse.NewSecurityPort

function Reboot-FritzBox {
    $resp = New-Request -urn 'urn:dslforum-org:service:DeviceConfig:1' -action 'Reboot'
    return $resp.Envelope.Body.InnerText
}

$Result = Reboot-FritzBox
echo $Result
exit 0

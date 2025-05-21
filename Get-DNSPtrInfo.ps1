<#
.SYNOPSIS
    Retrieves DNS A/AAAA records for the specified hostnames and performs reverse (PTR) lookups.

.DESCRIPTION
    The Get-DnsPtrInfo function accepts one or more hostnames, resolves each to its IPv4 and IPv6
    addresses, then attempts to resolve each IP back to its PTR (reverse DNS) record. The final output
    is a JSON-formatted array of objects with the following properties:
      • Name       – the original hostname
      • IPAddress  – the resolved IP address
      • PTRName    – the reverse-DNS host name (if found)

.PARAMETER Name
    One or more hostnames (strings) to resolve.

.EXAMPLE
    PS> Get-DnsPtrInfo -Name "example.com"
    [
      {
        "Name": "example.com",
        "IPAddress": "93.184.216.34",
        "PTRName": "example.com"
      }
    ]

.EXAMPLE
    PS> "google.com","microsoft.com" | Get-DnsPtrInfo
    [
      { "Name":"google.com","IPAddress":"142.250.190.14","PTRName":"lga34s65-in-f14.1e100.net" },
      { "Name":"microsoft.com","IPAddress":"40.113.200.201","PTRName":"a-0001.a-msedge.net" }
    ]

.EXAMPLE
    # Convert the JSON output back into PowerShell objects for further processing
    PS> Get-DnsPtrInfo -Name "example.com" | ConvertFrom-Json | Where-Object PTRName

.NOTES
    • Requires the Resolve-DnsName cmdlet (available in Windows PowerShell 3.0+ and PowerShell Core).
    • If no PTR record is found for an IP, the PTRName property will be $null (and a debug message is written).

.AUTHOR
    XRTCE
#>
function Get-DnsPtrInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [string[]]$name
    )
    $dnsResult = $name | ForEach-Object {
        Resolve-DnsName -Type A_AAAA $_
    }
    $outputObj = $dnsResult | ForEach-Object { 
        try {
            $ptrResult = $null
            $ip = $_.IPAddress
            $ptrResult = Resolve-DnsName $_.IPAddress -ErrorAction Stop
        }
        catch [System.ComponentModel.Win32Exception] {
            Write-Debug "No PTR Record found for $ip"
        }
        [pscustomobject]@{
            Name = $_.Name
            IPAddress = $_.IPAddress
            PTRName = $ptrResult.NameHost
        }
    }
    return $outputObj | ConvertTo-Json
}

﻿<#
.SYNOPSIS
	list-cmdlets.ps1 
.DESCRIPTION
	Lists all PowerShell cmdlets
.EXAMPLE
	PS> .\list-cmdlets.ps1
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author:  Markus Fleschutz
	License: CC0
#>

try {
	Get-Command -Command-Type cmdlet
	exit 0
} catch {
	write-error "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}

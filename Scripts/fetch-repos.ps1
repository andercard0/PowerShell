#!/usr/bin/pwsh
<#
.SYNTAX       fetch-repos.ps1 [<parent-dir>]
.DESCRIPTION  fetches updates for all Git repositories under the current/given directory (including submodules)
.LINK         https://github.com/fleschutz/PowerShell
.NOTES        Author: Markus Fleschutz / License: CC0
#>

param($ParentDir = "$PWD")

try {
	"Fetching updates for Git repositories under $($ParentDir)..."
	$StopWatch = [system.diagnostics.stopwatch]::startNew()

	if (-not(test-path "$ParentDir" -pathType container)) { throw "Can't access directory: $ParentDir" }
	set-location $ParentDir

	& git --version
	if ($lastExitCode -ne "0") { throw "Can't execute 'git' - make sure Git is installed and available" }

	[int]$Count = 0
	get-childItem $ParentDir -attributes Directory | foreach-object {
		& "$PSScriptRoot/fetch-repo.ps1" "$($_.FullName)"
		if ($lastExitCode -ne "0") { throw "Script 'fetch-repo.ps1' failed" }

		$Count++
	}

	write-host -foregroundColor green "OK - fetched updates for $Count Git repositories under $ParentDir in $($StopWatch.Elapsed.Seconds) second(s)"
	exit 0
} catch {
	write-error "ERROR: line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}

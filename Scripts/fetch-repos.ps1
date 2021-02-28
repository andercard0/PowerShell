#!/bin/powershell
<#
.SYNTAX         ./fetch-repos.ps1 [<repo-dir>]
.DESCRIPTION	fetches all Git repositories under the current/given directory (including submodules)
.LINK		https://github.com/fleschutz/PowerShell
.NOTES		Author:	Markus Fleschutz / License: CC0
#>

param($RepoDir = "$PWD")

try {
	$null = $(git --version)
} catch {
	write-error "ERROR: can't execute 'git' - make sure Git is installed and available"
	exit 1
}

try {
	write-progress "Fetching repository $RepoDir ..."
	set-location $RepoDir
	& git fetch --recurse-submodules
	if ($lastExitCode -ne "0") { throw "'git fetch --recurse-submodules' failed" }

	write-host -foregroundColor green "OK - fetched repository $RepoDir"
	exit 0
} catch {
	write-error "ERROR: line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}

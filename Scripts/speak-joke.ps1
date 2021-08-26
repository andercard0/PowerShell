﻿<#
.SYNOPSIS
	speak-joke.ps1
.DESCRIPTION
	Speaks a random Chuck Norris joke by text-to-speech (TTS)
.EXAMPLE
	PS> .\speak-joke.ps1
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author:  Markus Fleschutz
	License: CC0
#>

try {
	$Table = import-csv "$PSScriptRoot/../Data/jokes.csv"
	$NumRows = $Table.count

	$Generator = New-Object System.Random
	$Index = [int]$Generator.next(0,$NumRows - 1)
	$Joke = $Table[$Index].Joke

	& "$PSScriptRoot/speak-english.ps1" "$Joke"
	exit 0
} catch {
	write-error "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}

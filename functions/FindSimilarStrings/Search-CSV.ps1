. "../Shared/Save-File.ps1"
. "../Shared/Open-File.ps1"
. "../Shared/Compare-Strings.ps1"
. "../Shared/Find-ExcelContent.ps1"
Import-Module ImportExcel
Add-Type -AssemblyName System.Windows.Forms

function Search-CSV {
    <#
        .SYNOPSIS
            Searches for similar strings in a CSV file that fit within a user-defined tolerance. 
            Can return the whole row of data for each match found or just the specified column's value.

        .DESCRIPTION
            Prompts the user to select a CSV file, enter a search value, a column name, and a tolerance level.
            Prompts the user to return whole row or just the specified column's value results.
            Searches for strings that are similar to the provided search value within the specified tolerance.
            Results can be returned for the whole row or just the specified column.

        .EXAMPLE
            Search-CSV
            This will execute the function and prompt for necessary input.

        .NOTES
            Author: Connor Mason
            Last Updated: 10/2/2024
    #>
    [CmdletBinding()]
    Param()

    $initialDirectory = $PWD.Path 
    if (-not (Test-Path -Path $initialDirectory)) {
        $initialDirectory = $env:USERPROFILE 
    }
    if (-not (Test-Path -Path $initialDirectory)) {
        $initialDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
    }

    $selectedFile = Open-File -Title "Select the Input File" -InitialDirectory $initialDirectory
    $searchVal = Get-ValidatedInput `
        -Prompt "Please enter the value you are searching for" `
        -Pattern '^[\w\s\-.,;:!?@#$%^&*()_+=\[\]{}|\\/<>~`"'']+$' `
        -ErrorMessage "Invalid input. Please enter a valid search value."
    if (-not $searchVal) { return }
    $columnName = Get-ValidatedInput `
        -Prompt "Enter the column name that contains the value you are searching for" `
        -Pattern '^[a-zA-Z0-9_]+$' `
        -ErrorMessage "Invalid input. Please enter a valid column name."
    if (-not $columnName) { return }
    $tolerance = Get-ToleranceInput
    $returnWholeRow = Get-YesNoInput "Do you want to return the whole row when we find matches within the tolerance you set? (y/n)"
    if (-not $returnWholeRow) { return }
    $useRegex = Get-YesNoInput "Do you want to use regex pattern matching for comparison? (y/n)"
    if (-not $useRegex) { return }

    try {
        $matchingStringsResults = Find-ExcelContent `
            -SelectedFile $selectedFile `
            -SearchVal $searchVal `
            -ColumnName $columnName `
            -Tolerance $tolerance `
            -ReturnWholeRow $returnWholeRow `
            -UseRegex $useRegex
    }
    catch {
        Write-Error "An error occurred while searching the file: $_"
        return
    }

    if ($matchingStringsResults.Count -eq 0) {
        Write-Host "No matching results found."
        return
    }

    $savedFilePath = Save-File `
        -Content $matchingStringsResults `
        -Title "Save the Results File" `
        -FileTypeFilter "Excel Files (*.xlsx)|*.xlsx" `
        -InitialDirectory $initialDirectory
    if ($savedFilePath) {
        Write-Host "Results saved to: $savedFilePath"
    }

    Show-Results -Results $matchingStringsResults
    Read-Host -Prompt "Press Enter to exit"
}

function Get-ValidatedInput {
    param (
        [string]$prompt,
        [string]$pattern,
        [string]$errorMessage
    )
    $input = Read-Host $prompt
    if (-not $input -is [string]) {
        $input = $input.ToString()
    }
    if ($input -notMatch $pattern) {
        Write-Host $errorMessage
        return $null
    }
    return $input
}

function Get-ToleranceInput {
    $tolerance = Read-Host "Enter the number of characters the string can be off by to still be returned in the search"
    while ($tolerance -notmatch '^[0-9]$' -or [int]$tolerance -gt 9) {
        Write-Host "Invalid input. Please enter a number between 0 and 9."
        $tolerance = Read-Host "Enter the number of characters the string can be off by to still be returned in the search"
    }
    return [int]$tolerance
}

function Get-YesNoInput {
    param (
        [string]$prompt
    )
    $input = Read-Host $prompt
    while ($input -notmatch '^[ynYN]$') {
        Write-Host "Invalid input. Please enter y or n."
        $input = Read-Host $prompt
    }
    return $input -eq 'y' -or $input -eq 'Y'
}

function Show-Results {
    Param(
        [Parameter(Mandatory=$true)]
        [System.Object[]]$Results
    )
    $Results | ForEach-Object {
        $_ | Format-Table -AutoSize
    }
}

Search-CSV
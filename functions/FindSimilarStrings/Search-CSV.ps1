. "../Shared/Save-File.ps1"
. "../Shared/Open-File.ps1"
. "../Shared/Compare-Strings.ps1"
. "../Shared/Process-CSV-File.ps1"
Add-Type -AssemblyName System.Windows.Forms

function Search-CSV {
    <#
        .SYNOPSIS
            Searches for similar strings in a CSV file that fit within a user-defined tolerance. 
            Can return the whole row of data for each match found or just the specified column's value.

        .DESCRIPTION
            Prompts the user to select a CSV file, enter a search value, a column name, and a tolerance level.
            Prompts the user to return whole row or just the specified column's value results.
            Prompts the user to select a CSV file to save the results in.
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
    # Define a safe initial directory using environment variables and fallbacks
    $initialDirectory = $PWD.Path 
    if (-not (Test-Path -Path $initialDirectory)) {
        $initialDirectory = $env:USERPROFILE 
    }
    if (-not (Test-Path -Path $initialDirectory)) {
        $initialDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
    }
    $selectedFile = Open-File -Title "Select the Input CSV File" -FileType "*.csv" -InitialDirectory $initialDirectory

    # Get user input vars to inform the search
    $searchVal = Read-Host "Please enter the value you are searching for"
    if (-not $searchVal -is [string]) {
        $searchVal = $searchVal.ToString()
    }
    $columnName = Read-Host "Enter the column name that contains the value you are searching for"
    $tolerance = Read-Host "Enter the number of characters the string can be off by to still be returned in the search"
    while ($tolerance -notmatch '^[0-9]$' -or [int]$tolerance -gt 9) {
        Write-Host "Invalid input. Please enter a number between 0 and 9."
        $tolerance = Read-Host "Enter the number of digits the SSN can be off by to still be returned in the search"
    }
    $returnWholeRow = Read-Host "Do you want to return the whole row when we find matches within the tolerance you set? (y/n)"
    while ($returnWholeRow -notmatch '^[ynYN]$') {
        Write-Host "Invalid input. Please enter y or n."
        $returnWholeRow = Read-Host "Do you want to return the whole row when we find matches within the tolerance you set? (y/n)"
    }

    $matchingStringsResults = Process-CSV-File -SelectedFile $selectedFile -SearchVal $searchVal -ColumnName $columnName -Tolerance $tolerance -ReturnWholeRow $returnWholeRow

    Save-File -Title "Save the Results File" -FileType "*.csv" -MatchingStringsResults $matchingStringsResults -InitialDirectory $initialDirectory
    Display-Results -Results $matchingStringsResults
    Read-Host -Prompt "Press Enter to exit"
}

function Display-Results {
    Param(
        [Parameter(Mandatory=$true)]
        [System.Object[]]$Results
    )
    $Results | ForEach-Object {
        $_ | Format-Table -AutoSize
    }
}

Search-CSV

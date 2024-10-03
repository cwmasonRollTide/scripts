. "../Shared/Compare-Strings.ps1"

function Find-ExcelContent {
    <#
        .SYNOPSIS
            Finds matching strings within a specified tolerance in a CSV file. Either returns the entire rows or just the matching values.

        .DESCRIPTION
            The Find-ExcelContent function searches for matching strings within a specified tolerance in a CSV file. 
            It compares the search value with the values in the specified column of the CSV file and returns either the matching strings or the entire row.

        .PARAMETER selectedFile
            Specifies the path to the CSV file. Must be CSV File because it searches by column name and optionally returns the entire row.

        .PARAMETER searchVal
            Specifies the value to search for within the CSV file.

        .PARAMETER columnName
            Specifies the name of the column in the CSV file to search within.

        .PARAMETER tolerance
            Specifies the tolerance level for string comparison. Only strings within this tolerance level will be considered as matches.

        .PARAMETER returnWholeRow
            Specifies whether to return the entire row or just the matching value. Use "y" to return the entire row, and any other value to return just the matching value.

        .EXAMPLE
            Find-ExcelContent -selectedFile "C:\path\to\file.csv" -searchVal "apple" -columnName "Fruit" -tolerance 2 -returnWholeRow "y"
            This example searches for the value "apple" within the "Fruit" column of the CSV file located at "C:\path\to\file.csv". It allows a tolerance of 2 characters for string comparison and returns the entire row for each matching string.

        .EXAMPLE
            Find-ExcelContent -selectedFile "C:\path\to\file.csv" -searchVal "banana" -columnName "Fruit" -tolerance 1 -returnWholeRow "n"
            This example searches for the value "banana" within the "Fruit" column of the CSV file located at "C:\path\to\file.csv". It allows a tolerance of 1 character for string comparison and returns only the matching value for each match.

        .OUTPUTS
            System.Object[] | string[] 
            An array of matching strings or rows from the CSV file, depending on the returnWholeRow parameter.

        .NOTES
            Author: Connor Mason
            Date:   10/2/2024

    #>
    [CmdletBinding()]
    param (
        [string]$selectedFile,
        [string]$searchVal,
        [string]$columnName,
        [int]$tolerance,
        [string]$returnWholeRow,
        [string]$useRegex
    )
    $csvData = Import-Excel -Path $selectedFile
    $matchingStringsResults = @()
    foreach ($row in $csvData) {
        $currentVal = $row.$columnName
        if ($useRegex -eq "y") {
            if (Compare-StringsRegex -Str1 $searchVal -Str2 $currentVal -Tolerance $tolerance) {
                if ($returnWholeRow -eq "y") {
                    $matchingStringsResults += $row
                } else {
                    $matchingStringsResults += [PSCustomObject]@{$columnName = $currentVal}
                }
            }
        } else {
            if (Compare-Strings -Str1 $searchVal -Str2 $currentVal -Tolerance $tolerance) {
                if ($returnWholeRow -eq "y") {
                    $matchingStringsResults += $row
                } else {
                    $matchingStringsResults += [PSCustomObject]@{$columnName = $currentVal}
                }
            }
        }
    }
    return $matchingStringsResults
}


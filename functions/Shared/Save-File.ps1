Add-Type -AssemblyName System.Windows.Forms

function Save-File {
<#
    .SYNOPSIS
        Saves a file with user-defined options for title and file type.
    
    .DESCRIPTION
        Opens a save file dialog that allows the user to save a file with options for specifying the title and the file type filter.
    
    .PARAMETER Title
        The title of the save file dialog. Default is 'Save the File'.
    
    .PARAMETER FileType
        The file type filter for the save dialog. Default is 'All Files (*.*)'.
    
    .EXAMPLE
        Save-File
        Opens a save dialog with the default title and file type filter.
    
    .EXAMPLE
        Save-File -Title "Export CSV File" -FileType "*.csv"
        Opens a save dialog with a custom title and filter for CSV files only.
    
    .Notes
        Author: Connor Mason
        Date: 10/2/2024
#>
[CmdletBinding()]
Param(
    [ValidatePattern('^\*\.[a-zA-Z0-9]+$|^All files \(\*\.\*\)$')]
    [string]$FileType = "*.",
    [string]$Title = "Select a File",
    [string]$InitialDirectory = "",
    [object[]]$MatchingStringsResults = @()
)
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Title = $Title
    $saveFileDialog.Filter = "$FileType|$FileType"
    $saveFileDialog.InitialDirectory = $InitialDirectory
    $result = $saveFileDialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $resultFile = $saveFileDialog.FileName
        $MatchingStringsResults | Export-Csv -Path $resultFile -NoTypeInformation
        Write-Host "Results file saved: $resultFile"
    } else {
        Write-Host "No file was selected to save the results."
        exit
    }
}
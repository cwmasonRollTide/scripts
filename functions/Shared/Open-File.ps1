function Open-File {
    <#
        .SYNOPSIS
            Allows the user to Open a file for processing.

        .DESCRIPTION
            Opens a file dialog that lets the user Open a file. The file type can be specified; defaults to all file types.

        .PARAMETER FileType
            The file extension to filter by in the file dialog. Default is "All files (*.*)".

        .PARAMETER Title
            The title of the file dialog. Default is "Open a File".

        .PARAMETER InitialDirectory
            The initial directory to display in the file dialog. Default is the directory of the script.

        .EXAMPLE
            Open-File -FileType "*.txt"
            Opens a dialog allowing only text files to be selected.

        .EXAMPLE
            Open-File
            Opens a dialog allowing any file type to be selected.

        .OUTPUTS 
            String
            The full path of the selected file. If canceled, exits the script.
        
        .NOTES
            Author: Connor Mason
            Date: 10/2/2024
    #>
    [CmdletBinding()]
    Param(
        [ValidatePattern('^\*\.[a-zA-Z0-9]+$|^All files \(\*\.\*\)$')]
        [string]$FileType = "All files (*.*)",
        [string]$Title = "Select a File",
        [string]$InitialDirectory = ""
    )
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $Title
    $openFileDialog.Filter = "$FileType|$FileType"
    $openFileDialog.InitialDirectory = $InitialDirectory
    $result = $openFileDialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedFile = $openFileDialog.FileName
        Write-Host "File selected: $selectedFile"
        return $selectedFile
    } else {
        Write-Host "No file was selected."
        exit
    }
}
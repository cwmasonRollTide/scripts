Add-Type -AssemblyName System.Windows.Forms
. "../Shared/Compare-Strings.ps1"

$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.InitialDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
$openFileDialog.Filter = "CSV files (*.csv)|*.csv"
$openFileDialog.Title = "Select the Employee Data File"

$result = $openFileDialog.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedFile = $openFileDialog.FileName
    Write-Host "File selected: $selectedFile"
} else {
    Write-Host "No file was selected."
    exit
}

if (-not $selectedFile) {
    Write-Host "No file was selected or file path could not be retrieved. Exiting script."
    exit
}

$searchSSN = Read-Host "Please enter the Social Security Number you are searching for"

while ($searchSSN -notmatch '^\d{9}$') {
    Write-Host "Invalid SSN format. Please enter a 9-digit SSN."
    $searchSSN = Read-Host "Please enter the Social Security Number you are searching for"
}

$tolerance = Read-Host "Enter the number of digits the SSN can be off by to still be returned in the search"

while ($tolerance -notmatch '^[0-9]$' -or [int]$tolerance -gt 9) {
    Write-Host "Invalid input. Please enter a number between 0 and 9."
    $tolerance = Read-Host "Enter the number of digits the SSN can be off by to still be returned in the search"
}

$csvData = Import-Csv -Path $selectedFile

$matchingSSNs = @()

foreach ($row in $csvData) {
    $currentSSN = $row.Tax_ID
    if (Compare-Strings $searchSSN $currentSSN $tolerance) {
        $matchingSSNs += [PSCustomObject]@{SSN = $currentSSN}
    }
}

$matchingSSNs | Export-Csv -Path "Results.csv" -NoTypeInformation

Write-Host "Matching SSNs:"
$matchingSSNs | ForEach-Object { Write-Host $_.SSN }
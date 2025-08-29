# Author: Nilson Sangy
# https://github.com/nilsonsangy/forensic-tools

# Prompt the user to enter the folder path
$folderPath = Read-Host "Please enter the folder path where the files are located"

# Validate the folder path
if (-Not (Test-Path -Path $folderPath)) {
    Write-Host "The folder path does not exist. Exiting." -ForegroundColor Red
    exit
}

# Define the path for the hashes.txt file
$outputFile = Join-Path -Path $folderPath -ChildPath "hashes.txt"

# Handle existing hashes.txt file
if (Test-Path -Path $outputFile) {
    # Ask for confirmation before deleting the file
    $confirmation = Read-Host "The file 'hashes.txt' already exists. Do you want to overwrite it? (yes/no)"
    if ($confirmation.ToLower() -ne "yes") {
        Write-Host "Operation canceled by the user." -ForegroundColor Yellow
        exit
    }
    # Remove the file if the user confirms
    Remove-Item -Path $outputFile -Force
}

# Add the script link on GitHub to the first line of hashes.txt
$githubLink = "https://github.com/nilsonsangy/forensic-tools/blob/main/generate_hashes.ps1"
"Script source: $githubLink`n" | Out-File -FilePath $outputFile -Encoding UTF8

# Add the timestamp to the next line of hashes.txt
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"Hashes generated on: $timestamp`n" | Out-File -FilePath $outputFile -Append -Encoding UTF8

# Calculate the SHA256 hash of each file in the folder (including subfolders) and save it to hashes.txt
Get-ChildItem -Path $folderPath -File -Recurse | ForEach-Object {
    $filePath = $_.FullName
    $hash = Get-FileHash -Path $filePath -Algorithm SHA256
    "$($hash.Hash) $($hash.Path)" | Out-File -FilePath $outputFile -Append -Encoding UTF8
}

Write-Host "Hashes have been saved to $outputFile" -ForegroundColor Green

# Calculate the SHA256 hash of the hashes.txt file
$hashesFileHash = Get-FileHash -Path $outputFile -Algorithm SHA256

# Print the SHA256 hash of the hashes.txt file to the terminal
Write-Host "SHA256 of hashes.txt: $($hashesFileHash.Hash)" -ForegroundColor Yellow
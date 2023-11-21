param (
    [string]$evtxFolderPath,
    [string]$outputDirectoryName,
    [string]$splunkPath = "C:\Program Files\Splunk\bin\splunk.exe"
)

# Function to check and install Rust
function Install-Rust {
    if (-not (Get-Command "rustc" -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Rust..."
        $rustupUrl = "https://win.rustup.rs/"
        $rustupFile = "rustup-init.exe"
        Invoke-WebRequest -Uri $rustupUrl -OutFile $rustupFile
        Start-Process -FilePath .\rustup-init.exe -ArgumentList '-y' -Wait
        Remove-Item .\rustup-init.exe
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","User")
    } else {
        Write-Host "Rust is already installed."
    }
}

# Function to check and install EVTX parser
function Install-EVTXParser {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","User")
    if (-not (Get-Command "evtx_dump" -ErrorAction SilentlyContinue)) {
        Write-Host "Installing evtx_dump..."
        cargo install evtx
    } else {
        Write-Host "EVTX parser is already installed."
    }
}

# Function to parse EVTX files to JSON
function Parse-EVTXFiles {
    $outputFolder = Join-Path "C:\org\" $outputDirectoryName
    if (-not (Test-Path -Path $outputFolder)) {
        New-Item -ItemType Directory -Path $outputFolder
        Write-Host "Created folder: $outputFolder"
    }

    Get-ChildItem -Path $evtxFolderPath -Filter *.evtx | ForEach-Object {
        $jsonFileName = [IO.Path]::GetFileNameWithoutExtension($_.Name) + ".json"
        $jsonFilePath = Join-Path $outputFolder $jsonFileName

        # Use evtx_dump to convert EVTX to JSON
        $evtxContent = evtx_dump -o json $_.FullName

        # Remove "Record" and the following random number from each log entry
        $evtxContent = $evtxContent -replace 'Record \d+', ''

        # Save the modified content to the JSON file
        $evtxContent | Set-Content -Path $jsonFilePath

        Write-Host "Converted $_ to JSON and saved to $jsonFilePath"
    }
}



# Main script execution
Install-Rust
Install-EVTXParser
Parse-EVTXFiles

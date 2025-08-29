# PowerShell script to set up Python virtual environment and install dependencies

$envPath = Join-Path $PSScriptRoot "venv"
$requirements = Join-Path $PSScriptRoot "requirements.txt"

# Create virtual environment if it doesn't exist
if (-not (Test-Path $envPath)) {
    Write-Host "Creating virtual environment in 'venv'..."
    python -m venv $envPath
}
else {
    Write-Host "Virtual environment already exists."
}

# Activate the virtual environment
$activateScript = Join-Path $envPath "Scripts\Activate.ps1"
Write-Host "Activating virtual environment..."
. $activateScript

# Install dependencies
Write-Host "Installing dependencies from requirements.txt..."
pip install -r $requirements

# Upgrade pip
Write-Host "Upgrading pip..."
python -m pip install --upgrade pip

Write-Host "Environment setup complete."

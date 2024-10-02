param (
    [string]$FunctionName,
    [string]$FunctionPath
)

# Debugging line to output the PATH environment variable
Write-Host "PATH: $env:PATH"

Write-Host "Packaging $FunctionName..."
Remove-Item -Path "$PSScriptRoot/../package/$FunctionName" -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path "$PSScriptRoot/../package/$FunctionName" -ItemType Directory -Force
pip install -r "$FunctionPath/requirements.txt" -t "$PSScriptRoot/../package/$FunctionName"
Copy-Item "$FunctionPath/*.py" -Destination "$PSScriptRoot/../package/$FunctionName"
Compress-Archive -Path "$PSScriptRoot/../package/$FunctionName/*" -DestinationPath "$PSScriptRoot/../package/$FunctionName.zip" -Force
Write-Host "Packaging of $FunctionName complete."

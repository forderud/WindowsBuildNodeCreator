# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Cleaning Jenkins workspace..."

if ($args.Count -eq 0) {
    throw "Workspace path argument missing."
}

$workspace = $args[0] # typically "C:\dev\workspace"
$numDays = 0.5 # unmodified for 12 hours

Get-ChildItem $workspace -Directory | Foreach-Object {
    $item = $_.FullName
    $modified = $_.LastWriteTime
    $cutOff = (Get-Date).AddDays(-$numDays)
    
    if ($modified -lt $cutOff) {
        Write-Host "Deleting $item that haven't been modified recently"
        Remove-Item -Path $item -Recurse -Force
    }
}

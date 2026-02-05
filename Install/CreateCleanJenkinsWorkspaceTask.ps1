# stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Creating scheduled task to clean old Jenkins workspaces..."
$jeninsWorkspace = "C:\dev\workspace"
$action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-File C:\Install\CleanJenkinsWorkspace.ps1 $jeninsWorkspace"

# run daily
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
# only run if idle for 5min (wait up to 3hours)
$settings = New-ScheduledTaskSettingsSet -RunOnlyIfIdle -IdleDuration 00:05:00 -IdleWaitTimeout 03:00:00

Register-ScheduledTask -Action $action -User "System" -Trigger $trigger -Settings $settings -TaskName "Jenkins cleanup" -Description "Delete old Jenkins workspaces"

Write-Host "Excluding Jenkins workspace from antivirus scans..."
Add-MpPreference -ExclusionPath $jeninsWorkspace

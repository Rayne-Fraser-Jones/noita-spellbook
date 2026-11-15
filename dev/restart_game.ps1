# Restarts Noita so it loads the mod's latest files, the way "Restart with enabled mods active"
# in the game's Mods menu does: the game is started again with the options that button uses
# (seen in play: noita.exe -no_logo_splashes -gamemode 4294967295 -save_slot 0), which skip the
# logos and the main menu and continue the run in save00.
#
# A running game is asked to close (as clicking its window's X does) and the script waits for
# it to exit. Nothing is forced: if it hasn't closed within the wait, it is left running. The
# script says whether the run was saved as it closed (the save file's time changed).
# Usage: powershell -ExecutionPolicy Bypass -File dev/restart_game.ps1
param([int]$WaitSeconds = 30)

$gameDir = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$exe = Join-Path $gameDir "noita.exe"
$saveFile = Join-Path $env:USERPROFILE "AppData\LocalLow\Nolla_Games_Noita\save00\world_state.xml"
function SavedAt { if (Test-Path $saveFile) { (Get-Item $saveFile).LastWriteTime } else { $null } }

$game = Get-Process noita -ErrorAction SilentlyContinue | Select-Object -First 1
if ($game) {
	$before = SavedAt
	if (-not $game.CloseMainWindow()) {
		Write-Output "Couldn't ask Noita to close (no window found); left running."
		exit 1
	}
	if (-not $game.WaitForExit($WaitSeconds * 1000)) {
		Write-Output "Noita didn't close within $WaitSeconds seconds; left running."
		exit 1
	}
	$after = SavedAt
	if ($after -ne $before) { Write-Output "Noita closed; the run was saved ($after)." }
	else { Write-Output "Noita closed; the save file didn't change (last saved $before)." }
	Start-Sleep -Seconds 1
}
# The game gets this script's environment, which may be older than the account's (a variable set
# with setx only reaches programs started afterwards). Take the account's current values of the
# variables the game cares about, such as SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS (0: the game doesn't
# minimise when another window is clicked).
foreach ($name in @("SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS")) {
	$value = [Environment]::GetEnvironmentVariable($name, "User")
	if ($value -ne $null) { Set-Item -Path "Env:$name" -Value $value }
}
Start-Process -FilePath $exe -WorkingDirectory $gameDir -ArgumentList "-no_logo_splashes", "-gamemode", "4294967295", "-save_slot", "0"
Write-Output "Noita started, continuing the run in save00."

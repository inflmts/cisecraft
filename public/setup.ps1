#
# This script automatically installs and runs the Minecraft client
# on a UF Marston Science Library computer.
# Do not run this on another computer!
# It is assumed that Java 21+ is already installed.
#

$ErrorActionPreference = 'Stop'

$hostname = [System.Net.Dns]::GetHostName()
$scoop_root = "$HOME\scoop"
$picomc_root = "$HOME\picomc"
$minecraft_dir = "$picomc_root\instances\cisecraft\minecraft"
$mods_dir = "$minecraft_dir\mods"

# updates $PATH with registry values
function Update-Environment {
  Write-Host "Updating environment..."
  $Env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('PATH', 'User')
}

# check that this is indeed a Marson computer
if (-not $hostname.StartsWith("AT-L-M-")) {
  Throw "Refusing to install on $hostname"
}

# remove existing installations of scoop and picomc
if (Test-Path $scoop_root) {
  Write-Host "Removing existing scoop installation..."
  cmd /c rmdir /q /s $scoop_root
}
if (Test-Path $picomc_root) {
  Write-Host "Removing existing picomc installation..."
  cmd /c rmdir /q /s $picomc_root
}

# install scoop
Write-Host "Installing scoop..."
Invoke-RestMethod https://get.scoop.sh | powershell -
Update-Environment

# install python
Write-Host "Installing python..."
scoop install python
Update-Environment

# install picomc
Write-Host "Installing picomc..."
pip install picomc

# setup picomc
Write-Host "Preparing picomc..."
$Env:PICOMC_ROOT = $picomc_root
picomc account create inflmts
picomc mod loader fabric install 1.21.1 0.16.3
picomc instance create cisecraft fabric-loader-0.16.3-1.21.1
$null = New-Item $mods_dir -ItemType Directory -Force
$null = New-Item $minecraft_dir -ItemType Directory -Force
$null = New-Item "$minecraft_dir\config" -ItemType Directory -Force
irm 'https://cdn.modrinth.com/data/P7dR8mSH/versions/gQS3JbZO/fabric-api-0.103.0%2B1.21.1.jar' -OutFile "$mods_dir\fabric-api-0.103.0.jar"
irm 'https://cdn.modrinth.com/data/AANobbMI/versions/RncWhTxD/sodium-fabric-0.5.11%2Bmc1.21.jar' -OutFile "$mods_dir\sodium-0.5.11.jar"
irm 'https://cdn.modrinth.com/data/EsAfCjCV/versions/fG1xJao0/appleskin-fabric-mc1.21-3.0.5.jar' -OutFile "$mods_dir\appleskin-3.0.5.jar"
irm 'https://cdn.modrinth.com/data/vgTtWasp/versions/PBTRsK6q/nomenublur%20-1.0.0.jar' -OutFile "$mods_dir\nomenublur-1.0.0.jar"
irm 'https://cdn.modrinth.com/data/1eAoo2KR/versions/Y8Wa10Re/YetAnotherConfigLib-3.5.0%2B1.21-fabric.jar' -OutFile "$mods_dir\yacl-3.5.0.jar"
irm 'https://www.cise.ufl.edu/~li.daniel/cisecraft/options.txt' -OutFile "$minecraft_dir\options.txt"
irm 'https://www.cise.ufl.edu/~li.daniel/cisecraft/sodium-options.json' -OutFile "$minecraft_dir\config\sodium-options.json"

# connect to server
Start-Process ssh "-q -L 25452:localhost:25452 -o `"ExitOnForwardFailure yes`" li.daniel@storm.cise.ufl.edu `"~/cisecraft/connect-shell`""

# launch
Write-Host "Launching Minecraft..."
picomc instance launch cisecraft

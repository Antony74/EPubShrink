
param(
    [string] $inFilename = '',
    [int]    $quality = 50,
    [bool]   $bInstallPrompt = $TRUE);

$arrDependancies = @(
    @('7z',          '7zip.commandline'),
	@('jpegoptim',   'jpegoptim'),
	@('pngquant',    'pngquant'),
	@('kindlegen',   'kindlegen'),
	@('kindlestrip', 'kindlestrip'),
	@('pip',         'pip'),
	@('choco',       'chocolately')
);

$bChocoNeeded = $FALSE;
$bPipNeeded = $FALSE;
$sMissingPackages =  '';

#
# Ensure all commands exist
#
foreach ($dependancy in $arrDependancies)
{
    $cmd = $dependancy[0];
	$package = $dependancy[1];

	if ( ($package -eq 'chocolately') -and ($bChocoNeeded -eq $FALSE) )
	{
		continue;
	}

	if ( ($package -eq 'pip') -and ($bPipNeeded -eq $FALSE) )
	{
		continue;
	}

	if (!(Get-Command $cmd -errorAction SilentlyContinue))
	{
		Write-Host ("Command '$cmd' not found (package '$package' needed)");

		if ($package -eq 'kindlestrip')
		{
			$bPipNeeded = $TRUE;
		}
		else
		{
			$bChocoNeeded = $TRUE;
			$sMissingPackages = $sMissingPackages + ' ' + $package;
		}
	}
}

#
# Do we need to install anything?
#

if ( ($sMissingPackages -ne '') -or $bPipNeeded -or $bChocoNeeded )
{
	# Ensure we have permission to install stuff

	if ($bInstallPrompt)
	{
		$confirmation = '';

		while ($confirmation -ne 'y')
		{
			if ($confirmation -eq 'n')
			{
				Exit;
			}

			$confirmation = Read-Host('Install all above named packages and continue? [y/n]');
		}
	}

	# Ensure we have admin rights to install stuff

	if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		$newProcess = new-object System.Diagnostics.ProcessStartInfo;
		$newProcess.Filename = $PsHome + '\PowerShell.exe';

		$newProcess.Arguments = ' -ExecutionPolicy unrestricted '            +
								$myInvocation.MyCommand.Definition           +
								' -inFilename {' + [string]$inFilename + '}' +
								' -quality ' + [int]$quality                 +
								' -bInstallPrompt $FALSE'                    ;

		$newProcess.Verb = "runas";

		$p = [System.Diagnostics.Process]::Start($newProcess);

		Exit;
	}

}


#*********************************************************************#
#***    This software is in the public domain, furnished "as is",  ***#
#***    without technical support, and with no warranty, express   ***#
#***    or implied, as to its usefulness for any purpose.          ***#
#*********************************************************************#

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

$filetitle = Get-ChildItem $inFilename | % {$_.BaseName};

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
            $sMissingPackages = $sMissingPackages + ';' + $package;
        }
    }
    elseif ($package -eq 'chocolately')
    {
        $bChocoNeeded = $FALSE;
    }
}

#
# Do we need to install anything?
#

if ( ($sMissingPackages -ne '') -or $bPipNeeded -or $bChocoNeeded )
{
    #
    # Ensure we have permission to install stuff
    #

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

    #
    # Ensure we have admin rights to install stuff
    #

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

    #
    # Install Chocolately, if required
    #

    if ($bChocoNeeded)
    {
        iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'));
    }

    #
    # Install any Chocolately packages required
    #
    if ($sMissingPackages.Length)
    {
        choco install --force $sMissingPackages
    }

    #
    # Install kindlestrip, if required
    #
    if ($bPipNeeded)
    {
        pip install kindlestrip 
    }
}

#
# The real work of this script starts here!
# (now all our required dependancies are in place)
#

$maxQuality = [math]::min(100, [math]::max(1, $quality));
$minQuality = [math]::max(1, $maxQuality - 10);
$qualityRange = '' + $minQuality + '-' + $maxQuality;

#
# Remove any existing 'output' directory
#

if (Get-Item output -errorAction SilentlyContinue)
{
    Remove-Item output -recurse -force;

    if (Get-Item output -errorAction SilentlyContinue)
    {
        Exit;
    }
}

#
# 1. Unzip the .epub with 7Zip
#

7z x $inFilename -ooutput/archive

if (-not (Get-Item output -errorAction SilentlyContinue))
{
    Exit;
}

#
# 2. Shrink any .jpeg files with jpegoptim
#

foreach($filename in (Get-ChildItem output/archive/OEBPS/Images/*.jpg))
{
    jpegoptim --max=$maxQuality $filename
}

#
# 3. Shrink any .png files with pngquant
#
pngquant --verbose --ext .png --force --quality $qualityRange output/archive/OEBPS/Images/*.png

#
# 4. Rezip the .epub with 7Zip
#

7z a -tzip output/$filetitle.epub output/archive

#
# 5. Convert to .mobi with kindlegen
#

kindlegen output/$filetitle.epub

#
# 6. Remove the .epub from the .mobi with kindlestrip
#

kindlestrip output/$filetitle.mobi output/$filetitle.mobi


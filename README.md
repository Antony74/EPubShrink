# EPubShrink
Script for .epub shrinkage and .mobi conversion.
Runs on Windows and uses lossy compression.

Usage:
`powershell ./EPubShrink.ps1 filename.mobi -quality 50`

The process this script automates is as follows (after offering to install any of the listed dependancies which are not present):

1. Unzip the .epub with [7Zip](https://chocolatey.org/packages/7zip.commandline)
2. Shrink any .jpeg files with [jpegoptim](https://chocolatey.org/packages/jpegoptim)
3. Shrink any .png files with [pngquant](https://chocolatey.org/packages/pngquant)
4. Rezip the .epub with [7Zip](https://chocolatey.org/packages/7zip.commandline)
5. Convert to .mobi with [kindlegen](https://chocolatey.org/packages/kindlegen)
6. Remove the .epub from the .mobi with [kindlestrip](https://github.com/jefftriplett/kindlestrip)

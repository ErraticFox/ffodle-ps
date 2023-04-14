$url = Get-Clipboard

# verify if the clipboard is a url
if ($url -notmatch '^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$') {
    Exit
}

Write-Host "Downloading "$url"..."

$domainName = $url -replace '.+\/\/i\.|.+\/\/|www.|\..+', ''

$extractorExists = (youtube-dlp --list-extractors) | Select-String -Pattern "^$domainName$"

if (!$extractorExists) {
    Write-Host "Domain has no extractor... Attempting to use generic extractor, may error out"
}

$downloadDir = "$PSScriptRoot\Downloads"
$fileName = "%(webpage_url_domain)s-%(uploader)s-%(id)s.%(ext)s"
$tmpFilePath = "$downloadDir/$fileName"

if (!(Test-Path -Path $downloadDir)) {
    New-Item -Path $downloads -ItemType Directory
}

switch ($domainName) {
    'facebook' {
        $filePath = youtube-dlp --windows-filenames --print after_move:filepath --quiet -o $tmpFilePath $url

        if (!$filePath) {
            Write-Host "`nPrivate Facebook videos are currently broken af (ref: https://github.com/yt-dlp/yt-dlp/issues/4311)"
            Start-Sleep 8
            Exit
        }
    }
    '4cdn' {
        $fileName = "4chan-%(id)s.%(ext)s"
    }
}

if (!$filePath) {
    if ($domainName -ne 'facebook') {
        $filePath = youtube-dlp --windows-filenames --cookies-from-browser 'chrome' --print after_move:filepath --quiet --force-overwrites -o $tmpFilePath $url

        if (!$filePath) {
            Start-Sleep 5
            Exit
        }

    }
}

$newFileNoExt = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)

$outputPath = "$downloadDir\$newFileNoExt.mp4" -replace '(m\.)' -replace '.com' -replace '@' -replace '_' -replace ' ', '_'

Write-Host "output path $outputPath"

ffmpeg -i $filePath -y -vcodec libx264 -crf 28 -c:a copy $outputPath
Remove-Item $filePath

Add-Type -AssemblyName System.Windows.Forms

$files = [System.Collections.Specialized.StringCollection]::new()
$files.Add($outputPath)
    
[System.Windows.Forms.Clipboard]::SetFileDropList($files)

Write-Host "Success! Thank you for using ffedlip! :^)`r`nDownloaded to $downloadDir/$newFileExt`r`nClosing in 5 seconds..."
Start-Sleep 5
Exit
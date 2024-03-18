$msdata = @("https://learn.microsoft.com/en-us/lifecycle/products/windows-10-2016-ltsb", "https://learn.microsoft.com/en-us/lifecycle/products/windows-10-enterprise-ltsc-2019")
$d4nData = Invoke-WebRequest "https://raw.githubusercontent.com/altrhombus/ReportSource/main/content/ms/mswin/lifecycle-client-ltsc.json" | Select-Object -ExpandProperty Content | ConvertFrom-Json

$releaseList = New-Object System.Collections.ArrayList

foreach ($sourceURL in $msdata) {
    $source = Invoke-WebRequest $sourceURL -UseBasicParsing
    $allReleases = [RegEx]::New(('<td>(.*?)<\/td>\s*<td align="right">\s*<local-time timezone="America\/Los_Angeles" format="date" datetime="(.*?)">(.*?)<\/local-time>\s*<\/td>\s*<td align="right">\s*<local-time timezone="America\/Los_Angeles" format="date" datetime="(.*?)">(.*?)<\/local-time>\s*<\/td>\s*<td align="right">\s*<local-time timezone="America\/Los_Angeles" format="date" datetime="(.*?)">(.*?)<\/local-time>')).Matches($source.RawContent)
    $allReleases.ForEach{
        $releaseList.add(
            [PSCustomObject]@{
                Version = $_.Groups[1].value
                SKU = "LTSC"
                StartDate = $(Get-Date $_.Groups[2].Value -Format "yyyy-MM-dd")
                MainstreamEndDate = $(Get-Date $_.Groups[4].Value -Format "yyyy-MM-dd")
                ExtendedEndDate = $(Get-Date $_.Groups[6].Value -Format "yyyy-MM-dd")
            }
        ) | Out-Null
    }
}

$releaseList = $releaseList | Sort-Object Version | Select-Object Version,SKU,StartDate,MainstreamEndDate,ExtendedEndDate -Unique

$outputData = [PSCustomObject]@{
    "DataForNerds"=[PSCustomObject]@{
        "LastUpdatedUTC" = (Get-Date).ToUniversalTime()
        "SourceList" = @("https://learn.microsoft.com/en-us/lifecycle/products/windows-10-2016-ltsb", "https://learn.microsoft.com/en-us/lifecycle/products/windows-10-enterprise-ltsc-2019")
    }
    "Data" = $releaseList
}

$allProperties = $releaseList[0].psobject.Properties.Name

If(Compare-Object $d4nData.Data $releaseList -Property $allProperties -SyncWindow 0) {
    $outputFolder = Resolve-Path (Join-Path $PSScriptRoot -ChildPath "../../../content/ms/mswin")
    $outputFile = Join-Path $outputFolder -ChildPath "lifecycle-client-ltsc.json"

    $jsonData = $outputData | ConvertTo-Json
    [System.IO.File]::WriteAllLines($outputFile, $jsonData)   
} else {
    Write-Host "The data has not changed."
}

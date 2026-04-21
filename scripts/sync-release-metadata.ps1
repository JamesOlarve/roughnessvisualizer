param(
    [string]$ReleaseVersion = $env:RELEASE_VERSION,

    [string]$Doi = $env:RELEASE_DOI,

    [string]$ReleaseYear = $env:RELEASE_YEAR
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
    throw 'ReleaseVersion is required. Pass -ReleaseVersion or set RELEASE_VERSION.'
}

if ([string]::IsNullOrWhiteSpace($Doi)) {
    throw 'Doi is required. Pass -Doi or set RELEASE_DOI.'
}

if ([string]::IsNullOrWhiteSpace($ReleaseYear)) {
    throw 'ReleaseYear is required. Pass -ReleaseYear or set RELEASE_YEAR.'
}

$parsedReleaseYear = 0
if (-not [int]::TryParse($ReleaseYear, [ref]$parsedReleaseYear)) {
    throw "ReleaseYear must be an integer. Received: $ReleaseYear"
}

$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$readmePath = Join-Path -Path $repoRoot -ChildPath 'README.md'
$citationPath = Join-Path -Path $repoRoot -ChildPath 'CITATION.cff'

function Update-SingleMatch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(Mandatory = $true)]
        [string]$Replacement,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $match = [regex]::Matches($Content, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($match.Count -ne 1) {
        throw "Expected exactly one match for $Label, found $($match.Count)."
    }

    return [regex]::Replace(
        $Content,
        $Pattern,
        $Replacement,
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )
}

$readmeContent = Get-Content -Path $readmePath -Raw
$readmeContent = Update-SingleMatch -Content $readmeContent -Pattern '^Version:\s+.+$' -Replacement "Version: $ReleaseVersion" -Label 'README version line'
$readmeContent = Update-SingleMatch -Content $readmeContent -Pattern '\[!\[DOI\]\(https://zenodo\.org/badge/DOI/[^)]+\.svg\)\]\(https://doi\.org/[^)]+\)' -Replacement "[![DOI](https://zenodo.org/badge/DOI/$Doi.svg)](https://doi.org/$Doi)" -Label 'README DOI badge'
$readmeContent = Update-SingleMatch -Content $readmeContent -Pattern '^Olarve, J\. S\. \(\d{4}\)\. \*RoughnessVisualizer: A Web-Based Roughness Analysis Tool\* \(v[^)]+\)\. Zenodo\.[ \t]*\r?$' -Replacement "Olarve, J. S. ($parsedReleaseYear). *RoughnessVisualizer: A Web-Based Roughness Analysis Tool* (v$ReleaseVersion). Zenodo.  " -Label 'README citation line'
$readmeContent = Update-SingleMatch -Content $readmeContent -Pattern '^https://doi\.org/10\.5281/zenodo\.[0-9]+[ \t]*\r?$' -Replacement "https://doi.org/$Doi" -Label 'README DOI URL'
Set-Content -Path $readmePath -Value $readmeContent -NoNewline

$citationContent = Get-Content -Path $citationPath -Raw
$citationContent = Update-SingleMatch -Content $citationContent -Pattern '^version:\s+"[^"]+"\r?$' -Replacement ('version: "{0}"' -f $ReleaseVersion) -Label 'CITATION version'
$citationContent = Update-SingleMatch -Content $citationContent -Pattern '^doi:\s+.+\r?$' -Replacement "doi: $Doi" -Label 'CITATION DOI'
Set-Content -Path $citationPath -Value $citationContent -NoNewline

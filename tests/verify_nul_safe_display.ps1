$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$header = Get-Content -Raw -Path (Join-Path $root 'src/qscidisplaywindow.h')
$source = Get-Content -Raw -Path (Join-Path $root 'src/qscidisplaywindow.cpp')

if ($header -notmatch 'void\s+setText\s*\(\s*const\s+QString\s*&\s*text\s*\)\s*(override\s*)?;') {
    throw 'QsciDisplayWindow must declare its own setText(const QString &text).'
}

$methodMatch = [regex]::Match(
    $source,
    'void\s+QsciDisplayWindow::setText\s*\(\s*const\s+QString\s*&\s*text\s*\)\s*\{(?<body>[\s\S]*?)^\}',
    [System.Text.RegularExpressions.RegexOptions]::Multiline
)

if (-not $methodMatch.Success) {
    throw 'QsciDisplayWindow::setText implementation was not found.'
}

$body = $methodMatch.Groups['body'].Value

if ($body -notmatch 'QsciScintilla::clear\s*\(\s*\)\s*;') {
    throw 'QsciDisplayWindow::setText must clear through QsciScintilla::clear().'
}

if ($body -notmatch 'QsciScintilla::append\s*\(\s*text\s*\)\s*;') {
    throw 'QsciDisplayWindow::setText must append through QsciScintilla::append(text), which uses SCI_APPENDTEXT with an explicit length.'
}

if ($body -match 'SCI_SETTEXT') {
    throw 'QsciDisplayWindow::setText must not use SCI_SETTEXT because it truncates at embedded NUL bytes.'
}

Write-Host 'NUL-safe display source checks passed.'

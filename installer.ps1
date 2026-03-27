param(
    [string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkCyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor DarkCyan
}

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

$PackageRoot = $PSScriptRoot
$LogDir = Join-Path $PackageRoot "logs"
Ensure-Dir $LogDir
$Global:LogFile = Join-Path $LogDir ("apply_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")

function Write-Log([string]$Message) {
    $Message | Tee-Object -FilePath $Global:LogFile -Append | Out-Host
}

function Run-Native {
    param(
        [string]$Exe,
        [string[]]$Args,
        [string]$Step,
        [string]$WorkingDirectory = "",
        [switch]$AllowFail
    )

    Write-Step $Step
    Write-Log ("CMD: " + $Exe + " " + ($Args -join " "))

    $old = Get-Location
    try {
        if ($WorkingDirectory) {
            Set-Location $WorkingDirectory
        }
        & $Exe @Args 2>&1 | Tee-Object -FilePath $Global:LogFile -Append | Out-Host
        $code = $LASTEXITCODE
    }
    finally {
        Set-Location $old
    }

    if (($code -ne 0) -and (-not $AllowFail)) {
        throw "Step failed: $Step (exit code $code)"
    }

    return $code
}

try {
    Write-Step "شروع نصب خودکار پچ شاهین موتور"
    Write-Log "Package root: $PackageRoot"

    $candidateRoots = @()
    if ($ProjectRoot) { $candidateRoots += $ProjectRoot.Trim('"') }
    $candidateRoots += @(
        (Join-Path $PackageRoot "public_html"),
        $PackageRoot,
        (Split-Path $PackageRoot -Parent),
        (Join-Path (Split-Path $PackageRoot -Parent) "public_html")
    )
    $candidateRoots = $candidateRoots | Where-Object { $_ } | Select-Object -Unique

    $ResolvedProjectRoot = $null
    foreach ($cand in $candidateRoots) {
        if (Test-Path -LiteralPath (Join-Path $cand "manage.py")) {
            $ResolvedProjectRoot = (Resolve-Path -LiteralPath $cand).Path
            break
        }
    }

    if (-not $ResolvedProjectRoot) {
        Write-Host ""
        $manual = Read-Host "مسیر پوشه پروژه را وارد کنید (پوشه‌ای که manage.py داخلش است)"
        if (-not $manual) { throw "Project path not provided." }
        $manual = $manual.Trim('"')
        if (-not (Test-Path -LiteralPath (Join-Path $manual "manage.py"))) {
            throw "manage.py در مسیر واردشده پیدا نشد: $manual"
        }
        $ResolvedProjectRoot = (Resolve-Path -LiteralPath $manual).Path
    }

    Write-Log "Project root: $ResolvedProjectRoot"

    $PatchArchive = Join-Path $PackageRoot "payload\shahinmotor_registration_patch_v2.zip"
    if (-not (Test-Path -LiteralPath $PatchArchive)) {
        throw "Patch archive not found: $PatchArchive"
    }

    $WorkRoot = Join-Path $PackageRoot "_work"
    $PatchDir = Join-Path $WorkRoot "patch"
    $BackupRoot = Join-Path $PackageRoot ("backup_before_patch_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
    Ensure-Dir $WorkRoot
    if (Test-Path -LiteralPath $PatchDir) {
        Remove-Item -LiteralPath $PatchDir -Recurse -Force
    }
    Ensure-Dir $PatchDir
    Ensure-Dir $BackupRoot

    Write-Step "باز کردن فایل پچ"
    Expand-Archive -LiteralPath $PatchArchive -DestinationPath $PatchDir -Force
    Write-Log "Patch extracted to: $PatchDir"

    Write-Step "تهیه بکاپ از فایل‌های جایگزین‌شونده و کپی پچ روی پروژه"
    Get-ChildItem -LiteralPath $PatchDir -Recurse -File | ForEach-Object {
        $source = $_.FullName
        $relative = $source.Substring($PatchDir.Length).TrimStart('\\','/')
        $dest = Join-Path $ResolvedProjectRoot $relative
        $destDir = Split-Path $dest -Parent
        Ensure-Dir $destDir

        if (Test-Path -LiteralPath $dest) {
            $backupPath = Join-Path $BackupRoot $relative
            $backupDir = Split-Path $backupPath -Parent
            Ensure-Dir $backupDir
            Copy-Item -LiteralPath $dest -Destination $backupPath -Force
        }

        Copy-Item -LiteralPath $source -Destination $dest -Force
        Write-Log ("Patched: " + $relative)
    }

    $pythonCandidates = @(
        (Join-Path $ResolvedProjectRoot "venv\Scripts\python.exe"),
        (Join-Path (Split-Path $ResolvedProjectRoot -Parent) "venv\Scripts\python.exe")
    )

    $pyCmd = Get-Command py -ErrorAction SilentlyContinue
    if ($pyCmd) { $pythonCandidates += $pyCmd.Source }
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) { $pythonCandidates += $pythonCmd.Source }

    $PythonExe = $null
    foreach ($cand in ($pythonCandidates | Select-Object -Unique)) {
        if ($cand -and (Test-Path -LiteralPath $cand)) {
            $PythonExe = $cand
            break
        }
    }

    if (-not $PythonExe) {
        throw "Python executable پیدا نشد. لطفاً Python یا venv را بررسی کنید."
    }

    $exeName = [System.IO.Path]::GetFileName($PythonExe).ToLowerInvariant()
    $PythonPrefix = @()
    if ($exeName -eq "py.exe" -or $exeName -eq "py") {
        $PythonPrefix = @("-3")
    }

    function Run-Python {
        param(
            [string[]]$Args,
            [string]$Step,
            [switch]$AllowFail
        )
        return Run-Native -Exe $PythonExe -Args ($PythonPrefix + $Args) -Step $Step -WorkingDirectory $ResolvedProjectRoot -AllowFail:$AllowFail
    }

    $reqFile = Join-Path $ResolvedProjectRoot "requirements.txt"
    if (-not (Test-Path -LiteralPath $reqFile)) {
        throw "requirements.txt پیدا نشد."
    }

    $pipCode = Run-Python -Args @("-m","pip","install","--disable-pip-version-check","-r",$reqFile) -Step "نصب وابستگی‌ها" -AllowFail
    if ($pipCode -ne 0) {
        Run-Python -Args @("-m","pip","install","--upgrade","pip") -Step "ارتقای pip" -AllowFail | Out-Null
        $pipCode = Run-Python -Args @("-m","pip","install","--disable-pip-version-check","-r",$reqFile) -Step "تلاش دوباره برای نصب وابستگی‌ها" -AllowFail
        if ($pipCode -ne 0) {
            throw "نصب وابستگی‌ها ناموفق بود. احتمالاً اینترنت یا دسترسی pip مشکل دارد."
        }
    }

    $migrateCode = Run-Python -Args @("manage.py","migrate") -Step "اجرای migrate" -AllowFail
    if ($migrateCode -ne 0) {
        Run-Python -Args @("manage.py","makemigrations") -Step "تلاش برای makemigrations" -AllowFail | Out-Null
        $migrateCode = Run-Python -Args @("manage.py","migrate") -Step "تلاش دوباره برای migrate" -AllowFail
        if ($migrateCode -ne 0) {
            throw "migrate ناموفق بود."
        }
    }

    $checkCode = Run-Python -Args @("manage.py","check") -Step "بررسی سلامت پروژه" -AllowFail
    if ($checkCode -ne 0) {
        Run-Python -Args @("manage.py","migrate") -Step "اجرای دوباره migrate پس از check" -AllowFail | Out-Null
        $checkCode = Run-Python -Args @("manage.py","check") -Step "بررسی دوباره سلامت پروژه" -AllowFail
        if ($checkCode -ne 0) {
            throw "check ناموفق بود. لاگ را بررسی کنید."
        }
    }

    $ports = @(8000, 8001, 8002, 8010)
    $started = $false
    foreach ($port in $ports) {
        Write-Step "تلاش برای اجرای سرور روی پورت $port"
        $stdoutFile = Join-Path $LogDir ("server_" + $port + "_stdout.log")
        $stderrFile = Join-Path $LogDir ("server_" + $port + "_stderr.log")
        if (Test-Path -LiteralPath $stdoutFile) { Remove-Item -LiteralPath $stdoutFile -Force }
        if (Test-Path -LiteralPath $stderrFile) { Remove-Item -LiteralPath $stderrFile -Force }

        $proc = Start-Process -FilePath $PythonExe `
            -ArgumentList ($PythonPrefix + @("manage.py","runserver","127.0.0.1:$port")) `
            -WorkingDirectory $ResolvedProjectRoot `
            -PassThru `
            -RedirectStandardOutput $stdoutFile `
            -RedirectStandardError $stderrFile

        $ok = $false
        for ($i = 0; $i -lt 12; $i++) {
            Start-Sleep -Seconds 1
            try {
                $resp = Invoke-WebRequest -Uri ("http://127.0.0.1:" + $port + "/") -UseBasicParsing -TimeoutSec 2
                if ($resp.StatusCode -ge 200) {
                    $ok = $true
                    break
                }
            }
            catch {
            }

            if ($proc.HasExited) {
                break
            }
        }

        if ($ok) {
            Write-Log "Server started on http://127.0.0.1:$port"
            Start-Process ("http://127.0.0.1:" + $port)
            Write-Host ""
            Write-Host "پروژه اجرا شد: http://127.0.0.1:$port" -ForegroundColor Green
            Write-Host ("لاگ نصب: " + $Global:LogFile) -ForegroundColor Yellow
            Write-Host ("بکاپ فایل‌های قبلی: " + $BackupRoot) -ForegroundColor Yellow
            Write-Host ("لاگ سرور: " + $stdoutFile + " و " + $stderrFile) -ForegroundColor Yellow
            $started = $true
            break
        }
        else {
            try {
                if (-not $proc.HasExited) { $proc.Kill() }
            }
            catch {
            }
            Write-Log "Port $port did not start successfully. Trying next port."
        }
    }

    if (-not $started) {
        throw "سرور روی هیچ‌کدام از پورت‌های پیش‌فرض بالا نیامد."
    }

    exit 0
}
catch {
    Write-Host ""
    Write-Host "خطا: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ("لاگ کامل: " + $Global:LogFile) -ForegroundColor Yellow
    exit 1
}


function StandardCleanup {
    if ($script:logs -eq 0) {
        StandardCleanupNoLogs
    } else {
        StandardCleanupLogs
    }
}

function StandardCleanupNoLogs {
    Clear-Host
    Write-Host "Starting standard cleanup with no logs..."
    Dism.exe /online /cleanup-image /restorehealth
    sfc.exe /scannow
    Write-Host y | chkdsk /f /r /x /b
    shutdown /r /t 0
}

function StandardCleanupLogs {
    Clear-Host
    Write-Host "Starting standard cleanup with logs on desktop log folder..."
    Dism.exe /online /cleanup-image /restorehealth >> C:\Users\$env:USERNAME\Desktop\log\DISM.log
    sfc.exe /scannow >> C:\Users\$env:USERNAME\Desktop\log\SFC.log
    Write-Host y | chkdsk /f /r /x /b 
    shutdown /r /t 0
}

function CreateAdminAccount {
    Clear-Host
    Write-Host "Creating admin account..."
    net user administrator /active:yes
    Write-Host "Switching to admin account..."
    Start-Process powershell -Verb runAs
}

function DisableAdminAccount {
    Clear-Host
    Write-Host "Disabling admin account..."
    net user administrator /active:no
}

function DisableBitLocker {
    Clear-Host
    Write-Host "Disabling BitLocker..."
    manage-bde -off C:
}

function BootOptions {
    Clear-Host
    Write-Host "Boot Options:"
    Write-Host "1) Boot into UEFI settings"
    Write-Host "2) Boot into advanced startup"
    Write-Host "3) Reboot"
    $option = Read-Host "Enter your choice: "
    switch ($option) {
        1 {
            Clear-Host
            Write-Host "Booting into UEFI settings..."
            shutdown /r /fw /t 3
        }
        2 {
            Clear-Host
            Write-Host "Booting into advanced startup..."
            shutdown /r /o /t 3
        }
        3 {
            Clear-Host
            Write-Host "Rebooting..."
            shutdown /r /t 3
        }
    }
}

function ShowOptions {
    Clear-Host
    if ($script:logs -eq 0) {
        Write-Host "Logs turned off!" -ForegroundColor Red
    } else {
        Write-Host "Logs turned on!"  -ForegroundColor Green
    }
    Write-Host "Options:"
    if ($script:logs -eq 0) {
        Write-Host "1) Turn on logs"
    } else {
        Write-Host "1) Turn off logs"
    }
    Write-Host "2) Back to main menu"
    $option = Read-Host "Enter your choice: "
    switch ($option) {
        1 {
            if ($script:logs -eq 0) {
                $script:logs = 1
            } else {
                $script:logs = 0
            }
        }
        2 {
            continue
        }
    }
}

function MainMenu {
    while ($true) {
        Clear-Host
        if ($script:logs -eq 0) {
            Write-Host "Logs turned off!" -ForegroundColor Red
        } else {
            Write-Host "Logs turned on!" -ForegroundColor Green
        }
        Write-Host "Welcome to the Quick Fix Script!"
        Write-Host "1) DISM, SFC, CHKDSK, and reboot"
        Write-Host "2) Create Admin account, and switch to it"
        Write-Host "3) Disable Admin account"
        Write-Host "4) Disable BitLocker"
        Write-Host "5) Boot Options"
        Write-Host "6) Options"
        Write-Host "q) Exit"
        $choice = Read-Host "Enter your choice: "

        switch ($choice) {
            1 {
                StandardCleanup
            }
            2 {
                CreateAdminAccount
            }
            3 {
                DisableAdminAccount
            }
            4 {
                DisableBitLocker
            }
            5 {
                BootOptions
            }
            6 {
                ShowOptions
            }
            'q'{
                Clear-Host
                exit
            }
        }
    }
}


$script:logs = 0
MainMenu

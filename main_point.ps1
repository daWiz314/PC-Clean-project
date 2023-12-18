
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
    Write-Host "4) Back to main menu"
    $option = getKeyPress
    switch ($option) {
        1 {
            Clear-Host
            Write-Host "Booting into UEFI settings..."
            shutdown /r /f /fw /t 3
        }
        2 {
            Clear-Host
            Write-Host "Booting into advanced startup..."
            shutdown /r /f /o /t 3
        }
        3 {
            Clear-Host
            Write-Host "Rebooting..."
            shutdown /r /f /t 3
        }
        4 {
            main_menu
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
    $option = getKeyPress
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

function userControl {
    Clear-Host
    Write-Host "Still working on this..."
    sleep 3
    mainMenu
    Write-Host "Choose a user to select:"
    for ($i = 0; $i -lt $users.Length; $i++) {
        Write-Host "$i) $users[$i]"
    }
    $choice = getKeyPress
    Write-Host "You chose $users[$choice]"
    Write-Host "1) Reset password"
    Write-Host "2) Delete user"
    Write-Host "3) Convert user to local account"
    Write-Host "4) Create new user"
    Write-Host "q) Back to main menu"
    $option = getKeyPress
    switch ($option) {
        1 {
            Clear-Host
            Write-Host "Changing password for $users[$choice]"
            resetUserPassword $users[$choice]
        }
        2 {
            Clear-Host
            Write-Host "Deleting user $users[$choice]"
            net user $users[$choice] /delete
        }
        3 {
            Clear-Host
            Write-Host "Still working on this..."
            userControl
        }
        4 {
            Clear-Host
            Write-Host "Type in a password for the new user:" -ForegroundColor Green
            $password = Read-Host -AsSecureString
            Clear-Host
            Write-Host "Full Name for user:" -ForegroundColor Green
            $fullName = Read-Host
            Clear-Host
            Write-Host "Description for user:" -ForegroundColor Green
            $description = Read-Host
            Clear-Host
            Write-Host "Username for user:" -ForegroundColor Green
            $username = Read-Host
            Clear-Host
            Write-Host "Add to local administrators group? (y/n)" -ForegroundColor Green
            $choice = getKeyPress
            if ($choice -eq 'y') {
                $group = 'Administrators'
            } else {
                $group = 'Users'
            }
            Write-Host "Creating user $username..."
            if ($password -eq $null) {
                New-LocalUser -Name $username -FullName $fullName -Description $description -AccountNeverExpires -Group $group
            } else {
                New-LocalUser -Name $username -FullName $fullName -Description $description -AccountNeverExpires $password -Group $group
            }
            userControl
        }
        "q" {
            mainMenu
        }
    }

    userControl
}

function resetUserPassword {
    param (
        [Parameter(Mandatory=$true)][string]$user
    )
    Clear-Host
    Write-Host "Resetting user password..."
    net user $user *

    userControl
}

function deleteUser {
    param (
        [Parameter(Mandatory=$true)][string]$user
    )
    Clear-Host
    Write-Host "Are you sure you want to delete $user? This action cannot be undone. (y/n)" -ForegroundColor Red
    $choice = getKeyPress
    if ($choice -eq 'n') {
        userControl
    }
    Clear-Host
    Write-Host "Are you really sure you want to delete $user? This action cannot be undone. (y/n)" -ForegroundColor Red -BackgroundColor white
    $choice = getKeyPress
    if ($choice -eq 'n') {
        userControl
    }
    Clear-Host
    Write-Host "Deleting user..."
    net user $user /delete

    userControl
}

function getKeyPress {
    $pressedKey = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $key = $pressedKey.Character
    return $key
}

function MainMenu {
    while ($true) {
       # Clear-Host
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
        Write-Host "7) User Control"
        Write-Host "q) Exit"
        $choice = getKeyPress

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
            7 {
                userControl
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

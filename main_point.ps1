
function confirm {
    param (
        [Parameter(Mandatory=$true)][string]$message
    )
    Clear-Host
    Write-Host $message -ForegroundColor Red
    Write-Host "Are you sure you want to do this? (y/n)" -ForegroundColor Red
    $choice = getKeyPress
    if ($choice -eq 'n') {
        Clear-Host
        return -1
    } elseif ($choice -eq 'y') {
        Clear-Host
        return 1
    } else {
        confirm
    }
}
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
    Write-Host "SHUTTING DOWN IN 10 SECONDS" -ForegroundColor Red
    Start-Sleep 1
    for ($i=9; $i -gt 0; $i--) {
        Clear-Host
        Write-Host "SHUTTING DOWN IN $i SECONDS" -ForegroundColor Red
        Start-Sleep 1
    }
    shutdown /r /t 0
}

function StandardCleanupLogs {
    Clear-Host
    Write-Host "Starting standard cleanup with logs in user account folder"
    Write-Host "Logs will be located in C:\Users\$env:USERNAME\log"
    Write-Host "Running DISM" -ForegroundColor Green
    Write-Host "DO NOT CLOSE THIS WINDOW" -ForegroundColor Red
    Dism.exe /online /cleanup-image /restorehealth >> C:\Users\$env:USERNAME\log\DISM.log
    Write-Host "Running SFC" -ForegroundColor Green
    Write-Host "DO NOT CLOSE THIS WINDOW" -ForegroundColor Red
    sfc.exe /scannow >> C:\Users\$env:USERNAME\log\SFC.log
    Write-Host y | chkdsk /f /r /x /b 
    Write-Host "Running CHKDSK" -ForegroundColor Green
    Write-Host "SHUTTING DOWN IN 10 SECONDS" -ForegroundColor Red
    Start-Sleep 1
    for ($i=9; $i -gt 0; $i--) {
        Clear-Host
        Write-Host "SHUTTING DOWN IN $i SECONDS" -ForegroundColor Red
        Start-Sleep 1
    }
    shutdown /r /t 0
    getkeyPress
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
                mkdir C:\Users\$env:USERNAME\log
            } else {
                $script:logs = 0
            }
        }
        2 {
            continue
        }
    }
}

function getListOfUsers {
    [System.Collections.ArrayList]$users = net user | Select-String -Pattern "^[A-Za-z0-9]" | Select-Object -ExpandProperty Line | ForEach-Object { $_.Trim() }
    #remove the spaces from in-between the users
    #For some reason the list will contain the users like USER1             USER2, so we want to get rid of all that extra space
    $users = $users -split '  '
    $users = $users | Where-Object { $_ -ne "" }
    $users.RemoveAt(0)
    $users.RemoveAt($users.Count-1)
    $users = foreach ($_ in $users) { $_.Trim()}
    return $users
}

function selectUser {
    Clear-Host
    $users = getListOfUsers
    Write-Host "Choose a user:"
    for($i=0; $i -lt $users.count; $i++) {
        Write-Host $i")" $users[$i]
    }
    Write-Host "q) Back"
    $choice = Read-Host "Enter a number"
    if ($choice -eq 'q') {
        return
    }
    Write-Host "You chose: " $users[$choice]
    Start-Sleep 1.5
    Clear-Host
    return $users[$choice]
}

function resetPassword {
    Clear-Host
    $user = selectUser
    $result = confirm("Resetting password for user: "+$user)
    if ($result -eq 1) {
        net user $user *
    } else {
        return
    }
}

function deleteUser {
    Clear-Host
    $user = selectUser
    $result = confirm("Deleting user: "+$user)
    if ($result -eq 1) {
        $result2 = confirm("CONFIRM THE ACTION: Deleting user: "+$user)
        if ($result2 -eq 1) {
            net user $user /delete
            Start-Sleep 1.5
        } else {
            return
        }
    } else {
        return
    }
}

function createNewUser {
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
    $result = confirm("Add to local administrators group?")
    if ($result -eq 1) {
        $group = 'Administrators'
    } else {
        $group = 'Users'
    }
    Write-Host "Creating user $username..."
    if ($password) {
        New-LocalUser -Name $username -FullName $fullName -Description $description -AccountNeverExpires -NoPassword
    } else {
        New-LocalUser -Name $username -FullName $fullName -Description $description -AccountNeverExpires $password
    }

    if ($group -eq 'Administrators') {
        Add-LocalGroupMember -Group "Administrators" -Member $username
    }
    Start-Sleep 1.5
    return

}

function userControl {
    Clear-Host
    Write-Host "User Control" -ForegroundColor Green
    Write-Host "Choose an option:"
    Write-Host "1) Reset password"
    Write-Host "2) Delete user"
    Write-Host "3) Convert user to local account"
    Write-Host "4) Create new user"
    Write-Host "q) Back to main menu"
    $option = getKeyPress
    switch ($option) {
        1 {
            resetPassword
        }
        2 {
            deleteUser
        }
        3 {
            Clear-Host
            Write-Host "Still working on this..."
            userControl
        }
        4 {
            createNewUser
        }
        "q" {
            mainMenu
        }
    }

    userControl
}

function getKeyPress {
    $pressedKey = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $key = $pressedKey.Character
    return $key
}

function MainMenu {
    while ($true) {
        Clear-Host
        if ($script:logs -eq 0) {
            Write-Host "Logs turned off!" -ForegroundColor darkRed
        } else {
            Write-Host "Logs turned on!" -ForegroundColor darkGreen
        }
        Write-Host "Welcome to the Quick Fix Script!" -ForegroundColor Blue
        Write-Host "Main Menu" -ForegroundColor Green
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

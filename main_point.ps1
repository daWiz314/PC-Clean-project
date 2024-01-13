

$VERSION = "1.0.7"

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

# Count down function to streamline the code

function countdown {
    param (
        [Parameter(Mandatory=$true)][int]$seconds,
        [Parameter(Mandatory=$true)][string]$message
    )
    Clear-Host
    Write-Host $message " IN " $seconds " SECONDS" -ForegroundColor Red
    Start-Sleep 1
    for ($i=$seconds-1; $i -gt 0; $i--) {
        Clear-Host
        Write-Host $message " IN " $i " SECONDS" -ForegroundColor Red
        Start-Sleep 1
    }
    return # To actually do the thing in $i seconds
}

function StandardCleanup {
    if ($script:logs -eq 0) {
        StandardCleanupNoLogs
    } else {
        StandardCleanupLogs
    }
}

function sfc_log {
    $container = sfc.exe /scannow
    #Splits them into groups
    $container = $container -split " "
    $newContainer = [System.Collections.ArrayList]::new()
    foreach ($group in $container) {
        # If it actually contains letters, numbers, or symbols, then we want to split it up
        if ($group -match '[\s+a-z+0-9+.+%+/-]') {
            $group = $group -split ""
            foreach ($letter in $group) {
                # For every letter that is NOT a space, add it to the array
                if ($letter -match '[\a-z+0-9+.+%+/-]') {
                    $newContainer.Insert($newContainer.Count, $letter)
                    continue
                }           
            }
            #Add a space after each letter
            $newContainer.Insert($newContainer.Count, " ")
        } else {
            continue
        }
    } 

    #Output it to a file

    for ($i=0; $i -lt $newContainer.Count; $i++) {
        if ($newContainer[$i] -eq ".") {
            Out-File C:\Users\$env:USERNAME\log\sfc.txt -InputObject $newContainer[$i] -Append
        } else {
            Out-File C:\Users\$env:USERNAME\log\sfc.txt -InputObject $newContainer[$i] -Append -NoNewline
        }
    }
}

function StandardCleanupNoLogs {
    Clear-Host
    Write-Host "Starting standard cleanup with no logs..."
    Dism.exe /online /cleanup-image /restorehealth
    sfc.exe /scannow
    echo y | chkdsk C: /f /r /x /b
    countdown(10, "SHUTTING DOWN")
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
    echo y | chkdsk C: /f /r /x /b 
    Write-Host "Running CHKDSK" -ForegroundColor Green
    countdown(10, "SHUTTING DOWN")
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
            countdown(3, "Booting into UEFI Settings")
            shutdown /r /f /fw /t 00
        }
        2 {
            Clear-Host
            countdown(3, "Booting into Advanced Startup")
            shutdown /r /f /o /t 00
        }
        3 {
            Clear-Host
            countdown(3, "Rebooting")
            shutdown /r /f /t 00
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

function create_folders {
    mkdir C:\Users\$env:USERNAME\log
}

function getListOfUsers {
    [System.Collections.ArrayList]$users = net user | Select-String -Pattern "^[A-Za-z0-9]" | Select-Object -ExpandProperty Line | ForEach-Object { $_.Trim() }
    #remove the spaces from in-between the users
    #For some reason the list will contain the users like USER1     (bunch of spaces here in case you can't tell)        USER2, so we want to get rid of all that extra space
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
    Start-Sleep 1
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
            Try {
                net user $user /delete
            } Catch {
                Write-Host "Unable to delete user!" -ForegroundColor Red
                Start-Sleep 1.5
                return
            }
            Write-Host "User deleted!" -ForegroundColor Green
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
    Write-Host "3) Create new user"
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
        Write-Host "Main Menu "$VERSION -ForegroundColor Green
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

$ui.WindowTitle = "Quick Fix Script"

$script:logs = 1
create_folders
MainMenu



$VERSION = "1.0.10"
$LOGSPATH = ""

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

    $time = Get-Date -Format "HH:mm:ss"
    #Output it to a file
    Out-File $LOGSPATH\sfc.txt -InputObject "Starting SFC at: $time" -Append

    for ($i=0; $i -lt $newContainer.Count; $i++) {
        if ($newContainer[$i] -eq ".") {
            Out-File $LOGSPATH\sfc.txt -InputObject $newContainer[$i] -Append
        } else {
            Out-File $LOGSPATH\sfc.txt -InputObject $newContainer[$i] -Append -NoNewline
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
    Write-Host "Logs will be located in C:\Users\$env:USERNAME\logs"
    Write-Host "Running DISM" -ForegroundColor Green
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "Current Time: "
    Write-Host "DO NOT CLOSE THIS WINDOW" -ForegroundColor Red
    Out-File $LOGSPATH\DISM.txt -InputObject "Time Started $time" -Append
    Dism.exe /online /cleanup-image /restorehealth >> $LOGSPATH\DISM.txt
    Write-Host "Running SFC" -ForegroundColor Green
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "Current Time: "
    Write-Host "DO NOT CLOSE THIS WINDOW" -ForegroundColor Red
    sfc_log
    echo y | chkdsk C: /f /r /x /b 
    Write-Host "Running CHKDSK" -ForegroundColor Green
    countdown(10, "SHUTTING DOWN")
    shutdown /r /t 0
    getkeyPress
}

function CreateAdminAccount {
    Clear-Host
    Write-Host "Creating admin account..."
    Try {
        net user administrator /active:yes
    } Catch {
        Write-Host "Unable to create admin account!" -ForegroundColor Red
        Start-Sleep 1.5
        return
    }
    Write-Host "Switching to admin account..."
    Start-Process powershell -Verb runAs
    Start-Sleep 1.5
    return
}

function DisableAdminAccount {
    Clear-Host
    Write-Host "Disabling admin account..."
    Try {
        net user administrator /active:no
    } Catch {
        Write-Host "Unable to disable admin account!" -ForegroundColor Red
        Start-Sleep 1.5
        return
    }
    Write-Host "Admin account disabled!" -ForegroundColor Green
    Start-Sleep 1.5
    return
}

function DisableBitLocker {
    Clear-Host
    Write-Host "Disabling BitLocker..."
    Try {
        manage-bde -off C:
    } Catch {
        Write-Host "Unable to disable BitLocker!" -ForegroundColor Red
        Start-Sleep 1.5
        return
    }
    Write-Host "BitLocker disabled!" -ForegroundColor Green
    Start-Sleep 1.5
    return
    
}

function BootOptions {
    Clear-Host
    Write-Host "Boot Options:" -ForegroundColor Green
    Write-Host "1) Boot into UEFI settings"
    Write-Host "2) Boot into advanced startup"
    Write-Host "3) Reboot"
    Write-Host "q) Back to main menu"
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
        "q" {
            main_menu
        }
    }
}

function ShowOptions {
    Clear-Host
    if ($logs -eq 0) {
        Write-Host "Logs turned off!" -ForegroundColor Red
    } else {
        Write-Host "Logs turned on!"  -ForegroundColor Green
    }
    Write-Host "Options" -ForegroundColor Green
    if ($logs -eq 0) {
        Write-Host "1) Turn on logs"
    } else {
        Write-Host "1) Turn off logs"
    }
    Write-Host "2) Back to main menu"
    $option = getKeyPress
    switch ($option) {
        1 {
            if ($logs -eq 0) {
                
                $logs = create_folders

            } else {
                $logs = 0
            }
        }
        2 {
            continue
        }
    }
}

function create_folders {
    if (Test-Path -Path C:\Users\$env:USERNAME\logs) {
        $date = Get-Date -Format "MM-dd-yyyy"
        if (Test-Path -Path C:\Users\$env:USERNAME\logs\$date) {
            Try {
                $time = Get-Date -Format "HH_mm_ss"
                mkdir C:\Users\$env:USERNAME\logs\$date\$time
                $LOGSPATH = "C:\Users\$env:USERNAME\logs\$date\$time"
                return 1
            } Catch {
                Write-Host "Unable to create log folder!" -ForegroundColor Red
                Start-Sleep 1.5
                return 0
        }
    }
            Try {
                mkdir C:\Users\$env:USERNAME\logs\$date
                create_folders
            } Catch {
                Write-Host "Unable to create log folder!" -ForegroundColor Red
                Start-Sleep 1.5
                return 0
            }
        } else {
            Try {
                mkdir C:\Users\$env:USERNAME\logs
                create_folders
            } Catch {
            Write-Host "Unable to create log folder!" -ForegroundColor Red
            Start-Sleep 1.5
            return 0
            }
        }
}

function recoverDeletedUsersFolders {
    Clear-Host "Still working on this!"
    Start-Sleep 1.5
    return
    [Parameter(Mandatory=$true)][string]$user
    Start-Sleep 2
    $choice = confirm("Copy deleted user: " +$user+ " folders?")
    if ($choice -eq 1) {
        Clear-Host
        Write-Host "Copying deleted user: "$user  " folders"
        $path = "C:\Users\$user"
        $dest = "C:\Users\$env:USERNAME\$user"
        Try {
            $i = 0
            while ($true) {
                $i++
                if (Test-Path -Path $dest) {
                    $dest = "C:\Users\$env:USERNAME\$user$i"
                    continue
                } else {
                    break
                    Write-Host "In Loop"
                    
                }
            }
            mkdir $dest
        } catch {
            Write-Host "Unable to create folder to move data to!" -ForegroundColor Red
            Start-Sleep 1.5
            return
        }
        
        Try {
            robocopy $path $dest /MIR /R:1 /W:1 /MT:128 /log:$LOGSPATH\$user.txt /j
            Try {
                Remove-Directory -r -force -$path

            } catch {
                Write-Host "Unable to delete " $user " folder!" -ForegroundColor Red
                Start-Sleep 1.5
                return
            }
        } Catch {
            Write-Host "Unable to copy users folders!" -ForegroundColor Red
            Start-Sleep 1.5
            return
        }
    }
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
        Try {
            net user $user *
        } Catch {
            Write-Host "Unable to reset password!" -ForegroundColor Red
            Start-Sleep 1.5
            return
        }
        Write-Host "Password reset!" -ForegroundColor Green
        Start-Sleep 1.5
        return
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
            Start-Sleep .5
            Clear-Host
            recoverDeletedUsersFolders($user)
        } else {
            return
        }
    } else {
        return
    }
}

function createNewUser {
    Clear-Host
    Write-Host "Username for user:" -ForegroundColor Green
    $username = Read-Host
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
    $result = confirm("Add to local administrators group?")
    if ($result -eq 1) {
        $group = 'Administrators'
    } else {
        $group = 'Users'
    }
    Write-Host "Creating user $username..."
    Try {
        if ($password) {
            New-LocalUser -Name $username -FullName $fullName -Description $description -AccountNeverExpires -NoPassword
        } else {
            New-LocalUser -Name $username -FullName $fullName -Description $description -AccountNeverExpires $password
        }
    } Catch {
        Write-Host "Unable to create user!" -ForegroundColor Red
        Start-Sleep 1.5
        return
    }

    Try {
        if ($group -eq 'Administrators') {
            Add-LocalGroupMember -Group "Administrators" -Member $username
        }
    } catch {
        Write-Host "Unable to add user to Administrators group!" -ForegroundColor Red
        Start-Sleep 1.5
        return
    }

    Write-Host "User created!" -ForegroundColor Green
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


# Resets the windows update folders related to it.
function resetWindowsUpdate {
    Clear-Host
    Write-Host "Resetting Windows Update" -ForegroundColor Green
    Write-Host "Please wait..." -ForegroundColor Red
    # Stopping update services
    Stop-Service -Name BITS -Force
    Stop-Service -Name wuauserv -Force
    Stop-Service -Name cryptsvc -Force

    # Removing folders with update data
    Remove-Item -Path "$env:systemroot\SoftwareDistribution" -ErrorAction SilentlyContinue -Recurse
    Remove-Item -Path "$env:systemroot\System32\Catroot2" -ErrorAction SilentlyContinue -Recurse

    # Reset Win Sock
    netsh winsock reset

    # Restarting 
    Start-Service -Name BITS 
    Start-Service -Name wuauserv 
    Start-Service -Name cryptsvc

    # Finished, explain to user
    Clear-Host
    Write-Host "Windows Update reset!" -ForegroundColor Green
    Start-Sleep 1.5
    return
}

function removeDefaultPackages {
    Clear-Host
		Clear-Host
		Write-Host "Still under construction" -ForegroundColor Red
		Start-Sleep 1.5
		return
    Write-Host "Deleting default packages" -ForegroundColor Green
    Write-Host "Please wait..." -ForegroundColor Red

    # Removing default packages
    Get-AppxPackage -AllUsers | Remove-AppxPackage

    # Finished, explain to user
    Clear-Host
    Write-Host "Default packages removed!" -ForegroundColor Green
    Start-Sleep 1.5
    return
}

class FindPackage {
    [string]$name
    [string]$id
    [bool]$checked
    Package([string]$name, [string]$id, [bool]$checked) {
        $this.name = $name
        $this.id = $id
        $this.checked = $checked
    }
    [void] toggle() {
        if ($this.checked) {
            $this.checked = $false
        } else {
            $this.checked = $true
        }
    }
}


function reinstallBasicPackages {
		Clear-Host
		Write-Host "Still under construction" -ForegroundColor Red
		Start-Sleep 1.5
		return
    Clear-Host
    Write-Host "Please select which packages to install:" -ForegroundColor Green
    $selector = 0

    $packages = @(FindPackage("Windows Camera"), FindPackage("Photos"))
}



# Settings for new setups or for existing set ups
# To be added onto in the future
# 1) Will reset the windows update that sometimes bugs out with updates. It will reset the folders related and reset the service involved
# 2) Removes all the default packages, usually noted as bloatware, downside is it removes camera, calculator, photos, and other general use items as well
# 3) Reinstalls the basic packages that are removed from option 2, but will present it as a list

function newSetUpSettings {
    Clear-Host
    Write-Host "This is still being worked on, come back later!" -ForegroudColor -Red
    Write-Host "New Setup Settings / OS Settings" -ForegroundColor Green
    Write-Host "Choose an option:"
    Write-Host "1) Reset Windows Update"
    Write-Host "2) Remove all default preinstalled packages"
    Write-Host "3) Reinstall basic packages (Camera, Calculator, etc.)"
    Write-Host "q) Back to main menu"
    $option = getKeyPress
    switch ($option) {
        1 {
            resetWindowsUpdate
        }
        2 {
            removeDefaultPackages
        }
        3 {
            reinstallBasicPackages
        }
        "q" {
            mainMenu
        }
    }
}



function getKeyPress {
    $pressedKey = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $key = $pressedKey.Character
    return $key
}

function MainMenu {
    while ($true) {
        Clear-Host
        if ($logs -eq 0) {
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
        Write-Host "8) New Setup Settings / OS Settings"
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
            8 {
                newSetUpSettings
            }
            'q'{
                Clear-Host
                exit
            }
        }
    }
}


# Causes issues.
#$ui.WindowTitle = "Quick Fix Script"

$LOGS = create_folders
MainMenu


#Test change to verify git is working

$VERSION = "1.1.1"
$LOGSPATH = ""
# Website for the script
$website = "dawiz314.github.io"

class bitlockerDrive {
    [string]$driveLetter
    [bool]$lockStatus
    [string]$encryptionPercentage

    bitlockerDrive([string]$driveLetter, [bool]$lockStatus, [string]$encryptionPercentage) {
        $this.driveLetter = $driveLetter
        $this.lockStatus = $lockStatus
        $this.encryptionPercentage = $encryptionPercentage
    }
}

function getKeyPress {
    $pressedKey = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $key = $pressedKey.Character
    return $key
}

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

# function to get change log and read it
function changeLog {
    Clear-Host
    $log = "C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\change_log.txt"
    irm $website/patch_notes.txt > $log
    Get-Content -Path $log -Raw | more
    getKeyPress
}


function StandardCleanup {
    if ($Global:LOGSPATH -eq 0) {
        StandardCleanupNoLogs
    } else {
        StandardCleanupLogs
    }
}

function sfc_log {
    sfc.exe /scannow | Tee-Object -Variable container
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

    $log = $LOGSPATH[2]
    $time = Get-Date -Format "HH:mm:ss"
    #Output it to a file
    Out-File $log\sfc.txt -InputObject "Starting SFC at: $time" -Append
    
    for ($i=0; $i -lt $newContainer.Count; $i++) {
        if ($newContainer[$i] -eq ".") {
            Out-File $log\sfc.txt -InputObject $newContainer[$i] -Append
        } else {
            Out-File $log\sfc.txt -InputObject $newContainer[$i] -Append -NoNewline
        }
    }
}

function checkdisk_no_log {
    foreach($drive in $Global:unlockedDrives) {
        echo y | chkdsk $drive.driveLetter /f /r /x /b
    }
}

function checkdisk_log {
    $log = $Global:LOGSPATH[2]
    echo $log
    getKeyPress
    $time = Get-Date -Format "HH:mm:ss"
    Out-File $log\chkdsk.txt -InputObject "Starting CHKDSK at: $time" -Append
    foreach($drive in $Global:unlockedDrives) {
        Out-File $log\chkdsk.txt -InputObject ("Running CHKDSK on drive: " + [String]$drive.driveLetter) -Append
        echo y | chkdsk $drive.driveLetter /f /r /x /b | Tee-Object -FilePath $log\chkdsk.txt
    }
    #echo y | chkdsk C: /f /r /x /b | Tee-Object -FilePath $log\chkdsk.txt
}
function StandardCleanupNoLogs {
    Clear-Host
    Write-Host "Starting standard cleanup with no logs..."
    Dism.exe /online /cleanup-image /restorehealth
    sfc.exe /scannow
    checkdisk_no_log
    countdown -seconds 10 -message "SHUTTING DOWN"
    shutdown /f /r /t 0
}

function StandardCleanupLogs {
    Clear-Host
    if ($LOGSPATH = 0) {
        StandardCleanupNoLogs
    }
    $log = $Global:LOGSPATH[2]
    Write-Host "Starting standard cleanup with logs in user account folder"
    Write-Host "Logs will be located in " $log
    Write-Host "Running DISM" -ForegroundColor Green
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "Current Time: $time"
    Write-Host "DO NOT CLOSE THIS WINDOW" -ForegroundColor Red
    Out-File $log\DISM.txt -InputObject "Time Started $time" -Append
    Dism.exe /online /cleanup-image /restorehealth | Tee-Object -FilePath $log\DISM.txt
    Write-Host "Running SFC" -ForegroundColor Green
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "Current Time: $time"
    Write-Host "DO NOT CLOSE THIS WINDOW" -ForegroundColor Red
    sfc_log
    # echo y | chkdsk C: /f /r /x /b 
    Write-Host "Running CHKDSK" -ForegroundColor Green
    checkdisk_log
    getkeypress
    countdown -seconds 10 -message "SHUTTING DOWN"
    shutdown /f /r /t 0
    getkeyPress
}

function CreateAdminAccount {
    Clear-Host
    Write-Host "Activating admin account..."
    Try {
        net user administrator /active:yes
    } Catch {
        Write-Host "Unable to activate admin account!" -ForegroundColor Red
        Start-Sleep 1.5
        return
    }
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

function bitlocker_helper {
    $container = fsutil.exe fsinfo drives
    $container = $container -split ":"
    $container = ($container | Where-Object {$_ -match "\s\w"}) -replace "\\", ""
    Clear-Host

    $bitlockerDrives = @()
    
    foreach ($drive in $container.trim()) {
        $container2 = manage-bde.exe $drive":" -status
        $container2 = $container2 -split "\n"
        $lock_status = $container2 | Where-Object {$_ -match "Lock Status"}
        if ($lock_status -match "Unlocked") {
            $lock_status = $false
        } else {
            $lock_status = $true
        }
        $encryption_percentage = $container2 | Where-Object {$_ -match "Percentage Encrypted"}
        $encryption_percentage = $encryption_percentage -replace ".*:\s", ""
    
        $bitlockerDrives += [bitlockerDrive]::new($drive+":", $lock_status, $encryption_percentage)
    }
    
    $Global:lockedDrives = @()
    $Global:unlockedDrives = @()

    foreach ($drive in $bitlockerDrives) {
        if ($drive.lockStatus -eq $true) {
            $Global:lockedDrives += $drive
        } else {
            $Global:unlockedDrives += $drive
        }
    }
}
function bitlocker {
    Clear-Host
    bitlocker_helper
    Write-Host "BitLocker" -ForegroundColor Green
    Write-Host "Locked Drives: " -NoNewline
    foreach ($drive in $Global:lockedDrives) {
        Write-Host $drive.driveLetter -NoNewline
        Write-Host " " -NoNewline
    }
    Write-Host ""
    Write-Host "Unlocked Drives: " -NoNewline
    foreach ($drive in $Global:unlockedDrives) {
        Write-Host $drive.driveLetter -NoNewline
        Write-Host " " -NoNewline
    }
    Write-Host ""
    if ($Global:lockedDrives.count -eq 0) {
        Write-Host "No locked drives!" -ForegroundColor Green
        Start-Sleep 1.5
        return
    }
    Write-Host "Unlock any drives? (y/n)"
    $choice = getKeyPress
    if ($choice -eq 'y') {
        unlockDrive($Global:lockedDrives)
    } else {
        return
    }
}

function unlockDrive {
    param (
        [Parameter(Mandatory=$true)][bitlockerDrive[]]$bitlockerDrives
    )
    while ($true) {
        Clear-Host
        Write-Host "Choose a drive to unlock:"
        for ($i=0; $i -lt $bitlockerDrives.count; $i++) {
            Write-Host "$i)" $bitlockerDrives[$i].driveLetter
        }
        Write-Host "q) Main Menu"
        $choice = Read-Host ">"
        if ($choice -eq 'q') {
            MainMenu
        } 
        if ([int]$choice -lt $bitlockerDrives.count-1) {
            Write-Host "Attempting to unlock drive: " $bitlockerDrives[$choice].driveLetter
            manage-bde.exe $bitlockerDrives[[int]$choice].driveLetter"-off"
            Write-Host "Press any key to continue..."
            getKeyPress
            MainMenu
        } else {
            Write-Host "Invalid choice!" -ForegroundColor Red
            Write-Host "Please try again!" -ForegroundColor Red
            Start-Sleep 1
            continue
        }
    }
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
            countdown -seconds 3 -message "Booting into UEFI Settings"
            shutdown /r /f /fw /t 00
        }
        2 {
            Clear-Host
            countdown -seconds 3 -message "Booting into Advanced Startup"
            shutdown /r /f /o /t 00
        }
        3 {
            Clear-Host
            countdown -seconds 3 -message "Rebooting"
            shutdown /r /f /t 00
        }
        "q" {
            MainMenu
        }
    }
}

function ShowOptions {
    Clear-Host
    $logs = $LOGSPATH[1]
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
    Write-Host "2) Clear this scripts data and recreate folder"
    Write-Host "3) Clear all data and DO NOT recreate it"
    Write-Host "q) Back to main menu"
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
            clear_logs
        }
        3 {
            full_clear_logs
        }
        'q' {
            MainMenu
        }
    }
}

function clear_logs {
    Clear-Host
    Remove-Item -r "C:\Users\$env:USERNAME\AppData\Local\temp\pc_cleanup"
    $Global:LOGSPATH = create_folders
    Write-Host "Logs cleared!" -ForegroundColor Green
    Start-Sleep 1.5
    return
}

function full_clear_logs {
    Clear-Host
    Remove-Item -r "C:\Users\$env:USERNAME\AppData\Local\temp\pc_cleanup"
    Write-Host "All data cleared!" -ForegroundColor Green
    $Global:LOGSPATH = 0
    Start-Sleep 1.5
    return

}

function create_folders {
    # New log file location
    # C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\logs
    $LOGSPATH = ""
    if (Test-Path -Path C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup) {
        $date = Get-Date -Format "MM-dd-yyyy"
        if (Test-Path -Path C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\logs\$date) {
            Try {
                $time = Get-Date -Format "HH_mm_ss"
                mkdir C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\logs\$date\$time
                $LOGSPATH = "C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\logs\$date\$time"
                return (1, $LOGSPATH)
            } Catch {
                Write-Host "Unable to create log folder!" -ForegroundColor Red
                Start-Sleep 1.5
                return (0, $LOGSPATH)
        }
    }
            Try {
                mkdir C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\logs\$date
                create_folders
            } Catch {
                Write-Host "Unable to create log folder!" -ForegroundColor Red
                Start-Sleep 1.5
                return (0, $LOGSPATH)
            }
        } else {
            Try {
                mkdir C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\logs
                create_folders
            } Catch {
            Write-Host "Unable to create log folder!" -ForegroundColor Red
            Start-Sleep 1.5
            return (0, $LOGSPATH)
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
            robocopy $path $dest /MIR /R:1 /W:1 /MT:128 /log:$LOGSPATH[1]\$user.txt /j
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
    if ([int]$choice -lt 0 -or [int]$choice -gt $users.count) {
        Write-Host "Invalid choice!" -ForegroundColor Red
        Start-Sleep 1.5
        selectUser
    }
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
    Write-Host "1) Create new user"
    Write-Host "2) Reset password"
    Write-Host "3) Delete user"
    Write-Host "q) Back to main menu"
    $option = getKeyPress
    switch ($option) {
        1 {
            createNewUser
        }
        2 {
            resetPassword
        }
        3 {
            deleteUser
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



# Settings for new setups or for existing set ups
# To be added onto in the future
# 1) Will reset the windows update that sometimes bugs out with updates. It will reset the folders related and reset the service involved

function newSetUpSettings {
    Clear-Host
    Write-Host "This is still being worked on, come back later!" -ForegroudColor Red
    Write-Host "New Setup Settings / OS Settings" -ForegroundColor Green
    Write-Host "Choose an option:"
    Write-Host "1) Reset Windows Update"
    Write-Host "2) Change Time Zone"
    Write-Host "q) Back to main menu"
    $option = getKeyPress
    switch ($option) {
        1 {
            resetWindowsUpdate
        }
        2 {
            changeTimeZone
        }
        "q" {
            mainMenu
        }
    }
}

# Function for changing time zone, only adding US based ones for now, will add more later.
#TODO: Add more time zones
function changeTimeZone {
    Clear-Host
    Write-Host "Change Time Zone" -ForegroundColor Green
    Write-Host "Choose a time zone:"
    Write-Host "1) Eastern Time"
    Write-Host "2) Central Time"
    Write-Host "3) Mountain Time"
    Write-Host "4) Pacific Time"
    Write-Host "q) Back to main menu"
    $option = getKeyPress
    switch ($option) {
        1 {
            Set-TimeZone -Id "Eastern Standard Time"
        }
        2 {
            Set-TimeZone -Id "Central Standard Time"
        }
        3 {
            Set-TimeZone -Id "Mountain Standard Time"
        }
        4 {
            Set-TimeZone -Id "Pacific Standard Time"
        }
        "q" {
            mainMenu
        }
    }
    # TODO:
        # Add error catching here
    W32tm.exe /resync /force
    return
}


function MainMenu {
    while ($true) {
        Clear-Host
        if ($LOGSPATH[1] -eq 0) {
            Write-Host "Logs turned off!" -ForegroundColor darkRed
        } else {
            Write-Host "Logs turned on!" -ForegroundColor darkGreen
        }
        Write-Host "Welcome to the Quick Fix Script!" -ForegroundColor Blue
        Write-Host "Main Menu "$VERSION -ForegroundColor Green
        Write-Host "1) DISM, SFC, CHKDSK, and reboot"
        Write-Host "2) Create Admin account, and switch to it"
        Write-Host "3) Disable Admin account"
        Write-Host "4) BitLocker"
        Write-Host "5) Boot Options"
        Write-Host "6) Options"
        Write-Host "7) User Control"
        Write-Host "8) New Setup Settings / OS Settings"
        Write-Host "9) Patch Notes"
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
                BitLocker
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
            9 {
                changeLog
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

$Global:LOGSPATH = create_folders
bitlocker_helper
MainMenu

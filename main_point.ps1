
#Test change to verify git is working

$VERSION = "1.1.2"
$LOGSPATH = ""
$LASTRUN_PATH = ""
# Website for the script
$website = "dawiz314.github.io"


function add_lines {
    # Parameters
    param (
        [Parameter(Mandatory=$true)][int]$lines
    )
    for($i=0; $i -lt $lines; $i++) {
        Write-Host
    }

}

function add_spaces {
    # Parameters
    param (
        [Parameter(Mandatory=$true)][int]$spaces
    )
    $test = "";
    for($i=0; $i -lt $spaces; $i++) {
        $test += " "
    }
    return $test

}

function display_message {
    # Parameters
    param (
        [Parameter(Mandatory=$true)][string[]]$messages,
        [Parameter(Mandatory=$false)][int]$top=1,
        [Parameter(Mandatory=$false)][int]$selection=$top+1
    )
    Clear-Host
    add_lines -lines (($Host.UI.RawUI.WindowSize.Height/2)-$messages.Length + 1)
    foreach($message in $messages) {
        if ($selection -eq $messages.IndexOf($message)) {
            $spaces = add_spaces -spaces (($Host.UI.RawUI.WindowSize.Width/2)-($message.Length/2))
            Write-Host $spaces -NoNewLine
            Write-Host $message.Trim() -BackgroundColor White -ForegroundColor Black
        } else {
            $spaces = add_spaces -spaces (($Host.UI.RawUI.WindowSize.Width/2)-($message.Length/2))
            Write-Host $spaces$message
        }
    }
    add_lines -lines (($Host.UI.RawUI.WindowSize.Height/2)-$messages.Length)
    $key = detectKeyPress
    if ($key -eq "up") {
        if ($selection -gt $top+1) {
            $selection--
        } else {
            $selection = $messages.Length - 1
        }
    } elseif ($key -eq "down") {
        if ($selection -lt ($messages.Length - 1)) {
            $selection++
        } else {
            $selection = $top+1
        }
    } elseif ($key -eq "enter") {
        return $selection
    }
    display_message -messages $messages -selection $selection
}

function display_single_message {
    # Parameters
    param (
        [Parameter(Mandatory=$true)][string]$message
    )
    Clear-Host
    add_lines -lines (($Host.UI.RawUI.WindowSize.Height/2)-1)
    $spaces = add_spaces -spaces (($Host.UI.RawUI.WindowSize.Width/2)-($message.Length/2))
    Write-Host $spaces$message
    add_lines -lines (($Host.UI.RawUI.WindowSize.Height/2)-1)

}

# Detect key press
# 38 = Up arrow
# 40 = Down arrow
# 37 = Left arrow
# 39 = Right arrow
# 13 = Enter
function detectKeyPress {
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    switch ($key.VirtualKeyCode) {
        38 {
            return "up"
        }
        40 {
            return "down"
        }
        37 {
            return "left"
        }
        39 {
            return "right"
        }
        13 {
            return "enter"
        }
        81 {
            return "q"
        }
    }
    detectKeyPress

}
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

# Need to fix this so it can read all drives, and stop erroring out
function bitlocker_helper {
    $container = fsutil.exe fsinfo drives
    $container = $container -split ":"
    $container = ($container | Where-Object {$_ -match "\s\w"}) -replace "\\", ""
    Clear-Host

    $Global:bitlockerDrives = @()
    
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
    
        $Global:bitlockerDrives += ([bitlockerDrive]::new(($drive + ":"),$lock_status, [string]$encryption_percentage))
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
            main_menu
        } 
        if ([int]$choice -lt $bitlockerDrives.count-1) {
            Write-Host "Attempting to unlock drive: " $bitlockerDrives[$choice].driveLetter
            manage-bde.exe $bitlockerDrives[[int]$choice].driveLetter"-off"
            manage-bde.exe $bitlockerDrives[[int]$choice].driveLetter"-unlock"
            Write-Host "Press any key to continue..."
            getKeyPress
            unlockDrive
        } else {
            Write-Host "Invalid choice!" -ForegroundColor Red
            Write-Host "Please try again!" -ForegroundColor Red
            Start-Sleep 1
            continue
        }
    }
}

function getKeyPress {
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return $key.Character
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
        confirm -message $message
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
    try {
        irm $website/patch_notes.txt > $log
    }
    catch {
        Write-Host "Unable to get patch notes!" -ForegroundColor Red
        Start-Sleep 1.5
        return
    }
    Get-Content -Path $log -Raw | more
    Write-Host "Press any key to continue..."
    getKeyPress
}

function fix_drives {
    Clear-Host
    display_single_message -message "Fixing drives..."
    $drives_run_on = checkdisk_no_log -runOnBootDrive $false
    if ($drives_run_on -eq $null) {
        display_single_message -message "No drives to fix!"
        Start-Sleep 1.5
    } else {
        display_single_message -message ("Ran on drives: " + $drives_run_on)
        Start-Sleep 1.5
    }
    Write-Host "Press any key to continue..."
    getKeyPress
    return

}

function repair_menu {
    $messages = @("Repair Menu", "Choose an option:", "DISM/SFC/CHKDSK", "Fix Drives", "Back to main menu")
    switch((display_message -messages $messages -selection 2)-1) {
        1 {
            standard_clean_up
        }
        2 {
            fix_drives
        }
        3 {
            main_menu
        }
    }

}

function standard_clean_up {
    $messages = @("Standard Cleanup", "Choose an option:", "Without source", "With source", "Back to main menu")
    switch((display_message -messages $messages -selection 2)-1) {
        1 {
            if ($Global:LOGSPATH -eq 0) {
                StandardCleanupNoLogs
            } else {
                StandardCleanupLogs
            }
        }
        2 {
            if ($Global:LOGSPATH -eq 0) {
                StandardCleanupWithSourceNoLogs
            } else {
                StandardCleanupWithSource
            }
        }
        3 {
            main_menu
        }
    }
}

# Function standard cleanup with source and no logging
function StandardCleanupWithSourceNoLogs {
    Write-Host "Starting standard cleanup without logs"
    # Get the source
    $source = ""
    # run this to update drives
    bitlocker_helper
    foreach ($drive in $Global:bitlockerDrives) {
        if ([System.IO.File]::Exists($drive.driveLetter + "\sources\install.wim")) {
            $source = $drive.driveLetter + "\sources\install.wim"
            break
        } elseif ([System.IO.File]::Exists($drive.driveLetter + "\sources\install.esd")) {
            $source = $drive.driveLetter + "\sources\install.esd"
            break
        } elseif ([System.IO.File]::Exists($drive.driveLetter + "\sources\install.swm")) {
            $source = $drive.driveLetter + "\sources\install.swm"
            break
        }
    }
    if ($source -eq "") {
        Write-Host "Unable to find source!" -ForegroundColor Red
        Start-Sleep 1.5
        standard_clean_up
    }
    run_dism -logs $false, -source $source
    sfc.exe /scannow
    checkdisk_no_log
    countdown -seconds 10 -message "SHUTTING DOWN"
    shutdown /f /r /t 0
    getkeyPress
}

# Function standard cleanup with source
function StandardCleanupWithSource {
    if ($LOGSPATH -eq 0 -or $LOGSPATH[2] -eq 1) {
        StandardCleanupNoLogs
    }
    $log = $Global:LOGSPATH[2]
    clear_last_run
    Write-Host "Starting standard cleanup"
    Write-Host "Logs will be located in " $log
    
    # Get the source
    $source = ""
    # run this to update drives
    bitlocker_helper
    foreach ($drive in $Global:bitlockerDrives) {
        if ([System.IO.File]::Exists($drive.driveLetter + "\sources\install.wim")) {
            $source = $drive.driveLetter + "\sources\install.wim"
            break
        } elseif ([System.IO.File]::Exists($drive.driveLetter + "\sources\install.esd")) {
            $source = $drive.driveLetter + "\sources\install.esd"
            break
        } elseif ([System.IO.File]::Exists($drive.driveLetter + "\sources\install.swm")) {
            $source = $drive.driveLetter + "\sources\install.swm"
            break
        }
    }
    if ($source -eq "") {
        Write-Host "Unable to find source!" -ForegroundColor Red
        Start-Sleep 1.5
        standard_clean_up
    }
    run_dism -logs $true, -source $source
    sfc_log
    checkdisk_log
    countdown -seconds 10 -message "SHUTTING DOWN"
    shutdown /f /r /t 0
    getkeyPress
}

function sfc_log {
    Write-Host "Running SFC" -ForegroundColor Green
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "Current Time: $time"
    Write-Host "DO NOT CLOSE THIS WINDOW" -ForegroundColor Red

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
    $sfc_log = ("SFC Time started at: " + $time + "`n" + $container)
    log_data -name_of_file "SFC" -data $sfc_log
}

function checkdisk_no_log {
    Param (
        [Parameter(Mandatory=$false)][bool]$runOnBootDrive
    )
    $drives_run_on = @()
    foreach($drive in $Global:bitLockerDrives) {
        try {
            if ($drive.driveLetter -eq "C:") {
                if ($runOnBootDrive -eq $false) {
                    continue
                }
            }
            Write-Host "On Drive " $drive.driveLetter
            Start-Sleep 1
            $test = (echo y | chkdsk $drive.driveLetter /f /r /x /b)
            if ($test -contains "Windows supports re-evaluating bad clusters on NTFS volumes only.") {
                $no_cap = chkdsk $drive.driveLetter
            }
            $drives_run_on += $drive.driveLetter
        }
        catch {
            Write-Host "Unable to run CHKDSK on drive: " $drive.driveLetter -ForegroundColor Red
            Start-Sleep 1.5
            Write-Host "Press any key to continue..."
            getKeyPress
            continue
        
        }
    }
    return $drives_run_on
}

function checkdisk_log {
    $log = $Global:LOGSPATH[2]
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "Running CHKDSK" -ForegroundColor Green
    #Out-File $log\chkdsk.txt -InputObject "Starting CHKDSK at: $time" -Append
    $chkdsk_time = "CHKDSK Time Started at: " + $time
    $chkdsk_log = ""
    $container = @()
    foreach($drive in $Global:unlockedDrives) {
        #Out-File $log\chkdsk.txt -InputObject ("Running CHKDSK on drive: " + [String]$drive.driveLetter) -Append
        try {
            echo y | chkdsk $drive.driveLetter /f /r /x /b | Tee-Object -Variable container
            if ($container -contains "Cannot lock current drive.") {
                $container = @("Passed 'Y' to run offline!")
            }
            if ($container -contains "Windows supports re-evaluating bad clusters on NTFS volumes only.") {
                $container = @()
                chkdsk $drive.driveLetter | Tee-Object -Variable container
            }
        }
        catch {
            Write-Host "Unable to run CHKDSK on drive: " $drive.driveLetter -ForegroundColor Red
            Start-Sleep 1.5
            continue
        }
        $container += "Run on drive: " + $drive.driveLetter
        $chkdsk_log = ($chkdsk_time + "`n" + $container)
        log_data -name_of_file ("Checkdisk_drive_" + $drive) -data $chkdsk_log
        $chkdsk_log = ""
        $container = @()
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
    if ($LOGSPATH -eq 0 -or $LOGSPATH[2] -eq 1) {
        StandardCleanupNoLogs
    }
    clear_last_run
    $log = $Global:LOGSPATH[2]

    Write-Host "Starting standard cleanup with logs in user account folder"
    Write-Host "Logs will be located in " $log

    run_dism
    
    sfc_log

    # echo y | chkdsk C: /f /r /x /b 
    
    checkdisk_log

    countdown -seconds 10 -message "SHUTTING DOWN"
    shutdown /f /r /t 0
    getkeyPress
}

function run_dism {
    Param (
        [Parameter(Mandatory=$false)][bool]$logs=$true,
        [Parameter(Mandatory=$false)][string]$source=""
    )
    Write-Host "Running DISM" -ForegroundColor Green
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "Current Time: $time"
    Write-Host "DO NOT CLOSE THIS WINDOW" -ForegroundColor Red
    $dism_time = "DISM Time Started at: " + $time
    $dism_log = ""
    $container = @()
    if ($logs) {
        if ($source -eq "") {
            Dism.exe /online /cleanup-image /restorehealth | Tee-Object -Variable container
        } else {
            Dism.exe /online /cleanup-image /restorehealth /source:$source | Tee-Object -Variable container
        }
        
        $dism_log = ($dism_time + "`n" + $container)
        log_data -name_of_file "DISM" -data $dism_log
    } else {
        if ($source -eq "") {
            Dism.exe /online /cleanup-image /restorehealth
        } else {
            Dism.exe /online /cleanup-image /restorehealth /source:$source
        }
    }
    return
}

function CreateAdminAccount {
    Clear-Host
    Write-Host "Activating admin account..."
    Try {
        net user administrator /active:yes
    } Catch {
        Write-Host "Unable to activate admin account!" -ForegroundColor Red
        Start-Sleep 1.5
        Write-Host "Press any key to continue..."
        getKeyPress
        return
    }
    Start-Sleep 1.5
    Write-Host "Press any key to continue..."
    getKeyPress
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
        Write-Host "Press any key to continue..."
        getKeyPress
        return
    }
    Write-Host "Admin account disabled!" -ForegroundColor Green
    Start-Sleep 1.5
    Write-Host "Press any key to continue..."
    getKeyPress
    return
}

function boot_options {
    $messages = @("Boot Options", "Choose an option:", "Boot into UEFI settings", "Boot into advanced startup", "Reboot", "Back to main menu")
    switch((display_message -messages $messages -selection 2)-1) {
        1 {
            countdown -seconds 3 -message "Booting into UEFI Settings"
            shutdown /r /f /fw /t 00
        }
        2 {
            countdown -seconds 3 -message "Booting into Advanced Startup"
            shutdown /r /f /o /t 00
        }
        3 {
            countdown -seconds 3 -message "Rebooting"
            shutdown /r /f /t 00
        }
        4 {
            main_menu
        }
    }
}

function show_options {
    if ($Global:LOGSPATH -eq 0) {
        $messages = @("Options", "Logs turned off!", "Turn on logs", "Clear this scripts data and recreate folder", "Clear all data and DO NOT recreate it", "Back to main menu")
    } else {
        $messages = @("Options", "Logs turned on!", "Turn off logs", "Clear this scripts data and recreate folder", "Clear all data and DO NOT recreate it", "Back to main menu")
    }
    switch((display_message -messages $messages -selection 2)-1) {
        1 {
            if ($Global:LOGSPATH -eq 0) {
                $Global:LOGSPATH = create_folders
            } else {
                $Global:LOGSPATH = 0
            }
        }
        2 {
            clear_logs
        }
        3 {
            full_clear_logs
        }
        4 {
            main_menu
        }
    }
}

function clear_logs {
    Clear-Host
    Remove-Item -r "C:\Users\$env:USERNAME\AppData\Local\temp\pc_cleanup"
    $Global:LOGSPATH = create_folders
    Write-Host "Logs cleared!" -ForegroundColor Green
    Start-Sleep 1.5
    Write-Host "Press any key to continue..."
    getKeyPress
    return
}

function full_clear_logs {
    Clear-Host
    Remove-Item -r "C:\Users\$env:USERNAME\AppData\Local\temp\pc_cleanup"
    Write-Host "All data cleared!" -ForegroundColor Green
    $Global:LOGSPATH = 0
    Start-Sleep 1.5
    Write-Host "Press any key to continue..."
    getKeyPress
    return

}

function clear_last_run {
    Clear-Host
    Remove-Item -r "C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\last_run\*"
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
                if (Test-Path -Path C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\last_run) {
                    $Global:LASTRUN_PATH = "C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\last_run"
                } else {
                    Try {
                        mkdir C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\last_run
                        $Global:LASTRUN_PATH = "C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\last_run"
                    } Catch {
                        Write-Host "Unable to create last run folder!" -ForegroundColor Red
                        Write-Host "Press any key to continue..."
                        getKeyPress
                    }
                }
                return (1, $LOGSPATH)
            } Catch {
                Write-Host "Unable to create log folder!" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                getKeyPress
                return (0, $LOGSPATH)
        }
    }
        Try {
            mkdir C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\logs\$date
            create_folders
        } Catch {
            Write-Host "Unable to create log folder!" -ForegroundColor Red
            Write-Host "Press any key to continue..."
            getKeyPress
            return (0, $LOGSPATH)
        }
    } else {
        Try {
            mkdir C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\logs
            create_folders
        } Catch {
        Write-Host "Unable to create log folder!" -ForegroundColor Red
        Write-Host "Press any key to continue..."
        getKeyPress
        return (0, $LOGSPATH)
        }
    }
}

function log_data {
    Param (
        [Parameter(Mandatory=$true)][string]$name_of_file,
        [Parameter(Mandatory=$true)][string]$data
    )
    if ($LOGSPATH -eq 0 -or $LOGSPATH[2] -eq 1 -or $Global:LASTRUN_PATH -eq 0) {
        throw "Something went terribly wrong, please report this error. Code 01"
        # Def should not get to this point, will add more error checking later, just trying to get a rough idea working
    }
    $log = $Global:LOGSPATH[2]
    $last_run = $Global:LASTRUN_PATH
    $data = $data.replace("[", "`n[")
    $data = $data.replace("]", "]`n")
    $data = $data -replace '\D\.', ". `n"
    Try {
        Out-File $log\$name_of_file.txt -InputObject $data
        Out-File $last_run\$name_of_file.txt -InputObject $data
    } catch {
        throw "Please run without logs, we don't have access to write logs!"
    }
    return
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

function select_user {
    $messages = @("Select a user", "Choose a user:")
    $messages += getListOfUsers
    $messages += "(q) Back"
    $result = display_message -messages $messages -selection 2
    if ($result -eq $messages.Count-1) {
        user_control
    } else {
        return $messages[$result]
    }
}

function reset_password {
    Clear-Host
    $user = select_user
    $result = confirm -message ("Resetting password for user: " + $user)
    if ($result -eq 1) {
        Try {
            net user $user *
        } Catch {
            Write-Host "Unable to reset password!" -ForegroundColor Red
            Start-Sleep 1.5
        }
        Write-Host "Password reset!" -ForegroundColor Green
        Start-Sleep 1.5
    } else {
        return
    }
    Write-Host "Press any key to continue..."
    getKeyPress
    return

}

function deleteUser {
    Clear-Host
    $user = select_user
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
            Write-Host "Press any key to continue..."
            getKeyPress
            Clear-Host
        } else {
            return
        }
    } else {
        return
    }
}

function create_new_user {
    display_single_message -message "Username for user:"
    $username = Read-Host
    display_single_message -message "Type in a password for the new user:"
    $password = Read-Host -AsSecureString
    display_single_message -message "Full Name for user:"
    $fullName = Read-Host
    display_single_message -message "Description for user:"
    $description = Read-Host
    $result = confirm -message "Add to local administrators group?"
    if ($result -eq 1) {
        $group = 'Administrators'
    } else {
        $group = 'Users'
    }
    display_single_message -message "Creating user $username"
    Try {
        if ($password) {
            New-LocalUser -Name $username -FullName $fullName -Description $description -AccountNeverExpires -NoPassword
        } else {
            New-LocalUser -Name $username -FullName $fullName -Description $description -AccountNeverExpires $password
        }
    } Catch {
        display_single_message -message "Unable to create user!" -ForegroundColor Red
        Start-Sleep 1.5
        Write-Host "Press any key to continue..."
        getKeyPress
        return
    }

    Try {
        if ($group -eq 'Administrators') {
            Add-LocalGroupMember -Group "Administrators" -Member $username
        }
    } catch {
        display_single_message -message "Unable to add user to Administrators group!" 
        Start-Sleep 1.5
        Write-Host "Press any key to continue..."
    getKeyPress
        return
    }

    display_single_message -message "User created!"
    Start-Sleep 1.5
    Write-Host "Press any key to continue..."
    getKeyPress
}

function user_control {
    $messages = @("User Control", "Choose an option:", "Create new user", "Reset password", "Delete user", "Create Admin Account", "Disable Admin Account", "Back to main menu")
    switch((display_message -messages $messages -selection 2)-1) {
        1 {
            create_new_user
        }
        2 {
            reset_password
        }
        3 {
            deleteUser
        }
        4 {
            CreateAdminAccount
        }
        5 {
            DisableAdminAccount
        }
        6 {
            main_menu
        }
    }
}

function toggle_new_context_menu {
    $path = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    if(Test-Path $path) {
        try {
            reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
            display_single_message -message "Turned it on!"
            Start-Sleep 1.5
        } catch {
            Write-Host "Unable to turn off new context menu" -ForegroundColor Red
            Start-Sleep 1.5
            Write-Host "Press any key to continue..."
            getKeyPress
            return
        }
    } else {
        try {
            reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
            display_single_message -message "Turned it off!"
            Start-Sleep 1.5
        } catch {
            Write-Host "Unable to turn off new context menu!" -ForegroundColor Red
            Start-Sleep 1.5
            Write-Host "Press any key to continue..."
            getKeyPress
            return
        }
    }
    display_single_message -message "Please restart your computer!"
    Start-Sleep 1.5
    Write-Host "Press any key to continue..."
    getKeyPress
    return
}

function new_set_up_settings_menu {
    $messages = @("New Setup Settings / OS Settings", "Choose an option:", "Reset Windows Update", "Change Time Zone", "Toggle new context menu","Back to main menu")
    switch((display_message -messages $messages -selection 2)-1) {
        1 {
            resetWindowsUpdate
        }
        2 {
            change_time_zone
        }
        3 {
            toggle_new_context_menu
        }
        4 {
            main_menu
        }
    }
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
    Write-Host "Press any key to continue..."
    getKeyPress
    return
}

function change_time_zone {
    $messages = @("Change Time Zone", "Choose a time zone:", "Eastern Time", "Central Time", "Mountain Time", "Pacific Time", "Back to main menu")
    switch((display_message -messages $messages -selection 2)-1) {
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
        5 {
            main_menu
        }
    }
    try {
        Start-Service -Name "W32Time"
        W32tm.exe /resync
    } 
    catch {
        try {
            Start-Service -Name "W32Time" -Force
            W32tm.exe /resync /force
        } 
        catch {
            Clear-Host
            Write-Host "Unable to resync time, service unable to start" -ForegroundColor red
            Start-Sleep 1.5
            Write-Host "Press any key to continue..."
            getKeyPress
            return
        }
    }
    Display_single_message -message "Time resynced!"
    main_menu
}

function view_last_results {
    Clear-Host
    if ($Global:LASTRUN_PATH -eq 0) {
        display_single_message -message "No last run data!"
        Start-Sleep 1.5
        Write-Host "Press any key to continue..."
        getKeyPress
        return
    }
    $log = $Global:LASTRUN_PATH
    
    try {
        $container = Get-ChildItem -Path $log -Force
    } catch {
        display_single_message -message "Unable to check for last run!"
        Start-Sleep 1.5
        Write-Host "Press any key to continue..."
        getKeyPress
        return
    }
    if ($container.Length -eq 0) {
        display_single_message -message "No last run data found!"
        Start-Sleep 1.5
        Write-Host "Press any key to continue..."
        getKeyPress
        return
    }
    foreach ($file in $container) {
        try {
            Get-Content -Path $log\$file -Raw | oh #more -s
            Write-Host "Press any key to continue..."
            getKeyPress
        } catch {
            display_single_message -message ("Unable to open " + $file)
        }
    }
    return
}

function main_menu {
    while ($true) {
        $messages = @(("V" + $VERSION),"Main Menu", "Repair Menu", "View last run", "User Control", "BitLocker", "Boot Options", "New Setup Settings / OS Settings", "Patch Notes", "Options", "Exit")
        switch((display_message -messages $messages -top 2 -selection 2)-1) {
            1 {
                repair_menu
            }
            2 {
                view_last_results
            }
            3 {
                user_control
            }
            4 {
                BitLocker
            }
            5 {
                boot_options
            }
            6 {
                new_set_up_settings_menu
            }
            7 {
                changeLog
            }
            8 {
                show_options
            }
            9 {
                exit
            }
        }
    }
}

# Causes issues.
#$ui.WindowTitle = "Quick Fix Script"

$Global:LOGSPATH = create_folders
bitlocker_helper

main_menu

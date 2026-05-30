
#Requires -RunAsAdministrator

#Test change to verify git is working

# Redoing the code almost entirely 
# Aiming for more of a Class/Object oriented approach but the downside is
# When looking at this code with the ideas or concepts of the book Philosophy of Software Design 2nd Edition by Jogn Ousterhout
# It doesn't align with the ideals laid out in his book.
# Most of the classes only interact with each other to display.
# Each of the classes will contain all the methods related to that menu or subject.
# Example, the repair menu will have all the methods related to the repairs
# The options menu will have all the methods related to the options and file management
#
# The purpose of the run function is to run the NEW parts of the script.

$VERSION = "1.1.2"
$LOGSPATH = ""
$LASTRUN_PATH = ""
# Website for the script
$website = "dawiz314.github.io"


function detectKeyPress {
    # Detect key press
    # 38 = Up arrow
    # 40 = Down arrow
    # 37 = Left arrow
    # 39 = Right arrow
    # 13 = Enter
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

class Message {
    [string]        $message
    [string]        $background_color
    [string]        $foreground_color
    [ScriptBlock]   $function
    [bool]          $selectable

    Message([string]$message, [ScriptBlock]$function, [bool]$selectable = $false) {
        $this.Init($message, (get-host).UI.RawUI.BackgroundColor, (get-host).UI.RawUI.ForegroundColor, $function, $selectable)
    }

    Message([string]$message, [string]$background_color, [string]$foreground_color, [ScriptBlock]$function, [bool]$selectable = $false) {
        $this.Init($message, $background_color, $foreground_color, $function, $selectable)
    }

    [void]Init([string]$message, [string]$background_color, [string]$foreground_color, [ScriptBlock]$function, [bool]$selectable) {
        $this.message = $message
        $this.background_color = $background_color
        $this.foreground_color = $foreground_color
        $this.function = $function
        $this.selectable = $selectable
    }

    [void]display([bool]$selected=$false) {
        if ($selected) {
            Write-Host "> " $this.message " <" -BackgroundColor $this.background_color -ForegroundColor $this.foreground_color
        } else {
            Write-Host $this.message -BackgroundColor $this.background_color -ForegroundColor $this.foreground_color
        }
    }
}

class Display_Util {
    [Message[]] $messages
    [int] $top = 0

    Display_Util() {}

    [void] display_messages() {
        $this.display_messages(0)
    }

    [void] display_messages([int]$selection) {
        Clear-Host

        if ($selection -le 0) {
            if ($this.messages[0].selectable) {
                $selection = 0
                $this.top = 0
            } else {
                foreach ($message in $this.messages) {
                    if ($message.selectable) {
                        $selection = $this.messages.IndexOf($message)
                        $this.top = $selection
                        break
                    }
                }
            }
        }

        foreach ($message in $this.messages) {
            if ($message.selectable -and $selection -eq $this.messages.IndexOf($message)) {
                $message.display($true)
            } else {
                $message.display($false)
            }
        }
        while($true) {
            $key = detectKeyPress
            if ($key -eq "up") {
                if ($selection -gt $this.top) {
                    $selection--
                    break
                } else {
                    $selection = $this.messages.Length - 1
                    break
                }
            } elseif ($key -eq "down") {
                if ($selection -lt ($this.messages.Length - 1)) {
                    $selection++
                    break
                } else {
                    $selection = $this.top
                    break
                }
            } elseif ($key -eq "enter") {
                $this.messages[$selection].function.Invoke()
                break
            }
        }
        $this.display_messages($selection)
    }
}

function test {
    $messages = @(
        [Message]::new("Test", "Black", "White", { Write-Host "Test" }, $true),
        [Message]::new("Test2", { Write-Host "Test2" }, $true),
        [Message]::new("Test3", "Black", "White", { Write-Host "Test3" }, $true)
    )

    $display = [Display_Util]::new()
    $display.messages = $messages
    $display.display_messages()
    Start-Sleep 30
    quit
}

class MainMenu : Display_Util {

    MainMenu() {
        $this.messages = @(
            [Message]::new("V" + $global:VERSION, "Black", "Green", {}, $false),
            [Message]::new("Main Menu", "Black", "White", { }, $false),
            [Message]::new("Repair Menu", { $global:repair_menu.display_messages()}, $true),
            [Message]::new("BitLocker", { bitlocker }, $true),
            [Message]::new("Boot Options", { $global:boot_menu.display_messages() }, $true),
            [Message]::new("Options", { $global:options_menu.display_messages() }, $true),
            [Message]::new("New Set Up / OS Settings", { $global:os_settings_menu.display_messages() }, $true),
            [Message]::new("Exit", { exit }, $true)
        )
    }
}

class Repair_Menu : Display_Util {
    [string] $source = ""
    [int] $dots = 10
    $ws_job = $null

    [Message[]] $original_messages = @(
        [Message]::new("Repair Menu", "Black", "White", { }, $false),
        [Message]::new("Standard Cleanup", { $this.standard_clean_up() }, $true),
        [Message]::new("Fix Drives", { fix_drives }, $true),
        [Message]::new("Back to main menu", { $global:main_menu.display_messages() }, $true)
    )

    Repair_Menu() {
        $this.messages = $this.original_messages
    }

    [void] standard_clean_up() {
        $clean_up_messages = @(
            [Message]::new("Standard Cleanup", "Black", "White", { }, $false),
            [Message]::new("Without source", { $this.run_cleanup() }, $true),
            [Message]::new("With source", { $this.source = $true; $this.run_cleanup() }, $true),
            [Message]::new("Back to main menu", { $this.return_to_main_menu() }, $true)
        )
        $this.messages = $clean_up_messages
        $this.display_messages()
    }

    $dism_job = {
        param (
            [string]$source,
            [string]$LASTRUN_PATH
            )


        if ($source -eq "") {
            $_ = Dism.exe /online /cleanup-image /restorehealth | Tee-Object -FilePath ($LASTRUN_PATH + "\DISM.txt")
        } else {
            $_ = Dism.exe /online /cleanup-image /restorehealth /source:$source | Tee-Object -FilePath ($LASTRUN_PATH + "\DISM.txt")
        }
        
    }

    $sfc_job = {
        param (
            [string]$LASTRUN_PATH
        )

        $_ = sfc.exe /scannow | Tee-Object -FilePath ($LASTRUN_PATH + "\SFC.txt")
    }

    $wshell_background = {
        $obj = New-Object -ComObject Wscript.Shell
        while ($true) {
            $obj.sendkeys("{SCROLLLOCK}")
            Start-Sleep 120
        }
    }

    [void] run_cleanup() {
        if ($this.source) {
            $this.find_source()
        } else {
            $this.source = ""
        }
        $this.ws_job = Start-Job -scriptBlock $this.wshell_background
        $this.dism()
        getKeyPress
        $this.sfc()
        $this.ws_job.StopJob()
        checkdisk_no_log
        Copy-Item -Path $global:LASTRUN_PATH + "\*" -Destination $global:LOGSPATH -Recurse
        Write-Host "Standard cleanup has completed!" -ForegroundColor Green
        shutdown /f /r /t 0

    }

    [void] find_source() {
        bitlocker_helper
        $this.source = ""
        foreach ($drive in $Global:bitlockerDrives) {
            if ([System.IO.File]::Exists($drive.driveLetter + "\sources\install.wim")) {
                $this.source = $drive.driveLetter + "\sources\install.wim:1"
                break
            } elseif ([System.IO.File]::Exists($drive.driveLetter + "\sources\install.esd")) {
                $this.source = $drive.driveLetter + "\sources\install.esd:1"
                break
            } elseif ([System.IO.File]::Exists($drive.driveLetter + "\sources\install.swm")) {
                $this.source = $drive.driveLetter + "\sources\install.swm:1"
                break
            }
        }
    }


    [void] dism_output([string]$log) {
        Write-Host "Running DISM!" -ForegroundColor Green
        if ($this.source -eq "") {
            Write-Host "With no source file!"
        } else {
            Write-Host "With source file: " $this.source
        }
        Write-Host "Logs will be located in " $log
    }

    [void] sfc_output([string]$log) {
        Write-Host "Running SFC" -ForegroundColor Green
        Write-Host "Logs will be located in " $log
    }

    [void] dism() {
        if ($global:LOGSPATH -eq 0) {
            if ($this.source -eq "") {
                Dism.exe /online /cleanup-image /restorehealth
            } else {
                Dism.exe /online /cleanup-image /restorehealth /source:$this.source
            }

            start-sleep 3
        } else {
            $log = $global:LOGSPATH[2]
            $global:options_menu.clear_last_run()
            Write-Host "Running DISM!"
            if ($this.source -eq "") {
                Write-Host "With no source file!"
            } else {
                Write-Host "With source file: " $this.source
            }

            Write-Host "Logs will be located in " $log

            $old_content = ""
            $count = 1
            $job = Start-Job -scriptBlock $this.dism_job -ArgumentList $this.source, $global:LASTRUN_PATH
            $done = $false
            while($done -eq $false) {
                try{
                    $path = $global:LASTRUN_PATH + "\DISM.txt"
                    if ($job.State -ne "Running" -and $job.State -ne "NotStarted") {
                        $done = $true
                        $contents = Get-Content -Path $path
                        $contents = $contents -split "`n" 
                        $contents = $contents | Where-Object {$_ -ne ""} # Remove empty lines
                        $contents = $contents.Trim()
                        Clear-Host
                        $this.dism_output($log)
                        $filter_this = $contents[-5..$contents.length - 1]
                        foreach ($message in $filter_this) {
                            if ($message -match "\[*]") {
                                continue
                            } else {
                                Write-Host $message
                            
                            }
                        }
                        Write-Host "DISM has completed!" -ForegroundColor Green
                        Start-Sleep 10
                        break

                    }
                    if (Test-Path $path) {
                        $contents = Get-Content -Path $path
                        if ($contents -ne $null) {
                            $contents = $contents -split "`n" 
                            $contents = $contents | Where-Object {$_ -ne ""} # Remove empty lines
                            $contents = $contents.Trim()
                            if ($old_content -ne $contents[-1]) {
                                Clear-Host
                                $this.dism_output($log)

                                Write-Host -NoNewLine $contents[-1]
                                $old_content = $contents
                            }
                        }
                    } else {
                        if ($old_content -ne "Waiting on a return value.") {
                            $old_content = "Waiting on a return value."
                            Clear-Host
                            $this.dism_output($log)

                            Write-Host -NoNewLine $old_content
                        }
                    }
                } catch {
                    Write-Host "Error: " $_.Exception.Message
                }
                Start-Sleep 1

                Write-Host -noNewLine " ."
                $count += 1

                if ($count -eq $this.dots) {
                    $count = 1
                    $this.dism_output($log)
                    Clear-Host -noNewLine $old_content
                }
            }
        }
    }

    [void] sfc() {
        if ($global:LOGSPATH -eq 0) {
            sfc.exe /scannow

            start-sleep 3
        } else {
            $log = $global:LOGSPATH[2]
            
            Write-Host "Running SFC"
            Write-Host "Logs will be located in " $log
            Write-Host "Waiting on job to start..."
            
            $old_content = ""
            $count = 1

            $job = Start-Job -scriptBlock $this.sfc_job -ArgumentList $global:LASTRUN_PATH
            $done = $false

            while(-not $done) {
                try{
                    $path = $global:LASTRUN_PATH + "\SFC.txt"
                    if ($job.State -ne "Running" -and $job.State -ne "NotStarted") {
                        $done = $true
                        $contents = Get-Content -Path $path
                        $contents = $contents -split "`n" 
                        $contents = $contents | Where-Object {$_ -ne ""} # Remove empty lines
                        
                        $contents = $contents.Trim()
                        $filter_this = $contents[-5..-1]
                        $cleaned_text = @()
                        
                        Clear-Host
                        $this.sfc_output($log)
                        

                        foreach ($message in $filter_this) { Write-Host $message }
                        Write-Host "SFC has completed!" -ForegroundColor Green
                        Start-Sleep 10
                        break
                    }
                    if (Test-Path $path) {
                        # File path exists, we can check it now
                        $contents = Get-Content -Path $path
                        if ($contents -ne $null) { # Making sure the contents are not nothing
                            # Splitting the contents into an array
                            $contents = $contents -split "`n" 
                            $contents = $contents | Where-Object {$_ -ne ""} # Remove empty lines
                            $contents = $contents.Trim()
                            
                            # Seeing if its the same stuff we already have on the screen
                            if ($old_content -ne $contents[-1]) {
                                # If it is different, then update with the new stuff
                                Clear-Host
                                $this.sfc_output($log)
                                Write-Host -NoNewLine $contents[-1]
                                $old_content = $contents[-1]
                            }
                        } else {
                            # If the contents are null, then we need to update the screen
                            if ($old_content -ne "Waiting on a return value.") {
                                $old_content = "Waiting on a return value."
                                Clear-Host
                                $this.sfc_output($log)
                                Write-Host -NoNewLine $old_content
                            }
                            
                        
                        }
                    } else {
                        # If the file path is null, then we need to update the screen
                        if ($old_content -ne "Waiting on a return value.") {
                            $old_content = "Waiting on a return value."
                            Clear-Host
                            $this.sfc_output($log)
                            Write-Host -NoNewLine $old_content
                        }
                    }
                } catch {
                    # Basic error catching
                    Write-Host "Error: " $_.Exception.Message
                }
                # Wait 1 second to update the screen
                Start-Sleep 1

                # Add a dot to the screen every second, so the user knows it's not frozen.
                Write-Host -noNewLine " ."
                $count += 1

                # if we have waited X seconds, then update the screen
                if ($count -eq $this.dots) {
                    $count = 1
                    Clear-Host 
                    $this.sfc_output($log)
                    Write-Host -noNewLine $old_content
                }
            }
        }
    }

    [void] return_to_main_menu() {
        $this.messages = $this.original_messages
        $global:main_menu.display_messages()
    }
}

class Boot_Menu : Display_Util {
    Boot_Menu() {
        $this.messages = @(
            [Message]::new("Boot Menu", "Black", "White", { }, $false),
            [Message]::new("Boot into UEFI settings", { $this.uefi_settings() }, $true),
            [Message]::new("Boot into advanced startup", { $this.advanced_startup() }, $true),
            [Message]::new("Reboot", { $this.reboot() }, $true),
            [Message]::new("Back to main menu", { $global:main_menu.display_messages() }, $true)
        )
    }

    [void] uefi_settings() {
        countdown -seconds 3 -message "Booting into UEFI Settings"
        shutdown /r /f /fw /t 00
    }

    [void] advanced_startup() {
        countdown -seconds 3 -message "Booting into Advanced Startup"
        shutdown /r /f /o /t 00
    }

    [void] reboot() {
        countdown -seconds 3 -message "Rebooting"
        shutdown /r /f /t 00
    }

}

class Options_Menu : Display_Util {
    Options_Menu() {
        # $this.messages = @(
        #     [Message]::new("Options Menu", "Black", "White", { }, $false),
        #     [Message]::new("Logs turned " + $(if ($global:LOGSPATH -eq 0) { "off!" } else { "on!" }), "Black", "White", { }, $false),
        #     [Message]::new("Toggle logs", { $global:LOGSPATH = create_folders }, $true),
        #     [Message]::new("Clear this scripts data and recreate folder", { $this.clear_logs() }, $true),
        #     [Message]::new("Clear all data and DO NOT recreate it", { $this.full_clear_logs() }, $true),
        #     [Message]::new("Back to main menu", { $global:main_menu.display_messages() }, $true)
        # )
    }

    [void] display_messages() {
        $this.messages = @(
            [Message]::new("Options Menu", "Black", "White", { }, $false),
            [Message]::new("Logs turned " + $(if ($global:LOGSPATH -eq 0) { "off!" } else { "on!" }), "Black", "White", { }, $false),
            [Message]::new("Toggle logs", { $this.toggle_logs()}, $true),
            [Message]::new("Clear this scripts data and recreate folder", { $this.clear_logs() }, $true),
            [Message]::new("Clear all data and DO NOT recreate it", { $this.full_clear_logs() }, $true),
            [Message]::new("Back to main menu", { $global:main_menu.display_messages() }, $true)
        )
        ([Display_Util]$this).display_messages()
    }

    [void] toggle_logs() {
        if ($Global:LOGSPATH -eq 0) {
            $Global:LOGSPATH = $this.create_folders
        } else {
            $Global:LOGSPATH = 0
        }
        $this.display_messages()
    }

    [void] clear_logs() {
        Clear-Host
        Remove-Item -r "C:\Users\$env:USERNAME\AppData\Local\temp\pc_cleanup"
        $global:LOGSPATH = $this.create_folders
        Write-Host "Logs cleared!" -ForegroundColor Green
        Start-Sleep 1.5
        Write-Host "Press any key to continue..."
        getKeyPress
        return
    }

    [void] full_clear_logs() {
        Clear-Host
        Remove-Item -r "C:\Users\$env:USERNAME\AppData\Local\temp\pc_cleanup"
        Write-Host "All data cleared!" -ForegroundColor Green
        $Global:LOGSPATH = 0
        Start-Sleep 1.5
        Write-Host "Press any key to continue..."
        getKeyPress
        return
    }

    [System.Tuple[int,string]] create_folders() {
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
        return (0, $LOGSPATH)
    }

    [void] clear_last_run() {
        Clear-Host
        Remove-Item -r "C:\Users\$env:USERNAME\AppData\Local\Temp\pc_cleanup\last_run\*"
        return
    }
}

class OS_Settings_Menu : Display_Util {
    OS_Settings_Menu() {
        $this.messages = @(
            [Message]::new("OS Settings Menu", "Black", "White", { }, $false),
            [Message]::new("Reset Windows Update", { $this.reset_windows_update() }, $true),
            [Message]::new("Toggle Context Menu Style (Windows 10 vs Windows 11)", { $this.toggle_context_menu_style() }, $true),
            [Message]::new("Back to main menu", { $global:main_menu.display_messages() }, $true)
        )
    }

    [void] reset_windows_update() {
        Clear-Host
        Write-Host "Resetting Windows Update..." -ForegroundColor Green
        Start-Sleep 1.5
        Write-Host "Stopping Windows Update Service..." -ForegroundColor Green
        Stop-Service -Name wuauserv -Force
        Start-Sleep 1.5
        Write-Host "Deleting Windows Update Cache..." -ForegroundColor Green
        Remove-Item -Path C:\Windows\SoftwareDistribution\* -Recurse -Force
        Start-Sleep 1.5
        Write-Host "Starting Windows Update Service..." -ForegroundColor Green
        Start-Service -Name wuauserv
        Start-Sleep 1.5
        Write-Host "Windows Update has been reset!" -ForegroundColor Green
        Start-Sleep 1.5
    }
    
    [void] toggle_context_menu_style() {
        $path = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
        if(Test-Path $path) {
            try {
                reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
                Write-Host "Turned it on!" -ForegroundColor Green
            } catch {
                Write-Host "Unable to turn off new context menu" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                getKeyPress
                return
            }
        } else {
            try {
                reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
                Write-Host "Turned it off!" -ForegroundColor Green
            } catch {
                Write-Host "Unable to turn off new context menu!" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                getKeyPress
                return
            }
        }
        Write-Host "Please restart your computer!" -ForegroundColor Green
        Start-Sleep 1.5
        Write-Host "Press any key to continue..."
        getKeyPress
        return
    }

    
}

function run {
    $global:main_menu = [MainMenu]::new()
    $global:repair_menu = [Repair_Menu]::new()
    $global:boot_menu = [Boot_Menu]::new()
    $global:options_menu = [Options_Menu]::new()
    $global:os_settings_menu = [OS_Settings_Menu]::new()
    $main_menu.display_messages()
    # $global:repair_menu.dism()
    # $global:repair_menu.sfc()
    exit
}



function add_lines {
    # Parameters
    param (
        [Parameter(Mandatory=$True)][int]$lines
    )
    for($i=0; $i -lt $lines; $i++) {
        Write-Host
    }

}

function add_spaces {
    # Parameters
    param (
        [Parameter(Mandatory=$True)][int]$spaces
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
        [Parameter(Mandatory=$True)][string[]]$messages,
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
        [Parameter(Mandatory=$True)][string]$message
    )
    Clear-Host
    add_lines -lines (($Host.UI.RawUI.WindowSize.Height/2)-1)
    $spaces = add_spaces -spaces (($Host.UI.RawUI.WindowSize.Width/2)-($message.Length/2))
    Write-Host $spaces$message
    add_lines -lines (($Host.UI.RawUI.WindowSize.Height/2)-1)

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
            $lock_status = $True
        }
        $encryption_percentage = $container2 | Where-Object {$_ -match "Percentage Encrypted"}
        $encryption_percentage = $encryption_percentage -replace ".*:\s", ""
    
        $Global:bitlockerDrives += ([bitlockerDrive]::new(($drive + ":"),$lock_status, [string]$encryption_percentage))
    }
    
    $Global:lockedDrives = @()
    $Global:unlockedDrives = @()

    foreach ($drive in $bitlockerDrives) {
        if ($drive.lockStatus -eq $True) {
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
        [Parameter(Mandatory=$True)][bitlockerDrive[]]$bitlockerDrives
    )
    while ($True) {
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
        [Parameter(Mandatory=$True)][string]$message
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
        [Parameter(Mandatory=$True)][int]$seconds,
        [Parameter(Mandatory=$True)][string]$message
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
        [Parameter(Mandatory=$false)][bool]$logs=$True,
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
        [Parameter(Mandatory=$True)][string]$name_of_file,
        [Parameter(Mandatory=$True)][string]$data
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
# Causes issues.
#$ui.WindowTitle = "Quick Fix Script"

$Global:LOGSPATH = create_folders
bitlocker_helper

# main_menu
run
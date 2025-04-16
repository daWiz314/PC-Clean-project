#   Created By Harry F. Martin III
#   Created On April 6th, 2025
#
#   The point of this script is to move files from one directory to another, but with a nice display.
#
#   Main purpose is for a friend who wants to move a bunch of files quickly with minimal issues and effort.
#

function test() {
    # This is just to test out the script
    Clear-Host
    $src = "C:\Users\hfmar\Downloads"
    $test_folder = [Folder]::new($src, "Downloads")
    foreach ($item in $test_folder.contents) {
        Write-Host $item.name
        Start-Sleep 0.5
    }
}

class Folder {
    [string]    $path
    [string]    $name
    [array]     $contents

    Folder([string]$path, [string]$name) {
        $this.path = $path
        $this.name = $name
        $this.contents = @()
        $this.getContents()
    }

    [void] getContents() {
        # Get the contents of this directory
        $everything = Get-ChildItem -Path $this.path -Name

        foreach ($item in $everything) {
            if ($item -NotLike "*.*") {
                # If the item is a directory, create a new Folder object
                $folder = New-Object Folder -ArgumentList (Join-Path -Path $this.path -ChildPath $item), $item
                $this.contents += $folder
            } else {
                # If the item is a file, create a new File object
                $file = New-Object File -ArgumentList (Join-Path -Path $this.path -ChildPath $item), $item
                $this.contents += $file
            }
        }
    }
}

class File {
    [string]    $path
    [string]    $name

    File([string]$path, [string]$name) {
        $this.path = $path
        $this.name = $name
    }
}

class Display {
    Display() {
        # This is just a placeholder for now
        # This class will be used to display the files and folders in a nice way
        # It will also handle the user input and selections
    }
}

# test
function Move_Files {
    Param(

        [Parameter(Mandatory=$True)][string]$src,
        [Parameter(Mandatory=$True)][string]$dest,
        [Parameter(Mandatory=$True)][array]$files = @()
    )

    # Check if the source directory exists
    if (-Not (Test-Path -Path $src)) {
        Write-Host "Source directory does not exist: $src" -ForegroundColor Red
        return
    }

    # Check if the destination directory exists
    if (-Not (Test-Path -Path $dest)) {
        Write-Host "Destination directory does not exist: $dest" -ForegroundColor Red
        return
    }
    
    # To actually move the files, we are just going to use the Move-Item command

}

# Function to create a directory at the given path
# Parameters:
#   $path - The path where the directory should be created
#   $name - The name of the directory to create
# Returns:
#   The full path of the created directory
#   OR
#   A message indicating that the directory already exists

function Create_Dir {
    Param(
        [Parameter(Mandatory=$True)][string]$path,
        [Parameter(Mandatory=$True)][string]$name
    )

    # Check if the directory already exists
    if (Test-Path -Path (Join-Path -Path $path -ChildPath $name)) {
        Write-Host "Directory already exists: $name" -ForegroundColor Yellow
        return "Cannot create a directory that already exists!", -1
    }
    # Create the directory
    try {
        New-Item -Path $path -Name $name -ItemType Directory
        Write-Host "Directory created: $name\n Full path: $path\$name" -ForegroundColor Green
        return "$path\$name", 0
    } catch  {
        Write-Host "Failed to create directory: $name" -ForegroundColor Red
        return "Failed to create directory!", -2
    }
}

function add_lines() {
    Param(
        [Parameter(Mandatory=$True)][int]$lines
    )

    for ($i = 0; $i -lt $lines; $i++) {
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

# Detect key press
# 38 = Up arrow
# 40 = Down arrow
# 37 = Left arrow
# 39 = Right arrow
# 13 = Enter
function detect_key_press {
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
    detect_key_press

}
function display_message() {
    Param(
        [Parameter(Mandatory=$True)][string[]]$messages,
        [Parameter(Mandatory=$True)][int]$top,
        [Parameter(Mandatory=$False)][int]$selection=$top+1
    )
    $current_top = $top # This is incase there is too much to display, and will mark the top incase we need to scroll and keep track of where we are
    $controls_message = "Press 'q' to quit, 'up' to move up, 'down' to move down, 'enter' to select, and 'd' to view other drives"
    if ($Host.UI.RawUI.WindowSize.Height -lt $messages.Length) {
        $max_displayed = $Host.UI.RawUI.WindowSize.Height - 3
    } else {
        $max_displayed = $messages.Length
        if (-not $messages.Contains($controls_message)) {
            $messages += $controls_message
        }
    }

    Clear-Host

    foreach ($message in $messages) {
        if ($messages.IndexOf($message) -gt $max_displayed) {
            Write-Host $controls_message -BackgroundColor White -ForegroundColor Green
            break
        }
        if ($selection -eq $messages.IndexOf($message)) {
            Write-Host $message -BackgroundColor White
        } else {
            Write-Host $message
        }
        if ($selection -gt $max_displayed) {
            $current_top += 1
        }
    }
    $key = detect_key_press

    if ($key -eq "up") {
        if ($selection -gt $top+1) {
            $selection--
        } else {
            $selection = $top+1
        }
    } elseif ($key -eq "down") {
        if ($selection -lt ($messages.Length - 1)) {
            $selection++
        } else {
            $selection = $messages.Length - 1
        }
    } elseif ($key -eq "enter") {
        return $selection
    } elseif ($key -eq "q") {
        exit
    }
    display_message -messages $messages -top $top -selection $selection
}

function Main() {
    $src = ""
    $dest = ""
    
    Clear-Host

    $src = $PSScriptRoot
    $name = $src.Substring($src.LastIndexOf("\") + 1)
    
    $src = [Folder]::new($src, $name)# This way it will just run from where ever the user already is

    $messages = @("Welcome!", "Please enter your source directory to move!")
    $top = 1
    foreach ($item in $src.contents) {
        $messages += $item.name
    }

    display_message -messages $messages -top $top
    
}

Main
Write-Host $Host.UI.RawUI.WindowSize.Width
Write-Host $Host.UI.RawUI.WindowSize.Height

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
        [Parameter(Mandatory=$true)][string[]]$messages
    )
    Clear-Host
    add_lines -lines (($Host.UI.RawUI.WindowSize.Height/2)-$message.Length - 1)
    foreach($message in $messages) {
        $test = add_spaces -spaces (($Host.UI.RawUI.WindowSize.Width/2)-$message.Length)
        Write-Host $test$message
        Start-Sleep 1
    }
    add_lines -lines ($Host.UI.RawUI.WindowSize.Height/2)

}

$messages = @("Hello", "World")
display_message -messages $messages
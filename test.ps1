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
    # for($i=0; $i -lt $spaces; $i++) {
    #     $test += " "
    # }
    return $test += " " * $spaces

}

function compile_message {
    param (
        [Parameter(Mandatory=$true)][string[]]$messages,
        [Parameter(Mandatory=$false)][int]$top=1,
        [Parameter(Mandatory=$false)][int]$selection=$top+1
    )
    Clear-Host
    $new_line = $Host.UI.RawUI.WindowSize.Width
    $height = ($Host.UI.RawUI.WindowSize.Height/2) - $messages.Length
    $center = $Height * $new_line
    $final_message = " " * $center
    foreach ($message in $messages) {
        if($selection -eq $messages.IndexOf($message)) {
            $space_around_word = ($Host.UI.RawUI.WindowSize.Width/2) - $message.Length + 1
            $final_message += (" " * $space_around_word) + ">" + $message + (" " * $space_around_word)
        } else {
            $space_around_word = ($Host.UI.RawUI.WindowSize.Width/2) - $message.Length
            $final_message += (" " * $space_around_word) + $message + (" " * $space_around_word)
        }
        
    }
    Write-Host $final_message -NoNewline

    $key = detectKeyPress
    if ($key -eq "up") {
        if ($selection -gt 0) {
            $selection--
        } else {
            $selection = $messages.Length - 1
        }
    } elseif ($key -eq "down") {
        if ($selection -lt ($messages.Length - 1)) {
            $selection++
        } else {
            $selection = 0
        }
    } elseif ($key -eq "enter") {
        return $selection
    }
    compile_message -messages $messages -selection $selection -top $top

}

function display_message {
    # Parameters
    param (
        [Parameter(Mandatory=$true)][string[]]$messages,
        [Parameter(Mandatory=$false)][int]$selection=0
    )
    Clear-Host
    add_lines -lines (($Host.UI.RawUI.WindowSize.Height/2)-$message.Length - 1)
    foreach($message in $messages) {
        if ($selection -eq $messages.IndexOf($message)) {
            $test = add_spaces -spaces (($Host.UI.RawUI.WindowSize.Width/2)-$message.Length - 1)
            Write-Host $test">"$message
        } else {
            $test = add_spaces -spaces (($Host.UI.RawUI.WindowSize.Width/2)-$message.Length)
            Write-Host $test$message
        }
    }
    add_lines -lines (($Host.UI.RawUI.WindowSize.Height/2)-$nessage.Length)
    $key = detectKeyPress
    if ($key -eq "up") {
        if ($selection -gt 0) {
            $selection--
        } else {
            $selection = $messages.Length - 1
        }
    } elseif ($key -eq "down") {
        if ($selection -lt ($messages.Length - 1)) {
            $selection++
        } else {
            $selection = 0
        }
    } elseif ($key -eq "enter") {
        return $selection
    }
    display_message -messages $messages -selection $selection
}

function getKeyPress {
    $pressedKey = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $key = $pressedKey
    return $key
}

# Detect key press
# 38 = Up arrow
# 40 = Down arrow
# 37 = Left arrow
# 39 = Right arrow
# 13 = Enter
function detectKeyPress {
    $key = getKeyPress
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

$messages = @("Hello", "World", "test", "test2")
compile_message -messages $messages
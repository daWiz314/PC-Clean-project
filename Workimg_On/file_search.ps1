#
#   Author:
#       Harry F Martin III
#   Date:
#       4/4/2024
#   Location:
#      Random Coffee Shop with Wife
#   Description:
#       This is a test file for file searching / indexing.
#       Steps in order
#       Log all files in root dir
#       Start a job for each folder, that will open it and repeat the process
#       Log all of it to a file to cache it
#       Every time this opens, it will check the cache file and update it
#
# 
# ------------------------------------------------------------------------------
#
#               Classes
# ------------------------------------------------------------------------------
# Class File
#   Just a container for a file object
#   METHODS:
#       get_path() - Returns the path of the file

# Class Folder
#   Contains a directory and all of its children
#   It is linked to the parent object, by the parent being passed into object.
#   This way we can crawl any direction from a folder
#   Will we actually do this? No. But it's cool.
#   METHODS:
#      get_path() - Returns the path of the folder
#
class File {
    [Folder]$parent
    [string]$name
    [string]$drive

    File([Folder]$folder, [string]$drive, [string]$name) {
        $this.parent = $folder
        $this.name = $name
        $this.drive = $drive
    }

    [string]get_path() {
        return ($this.parent.path + "\" + $this.name)
    }
}


class Folder {
    [string]$drive
    [string]$path
    [string]$name
    [folder]$parent
    [folder[]]$children_folders
    [File[]]$files
    [string[]]$contents

    Folder([Folder]$parent, [string]$drive, [string]$name) {
        # If the parent directory is null, then we are at the root
        if($parent -eq $null) {
            $this.name = ""
            $this.path = $drive
        } else {
            # If we are not at the root,
            # Then we need to get the path from the parent
            # If the parent path ends in a \, then we don't need to add one
            if ($parent.path -match "\\$") {
                $this.path = $parent.path + $name
            } else {
                $this.path = $parent.path + "\" + $name
            }
            $this.drive = $drive
        }        
        $this.name = $name
        $this.parent = $parent
        $this.contents = dir $this.path
    }

    [string]get_path() {
        if ($this.parent -eq $null) {
            return $this.path
        } else {
            return ($this.parent.path + "\" + $this.name)
        }
    }

    discover_children() {
        foreach ($content in $this.contents) {
            if ($content -is [System.IO.DirectoryInfo]) {
                $this.children_folders.Add([Folder]::new($this, $this.drive, $content.Name))
            } else {
                #$this.files.Add([File]::new($this, $this.drive, $content.Name))
            }
        }
        # Try to do some clean up
        $this.contents = $null
    }

    [Folder[]]get_children() {
        return $this.children_folders
    }
}
# ------------------------------------------------------------------------------
#
#            Functions
# ------------------------------------------------------------------------------
# Function Main
# Main function that is body of script
# After finding all drives, starts a Master Job controller, 
# that will in turn call actual workers to crawl everything
#
function main {
    # Get all drives
    $container = fsutil.exe fsinfo drives
    # Split drives into array with just spaces between
    $container = $container -split ":"
    # Remove all \ because we don't need those
    # Regex is matching a space then a word character
    $container = ($container | Where-Object {$_ -match "\s\w{1,2}"}) -replace "\\", ""
    $container = $container.Trim()


    foreach($drive in $container) {
        $folder_container.Add([Folder]::new($null, $drive+":\", $null), $false)
    }

    # RunspaceFactoryPool that runs through for uncrawled items and crawls them
    $list_adder = [RunspaceFactory]::CreateRunspacePool(1, 5)
    $list_adder.Open()

    $list_adder_script = {
        param($num)
        $cacheData[$num] = $false
    }

    # Actually start job
    foreach ($num in 1..255) {
        $test = [Powershell]::Create().AddScript($list_adder_script).AddArgument($num)
        $test.RunspacePool = $list_adder
        $test.BeginInvoke()
    }
    $list_adder.Close()
    $list_adder.Dispose() # Should be done here
}   

# ------------------------------------------------------------------------------
#
#            Variables
# ------------------------------------------------------------------------------
# Variable: cacheData
#   Contains all the data from the cache if there is one available
#   This is the main data store for the program
#   Data outline
#                     [KEY] : [VALUE]
#   [file/folder indicator] : [object pertaining to file or folder]

# Variable: folder_container
#   Master Container for all the folders, and if they are sorted or not
#   Data outline
#                     [KEY] : [VALUE]
#                  [Folder] : [bool on if it is sorted or not]

#
# Variable: sorted_list_alpha
#   Contains all the data from the cache, but sorted alphabetically
#   This is for easy access to the data when searching
#                      [KEY] : [VALUE]
#         [file/folder name] : [path to corresponding file/folder]
#

# Variable: sorted_list_tree
#   Contains all the data from the cache, but sorted by tree
#   This is for easy access to the data when searching
#                      [KEY] : [VALUE]
#         [file/folder name] : [path to corresponding file/folder]

$cacheData = [Hashtable]::Synchronized(@{})
$folder_container = [Hashtable]::Synchronized(@{})
$sorted_list_alpha = [Hashtable]::Synchronized(@{})
$sorted_list_tree = [Hashtable]::Synchronized(@{})





# ------------------------------------------------------------------------------
#
#         Actually run script
# ------------------------------------------------------------------------------
#Measure-Command {main}

#break point here
Write-Host "Done!"
Function Get-RunspaceData {
    [cmdletbinding()]
    param(
        [switch]$Wait
    )
    Do {
        $more = $false         
        Foreach($runspace in $runspaces) {
            If ($runspace.Runspace.isCompleted) {
                $runspace.powershell.EndInvoke($runspace.Runspace)
                $runspace.powershell.dispose()
                $runspace.Runspace = $null
                $runspace.powershell = $null                 
            } ElseIf ($runspace.Runspace -ne $null) {
                $more = $true
            }
        }
        If ($more -AND $PSBoundParameters['Wait']) {
            Start-Sleep -Milliseconds 100
        }   
        #Clean out unused runspace jobs
        $temphash = $runspaces.clone()
        $temphash | Where {
            $_.runspace -eq $Null
        } | ForEach {
            Write-Verbose ("Removing {0}" -f $_.computer)
            $Runspaces.remove($_)
        }  
        [console]::Title = ("Remaining Runspace Jobs: {0}" -f ((@($runspaces | Where {$_.Runspace -ne $Null}).Count)))             
    } while ($more -AND $PSBoundParameters['Wait'])
}
$ScriptBlock = {
    Param ($computer,$hash)
    $hash[$Computer]=([int]$computer*10)
}
$Script:runspaces = New-Object System.Collections.ArrayList   
$Computername = 1,2,3,4,5
$hash = [hashtable]::Synchronized(@{})
$sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
$runspacepool = [runspacefactory]::CreateRunspacePool(1, 10, $sessionstate, $Host)
$runspacepool.Open() 

ForEach ($Computer in $Computername) {
    #Create the powershell instance and supply the scriptblock with the other parameters 
    $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($computer).AddArgument($hash)
           
    #Add the runspace into the powershell instance
    $powershell.RunspacePool = $runspacepool
           
    #Create a temporary collection for each runspace
    $temp = "" | Select-Object PowerShell,Runspace,Computer
    $Temp.Computer = $Computer
    $temp.PowerShell = $powershell
           
    #Save the handle output when calling BeginInvoke() that will be used later to end the runspace
    $temp.Runspace = $powershell.BeginInvoke()
    Write-Verbose ("Adding {0} collection" -f $temp.Computer)
    $runspaces.Add($temp) | Out-Null               
}
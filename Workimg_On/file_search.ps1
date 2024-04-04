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
# ----------------------------------------------------------------------------------
#               Classes
# ----------------------------------------------------------------------------------
# Class File
# Just a container for a file object
#
# Class Folder
# Contains a directory and all of its children
# It is linked to the parent object, by the parent being passed into object.
# This way we can crawl any direction from a folder
# Will we actually do this? No. But it's cool.
#
class File {
    [folder]$parent
    [string]$name

    file([folder]$folder, [string]$name) {
        $this.parent = $folder
        $this.name = $name
    }
}


class Folder {
    [string]$path
    [string]$name
    [folder]$parent
    [folder[]]$children_folders
    [File[]]$files
    [string[]]$contents

    Folder([folder]$parent=$null, [string]$name) {
        # If the parent directory is null, then we are at the root
        if($parent -eq $null) {
            # Grab the path to figure out which drive we are in
            # Then split it up, to just the letter and extra stuff we don't need
            $this.path = ((pwd)-split ":") -replace "\\", ""
            $this.parent = $this.path.Trim() + ":\"
        }
        $this.path = $parent.path + "\" + $name
        $this.name = $name
        $this.parent = $parent
        $this.contents = dir $this.path
    }
}
# ----------------------------------------------------------------------------------
#            Functions
# ----------------------------------------------------------------------------------
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

    cd \
    $test = [folder]::new($null, "Users")
    Write-Host $test

}

# ----------------------------------------------------------------------------------
#            Variables
# ----------------------------------------------------------------------------------
# Variable: cacheData
#   Contains all the data from the cache if there is one available
#   This is the main data store for the program
#   Data outline
#                       [KEY] : [VALUE]
#     [file/folder indicator] : [object pertaining to file or folder]

# Variable: syncData
#   Contains all the new data from the threads
#   This is to update the cache as needed
#   ----------Same data outline as above----------
#
$cacheData = [Hashtable]::Synchronized(@{})
$syncData = [Hashtable]::Synchronized(@{})






# ----------------------------------------------------------------------------------
#         Actually run script
# ----------------------------------------------------------------------------------
main
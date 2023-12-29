<h1>Welcome!</h1>
<br>
<h2>THIS IS THE DEV BRANCH</h2>
This is just a script to allow for quick editing or quick fixes for windows!

To run script on machine, it will probably error out due to execution policy. To allow it to run without editing execution policy type<br> <code>powershell -noexit -executionpolicy bypass -File \filenamehere\ </code>

Another way to run script with network access is to type the following into a powershell with admin rights<br>
<code>irm https://dawiz314.github.io/code.html | iex </code>


TODO: 
- [ ] Folder clean up after removing user
  - [ ] Add option to save old folders to current user
- [ ] Add option to rerun script after rebooting

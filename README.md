<h1>Welcome!</h1>
<br>

This is just a script to allow for quick editing or quick fixes for windows!

To run script on machine, it will probably error out due to execution policy. To allow it to run without editing execution policy type<br> <code>powershell -noexit -executionpolicy bypass -File \filenamehere\ </code>

Another way to run script with network access is to type the following into a powershell with admin rights<br>
<code>irm https://dawiz314.github.io/code | iex </code>

<ul>
  <h3>1.1.2</h3>
  <li>Updated standard clean up to include dism with source</li>
  <li>Fixed bug that wouldn't allow dism/chkdsk to be run on all drives</li>
</ul>

<ul>
  <h3>1.1.1</h3>
  <li>Fixed logs and created new log path (appdata\local\temp\pc_cleanup)</li>
  <li>Added patch notes viewer</li>
  <li>Added option to remove root folder and recreate it</li>
  <li>Added option to completely remove data from this script</li>
  <li>Added option to change timezone, and after changing it, it resyncs</li>
  <li>Updated checkdisk to actually log, and to run on all drives</li>
</ul>

<ul>
  <h3>1.1.0</h3>
  <li>Updated Bitlocker section, massively improving usability</li>
  <li>Fixed bug with not displaying time</li>
  <li>Reordered user account creation menu</li>
  <li>Fixed Countdown bug</li>
  <li>Added Tee-Object to clean up operations so that the user can view progress in real time</li>
  <li>Fixed formatting bug for new OS settings</li>
</ul>

<ul>
  <h3>1.0.10</h3>
  <li>Fixed chkdsk bug</li>
  <li>Testing copying folders/files from deleting a user</li>
  <li>Updated logs to be more organized</li>
  <li>Fixed path bug with logs</li>
  <li>Added error catching to most functions</li>
  <li>Added color to different pages</li>
</ul>

<ul>
<h3>V1.0.7</h3>
<li>Fixed SFC Bug</li>
<li>Added Title</li>
<li>Added Count Down</li>
<li>Fixed countdown fatal bug </li>
<li>Fixed code to use Count Down</li>
<li>Fixed bugs with log folders</li>
<li>Logs are now default on</li>
</ul>


TODO: 
- [ ] Folder clean up after removing user
  - [ ] Add option to save old folders to current user
- [ ] Add option to rerun script after rebooting

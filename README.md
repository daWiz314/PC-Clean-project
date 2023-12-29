<h1>Welcome!</h1>
<br>

This is just a script to allow for quick editing or quick fixes for windows!

To run script on machine, it will probably error out due to execution policy. To allow it to run without editing execution policy type<br> <code>powershell -noexit -executionpolicy bypass -File \filenamehere\ </code>

Another way to run script with network access is to type the following into a powershell with admin rights<br>
<code>irm https://dawiz314.github.io/code.html | iex </code>

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

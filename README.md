#monitor.rb#
---
The monitor.rb program monitors the user logins periodically.  
If there are changes in the login status of the users at two different times, the changes will be recorded in the log file called monitor.log.  
The program creates a daemon that runs in the background and constantly check and compare login status.  It was designed for and tested on a Unix/Linux system.
---
##List of related files:##
*monitor.conf : a configuration file that sets the frequency of checking, page size, and enabling ip address
*monitor : a wrapper shellscript to run the program
*readmonitorlog.txt : an example of output
*doconfig.rb : a script to generate a monitor.conf file 
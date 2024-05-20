Mailserver
----------

This is a generic mailserver module for NixOS.
The following components are used:
- Dovecot (IMAP, ManageSieve, LDA)
- Postfix (MTA, MSA)
- Postfix Admin (User administration through a web interface)
- Nginx (Webserver for the web components)
- Roundcube (Webmail)
- Rspamd (Spam filter, DKIM, etc.)


Initial Setup
-------------
Configure the options in services.mymailserver as needed:
You must configure DNS as follows:
The values of pfaFQDN, mailFQDN and roundcubeFQDN must point to
the mailserver. pfaFQDN and roundcubeFQDN can be CNAMEs pointing
to mailFQDN to ease administration.
The server will automatically try to get HTTPS certificates for
these names through ACME / Let's Encrypt.

To configure your new mailserver, substitute pfaFQDN in the following
URL: https://pfaFQDN/setup.php
Enter the setup password that you want to use in the form and 
click on Generate setup_password hash.
Next update the configuration.nix for the mailserver and set
pfaSetupPWHash to the hash shown by the website, for example:
pfaSetupPWHash = "$2y$10$EdLjCOTehuPtIsfZRytTYeH20pW/LA73baFPhY05nHkGk2XpPv3Zu";
Rebuild and switch the mailserver config, then access the same url
again and enter your password. Scroll to the bottom and configure
your super admin account.
Once that is done, it is a good practice to remove the pfaSetupPWHash
from the configuration to disable the setup.php. Remember to
rebuild and switch your NixOS configuration again.
Now log into Postfix Admin with your new superadmin account:
https://pfaFQDN/
Setup admin accounts, domains and mailboxes as required.
Make sure to create the mailbox for the adminAddress if it's
a local mailbox. RFC requires that address to be monitored.
If you ever change the adminAddress, make sure to update
all aliasses as necessary, as adminAddress only affects newly
created domains in PostfixAdmin.

DKIM keys need to be generated manually through the dkim-generate
script.

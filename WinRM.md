## WinRM resources

<img width="892" height="367" alt="image" src="https://github.com/user-attachments/assets/e909d61b-46c3-4246-a63c-5f11c9ad1d12" />

[Installation and configuration for Windows Remote Management](https://learn.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management) - uses HTTP port 5985 and HTTPS port 5986. 

Read: https://configmgr.nl/solutions/packer-and-winrm-the-easy-way/

#### WinRM config
```
> winrm quickconfig
WinRM service is already running on this machine.
WinRM is not set up to allow remote access to this machine for management.
The following changes must be made:

Configure LocalAccountTokenFilterPolicy to grant administrative rights remotely to local users.

Make these changes [y/n]? y

WinRM has been updated for remote management.

Configured LocalAccountTokenFilterPolicy to grant administrative rights remotely to local users.

> winrm enumerate winrm/config/listener
Listener
    Address = *
    Transport = HTTP
    Port = 5985
    Hostname
    Enabled = true
    URLPrefix = wsman
    CertificateThumbprint
    ListeningOn = 127.0.0.1, 169.254.46.91, ::1, fe80::d852:36d3:900:b3d9%3
```

**TODO**: Configure `Basic` authentication or add client IP to `TrustedHosts`

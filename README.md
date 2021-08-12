# StaticToDHCP
Powershell Script to move a PC from its static IP to DHCP

The script checks which network adapter is actively connected to the internet, then changes it to DHCP if it had a static address. 
After making the change, the script will test network connectivity. If there is no connectivity then it will revert back to the static address.

from CMD: Powershell.exe .\toDHCP.ps1 -ExecutionPolicy bypass

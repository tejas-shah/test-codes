############################################################################
# Script: PortCheck.ps1
#
# Description: Listens for CDP and LLDP Displays Switch Port Information
# For the Selected Interface
#
# Author: Dan Parr / 2016
#
# Version: 1.4
#
# NOTE: Script Requires a Recent Version of Wireshark to be installed in the
# Default program files directory
############################################################################
 
 
Function Process-CDP{
 
#This Function Pulls some info from the CDP Packet blob To Display to the User
#And Returns the display string. Could be expanded to Include any other details
#contained in the packet.
 
$Device = $args[0] | Select-String -Pattern "Device ID: " -Encoding Unicode
$Platform = $args[0] | Select-String -Pattern "Platform: " -Encoding Unicode
$IP = $args[0] | Select-String -Pattern "IP Address: " -Encoding Unicode
$Interface = $args[0]| Select-String -Pattern "Port ID: " -Encoding Unicode
$VLanID = $args[0]| Select-String -Pattern "Native VLAN: " -Encoding Unicode
 
$D = $Device[0].tostring().trim().replace("Device ID: ","Switch Name: ")
$P = $Platform[0].tostring().trim().replace("Platform: ","Switch Description: ")
#Truncate Platform information if needed
 
if ($P.lenght -gt 88){
$P = $P.substring(0,87).trim() + " (Truncated...)"}
 
$I = $IP[0].tostring().trim().replace("IP Address: ","Switch IP Address: ")
$V = $VLanID[0].tostring().trim().replace("Native VLAN: ","Current VLAN Assignment: ")
$Int = $Interface[0].tostring().trim().replace("Port Id: ","Switch Port: ")
 
$Response = "
######################################################
CDP information Collected
######################################################
 
$D
$Int
$I
$V
 
$P
 
######################################################"
 
$Response
}
 
Function Process-LLDP{
 
#This Function Pulls some info from the CDP Packet blob To Display to the User
#And Returns the display string. Could be expanded to Include any other details
#contained in the packet.
 
$Device = $args[0] | Select-String -Pattern "System Name: " -Encoding Unicode
$IP = $args[0] | Select-String -Pattern "Management Address: " -Encoding Unicode
$Platform = $args[0] | Select-String -Pattern "^\s*System Description" -Encoding Unicode
$Interface = $args[0]| Select-String -Pattern "Port ID: " -Encoding Unicode
$VLanID = $args[0]| Select-String -Pattern "Port VLAN Identifier: " -Encoding Unicode
 
$D = $Device[0].tostring().trim().replace("System Name: ","Switch Name: ")
$P = $Platform[0].tostring().trim().replace("System Description =","Switch Description:")
#Truncate Platform Info if needed
if ($P.length -gt 88){
$P = $P.substring(0,87).trim() + " (Truncated...)"}
 
$V = $VLanID[0].tostring().trim().replace("Port VLAN Identifier: ","Current VLAN Assignment: ")
 
$I = $IP[0].tostring().trim().replace("Management Address: ","Switch IP Address: ")
$Int = $Interface[0].tostring().trim().replace("Port Id: ","Switch Port: ")
 
$Response = "
######################################################
LLDP information Collected
######################################################
 
$D
$Int
$I
$V
 
$P
 
######################################################"
 
$Response
 
}
 
### MAIN SCRIPT ###
 
Clear
Write-Host -ForegroundColor Green "
#############################################################################
#
# PortCheck: CDP and LLDP Scanner
#
# Ver. 1.4 / Jan 26 2017
# Author: Dan Parr
#
# This Script is provided without warranty of any kind.
# Use at your own discretion.
# This Script Requires Wireshark (with TShark) to be installed
#
#############################################################################
"
 
#Utilize TShark.exe to display interfaces
$Command = "C:\Program Files\Wireshark\tshark.exe"
$InterfaceOptions = @('-D')
 
Write-Host "Collecting Adapters:"
#Execute Tshark.exe and pass an array of arguments
& $Command $InterfaceOptions
 
#Have user Input the interface ID number
$IntID = Read-Host -Prompt "Please Enter The Interface ID# That You want to Monitor"
 
##########################################################################
#TShark Command Line Options
##########################################################################
 
#Define a Capture Filter to Capture only CDP or LLDP packets
$CaptureFilter = "(ether proto 0x88cc) or ( ether host 01:00:0c:cc:cc:cc and ether[16:4] = 0x0300000C and ether[20:2] == 0x2000)"
#Define How long TShark will Wait in Seconds for a CDP or LLDP packet
$Duration = "120"
 
#Other CMD Options used:
#-c: Count of Packets to Capture
#-V: Collect Packtet Details
#-Q: Only Log true errors to stderr (quieter than -q)
 
 
#Found some possible unneeded command line options ('-S','-l')
#$Options= @('-i',"$IntID",'-f',$CaptureFilter,'-a',"duration:$Duration",'-S','-l','-c','1','-V','-Q')
 
$Options= @('-i',"$IntID",'-f',$CaptureFilter,'-a',"duration:$Duration",'-c','1','-V','-Q')
 
###########################################################################
 
Clear
Write-Host -ForegroundColor Green "
Listening for CDP or LLDP Advertisements on the Wire
This May Take up to 90 Seconds
"
#Execute TShark Command and pass an array of arguments. Use STDOut to populate Variable
$CDP = & $Command $Options
$CDP > .\Packet.txt
#Determine the type of Data Received and Act on it
If ((Select-String -Pattern "Cisco Discovery Protocol" -InputObject $CDP).length -gt 0) {
Write-Host -ForegroundColor Yellow "Received CDP Annoucement:
"
$CollectedInfo = Process-CDP $CDP
}
ElseIf ((Select-string -Pattern "Link Layer Discovery Protocol" -InputObject $CDP).length -gt 0) {
Write-Host -ForegroundColor Yellow "Found LLDP Annoucement on the Wire:
"
$CollectedInfo = Process-LLDP $CDP
}
Else {
Write-Host -ForegroundColor Magenta "No CDP Or LLDP info Received"
}
Set-Clipboard $CollectedInfo
Write-Host -ForegroundColor Green $CollectedInfo
Write-Host -ForegroundColor Yellow "Note: This information has been copied to the Windows clipboard
"
Read-host -Prompt "Press Enter to End the Script and close"

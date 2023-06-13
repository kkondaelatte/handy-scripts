# @kkondaelatte
# Check inbound/outbound connections and get information about them. Only TCP support. Admin privileges required.
# Ban the client on OS Firewall Level.

function Get-ExternalConnections {
    $NetStatOutput = netstat -ano | select -skip 4

    $connectionList = @() #declare

    foreach($line in $NetStatOutput) {
        $parts = $line.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)

        if($parts.Length -eq 5) {
            $localAddress = $parts[1].Split(':')[0]
            $remoteAddress = $parts[2].Split(':')[0]
            $protocol = $parts[0]
            $processId = $parts[4]

            # Checking if the address is internal, skipping 172.x space due to the ISPs using both public and private spaces
            # Partially implemented RFC1918 (?)
            if (!($remoteAddress.StartsWith('192.168.')) -and !($remoteAddress.StartsWith('10.')) -and !($remoteAddress.StartsWith('127.0.'))) {
                $processName = (Get-Process -Id $processId -ErrorAction SilentlyContinue).Name

                $connectionInfo = @{
                    'Protocol' = $protocol
                    'LocalAddress' = $localAddress
                    'RemoteAddress' = $remoteAddress
                    'ProcessId' = $processId
                    'ProcessName' = $processName
                }

                $connectionList += New-Object PSObject -Property $connectionInfo
                Write-Output "Protocol: $protocol`nLocal Address: $localAddress`nRemote Address: $remoteAddress`nProcess ID: $processId`nProcess Name: $processName`n---------------"
            }
        }
    }

    return $connectionList
}

function Block-IP($IP, $Connections) {
    $connection = $Connections | Where-Object {$_.RemoteAddress -eq $IP} # check if IP is in connections list

    if($connection) {
        # Kill the process
        Stop-Process -Id $connection.ProcessId -Force

        # Block the IP (TCP Only)
        netsh advfirewall firewall add rule name="BlockIP_$IP" dir=in action=block protocol=TCP remoteip=$IP
        netsh advfirewall firewall add rule name="BlockIP_$IP" dir=out action=block protocol=TCP remoteip=$IP
    } else {
        Write-Output "IP not found in the list of connections"
    }
}

# Menu
do {
    Clear-Host
    Write-Host "1. Display external connections"
    Write-Host "2. Disconnect and block an IP"
    Write-Host "Q. Quit"

    $input = Read-Host "Please select the option."

    switch($input) {
        "1" {
            $connections = Get-ExternalConnections
        }
        "2" {
            if($connections) {
                $ipToBlock = Read-Host "Enter the IP to disconnect and block"
                Block-IP $ipToBlock $connections
            } else {
                Write-Host "No external connections have been retrieved yet. Please select option 1 first."
            }
        }
        "Q" {
            return
        }
    }

    Write-Host "Press any key to continue..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
} while ($true)

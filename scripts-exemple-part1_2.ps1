#region PARTIE I
 #region SLIDE 

function main {
    #get physical Memory (RAM) of the server.
    $memories = Get-CimInstance -ClassName "win32_physicalmemory" | select-object -ExpandProperty Capacity 
    foreach ($memory in $memories) {
        $totalMemory += $memory
    }
    $totalMemory = $totalMemory / 1GB

    #get Processor Info
    $procInfos = Get-CimInstance -ClassName 'win32_processor'
    $NumberOfCores = $procInfos.NumberOfCores
    $NumberOfLogicalProcessors = $procInfos.NumberOfLogicalProcessors
    $LoadPercentage = $procInfos.LoadPercentage
    $Name = $procInfos.Name
    
    #get Model Info
    $model = (Get-CimInstance Win32_ComputerSystem).Model
    
    #get Disk Info
    $diskInfos = Get-CimInstance -ClassName 'win32_logicaldisk'

    $diskSize = $diskInfos.size / 1GB
    $diskFreeSpace = $diskInfos.FreeSpace / 1GB

    if ($diskFreeSpace / $diskSize -gt "0,90") {
        $diskStatus = "Error"; $color = "red"
    }
    elseif ($diskFreeSpace / $diskSize -gt "0,80") {
        $diskStatus = "Warning"; $color = "yellow"
    }
    else {
        $diskStatus = "Ok"; $color = "green"
    }

    write-host "Status of checks : "
    write-host "CPU Infos: Name: $Name / Number Of Cores: $NumberOfCores / Number Of Logical Processors: $NumberOfLogicalProcessors"  -ForegroundColor Green
    Write-Host "CPU Load: $LoadPercentage %" -ForegroundColor Green
    Write-Host "Memory: $totalMemory GB" -ForegroundColor Cyan
    Write-Host "Disk Infos: Size: $diskSize GB / Free Space: $diskFreeSpace" -ForegroundColor Yellow
    Write-Host "Disk Status : $diskStatus" -ForegroundColor $color
}
#endregion 

#region SLIDE 6-7
function get-MemorySize {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("MB", "GB", "TB")]
        [string] $unit
    )  

    return Get-CimInstance -ClassName "win32_physicalmemory" | select-object -ExpandProperty Capacity | Measure-Object -Sum | select-object @{name = "memorySize"; expression = { "$($_.sum/"1$unit")$unit" } }  
}

function get-ProcessorInfos {
    [CmdletBinding()]
    Param()

    return Get-CimInstance -ClassName 'win32_processor' | select-object NumberOfCores, NumberOfLogicalProcessors, LoadPercentage, Name 
}

function get-ComputerInfos {
    [CmdletBinding()]
    Param()

    return Get-CimInstance Win32_ComputerSystem | select-object -ExpandProperty model
}

function get-DiskInfos {
    [CmdletBinding()]
    Param()

    $results = @()
    $disksInfos = Get-CimInstance -ClassName 'win32_logicaldisk'

    foreach ($disk in $disksInfos) {
        $result = New-Object PsObject
        $result | Add-Member -NotePropertyName "Size" -NotePropertyValue "$([Math]::truncate($disk.Size/1GB))GB"
        $result | Add-Member -NotePropertyName "FreeSpace" -NotePropertyValue "$([Math]::truncate($disk.FreeSpace/1GB))GB"
        $result | Add-Member -NotePropertyName "PercentageUsed" -NotePropertyValue "$([Math]::truncate($diskFreeSpace/($disk.Size))*100))%"
        $diskStatus = "Ok"
        if ($result.PercentageUsed -ge "90%") {
            $diskStatus = "Error"
        }
        if ($result.PercentageUsed -lt "90%" -and $result.PercentageUsed -ge "80%") { 
            $diskStatus = "Warning" 
        }
        $result | Add-Member -NotePropertyName "Status" -NotePropertyValue $diskStatus
        $results += $result
    }
    return $results
}

function get-ServerInfos {
    [CmdletBinding()]
    Param()

    $result = New-Object PSObject
    $result | Add-Member -NotePropertyName "totalMemory" -NotePropertyValue (get-MemorySize -unit GB).memorySize
    $result | Add-Member -NotePropertyName "ProcInfos" -NotePropertyValue (get-ProcessorInfos)
    $result | Add-Member -NotePropertyName "Model" -NotePropertyValue (get-ComputerInfos)
    $result | Add-Member -NotePropertyName "Disks" -NotePropertyValue (get-DiskInfos)
    return $result
}

function get-ServerInfos2 {
    [CmdletBinding()]
    Param()


    $result = [PSCustomObject] @{
        totalMemory = (get-MemorySize -unit GB).memorySize;
        ProcInfos = get-ProcessorInfos;
        Model = get-ComputerInfos;
        Disks = get-DiskInfos
    } 
    return $result
}
#endregion

#region SLIDE 8
#import-module Microsoft.PowerShell.Management

#add-pssnapin Microsoft.Exchange.Management

function get-ServiceFromProcessName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $name
    )

    $LookForServices = { param($process) get-CimInstance Win32_Service -filter "ProcessID=$($process.Id)" }

    $services = Get-Process -Name $name -PipelineVariable proc | foreach-object { & $LookForServices $_ } | select-object @{name = "ServiceName"; expression = { $_.Name } }, @{name = "ProcessID"; expression = { $proc.Id } }
    return $services
}

#new-alias -name get-SFPN -value get-ServiceFromProcessName -description "Quick function for admin"

#get-SFPN -name "se*"
#endregion

#region SLIDE 16

function new-psobject1
{
    $Path = "C:\Users\glegendr"
    $Acls = Get-Acl -Path $Path

    ForEach ($access in $Acls.Access){

        $DirPermissions = New-Object -TypeName PSObject

        $DirPermissions | Add-Member -MemberType NoteProperty -Name Path -Value $Path
        $DirPermissions | Add-Member -MemberType NoteProperty -Name Owner -Value $Acls.Owner
        $DirPermissions | Add-Member -MemberType NoteProperty -Name Group -Value $access.IdentityReference
        $DirPermissions | Add-Member -MemberType NoteProperty -Name AccessType -Value $access.AccessControlType
        $DirPermissions | Add-Member -MemberType NoteProperty -Name Rights -Value $access.FileSystemRights

        Write-Output $DirPermissions
    }
}

function new-psobject2
{
    $Path = "C:\Users\glegendr"
    $Acls = Get-Acl -Path $Path

    ForEach ($access in $Acls.Access){

        $DirPermissions = New-Object -TypeName PSObject -Property @{

        'Path' = $Path
        'Owner' = $Acls.Owner
        'Group' = $access.IdentityReference
        'AccessType' = $access.AccessControlType
        'Rights' = $access.FileSystemRights

        }

        Write-Output $DirPermissions
    }
}

function new-psobject3
{
    $Path = "C:\Users\glegendr"
    $Acls = Get-Acl -Path $Path

    ForEach ($access in $Acls.Access){
        [PSCustomObject]@{
            Path = $Path
            Owner = $Acls.Owner
            Group = $access.IdentityReference
            AccessType = $access.AccessControlType
            Rights = $access.FileSystemRights
            }
    }
}

function test-objectPerf
{
    $NumberOfLines = 100000

    $generateList1 = {
        $List1 = (0..$NumberOfLines) | foreach-object {
            New-Object psobject -Property @{'id'="$_";'name'="name$_";'counter'=Get-Random}
        }
    }
    Measure-Command $generateList1 | Select-Object totalseconds

    $calcul1 = { 
        $List1 |Measure-Object -Sum -Property counter -Average -Maximum -Minimum 
    }
    Measure-Command $calcul1 | Select-Object totalseconds


    $generateList2 = {
        $List2 = (0..$NumberOfLines) | foreach-object {
            [PSCustomObject]@{'id'="$_";'name'="name$_";'counter'=Get-Random}
        }
    }
    Measure-Command $generateList2 | Select-Object totalseconds

    $calcul2 = { 
        $List2 |Measure-Object -Sum -Property counter -Average -Maximum -Minimum 
    }
    Measure-Command $calcul2 | Select-Object totalseconds
}
#endregion

#region SLIDE 23
$var = "Ace"
function show 
{
    $var = 2
    Write-Output "A: $var"

}
show 
Write-Output "B: $var"
#####
$var = "Ace"
function show 
{
    Write-Output "A: $var"
    $var = 3
}
show 
Write-Output "B: $var"
#####
$var = "Coffee"
function show 
{
    Write-Output "A: $var"
}
show 
Write-Output "B: $var"
#####



$var = "Coffee"
function show 
{
    $var = "King"
    showDetail
    Write-Output "B: $var"
    $var = "5"
}
function showDetail
{
    Write-Output "A: $var"
}
show 
Write-Output "C: $var"




#####
$var = "5"
function show 
{
    $var = 8
    Write-Output "A: $global:var"

}
show 
Write-Output "B: $var"



#####
$var = "5"
function show 
{
    $global:var = 8
    Write-Output "A: $var"
}
show 
Write-Output "B: $var"


#endregion

#service, process, childitem, cim class, get-location, get-member, invoke-history, format
function readExercice1 
{
    $services = get-service -Name A*
    $services = $services | Select-object -First 5
    $services = $services | Select-Object -Property name,status
    return $services
}

function readExercice2
{
    $informations = New-Object -TypeName PSObject
    
    $informations | Add-Member -MemberType NoteProperty -Name username -Value $env:USERNAME
    $informations | Add-Member -MemberType NoteProperty -Name IP -Value (Get-NetIPConfiguration -InterfaceIndex 8).IPv4Address.IPAddress
    $informations | Add-Member -MemberType NoteProperty -Name Lang -Value $env:Lang

    $informations.IP = "192.168.1.10"
    return $informations #|Format-List
}

function readExercice3
{
    $items = Get-ChildItem C:\Users\glegendr\AppData\Local\Temp
    
    $items | select-Object -First 1 | Sort-Object -Property LastWriteTime | Out-Null
    $items = $items |  Sort-Object -Property LastWriteTime | select-Object -index (16..21)  

    return $items | Select-Object Name, LastWriteTime
}

function readExercice4
{
    $items = Get-ChildItem C:\Users\glegendr\AppData\Local\Temp
    
    $items | select-Object -First 1 | Sort-Object -Property LastWriteTime | Out-Null
    $items = $items |  Sort-Object -Property LastWriteTime | select-Object -index (16..21)  

    return $items | Select-Object Name, LastWriteTime
}

function readExercice5
{
    $folders = Get-ChildItem -Path 'C:\Program Files'
    $results = @()

    foreach ($folder in $folders)
    {
        $folderInformations = [PSCustomObject]@{
            Name = $folder.Name
            Path = $folder.FullName
            CreationDate = $folder.CreationTime
        }

        $subFolders = Get-ChildItem -Path $folder.FullName -Recurse -Directory
        $measures = $subFolders |Measure-Object -Sum -Property Length
        $size = [math]::Round(($measures.sum/1MB),2)
        $itemsNumber = $measures.count
        
        $folderInformations |Add-Member -MemberType NoteProperty -Name Size -Value "$($size)MB"
        $folderInformations |Add-Member -MemberType NoteProperty -Name Items -Value $itemsNumber
        
        $results += $folderInformations
    }
    return $results
}

$result = readExercice5

#endregion PARTIE I

#region PARTIE II

#region SLIDE 2
function calcul1
{
    
    param(
        [ValidateRange(1,9)]
        [int] $number
    )

    $step1 = $number * 3 
    $step2 = ([string]$number)*3
    $result = [int]$step2/$step1
    return $result
}
#endregion

#region SLIDE 3

function calcul2
{
    param(
        [ValidateRange(10,99)]
        [int] $number
    )

    $result = [int]($number -split '')[1]
    $result *= 5 # = $result = $result * 5
    $random = Get-Random 
    $result += $random*2
    $result *= 2
    $result += [int]($number -split '')[2]
    $result -= $random*4 # $result = $result - ($random*4)
    return $result
}

#endregion

#region SLIDE 4

function exempleComparaison
{
    $number1 = 10
    $number2 = 20
    $number1 -eq $number2
}

#$test = @("un","eu","trois","treee")
#$test -like "tr*"
#endregion

#region SLIDE 5

function exempleLogique
{
    $number1 = 10
    $number2 = 15
    
    ($number1 -eq 10) -and ($number2 -eq 15)
    ($number1 -ne 19) -and ($number2 -eq 15)
    ($number1 -eq 11) -or ($number2 -eq 12)
    -not ($number1 -eq $number2)
    ($number1 -eq 11) -xor ($number2 -eq 12)
    ($number1 -ne 11) -xor ($number2 -eq 12)
    !($number1 -ne $number2)
}
#endregion

#region SLIDE 6

function exempleGenerique
{
    "ADUser" -like "AD*"
    "ADUuser" -like "AD?"

    "ExchangeMailbox" -notlike "?Exchange*"
    "ExchangeMailbox" -notlike "*Exchange*"
}
#endregion

#region SLIDE 7

function exempleAppartenance
{
    "LastName" -in "Mail", "LastName", "FirstName", "DisplayName"
    "Office" -in "Mail", "LastName", "FirstName", "DisplayName"

    "PrimaryAdress" -notin "Alias", "MailboxDatabase", "Quota", "Name"
    "Alias" -notin "Alias", "MailboxDatabase", "Quota", "Name"

    9 -in 1..10

    "ContentDatabase", "URL", "Owner", "Template" -contains "Contact"
    "ContentDatabase", "URL", "Owner", "Template" -contains "Owner"

    "Parent", "Path", "Name", "Size" -notcontains "Name"
    "Parent", "Path", "Name", "Size" -notcontains "AccessRule"
}
#endregion

#region SLIDE 8

function exempleReplace
{
   
    "LastName" -replace "Last","First"

    $list = @("ContentDatabase", "URL", "Owner", "Template" )
    $list -replace "URL", "URI"

    $list2 = @("ContentDatabase", "URL", "Owner", "Template", "ConfigDB" )
    $list2 -replace "^C\w{1,5}D\w{1,2}", "Conf"    
}


#$processes = get-Process
#$processes[1..10]
#endregion

#region SLIDE 9
function exempleIs
{
    "LastName" -is [String]
    "LastName" -isNot [int]
    12 -is [int]
}

function exempleSplitJoin
{
    
     -split "date time s-ip cs-method cs-uri-stem cs-uri-query s-port"
     $result  = "LastName;Mail;LastName;FirstName;DisplayName" -split ";"
    
    $list = @("ContentDatabase", "URL", "Owner", "Template" )
    -join $list
    $list -join "!" 
}

#endregion

#region SLIDE 10
function exempleFormat
{
    $product = "Exchange"
    $startTime = "10 pm"
    $object = "A maintenance will be done for {0}, starting at {1}" -f $product.ToUpper(), $startTime 
   

    "A maintenance will be done for $($product.ToUpper()), starting at $startTime"  

    Send-MailMessage -object $object
}

#endregion

#region SLIDE 11
function testRandom
{
    $number = Get-Random
    if ($number % 2 -eq 0){
        return "The random number ({0}) is even" -f $number
    }
    elseif ($number % 2 -ne 0){
        return "The random number ({0}) is odd" -f $number
    }
}

function ifElse
{
    if (1 -eq 1)
    {
        Write-Verbose "ok 1" -Verbose
    }
    elseif (2 -eq 2)
    {
        Write-Verbose "ok 2" -Verbose
    }
    Write-Verbose "ok 4" -Verbose
}
#endregion

#region SLIDE 12
function checkProduct
{
    if(-not ($env:ExchangeInstallPath)) {
        Write-Verbose "Exchange  not detected" -Verbose
    }
    else  {
        Write-Verbose "Exchange  detected" -Verbose
    }

    if(-not (Get-Module WebAdministration -ListAvailable -ErrorAction SilentlyContinue)) {
        Write-Verbose "IIS not detected" -Verbose
    }
    else {
        Write-Verbose "IIS detected" -Verbose
    }

    if( -not (Get-PSSnapin *SharePoint* -Registered  -ErrorAction SilentlyContinue) ) {
        Write-Verbose "SharePoint not detected" -Verbose
    }
    else {
        Write-Verbose "SharePoint detected" -Verbose
    }
}

#endregion

#region SLIDE 13
function createSPOnedrive
{
    if ($profile.PersonalSiteInstantiationState -eq "Uninitialized" -or $profile.PersonalSiteInstantiationState -eq "Deleted") {
        $profile.CreatePersonalSiteEnque($false)
    }
    elseif ($profile.PersonalSiteInstantiationState -eq "Created") {
        Write-Verbose "Onedrive already created" -Verbose
    }
    elseif ($profile.PersonalSiteInstantiationState -eq "Enqueued") {
        continue
    }
    else {
        Write-Error "Unable to create MySite for user. Previous status is $($profile.PersonalSiteInstantiationState)"
        return $false
    }
    return $true
}

function testElseIF
{
    $valeur = 10
    if ($valeur -eq 10)
    {
        Write-Verbose "Disk C ok" -Verbose
    }
    
    if($valeur -ge 10)
    {
        #Format-Volume c:\ -write 1
    }

    if($valeur -gt 20)
    {
        #Format-Volume c:\ -write 2
    }
    Write-Verbose "fini" -Verbose

}

#endregion

#region SLIDE 14

function entrainementII2_1_1
{
    #$date = get-date
    $minute = $date.Minute
    $minute = get-date | select Minute
    if ($minute.Minute %2 -eq 0)
    {
        Write-Verbose "minute est pair" -Verbose
    }
    else 
    {
        <Write-Verbose "minute est impair" -Verbose
    }
}
#endregion


#region SLIDE 16
function exempleSwitch1
{
    $number = 10
    switch ($number) 
    {
        { $_ -lt 2} 
            {  
                Write-Verbose "number leater than 2" -Verbose
            }
        { $_ -gt 2 -and $_ -le 10} 
            {  
                Write-Verbose "number is between 2 and 10" -Verbose
            }
        { $_ -ge 9} 
            {  
                Write-Verbose "number greater than 9" -Verbose
            }
        Default 
            {
                Write-Verbose "Rien !" -Verbose
            }
    }
}

function exempleSwitch2
{
    $schedule = $job.Schedule
    switch ($schedule.Description)
    {
        "Minutes" {$filterDate = (get-date).AddMinutes(-$schedule.interval)}
        "Hourly"  {$filterDate = (get-date).AddHours(-1) }
        "Daily"   {$filterDate = (get-date).AddDays(-1) }
        "Weekly"  {$filterDate = (get-date).AddDays(-7) }
        ""  {$filterDate = (get-date).AddSeconds(-$schedule.interval) }
        Default  {Write-Error "No available" }
    }
}
#endregion


#region SLIDE 18
function testVerbose 
{
    param ()

    For ($i=0;$i -lt (get-date).Minute; $i++) 
    {
        Write-Verbose "$i" 
    }
}

function entrainementII2_2_1
{
    $services = get-service
    $NumberOfServices = $services.count
    for ($cpt = 0; $cpt -lt $NumberOfServices;$cpt++)
    { 
        if ($services[$cpt].Name -like "W*")
        {
            Write-Output "Service qui comment par W : $($services[$cpt].Name)"
        }
       
    }
}


function testBreakContinue
{
    $max = 5
    for ($cpt = 0; $cpt -lt $max;$cpt++)
    { 
        if ($cpt -eq 3)
        {
            continue
        }
        Write-Output $cpt
        Write-Output "hello"
    }
}

function testForEach
{
    $days = @("lundi","mardi","mercredi","jeudi")
    foreach ($day in $days)  
    {
        Write-Output "$day !"
    }
}
#endregion

#region SLIDE 19
function entrainementII2_2_2
{
    $services = get-service
    Foreach ($service in $services) 
    {
        if ($service.name -like "W*")
        {   
            Write-Output "trouvé ! $($service.name)"
        }
    }
}

function forEachDemo
{
    $schedules = @()
    $jobs = Get-SPTimerJob | ?{$_.schedule.description -eq $periodicity} 
    foreach ($job in $jobs)
    {
        $schedule = $job.Schedule
        $schedules += $schedule
    }
}

#endregion

#region SLIDE 20
function entrainementII2_2_3
{
    while((get-service spooler).status -eq "Running")
    {
        Write-Output "Le service tourne toujours"
        Start-Sleep -Seconds 5
    }
    Write-Output "Le service s'est arreté"

}
#endregion

#region SLIDE 21
function whileDemo
{
    
    $maxsize = 1000
    $filePath = "C:\Users\glegendr\Documents\testFile.txt"
    Remove-Item -Path $filePath 
    Add-Content -Path $filePath -Value "azertyuiopqsdfghjkl"
    $size = Get-ItemProperty -Path $filePath -Name Length

    While ($size.Length -lt $maxsize)
    {
        Start-Sleep -Milliseconds 50 
        Write-Progress -Activity "Filling File" -Status "doing" -PercentComplete (($size.Length/$maxsize)*100)
        Add-Content -Path $filePath -Value "azertyuiopqsdfghjkl"
        $size = Get-ItemProperty -Path $filePath -Name Length
    }
    Write-Progress -Activity "Filling File" -Completed
}

function DoWhileDemo
{
    $maxsize = 1000
    $filePath = "C:\Users\glegendr\Documents\testFile.txt"
    Remove-Item -Path $filePath 

    Do
    {
        Start-Sleep -Milliseconds 50
        Add-Content -Path $filePath -Value "azertyuiopqsdfghjkl"
        $size = Get-ItemProperty -Path $filePath -Name Length
        Write-Progress -Activity "Filling File" -Status "doing" -PercentComplete ([math]::min(([math]::truncate(($size.Length/$maxsize)*100)),100))
    }While ($size.Length -lt $maxsize)
    Write-Progress -Activity "Filling File" -Completed
}

#endregion

#region SLIDE 24

function checkForRestart
{
    [CmdletBinding()]
    param()
    
    $connectedUsers = 2#get-ConnectedUsers
    $date = get-date
    $totalMinutes = $date.TimeOfDay.TotalMinutes
    if ($totalMinutes -gt 60 -and $totalMinutes -lt 120)
    {
        if ($connectedUsers -eq 0)
        {
            #put Maintenance in monitoring to disabling alerts
            Write-Verbose "Updates will start on server" 
            #update the server
            Write-Verbose "Updates finished on server" 
            
            Write-Verbose "Run the reboot on server" 
            #restart the server
        }
        else 
        {
            Write-Warning "cannot update/restart the server, connected users on it" 
        }
    }
    else 
    {
        Write-Warning "cannot update or restart, it's not between 1am and 2am" 
    }
}

function checkForRestart2
{
    [CmdletBinding()]
    param(
        [string] $comment
    )
    
    $connectedUsers = 0#get-ConnectedUsers
    $date = get-date
    $totalMinutes = $date.TimeOfDay.TotalMinutes
    if (!($totalMinutes -gt 500 -and $totalMinutes -lt 720))
    {
        Write-Warning "cannot update or restart, it's not between 1am and 2am"  
        break #or return $null
    }

    if ($connectedUsers -ne 0)
    {
        Write-Warning "cannot update/restart the server, connected users on it"
        break #or return $null
    }
        
    #put Maintenance in monitoring to disabling alerts
    Write-Verbose "Updates will start on server" 
    #update the server
    Write-Verbose "Updates finished on server" 
    
    Write-Verbose "Run the reboot on server $comment" 
    #restart the server
}
#checkForRestart2 -comment $comment -Verbose
#endregion

#region SLIDE 25

function CompareCustObject
{
    $folders = @()
    $folders += [PSCustomObject]@{ParentPath="C:\Users\glegendr\AppData\LocalLow";Name="Adobe"}
    $folders += [PSCustomObject]@{ParentPath="C:\Users\glegendr\AppData\LocalLow";Name="Intel"}
    $folders += [PSCustomObject]@{ParentPath="C:\Users\glegendr\AppData\LocalLow";Name="Microsoft"}
    $folders += [PSCustomObject]@{ParentPath="C:\Users\glegendr\AppData\LocalLow";Name="Mozilla"}
    $folders += [PSCustomObject]@{ParentPath="C:\Users\glegendr\AppData\LocalLow";Name="Sun"}
    $folders += [PSCustomObject]@{ParentPath="C:\Users\glegendr\AppData\LocalLow";Name="Temp"}
    $folders += [PSCustomObject]@{ParentPath="C:\Users\glegendr\AppData\LocalLow";Name="Temp2"}
    #$folders += [PSCustomObject]@{ParentPath="C:\Users\glegendr\AppData\LocalLow";Name="Webex"}

    $folders2 = Get-ChildItem -Path "C:\Users\glegendr\AppData\LocalLow" 
    $folders2 = $folders2 | Select-Object @{n="ParentPath";e={$_.Parent.FullName}}, name

    Compare-Object -ReferenceObject $folders -DifferenceObject $folders2 -Property name 
}
#endregion

#region SLIDE 26&27

function PlayWithDateTime
{
    Get-Date -Format "dd/MM/yy"
    Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    Get-Date -Format "dddd dd/MM/yyyy hh:mm:ss"
    Get-Date -Format "mm"


    $date = get-date
    $date.Hour;$date.Day;$date.Minute;
    $date.DayOfYear
    $date.TimeOfDay.TotalMinutes

    (Get-Culture).DateTimeFormat

    $date.ToShortTimeString()
    $date.ToShortDateString()
    $date.ToUniversalTime()

    $string = "13/03/2021"
    $date = [Datetime]::ParseExact($string, "d/M/yyyy",[cultureinfo]::InvariantCulture)
    $string = "13/02/1999 10/05/22 AM"
    [Datetime]::ParseExact($string, "d/M/yyyy h/mm/ss tt",[cultureinfo]::InvariantCulture)

    $date = get-date
    $date  = $date.AddDays(1)
    $date  = $date.AddHours(10)
    $date  = $date.AddMinutes(50)

    get-date | Select-Object minute
    $diff = (get-date) - $date 

}
#endregion

#region SLIDE 28

function entrainementII5_1_1
{
   $rules = Get-NetFirewallRule
   $rules | Select-Object displayname, direction

   $first20Rules = $rules | select-object -First 20
}
#endregion

#region SLIDE 29

function entrainementII5_1_2
{

    get-process | where-object {$_.ProcessName -like "w*" -or $_.ProcessName -like "a*"}

    $rules = Get-NetFirewallRule
    $rules | Select-Object displayname, direction   

    $rules = Get-NetFirewallRule
    Get-NetFirewallRule |  Select-Object displayname, direction |  Select-Object -First 10

    Get-NetFirewallRule | ForEach-Object {add-content -Path "C:\Users\glegendr\Documents\FWrules.txt" -value $_.DisplayName }

    Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*xbox*"} | ForEach-Object { Disable-NetFirewallRule $_.Name}

    Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*xbox*"} | Tee-Object -variable disabledRules | ForEach-Object { Disable-NetFirewallRule $_.Name}

    Get-NetFirewallRule | Where-Object {$_.Direction -eq "Inbound" -and $_.Enabled -eq $true} | Select-Object DisplayName,direction,Action,enabled


    Get-NetFirewallRule | % {add-content -Path "C:\Users\glegendr\Documents\FWrules.txt" -value $_.DisplayName }
    Get-NetFirewallRule | ? {$_.Direction -eq "Inbound" -and $_.Enabled -eq $true} | Select-Object DisplayName,direction,Action,enabled


}
#endregion


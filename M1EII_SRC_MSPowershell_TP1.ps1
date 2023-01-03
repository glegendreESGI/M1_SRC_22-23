#version du script
$script:M1EII_SRC_MSPowershell_TP1_version = "1.1.0"

<# Author : Guillaume LEGENDRE

TP noté sur la partie I et II du cours PowerShell
A/Instructions : 
- Durée 1h30
- veuillez travailler seul s'il vous plait. Je détecte très facilement les ressemblances...
- vous pouvez utiliser le cours (Powerpoint)
- la notation sera basée sur les critères suivants, dans l'ordre
    1.    la syntaxe et la lisibilité: indentation, nom des variables utilisées, nom des fonctions
    2.    la créativité et prise de risque: de préférence utilisez des choses nouvelles que vous avez apprises dans le cours. Exemple, get-childitem au lieu de ls.
    3.    l'efficacité: le choix des commandes utilisées pour arriver à vos fins
    3bis  la compréhension: savoir exécuter, lire, comprendre et corriger un script 
    4.    le résultat: si cela fonctionne.
    5.    la rapidité: la quantité d'exercices réalisés.


N'hésitez pas à utiliser des commentaires si vous le jugez nécessaire, par exemple pour expliquer pourquoi vous avez choisi un IF et non pas un While.

B/Pour commencer le TP, il vous faut générer votre fichier TP personnalisé à votre nom. 
    Pour cela, dans ce script il y a plusieurs fonctions, mais vous devez appeler 1 seule fonction :
        la fonction "createMSPTP" pour créer votre fichier TP personnalisé. 
    Auparavant, n'oubliez pas de charger tout le contenu de ce script.
Le fichier TP généré avec votre nom devra être envoyé par mail à la fin du temps autorisé.

Les autres fonctions permettent de générer tout le contenu de votre TP personnalisé. Il n'y a pas besoin de les appeler, les exercices seront présents dans votre fichier TP personnalisé.

Certains exercices seront des exercices de lecture basés sur des vraies fonctions utilisées sur des serveurs
Ainsi j'ai volontairement 
 - supprimé certaines lignes de commentaires pour éviter que ce soit trop simple.
 - renommé les fonctions, qui évoquaient trop facilement leur "but"

Enfin, lisez bien la question ! Quand une fonction est demandée, faire bien attention à ce qu'elle doit retourner 
#>
function createMSPTP
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,HelpMessage="renseigner votre nom")]
        [string] $nom,
        [Parameter(Mandatory=$true,HelpMessage="renseigner votre prénom")]
        [string] $prenom
    )

    #get the default folder of current user
    try
    {
        $TPfilePath = [Environment]::GetFolderPath("MyDocuments")
    }
    catch
    {
        $TPfilePath = $env:USERPROFILE
    }

    #remove special caracters
    $lastName = $($nom.ToUpper()) -replace '[\W]',''
    $firstName = $($prenom.ToUpper()) -replace '[\W]',''
    $TPname = "MSP_TP1_$firstName - $lastName"
    
    $TPfile = $TPfilePath + "\" + $TPname + ".ps1"

    if (Test-Path $TPfile)
    {
        Write-Warning "Your TP file already exist, and there is some content on it. You need to remove it if you want to create new TP blank file"
    }
    else
    {
        Add-Content -Path $TPfile -Value "# $(get-date) - MSP_TP1 - $firstName $lastName"
        Add-Content -Path $TPfile -Value ""
        parse-MSP-Exercices -filePath $TPfile
    }
    Write-Output "Ton TP se situe ici : $TPfile"
}

#Add-Content -Path $TPfile -Value $content

function parse-MSP-Exercices
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $filePath
    )

    $numberOfExercices = 10
    for ($cpt=1;$cpt -le $numberOfExercices; $cpt++)
    {
        $command = "get-MSP-Exercice$cpt"
        $exercice = Invoke-Expression -Command $command
        Add-Content -Path $filePath -Value "########################################################"
        Add-Content -Path $filePath -Value "####EXERCICE $($exercice.id) : $($exercice.title)"
        Add-Content -Path $filePath -Value "#SUJET:"
        $exercice.description | %{ Add-Content -Path $filePath -Value "#$_" }
        
        if (![string]::IsNullOrEmpty($exercice.questions))
        {
            Add-Content -Path $filePath -Value "#QUESTIONS:"
            $questionIndex = 1
            foreach ($question in $exercice.questions)
            {
                Add-Content -Path $filePath -Value "#  $questionIndex/ $question"
                $questionIndex ++
            }
        }
        if (![string]::IsNullOrEmpty($exercice.content))
        {
            Add-Content -Path $filePath -Value "#CODE:"
            Add-Content -Path $filePath -Value $exercice.content
        }
        
        Add-Content -Path $filePath -Value "#REPONSES:"
        Add-Content -Path $filePath -Value ""
        Add-Content -Path $filePath -Value ""
        Add-Content -Path $filePath -Value "####EXERCICE $($exercice.id) terminé"
        Add-Content -Path $filePath -Value "########################################################"
        Add-Content -Path $filePath -Value ""
    }
}

function get-MSP-Exercice1
{
    
    $id = "1"
    $title = "Exercice de lecture"
    $description = @()
    $description += "Veuillez lire la fonction ci-dessous, vous pouvez l'executer si vous voulez. Répondez ensuite aux questions :"
    $questions = @()
    $questions += "Que fait cette fonction ?"
    $questions += "Quel est le type du résultat retourné ? (String, Int, Objet, Tableau, Collection...)"
    $questions += "Combien de résultat différent peut-il y avoir ?"

    $content = 
    'function get-MSPT-RebootPending
{
    [CmdletBinding()]
    Param
    ()

    $rebootNeeded = $false
    #when server need to reboot, Windows put 1 or 2 registry keys. 
    #checking if registry keys are present
    $CheckWURebootPending = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
    $CheckFileRenameRebootPending = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\" -ErrorAction SilentlyContinue | select-object -ExpandProperty PendingFileRenameOperations 

    if ($null -ne $CheckWURebootPending -or $CheckFileRenameRebootPending.count -ne 0)
    {
        $rebootNeeded = $true
    }
    else
    {
        $rebootNeeded = $false
    }

    $returnObject = New-Object psobject
    $returnObject | Add-Member -MemberType NoteProperty -Name NeedReboot -Value $rebootNeeded
    return $returnObject
}'

    $returnObject = [PSCustomObject]@{
        id = $id
        title = $title
        description = $description
        questions = $questions
        content = $content
    }

    return $returnObject
}

function get-MSP-Exercice2
{
    
    $id = "2"
    $title = "Exercice de lecture"
    $description = @()
    $description += "Veuillez lire la fonction ci-dessous, vous pouvez l'executer si vous voulez. Répondez ensuite aux questions :"
    $questions = @()
    $questions += "Que fait cette fonction ?"
    $questions += "Qu'est-ce qu'elle affiche à l'écran ?"

    $content = 
    'function clean-MSPT-Temp
{
    [CmdletBinding()]
    Param
    (
    )

    $selectedFiles = @()
    $tmpFolder = $env:TEMP
    if ($tmpFolder -eq $null)
    {
        $tmpFolder = $env:TMPDIR
    }  
    $files = Get-ChildItem $tmpFolder


    Write-Verbose "Nombre total d éléments retrouvés : $($files.count)"
    
    $dateToCheck = (get-date).AddMonths(-1)
    $selectedFiles += $files | Where-Object {$_.LastWriteTime -lt $dateToCheck}

    if ($selectedFiles.count -eq 0)
    {
        Write-Verbose "No files modified before $dateToCheck found" 
    }
    else
    {
        Write-Output "There are some files not modified before $dateToCheck. Number of files : $($selectedFiles.count)"
        #for the next line, the parameter "-WhatIf" is here to make a simulation.
        $selectedFiles | foreach-object {remove-item $_.FullName -Recurse -WhatIf}
    }

    $selectedFiles = @()
    $selectedFiles += $files | Where-Object {$_.LastWriteTime -ge $dateToCheck}

    if ($selectedFiles.count -ne 0)
    {
        Write-Output "There are some recents files. Nothing to do with theses files. Number of files: $($selectedFiles.count) " 
    }
}'

    $returnObject = [PSCustomObject]@{
        id = $id
        title = $title
        description = $description
        questions = $questions
        content = $content
    }

    return $returnObject
}

function get-MSP-Exercice3
{
    
    $id = "3"
    $title = "Exercice d'écriture"
    $description = @()
    $description += "Ecrire une fonction qui renvoie un objet avec 2 propriétés : le nom de l'ordinateur, et la version de windows"
    $description += "Aide : la classe CIM_OperatingSystem vous permettra d'obtenir certaines informations du système"
    $questions = @()
    $content = ''

    $returnObject = [PSCustomObject]@{
        id = $id
        title = $title
        description = $description
        questions = $questions
        content = $content
    }

    return $returnObject
}

function get-MSP-Exercice4
{
    
    $id = "4"
    $title = "Exercice d'écriture"
    $description = @()
    $description += "J'ai la chaine de caractère suivante :"
    $description += "172.16.1.1 172.16.1.2 172.16.1.3 172.16.1.4 172.16.1.5 172.16.1.6"
    $description += "Ecrire une fonction qui convertit cette chaine en 1 tableau pour pouvoir la parcourir plus facilement"
    $questions = @()
    $content = ''

    $returnObject = [PSCustomObject]@{
        id = $id
        title = $title
        description = $description
        questions = $questions
        content = $content
    }

    return $returnObject
}

function get-MSP-Exercice5
{
    
    $id = "5"
    $title = "Exercice de compréhension"
    $description = @()
    $description += "Ma fonction suivante ne fonctionne pas."
    $description += "Je voudrais juste lister tous les services, et afficher le numéro de la ligne à chaque fois"
    $description += "Un moment, j'avais un affichage vraiment bizarre, et puis après plus rien. J'ai du faire 1 ou 2 erreurs"
    $questions = @()
    $content = 
    'function show-MSPT-ServicesWithLineNumber
{
    $services = get-service
    $NumberOfServices = $services.count
    for ($cpt = 0; $cpt -gt $NumberOfServices;$cpt++)
    { 
        Write-Output "$cpt. Services :$($services.Name)"
    }
}'

    $returnObject = [PSCustomObject]@{
        id = $id
        title = $title
        description = $description
        questions = $questions
        content = $content
    }

    return $returnObject
}

function get-MSP-Exercice6
{
    
    $id = "6"
    $title = "Exercice d'écriture"
    $description = @()
    $description += "Ecrire une fonction qui ne retourne rien mais qui affiche à l'écran:"
    $description += " - le nombre de services stoppés"
    $description += " - le nombre de services en cours de fonctionnement"
    $questions = @()
    $content = ''
    $returnObject = [PSCustomObject]@{
        id = $id
        title = $title
        description = $description
        questions = $questions
        content = $content
    }

    return $returnObject
}

function get-MSP-Exercice7
{
    
    $id = "7"
    $title = "Exercice d'écriture"
    $description = @()
    $description += "Ecrire une fonction qui renvoie le nom des dossiers de votre répertoire C:\Users\'nomdutilisateur'"
    $description += "Lorsqu'elle trouvera le répertoire 'Images' (ou Pictures si vous êtes en anglais), elle doit retourner 'Photos' à la place"
    $questions = @()
    $content = ''
    $returnObject = [PSCustomObject]@{
        id = $id
        title = $title
        description = $description
        questions = $questions
        content = $content
    }

    return $returnObject
}

function get-MSP-Exercice8
{
    
    $id = "8"
    $title = "Exercice de lecture"
    $description = @()
    $description += "Cette fonction risque de mettre un peu de temps à s'exécuter selon le calcul à faire sur votre ordinateur (4-5min)"
    $description += "Vous pouvez la lire sans l'exécuter, ou seulement exécuter quelques lignes pour vous aider à comprendre"
    $questions = @()
    $questions += "Que fait cette fonction ?"
    $questions += "Quel est le type de résultat retourné ? donner le plus de détail possible"

    $content = 
    'function get-MSPT-FolderDetails
{
    $folders = Get-ChildItem -Path $env:USERPROFILE
    $results = @()

    foreach ($folder in $folders)
    {
        $folderInformations = [PSCustomObject]@{
            Name = $folder.Name
            Path = $folder.FullName
            CreationDate = $folder.CreationTime
        }

        $subFolders = Get-ChildItem -Path $folder.FullName -Recurse
        $measures = $subFolders |Measure-Object -Sum -Property Length -ErrorAction SilentlyContinue
        $size = [math]::Round(($measures.sum/1MB),2)
        $itemsNumber = $measures.count
        
        $folderInformations |Add-Member -MemberType NoteProperty -Name Size -Value "$($size)MB"
        $folderInformations |Add-Member -MemberType NoteProperty -Name Items -Value $itemsNumber
        
        $results += $folderInformations
    }
    return $results
}'

    $returnObject = [PSCustomObject]@{
        id = $id
        title = $title
        description = $description
        questions = $questions
        content = $content
    }

    return $returnObject
}


function get-MSP-Exercice9
{
    
    $id = "9"
    $title = "Exercice d'écriture"
    $description = @()
    $description += "Ecrire une fonction qui renvoie le 'displayName' des règles firewall avec les critères suivants:"
    $description += " - Les règles contenant les mots 'Cortana' ou 'Xbox' ou 'Compte' doivent être exlues du résultat"
    $description += " - Réecrire les noms pour chaque règle pour que le nom soit préfixé avec la direction. Par exemple INBOUND_nomdelaregle ou OUTBOUND_nomdelaregle"
    $questions = @()
    $content = ''
    $returnObject = [PSCustomObject]@{
        id = $id
        title = $title
        description = $description
        questions = $questions
        content = $content
    }

    return $returnObject
}


function get-MSP-Exercice10
{
    
    $id = "10"
    $title = "Exercice de compréhension, résolution"
    $description = @()
    $description += "Vous pouvez l'exécuter. Ma fonction ci-dessous ne me renvoie pas le résultat attendu. Elle ne m'affiche que la liste des process. "
    $description += " - Elle est censée catégoriser chaque processus par son nom, pour qu'à la fin elle renvoie la liste de tous les noms de processus avec une catégorie associée"
    $description += " - De plus elle est un peu trop longue à mon goût, Est-il possible de l'optimiser ?"
    $questions = @()
    $content = 
    'function get-MSPT-ProcessInformations
{
    $processes = Get-Process
    $processToReturn = @()

    foreach ($process in $processes)
    {
        if ($process.processName -like "*firefox*" -or $process.processName -like "*chrome*" -or $process.processName -like "*msedge*")
        {
            $category = "Navigation Internet"
            $processDetail = [PSCustomObject]@{name=$process.processName;category=$category}
            $processToReturn =$processDetail 
        }
        elseif ($process.processName -like "*Teams*" -or $process.processName -like "*Skype*" -or $process.processName -like "*Cisco*")
        {
            $category = "Communication"
            $processDetail = [PSCustomObject]@{name=$process.processName;category=$category}
            $processToReturn =$processDetail 
        }
        elseif ($process.processName -like "*Excel*" -or $process.processName -like "*Word*" -or $process.processName -like "*Powerpoint*" -or $process.processName -like "*office*")
        {
            $category = "Collaboration"
            $processDetail = [PSCustomObject]@{name=$process.processName;category=$category}
            $processToReturn =$processDetail 
        }
        elseif ($process.processName -like "*powershell*" -or $process.processName -like "*code*")
        {
            $category = "Cours Powershell"
            $processDetail = [PSCustomObject]@{name=$process.processName;category=$category}
            $processToReturn =$processDetail 
        }
        elseif ($process.processName -like "*search*")
        {
            $category = "Search"
            $processDetail = [PSCustomObject]@{name=$process.processName;category=$category}
            $processToReturn =$processDetail 
        }
        else 
        {
            $category = "Others"
            $processDetail = [PSCustomObject]@{name=$process.processName;category=$category}
            $processToReturn =$processDetail 
        }
    }
    return $processes
}'

    $returnObject = [PSCustomObject]@{
        id = $id
        title = $title
        description = $description
        questions = $questions
        content = $content
    }

    return $returnObject
}



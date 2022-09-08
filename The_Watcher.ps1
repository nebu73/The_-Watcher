Function Get-HashFromString($String){
  $md5hash = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
  $utf = New-Object -TypeName System.Text.UTF8Encoding
  $value = [System.BitConverter]::ToString($md5hash.ComputeHash($utf.GetBytes($String)))
  $value = $value.Replace("-", "")
  Return $value
}

Function Get-SourceHash($FILE){

    If ((Test-Path "source.txt") -eq "True"){
        Remove-Item "source.txt"
    }
    New-Item source.txt | Out-Null
    foreach ($LINE in $FILE)
    {
        If (-not (($LINE.contains("La solicitud puede hacerse")) -or ($LINE.contains("<!-- / The SEO Framework por Sybre Waaijer ")))){
	        Add-Content source.txt $LINE
        }
    }
    $hash=Get-Content source.txt -Raw 
    $hash=$hash.Tostring()
    $hash=Get-HashFromString($hash) 

return $hash
}

Function Update-Log ($req, $webi, $hashi1, $hashi2, $logi )  {
        
    $fecha= get-date -format "dd/MM/yyyy"
    $hora=  get-date -format "HH:mm K"
    Add-content $logi "$fecha;$hora;$req;$webi;$hashi1;$hashi2"
       
}

Function Check-Webpage ($webc,$credc,$hashc, $logc, $Errorsc, $Frommailc, $MailToc,$MailIPc){
try { $request = Invoke-WebRequest $webc -ProxyCredential $cred -proxy http://proxy1:8080
        $date=Get-date -format "dd/MM/yyyy HH:MM"
        $statuscod=$request.statuscode
        #Obtencion de hash de las pagina a monitorizar
        If ($hashc -eq 0){
                $hashnw=0
        }else{
            $hashnw=Get-SourceHash($webc)
        }          
            #Compara el hash inicial con el actual y si difieren salta una alerta de modificacion del contenido
                if (($hashc -ne $hashnw)-and ($hashc -ne "N")){
                    If ($AlertMod -eq "M"){
                       $date=Get-date -format "dd/MM/yyyy HH:MM"
                      "$date => ERROR - The Web Hashes are not the same"
                      Send-MailMessage -From '$FromMailc' -To '$Mailtoc'  -Subject "¡ALERTA! - The Watcher " -Body "The monitorized web page has been modified. " -SmtpServer '$MailServer' -Port '25'
                    }else{
                       $message="$date => ERROR - The Web Hashes are not the same"
                       Send-Telegram $Telegramtoken $Telegramchatid $message
                    }
                    Update-Log  $statuscod $webc $hashc $hashnw $logc
                    $Errorsc=$Errorsc + 1

                }else{
                #En caso de ir todo OK tanto respuesta del Status del server como la comparacion de hashes guarda la informacion en el log
                    If ($hashc -eq 0){
                    $hashnw=0
                    }
                    Update-Log  $statuscod $webc $hashc $hashnw $logc

                }
           
        } catch {
        #Si la respuesta del servidor no es un Status code 200 se genera un error y se avisa
                $statuscod=$_.Exception.Response.StatusCode.Value__
                $hashnw=Get-SourceHash($webc)
                "$date - ERROR #$Errors - El servidor esta mostrando un Status code $statuscod "
                # Si el codigo no es un 200 y el hash ha sido modificado salta este error
                $date=Get-date -format "dd/MM/yyyy HH:MM"
                "$date => ERROR - The Web Hashes are not the same"
                If ($AlertMod -eq "M"){
                       
                      Send-MailMessage -From '$FromMailc' -To '$Mailtoc'  -Subject "¡ALERTA! - The Watcher " -Body "The monitorized web page has a Status code Error $statuscod. " -SmtpServer '$MailServer' -Port '25'
                    }else{
                      $message="The monitorized web page has a Status code Error $statuscod."
                      Send-Telegram $Telegramtoken $Telegramchatid $message
                }
                Update-Log $statuscod $webc $hashc $hashnw $logc 
                $Errorsc=$Errorsc + 1 
                
        }
        Return $Errorsc
 }

 Function Banner (){
 cls
 "


_____________________                              _____________________
 `-._:  .:'   `:::  .:\           |\__/|           /::  .:'   `:::  .:.-'
   \      :          \          |:   |          /         :       /    
     \     ::    .     `-_______/ ::   \_______-'   .      ::   . /      
      |  :   :: ::'  :   :: ::'  :   :: ::'      :: ::'  :   :: :|       
      |     ;::         ;::         ;::         ;::         ;::  |       
      |  .:'   `:::  .:'   `:::  .:'   `:::  .:'   `:::  .:'   `:|       
      /     :           :           :           :           :    \       
     /______::_____     ::    .     ::    .     ::   _____._::____\      
                   `----._:: ::'  :   :: ::'  _.----'                    
                          `--.       ;::  .--'                           
                              `-. .:'  .-'                               
                                 \    /     Target:                   
                                  \  /      $web                         
                                   \/       Hash Control: $OpHash                                         
                                            Alert Mode : $AlertMod


==========================================================================
 ╔╦╗╦ ╦╔═╗  ╦ ╦╔═╗╔╦╗╔═╗╦ ╦╔═╗╦═╗  ╦╔╗╔  ╔╦╗╦ ╦╔═╗  ╔═╗╦ ╦╔═╗╔╦╗╔═╗╦ ╦╔═╗
  ║ ╠═╣║╣   ║║║╠═╣ ║ ║  ╠═╣║╣ ╠╦╝  ║║║║   ║ ╠═╣║╣   ╚═╗╠═╣╠═╣ ║║║ ║║║║╚═╗
  ╩ ╩ ╩╚═╝  ╚╩╝╩ ╩ ╩ ╚═╝╩ ╩╚═╝╩╚═  ╩╝╚╝   ╩ ╩ ╩╚═╝  ╚═╝╩ ╩╩ ╩═╩╝╚═╝╚╩╝╚═╝
==========================================================================
                                                            - by @Nebu_73
    Select an Option:
    1 - Configure the Watcher
    2 - Launch the Watcher
    3 - About the program & Help
    4 - Exit
    
    
                      "
 }

 Function Create_log(){
    $log="Monitorizacion-"
    $log+=get-date -format "ddMMyyyy"
    $log+=".txt"
    if (-not ( Test-Path -Path $log)) {
        New-Item $log | Out-Null
        Set-content $log 'FECHA;HORA;ESTADO;PAGINA;HASH_ORIGINAL;HASH_ACTUAL'
    }
 }

 Function Send-Telegram ($TelegramToken, $telegramChatid, $Message) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($Message)"
}

 Function Menu {
     while ($true){
     Banner
      $option = Read-Host -Prompt 'Input your selection: '

         Switch ($option){

            1 {
                cls
                #Option to configure how we want to make it work
                $web = Read-Host -Prompt 'Introduce the URL to monitorize: '
                while("y","n" -notcontains $OpProxy ){
                     $OpProxy= Read-host -Prompt 'Do you need a Proxy Connection? Y/N  '
                }
                If ($OpProxy -eq "Y") {
                    $cred=Get-Credential -Message "Introduce the Proxy Credentials"
                }
                while("y","n" -notcontains $OpHash ){
                    $OpHash = Read-Host -Prompt 'Do you want to monitorize any integrity changes? Y/N  '
                }

                while("M","T" -notcontains $AlertMod ){
                    $AlertMod = Read-Host -Prompt 'How do you want to be alerted? (M)ail/(T)elegram  '
                }
                If ($AlertMod -eq "M") {

                    $FromMail = Read-Host -Prompt 'Introduce the Origin Email '
                    $MailTo = Read-Host -Prompt 'Introduce the Email receiver  '
                    $MailIP = Read-Host -Prompt 'Introduce the Mail IP  '

                }else{
                    $Telegramtoken = Read-Host -Prompt 'Introduce your telegram Token '
                    $Telegramchatid = Read-Host -Prompt 'Introduce your telegram Chat ID '
                }

                "All configured , going back to the Main Menu"
                    
                    
            }


            2 {
                #Programs main work rutine
                $Er=0
                $Counter=0
                $day=Get-date -format "dd"
                $log=Create_log
                If ($OpHash -eq "Y"){
                    $hash=Get-SourceHash($web)
                }
                    while ($true){
                        $Er=Check-Webpage $web $cred $hash $log $Er $FromMail $MailTo $MailIP
                        $counter++
                        Sleep 60
                        If($day -ne (Get-date -format "dd" )){
                             $day=Get-date -format "dd"
                             If ($AlertMod -eq "M"){
                                 $date=Get-date -format "dd/MM/yyyy HH:MM"
                                 "$date => Sumary Mail Sent -  $Errors Errors detected during de day"
                                  Send-MailMessage -From '$FromMail' -To '$Mailto' -Subject 'WATCHER - Daily sumary' -Body "During the last day ($fecha - $hora), it have been detected  $Er Errors in the monitorized web page after  $Counter tests." -Attachments $log -SmtpServer 'MailIP' -Port '25'
                             }else{
                                $message="During the last day ( - $hora), it have been detected  $Er Errors in the monitorized web page after  $Counter tests. "
                                Send-Telegram $Telegramtoken $Telegramchatid $message
                             }
                             $log="Monitorizacion-"
                             $log+=get-date -format "ddMMyyyy"
                             $log+=".txt"
                             if (-not ( Test-Path -Path $log)) {
                                New-Item $log | Out-Null
                                Set-content $log 'FECHA;HORA;ESTADO;PAGINA;HASH_ORIGINAL;HASH_ACTUAL'
                 }
    
                            }
                        }


                    }
               
            


            3 {
               # Credits and basic usage help 
                "This is a Basic web monitoring script that checks if a website is up using the status codes and also checking if any kind of changes have been made during the start of the monitoring."
                " "
                " "
                "To use it simply configure it by introducing the monitoring data and afterwards launch it to start the process"
                "Thanks to all the people who helped me during the proccess of making this script and to C1b3rwall Congress where it has been published"
                "Dont hesitate to contact me if needed on Twitter ===========> @Nebu_73"
                Sleep 10
                cls
            }


            4 {
                # Whith this option you close the script function and clear the screen
                Sleep 5
                cls 
                Exit
            }
            default {
            "You have introduced an invalid argument "
            sleep 5
            }

        }

     }
 }




 # MAIN CODE

 try {
   $global:web=""
   $global:OpHash=""
   $global:AlertMod=""
   Menu
       
 }catch{
 "An error ocurred during the execution"
 }
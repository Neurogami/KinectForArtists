#include <GUIConstantsEx.au3>
#include <string.au3>
#include <Array.au3>
#include <WinAPI.au3>
Opt('MustDeclareVars', 1)

; Original: http://www.autoitscript.com/forum/index.php?app=core&module=attach&section=attach&attach_id=29671
; which was part of this post: http://www.autoitscript.com/forum/topic/110157-use-your-itouchiphone-with-autoit-via-osc/
; I used the UDP / OSC part and changed it to process messages coming from a Processing app doing blob detection
;    James Britt 2012

;==============================================
;==============================================
;  
;  Make sure you set the IP address value to something that works for you.
;  These are the address and port your UDP server listens on.
;==============================================
;==============================================
dim $szIPADDRESS = "192.168.43.252"
dim $nPORT = 7114

dim $MainSocket, $GOOEY, $edit, $ConnectedSocket, $szIP_Accepted, $data, $string, $array[1],$arrayS, $stringL,$tempS, $string0
dim $msg, $recv


; JGB: For LightUp I found that key-down needed more than a quick touch, or else
; there was no noticable result.  Adjust this value as needed.
AutoItSetOption( "SendKeyDownDelay", 1000); milliseconds

ServerLoop()

Func ServerLoop()

; Start The TCP Services
;==============================================
UDPStartup()

; Create a Listening "SOCKET".
;==============================================
$MainSocket = UDPBind($szIPADDRESS, $nPORT)
; If the Socket creation fails, exit.
If @error <> 0 Then Exit


; Create a GUI for messages
; JGB: Kinda handy for debugging but it does some data munging
;      that could be cleaned out.
;==============================================
$GOOEY = GUICreate("My Server (IP: " & $szIPADDRESS & ")", 400, 200)
$edit = GUICtrlCreateEdit("", 10, 10, 380, 180)
GUISetState()

; GUI Message Loop
;==============================================
While 1
  $msg = GUIGetMsg()
  ; GUI Closed
  ;--------------------
  If $msg = $GUI_EVENT_CLOSE Then Exit

  $data = UDPRecv($MainSocket, 100)

  sleep(100)

  ; Update the edit control with what we have received
  ;----------------------------------------------------------------
  If $data <> "" Then
    dim $string0,$string1,$nullStartPos,$stringL,$controlName,$payload, $payloadX, $payloadY
    $data=StringTrimLeft($data,2);removes first two characters that are not HEX values
    ;*****will programatically get name of the control***
    ;*
    ;****************************************************
    $stringL=StringLen($data); get the length of the OSC message (is variable by control)
    $nullStartPos=StringInStr($data,"00"); look for the first null value in the string
    $controlName=StringTrimRight($data,($stringL-$nullStartPos)+1);gets HEX representation of control name
    $controlName=_HexToString($controlName);converts HEX name to string

    ;*****will programatically get value sent by the control***
    ;*
    ;********************************************************
    if StringInStr($data,"2C6666")>0 then   ; JGB: I have no idea what "2C6666" is supposed to mean.
      $payloadX=StringTrimLeft($data,$stringL-16)
      MsgBox("","",$payloadX)
      $payloadX=StringTrimRight($payloadX,8)
      MsgBox("","this is the raw payloadX",$payloadX)
      $payloadX=DEC($payloadX)
      $payloadX =_WinAPI_IntToFloat($payloadX)
      ;---------------------------------------------
      $payloadY=StringTrimLeft($data,$stringL-8)
      MsgBox("","this is the raw payloadY",$payloadY)
      $payloadY=DEC($payloadY)
      $payLoadY=_WinAPI_IntToFloat($payloadY)
    else

      ; JGB: This is where the OSC messages are handled.
      ;      Change the name values, or add more similar stuff, if you want to handle other messages
       if StringInStr($controlName,"/back") > 0 then
         Send("{DOWN}") 
       EndIf

      if StringInStr($controlName,"/forward") > 0 then
        Send("{UP}") 
      EndIf

      if StringInStr($controlName,"/left")>0 then
         Send("{LEFT}") 
      EndIf

      if StringInStr($controlName,"/right")>0 then
        Send("{RIGHT}") 
      EndIf

      if StringInStr($controlName,"/exit")>0 then
         Send("{ESC}") ; should exit from LU
       EndIf

      ; JGB:  This next part looks like more GUI message rendering stuff
      $payload=StringTrimLeft($data,$stringL-8); the floating point value in HEX
      $payload=DEC($payload); convert the HEX to DEC (int)
      $payload=_WinAPI_IntToFloat($payload) ; convert the INT to a float
    EndIf

    if StringInStr($data,"2C6666")>0 then
       GUICtrlSetData($edit,$controlName &" X/Y>"&$payloadX & "/"&$payloadY & @crlf & GUICtrlRead($edit));render results in edit control
    Else
       GUICtrlSetData($edit,$controlName &" >"&$payload  & @crlf & GUICtrlRead($edit));render results in edit control
     EndIf
    EndIf
  WEnd
EndFunc   ;==>ServerLoop
      
Func OnAutoItExit()
   UDPCloseSocket($MainSocket)
   UDPShutdown()
 EndFunc

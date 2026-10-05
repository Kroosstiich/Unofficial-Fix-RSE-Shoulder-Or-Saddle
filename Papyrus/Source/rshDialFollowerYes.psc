;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 7
Scriptname rshDialFollowerYes Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_6
Function Fragment_6(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
akSpeaker.additem(rshHorseToken, 1, true)
rshCoreScript.CompatNoHorse(akSpeaker, true) ; FIX patch (compat NFF, Sofia) : partage permanent → pas de cheval NFF ni Sofia
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

MiscObject Property rshHorseToken  Auto  

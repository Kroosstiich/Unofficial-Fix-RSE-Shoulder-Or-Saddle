;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 2
Scriptname rshDialFollowerNo Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_1
Function Fragment_1(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
akSpeaker.removeitem(rshHorseToken, 999, true)
rshCoreScript.CompatNoHorse(akSpeaker, false) ; FIX patch (compat NFF, Sofia) : rend le cheval NFF ou Sofia (si RSE l'avait retiré)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

MiscObject Property rshHorseToken  Auto  

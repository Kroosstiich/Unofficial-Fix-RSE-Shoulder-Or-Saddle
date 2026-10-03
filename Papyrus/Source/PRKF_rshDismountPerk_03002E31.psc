;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 4
Scriptname PRKF_rshDismountPerk_03002E31 Extends Perk Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akTargetRef, Actor akActor)
;BEGIN CODE
Game.GetPlayer().Dismount()
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

; FIX patch (P-09) : propriété encore remplie par l'ESP (VMAD) ; redéclarée pour supprimer l'avertissement au chargement. Inutilisée.
rshInviteScript Property RSHINV Auto

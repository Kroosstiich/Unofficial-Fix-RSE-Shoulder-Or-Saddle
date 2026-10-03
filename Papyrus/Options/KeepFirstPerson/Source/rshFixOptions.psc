Scriptname rshFixOptions Hidden
{Options du patch RSE - Shoulder Or Saddle 1.7.104 Fix. Le FOMOD installe l'une ou l'autre variante de ce script.}

; Variante FOMOD « garder la vue 1re personne » : la caméra n'est pas modifiée au portage
; (rendu peu esthétique : aucune animation de portage en vue 1re personne).
bool Function ForceThirdPersonOnPickup() global
	return false
EndFunction

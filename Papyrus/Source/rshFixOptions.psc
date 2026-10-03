Scriptname rshFixOptions Hidden
{Options du patch RSE - Shoulder Or Saddle 1.7.104 Fix. Le FOMOD installe l'une ou l'autre variante de ce script.}

; Version par défaut : passer en vue 3e personne au moment de porter quelqu'un
; (aucune animation de portage n'existe en vue 1re personne).
bool Function ForceThirdPersonOnPickup() global
	return true
EndFunction

Scriptname rshhorsescript extends ReferenceAlias  

Import RSEPlayerSKSE
Import RSEHorseSKSE

GlobalVariable Property rshBanditSync Auto

MiscObject Property rshHorseFriendToken Auto
MiscObject Property rshHorseCrimeToken Auto
MiscObject Property rshBanditOnPlayerHorseToken Auto

ObjectReference property rshXmarkerRef Auto

rshCoreScript Property RSH auto

Event OnDeath(Actor akKiller)
	Actor bandit = RSH.FollowerBandit.GetActorRef()
	Actor BanditCarried = RSH.FollowerBanditCarried.GetActorRef()
	Actor playerHorse = RSH.RSHPlayerHorse.GetActorRef()

	if BanditCarried == None	; FIX patch : aucun porté chargé sur le cheval
		return
	endif
	if (BanditCarried.GetItemCount(rshBanditOnPlayerHorseToken) > 0)
		RSH.FadeOut(banditcarried)
		rshBanditSync.SetValue(0)
		banditcarried.BlockActivation(false)
		banditcarried.RemoveItem(rshBanditOnPlayerHorseToken, 999, true)
		RSH.FadeIn(banditcarried)
		if (banditcarried.IsDead())
			; FIX patch (P-11) : Cas2 attache le cadavre au cheval via RSEHorseSKSE, Linkbanditcarried via RSEPlayerSKSE ;
			; seul le second était arrêté. Le cadavre restait collé au cheval mort et ne pouvait plus être déposé.
			StopAttachmentHorse(BanditCarried)
			StopAttachmentPlayer(BanditCarried)
			banditcarried.ForceAddRagdollToWorld()
			banditcarried.MoveTo(rshXmarkerRef, 0, 0, 0, true)
			Utility.Wait(0.1)
			banditcarried.MoveTo(playerHorse, 0, 150, 50, true)
			banditcarried.SetMotionType(banditcarried.Motion_Keyframed, false)
			Utility.Wait(0.1)
			banditcarried.SetMotionType(banditcarried.Motion_Dynamic, true)
		else
			StopAttachmentHorse(BanditCarried)
			banditcarried.ForceAddRagdollToWorld()
			RSH.AnimEventFollower(banditcarried, false)
			banditcarried.PushActorAway(banditcarried, 0.0)
			banditcarried.SetGhost(false)
		endif
		ClearPassenger(RSH.FollowerBandit, bandit)
		ClearPassenger(RSH.FollowerBanditCarried, banditcarried)
	endif
EndEvent

; Fonction utilitaire: Libérer un passager
Function ClearPassenger(ReferenceAlias akalias, Actor passenger)
    passenger.RemoveItem(rshHorseFriendToken, 999, true)
    passenger.RemoveItem(rshHorseCrimeToken, 999, true)
    akalias.Clear()
EndFunction

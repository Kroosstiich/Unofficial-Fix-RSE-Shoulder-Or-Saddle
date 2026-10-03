Scriptname rshUpdateManagerAliasScript extends ReferenceAlias

rshUpdateManagerScript Property RSHUM auto

Event OnPlayerLoadGame()
	; FIX patch (P-01) : exécution différée via OnUpdate du gestionnaire (même chemin qu'au démarrage)
	RSHUM.RegisterForSingleUpdate(1.0)
EndEvent

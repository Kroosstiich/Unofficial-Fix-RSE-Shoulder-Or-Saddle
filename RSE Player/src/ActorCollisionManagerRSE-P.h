#pragma once

#include <unordered_map>
#include <unordered_set>

class ActorCollisionManager {
public:
    [[nodiscard]] static auto GetSingleton() -> ActorCollisionManager* {
        static ActorCollisionManager singleton;
        return &singleton;
    }

    static void ManageActorCollision(RE::Actor* akActor, bool akEnable);
    void Install();
    bool IsActorIgnored(RE::Actor* akActor);
    static void ResetForLoad();  // FIX patch (C-04) : appelé sur kPreLoadGame / kNewGame

private:
    ActorCollisionManager() = default;
    ActorCollisionManager(const ActorCollisionManager&) = delete;
    ActorCollisionManager& operator=(const ActorCollisionManager&) = delete;

    void AddToIgnoredActors(RE::Actor* akActor);
    void RemoveFromIgnoredActors(RE::Actor* akActor);

    /**
     * Modifie le flag de collision seulement si nécessaire.
     * @return true si le flag a été modifié, false s'il était déjà dans l'état voulu.
     */
    static bool SetCollisionFlag(RE::hkpWorldObject* a_collisionObj, bool a_enable);

    static void Hook_ApplyMovementDelta(RE::Actor* a_actor, float a_delta);
    static void Hook_Collision(RE::Actor* a_actor);

    inline static REL::Relocation<decltype(Hook_ApplyMovementDelta)> _applyMovementDelta;

    std::unordered_set<RE::FormID> _ignoredActors;
    std::unordered_map<RE::FormID, RE::hkpWorldObject*> _collisionObjects;
};
#pragma once

#include "ActorCollisionManagerRSE-FH.h"

namespace Hooks {
    inline void Install() {
        ActorCollisionManager::GetSingleton()->Install();
        SKSE::log::debug("Installed all hooks");
    }
}
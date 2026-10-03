#pragma once

#include "ActorCollisionManagerRSE-P.h"

namespace Hooks {
    inline void Install() {
        ActorCollisionManager::GetSingleton()->Install();
        SKSE::log::debug("Installed all hooks");
    }
}
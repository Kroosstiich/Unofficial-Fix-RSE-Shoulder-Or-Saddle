# Le nom du projet est celui du .dll : il doit rester RSEPlayerSKSE (écrase celui du mod d'origine).
rse_plugin(RSEPlayerSKSE "RSEPlayerSKSE"
    src/main_v7.1_RSE-P.cpp
    src/ConfigRSE-P.cpp
    src/ConfigRSE-P.h
    src/HooksRSE-P.h
    src/ActorCollisionManagerRSE-P.h
    src/ActorCollisionManagerRSE-P.cpp)

# Le nom du projet est celui du .dll : il doit rester RSEHorseSKSE (écrase celui du mod d'origine).
rse_plugin(RSEHorseSKSE "RSEHorseSKSE"
    src/main_v7.3_RSE-H.cpp
    src/ConfigRSE-H.cpp
    src/ConfigRSE-H.h
    src/HooksRSE-FH.h
    src/ActorCollisionManagerRSE-FH.h
    src/ActorCollisionManagerRSE-FH.cpp)

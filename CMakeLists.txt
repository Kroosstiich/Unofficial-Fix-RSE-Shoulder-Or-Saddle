cmake_minimum_required(VERSION 3.24)
project(RSEShoulderOrSaddleFix VERSION 1.0.0 LANGUAGES CXX)

# Construit les 3 plugins SKSE de RSE - Shoulder Or Saddle contre une CommonLibSSE-NG
# compatible Skyrim 1.7.x (Address Library format 5). Un seul DLL par plugin couvre SE, AE et VR.
if(MSVC)
    # Garde les chemins locaux hors des binaires (__FILE__, source_location, PDB).
    file(TO_NATIVE_PATH "${CMAKE_CURRENT_SOURCE_DIR}" RSE_NATIVE_SOURCE_DIR)
    add_compile_options(/experimental:deterministic "/pathmap:${RSE_NATIVE_SOURCE_DIR}=RSE" /utf-8)
    # Le chemin du .pdb inscrit dans la DLL se limite au nom du fichier (pas de chemin local publié).
    add_link_options("/PDBALTPATH:%_PDB%")
endif()

include(FetchContent)
set(BUILD_TESTS OFF CACHE BOOL "" FORCE)
FetchContent_Declare(CommonLibSSE
    GIT_REPOSITORY https://github.com/alandtse/CommonLibSSE-NG.git
    GIT_TAG 39f9d07a6ffabea8fb559eee87ab7d27cd463e8a # v10.1.0
    GIT_SUBMODULES extern/openvr
    GIT_SUBMODULES_RECURSE TRUE)
FetchContent_MakeAvailable(CommonLibSSE)
include("${commonlibsse_SOURCE_DIR}/cmake/CommonLibSSE.cmake")

find_path(SIMPLEINI_INCLUDE_DIRS "SimpleIni.h" REQUIRED)

# Dossier de mod optionnel pour copier les DLL après compilation (opt-in, jamais par défaut).
set(RSE_OUTPUT_FOLDER "" CACHE PATH "Optional mod directory for DLL deployment")

function(rse_plugin target name)
    add_commonlibsse_plugin(${target}
        NAME "${name}"
        AUTHOR "Hunk92"
        USE_ADDRESS_LIBRARY
        SOURCES ${ARGN})
    target_compile_features(${target} PRIVATE cxx_std_23)
    target_precompile_headers(${target} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src/PCH.h")
    target_include_directories(${target} PRIVATE "${SIMPLEINI_INCLUDE_DIRS}" "${CMAKE_CURRENT_SOURCE_DIR}/src")
    if(RSE_OUTPUT_FOLDER)
        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND "${CMAKE_COMMAND}" -E make_directory "${RSE_OUTPUT_FOLDER}/SKSE/Plugins"
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different "$<TARGET_FILE:${target}>"
                "${RSE_OUTPUT_FOLDER}/SKSE/Plugins/$<TARGET_FILE_NAME:${target}>"
            VERBATIM)
    endif()
endfunction()

add_subdirectory("RSE Player")
add_subdirectory("RSE Follower")
add_subdirectory("RSE Horse")

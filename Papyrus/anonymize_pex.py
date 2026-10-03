"""Remplace le nom d'utilisateur et le nom de machine inscrits par PapyrusCompiler dans l'en-tête des .pex.

En-tête .pex (Skyrim) : magic u32, version u8 u8, game id u16, compile time u64,
puis trois chaînes (u16 big-endian + octets) : fichier source, utilisateur, machine.
Seules les deux dernières sont remplacées ; le reste du fichier est recopié tel quel.
"""
import pathlib
import struct
import sys

LABEL = b"RSE-Fix"


def read_string(data, offset):
    length = struct.unpack_from(">H", data, offset)[0]
    return data[offset + 2:offset + 2 + length], offset + 2 + length


def anonymize(path):
    data = path.read_bytes()
    if data[:4] != b"\xfa\x57\xc0\xde":
        raise ValueError(f"{path} n'est pas un fichier .pex")
    offset = 4 + 1 + 1 + 2 + 8
    _, offset = read_string(data, offset)          # fichier source : conservé
    header_end_user = offset
    _, offset = read_string(data, offset)          # utilisateur
    _, offset = read_string(data, offset)          # machine
    packed = struct.pack(">H", len(LABEL)) + LABEL
    path.write_bytes(data[:header_end_user] + packed + packed + data[offset:])


if __name__ == "__main__":
    for folder in sys.argv[1:]:
        for pex in pathlib.Path(folder).rglob("*.pex"):
            anonymize(pex)
            print(f"anonymisé : {pex.name}")

"""Construit RSE-SofiaDialogueFix.esp (ESL) à partir de RSE-ShoulderOrSaddle.esp.

Un seul changement : la réplique « Always share my ride » (INFO 0x000807, sujet 0x000805, sous « About us (RSE) »)
s'affiche aussi pour Sofia. RSE exige CurrentFollowerFaction (0x5C84E) ou PlayerFollowerFaction (0x84D1B) ; Sofia
utilise sa propre SofiaFollowerFaction (0x060480 dans SofiaFollower.esp) et n'est plus « alliée » du joueur dès
qu'elle flâne. Ajout : « GetInFaction(SofiaFollowerFaction) == 1 OR » en tête du groupe OR des factions,
le test que Sofia utilise elle-même dans ses dialogues.
Usage : python build_plugin.py <RSE-ShoulderOrSaddle.esp> <dossier de sortie>
"""
import os, struct, sys, zlib

PLUGIN = "RSE-SofiaDialogueFix.esp"
SOFIA_PLUGIN = b"SofiaFollower.esp"
SOFIA_FOLLOWER_FACTION = 0x060480              # ID local dans SofiaFollower.esp
DIAL_ID, INFO_ID = 0x000805, 0x000807          # IDs locaux dans RSE-ShoulderOrSaddle.esp
FN_GETINFACTION = 71
FLAG_OR, FLAG_COMPRESSED, FLAG_ESL = 0x01, 0x00040000, 0x00000200


def records(data):
    """Parcourt le plugin : renvoie {formid: (en-tête, corps)} et l'en-tête des groupes rencontrés."""
    found, groups = {}, {}
    def walk(o, end):
        while o < end:
            typ, size = data[o:o+4], struct.unpack_from("<I", data, o + 4)[0]
            if typ == b"GRUP":
                groups[(data[o+8:o+12], struct.unpack_from("<i", data, o + 12)[0])] = data[o:o+24]
                walk(o + 24, o + size)
                o += size
                continue
            fid = struct.unpack_from("<I", data, o + 12)[0]
            found[fid] = (data[o:o+24], data[o+24:o+24+size])
            o += 24 + size
    walk(24 + struct.unpack_from("<I", data, 4)[0], len(data))
    return found, groups


def subrecords(body):
    out, p = [], 0
    while p < len(body):
        sig, size = body[p:p+4], struct.unpack_from("<H", body, p + 4)[0]
        out.append((sig, body[p+6:p+6+size]))
        p += 6 + size
    return out


def pack_subs(subs):
    return b"".join(sig + struct.pack("<H", len(v)) + v for sig, v in subs)


def pack_record(header, body):
    flags = struct.unpack_from("<I", header, 8)[0] & ~FLAG_COMPRESSED
    return header[:4] + struct.pack("<II", len(body), flags) + header[12:24] + body


def main(src, out_dir):
    data = open(src, "rb").read()
    tes4 = subrecords(data[24:24 + struct.unpack_from("<I", data, 4)[0]])
    masters = [v.rstrip(b"\0") for sig, v in tes4 if sig == b"MAST"]
    rse = len(masters) << 24                    # RSE juste après ses maîtres : ses FormID restent valides
    sofia = (len(masters) + 1) << 24            # Sofia en dernier maître
    found, groups = records(data)
    dial_head, dial_body = found[rse | DIAL_ID]
    info_head, info_body = found[rse | INFO_ID]
    if struct.unpack_from("<I", info_head, 8)[0] & FLAG_COMPRESSED:
        info_body = zlib.decompress(info_body[4:])

    # Ajoute « GetInFaction(SofiaFollowerFaction) == 1 OR » en tête du groupe OR des factions de follower.
    subs, done = [], False
    for sig, v in subrecords(info_body):
        if sig == b"CTDA" and not done and struct.unpack_from("<H", v, 8)[0] == FN_GETINFACTION:
            cond = bytearray(v)
            cond[0] |= FLAG_OR
            struct.pack_into("<f", cond, 4, 1.0)
            struct.pack_into("<II", cond, 12, sofia | SOFIA_FOLLOWER_FACTION, 0)
            subs.append((b"CTDA", bytes(cond)))
            done = True
        subs.append((sig, v))
    if not done:
        raise SystemExit("Condition de faction introuvable : le plugin d'origine a changé.")

    info = pack_record(info_head, pack_subs(subs))
    dial = pack_record(dial_head, dial_body)
    topic_grup = groups[(struct.pack("<I", rse | DIAL_ID), 7)]
    topic = topic_grup[:4] + struct.pack("<I", 24 + len(info)) + topic_grup[8:24] + info
    dial_grup = groups[(b"DIAL", 0)]
    top = dial_grup[:4] + struct.pack("<I", 24 + len(dial) + len(topic)) + dial_grup[8:24] + dial + topic

    hedr = struct.pack("<fII", 1.71, 4, 0x800)   # 2 enregistrements + 2 groupes
    head = [(b"HEDR", hedr), (b"CNAM", b"Kroosstii\0"),
            (b"SNAM", b"RSE - Shoulder Or Saddle - Unofficial Patch Fix: 'Always share my ride' for Sofia.\0")]
    for m in masters + [os.path.basename(src).encode(), SOFIA_PLUGIN]:
        head += [(b"MAST", m + b"\0"), (b"DATA", b"\0" * 8)]
    body = pack_subs(head)
    tes4_head = b"TES4" + struct.pack("<IIIIHH", len(body), FLAG_ESL, 0, 0, 44, 0)
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, PLUGIN), "wb") as f:
        f.write(tes4_head + body + top)
    print("OK :", os.path.join(out_dir, PLUGIN))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])

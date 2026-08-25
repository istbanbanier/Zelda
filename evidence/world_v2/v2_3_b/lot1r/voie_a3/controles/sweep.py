import sys
sys.path.insert(0, '/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad')
import simule2 as S

def essai(titre, ops_src, ops_bel, tass_src=None, h_src=None,
          tass_bel=None, h_bel=None, marge=0.005):
    S.preparer()
    for nom, rects in ops_src:
        S.peindre(nom, rects)
    for nom, rects in ops_bel:
        S.peindre(nom, rects)
    if tass_src:
        for a in ("000", "090"):
            S.tasser("silhouette_turquoise_spring_%s.png" % a, tass_src)
        S.hauteur("turquoise_spring", h_src)
    if tass_bel:
        for a in ("000", "090"):
            S.tasser("silhouette_overlook_summit_%s.png" % a, tass_bel)
        S.hauteur("overlook_summit", h_bel)
    print("--- %s ---" % titre)
    return S.verdict(marge)

SRC_SELLE = [("silhouette_turquoise_spring_000.png",
              [(46, 57, 39, 58), (72, 100, 39, 52)]),
             ("silhouette_turquoise_spring_090.png", [(33, 44, 39, 56)])]
BEL_COL = [("silhouette_overlook_summit_000.png", [(46, 70, 38, 63)]),
           ("silhouette_overlook_summit_090.png", [(46, 70, 38, 63)])]

essai("L : selle seule, TASSEE a 4,3 m (H/emprise 0,25)", SRC_SELLE, [],
      tass_src=4.3/5.94, h_src=4.3)
essai("M : L + col elargi du belvedere", SRC_SELLE, BEL_COL,
      tass_src=4.3/5.94, h_src=4.3)

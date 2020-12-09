import os

const stdDatadir* = currentSourcePath.parentDir / "data"

const
  NIMBASE_1_0_X* = slurp"data/nimbase-1.0.x.h"
  NIMBASE_1_2_X* = slurp"data/nimbase-1.2.x.h"
  NIMBASE_1_4_x* = slurp"data/nimbase-1.4.x.h"

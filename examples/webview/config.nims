switch("gc", "orc")
switch("d", "pixieNoSimd")
when defined(android):
  switch("d", "crunchyNoSimd")

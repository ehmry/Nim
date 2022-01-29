# this config.nims also needs to exist to prevent future regressions, see #9990

cppDefine "errno"
cppDefine "unix"

# mangle the macro names in nimbase.h
cppDefine "NAN_INFINITY"
cppDefine "INF"
cppDefine "NAN"

when defined(nimStrictMode):
  # xxx add more flags here, and use `-d:nimStrictMode` in more contexts in CI.

  # enable this:
  # when defined(nimHasWarningAsError):
  #   switch("warningAsError", "UnusedImport")

  when defined(nimHasHintAsError):
    # switch("hint", "ConvFromXtoItselfNotNeeded")
    switch("hintAsError", "ConvFromXtoItselfNotNeeded")
    # future work: XDeclaredButNotUsed

switch("define", "nimVersion:" & NimVersion)

when defined(solo5):
  const solo5tender {.strdefine.}: string = "spt"
  switch("passL", "-z solo5-abi=" & solo5tender)
    # Select the Solo5 tender to link against.

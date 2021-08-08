## Tool for converting JSON build recipes to Plan 9 mkfiles

import json, streams, strutils, os

proc convert(js: JsonNode; output: Stream) =  
  output.write js["outputFile"].getStr
  output.write ":"
  for obj in js["link"].items:
    output.write " "
    output.write obj.getStr
  output.write "\n\t"
  output.write js["linkcmd"].getStr
  output.write "\n"
  
  for pair in js["compile"].items:
    output.write pair[0].getStr
    output.write ".o: "
    output.write pair[0].getStr
    output.write "\n\t"
    output.write pair[1].getStr
    output.write "\n"

for arg in commandLineParams():
  if not arg.endsWith".json":
    quit("refusing to convert " & arg)
  let
    mkfilePath = arg.parentDir / "mkfile"
    mkfileStream = open(mkfilePath, fmWrite).newFileStream
    js = arg.open.newFileStream.parseJson
  convert(js, mkfileStream)
  close(mkFileStream)
  echo mkfilePath

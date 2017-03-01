#!/usr/bin/python
from struct import unpack
import base64
import sys

def try_decode(s):
  try:
    return base64.b64decode(s+'=====', '_-')
  except TypeError:
    return None

if __name__ == '__main__':
  for line in sys.stdin:
    line = line.strip()
    if not line:
      continue
    packed = try_decode(line[1:])
    if not packed:
      print line
      continue
    unpacked = unpack('B'*len(packed), packed)

    print '|'.join(map(lambda x: '{0:08b}'.format(x), unpacked))

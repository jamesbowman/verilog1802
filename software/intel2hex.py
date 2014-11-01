import sys
from intelhex import IntelHex

i = IntelHex(sys.argv[1])
i.readfile()
bin = i.tobinstr().ljust(32768, chr(0))
open(sys.argv[2], "w").write("".join(["%02x\n" % ord(c) for c in bin]))

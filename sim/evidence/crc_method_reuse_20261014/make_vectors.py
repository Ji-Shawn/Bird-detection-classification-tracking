from pathlib import Path
import random,zlib,json
w=Path(__file__).resolve().parent;r=random.Random(2276)
payloads=[b'',b'123456789']+[r.randbytes(n) for n in [1,2,3,15,16,31,32,63,64,1399,1400,1401,8192]]
payloads += [r.randbytes(r.randrange(1,2801)) for _ in range(64)]
frame=r.randbytes(1920*1080*2)
payloads += [frame[i:i+1400] for i in range(0,len(frame),1400)]
words=0
with (w/'input.hex').open('w') as f:
 for data in payloads:
  if not data:f.write('40000\n');words+=1;continue
  for i in range(0,len(data),2):
   b=data[i:i+2];value=int.from_bytes(b,'little')|((3 if len(b)==2 else 1)<<16)|((i+2>=len(data))<<18)
   f.write(f'{value:05x}\n');words+=1
(w/'expected.hex').write_text(''.join(f'{zlib.crc32(p):08x}\n' for p in payloads))
(w/'vector_config.vh').write_text(f'`define WORDS {words}\n`define PACKETS {len(payloads)}\n')
(w/'vectors.json').write_text(json.dumps(dict(seed=2276,packets=len(payloads),words=words,video_bytes=len(frame),oracle='Python zlib.crc32'),indent=2))
print(words,len(payloads))

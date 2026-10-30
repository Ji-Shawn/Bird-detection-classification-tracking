"""Display-only SSD candidates; neither decoding nor drawing sends controls."""
import math
import struct
from .visual_policy import VISUAL_BIRD_MIN_SCORE

def decode_preview(data):
    if len(data)!=80:raise ValueError('SVP1 length')
    w=struct.unpack('<20I',data)
    if w[:3]!=(0x31505653,1,80) or w[6]>1 or w[18]>4 or w[19]:raise ValueError('SVP1 identity')
    box=struct.unpack_from('<4f',data,48)
    score,quality=struct.unpack_from('<2f',data,64)
    ts=w[8]|w[9]<<32;now=w[10]|w[11]<<32
    if not all(math.isfinite(v) for v in (*box,score,quality)):raise ValueError('SVP1 finite')
    if w[6] and (not w[5] or not ts or now<ts or now-ts>1500000 or
        not VISUAL_BIRD_MIN_SCORE<score<=1 or not 0<=quality<=1.00001 or
        not(0<=box[0]<box[2]<=1920 and 0<=box[1]<box[3]<=1080 and
            box[2]-box[0]>=8 and box[3]-box[1]>=8)):
        raise ValueError('SVP1 geometry/time')
    return dict(boot_id=w[3],message_sequence=w[4],candidate_id=w[5],visible=bool(w[6]),
                sequence=w[7],timestamp_us=ts,published_us=now,box=box,score=score,quality=quality,reason=w[18])

def preview_target(t,frame_boot,frame_stale=False):
    p=t.get('ssd_preview')
    age=t.get('ssd_preview_age_s',float('inf'))
    if (frame_stale or not p or not p['visible'] or not t.get('online') or
        p['boot_id']!=frame_boot or t.get('boot_id')!=frame_boot or
        t.get('telemetry_age_s',99)>1 or age>.25):return None
    source_age=(p['published_us']-p['timestamp_us'])/1e6+age
    if source_age>1.5:return None
    b=p['box'];cx,cy=(b[0]+b[2])/2,(b[1]+b[3])/2
    return dict(box=tuple(v/3 for v in b),center=(cx/3,cy/3),error=(cx-960,cy-540),
        provisional=True,centered=False,continuous=False,reacquiring=False,vertical_only=False,
        age=source_age,score=p['score'],quality=p['quality'],sequence=p['sequence'],candidate_id=p['candidate_id'])

def decode_class_metadata(data):
    if len(data)!=96:raise ValueError('SVC1 length')
    w=struct.unpack('<24I',data)
    if w[:3]!=(0x31435653,1,96) or not w[5] or w[7]>1 or w[11]>1 or w[18]>1 or w[23]:
        raise ValueError('SVC1 identity')
    captured=w[8]|w[9]<<32;source=w[12]|w[13]<<32
    completed=w[14]|w[15]<<32;published=w[16]|w[17]<<32
    roi=struct.unpack_from('<4i',data,76)
    if not source or source>captured or completed<source or published<completed or (w[7] and published-completed>2000000):
        raise ValueError('SVC1 time')
    if not w[7] and (w[10]!=w[6] or source!=captured):raise ValueError('SVC1 new source')
    return dict(boot_id=w[3],message_sequence=w[4],target_id=w[5],video_sequence=w[6],
        video_timestamp_us=captured,reused=bool(w[7]),source_sequence=w[10],source_timestamp_us=source,
        completed_us=completed,published_us=published,policy=w[11],applied_policy=w[18],roi=roi)

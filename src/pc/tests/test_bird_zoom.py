import struct
import numpy as np
from PIL import Image
from av_monitor.bird_zoom import active_box,render,focus_text,ZoomTransition,FULL
from av_monitor.network import ReceiverService

def telemetry():
    return dict(online=True,boot_id=3,telemetry_age_s=.1,focus_enabled=True,
        bird_zoom_active=True,bird_zoom_age_ms=1000,bird_zoom_box=[480,210,800,390])

def test_zoom_fails_closed():
    t=telemetry();assert active_box(t,3)==(480,210,800,390)
    assert active_box(t,4) is None and active_box(t,3,True) is None
    for k,v in [('online',False),('telemetry_age_s',2),('focus_enabled',False),
                ('bird_zoom_active',False),('bird_zoom_age_ms',12001),
                ('bird_zoom_box',[0,0,1,1]),('bird_zoom_box',[0,0,1281,720])]:
        bad=dict(t);bad[k]=v;assert active_box(bad,3) is None

def test_render_keeps_full_frame_and_aspect():
    rgb=np.zeros((720,1280,3),np.uint8);rgb[210:390,480:800]=[255,0,0]
    original=rgb.copy();out=render(rgb,(480,210,800,390))
    assert out.shape==(360,640,3) and list(out[100,100])==[255,0,0]
    assert np.array_equal(rgb,original)
    assert np.array_equal(render(rgb,None),np.asarray(Image.fromarray(rgb).resize((640,360),Image.Resampling.BILINEAR)))

def test_new_telemetry_and_old_compatibility():
    r=ReceiverService(port_types={})
    payload=bytearray(200)
    struct.pack_into('!16I',payload,136,0x41465a31,1,5,0xfffffffe,1,42,2000,24000,
        480,210,800,390,40,25,3,2)
    r._accept_status(payload,100)
    _,t,_=r.snapshots()
    assert t['focus_error']==-2 and t['bird_zoom_box']==[480,210,800,390]
    assert t['focus_requests']==3 and t['focus_completed']==2
    assert '失败' in focus_text(dict(t,online=True,telemetry_age_s=0))
    r._accept_status(payload[:136],200)
    _,t,_=r.snapshots();assert 'focus_state' not in t

def test_smooth_zoom_retargets_without_jumps_and_restores():
    z=ZoomTransition(.8);box=(480,210,800,390)
    assert z.update(box,10)==FULL
    mid=z.update(box,10.4)
    assert np.allclose(mid,[240,105,1360,735])
    assert z.update(box,10.9)==tuple(map(float,box))
    new=(800,500,1120,680)
    before=z.value(11);assert z.update(new,11)==before
    for t in np.linspace(11,11.8,20):
        b=z.update(new,t);assert 0<=b[0]<b[2]<=1280 and 0<=b[1]<b[3]<=720
        assert abs((b[2]-b[0])*9-(b[3]-b[1])*16)<1e-6
    z.update(None,12);assert z.update(None,13)==FULL
    z.update(box,14);assert z.update(None,14.2,immediate=True)==FULL

def test_cached_renderer_matches_fresh_reference_during_animation():
    from av_monitor.bird_zoom import FrameRenderer
    from PIL import Image
    rng=np.random.default_rng(2276)
    rgb=rng.integers(0,256,(720,1280,3),dtype=np.uint8)
    cached=FrameRenderer(rgb);small=None
    for box in [(0,0,1280,720),(120.5,44.5,1120.5,607),(480,210,800,390)]:
        out=cached.render(box)
        ref=Image.fromarray(rgb).transform((640,360),Image.Transform.EXTENT,box,Image.Resampling.BILINEAR)
        ref.paste(Image.fromarray(rgb).resize((160,90),Image.Resampling.BILINEAR),(478,268))
        assert np.array_equal(out,np.asarray(ref))
        if small is not None:assert cached.small is small
        small=cached.small
    assert np.array_equal(cached.render(None),np.asarray(Image.fromarray(rgb).resize((640,360),Image.Resampling.BILINEAR)))

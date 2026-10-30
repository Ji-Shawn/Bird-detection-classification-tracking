import numpy as np
from av_monitor.bird_zoom import active_box, FrameRenderer

def test_bottom_right_full_hd_zoom_box_is_not_rejected():
    telemetry=dict(online=True,boot_id=7,telemetry_age_s=0,focus_enabled=True,
        bird_zoom_active=True,bird_zoom_age_ms=0,bird_zoom_box=[1440,810,1920,1080])
    assert active_box(telemetry,7)==(1440,810,1920,1080)

def test_full_hd_panorama_fits_existing_canvas_and_preserves_bottom_right():
    rgb=np.zeros((1080,1920,3),dtype=np.uint8)
    rgb[1060:,1900:]=[255,0,0]
    rendered=FrameRenderer(rgb).render(None)
    assert rendered.shape==(360,640,3)
    assert rendered[-1,-1].tolist()==[255,0,0]

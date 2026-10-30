import numpy as np

from av_monitor.ui import _mel_rgb


def test_mel_colour_uses_fixed_uint16_scale_not_frame_percentiles():
    low = np.full((128, 4), 4096, dtype=np.uint16)
    with_outlier = low.copy()
    with_outlier[0, 0] = 65535
    low_rgb = _mel_rgb(low, width=4)
    outlier_rgb = _mel_rgb(with_outlier, width=4)
    # The same encoded level must retain the same colour even when another
    # bin changes; percentile auto-stretch violates this invariant.
    assert np.array_equal(low_rgb[0, 1], outlier_rgb[0, 1])
    assert int(low_rgb[0, 1, 0]) < 20
    assert int(_mel_rgb(low,width=4,lift_weak=True)[0,1,0]) >= 45


def test_mel_colour_keeps_silence_dark_and_saturates_full_scale():
    levels = np.array([[0, 2048, 49152, 65535]], dtype=np.uint16)
    rgb = _mel_rgb(levels, width=4)

    assert int(rgb[0, 0, 0]) == 0
    assert int(rgb[0, 1, 0]) == 0
    assert int(rgb[0, 2, 0]) == 255
    assert int(rgb[0, 3, 0]) == 255

"""M42 recovery wording: a held grey box does not imply stationary tilt.

The two captions describe the same recovery state for both a directional
search and the retained centered/unknown-position retry hold. No display
geometry, timing, wire protocol or target acceptance rule changes.
"""

PAIRS = [
    ('灰框为上次位置；舵机等待新的有效定位',
     '灰框为上次位置；按失锁恢复策略找回目标'),
    ('板端正在找回目标；灰框为上次位置，舵机等待新的有效定位',
     '板端正在找回目标；灰框为上次位置，等待新的有效匹配'),
]


def apply(text):
    for old, new in PAIRS:
        assert text.count(old) == 1, old
        text = text.replace(old, new)
    return text


def revert(text):
    for old, new in reversed(PAIRS):
        assert text.count(new) == 1, new
        text = text.replace(new, old)
    return text


if __name__ == '__main__':
    from pathlib import Path
    root = Path(__file__).resolve().parents[2]
    path = root / 'pc/av_monitor/tracking_overlay.py'
    before = path.read_text(encoding='utf8')
    after = apply(before)
    assert revert(after) == before
    path.write_text(after, encoding='utf8')

"""M36 fusion integration: 33-ms position delivery and listening in recovery.

Only the formal servo/NCC recovery state releases the coarse visual-state
audio gate. A display-only candidate cannot cause this handoff. The existing
bird-confidence, species, energy and spatial guards still approve audio.
"""

PAIRS = [
    ('static unsigned visual_present(uint64_t now,unsigned require_current_target) {\n',
     'static unsigned visual_present(uint64_t now,unsigned require_current_target) {\n'
     '    /* Searching after a lost target must continue to hear new bearings. */\n'
     '    if(servo_tracking_recovery_active())return 0;\n'),
    ('if(end-last_status>=100000u) {',
     '/* Formal NCC position is included in the existing status packet. */\n'
     '    if(end-last_status>=33000u) {'),
]


def apply(text):
    for old, new in PAIRS:
        assert text.count(old) == 1, old
        text = text.replace(old, new, 1)
    return text


def revert(text):
    for old, new in reversed(PAIRS):
        assert text.count(new) == 1, new
        text = text.replace(new, old, 1)
    return text

"""M40 first valid SSD lock, with a strict float32 >50% presence gate.

An established target keeps its existing association and replacement grace.
Only an exact, current, completed camera frame may start continuous control;
delayed SSD coordinates seed history replay or one sparse post-motion step.
All substitutions are reversible for release scope verification.
"""
MARK = '/* M40 first valid SSD acquisition; strict >50 percent. */\n'


def change(text, pairs, reverse=False):
    for old, new, count in (reversed(pairs) if reverse else pairs):
        if reverse:
            old, new = new, old
        assert text.count(old) == count, (old, text.count(old), count)
        text = text.replace(old, new)
    return text


TRACKER = [
    ('score<VISUAL_BIRD_MIN_SCORE', 'score<=VISUAL_BIRD_MIN_SCORE', 3),
    ('if(candidate_hits>=VISUAL_TARGET_CONFIRMATIONS &&',
     'if((!active || candidate_hits>=VISUAL_TARGET_CONFIRMATIONS) &&', 1),
    ('/* Protect the existing target for two missing detections. Replacing\n'
     '         * it requires both repeated evidence and exhaustion of that grace. */',
     '/* First valid SSD acquires immediately. Replacing an established\n'
     '         * identity still requires repeated evidence and missing grace. */', 1),
    ('    if(handed_off) {\n        handoff_observed_sequence=sequence;handoff_observed_captured=captured;\n',
     '    handoff_observed_sequence=sequence;handoff_observed_captured=captured;\n'
     '    if(handed_off || (have_frame && f==&history[head] && f->valid &&\n'
     '       f->sequence==seed_sequence && f->timestamp==seed_captured &&\n'
     '       now>=seed_captured && now-seed_captured<=VISUAL_SERVO_POSITION_MAX_AGE_US)) {\n', 1),
    ('(uint32_t)(bird_score*1000000.f+.5f)',
     'visual_detection_score_q6(bird_score)', 2),
]

FUSION = [
    ('tracker[10]>=VISUAL_BIRD_MIN_SCORE_Q6',
     'tracker[10]>VISUAL_BIRD_MIN_SCORE_Q6', 1),
    ('d[i].score<fusion_detection_threshold',
     'd[i].score<=fusion_detection_threshold', 1),
    ('result.detector_score>=fusion_detection_threshold',
     'result.detector_score>fusion_detection_threshold', 2),
    ('/* Selection seeds a display-only candidate before classification. */',
     '/* Formal first-SSD acquisition precedes optional species classification. */', 1),
]

OLD_HITS = '''    if(hits<2) {
        if(recovering && captured>=recovery_started && !recovery_sparse_seen) {
            recovery_sparse_seen=1;
            recovery_sparse_until=UINT64_MAX-now<VISUAL_RECOVERY_SPARSE_CONFIRM_US?
                UINT64_MAX:now+VISUAL_RECOVERY_SPARSE_CONFIRM_US;
        }
        reason=WAIT_STABLE;return;
    }
'''
NEW_HITS = '''    /* Upstream SSD identity is already formal after one >50% detection.
     * This fallback takes at most one step per independent post-motion image;
     * it never turns a delayed SSD coordinate into continuous velocity. */
'''
CONTROLLER = [
    ('score<VISUAL_BIRD_MIN_SCORE', 'score<=VISUAL_BIRD_MIN_SCORE', 2),
    ('(uint32_t)(score*1000000.f+.5f)', 'visual_detection_score_q6(score)', 2),
    ('/* Sparse SSD fallback has its own two-frame/post-motion guard. A delayed',
     '/* Sparse SSD fallback retains its independent post-motion guard. A delayed', 1),
    (OLD_HITS, NEW_HITS, 1),
    ('/* The sparse SSD fallback still needs independent post-motion hits;\n'
     '         * candidate/coarse presence and delayed pre-loss coordinates cannot',
     '/* The sparse SSD fallback needs a new independent post-motion frame;\n'
     '         * candidate/coarse presence and delayed pre-loss coordinates cannot', 1),
]

SCORE_HELPER = '''#include <stdint.h>
/* Only an accepted float32 >0.5 score is nudged past the wire quantization
 * boundary. nextafterf(0.5,+inf) must remain visible after Q6 rounding; an
 * exact 0.5 is never promoted or accepted by this helper. */
static inline uint32_t visual_detection_score_q6(float score) {
    uint32_t value=(uint32_t)(score*1000000.f+.5f);
    return score>VISUAL_BIRD_MIN_SCORE && value<=VISUAL_BIRD_MIN_SCORE_Q6?
        VISUAL_BIRD_MIN_SCORE_Q6+1u:value;
}
'''
HEADER = [
    ('/* SSD bird-presence threshold; independent of species/audio confidence. */',
     '/* SSD bird presence is STRICTLY >50%; independent of species/audio. */', 1),
    ('#define VISUAL_BIRD_MIN_SCORE .45f', '#define VISUAL_BIRD_MIN_SCORE .5f', 1),
    ('#define VISUAL_BIRD_MIN_SCORE_Q6 450000u', '#define VISUAL_BIRD_MIN_SCORE_Q6 500000u', 1),
    ('#define VISUAL_CANDIDATE_SCAN_HOLD_US 3000000u\n',
     '#define VISUAL_CANDIDATE_SCAN_HOLD_US 3000000u\n'+SCORE_HELPER, 1),
]
FOCUS = [
    ('#include "board_focus.h"', '#include "board_focus.h"\n#include "visual_detection_policy.h"', 1),
    (' if(!isfinite(score)||score<.45f||score>1.f)return;',
     ' if(!isfinite(score)||score<=VISUAL_BIRD_MIN_SCORE||score>1.f)return;', 1),
]
FAST = [('score<VISUAL_BIRD_MIN_SCORE', 'score<=VISUAL_BIRD_MIN_SCORE', 2)]
DISPLAY = [('t[10]>=VISUAL_BIRD_MIN_SCORE_Q6', 't[10]>VISUAL_BIRD_MIN_SCORE_Q6', 1)]
PC = {
    'visual_policy.py': [
        ("struct.pack('<f',.45)", "struct.pack('<f',.5)", 1),
        ('VISUAL_BIRD_MIN_SCORE_Q6=450000', 'VISUAL_BIRD_MIN_SCORE_Q6=500000', 1),
    ],
    'tracking_overlay.py': [
        ('not VISUAL_BIRD_MIN_SCORE<=score<=1', 'not VISUAL_BIRD_MIN_SCORE<score<=1', 1),
        ('1:f"新目标确认', '1:f"切换目标确认', 1),
    ],
    'ssd_preview.py': [
        ('not VISUAL_BIRD_MIN_SCORE<=score<=1', 'not VISUAL_BIRD_MIN_SCORE<score<=1', 1),
    ],
    'network.py': [
        ('b[0]>=VISUAL_BIRD_MIN_SCORE_Q6', 'b[0]>VISUAL_BIRD_MIN_SCORE_Q6', 1),
        ('q[9]>=VISUAL_BIRD_MIN_SCORE_Q6', 'q[9]>VISUAL_BIRD_MIN_SCORE_Q6', 1),
    ],
    'ui.py': [
        ('等待连续两次稳定鸟框', '等待新的有效定位', 1),
        ('置信度≥45%', '置信度>50%', 1),
        ('SSD鸟框（≥45%）', 'SSD鸟框（>50%）', 1),
    ],
}


def tracker(text):
    return MARK + change(text, TRACKER)


def revert_tracker(text):
    assert text.startswith(MARK)
    return change(text[len(MARK):], TRACKER, True)


def apply(text):
    return MARK + change(text, FUSION)


def revert(text):
    assert text.startswith(MARK)
    return change(text[len(MARK):], FUSION, True)


def controller(text):
    return change(text, CONTROLLER)


def revert_controller(text):
    return change(text, CONTROLLER, True)


def install(root):
    """Apply only enumerated persistent sources; builder owns generated C."""
    app=root/'platform/capture/sdk/core0_network'
    soft=root/'application/software'
    files={app/'include/visual_detection_policy.h':HEADER,
           app/'src/servo_tracking.c':CONTROLLER,
           soft/'board_focus.c':FOCUS,soft/'ssd_fast.c':FAST,
           soft/'board_display.c':DISPLAY}
    pc=root/'pc/av_monitor'
    files.update({pc/name:pairs for name,pairs in PC.items()})
    for path,pairs in files.items():
        old=path.read_text(encoding='utf8')
        current=change(old,pairs)
        assert change(current,pairs,True)==old,path
        path.write_text(current,encoding='utf8')

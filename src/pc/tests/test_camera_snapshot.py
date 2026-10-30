from av_monitor.network import ReceiverService
from av_monitor.video import CompletedFrame
import time


def _await_saved(path, expected):
    # Saving is deliberately off the UDP receive thread; keep the exact-byte
    # and atomic replacement assertions after bounded completion.
    deadline = time.monotonic()+2
    while time.monotonic()<deadline:
        if path.exists() and path.read_bytes()==expected:
            return
        time.sleep(.01)
    assert path.read_bytes()==expected


def test_complete_video_frame_is_saved_for_passive_monitoring(tmp_path):
    output = tmp_path / "watch" / "latest.rgb565"
    receiver = ReceiverService("127.0.0.1", {}, snapshot_path=output)
    frame = CompletedFrame(7, 42, 100, b"\x12\x34\x56\x78")

    receiver._accept_video_frame(frame, now_ns=1_000_000_000)
    _await_saved(output, frame.rgb565)

    assert output.read_bytes() == frame.rgb565
    assert not output.with_suffix(".rgb565.tmp").exists()
    delivered, _, _ = receiver.snapshots()
    assert delivered == frame
    receiver.stop()


def test_snapshot_rate_limit_keeps_display_frames_current(tmp_path):
    output = tmp_path / "latest.rgb565"
    receiver = ReceiverService("127.0.0.1", {}, snapshot_path=output,
                               snapshot_interval_s=60)
    first = CompletedFrame(7, 1, 100, b"first")
    middle = CompletedFrame(7, 2, 200, b"middle")
    last = CompletedFrame(7, 3, 300, b"last")

    receiver._accept_video_frame(first, now_ns=1_000_000_000)
    _await_saved(output, first.rgb565)
    receiver._accept_video_frame(middle, now_ns=31_000_000_000)
    assert output.read_bytes() == b"first"
    assert receiver.snapshots()[0] == middle

    receiver._accept_video_frame(last, now_ns=61_000_000_000)
    _await_saved(output, last.rgb565)
    assert output.read_bytes() == b"last"
    assert receiver.snapshots()[0] == last
    receiver.stop()

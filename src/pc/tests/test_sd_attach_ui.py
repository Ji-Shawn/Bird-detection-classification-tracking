"""SD attachment only changes implicit close-stop; explicit controls stay intact."""
from pathlib import Path
import ast
import sys
import unittest
from unittest.mock import Mock,patch

from av_monitor.ui import MonitorWindow
from av_monitor import main as monitor_main


class SdAttachUiTests(unittest.TestCase):
    def window(self,sd_attach=False,online=True,supported=True):
        window=MonitorWindow.__new__(MonitorWindow)
        window._sd_attach=sd_attach
        window._closed=False
        window.root=Mock()
        window.receiver=Mock()
        window.receiver.snapshots.return_value=(None,dict(online=online,servo_supported=supported),None)
        window._close_scan_preview_tuning=Mock()
        window._close_audio_tuning=Mock()
        window._close_visual_tuning=Mock()
        return window

    def closed_cleanly(self,window):
        window.receiver.stop.assert_called_once_with()
        window.root.destroy.assert_called_once_with()
        window._close_scan_preview_tuning.assert_called_once_with()
        window._close_audio_tuning.assert_called_once_with()
        window._close_visual_tuning.assert_called_once_with()

    def test_default_close_sends_the_original_stop(self):
        window=self.window()
        window.close()
        window.receiver.send_control.assert_called_once_with(13,0,'关闭窗口：停止云台')
        self.closed_cleanly(window)

    def test_sd_close_does_not_send_stop_or_read_telemetry(self):
        window=self.window(sd_attach=True)
        window.close()
        window.receiver.send_control.assert_not_called()
        window.receiver.snapshots.assert_not_called()
        self.closed_cleanly(window)

    def test_sd_close_does_not_invent_an_automatic_restart(self):
        window=self.window(sd_attach=True)
        window.close()
        self.assertEqual(window.receiver.method_calls,[unittest.mock.call.stop()])

    def test_default_offline_close_still_releases_receiver(self):
        window=self.window(online=False)
        window.close()
        window.receiver.send_control.assert_not_called()
        self.closed_cleanly(window)

    def test_default_unsupported_servo_close_does_not_send_stop(self):
        window=self.window(supported=False)
        window.close()
        window.receiver.send_control.assert_not_called()
        self.closed_cleanly(window)

    def test_default_send_failure_still_releases_receiver(self):
        for error in (RuntimeError('closed'),OSError('unplugged')):
            with self.subTest(error=type(error).__name__):
                window=self.window()
                window.receiver.send_control.side_effect=error
                window.close()
                self.closed_cleanly(window)

    def test_repeated_close_is_idempotent_in_both_modes(self):
        for attached in (False,True):
            with self.subTest(sd_attach=attached):
                window=self.window(sd_attach=attached)
                window.close();window.close()
                self.closed_cleanly(window)
                self.assertEqual(window.receiver.send_control.call_count,0 if attached else 1)

    def test_command_line_default_preserves_original_close_mode(self):
        self.check_command_line([],False)

    def test_command_line_sd_attach_is_forwarded(self):
        self.check_command_line(['--sd-attach'],True)

    def check_command_line(self,options,expected):
        receiver=Mock();root=Mock()
        with patch.object(sys,'argv',['av_monitor',*options]), \
             patch.object(monitor_main,'ReceiverService',return_value=receiver), \
             patch.object(monitor_main.tk,'Tk',return_value=root), \
             patch.object(monitor_main,'MonitorWindow') as window:
            monitor_main.main()
        receiver.start.assert_called_once_with()
        receiver.send_control.assert_not_called()
        window.assert_called_once_with(root,receiver,metrics_file=None,sd_attach=expected)
        root.mainloop.assert_called_once_with()

    def test_explicit_stop_and_original_heartbeat_remain_present(self):
        # Check the actual callback and heartbeat nodes, not a mirrored helper.
        tree=ast.parse(Path(sys.modules[MonitorWindow.__module__].__file__).read_text(encoding='utf8'))
        ctor=next(n for n in ast.walk(tree) if isinstance(n,ast.FunctionDef) and n.name=='__init__')
        self.assertTrue(any(isinstance(n,ast.Tuple) and len(n.elts)==3 and
            all(isinstance(x,ast.Constant) for x in n.elts) and
            [x.value for x in n.elts]==['停止 / 关闭追踪',13,0] for n in ast.walk(ctor)))
        refresh=next(n for n in ast.walk(tree) if isinstance(n,ast.FunctionDef) and n.name=='_refresh')
        self.assertTrue(any(isinstance(n,ast.Call) and isinstance(n.func,ast.Attribute) and
            n.func.attr=='send_servo_keepalive' for n in ast.walk(refresh)))


if __name__=='__main__':unittest.main()

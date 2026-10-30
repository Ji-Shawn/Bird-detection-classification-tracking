"""Compare measured frame-counter deltas within one stable operating mode.

No sockets, commands, images or inference are created here. Counter rates are
diagnostics; they do not estimate mechanical motion or fabricate lost frames.
"""
import math


class FrameFlow:
    COUNTERS=('frame_count','video_drop_old','video_drop_tx','video_assembly_loss')

    def __init__(self):
        self._previous=None

    @staticmethod
    def _counter(value):
        return type(value) is int and value>=0

    @staticmethod
    def _delta(current,previous):
        if current>=previous:return current-previous
        if 0xf0000000<=previous<=0xffffffff and 0<=current<=0x0fffffff:
            return (current-previous)&0xffffffff
        return None

    def sample(self,telemetry,video_frames,now_ns,result=None,result_age_s=float('inf')):
        row={'valid':False,'reason':'baseline','boot_id':telemetry.get('boot_id'),
             'fusion_mode':telemetry.get('fusion_mode'),'servo_auto':bool(telemetry.get('servo_auto')),
             'sound_tracking_enabled':bool(telemetry.get('sound_tracking_enabled')),
             'capture_state':telemetry.get('capture_state'),
             'tracker_active':bool(telemetry.get('visual_tracker_active')),
             'tracker_frame_age_ms':telemetry.get('visual_tracker_frame_age_ms'),
             'tracker_misses':telemetry.get('visual_tracker_misses'),
             'tracker_quality':telemetry.get('visual_tracker_quality')}
        # Preserve raw receive evidence even when board telemetry is stale or a
        # mode transition makes rate deltas incomparable.
        for name in ('port_packets', 'port_last_packet_age_s', 'video_assembly_progress',
                     'video_duplicate_fragments', 'video_rejected_fragments',
                     'video_last_frame_age_s', 'video_last_packet_age_s',
                     'video_last_second_frames', 'video_stalled', 'video_waiting',
                     'video_no_frame_1s', 'video_stale_after_s', 'video_interruptions',
                     'video_last_gap_s', 'video_max_gap_s', 'video_frame_identity',
                     'video_health', 'video_capture_evidence', 'diagnostic_io_dropped', 'diagnostic_io_errors',
                     'diagnostic_io_pending'):
            if name in telemetry:
                row[name] = telemetry[name]
        tuning=telemetry.get('visual_tuning',{})
        row['tuning_revision']=tuning.get('revision')
        if tuning.get('ready'):row['tuning_values']=tuning.get('values')
        if result and math.isfinite(result_age_s) and 0<=result_age_s<=5:
            row['last_inference_service_gap_us']=result.get('max_service_gap_us')
            row['last_inference_timing_us']=result.get('timing_us')
        age=telemetry.get('telemetry_age_s',float('inf'))
        if (not telemetry.get('online') or not isinstance(age,(int,float)) or
                not math.isfinite(age) or not 0<=age<=1):
            self._previous=None;row['reason']='offline_or_stale';return row
        boot=telemetry.get('boot_id')
        values=tuple(telemetry.get(name) for name in self.COUNTERS)+(video_frames,)
        if (type(now_ns) is not int or now_ns<=0 or type(boot) is not int or not boot or
                not all(self._counter(value) for value in values)):
            self._previous=None;row['reason']='invalid_counters';return row
        mode=(row['fusion_mode'],row['servo_auto'],row['sound_tracking_enabled'],row['capture_state'])
        current=(now_ns,boot,mode,values)
        previous=self._previous
        if previous is None:
            self._previous=current;return row
        started,old_boot,old_mode,old_values=previous
        dt=(now_ns-started)/1e9
        if boot!=old_boot or mode!=old_mode:
            self._previous=current;row['reason']='boot_or_mode_transition';return row
        if dt<=0 or dt>5:
            self._previous=current;row['reason']='clock_or_long_gap';return row
        if dt<.25:
            row['reason']='short_interval';return row
        deltas=tuple(self._delta(new,old) for new,old in zip(values,old_values))
        self._previous=current
        if any(value is None for value in deltas):
            row['reason']='counter_reset';return row
        row.update(valid=True,reason='stable_mode_window',window_s=dt,
                   board_frame_counter_fps=deltas[0]/dt,
                   board_old_frame_replacements_per_s=deltas[1]/dt,
                   board_tx_drop_per_s=deltas[2]/dt,
                   pc_assembly_loss_per_s=deltas[3]/dt,
                   pc_completed_fps=deltas[4]/dt)
        return row

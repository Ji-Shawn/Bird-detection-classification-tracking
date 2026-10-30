"""Read-only recording health; does not change M47 controls or tracking."""
import struct

def decode(payload):
    if len(payload)<1432:return None
    w=struct.unpack_from('!12I',payload,1384)
    if w[0]!=0x53443438 or w[1]!=1 or w[2]&~31 or w[8]>2:return None
    return dict(flags=w[2],fps=w[3]/1000,tail_ms=w[4],produced=w[5],saved=w[6],
                dropped=w[7],queued=w[8],error=w[9],saved_bytes=w[10],worst_io_us=w[11])

def status_text(telemetry):
    s=telemetry.get('sd_record')
    if not telemetry.get('online') or telemetry.get('telemetry_age_s',float('inf'))>1:
        return 'SD 自动存图：等待新鲜状态'
    if s is None:return 'SD 自动存图：当前固件未提供状态'
    if s['flags']&16:
        archive_errors={
            0x5101:'缺少 bird_class/DATE.TXT，请设置拍摄日期后重新上电',
            0x5102:'DATE.TXT 日期无效，请填写 YYYY.MM.DD 后重新上电',
            0x5103:'照片鸟种代码无效',
            0x5104:'当前鸟种日期目录的图片编号已用尽',
        }
        reason=archive_errors.get(s['error'],f"存储错误 {s['error']}")
        state=f'{reason}，追踪继续'
    elif s['flags']&8:state='正在写入'
    elif s['flags']&4:state='就绪，等待正式鸟目标与视觉鸟种结果' if not s['flags']&2 else '记录中'
    else:state='正在检查 SD 卡'
    return (f"SD 自动存图：{state} · 已保存 {s['saved']} 张 · 待存 {s['queued']} 张 · "
            f"丢弃 {s['dropped']} 张 · 上限 {s['fps']:g} FPS · /bird_class/eBird码_日期")

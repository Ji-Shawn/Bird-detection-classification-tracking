"""Strict decoder for the board's little-endian FUS1 v1/v2/v3 (UDP 15005)."""
import json
import math
from pathlib import Path
import struct

STATUS_NAMES = {1: '仅音频，SSD未确认', 2: '音视融合', 3: '摄像头超时，回退音频', 4: '推理故障',
                5: '低置信度，未确认', 6: '独立视觉测试', 7: '视觉测试抓帧超时',
                8: '音频初判，等待视觉复核', 9: '未检测到鸟，跳过鸟种分类'}


def load_classes():
    classes = json.loads(Path(__file__).with_name('classes.json').read_text(encoding='utf-8'))
    if len(classes) != 60 or not all(isinstance(x, str) for x in classes):
        raise ValueError('Expected the frozen 60-class label order')
    return classes


def decode_result(data: bytes, classes: list[str]) -> dict:
    if len(data) not in (320,352,384):
        raise ValueError('FUS1 requires 320 (v1), 352 (v2), or 384 (v3) bytes')
    magic, version, seq, status, at, vt, vseq, top, atop, vtop, score, det, err, gap = struct.unpack_from('<4I2Q4I2fiI', data)
    if magic != 0x46555331 or (version,len(data)) not in ((1,320),(2,352),(3,384)) or status not in STATUS_NAMES:
        raise ValueError('Invalid fusion protocol magic, version or status')
    if len(classes) != 60 or top >= 60 or (atop != 0xffffffff and atop >= 60) or (vtop != 0xffffffff and vtop >= 60):
        raise ValueError('Invalid class index')
    probabilities = struct.unpack_from('<60f', data, 64)
    box = struct.unpack_from('<4f', data, 304)
    if not all(math.isfinite(x) for x in (score, det, *probabilities, *box)):
        raise ValueError('Non-finite fusion result')
    if not all(0 <= x <= 1.00001 for x in (score, det, *probabilities)):
        raise ValueError('Probability outside [0,1]')
    if status==9 and (version<3 or err or atop!=0xffffffff or vtop!=0xffffffff or
                     not vt or score!=0 or any(probabilities)):
        raise ValueError('Invalid no-bird result')
    if status not in (4,7,9) and (err != 0 or abs(sum(probabilities)-1) > .001 or abs(score-probabilities[top]) > .00001):
        raise ValueError('Inconsistent successful result')
    if status in (2,6) and (vtop == 0xffffffff or not vt):
        raise ValueError('Fused result lacks visual inference')
    ranked = sorted(range(60), key=lambda i: probabilities[i], reverse=True)[:3]
    extra={}
    if status==8 and (version<3 or atop==0xffffffff or vtop!=0xffffffff):
        raise ValueError('Invalid provisional audio result')
    if version>=2:
        policy,applied,*tail=struct.unpack_from('<2I4iIf',data,320)
        roi=tail[:4];full_top,full_score=tail[4:]
        if policy>3 or applied>3 or (full_top!=0xffffffff and full_top>=60) or not math.isfinite(full_score) or not 0<=full_score<=1.00001:
            raise ValueError('Invalid ROI result')
        if applied and (applied!=policy or roi[2]<=roi[0] or roi[2]-roi[0]!=roi[3]-roi[1] or roi[2]-roi[0]>4096 or any(v< -4096 or v>8192 for v in roi)):
            raise ValueError('Invalid ROI geometry')
        extra=dict(image_policy=policy,applied_policy=applied,roi_camera_pixels=roi,
                   full_image_label=None if full_top==0xffffffff else classes[full_top],full_image_confidence=full_score)
    if version>=3:
        names=('audio_compute_us','ssd_preprocess_us','ssd_compute_us','image_preprocess_us',
               'image_compute_us','total_us','audio_response_us','capture_wait_us')
        extra['timing_us']=dict(zip(names,struct.unpack_from('<8I',data,352)))
    return dict(sequence=seq, status=status, status_text=STATUS_NAMES[status],
                label=None if status==9 else classes[top], audio_label=None if atop==0xffffffff else classes[atop],
                image_label=None if vtop==0xffffffff else classes[vtop],
                confidence=score, detector_score=det, error=err,
                audio_timestamp_us=at, video_timestamp_us=vt, video_sequence=vseq,
                max_service_gap_us=gap, box_camera_pixels=box,
                top3=[] if status==9 else [(classes[i], probabilities[i]) for i in ranked],**extra)


def result_text(result, age_s):
    if result is None:
        return '等待板上识别结果（UDP 15005）…', '等待板端完成有效音频采样；模型在板上执行。'
    stale = '【结果已过期】' if age_s > 15 else ''
    if result['status'] == 4:
        return f"推理故障 {result['error']} {stale}", '板上推理已暂停；这里不显示旧预测为新结果。'
    if result['status']==7:
        return '视觉测试：抓帧超时', '没有得到完整摄像头帧；不显示分类预测。'
    if result['status']==9:
        t=result.get('timing_us',{})
        return f'{stale}未检测到鸟 · 不输出鸟种', (f"SSD鸟检测 {result['detector_score']:.1%}；未通过检测分数/鸟框有效性检查。"
            f"\n本轮 {t.get('total_us',0)/1000:.0f} ms，已跳过鸟种分类。漏检不等于场景一定无鸟；可用手动鸟框诊断。")
    title = f"{stale}候选 {result['label']}   {result['confidence']:.1%}   · {result['status_text']}"
    detector_text = '待执行' if result['status']==8 else (f"{result['detector_score']:.1%}" if result['video_timestamp_us'] else '未执行')
    detail = (f"音频: {result['audio_label'] or '未执行'}    视觉: {result['image_label'] or '未执行'}    "
              f"SSD鸟检测: {detector_text}\n"
              f"Top-3: " + '  /  '.join(f'{label} {p:.1%}' for label,p in result['top3']) + '\n' +
              f"结果 #{result['sequence']} · {age_s:.1f}秒前 · 对应视频帧 {result['video_sequence']} · "
              f"最大服务间隔 {result['max_service_gap_us']/1000:.1f} ms")
    if result['video_timestamp_us']:
        detail += '\n对应推理帧检测框 xyxy: ' + ', '.join(f'{v:.0f}' for v in result['box_camera_pixels']) + '（不叠加到当前实时帧）'
    if 'image_policy' in result and result['image_label']:
        applied=result['applied_policy']
        detail+='\n分类输入: '+{0:'整图',1:'自动小鸟裁剪',2:'手动鸟框',3:'手动鸟框（同帧对照）'}[applied]
        if applied:detail+='，原图裁剪区域 '+str(result['roi_camera_pixels'])
        elif result['image_policy']==1:detail+='（未满足自动裁剪条件，回退整图）'
        if result.get('full_image_label'):
            crop_score=f" {result['confidence']:.1%}" if result['status']==6 else ''
            detail+=f"\n同帧对照：整图 {result['full_image_label']} {result['full_image_confidence']:.1%} → 裁剪 {result['image_label']}{crop_score}（不是准确率）"
    if 'timing_us' in result:
        t=result['timing_us']
        detail+=f"\n本轮处理 {t['total_us']/1000:.0f} ms · 音频计算 {t['audio_compute_us']/1000:.0f} ms · SSD {t['ssd_compute_us']/1000:.0f} ms · 图像分类 {t['image_compute_us']/1000:.0f} ms"
        if result['audio_timestamp_us']:
            detail+=f" · 音频窗结束至初判 {t['audio_response_us']/1000:.0f} ms（另需完成有效采样）"
    meta=result.get('classification_source')
    if meta and meta['reused']:
        detail+=f"\n同一目标复用近期鸟种：来源帧 #{meta['source_sequence']}，分类完成距本轮 {(meta['published_us']-meta['completed_us'])/1e6:.1f} 秒"
    return title, detail

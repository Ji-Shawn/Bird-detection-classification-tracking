from pathlib import Path
import subprocess,sys,os,hashlib,json,re
from local_tools import arm_bin,vivado_bin
ROOT=Path(__file__).resolve().parents[1]; WS=ROOT.parent
BASE=WS/'platform'; prior=WS/'services/core0'
work=ROOT/'build/software';work.mkdir(parents=True,exist_ok=True)
text=(prior/'dma_service.c').read_text(encoding='utf8')
replacements={
'video_config = XAxiVdma_LookupConfig(XPAR_VDMA_DEVICE_ID);':'video_config = hdmi_vdma_config(XAxiVdma_LookupConfig(XPAR_VDMA_DEVICE_ID));',
'write_config.EnableCircularBuf = 1u;':'write_config.EnableCircularBuf = 1u;\n    write_config.EnableSync = 1u;\n    write_config.GenLockRepeat = 1u;',
'if (XAxiVdma_DmaStart(&video_dma, XAXIVDMA_WRITE)':'if (hdmi_capture_genlock(&video_dma) != XST_SUCCESS) return -7;\n    if (XAxiVdma_DmaStart(&video_dma, XAXIVDMA_WRITE)',
'uint32_t completed = (current + AV_VIDEO_BUFFER_COUNT - 1u) % AV_VIDEO_BUFFER_COUNT;':'uint32_t completed = last_video_store; /* dynamic genlock may skip a ring slot */',
'video_copy_poll(service, current);':'hdmi_output_poll(&video_dma, video_sequence);\n    video_copy_poll(service, current);'}
for a,b in replacements.items():
 assert text.count(a)==1,a
 text=text.replace(a,b)
text=text.replace('uint32_t target = 0;', 'if(!board_network_preview) service->video[0].valid=service->video[1].valid=0;\n    uint32_t target = 0;',1)
text=text.replace('frame->valid = 1u;', 'frame->valid = board_network_preview?1u:0u;',1)
text=text.replace('visual_tracker_frame_begin(frame_id,timestamp);','board_focus_frame_begin();visual_tracker_frame_begin(frame_id,timestamp);',1)
text=text.replace('visual_tracker_frame_chunk(destination,video_copy_offset,bytes);','board_focus_frame_chunk(destination,video_copy_offset,bytes);visual_tracker_frame_chunk(destination,video_copy_offset,bytes);',1)
text=text.replace('visual_tracker_frame_end();','board_focus_frame_end(video_copy_timestamp);visual_tracker_frame_end();',1)
text='#include "board_focus.h"\n#include "board_display.h"\n'+text
from audio_capture_overlay import apply as apply_audio_capture
text=apply_audio_capture(text)
fusion=(prior/'fusion_service.c').read_text(encoding='utf8')
from sound_search_overlay import apply as apply_sound_search
fusion=apply_sound_search(fusion)
from responsiveness_overlay import apply as apply_responsiveness, tracker as responsive_tracker
fusion=apply_responsiveness(fusion)
from sound_noise_overlay import apply as apply_sound_noise
fusion=apply_sound_noise(fusion)
from ssd_fast_overlay import apply as apply_ssd_fast, tracker as fast_tracker
from candidate_hold_overlay import apply as apply_candidate_hold, tracker as candidate_tracker
from visual_continuous_overlay import tracker as continuous_tracker
from visual_motion_overlay import tracker as motion_tracker
from visual_stability_overlay import tracker as stability_tracker
from visual_handoff_overlay import tracker as handoff_tracker
from visual_reacquire_overlay import tracker as reacquire_tracker, apply as apply_visual_reacquire
from focus_recovery_overlay import tracker as focus_tracker, apply as apply_focus_recovery
from acquisition_overlay import tracker as acquire_tracker, apply as apply_acquisition
from tracking_fps_overlay import tracker as fps_tracker, apply_service as apply_tracking_fps
(work/'visual_tracker_response.c').write_text(fps_tracker(acquire_tracker(focus_tracker(reacquire_tracker(handoff_tracker(stability_tracker(motion_tracker(continuous_tracker(candidate_tracker(fast_tracker(responsive_tracker((prior/'visual_tracker.c').read_text(encoding='utf8')))))))))))),encoding='utf8')
fusion='#include "board_focus.h"\n'+fusion
fusion=fusion.replace('bird_focus_poll(now_us());','bird_focus_poll(now_us());board_focus_policy_poll(now_us());',1)
fusion=fusion.replace('bird_focus_observe(result.detector_score,result.box,result.video_sequence,','board_focus_observe(result.detector_score,result.box,now_us());\n            bird_focus_observe(result.detector_score,result.box,result.video_sequence,',1)
fusion='#include "board_display.h"\n'+fusion
fusion=fusion.replace('visual_tracker_init();','visual_tracker_init();\n    requested_mode=1;',1)
fusion=fusion.replace('last_service=t;service_busy=1;','last_service=t;service_busy=1;\n    board_display_poll(t);',1)
fusion=fusion.replace('result.status=status;result.error=error;result.total_us=', 'result.status=status;result.error=error;board_display_result(&result,now_us());result.total_us=',1)
fusion=fusion.replace('if(capture_state==0 && job_mode==requested_mode)\n            board_focus_observe', 'if(capture_state==0 && job_mode==requested_mode) {\n            board_focus_observe',1)
fusion=fusion.replace('result.video_timestamp_us,now_us());\n        if(!bird_valid', 'result.video_timestamp_us,now_us());\n        }\n        if(!bird_valid',1)
fusion=apply_ssd_fast(fusion)
fusion=apply_candidate_hold(fusion)
from visual_recovery_overlay import apply as apply_visual_recovery
fusion=apply_visual_recovery(fusion)
fusion=apply_visual_reacquire(fusion)
fusion=apply_focus_recovery(fusion)
fusion=apply_acquisition(fusion)
fusion=apply_tracking_fps(fusion)
from classification_priority_overlay import apply_fusion as apply_classification_priority
fusion=apply_classification_priority(fusion)
from audio_tuning_overlay import apply_fusion as apply_audio_tuning_fusion, apply_control as apply_audio_tuning_control
fusion=apply_audio_tuning_fusion(fusion)
from stream_tuning_overlay import apply_fusion as apply_stream_fusion, apply_control as apply_stream_control
fusion=apply_stream_fusion(fusion)
from tracking_return_overlay import apply as apply_tracking_return
from tracking_motion_overlay import apply as apply_tracking_motion
from video_recovery_overlay import apply_dma as apply_video_dma, apply_fusion as apply_video_fusion, apply_tracker as apply_video_tracker
from small_target_overlay import apply_tracker as apply_small_target
from dynamic_roi_overlay import apply_fusion as apply_dynamic_roi
from tracking_handoff_overlay import apply as apply_tracking_handoff
tracker_path=work/'visual_tracker_response.c'
tracker_path.write_text(apply_tracking_handoff(apply_small_target(apply_video_tracker(apply_tracking_motion(apply_tracking_return(tracker_path.read_text(encoding='utf8')))))),encoding='utf8')
fusion=apply_dynamic_roi(apply_video_fusion(fusion))
from sound_round_overlay import apply_fusion as apply_sound_round
fusion=apply_sound_round(fusion)
from sound_round_tuning_overlay import apply_fusion as apply_sound_round_tuning_fusion, apply_control as apply_sound_round_tuning_control
fusion=apply_sound_round_tuning_fusion(fusion)
from standalone_fusion_overlay import apply_main as standalone_main, apply_fusion as standalone_fusion, apply_control as standalone_control
from sd_record_overlay import apply_main as record_main, apply_fusion as record_fusion, apply_dma as record_dma
from network_standalone_overlay import apply_phy as network_phy, apply_platform as network_platform, apply_udp as network_udp, apply_scheduler as network_scheduler
phy_source=BASE/'bsp_core0/libsrc/lwip202_v1_2/src/contrib/ports/xilinx/netif/xemacpsif_physpeed.c'
(work/'network_physpeed.c').write_text(network_phy(phy_source.read_text(encoding='utf8')),encoding='utf8')
(work/'network_platform.c').write_text(network_platform((BASE/'capture/sdk/core0_network/src/platform_port.c').read_text(encoding='utf8')),encoding='utf8')
(work/'network_udp.c').write_text(network_udp((prior/'udp_stream.c').read_text(encoding='utf8')),encoding='utf8')
(work/'network_scheduler.c').write_text(network_scheduler((prior/'stream_scheduler.c').read_text(encoding='utf8')),encoding='utf8')
fusion=standalone_fusion(record_fusion(fusion))
fusion='#include "board_keys.h"\n'+fusion
key_service_anchor='    last_service=t;service_busy=1;\n    board_display_poll(t);'
assert fusion.count(key_service_anchor)==1
fusion=fusion.replace(key_service_anchor,
    '    last_service=t;service_busy=1;\n    board_keys_poll((uint32_t)t);\n    board_display_poll(t);',1)
(work/'fusion_service_overlay.c').write_text(fusion,encoding='utf8')
text='#include "hdmi_output.h"\n'+text
from preview_pacing_overlay import apply_dma as apply_preview_pacing
(work/'dma_service_overlay.c').write_text(record_dma(apply_video_dma(apply_preview_pacing(text))),encoding='utf8')
from online_tuning_overlay import apply_control as apply_online_tuning_control
from visual_feedforward_overlay import apply_control as apply_visual_feedforward_control
(work/'control_online_tuning.c').write_text(apply_visual_feedforward_control(apply_sound_round_tuning_control(apply_stream_control(apply_audio_tuning_control(apply_online_tuning_control((prior/'control.c').read_text(encoding='utf8')))))),encoding='utf8')
builder=(prior/'build_core0.py').read_text(encoding='utf8')
control_path=work/'control_online_tuning.c'
control_path.write_text(standalone_control(control_path.read_text(encoding='utf8')),encoding='utf8')
line="    obj=work/f'{i}.o';objects.append(str(obj))"
assert builder.count(line)==1
builder=builder.replace(line, "    if src.name=='dma_service.c':src=work/'dma_service_overlay.c'\n    if src.name=='fusion_service.c':src=work/'fusion_service_overlay.c'\n"+line)
builder=builder.replace(line,"    if src.name=='visual_tracker.c':src=work/'visual_tracker_response.c'\n"+line)
builder=builder.replace(line,"    if src.name=='platform_port.c':src=work/'network_platform.c'\n"+line)
builder=builder.replace(line,"    if src.name=='udp_stream.c':src=work/'network_udp.c'\n"+line)
builder=builder.replace(line,"    if src.name=='stream_scheduler.c':src=work/'network_scheduler.c'\n"+line)
builder=builder.replace(line,"    if src.name=='control.c':src=work/'control_online_tuning.c'\n"+line)
builder=builder.replace("('ps_math_optimized.c','visual_tracker.c')", "('ps_math_optimized.c','visual_tracker.c','visual_tracker_response.c')")
builder=builder.replace('objects=[]',"sources += [Path("+repr(str(ROOT/'software/hdmi_output.c'))+"),Path("+repr(str(ROOT/'software/board_display.c'))+"),Path("+repr(str(ROOT/'software/board_focus.c'))+")]\nflags += ['-I'+"+repr(str(ROOT/'software'))+"]\nobjects=[]")
builder=builder.replace('sources += [Path(', 'sources += [Path('+repr(str(ROOT/'software/ssd_fast.c'))+'),Path(',1)
builder=builder.replace('sources += [Path(', 'sources += [Path('+repr(str(ROOT/'software/stream_tuning.c'))+'),Path(',1)
builder=builder.replace('sources += [Path(', 'sources += [Path('+repr(str(ROOT/'software/sound_round_tuning.c'))+'),Path(',1)
builder=builder.replace('sources += [Path(', 'sources += [Path('+repr(str(ROOT/'software/ssd_roi.c'))+'),Path(',1)
main=(BASE/'capture/sdk/core0_network/src/main.c').read_text(encoding='utf8')
builder=builder.replace('sources += [Path(', 'sources += [Path('+repr(str(ROOT/'software/sd_record.c'))+'),Path('+repr(str(ROOT/'software/standalone_fusion.c'))+'),Path(',1)
builder=builder.replace('sources += [Path(', 'sources += [Path('+repr(str(ROOT/'software/network_standalone.c'))+'),Path('+repr(str(work/'network_physpeed.c'))+'),Path(',1)
builder=builder.replace('sources += [Path(', 'sources += [Path('+repr(str(ROOT/'software/board_keys.c'))+'),Path(',1)
builder=builder.replace('objects=[]',"flags += ['-I'+"+repr(str(phy_source.parent))+"]\nobjects=[]",1)
main=main.replace('    for (;;) {', '    /* SD image preloads both ELFs; JTAG starts CPU1 explicitly instead. */\n    if(*(volatile uint32_t *)0x30F01004u==0x4D323842u) {\n        *(volatile uint32_t *)0x30F01004u=0;\n        Xil_SetTlbAttributes(0xFFFF0000u,0x14de2u);\n        *(volatile uint32_t *)0xFFFFFFF0u=0x08000000u;\n        __asm__ volatile("dmb sy; sev" ::: "memory");\n    }\n    for (;;) {',1)
main=standalone_main(record_main(main))
main='#include "board_keys.h"\n'+main
assert main.count('    for (;;) {')==1
main=main.replace('    for (;;) {',
    '    board_keys_init(platform_time_us());\n    for (;;) {',1)
(work/'main_board.c').write_text(main,encoding='utf8')
builder=builder.replace("    if src.name=='dma_service.c'", "    if src.name=='main.c':src=work/'main_board.c'\n    if src.name=='dma_service.c'")
builder=builder.replace('core0_ssd_pl.elf','core0_hdmi.elf')
# Compiler-produced dependencies include .inc and system headers as well as C/H.
# These options produce an audit sidecar and do not change generated ARM code.
compile_call="rc=subprocess.call([gcc]+flags+extra+['-c',str(src),'-o',str(obj)]"
assert builder.count(compile_call)==1
builder=builder.replace(compile_call,
    "rc=subprocess.call([gcc]+flags+extra+['-MD','-MF',str(work/f'{i}.d'),'-c',str(src),'-o',str(obj)]")
(work/'build_overlay.py').write_text(builder,encoding='utf8')
env=os.environ.copy();env['SSD_BUILD_DIR']=str(work);env['M29_SOURCE_ROOT']=str(WS)
env['ARM_GNU_BIN']=str(arm_bin())
if not Path(env.get('XILINX_SPEC','')).is_file():
    env['XILINX_SPEC']=str(vivado_bin().parent/'data/embeddedsw/scripts/specs/arm/Xilinx.spec')
# Pin local headers used by this build as well as the C input receipt produced
# by the compiler driver. Hash before compilation and reject concurrent edits.
# Superset includes BSP headers and same-directory quoted includes.
header_roots=[BASE/'bsp_core0/include',BASE/'src',BASE/'runtime',
    BASE/'capture/shared',BASE/'capture/sdk/core0_network',
    WS/'detector_preprocess/software',ROOT/'software',prior,work]
headers=sorted({p for directory in header_roots for p in directory.rglob('*.h')})
header_inputs=[{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in headers]
subprocess.run([sys.executable,'-E',str(work/'build_overlay.py'),'app'],env=env,check=True)
for item in header_inputs:
    assert hashlib.sha256(Path(item['path']).read_bytes()).hexdigest()==item['sha256'],('Header changed during compilation',item['path'])
receipt=json.loads((work/'compile_inputs.json').read_text(encoding='utf8'))
receipt['headers']=header_inputs
receipt['header_scope']='All local headers under compiler include roots and source directories (superset)'
dependencies=set()
for index in range(len(receipt['inputs'])):
    dependency_file=work/f'{index}.d'
    dependency_text=dependency_file.read_text(encoding='utf8').replace('\\\n',' ')
    assert ': ' in dependency_text,('Invalid compiler dependency output',dependency_file)
    # GCC escapes whitespace in Make paths but retains Windows separators.
    for token in re.findall(r'(?:\\[ \t]|[^\s])+',dependency_text.split(': ',1)[1]):
        path=Path(token.replace('\\ ',' ').replace('\\\t','\t')).resolve()
        assert path.is_file(),('Missing actual compiler dependency',path)
        dependencies.add(path)
receipt['dependencies']=[{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(dependencies)]
link_inputs={BASE/'build/core0.ld',Path(env['XILINX_SPEC']).resolve()}
for match in re.finditer(r'^LOAD (.+)$',(work/'app.map').read_text(encoding='utf8'),re.M):
    # GNU ld synthetic map entry is not a filesystem input.
    if match[1].strip()=="linker stubs":continue
    path=Path(match[1].strip().strip('"')).resolve()
    assert path.is_file(),('Missing actual link input',path)
    link_inputs.add(path)
receipt['link_inputs']=[{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(link_inputs)]
receipt['dependency_scope']='Compiler -MD dependencies and linker-map LOAD files, linker script, Xilinx.spec'
(work/'compile_inputs.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
(work/'preserved_overlays.json').write_text(json.dumps({n:hashlib.sha256((prior/n).read_bytes()).hexdigest() for n in ['stream_scheduler.c','control.c','fusion_service.c','udp_stream.c','visual_tracker.c','dma_service.c']},indent=2),encoding='utf8')

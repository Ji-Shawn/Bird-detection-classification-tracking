"""Run 37 SSD95 admission cases, including 5 real FatFs producer/writer cases."""
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
def main():
    cc=os.environ.get('HOST_CC') or shutil.which('gcc') or shutil.which('cc')
    if not cc:raise SystemExit('Set HOST_CC to a native GCC-compatible C compiler.')
    sw=ROOT/'src/application/software';out=ROOT/'build/out/tests';out.mkdir(parents=True,exist_ok=True)
    (out/'servo_tracking.h').write_text('#include <stdint.h>\nvoid servo_tracking_sound_candidate(unsigned,uint64_t);\n',encoding='ascii')
    (out/'network_service.h').write_text('int platform_udp_send(unsigned,const void *,unsigned);\n',encoding='ascii')
    sources=[ROOT/'sim/archive/test_ssd95_record.c',sw/'ssd_fast.c',sw/'sd_record.c',sw/'sd_writer.c',sw/'sd_vendor/ff.c',sw/'sd_vendor/ffunicode.c']
    exe=out/('ssd95.exe' if os.name=='nt' else 'ssd95')
    command=[cc,'-std=c11','-O2','-Wall','-Wextra','-Werror','-DSD_RECORD_HOST',
             '-I'+str(out),'-I'+str(sw),'-I'+str(sw/'sd_vendor'),
             '-I'+str(ROOT/'src/platform/capture/sdk/core0_network/include'),*map(str,sources),'-o',str(exe)]
    build=subprocess.run(command,capture_output=True,text=True)
    (out/'compile.log').write_text(build.stdout+build.stderr,encoding='utf8')
    assert build.returncode==0,build.stdout+build.stderr
    result=subprocess.run([str(exe),str(ROOT/'sim/fixtures/card_vbr.bin')],capture_output=True,text=True,timeout=60)
    (out/'run.log').write_text(result.stdout+result.stderr,encoding='utf8');assert result.returncode==0,result.stdout+result.stderr
    count=int(re.search(r'M51_SSD95_RECORD_NATIVE_PASS (\d+) cases',result.stdout).group(1));assert count>=37
    data={'status':'pass','cases':count,'fatfs_integration_cases':5,'board_accessed':False,'sd_card_written':False,
          'inputs':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},
          'limits':'Deterministic model inputs; no model accuracy or physical hardware claim.'}
    (out/'results.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf8');print(result.stdout.strip())
if __name__=='__main__':main()

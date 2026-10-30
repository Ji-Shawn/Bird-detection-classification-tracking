import socket
import struct
import time
import pytest
from av_monitor.recognition import decode_result, load_classes, result_text
from av_monitor.network import ReceiverService


def packet(status=2, visual=0, score=.6):
    data=bytearray(320)
    struct.pack_into('<4I2Q4I2fiI',data,0,0x46555331,1,7,status,5000000,6000000,123,
                     0,11,visual,score,.8,0,2000)
    struct.pack_into('<60f',data,64,.6,.4,*([0.]*58))
    struct.pack_into('<4f',data,304,40.,45.,120.,90.)
    return bytes(data)


def test_decoder_and_visible_labels():
    r=decode_result(packet(),load_classes())
    assert r['label']=='amecro' and r['status_text']=='音视融合'
    title,detail=result_text(r,16)
    assert '已过期' in title and '60.0%' in title
    assert '对应视频帧 123' in detail and '不叠加' in detail
    r=decode_result(packet(status=1,visual=0xffffffff),load_classes())
    assert r['image_label'] is None and '未执行' in result_text(r,0)[1]


@pytest.mark.parametrize('data',[b'',packet()[:-1],b'BAD!'+packet()[4:],
                                packet(score=float('nan')),packet(score=.7),
                                packet(visual=60),packet(status=2,visual=0xffffffff)])
def test_bad_packets(data):
    with pytest.raises(ValueError):decode_result(data,load_classes())


def test_real_udp_transport_and_log(tmp_path):
    probe=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
    probe.bind(('127.0.0.1',0));port=probe.getsockname()[1];probe.close()
    log=tmp_path/'results.jsonl'
    service=ReceiverService('127.0.0.1',{port:None},result_log=log)
    service.start()
    try:
        with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as sender:
            sender.sendto(packet(),('127.0.0.1',port))
        until=time.monotonic()+2
        while (not log.exists() or not log.stat().st_size) and time.monotonic()<until:
            time.sleep(.01)
        r,age=service.recognition_snapshot()
        assert r['sequence']==7 and age<2
        assert service.snapshots()[2].fusion_packets==1
        assert 'amecro' in log.read_text(encoding='utf-8')
    finally:service.stop()


def test_fault_does_not_display_previous_class():
    r=decode_result(packet(status=4),load_classes())
    title,detail=result_text(r,0)
    assert '故障' in title and 'amecro' not in title


def packet_v3(status=8):
    data=bytearray(packet(status=status,visual=0xffffffff if status==8 else 0))
    struct.pack_into('<I',data,4,3)
    data+=struct.pack('<2I4iIf',0,0,0,0,0,0,0xffffffff,0)
    data+=struct.pack('<8I',1800000,50000,1200000,40000,900000,4000000,1820000,30000)
    return bytes(data)


def test_v3_timings_and_provisional_are_explicit():
    r=decode_result(packet_v3(),load_classes())
    assert r['status']==8 and r['timing_us']['audio_compute_us']==1800000
    title,detail=result_text(r,0)
    assert '等待视觉复核' in title and '另需完成有效采样' in detail and '待执行' in detail


def test_delayed_provisional_cannot_replace_final():
    s=ReceiverService(port_types={})
    s._accept_recognition(packet_v3(2),1_000_000_000)
    s._accept_recognition(packet_v3(8),1_010_000_000)
    assert s.recognition_snapshot()[0]['status']==2


def test_v3_wrong_length_is_rejected():
    with pytest.raises(ValueError):decode_result(packet_v3()[:-4],load_classes())

def no_bird_packet():
    b=bytearray(packet_v3(9))
    struct.pack_into('<2I',b,40,0xffffffff,0xffffffff)
    struct.pack_into('<f',b,48,0.)
    struct.pack_into('<60f',b,64,*([0.]*60))
    return b

def test_no_bird_is_explicit_abstention_not_a_class():
    r=decode_result(no_bird_packet(),load_classes())
    assert r['label'] is None and r['image_label'] is None and r['top3']==[]
    title,detail=result_text(r,0)
    assert '不输出鸟种' in title and 'amecro' not in title and '漏检' in detail
    for offset,value in [(40,0),(44,0),(56,1)]:
        b=no_bird_packet();struct.pack_into('<I',b,offset,value)
        with pytest.raises(ValueError):decode_result(b,load_classes())
    b=no_bird_packet();struct.pack_into('<f',b,64,1.)
    with pytest.raises(ValueError):decode_result(b,load_classes())

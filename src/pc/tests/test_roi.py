import struct
import pytest
from av_monitor.recognition import decode_result,load_classes,result_text
from av_monitor.network import ReceiverService
from av_monitor.protocol import parse_datagram
from test_recognition import packet

def roi_packet():
    data=bytearray(packet(status=6))+bytearray(struct.pack('<2I4iIf',3,3,-10,-10,80,80,11,.8))
    struct.pack_into('<I',data,4,2)
    return data

def test_roi_result_v2_and_v1_compatibility():
    r=decode_result(roi_packet(),load_classes())
    assert r['full_image_label']=='cangoo' and r['applied_policy']==3
    assert '同帧对照' in result_text(r,0)[1]
    assert decode_result(packet(),load_classes())['label']=='amecro'

@pytest.mark.parametrize('offset,value',[(320,4),(324,4),(344,60),(332,1000),(336,99999)])
def test_invalid_roi_result(offset,value):
    data=roi_packet();struct.pack_into('<I',data,offset,value)
    with pytest.raises(ValueError):decode_result(data,load_classes())

def test_roi_control_wire():
    class Socket:
        def sendto(self,data,address):self.data=data;self.address=address
    r=ReceiverService();s=Socket();r._control_socket=s
    r.send_image_policy(3,(10,20,200,300))
    packet=parse_datagram(s.data)
    command,n,seq,policy,*box=struct.unpack('!HHIB4H',packet.payload)
    assert (command,n,policy,box)==(8,9,3,[10,20,200,300])
    assert s.address==('192.168.7.20',15004)
    with pytest.raises(ValueError):r.send_image_policy(2,(0,0,1,1))
    with pytest.raises(ValueError):r.send_image_policy(2,(0,0,1921,1080))

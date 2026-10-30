"""Integrate SCN2 without changing old command/telemetry meanings."""
def once(text,old,new):
    assert text.count(old)==1,(old,text.count(old))
    return text.replace(old,new,1)
def apply_control(text):
    text=once(text,'    switch (p[0]) {\n','    switch (p[0]) {\n    case 25:\n        return stream_tuning_command(service->boot_id,p,bytes)==0 ? CONTROL_APPLIED : CONTROL_REJECTED;\n')
    # Both the lease exception and the result/auto-start exception are required.
    old='payload[0]==23u || payload[0]==24u'
    assert text.count(old)==2
    text=text.replace(old,old+' || payload[0]==25u')
    assert text.count('payload[0]==25u')==2
    return '#include "stream_tuning.h"\n'+text
def apply_fusion(text):
    return '#include "stream_tuning.h"\n'+once(text,'    servo_tracking_init(status_start);','    servo_tracking_init(status_start);\n    stream_tuning_init();')

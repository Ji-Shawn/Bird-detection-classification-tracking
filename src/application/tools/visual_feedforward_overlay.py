"""M47 control routing only; independent cmd27 transaction owns its dedup.

Both outer-cache bypasses are necessary: no sequence collision and no renewal
of the automatic-control lease when applying or replaying tuning packets.
"""


def apply_control(text):
    anchor='    switch (p[0]) {\n'
    assert text.count(anchor)==1, 'M47 control switch anchor'
    text=text.replace(anchor,anchor+'    case 27:\n'
        '        return servo_tracking_feedforward_command(service->boot_id,p,bytes)==0 ? CONTROL_APPLIED : CONTROL_REJECTED;\n',1)
    old='payload[0]==23u || payload[0]==24u || payload[0]==25u || payload[0]==26u'
    assert text.count(old)==2, ('M47 transaction cache/lease exceptions',text.count(old))
    return text.replace(old,old+' || payload[0]==27u')


def revert_control(text):
    route='    case 27:\n        return servo_tracking_feedforward_command(service->boot_id,p,bytes)==0 ? CONTROL_APPLIED : CONTROL_REJECTED;\n'
    assert text.count(route)==1
    text=text.replace(route,'',1)
    old='payload[0]==23u || payload[0]==24u || payload[0]==25u || payload[0]==26u'
    assert text.count(old+' || payload[0]==27u')==2
    return text.replace(old+' || payload[0]==27u',old)

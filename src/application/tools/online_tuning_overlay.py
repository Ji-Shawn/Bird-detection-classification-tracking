"""M39 online P-controller tuning, with exact inverse transforms for scope QA.

No old SRV6/SRV7 fields or unsupported command meanings are repurposed.
The 8 values are RAM-only and never start/renew automatic control.
"""

HEADER = '''/* M39 RAM-only continuous visual-controller configuration. Values are
 * [pan Kp, tilt Kp, pan max, tilt max, pan enter, pan exit, tilt enter, tilt exit].
 * Kp: command degrees/s per full-image normalized error; max: command deg/s;
 * deadbands: fractions of FULL image width/height, not percentages. Pan uses
 * platform degrees; tilt uses shaft degrees. No encoder/speed feedback.
 * cmd23 v1 is 46 bytes: command/schema, BE boot/revision/request, 8 BE floats.
 * SRV9 appends actual adopted values and request acknowledgement to telemetry.
 */
int servo_tracking_tuning_command(uint32_t boot_id,const uint8_t *payload,unsigned bytes);
void servo_tracking_tuning_status(uint32_t words[16],uint32_t boot_id);
'''

STATE = '''/* M39: full-frame normalized visual errors; compile-time defaults remain
 * the M38 candidate settings. All changes are atomic and RAM-only. */
static const float tuning_defaults[8]={VISUAL_SERVO_PAN_KP_DPS,VISUAL_SERVO_TILT_KP_DPS,
    VISUAL_SERVO_PAN_MAX_DPS,VISUAL_SERVO_TILT_MAX_DPS,VISUAL_SERVO_PAN_DEAD_ENTER,
    VISUAL_SERVO_PAN_DEAD_EXIT,VISUAL_SERVO_TILT_DEAD_ENTER,VISUAL_SERVO_TILT_DEAD_EXIT};
static float tuning_values[8];
static uint32_t tuning_revision,tuning_ack_request,tuning_ack_status,tuning_applies,tuning_cache_next;
static struct {uint8_t request[46];uint32_t id,status,valid;} tuning_cache[16];
static void tuning_reset(void) {
    memcpy(tuning_values,tuning_defaults,sizeof tuning_values);
    tuning_revision=1u;tuning_ack_request=tuning_ack_status=tuning_applies=tuning_cache_next=0;
    memset(tuning_cache,0,sizeof tuning_cache);
}
'''

FUNCTIONS = '''/* Validate every value before replacing any value. Configuration bounds
 * are not claims of verified mechanical speed. IEEE values are copied by bits,
 * never through an unaligned wire pointer. */
static uint32_t tuning_be32(const uint8_t *p) {
    return ((uint32_t)p[0]<<24)|((uint32_t)p[1]<<16)|((uint32_t)p[2]<<8)|p[3];
}
int servo_tracking_tuning_command(uint32_t boot_id,const uint8_t *p,unsigned bytes) {
    if(!p || bytes!=46u)return -1;
    uint32_t request=tuning_be32(p+10),status=0;
    tuning_ack_request=request;
    if(p[0]!=23u || p[1]!=1u){tuning_ack_status=2u;return -1;}
    if(!boot_id || tuning_be32(p+2)!=boot_id){tuning_ack_status=3u;return -1;}
    if(!request){tuning_ack_status=5u;return -1;}
    for(unsigned i=0;i<16;i++)if(tuning_cache[i].valid && tuning_cache[i].id==request) {
        status=memcmp(tuning_cache[i].request,p,46u)?6u:tuning_cache[i].status;
        if(status==1u)status=7u;
        tuning_ack_status=status;return status==7u?0:-1;
    }
    float values[8];
    for(unsigned i=0;i<8;i++) {
        uint32_t bits=tuning_be32(p+14+4*i);memcpy(values+i,&bits,4);
        if(!isfinite(values[i]))status=5u;
    }
    for(unsigned i=0;i<2;i++)if(values[i]<1.f || values[i]>240.f)status=5u;
    for(unsigned i=2;i<4;i++)if(values[i]<1.f || values[i]>60.f)status=5u;
    for(unsigned i=4;i<8;i+=2)
        if(values[i]<.005f || values[i]>.15f || values[i+1]<.01f ||
           values[i+1]>.20f || values[i]>=values[i+1])status=5u;
    if(!supported)status=8u;
    if(tuning_be32(p+6)!=tuning_revision || tuning_revision==UINT32_MAX)status=4u;
    if(!status) {
        memcpy(tuning_values,values,sizeof tuning_values);tuning_revision++;tuning_applies++;
        /* Drop old sub-PWM fractions and hysteresis, retaining accepted PWM
         * estimates, frame freshness, elapsed-time clock and control owner.
         * This function writes no registers and never renews the lease. */
        if(continuous.active) {
            continuous.pan_mdeg=(float)pose();continuous.tilt_mdeg=shaft_for_pulse(tilt_us);
            continuous.pan_moving=continuous.tilt_moving=0;
        }
        status=1u;
    }
    unsigned index=tuning_cache_next++&15u;
    memcpy(tuning_cache[index].request,p,46u);tuning_cache[index].id=request;
    tuning_cache[index].status=status;tuning_cache[index].valid=1u;
    tuning_ack_status=status;return status==1u?0:-1;
}
void servo_tracking_tuning_status(uint32_t words[16],uint32_t boot_id) {
    memset(words,0,16*sizeof *words);
    words[0]=0x53525639u;words[1]=1u;words[2]=tuning_revision;
    words[3]=tuning_ack_request;words[4]=tuning_ack_status;words[5]=boot_id;
    for(unsigned i=0;i<8;i++)memcpy(words+6+i,tuning_values+i,4);
    words[14]=tuning_applies;
}
'''


def _replace(text, old, new):
    assert text.count(old) == 1, ('M39 exact anchor', old[:120], text.count(old))
    return text.replace(old, new)


CONTROL = '''    case 23:
        return servo_tracking_tuning_command(service->boot_id,p,bytes)==0 ?
               CONTROL_APPLIED : CONTROL_REJECTED;
'''


def apply_control(text):
    text = _replace(text, '    switch (p[0]) {\n', '    switch (p[0]) {\n'+CONTROL)
    text = _replace(text, '    for (index = 0; index < 16u; ++index)\n',
                    '    /* cmd23 has boot/revision/full-request idempotence, independent of outer UDP sequence. */\n'
                    '    if (!(bytes && payload[0]==23u))\n    for (index = 0; index < 16u; ++index)\n')
    return _replace(text, '    result = apply_command(service, control, payload, bytes);\n',
                    '    result = apply_command(service, control, payload, bytes);\n'
                    '    if (bytes && payload[0]==23u) return result;\n')


def revert_control(text):
    text = _replace(text, '    switch (p[0]) {\n'+CONTROL, '    switch (p[0]) {\n')
    text = _replace(text,
                    '    /* cmd23 has boot/revision/full-request idempotence, independent of outer UDP sequence. */\n'
                    '    if (!(bytes && payload[0]==23u))\n    for (index = 0; index < 16u; ++index)\n',
                    '    for (index = 0; index < 16u; ++index)\n')
    return _replace(text, '    result = apply_command(service, control, payload, bytes);\n'
                    '    if (bytes && payload[0]==23u) return result;\n',
                    '    result = apply_command(service, control, payload, bytes);\n')


RATES_OLD = '''    float vx=visual_rate(continuous.x,&continuous.pan_moving,VISUAL_SERVO_PAN_DEAD_ENTER,
        VISUAL_SERVO_PAN_DEAD_EXIT,VISUAL_SERVO_PAN_KP_DPS,VISUAL_SERVO_PAN_MAX_DPS);
    float vy=visual_rate(continuous.y,&continuous.tilt_moving,VISUAL_SERVO_TILT_DEAD_ENTER,
        VISUAL_SERVO_TILT_DEAD_EXIT,VISUAL_SERVO_TILT_KP_DPS,VISUAL_SERVO_TILT_MAX_DPS);
'''
RATES_NEW = '''    float vx=visual_rate(continuous.x,&continuous.pan_moving,tuning_values[4],
        tuning_values[5],tuning_values[0],tuning_values[2]);
    float vy=visual_rate(continuous.y,&continuous.tilt_moving,tuning_values[6],
        tuning_values[7],tuning_values[1],tuning_values[3]);
'''


def apply_servo(text):
    text = _replace(text, 'static void continuous_reset(void)', STATE+'static void continuous_reset(void)')
    text = _replace(text, 'static void continuous_poll(void) {', FUNCTIONS+'static void continuous_poll(void) {')
    text = _replace(text, RATES_OLD, RATES_NEW)
    return _replace(text, 'void servo_tracking_init(uint64_t now) {\n    continuous_reset();',
                    'void servo_tracking_init(uint64_t now) {\n    continuous_reset();tuning_reset();')


def revert_servo(text):
    text = _replace(text, STATE+'static void continuous_reset(void)', 'static void continuous_reset(void)')
    text = _replace(text, FUNCTIONS+'static void continuous_poll(void) {', 'static void continuous_poll(void) {')
    text = _replace(text, RATES_NEW, RATES_OLD)
    return _replace(text, 'void servo_tracking_init(uint64_t now) {\n    continuous_reset();tuning_reset();',
                    'void servo_tracking_init(uint64_t now) {\n    continuous_reset();')


def apply_header(text):
    return _replace(text, '#endif\n', HEADER+'#endif\n')


def revert_header(text):
    return _replace(text, HEADER+'#endif\n', '#endif\n')


TELEMETRY_MEMBER = '    uint32_t visual_tuning[16]; /* SRV9 v1 RAM-only P control, appended at byte 840. */\n'
TELEMETRY_SEND = '''    uint32_t tuning[16];servo_tracking_tuning_status(tuning,service->boot_id);
    for(unsigned i=0;i<16;i++)t.visual_tuning[i]=swap32(tuning[i]);
'''


def apply_telemetry(text):
    text = _replace(text, '} telemetry_v1_t;', TELEMETRY_MEMBER+'} telemetry_v1_t;')
    text = _replace(text, 'offsetof(telemetry_v1_t,servo_position)==792 && sizeof(telemetry_v1_t)==840,',
                    'offsetof(telemetry_v1_t,servo_position)==792 &&\n'
                    '               offsetof(telemetry_v1_t,visual_tuning)==840 && sizeof(telemetry_v1_t)==904,')
    return _replace(text, '    return udp_send_status_payload(service, sequence, &t, sizeof(t));',
                    TELEMETRY_SEND+'    return udp_send_status_payload(service, sequence, &t, sizeof(t));')


def revert_telemetry(text):
    text = _replace(text, TELEMETRY_MEMBER+'} telemetry_v1_t;', '} telemetry_v1_t;')
    text = _replace(text, 'offsetof(telemetry_v1_t,servo_position)==792 &&\n'
                    '               offsetof(telemetry_v1_t,visual_tuning)==840 && sizeof(telemetry_v1_t)==904,',
                    'offsetof(telemetry_v1_t,servo_position)==792 && sizeof(telemetry_v1_t)==840,')
    return _replace(text, TELEMETRY_SEND+'    return udp_send_status_payload(service, sequence, &t, sizeof(t));',
                    '    return udp_send_status_payload(service, sequence, &t, sizeof(t));')

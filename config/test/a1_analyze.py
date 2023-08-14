#!/usr/bin/python3

# Tshark command
# sudo tshark -o nas-5gs.null_decipher:true -i any -Y 'ngap && ip.addr == 192.168.4.80' -T fields -e frame.time_relative -e ngap.RAN_UE_NGAP_ID -e ngap.AMF_UE_NGAP_ID -e nas_5gs.sm.message_type -e nas_5gs.mm.message_type -e ngap.procedureCode -e ip.dst > /local/repository/config/test/tshark-log.txt


import pandas
pandas.options.mode.chained_assignment = None  # default='warn'
import numpy

import matplotlib
matplotlib.use('pdf')
import matplotlib.pyplot as plt

# 5G IDs
REGISTRATION_REQUEST = 0x41 #65
AUTH_REQUEST = 0x56 #86

AUTH_RESPONSE = 0x57 #87
SEC_MODE_COMMAND = 0x5D #93

SEC_MODE_COMPLETE = 0x5E #94
REGISTRATION_ACCEPT = 0x42 #66

PDU_SESSION_REQUEST = 0xC1 #193
PDU_SESSION_ACCEPT = 0xC2 #194

DEREGISTRATION_REQUEST = 0x45 #69
DEREGISTRATION_ACCEPT = 0x46 #70


UPLINK_MESSAGES = [
    REGISTRATION_REQUEST,
    AUTH_RESPONSE,
    SEC_MODE_COMPLETE,
    PDU_SESSION_REQUEST,
    DEREGISTRATION_REQUEST
]

DOWNLINK_MESSAGES = [
    AUTH_REQUEST,
    SEC_MODE_COMMAND,
    REGISTRATION_ACCEPT,
    PDU_SESSION_ACCEPT,
    DEREGISTRATION_ACCEPT
]


ue_msg_buffers = {}

# lists to be turned into dataframes
latency_list = []
uplink_list = []
downlink_list = []
req_resp_rat = {'valid': 0, 'invalid': 0}


def parse_line(line):
    [msg_time, ran_id, amf_id, sm_id, mm_id, ngap_id, dest_ip] = line.strip().split('\t')
    ue_id = ran_id if ran_id != '' else amf_id
    msg_id = sm_id if sm_id != '' else mm_id if mm_id != '' else ngap_id
    # an annoying edge case for the Security Mode Complete
    if sm_id == REGISTRATION_REQUEST: msg_id = SEC_MODE_COMPLETE
    if ue_id == '':
        return
    #if ue_id != '1': # TODO: just for testing
    #    return
    if msg_id == '0x5e,0x41':
        msg_id = '0x5e'
    if msg_id.startswith('0x'):
        msg_id = int(msg_id, 16)
    process_message(float(msg_time), int(ue_id), int(msg_id), dest_ip)


def process_message(msg_time, ue_id, msg_id, dest_ip):
    if dest_ip == '192.168.4.80':
        uplink_list.append([msg_time, 1])
    else:
        downlink_list.append([msg_time, 1])

    # check to see if we care about this message
    if msg_id not in UPLINK_MESSAGES + DOWNLINK_MESSAGES:
        return

    # handle an uplink message
    if msg_id in UPLINK_MESSAGES:
        ue_msg_buffers[ue_id] = (msg_time, msg_id)
        return

    # handle a downlink message
    valid_msg = handle_request_response_ratio(ue_id, msg_id)
    if valid_msg:
        # calculate the latency for this message and save it in the latency list
        msg_latency = msg_time - ue_msg_buffers[ue_id][0]
        latency_list.append([msg_time, ue_id, msg_latency])


def handle_request_response_ratio(ue_id, msg_id):
    last_message_from_ue = ue_msg_buffers[ue_id][1] if ue_id in ue_msg_buffers else None
    valid_msg = (last_message_from_ue == REGISTRATION_REQUEST   and msg_id == AUTH_REQUEST)          or \
                (last_message_from_ue == AUTH_RESPONSE          and msg_id == SEC_MODE_COMMAND)      or \
                (last_message_from_ue == SEC_MODE_COMPLETE      and msg_id == REGISTRATION_ACCEPT)   or \
                (last_message_from_ue == PDU_SESSION_REQUEST    and msg_id == PDU_SESSION_ACCEPT)    or \
                (last_message_from_ue == DEREGISTRATION_REQUEST and msg_id == DEREGISTRATION_ACCEPT)
    invalid_msg = (last_message_from_ue == REGISTRATION_REQUEST   and msg_id != AUTH_REQUEST)          or \
                (last_message_from_ue == AUTH_RESPONSE          and msg_id != SEC_MODE_COMMAND)      or \
                (last_message_from_ue == SEC_MODE_COMPLETE      and msg_id != REGISTRATION_ACCEPT)   or \
                (last_message_from_ue == PDU_SESSION_REQUEST    and msg_id != PDU_SESSION_ACCEPT)    or \
                (last_message_from_ue == DEREGISTRATION_REQUEST and msg_id != DEREGISTRATION_ACCEPT)
    if valid_msg:
        req_resp_rat['valid'] += 1
    elif invalid_msg:
        print('Invalid msg', last_message_from_ue, msg_id)
        req_resp_rat['invalid'] += 1
    return valid_msg


def create_summarised_dfs():
    uplink_df = pandas.DataFrame(uplink_list, columns=['time', 'count'])
    downlink_df = pandas.DataFrame(downlink_list, columns=['time', 'count'])
    latency_df = pandas.DataFrame(latency_list, columns=['time', 'ue', 'latency'])
    up_df = summarise_df(uplink_df, 'count', 'sum')
    down_df = summarise_df(downlink_df, 'count', 'sum')
    lat_df = summarise_df(latency_df, 'latency', 'mean')
    return up_df, down_df, lat_df


def summarise_df(df, col, aggregate_func):
    end_time = int(max(numpy.ceil(df['time'])))
    buckets = range(0, end_time)
    df['time_category'] = pandas.cut(df['time'], buckets)
    df[f'reduced_{col}'] = df.groupby('time_category')[col].transform(aggregate_func)
    df = df.drop_duplicates(subset=['time_category', f'reduced_{col}'])
    df['time'] = df['time_category'].apply(lambda x: x.left).astype(int)
    df = df[['time', f'reduced_{col}']]
    df = df.rename(columns={f'reduced_{col}': col})
    df = df.reset_index(drop=True)
    df = df.dropna()
    return df


def plot_msg_df(up_df, down_df):
    plt.plot(up_df['time'], up_df['count'], label='Uplink')
    plt.plot(down_df['time'], down_df['count'], label='Downlink')
    plt.xlabel('Time (s)')
    plt.ylabel('Packets per second')
    plt.title('Packets per second (PPS)')
    plt.legend()
    plt.savefig('/local/repository/config/test/packets-per-second.pdf')
    plt.clf()
    print('Packets per second PDF saved (/local/repository/config/test/packets-per-second.pdf)')


def plot_lat_df(lat_df):
    plt.plot(lat_df['time'], lat_df['latency'] * 1000)
    plt.xlabel('Time (s)')
    plt.ylabel('Average latency (ms)')
    plt.title('Message latencies')
    plt.savefig('/local/repository/config/test/message-latencies.pdf')
    plt.clf()
    print('Message latencies PDF saved (/local/repository/config/test/message-latencies.pdf)')


def print_req_resp_rat():
    valid = req_resp_rat['valid']
    invalid = req_resp_rat['invalid']
    ratio = (valid - invalid) / (valid + invalid)
    print(f'Request-response ratio: {ratio*100:.2f}%')


with open('/local/repository/config/test/tshark-log.txt') as f:
    for line in f:
        parse_line(line)
up_df, down_df, lat_df = create_summarised_dfs()
plot_msg_df(up_df, down_df)
plot_lat_df(lat_df)
print_req_resp_rat()

# Nervion Scenarios

A Nervion scenario is a JSON file that specifies the entire RAN architecture to be emulated and the behavior of the UEs that are part of it. The structure of a Nervion scenario is independent of the core network used (4G or 5G).

## What a Nervion scenario looks like?

Every Nervion scenario looks like this:

```yaml
{
  "enbs":
  [
    {
      "enb_num": 1,
      "enb_mcc": "<eNB MCC>",
      "enb_mnc": "<eNB MNC>"
    },
    ...
  ],
  "ues":
  [
    {
      "ue_mcc": "<UE MCC>",
      "ue_mnc": "<UE MNC>",
      "ue_msin": "<UE MSIN>",
      "ue_key": "<KEY>",
      "ue_op_key": "<Operator key>",
      "control_plane": "<Control Plane command>",
      "traffic_command": "<Data Plane command>",
      "enb": <Num of the eNB>
    },
    ...
  ]
}
```

Each Nervion scenario has two main objects: "enbs" (List of eNBs) and "ues" (List of UEs). 
The eNB list ("enbs") can contains any number of eNB objects each of them containing the following 4 mandatory fields:
- **enb_num**: Number of the eNB in the scenario (This field is used by the UEs to differentiate between eNBs and has to be *unique*)
- **enb_mcc**: Mobile Country Code (e.g. enb_mcc: "208")
- **enb_mnc**: Mobile Network Code (e.g. enb_mnc: "93")

Similarly to the eNBs list, the UEs list contains a list of UE objects each of them containing 9 mandatory fields:
- **ue_mcc**: Mobile Country Code (Generally, it has to match with the MCC of the serving eNB)
- **ue_mnc**: Mobile Network Code (Generally, it has to match with the MNC of the serving eNB)
- **ue_msin**: 10-digit string that uniquely identifies a UE in the core (e.g. ue_msin: "0000000001")
- **ue_key**: 16-byte string UE key (e.g. ue_key: "0x00000000000000000000000000000000")
- **ue_op_key**: 16-byte string Operator's key (e.g. ue_op_key: "0x00112233445566778899AABBCCDDEEFF")
- **control_plane**: Control plane command that defines the behavior of the UE (More details about this bellow)
- **traffic_command**: Bash command with the tool that generates traffic (e.g. traffic_command: ping -I {TUN} 8.8.8.8). This command is executed only when the UE is attached to the network.
- **enb**: Number of the eNB that is going to be the initial serving eNB.

Note that *enb* in the scenario can refer to either eNB or gNB as appropriate for the emulation scenario.

## How to specify Control Plane actions

The **control_plane** command is a string that defines actions in the following finite state machine (FSM). The Control Plane FSM represents the different states on which a UE can be and the control plane actions that can be taken:
![Control Plane state machine](/doc/images/state_machine.png)

The control-plane behaviour description language is a string of tuples. Each tuple has two elements: the action and the delay time. The action has to be one of the transitions in the FSM and the delay time has to be a positive integer, zero or the, '*inf*' string that represents the number of seconds that the UE is going to stay in the state result of that action; however, there are some actions that require some extra information, such as Handover procedures and attaching to another eNB. For those cases, the eNB ID has to be concatenated with the action. The character '*-*' (dash) is used as a separator between actions and delay times.

Every **control_plane** command has to start with the action '*init*' which performs the initial attach event with the eNB defined in the '*enb*' field defined for that UE. Another mandatory rule is that the **control_plane** command has to finish with an '*inf*' delay time or in the *Attached/Traffic* state. This is because the **control_plane** command is executed in a loop so the only way of finishing is by staying in a state for an infinite amount of time or by going back to the initial state (Attach/Traffic) to start the actions again from there. Note that the control plane actions have to be coherent with the FSM diagram (e.g. UE cannot go to Idle state from the Detached state).

The keywords used for the actions are the following:
- **init**: Initial action
- **detach**: Detach the UE from the core and move it from the Attached/Traffic state to the Detach state.
- **detach_switch_off**: Similar to detach but using the detach with switch off procedure insead.
- **attach**: Attach the UE to the core using the default eNB and move it from the Detach state to the Attached/Traffic state.
- **attach_\<eNB>**: Attach the UE to the core using another eNB (e.g. attach_3 attaches the UE using the eNB with ID 3).
- **move_to_idle**: The UE is moved to IDLE (In 4G this is done through the S1 Release event).
- **move_to_connected**: The UE is moved from IDLE to Connected (Atttached/Traffic state). In 4G this is done through the Service Request event.
- **x2handover_\<eNB>**: The UE performs an X2 handover with another eNB (e.g. x2handover_4 moves the UE from the current eNB to the eNB with ID 4).
- **s1handover_\<eNB>**: The UE performs an S1 handover with another eNB (e.g. s1handover_2 moves the UE from the current eNB to the eNB with ID 2).

The 4G version of Nervion currently supports the following actions: init, detach, detach_switch_off, attach, attach_\<eNB>, move_to_idle, move_to_connected, and x2handover_\<eNB>. s1handover_\<eNB> is partially supported. On the other hand, Nervion 5G supports: init, detach, detach_switch_off, attach, and attach_\<eNB>.


Some useful **control_plane** command examples:
- **init-inf**: Attach the UE and remains attached until the end of the experiment.
- **init-10-detach-inf**: Attach the UE during 10 seconds and then detach the UE.
- **init-15-detach-30-attach-15**: The UE attaches to the core for 15 seconds. Then it detaches from the network for 30 seconds. And finally it attaches again for another 15 seconds and the actions start again.
- **init-0-detach-0-attach-0**: Attach and Detach from the core as quick as possible in an infinite loop (This is used to generate high loads).

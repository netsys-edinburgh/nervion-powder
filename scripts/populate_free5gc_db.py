import pymongo
import sys

plmn = '20893'

policyData_ues_amData = {'subscCats': ['free5gc'], 'ueId': 'imsi-208930000000003'}

subscriptionData_provisionedData_smfSelectionSubscriptionData = {'ueId': 'imsi-208930000000003', 'servingPlmnId': '20893'}

subscriptionData_authenticationData_authenticationSubscription = {	'authenticationManagementField': '8000', 
																	'milenage': 
																		{'op': 
																			{	'opValue': '', 
																				'encryptionKey': 0.0, 
																				'encryptionAlgorithm': 0.0
																			}
																		},
																	'opc': 
																		{'opcValue': 
																			'8e27b6af0e692e750f32667a3b14605d', 
																			'encryptionKey': 0.0, 
																			'encryptionAlgorithm': 0.0
																		}, 
																	'ueId': 'imsi-208930000000005', 
																	'authenticationMethod': '5G_AKA', 
																	'permanentKey': 
																		{	'encryptionKey': 0.0, 
																			'encryptionAlgorithm': 0.0, 
																			'permanentKeyValue': '8baf473f2f8fd09487cccbd7097c6862'
																		}, 
																	'sequenceNumber': '16f3b3f70fc2'}

policyData_ues_smData = {	'ueId': 'imsi-208930000000003', 
							'smPolicySnssaiData': 
								{	'01010203': 
									{	'snssai': 
										{	'sst': 1.0, 
											'sd': '010203'
										}, 
										'smPolicyDnnData': 
										{	'internet': 
											{	'dnn': 'internet'}
										}
									}, 
									'01112233': 
									{	'snssai': 
										{	'sst': 1.0, 
											'sd': '112233'
										}, 
										'smPolicyDnnData': 
										{	'internet2': 
											{	'dnn': 'internet2'}
										}
									}
								}
							}

subscriptionData_provisionedData_amData = {	'gpsis': ['msisdn-0900000000'], 
											'subscribedUeAmbr': {'uplink': '1 Gbps', 'downlink': '2 Gbps'}, 
											'nssai': {'defaultSingleNssais': [{'sd': '010203', 'sst': 1.0}, {'sst': 1.0, 'sd': '112233'}]}, 
											'ueId': 'imsi-208930000000003', 'servingPlmnId': '20893'}

subscriptionData_provisionedData_smData_1 = {	'servingPlmnId': '20893', 
												'singleNssai': {'sst': 1.0, 'sd': '010203'}, 
												'dnnConfigurations': {	'internet': 
																		{	'sessionAmbr': {'uplink': '200 Mbps', 'downlink': '100 Mbps'}, 
																			'pduSessionTypes': {'defaultSessionType': 'IPV4', 'allowedSessionTypes': ['IPV4']}, 
																			'sscModes': {'allowedSscModes': ['SSC_MODE_2', 'SSC_MODE_3'], 'defaultSscMode': 'SSC_MODE_1'}, 
																			'5gQosProfile': {'5qi': 9.0, 'arp': {'priorityLevel': 8.0, 'preemptCap': '', 'preemptVuln': ''}, 'priorityLevel': 8.0}
																		}, 
																		'internet2': 
																		{	'sessionAmbr': {'uplink': '200 Mbps', 'downlink': '100 Mbps'},
																			'pduSessionTypes': {'defaultSessionType': 'IPV4', 'allowedSessionTypes': ['IPV4']}, 
																			'sscModes': {'allowedSscModes': ['SSC_MODE_2', 'SSC_MODE_3'], 'defaultSscMode': 'SSC_MODE_1'}, 
																			'5gQosProfile': {'5qi': 9.0, 'arp': {'priorityLevel': 8.0, 'preemptCap': '', 'preemptVuln': ''}, 'priorityLevel': 8.0}
																		}
																	}, 
												'ueId': 'imsi-208930000000005'}

subscriptionData_provisionedData_smData_2 = {	'servingPlmnId': '20893',
												'singleNssai': {'sst': 1.0, 'sd': '112233'}, 
												'dnnConfigurations': {	'internet': 
																		{	'sessionAmbr': {'uplink': '200 Mbps', 'downlink': '100 Mbps'},
																			'pduSessionTypes': {'defaultSessionType': 'IPV4', 'allowedSessionTypes': ['IPV4']}, 
																			'sscModes': {'defaultSscMode': 'SSC_MODE_1', 'allowedSscModes': ['SSC_MODE_2', 'SSC_MODE_3']}, 
																			'5gQosProfile': {'5qi': 9.0, 'arp': {'priorityLevel': 8.0, 'preemptCap': '', 'preemptVuln': ''}, 'priorityLevel': 8.0}
																		}, 
																		'internet2': 
																		{	'sscModes': {'defaultSscMode': 'SSC_MODE_1', 'allowedSscModes': ['SSC_MODE_2', 'SSC_MODE_3']}, 
																			'5gQosProfile': {'5qi': 9.0, 'arp': {'priorityLevel': 8.0, 'preemptCap': '', 'preemptVuln': ''}, 'priorityLevel': 8.0}, 
																			'sessionAmbr': {'uplink': '200 Mbps', 'downlink': '100 Mbps'}, 
																			'pduSessionTypes': {'defaultSessionType': 'IPV4', 'allowedSessionTypes': ['IPV4']}
																		}
																	}, 
												'ueId': 'imsi-208930000000005'}

def add_user(num, db):
	imsi = "imsi-" + plmn + "{:010d}".format(num+1)

	# policyData.ues.amData
	policyData_ues_amData['ueId'] = imsi
	tmp = policyData_ues_amData.copy()
	db['policyData.ues.amData'].insert_one(tmp)

	# subscriptionData.provisionedData.smfSelectionSubscriptionData
	subscriptionData_provisionedData_smfSelectionSubscriptionData['ueId'] = imsi
	subscriptionData_provisionedData_smfSelectionSubscriptionData['servingPlmnId'] = plmn
	tmp = subscriptionData_provisionedData_smfSelectionSubscriptionData.copy()
	db['subscriptionData.provisionedData.smfSelectionSubscriptionData'].insert_one(tmp)

	# subscriptionData.authenticationData.authenticationSubscription
	subscriptionData_authenticationData_authenticationSubscription['ueId'] = imsi
	tmp = subscriptionData_authenticationData_authenticationSubscription.copy()
	db['subscriptionData.authenticationData.authenticationSubscription'].insert_one(tmp)

	# policyData.ues.smData
	policyData_ues_smData['ueId'] = imsi
	tmp = policyData_ues_smData.copy()
	db['policyData.ues.smData'].insert_one(tmp)

	# subscriptionData.provisionedData.amData
	subscriptionData_provisionedData_amData['ueId'] = imsi
	subscriptionData_provisionedData_amData['servingPlmnId'] = plmn
	tmp = subscriptionData_provisionedData_amData.copy()
	db['subscriptionData.provisionedData.amData'].insert_one(tmp)

	# subscriptionData.provisionedData.smData
	subscriptionData_provisionedData_smData_1['ueId'] = imsi
	subscriptionData_provisionedData_smData_1['servingPlmnId'] = plmn
	tmp = subscriptionData_provisionedData_smData_1.copy()
	db['subscriptionData.provisionedData.smData'].insert_one(tmp)
	subscriptionData_provisionedData_smData_2['ueId'] = imsi
	subscriptionData_provisionedData_smData_2['servingPlmnId'] = plmn
	tmp = subscriptionData_provisionedData_smData_2.copy()
	db['subscriptionData.provisionedData.smData'].insert_one(tmp)


myclient = pymongo.MongoClient("mongodb://localhost/free5gc")
mydb = myclient["free5gc"]

for i in range(int(sys.argv[1])):
	add_user(i, mydb)

print('Done!')








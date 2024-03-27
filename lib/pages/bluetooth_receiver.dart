// Part of code stolen from: 
// https://github.com/boskokg/flutter_blue_plus/tree/master/example

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:green_scout/pages/navigation_layout.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:green_scout/utils/bluetooth_utils.dart';
import 'package:green_scout/utils/snackbar.dart';
import 'package:green_scout/widgets/floating_button.dart';
import 'package:green_scout/widgets/scan_result_tile.dart';

class BluetoothReceiverPage extends StatefulWidget {
	const BluetoothReceiverPage({super.key});

	@override
	State<BluetoothReceiverPage> createState() => _BluetoothReceiverPage();
}

class _BluetoothReceiverPage extends State<BluetoothReceiverPage> {

	// This code is borrowed from the flutter blue plus example.
	List<BluetoothDevice> _systemDevices = [];
	List<ScanResult> _scanResults = [];
	bool _isScanning = false;
	late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  	late StreamSubscription<bool> _isScanningSubscription;

	List<int> senderMessage = [];

	BluetoothDevice? currentDevice;

	@override
	void initState() {
		super.initState();

		_scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
			_scanResults = [];

			for (final result in results) {
				for (final service in result.device.servicesList) {
					if (service.uuid.str128 == serviceUuid.toLowerCase()) {
						break;
					}
				}

				// if (result.device.advName.isEmpty) {
				// 	break;
				// }

				_scanResults.add(result);
			}

			if (mounted) {
				setState(() {});
			}
		}, onError: (e) {
			Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
		});

		_isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
				_isScanning = state;
				if (mounted) {
					setState(() {});
				}
			}
		);
	}

	@override
	void deactivate() {
		_scanResultsSubscription.cancel();
		_isScanningSubscription.cancel();

		super.deactivate();
	}

	Future<void> onConnectPressed(BluetoothDevice device) async {
		try {
			if (currentDevice != null) { 
				await currentDevice!.disconnect().catchError((e) {
					Snackbar.show(ABC.c, prettyException("Disconnect Error: ", e), success: false);
				});
			}

			if (!device.isConnected) {
				await device.connect(mtu: null).catchError((e) {
					Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
				});

				currentDevice = device;
			} else {
				await device.disconnect().catchError((e) {
					Snackbar.show(ABC.c, prettyException("Disconnect Error: ", e), success: false);
				});

				currentDevice = null;
			}
		} finally {
			
		}
	}

	List<Widget> _buildSystemDeviceTiles(BuildContext context) {
		return _systemDevices
			.map(
				(d) => Text(d.advName),
			)
			.toList();
	}

	List<Widget> _buildScanResultTiles(BuildContext context) {
		return _scanResults
			.map(
				(r) => ScanResultTile(
					result: r,
					onTap: () async => await onConnectPressed(r.device),
				),
			)
		.toList();
	}

	Future<void> readDataFromDevice(BluetoothDevice? currentDevice) async {
		if (currentDevice == null) {
			print("Tried to send data without having a device to send too.");
			return;
		}

		try {
			await currentDevice.discoverServices();
		} catch (e) {
			print("Unable to discover services");
			Snackbar.show(ABC.a, "Unable to write to device.", success: false);
			return;
		}

		for (var service in currentDevice.servicesList) {
			for (var characteristic in service.characteristics) {
				print("found characteristic: ${characteristic.uuid.str128}");

				if (!characteristic.properties.read) {
					continue;
				}
				
				try {
					// The '3' is for the amount of space the bluetooth
					// device takes up for sending the data.
					// final maximumMessageSize = currentDevice.mtuNow - 3;

					senderMessage += await characteristic.read();

					// final packetCount = message.length ~/ maximumMessageSize;

					// for (var i = 0; i < packetCount; i++) {
					// 	await characteristic.write(
					// 		utf8.encode(message)
					// 			.sublist(
					// 				i     * maximumMessageSize,
					// 				(i+1) * maximumMessageSize,
					// 			), 
					// 		withoutResponse: characteristic.properties.writeWithoutResponse,
					// 	);
					// }

					// if (message.length % maximumMessageSize != 0) {
					// 	await characteristic.write(
					// 		utf8.encode(message)
					// 			.sublist(packetCount * maximumMessageSize), 
					// 		withoutResponse: characteristic.properties.writeWithoutResponse,
					// 	);
					// }
				} catch (e) {
					continue;
				}

				return;
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				backgroundColor: Theme.of(context).colorScheme.inversePrimary,
				actions: const [
					NavigationMenu(),
					Spacer(),
				],
			),

			body: buildBody(context),
		);
	}

	Widget buildBody(BuildContext context) {
		return ListView(
			children: [
				FloatingButton(
					labelText: "Find Device",
					onPressed: () async {
						try {
							_systemDevices = await FlutterBluePlus.systemDevices;
						} catch (e) {
							Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
						}

						await FlutterBluePlus.startScan(
							withKeywords: ["GreenScoutSender"],
							timeout: const Duration(seconds: 15),
						);

						if (mounted) {
							setState(() {});
						}
					},
				),
				FloatingButton(
					labelText: "Reading Example Data",
					onPressed: () async {
						print("Reading example data");
						await readDataFromDevice(currentDevice);	
						setState(() {});
					},
				),
				Text(utf8.decode(senderMessage)),
				..._buildSystemDeviceTiles(context),
				..._buildScanResultTiles(context),
			],
		);
	}
}
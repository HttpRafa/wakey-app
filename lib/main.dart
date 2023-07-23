import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:wakey/objects/device.dart";
import "package:wakey/utils/wakey_preferences.dart";

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakeyPreferences.init();

  runApp(const WakeyApp());
}

class WakeyApp extends StatelessWidget {
  const WakeyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Wakey",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 114, 137, 218),
            brightness: Brightness.dark
        ),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(title: "Devices"),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final serverURLController = TextEditingController();
  final serverTokenController = TextEditingController();

  late List<Device> devices;
  bool deleteEnabled = false;

  void saveDevices() async {
    WakeyPreferences.setDevices(devices);
  }

  void removeDevice(Device device) {
    setState(() {
      devices.remove(device);
      saveDevices();
    });
  }

  Future<http.Response> sendWakeUpRequest(Device device) {
    return http.post(Uri.parse("${device.serverUrl}/v1/wake/${device.token}"));
  }

  void startDevice(Device device) async {
    showLoadingDialog("Sending request");

    sendWakeUpRequest(device).then((value) {
      if(value.statusCode == 200) {
        Navigator.of(context).pop();
        showInfoDialog("Wake response", [value.body]);
      } else {
        Navigator.of(context).pop();
        showInfoDialog("Failed to fetch data", ["${value.statusCode}", value.body]);
      }
    }).onError((error, stackTrace) {
      Navigator.of(context).pop();
      showInfoDialog("Wake response", [error.toString()]);
    }).timeout(const Duration(seconds: 10), onTimeout: () {
      Navigator.of(context).pop();
      showInfoDialog("Wake response", ["Timeout after 10s"]);
    });
  }

  void addDevice(Device device) {
    setState(() {
      devices.add(device);
      saveDevices();
    });
  }

  void toggleDeleteDevice() {
    setState(() {
      deleteEnabled = !deleteEnabled;
    });
  }

  @override
  void initState() {
    super.initState();

    devices = WakeyPreferences.getDevices();
  }

  @override
  void dispose() {
    serverURLController.dispose();
    serverTokenController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Center(
            child: Text(
              widget.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold
              ),
            ),
          )
      ),
      body: Scrollbar(
        child: ListView(
          restorationId: "devices_list_view",
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for(int i = 0; i < devices.length; i++)
              ListTile(
                leading: const ExcludeSemantics(
                  child: CircleAvatar(
                    child: Icon(Icons.network_ping),
                  ),
                ),
                title: Text(
                    devices[i].name
                ),
                subtitle: Text(devices[i].serverUrl),
                trailing: deleteEnabled ? ElevatedButton(
                  onPressed: () => removeDevice(devices[i]),
                  child: const Icon(
                    Icons.recycling,
                    color: Colors.red,
                  ),
                ) : ElevatedButton(
                  onPressed: () => startDevice(devices[i]),
                  child: const Icon(
                    Icons.start,
                    color: Colors.green,
                  ),
                ),
              )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(15),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () async {
                  final device = await openAddDeviceDialog();
                  if(device == null) return;
                  addDevice(device);
                },
                tooltip: "Add Device",
                child: const Icon(
                    Icons.add,
                    color: Colors.green
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: deleteEnabled ? FloatingActionButton(
                onPressed: toggleDeleteDevice,
                tooltip: "Change Device",
                child: const Icon(
                    Icons.start,
                    color: Colors.green
                ),
              ): FloatingActionButton(
                onPressed: toggleDeleteDevice,
                tooltip: "Delete Device",
                child: const Icon(
                    Icons.recycling,
                    color: Colors.red
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void showLoadingDialog(String action) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 25),
            child: CircularProgressIndicator(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25),
            child: Text(action),
          ),
        ],
      ),
    ));
  }

  void showInfoDialog(String title, List<String> info) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for(int index = 0; index < info.length; index++)
            Text(info[index])
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Ok")
        ),
      ],
    ));
  }

  Future<Device?> openAddDeviceDialog() => showDialog(context: context, builder: (context) => AlertDialog(
    title: const Text("Add Device"),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Server"),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: TextField(
            decoration: const InputDecoration(hintText: "URL"),
            controller: serverURLController,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: TextField(
            decoration: const InputDecoration(hintText: "Token"),
            controller: serverTokenController,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel")
      ),
      TextButton(
          onPressed: () {
            Device device = Device(serverURLController.text, serverTokenController.text);
            showLoadingDialog("Getting data from server");
            device.requestName().then((value) {
              Navigator.of(context).pop();
              if(value.statusCode == 200) {
                device.name = value.body;
                Navigator.of(context).pop(device);
              } else {
                showInfoDialog("Failed to fetch data", ["${value.statusCode}", value.body]);
              }
            }).onError((error, stackTrace) {
              Navigator.of(context).pop();
              showInfoDialog("Failed to fetch data", [error.toString()]);
            }).timeout(const Duration(seconds: 10), onTimeout: () {
              Navigator.of(context).pop();
              showInfoDialog("Failed to fetch data", ["Timeout after 10s"]);
            });
          },
          child: const Text("Add")
      )
    ],
  ));

}
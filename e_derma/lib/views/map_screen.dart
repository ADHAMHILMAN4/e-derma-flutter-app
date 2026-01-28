import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'butiran_pusat_derma_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

List<String> selectedTypes = [];
double? selectedDistance; // Distance filter in km (null = no filter)

class _MapScreenState extends State<MapScreen> {
  LatLng? userLocation;
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    loadMapData();
  }

  Future<LatLng?> getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) return null;
      }

      Position position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPusatDerma() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection("pusat_derma").get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching data: $e");
      return [];
    }
  }

  Future<List<String>> getAllDonationTypes() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection("pusat_derma").get();

    Set<String> types = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;

      // Ensure donationTypes is a string before splitting
      if (data['donationTypes'] is String) {
        String typeString = data['donationTypes'];
        types.addAll(
          typeString
              .split(',')
              .map((e) => e.trim())
              .where((type) => type.isNotEmpty),
        );
      }
    }

    return types.toList()..sort();
  }

  Future<void> loadMapData() async {
    LatLng? location = await getUserLocation();
    if (location == null) {
      print("User location not available.");
      return;
    }

    List<Map<String, dynamic>> pusatDermaList = await fetchPusatDerma();
    final Distance distance = Distance();

    List<Marker> loadedMarkers = pusatDermaList.where((data) {
      final lat = double.tryParse(data["latitude"].toString());
      final lng = double.tryParse(data["longitude"].toString());
      if (lat == null || lng == null) return false;

      final pusatLocation = LatLng(lat, lng);

      // Apply distance filter
      if (selectedDistance != null) {
        final double distanceInKm =
            distance.as(LengthUnit.Kilometer, location, pusatLocation);
        if (distanceInKm > selectedDistance!) return false;
      }

      // Apply donation type filter
      if (selectedTypes.isEmpty) return true;
      final types = (data["donationTypes"] ?? "")
          .split(",")
          .map((e) => e.trim().toLowerCase())
          .toList();
      return selectedTypes.any((type) => types.contains(type.toLowerCase()));
    }).map((data) {
      return Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(
          double.tryParse(data["latitude"].toString()) ?? 0.0,
          double.tryParse(data["longitude"].toString()) ?? 0.0,
        ),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0x80263238), // 50% opacity
                title: Text(
                  data["name"] ?? "Unknown Location",
                  style: const TextStyle(color: Colors.white),
                ),
                content: const SizedBox.shrink(), // Removes the details text
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFFFB800), // Button background
                      foregroundColor: Colors.white, // Text color
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ButiranPusatDermaPage(
                            pusatDermaData: data,
                          ),
                        ),
                      );
                    },
                    child: const Text("Lihat Butiran"),
                  ),
                ],
              ),
            );
          },
          child: Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }).toList();

    // Add user location marker
    loadedMarkers.add(
      Marker(
        width: 50.0,
        height: 50.0,
        point: location,
        child: Icon(
          Icons.person_pin_circle,
          color: Colors.blue,
          size: 50,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        userLocation = location;
        markers = loadedMarkers;
      });
    }
  }

  Future<Map<String, String>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('pengguna')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        return {
          'name': data?['name'] ?? 'Pengguna',
          'profilePicture': data?['profile_picture'] ??
              'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png',
        };
      }
    }
    return {
      'name': 'Pengguna',
      'profilePicture':
          'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: FutureBuilder<Map<String, String>>(
          future: _getUserData(),
          builder: (context, snapshot) {
            final userData = snapshot.data ??
                {
                  'name': 'Pengguna',
                  'profilePicture':
                      'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png',
                };

            return Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(userData['profilePicture']!),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        "Hello, ",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      Expanded(
                        // 👈 Wrap name in another Expanded to allow flexible width
                        child: Text(
                          userData['name']! + "!",
                          overflow: TextOverflow.ellipsis, // 👈 Add ellipsis
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.filter_list,
                    color:
                        Color(0xFFFFB800), // Yellow color for the filter icon
                  ),
                  onPressed: () async {
                    // Your filter action code here (e.g., showing filter dialog)
                    List<String> allTypes = await getAllDonationTypes();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setStateDialog) {
                            return AlertDialog(
                              backgroundColor:
                                  const Color.fromARGB(128, 219, 163, 58),
                              title: const Text(
                                "Tapis Jenis Derma & Jarak",
                                style: TextStyle(color: Colors.white),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...allTypes.map((type) {
                                      return Theme(
                                        data: ThemeData(
                                          unselectedWidgetColor: Colors
                                              .white, // Unchecked checkbox color
                                        ),
                                        child: CheckboxListTile(
                                          controlAffinity:
                                              ListTileControlAffinity.trailing,
                                          title: Text(type,
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                          value: selectedTypes.contains(type),
                                          activeColor: Color(0xFFFFB800),
                                          checkColor: Colors.black,
                                          onChanged: (bool? value) {
                                            setStateDialog(() {
                                              if (value == true) {
                                                selectedTypes.add(type);
                                              } else {
                                                selectedTypes.remove(type);
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    }).toList(),
                                    const Divider(color: Colors.white),
                                    const Text("Jarak maksimum (km):",
                                        style: TextStyle(color: Colors.white)),
                                    Column(
                                      children: [null, 5.0, 10.0, 20.0]
                                          .map((distance) {
                                        return Theme(
                                          data: ThemeData(
                                            unselectedWidgetColor: Colors
                                                .white, // Unchecked radio color
                                          ),
                                          child: ListTile(
                                            title: Text(
                                              distance == null
                                                  ? "Tiada Had Jarak"
                                                  : "${distance.toInt()} km",
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            trailing: Radio<double?>(
                                              value: distance,
                                              groupValue: selectedDistance,
                                              activeColor: Color(0xFFFFB800),
                                              onChanged: (value) {
                                                setStateDialog(() {
                                                  selectedDistance = value;
                                                });
                                              },
                                            ),
                                            onTap: () {
                                              setStateDialog(() {
                                                selectedDistance = distance;
                                              });
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    selectedTypes.clear();
                                    selectedDistance = null;
                                    Navigator.pop(context);
                                    loadMapData();
                                  },
                                  child: const Text("Tetap Semula",
                                      style: TextStyle(color: Colors.white)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFFB800),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    loadMapData();
                                  },
                                  child: const Text("Tapis"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: userLocation == null
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                center: userLocation,
                zoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                  userAgentPackageName:
                      'com.example.e_derma', // <-- replace with your real app ID
                ),
                MarkerLayer(markers: markers),
              ],
            ),
    );
  }
}

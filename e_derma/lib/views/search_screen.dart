import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'butiran_pusat_derma_page.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allPusatDerma = [];
  List<Map<String, dynamic>> _filteredPusatDerma = [];
  List<String> _states = ['All'];
  String _selectedState = 'All';
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    fetchPusatDerma();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String extractState(String address) {
    final knownStates = [
      'Selangor',
      'Kuala Lumpur',
      'Johor',
      'Penang',
      'Pulau Pinang',
      'Perak',
      'Pahang',
      'Negeri Sembilan',
      'Melaka',
      'Kedah',
      'Perlis',
      'Terengganu',
      'Kelantan',
      'Sabah',
      'Sarawak',
      'Labuan',
      'Putrajaya'
    ];

    for (var state in knownStates) {
      if (address.toLowerCase().contains(state.toLowerCase())) {
        return state;
      }
    }
    return 'Lain-lain';
  }

  Future<void> fetchPusatDerma() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection("pusat_derma").get();

      List<Map<String, dynamic>> data = snapshot.docs.map((doc) {
        var item = doc.data() as Map<String, dynamic>;
        item['state'] = extractState(item['address'] ?? '');
        return item;
      }).toList();

      final uniqueStates = data.map((e) => e['state']).toSet().toList();
      uniqueStates.sort();
      setState(() {
        _states = ['All', ...uniqueStates]; // Update the states list
        _allPusatDerma = data;
        _filteredPusatDerma = data;
      });

      // Initialize TabController after setting the states
      _tabController = TabController(length: _states.length, vsync: this);
      _tabController?.addListener(() {
        if (_tabController?.indexIsChanging ?? false) return;
        setState(() {
          _selectedState = _states[_tabController!.index];
          _filterResults();
        });
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  void _filterResults() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPusatDerma = _allPusatDerma.where((item) {
        final matchesName =
            item['name']?.toString().toLowerCase().contains(query) ?? false;
        final matchesState =
            _selectedState == 'All' ? true : item['state'] == _selectedState;
        return matchesName && matchesState;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Pusat Derma",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Masukkan nama pusat derma...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (_) => _filterResults(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // Show the TabBar only when _tabController is initialized and _states has more than one state
          if (_tabController != null && _states.length > 1)
            Container(
              color: Color(0xFFC4C4C4), // Tab background color
              child: TabBar(
                controller: _tabController!,
                isScrollable: true,
                labelColor: Color(0xFFFFB800), // Selected tab text color
                unselectedLabelColor:
                    Color(0xFF8A8A8A), // Unselected tab text color
                indicatorColor:
                    Color(0xFFFFB800), // Selected tab indicator color
                tabs: _states.map((state) => Tab(text: state)).toList(),
              ),
            ),
          Expanded(
            child: _filteredPusatDerma.isEmpty
                ? Center(child: Text("Tiada pusat derma dijumpai"))
                : ListView.builder(
                    itemCount: _filteredPusatDerma.length,
                    itemBuilder: (context, index) {
                      var pusatDerma = _filteredPusatDerma[index];
                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: (pusatDerma['profileImageUrl'] !=
                                          null &&
                                      pusatDerma['profileImageUrl']
                                          .toString()
                                          .isNotEmpty)
                                  ? NetworkImage(pusatDerma['profileImageUrl'])
                                  : const AssetImage(
                                          'assets/default_profile_image.png')
                                      as ImageProvider,
                            ),
                            title: Text(pusatDerma["name"] ?? "Unknown"),
                            subtitle:
                                Text(pusatDerma["state"] ?? "Tiada negeri"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ButiranPusatDermaPage(
                                    pusatDermaData: pusatDerma,
                                  ),
                                ),
                              );
                            },
                          ),
                          Divider(), // Adds a line below each pusat derma
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

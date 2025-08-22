import 'package:cropai/dashboard_screen.dart';
import 'package:flutter/material.dart';

class AgricultureSummaryPage extends StatefulWidget {
  const AgricultureSummaryPage({super.key});

  @override
  State<AgricultureSummaryPage> createState() => _AgricultureSummaryPageState();
}

class _AgricultureSummaryPageState extends State<AgricultureSummaryPage> {
  final List<Map<String, String>> data = [
    {
      "date": "2025-08-01",
      "location": "Location A",
      "block": "Block 1",
      "plot": "Plot 101",
      "activity": "Sowing",
      "description": "Seeds planted successfully."
    },
    {
      "date": "2025-08-03",
      "location": "Location A",
      "block": "Block 1",
      "plot": "Plot 101",
      "activity": "Fertilizing",
      "description": "Applied nitrogen fertilizer."
    }
  ];

  String? selectedLocation;
  String? selectedBlock;
  String? selectedPlot;
  String? selectedActivity;

  @override
  Widget build(BuildContext context) {
    List<String> locations = data.map((e) => e['location']!).toSet().toList();
    List<String> blocks = data.map((e) => e['block']!).toSet().toList();
    List<String> plots = data.map((e) => e['plot']!).toSet().toList();
    List<String> activities = data.map((e) => e['activity']!).toSet().toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Your custom SliverAppBar
          SliverAppBar(
            expandedHeight: 155.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF6B8E23),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.push(context, 
                MaterialPageRoute(builder:
                 (context)=>const DashboardScreen()));
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Agriculture Form Review',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),
              background: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: const BoxDecoration(
                  color: Color(0xFF6B8E23),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/circle_logo.png',
                      width: 100,
                      height: 60,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // Filter dropdowns
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildDropdown("Location", locations, selectedLocation,
                      (val) => setState(() => selectedLocation = val)),
                  _buildDropdown("Block", blocks, selectedBlock,
                      (val) => setState(() => selectedBlock = val)),
                  _buildDropdown("Plot", plots, selectedPlot,
                      (val) => setState(() => selectedPlot = val)),
                  _buildDropdown("Activity", activities, selectedActivity,
                      (val) => setState(() => selectedActivity = val)),
                ],
              ),
            ),
          ),

          // Data list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = data[index];

                if ((selectedLocation != null &&
                        item['location'] != selectedLocation) ||
                    (selectedBlock != null &&
                        item['block'] != selectedBlock) ||
                    (selectedPlot != null && item['plot'] != selectedPlot) ||
                    (selectedActivity != null &&
                        item['activity'] != selectedActivity)) {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ExpansionTile(
                    leading:
                        const Icon(Icons.agriculture, color: Colors.green),
                    title: Text(item['activity']!,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['date']!),
                    children: [
                      ListTile(
                        title: Text("Location: ${item['location']}"),
                      ),
                      ListTile(
                        title: Text("Block: ${item['block']}"),
                      ),
                      ListTile(
                        title: Text("Plot: ${item['plot']}"),
                      ),
                      ListTile(
                        title: Text("Description: ${item['description']}"),
                      ),
                    ],
                  ),
                );
              },
              childCount: data.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue,
      ValueChanged<String?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedValue,
        hint: Text(label),
        icon: const Icon(Icons.arrow_drop_down),
        underline: const SizedBox(),
        items: items
            .map((value) => DropdownMenuItem(
                  value: value,
                  child: Text(value),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

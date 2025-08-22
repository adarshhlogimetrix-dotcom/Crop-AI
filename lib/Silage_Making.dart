import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Constants.dart';
import 'dashboard_screen.dart';
import 'package:flutter/services.dart'; // Add this import for input formatters


class Silage_Making extends StatefulWidget {
  const Silage_Making({super.key});

  @override
  State<Silage_Making> createState() => silage_making();
}

class silage_making extends State<Silage_Making> {
  // Form Key
  final _formKey = GlobalKey<FormState>();
  String _areaText = '';

  String yieldMt='';
  

  // Text Controllers
  final TextEditingController _fuelConsumptionController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _yieldController = TextEditingController();


  final TextEditingController _HSD_Consuption_Controller = TextEditingController();

  // Focus nodes to track focus state
  final _levelingFocusNode = FocusNode();
  final _majorMaintenanceFocusNode = FocusNode();
  final _HSD_FocusNode = FocusNode();

  
  // Dropdown Values with default options
  final String? _selectedSiteName = 'Select Site';
  String? _selectedBlockName = 'Select Block';
  String? _selectedPlotName = 'Select Plot';
  final String? _selectedAreaName = 'Select Area';

  String? _selectedSilageMaking = 'Select Method';
  String? _selectedLandQuality = 'Select Land Quality';

  String? _selectedManPowerRoll = 'Select ManPower';

  String? _selectedSeedName = 'Select Seed Name ';

//  String? _selectedManPower = 'Select Man Power';

  // ID storage for API communication
  int? _selectedSiteId;
  int? _selectedBlockId;
  int? _selectedPlotId;
  double? _selectedArea;

  // Date and Time Controllers
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _formFieldsEnabled = false;

  // API Data
  final List<Map<String, dynamic>> _sites = [];
  List<Map<String, dynamic>> _blocks = [];
  List<Map<String, dynamic>> _plots = [];

  // Lists for dropdown items
  final List<String> _siteNames = ['Select Site'];
  List<String> _blockNames = ['Select Block'];
  List<String> _plotNames = ['Select Plot'];
  final List<String> _areaOptions = ['Select Area'];

  List<String> _seedName = ['Select Seed Name'];


  List<Map<String, TextEditingController>> _sparePartsControllers = [];

// Replace the old tractor variables
  Set<String> selectedTractors = {};
  List<String> _tractorName = ['Select Tractor'];
  bool showTractorDropdown = false;
  final TextEditingController _tractorSearchController = TextEditingController();
  List<String> _filteredTractorNames = [];

// Replace the old machine variables
  Set<String> selectedMachines = {};
  List<String> _machineName = ['Select Machine'];
  bool showMachineDropdown = false;
  final TextEditingController _machineSearchController = TextEditingController();
  List<String> _filteredMachineNames = [];


  final List<String> _methodSilageMaking = [
    'Select Method', 'Pit Method', 'Bag Method', 'Round Bail'
  ];

  final List<String> _manPowerRoll = [
    'Select ManPower', 'On Roll', 'Off Roll','Third Party'
  ];

  bool _isLoading = true;


  bool showCheckboxes = false;
  bool isLoading = true;

  List<String> categories = [];
  Set<String> selectedCategories = {};

  Map<String, TextEditingController> controllers = {};
  Map<String, FocusNode> focusNodes = {};



  // Map to store the relationship between display names and original API category names
  Map<String, String> categoryMapping = {};
// List to store display category names
  List<String> displayCategories = [];

  Future<bool> _onWillPop() async {
    // Navigate to dashboard screen when back button is pressed
    Navigator.pushReplacementNamed(context, '/dashboard');
    return false; // Prevents default back behavior
  }
  @override
  void initState() {
    super.initState();

    for (var controllerMap in _sparePartsControllers) {
      controllerMap['part']?.clear();
      controllerMap['value']?.clear();
    }

    // Optionally remove all but one field
    if (_sparePartsControllers.isNotEmpty) {
      final firstController = _sparePartsControllers.first;

      // Dispose all other controllers
      for (int i = 1; i < _sparePartsControllers.length; i++) {
        _sparePartsControllers[i]['part']?.dispose();
        _sparePartsControllers[i]['value']?.dispose();
      }

      _sparePartsControllers = [firstController];
    }


    _fetchBlocksAndPlots();
    _machineName = ['Select Machine'];
   /* _selectedMachine = 'Select Machine';*/
    _fetchMachineDetails();
    _fetchTractorDetails();
    fetchCategories();

    // Add listeners to focus nodes
    _levelingFocusNode.addListener(() {
      setState(() {});
    });
  }
  void _addNewSparePart() {
    setState(() {
      _sparePartsControllers.add({
        'part': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _removeSparePart(int index) {
    setState(() {
      if (index < _sparePartsControllers.length) {
        // Dispose controllers to prevent memory leaks
        _sparePartsControllers[index]['part']?.dispose();
        _sparePartsControllers[index]['value']?.dispose();
        _sparePartsControllers.removeAt(index);
      }
    });
  }

  Widget _buildSparePartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and Add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Major Maintainance',
              style: TextStyle(
                  color: Color(0xFF6B8E23),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  fontFamily: "Poppins"
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Spare'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _formFieldsEnabled ? const Color(0xFF6B8E23) : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: _formFieldsEnabled ? _addNewSparePart : null,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Display all spare parts fields
        ..._sparePartsControllers.asMap().entries.map((entry) {
          int index = entry.key;
          var controllers = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: [
                // Spare part name field
                Expanded(
                  flex: 3,
                  child: _buildCustomTextField(
                    labelText: 'Major Repair',
                    hintText: 'Enter major repair',
                    controller: controllers['part']!,
                    isRequired: false,
                  ),
                ),
                const SizedBox(width: 10),

                // Spare part value field
                Expanded(
                  flex: 2,
                  child: _buildCustomTextField(
                    labelText: 'Cost(Rs)',
                    hintText: 'Enter value',
                    controller: controllers['value']!,
                    keyboardType: TextInputType.number,
                    isRequired: false,
                  ),
                ),

                // Remove button
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: _formFieldsEnabled ? () => _removeSparePart(index) : null,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _closeAllDropdowns() {
    setState(() {
      showMachineDropdown = false;
      showTractorDropdown = false;
      showCheckboxes = false;

    });
  }

  
Widget _buildMachineSelectionSection() {
  return FormField<Set<String>>(
    initialValue: selectedMachines,
    validator: (value) {
      if (_formFieldsEnabled && (value == null || value.isEmpty)) {
        return 'Please select at least one machine';
      }
      return null;
    },
    builder: (FormFieldState<Set<String>> state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _machineSearchController,
            readOnly: !showMachineDropdown || !_formFieldsEnabled,
            enabled: _formFieldsEnabled,
            onTap: _formFieldsEnabled ? () {
              // Only open dropdown if it's not already open
              if (!showMachineDropdown) {
                _closeAllDropdowns();
                setState(() {
                  showMachineDropdown = true;
                  // Clear search text when opening dropdown
                  _machineSearchController.clear();
                  // Reset filtered list when opening dropdown
                  _filteredMachineNames = _machineName
                      .where((machine) => machine != 'Select Machine')
                      .toList();
                });
              }
            } : null,
            onChanged: _formFieldsEnabled ? (value) {
              setState(() {
                _filteredMachineNames = _machineName
                    .where((machine) =>
                machine != 'Select Machine' &&
                    machine.toLowerCase().contains(value.toLowerCase()))
                    .toList();
              });
            } : null,
            decoration: InputDecoration(
              labelText: 'Machine *',
              errorText: state.errorText,
              labelStyle: TextStyle(
                color: _formFieldsEnabled ? const Color(0xFF6B8E23) : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
                fontFamily: "Poppins",
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 20.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide(
                    color: _formFieldsEnabled ? Colors.grey.shade400 : Colors.grey.shade300,
                    width: 1
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
              ),
              filled: true,
              fillColor: _formFieldsEnabled ? Colors.white : Colors.grey.shade100,
              hintText: selectedMachines.isEmpty ? 'Search or select machine' : selectedMachines.join(', '),
              hintStyle: TextStyle(
                color: selectedMachines.isEmpty ? Colors.grey : Colors.black,
                fontFamily: "Poppins",
                fontSize: 14,

            
              ),
              prefixIcon: showMachineDropdown ?
               const Icon(Icons.search, color: Color(0xFF6B8E23)) : null,
           
              suffixIcon: IconButton(
                onPressed: showMachineDropdown? () {
                  setState(() {
                    // Toggle dropdown when arrow is clicked
                    showMachineDropdown = !showMachineDropdown;

                    if (showMachineDropdown) {
                      // Clear search text when opening dropdown
                      _machineSearchController.clear();
                      // Reset filtered list when opening dropdown
                      _filteredMachineNames = _machineName
                          .where((machine) => machine != 'Select Machine')
                          .toList();
                    } else {
                      // Clear search text when closing dropdown
                      _machineSearchController.clear();
                      // Reset filtered list
                      _filteredMachineNames = _machineName
                          .where((machine) => machine != 'Select Machine')
                          .toList();
                    }
                  });
                } : null,
                icon: Icon(
                  showMachineDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: _formFieldsEnabled ? const Color(0xFF6B8E23) : Colors.grey,
                ),
              ),
            ),
          ),

          if (showMachineDropdown && _formFieldsEnabled)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8.0),
              ),
              margin: const EdgeInsets.only(top: 8.0),
              height: 200,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredMachineNames.length,
                itemBuilder: (context, index) {
                  final machine = _filteredMachineNames[index];
                  return CheckboxListTile(
                    contentPadding: const EdgeInsets.only(left: 4),
                    title: Text(
                      machine,
                      style: const TextStyle(fontFamily: "Poppins"),
                    ),
                    value: selectedMachines.contains(machine),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          selectedMachines.add(machine);
                        } else {
                          selectedMachines.remove(machine);
                        }
                        state.didChange(selectedMachines);
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFF6B8E23),
                  );
                },
              ),
            ),
        ],
      );
    },
  );
}

  Widget _buildTractorSelectionSection() {
    return FormField<Set<String>>(
      initialValue: selectedTractors,
      validator: (value) {
        if (_formFieldsEnabled && (value == null || value.isEmpty)) {
          return 'Please select at least one tractor';
        }
        return null;
      },
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _tractorSearchController,
              readOnly: !showTractorDropdown || !_formFieldsEnabled,
              enabled: _formFieldsEnabled,
              onTap: _formFieldsEnabled ? () {
                _closeAllDropdowns();
                setState(() {
                  showTractorDropdown = true;
                  if (_tractorSearchController.text.isNotEmpty) {
                    _filteredTractorNames = _tractorName
                        .where((tractor) =>
                    tractor != 'Select Tractor' &&
                        tractor.toLowerCase().contains(_tractorSearchController.text.toLowerCase()))
                        .toList();
                  } else {
                    _filteredTractorNames = _tractorName
                        .where((tractor) => tractor != 'Select Tractor')
                        .toList();
                  }
                });
              } : null,
              onChanged: _formFieldsEnabled ? (value) {
                setState(() {
                  _filteredTractorNames = _tractorName
                      .where((tractor) =>
                  tractor != 'Select Tractor' &&
                      tractor.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              } : null,
              decoration: InputDecoration(
                labelText: 'Tractor *',
                errorText: state.errorText,
                labelStyle: TextStyle(
                  color: _formFieldsEnabled ? const Color(0xFF6B8E23) : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  fontFamily: "Poppins",
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 20.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(
                      color: _formFieldsEnabled ? Colors.grey.shade400 : Colors.grey.shade300,
                      width: 1
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
                ),
                filled: true,
                fillColor: _formFieldsEnabled ? Colors.white : Colors.grey.shade100,
                hintText: selectedTractors.isEmpty ? 'Search or select tractor' : selectedTractors.join(', '),
                hintStyle: TextStyle(
                  color: selectedTractors.isEmpty ? Colors.grey : Colors.black,
                  fontFamily: "Poppins",
                  fontSize: 14,
                ),
                prefixIcon: showTractorDropdown ? const Icon(Icons.search, color: Color(0xFF6B8E23)) : null,
                suffixIcon: IconButton(
                  onPressed: showTractorDropdown?() {
                    setState(() {
                      // Toggle dropdown when arrow is clicked
                      showTractorDropdown = !showTractorDropdown;

                      if (showTractorDropdown) {
                        // Clear search text when opening dropdown
                        _tractorSearchController.clear();
                        // Reset filtered list when opening dropdown
                        _filteredTractorNames = _tractorName
                            .where((tractor) => tractor != 'Select Tractor')
                            .toList();
                      } else {
                        // Clear search text when closing dropdown
                        _tractorSearchController.clear();
                      }
                    });
                  } : null,
                  icon: Icon(
                    showTractorDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: _formFieldsEnabled ? const Color(0xFF6B8E23) : Colors.grey,
                  ),
                ),
              ),
            ),

            if (showTractorDropdown && _formFieldsEnabled)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                margin: const EdgeInsets.only(top: 8.0),
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredTractorNames.length,
                  itemBuilder: (context, index) {
                    final tractor = _filteredTractorNames[index];
                    return CheckboxListTile(
                      contentPadding: const EdgeInsets.only(left: 4),
                      title: Text(
                        tractor,
                        style: const TextStyle(fontFamily: "Poppins"),
                      ),
                      value: selectedTractors.contains(tractor),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            selectedTractors.add(tractor);
                          } else {
                            selectedTractors.remove(tractor);
                          }
                          state.didChange(selectedTractors);
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF6B8E23),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _fetchBlocksAndPlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}check-silage-Making'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

             print(responseData);

        if (responseData['success'] == true) {
          final List<dynamic> blocksData = responseData['data'];

          setState(() {
            // Reset arrays
            _blocks = [];
            _blockNames = ['Select Block'];

            // Process blocks data
            for (var block in blocksData) {
              _blocks.add({
                'block_name': block['block_name'],
                'plots': block['plots'],
              });
              _blockNames.add(block['block_name'].toString());
            }

            // Initialize plot dropdown with just the default option
            _plots = [];
            _plotNames = ['Select Plot'];

            // Initialize seed dropdown with just the default option
            _seedName = ['Select Seed Name'];
            _selectedSeedName = 'Select Seed Name';

            // Reset area text
            _areaText = '';
            _selectedArea = null;

            // Initial state is disabled
            _formFieldsEnabled = false;

            _isLoading = false;
          });
        } else {
          throw Exception('API returned false success status');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    } on SocketException {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your internet')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }
  
  
// 2. Update your _updatePlots method to enable seed selection immediately
void _updatePlots(String blockName) {
  // Check if "Select Block" is chosen
  if (blockName == 'Select Block') {
    setState(() {
      // Reset plot dropdown
      _plots = [];
      _plotNames = ['Select Plot'];
      _selectedPlotName = 'Select Plot';

      // Reset seed dropdown
      _seedName = ['Select Seed Name'];
      _selectedSeedName = 'Select Seed Name';

      // Reset area field
      _areaText = '';
      _selectedArea = null;
      _selectedPlotId = null;

      // Disable form fields (but seed will remain enabled due to isAlwaysEnabled logic)
      _formFieldsEnabled = false;
    });
    return;
  }

  // Find selected block
  final selectedBlock = _blocks.firstWhere(
        (block) => block['block_name'] == blockName,
    orElse: () => {},
  );

  if (selectedBlock.isNotEmpty) {
    setState(() {
      _selectedBlockId = _blockNames.indexOf(blockName);

      // Reset subsequent selections
      _selectedPlotName = 'Select Plot';
      _selectedPlotId = null;
      _selectedArea = null;
      _areaText = '';

      // Reset seed dropdown
      _seedName = ['Select Seed Name'];
      _selectedSeedName = 'Select Seed Name';

      // Form fields disabled by default (seed will still be enabled)
      _formFieldsEnabled = false;

      // Update plots for the selected block
      final List<dynamic> plotsData = selectedBlock['plots'];
      _plots = List<Map<String, dynamic>>.from(plotsData.map((plot) => {
        'plot_name': plot['plot_name'],
        'area': plot['area'],
        'is_silage_making': plot['is_silage_making'],
        'seed_name': plot['seed_name'],
        'yield_mt': plot['yield_mt'],
      }));

      // Update plot names dropdown
      _plotNames = ['Select Plot'];
      final uniquePlotNames = <String>{};
      for (var plot in _plots) {
        uniquePlotNames.add(plot['plot_name'].toString());
      }
      _plotNames.addAll(uniquePlotNames);

      // Collect all unique seed names from all plots in this block
      _updateSeedNamesForBlock();

      print('Plots loaded for block $blockName: $_plots');
    });
  }
}


// New method to update seed names for the entire block
  void _updateSeedNamesForBlock() {
    setState(() {
      // Reset seed dropdown with default option
      _seedName = ['Select Seed Name'];

      // Collect all unique seed names from all plots
      final uniqueSeedNames = <String>{};

      for (var plot in _plots) {
        if (plot['seed_name'] != null && 
        plot['seed_name'].toString().isNotEmpty) {
          uniqueSeedNames.add(plot['seed_name'].toString());
        }
      }


      // Add unique seed names to dropdown
      _seedName.addAll(uniqueSeedNames.toList());

      print('Available seed names for silage: ${uniqueSeedNames.toList()}');
    });
  }



// Update area and seed name based on selected plot
  void _updateAreaText(String plotName) {
    // Check if "Select Plot" is chosen
    if (plotName == 'Select Plot') {
      setState(() {
        _areaText = '';
        _selectedArea = null;
        _selectedPlotId = null;

        // Reset seed selection but keep all available seed names
        _selectedSeedName = 'Select Seed Name';

        // Disable form fields
        _formFieldsEnabled = false;
        _resetFormFieldsOnly(); // Reset just the form fields, not the selections
      });
      return;
    }

    // Find plot with matching name and get the first occurrence
    final matchingPlots = _plots.where((plot) => plot['plot_name'] == plotName).toList();

    if (matchingPlots.isNotEmpty) {
      final selectedPlot = matchingPlots.first;

      // Check is_silage_making value to decide whether to enable form fields
      bool enableFields = selectedPlot['is_silage_making'] == 1;

      print('Plot selected: $plotName, is_silage_making: ${selectedPlot['is_silage_making']}, form fields will be: ${enableFields ? 'enabled' : 'disabled'}');

      setState(() {
        _selectedPlotId = _plotNames.indexOf(plotName); // Store plot ID as index
        _selectedArea = double.tryParse(selectedPlot['area'].toString());
        // Set the area text directly
        _areaText = '${selectedPlot['area']} ';

        // Keep all seed names available but reset selection
        _selectedSeedName = 'Select Seed Name';

        // Enable or disable form fields based on is_silage_making value
        _formFieldsEnabled = enableFields;

        // If fields are disabled, reset form fields but keep the plot selection
        if (!_formFieldsEnabled) {
          _resetFormFieldsOnly();
        }
      });

      // Show a message to the user based on the silage_making status
      if (!enableFields) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silage making is not enabled for this plot. Form fields are disabled.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }


void _resetFormFieldsOnly() {
  // Reset all form field values but keep plot and block selections
  _fuelConsumptionController.clear();
  _areaController.clear();
  _yieldController.clear(); // Make sure this line exists
  _HSD_Consuption_Controller.clear();

  selectedTractors.clear();
  selectedMachines.clear();
  _tractorSearchController.clear();
  _machineSearchController.clear();
  showTractorDropdown = false;
  showMachineDropdown = false;

  // Clear spare parts
  for (var controllerMap in _sparePartsControllers) {
    controllerMap['part']?.dispose();
    controllerMap['value']?.dispose();
  }
  _sparePartsControllers.clear();

  _selectedLandQuality = 'Select Land Quality';
  _startDate = null;
  _startTime = null;
  _endTime = null;

  // Clear selected categories and their values
  selectedCategories = {};
  for (var controller in controllers.values) {
    controller.clear();
  }
}



  @override
  void dispose() {
    // Dispose controllers and focus nodes to prevent memory leaksbo
    _fuelConsumptionController.dispose();
    _areaController.dispose();
    _yieldController.dispose();
  /*  _majorMaintenanceController.dispose();*/
    _levelingFocusNode.dispose();
    /*_majorMaintenanceFocusNode.dispose();*/


    _tractorSearchController.dispose();
    _machineSearchController.dispose();

    // Dispose spare parts controllers
    for (var controllerMap in _sparePartsControllers) {
      controllerMap['part']?.dispose();
      controllerMap['value']?.dispose();
    }



    for (var controller in controllers.values) {
      controller.dispose();
    }
    for (var node in focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }


  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    if (!_formFieldsEnabled) return; // Prevent date selection if fields are disabled

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B8E23), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        }
      });
    }
  }

  // Time Picker Method
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    if (!_formFieldsEnabled) return; // Prevent time selection if fields are disabled

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B8E23), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }



Widget _buildCustomTextField({
  required String labelText,
  String? hintText,
  TextInputType? keyboardType,
  TextEditingController? controller, // ✅ Optional now
  FocusNode? focusNode,
  bool isRequired = true,
  String? Function(String?)? customValidator,
  int? maxLength,
  bool enabled = true,
  String? initialText,
}) {
  // ✅ Create or reuse controller
  final textController = controller ?? TextEditingController(
    text: initialText ?? '',
  );

  // ✅ If you pass a controller but don't want prefill, clear it
   if (controller == null && initialText != null) {
    textController.text = initialText;
  }



  return TextFormField(
    onTap: () {
      setState(() {
        _closeAllDropdowns();
      });
    },
    enabled: enabled,
    controller: textController, // ✅ Use safe controller
    focusNode: focusNode,
    keyboardType: keyboardType ?? TextInputType.text,
    maxLength: maxLength,
    maxLengthEnforcement: MaxLengthEnforcement.enforced,
    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
    validator: (value) {
      if (!enabled) return null; // Skip validation if disabled
      if (isRequired && (value == null || value.isEmpty)) {
        return 'Please enter $labelText';
      }
      if (maxLength != null && value != null && value.length > maxLength) {
        return '$labelText cannot exceed $maxLength characters';
      }
      if (customValidator != null) {
        return customValidator(value);
      }
      return null;
    },
    decoration: InputDecoration(
      labelText: labelText + (isRequired ? ' *' : ''),
      labelStyle: TextStyle(
        color: enabled ? const Color(0xFF6B8E23) : Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 14.0,
        fontFamily: "Poppins",
      ),
      hintText: hintText ?? 'Enter $labelText',
      hintStyle: const TextStyle(
        fontFamily: "Poppins",
        fontSize: 14.0,
        color: Colors.grey,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: const BorderSide(width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: BorderSide(
          color: enabled ? Colors.grey.shade400 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: const BorderSide(
          color: Color(0xFF6B8E23),
          width: 2,
        ),
      ),
      filled: true,
      fillColor: enabled ? Colors.white : Colors.grey.shade100,
    ),
  );
}


// 1. Update your _buildCustomDropdown method to handle seed name specially
Widget _buildCustomDropdown({
  required String labelText,
  required String? selectedValue,
  required List<String> items,
  required Function(String?) onChanged,
  bool isRequired = true,
}) {
  // Ensure items list doesn't have duplicates
  final uniqueItems = items.toSet().toList();

  // Check if selectedValue exists in the uniqueItems list
  final bool valueInItems = selectedValue 
  != null && uniqueItems.contains(selectedValue);

  // If the selected value isn't in the items list, use the first item or null
  final String? validatedValue = 
  valueInItems ? selectedValue :
  (uniqueItems.isNotEmpty ? uniqueItems[0] : null);

  // Check if this is Type of Man Power field to make it optional
  final bool isTypeOfManPower = labelText ==
   'Type of Man Power' || labelText ==
    'Type of Man Power ';
  final bool fieldRequired = isTypeOfManPower ? 
  false : isRequired;

  // Always enabled fields: Block Name, Plot Name, Seed Name
  final bool isAlwaysEnabled = labelText == 'Block Name' || 
                              labelText == 'Plot Name' || 
                              labelText == 'Seed Name' ||
                              labelText == 'Seed Name ';

  return DropdownButtonFormField<String>(
    onTap: (){
      setState(() {
        _closeAllDropdowns();
      });
    },

    isDense: true,
    isExpanded: true,
    menuMaxHeight: 300,
    validator: (value) {
      // Make Type of Man Power optional
      if (isTypeOfManPower) {
        return null; // No validation for Type of Man Power
      }

      // For always enabled fields (Block, Plot, Seed), always validate
      if (isAlwaysEnabled && fieldRequired && 
          (value == null || value.startsWith('Select'))) {
        return 'Please select $labelText';
      }

      // For other fields, only validate when form is enabled
      if (_formFieldsEnabled && fieldRequired && 
          (value == null || value.startsWith('Select'))) {
        return 'Please select $labelText';
      }
      return null;
    },
    decoration: InputDecoration(
      // Remove asterisk (*) for Type of Man Power, keep for others
      labelText: labelText + (fieldRequired ? ' *' : ''),
      labelStyle: TextStyle(
          color: (_formFieldsEnabled || isAlwaysEnabled)
              ? const Color(0xFF6B8E23)
              : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14.0,
          fontFamily: "Poppins"
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 20.0
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: BorderSide(
          color: (_formFieldsEnabled || isAlwaysEnabled)
              ? Colors.grey.shade400
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: const BorderSide(
          color: Color(0xFF6B8E23),
          width: 2,
        ),
      ),
      filled: true,
      fillColor: (_formFieldsEnabled || isAlwaysEnabled)
          ? Colors.white
          : Colors.grey.shade100,
      suffixIcon: Icon(
        Icons.keyboard_arrow_down,
        color: (_formFieldsEnabled || isAlwaysEnabled)
            ? const Color(0xFF6B8E23)
            : Colors.grey,
      ),
    ),
    value: validatedValue,
    items: uniqueItems.map((name) {
      return DropdownMenuItem<String>(
        value: name,
        child: Text(
          name,
          style: TextStyle(
            color: name.startsWith('Select') ? Colors.grey : Colors.black,
            fontFamily: "Poppins",
            fontSize: 14.0,
          ),
        ),
      );
    }).toList(),
    onChanged: (_formFieldsEnabled || isAlwaysEnabled) ? onChanged : null,
    icon: const SizedBox.shrink(), // Remove default dropdown icon
    dropdownColor: Colors.white,
    style: const TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontFamily: "Poppins",
    ),
  );
}



  Widget _buildManpowerSection() {
    return FormField<Set<String>>(
      initialValue: selectedCategories,
      validator: null, // No validation required since it's optional
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (!_formFieldsEnabled) return; // Prevent interaction if disabled
                setState(() {
                  showCheckboxes = !showCheckboxes;
                });
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Category of Man Power', // Optional field
                  errorText: state.errorText,
                  labelStyle: TextStyle(
                    color: _formFieldsEnabled ? const Color(0xFF6B8E23) : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                    fontFamily: "Poppins",
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 20.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(
                        color: _formFieldsEnabled ? Colors.grey.shade400 : Colors.grey.shade300,
                        width: 1
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
                  ),
                  filled: true,
                  fillColor: _formFieldsEnabled ? Colors.white : Colors.grey.shade100,
                  suffixIcon: Icon(
                    showCheckboxes ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: _formFieldsEnabled ? const Color(0xFF6B8E23) : Colors.grey,
                  ),
                ),
                child: Text(
                  selectedCategories.isEmpty
                      ? 'Select Category'
                      : selectedCategories.join(', '),
                  style: TextStyle(
                    color: selectedCategories.isEmpty ? Colors.grey : Colors.black,
                    fontFamily: "Poppins",
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            if (showCheckboxes && _formFieldsEnabled)
              Column(
                children: categories.map((category) {
                  return CheckboxListTile(
                    contentPadding: const EdgeInsets.only(left: 4),
                    title: Text(
                      category,
                      style: const TextStyle(fontFamily: "Poppins"),
                    ),
                    value: selectedCategories.contains(category),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          selectedCategories.add(category);
                        } else {
                          selectedCategories.remove(category);
                          // Clear the text field value when category is unselected
                          if (controllers[category] != null) {
                            controllers[category]!.clear();
                          }
                        }
                        state.didChange(selectedCategories);
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFF6B8E23),
                  );
                }).toList(),
              ),

            const SizedBox(height: 10),

            if (selectedCategories.isNotEmpty && _formFieldsEnabled)
              SizedBox(
                height: 90,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: selectedCategories.map((category) {
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildCustomTextField(
                          labelText: category,
                          controller: controllers[category]!,
                          focusNode: focusNodes[category],
                          keyboardType: TextInputType.number,
                          maxLength: 3, // Maximum 3 characters allowed
                          customValidator: (value) {
                            // Validation sirf tab hai jab category selected hai
                            if (selectedCategories.contains(category)) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Numbers only';
                              }
                            }
                            return null;
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  Widget _buildDateTimePicker({
    required String labelText,
    required String hintText,
    required dynamic value,
    required IconData icon,
    required Function() onTap,
    bool isRequired = true,
  }) {
    return GestureDetector(
      onTap: _formFieldsEnabled ? onTap : null,
      child: AbsorbPointer(
        child: TextFormField(
          validator: (val) {
            if (_formFieldsEnabled && isRequired && (value == null || value.toString().isEmpty)) {
              return 'Please select $labelText';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: labelText + (isRequired ? ' *' : ''),
            labelStyle: TextStyle(
              color: _formFieldsEnabled ? const Color(0xFF6B8E23) : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
              fontFamily: "Poppins",
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 14.0,
              fontFamily: "Poppins",
            ),
            filled: true,
            fillColor: _formFieldsEnabled ? Colors.white : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15.0,
              horizontal: 20.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(
                  color: _formFieldsEnabled ? Colors.grey.shade400 : Colors.grey.shade300,
                  width: 1
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
            ),
            suffixIcon: Icon(
                icon,
                color: _formFieldsEnabled ? const Color(0xFF6B8E23) : Colors.grey
            ),
          ),
          controller: TextEditingController(
            text: value?.toString() ?? '',
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14.0,
            fontFamily: "Poppins",
          ),
          readOnly: true,
          enabled: _formFieldsEnabled,
        ),
      ),
    );
  }



  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      try {
        // Get token from SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String token = prefs.getString('auth_token') ?? '';
        int? userId = prefs.getInt('user_id');
        if (token.isEmpty) {
          throw Exception('Authentication token not found');
        }

        if (userId == null) {
          throw Exception('User ID not found');
        }

        // Format date
        String formattedDate = '';
        if (_startDate != null) {
          formattedDate = DateFormat('yyyy-MM-dd').format(_startDate!);
        }

        // Format times
        String startTimeStr = '';
        String endTimeStr = '';

        if (_startTime != null) {
          startTimeStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
        }

        if (_endTime != null) {
          endTimeStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
        }

        // Calculate time in hours between start and end time
        double timeHrs = 0;
        if (_startTime != null && _endTime != null) {
          DateTime startDateTime = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
            _startTime!.hour,
            _startTime!.minute,
          );
          DateTime endDateTime = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
            _endTime!.hour,
            _endTime!.minute,
          );

          // If end time is before start time, assume it's the next day
          if (endDateTime.isBefore(startDateTime)) {
            endDateTime = endDateTime.add(const Duration(days: 1));
          }

          // Calculate hours difference
          timeHrs = endDateTime.difference(startDateTime).inMinutes / 60.0;
        }

        List<String> machineIds = [];
        if (selectedMachines.isNotEmpty) {
          for (String machineName in selectedMachines) {
            int index = _machineName.indexOf(machineName);
            if (index > 0) { // Skip the "Select Machine" option at index 0
              // Convert the index to a string to match the expected format in the request
              machineIds.add(index.toString());
            }
          }
        }

        List<String> tractorIds = [];
        if (selectedTractors.isNotEmpty) {
          for (String tractorName in selectedTractors) {
            int index = _tractorName.indexOf(tractorName);
            if (index > 0) { // Skip the "Select Tractor" option at index 0
              // Convert the index to a string to match the expected format in the request
              tractorIds.add(index.toString());
            }
          }
        }

        List<Map<String, String>> sparePartsData = [];
        for (var controller in _sparePartsControllers) {
          if (controller['part']!.text.isNotEmpty || controller['value']!.text.isNotEmpty) {
            sparePartsData.add({
              'spare_part': controller['part']!.text,
              'value': controller['value']!.text,
            });
          }
        }

        // Define mapping for category display names to API parameter names
        Map<String, String> categoryMapping = {
          "Unskilled": "unskilled",
          "Semi Skilled 1": "semi_skilled_1",
          "Semi Skilled 2": "semi_skilled_2"
        };

        // Collect manpower data
        Map<String, dynamic> manpowerData = {};
        for (String displayCategory in selectedCategories) {
          // Trim whitespace from category to handle potential space issues
          String trimmedCategory = displayCategory.trim();

          if (controllers[trimmedCategory]?.text != null && controllers[trimmedCategory]!.text.isNotEmpty) {
            // Get the server parameter name for this category
            String serverParam = categoryMapping[trimmedCategory] ??
                trimmedCategory.toLowerCase().replaceAll(' ', '_');

            // Add value to manpower data with the correct parameter name
            manpowerData[serverParam] = int.tryParse(controllers[trimmedCategory]!.text) ?? 0;
          }
        }

        // Prepare data for API request
        final Map<String, dynamic> requestData = {
          'block_name': _selectedBlockName,
          'plot_name': _selectedPlotName,
          'area': _selectedArea,

          'machine_ids': machineIds, // Multiple machine IDs
          'tractor_ids': tractorIds, // Multiple tractor IDs
          'spare_parts': sparePartsData, // Spare parts data

          'seed_name': _selectedSeedName == 'Select Seed Name' ? null : _selectedSeedName,
          'silage_making_method': _selectedSilageMaking == 'Select Method' ? null : _selectedSilageMaking,
          'area_covered': _areaController.text,
          'yield_mt': _yieldController.text,
          'hsd_consumption': double.tryParse(_HSD_Consuption_Controller.text) ?? 0.0,
          'start_time': startTimeStr,
          'end_time': endTimeStr,
          'date': formattedDate,
         'category': selectedCategories.toList(), // Convert Set to List
      //    'manpower_type': _selectedManPowerRoll == 'Select ManPower' ? null : _selectedManPowerRoll,
          'user_id': userId, // Now getting user_id from SharedPreferences
        };

        // Add category only if user has selected any categories
        if (selectedCategories.isNotEmpty) {
          requestData['category'] = selectedCategories.toList(); // Convert Set to List
        } else {
          requestData['category'] = null; // Send null if no categories selected
        }

        if (_selectedManPowerRoll != null &&
            _selectedManPowerRoll != 'Select ManPower' &&
            !_selectedManPowerRoll!.startsWith('Select')) {
          requestData['manpower_type'] = _selectedManPowerRoll;
        }

        // Add manpower data directly to the main request data
        requestData.addAll(manpowerData);

        print("Request Data: ${json.encode(requestData)}");
        print("User ID being sent: $userId"); // Debug print
        // Make API call
        final response = await http.post(
          Uri.parse('https://ccbfsolution.pmmsapp.com/api/store-silage-Making'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestData),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Parse response
          final responseData = json.decode(response.body);
          print("API Response: $responseData");

          // Success - show toast message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Details submitted successfully'),
              backgroundColor: Color(0xFF6B8E23),
              duration: Duration(seconds: 3),
            ),
          );

          // Clear form fields
          _resetForm();
        } else {
          // Error handling - Parse error response
          try {
            final errorData = jsonDecode(response.body);
            String errorMessage = '';

            // Check for specific error types
            if (errorData.containsKey('error')) {
              String mainError = errorData['error'] ?? 'Failed to submit data';

              // Check for seed stock error
              if (errorData.containsKey('available_stock') && errorData.containsKey('requested_consumption')) {
                String availableStock = errorData['available_stock'] ?? '0.00';
                String requestedConsumption = errorData['requested_consumption']?.toString() ?? '0';

                errorMessage = '$mainError\nAvailable Stock: $availableStock\nRequested: $requestedConsumption';
              } else {
                errorMessage = mainError;
              }
            } else if (errorData.containsKey('message')) {
              errorMessage = errorData['message'];
            } else {
              errorMessage = 'Failed to submit data';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4), // Increased duration for longer messages
              ),
            );
          } catch (parseError) {
            // If JSON parsing fails, show generic error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to submit data. Status: ${response.statusCode}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Connect to the back button handler
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 148.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF6B8E23),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) =>  const DashboardScreen()),
                    );
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: const Text(
                    'Silage Making',
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
            ];
          },
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B8E23)),
          ))
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Block Name Dropdown
                  _buildCustomDropdown(
                    labelText: 'Block Name',
                    selectedValue: _selectedBlockName,
                    items: _blockNames,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedBlockName = value;
                        });
                        _updatePlots(value);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Plot Name Dropdown
                  _buildCustomDropdown(
                    labelText: 'Plot Name',
                    selectedValue: _selectedPlotName,
                    items: _plotNames,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPlotName = value;
                        });
                        _updateAreaText(value);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Area Text Field (Read-only)
                  TextFormField(
                    controller: TextEditingController(text: _areaText),
                    readOnly: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: "Poppins",
                    ),
                    decoration: InputDecoration(
                      labelText: 'Area (Acre)',
                      hintText: 'Enter a Total Area',
                      labelStyle: const TextStyle(
                          color: Color(0xFF6B8E23),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                          fontFamily: "Poppins"
                      ),
                      hintStyle: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 14.0,
                          color: Colors.grey
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 20.0
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF6B8E23),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (_selectedArea == null) {
                        return 'Please select a plot first';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),


 _buildCustomTextField(
  labelText: 'Area Covered',
  hintText: 'Enter Area',
  controller: _areaController,
  focusNode: _levelingFocusNode,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  maxLength: 5,
  customValidator: (value) {
    if (!_formFieldsEnabled) return null; // Skip validation if disabled
    
    if (value == null || value.isEmpty) {
      return 'Please enter area covered';
    }
    
    // Check if the value is a valid number
    double? enteredArea = double.tryParse(value);
    if (enteredArea == null) {
      return 'Please enter a valid number';
    }
    
    // Check if _selectedArea (total area) has a value to compare against
    if (_selectedArea != null && enteredArea > _selectedArea!) {
      return 'Area covered cannot exceed total area (${_selectedArea!.toStringAsFixed(2)})';
    }
    
    // Check for negative values
    if (enteredArea < 0) {
      return 'Area covered cannot be negative';
    }
    
    return null;
  },
),
                  const SizedBox(height: 20),

               _buildCustomDropdown(
                labelText: 'Seed Name ',
                selectedValue: _selectedSeedName,
                items: _seedName,
                onChanged: (value) {
                if (value != null) {
                _updateFormBasedOnSeed(value); // Call this method when seed is selected
             }
                   },
            ),
            const SizedBox(
              height: 20,
            ),

                     _buildCustomTextField(
                     
                      enabled: false,
                    labelText: 'Total Green Fodder Yield (MT)	',
                    hintText: 'Total Yield ',
                      initialText: yieldMt,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true), // Number keyboard with decimal
                  ),

                  
                  const SizedBox(height: 20),



    _buildCustomTextField(
  isRequired: true,
  enabled: _formFieldsEnabled, // Add this line to make it disable/enable with other fields
  labelText: 'Yield(MT)',
  hintText: 'Enter a Yield',
  controller: _yieldController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  customValidator: (value) {
    if (!_formFieldsEnabled) return null; // Skip validation if disabled
    
    if (value == null || value.isEmpty) {
      return 'Please enter yield value';
    }
    
    // Check if the value is a valid number
    double? enteredYield = double.tryParse(value);
    if (enteredYield == null) {
      return 'Please enter a valid number';
    }
    
    // Check if yieldMt (total yield) has a value to compare against
    if (yieldMt.isNotEmpty) {
      double? totalYield = double.tryParse(yieldMt);
      if (totalYield != null && enteredYield > totalYield) {
        return 'Yield cannot exceed total yield ($yieldMt MT)';
      }
    }
    
    // Check for negative values
    if (enteredYield < 0) {
      return 'Yield cannot be negative';
    }
    
    return null;
  },
),

                  const SizedBox(height: 20),

                  // Date Picker
                  _buildDateTimePicker(
                    labelText: 'Date',
                    hintText: 'dd-mm-yyyy',
                    value: _startDate == null
                        ? null
                        : DateFormat('dd-MM-yyyy').format(_startDate!),
                    icon: Icons.calendar_today,
                    onTap: () => _selectDate(context, true),
                  ),

                  const SizedBox(height: 20),

                  // Method of Silage Making Dropdown
                  _buildCustomDropdown(
                    labelText: 'Method Of Silage Making',
                    selectedValue: _selectedSilageMaking,
                    items: _methodSilageMaking,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSilageMaking = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildMachineSelectionSection(),


                  const SizedBox(height: 20),

                  _buildTractorSelectionSection(),


                  const SizedBox(height: 20),

                  // HSD Consumption TextField
                  _buildCustomTextField(
  enabled: _formFieldsEnabled, // Add this line to make it disable/enable with other fields
  labelText: 'HSD Consumption',
  hintText: 'Enter HSD Consumption',
  controller: _HSD_Consuption_Controller,
  focusNode: _HSD_FocusNode,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  maxLength: 3,
  customValidator: (value) {
    if (!_formFieldsEnabled) return null; // Skip validation if disabled
    
    if (value == null || value.isEmpty) {
      return 'Please enter HSD consumption';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  },
),

                  const SizedBox(height: 20),

                  // Time Pickers Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimePicker(
                          labelText: 'Start Time',
                          hintText: 'Start Time',
                          value: _startTime?.format(context),
                          icon: Icons.access_time,
                          onTap: () => _selectTime(context, true),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildDateTimePicker(
                          labelText: 'End Time',
                          hintText: 'End Time',
                          value: _endTime?.format(context),
                          icon: Icons.access_time,
                          onTap: () => _selectTime(context, false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Type of Man Power Dropdown
                  _buildCustomDropdown(
                    labelText: 'Type of Man Power ',
                    selectedValue: _selectedManPowerRoll,
                    items: _manPowerRoll,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedManPowerRoll = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Man Power Section
                  _buildManpowerSection(),

                  const SizedBox(height: 20),

                

                  _buildSparePartsSection(),


                  const SizedBox(height: 20),

                  // Submit Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: SizedBox(
                      width: 100,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _formFieldsEnabled ? _submitForm : null, // Only enable if _formFieldsEnabled is true
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _formFieldsEnabled ? const Color(0xFF6B8E23) : Colors.grey, // Change color based on enabled state
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedBlockName = 'Select Block';
      _selectedPlotName = 'Select Plot';
      _areaText = '';
      _selectedManPowerRoll = 'Select ManPower';
      _selectedArea = null;
      _selectedBlockId = null;
      _selectedPlotId = null;
      /*_selectedTractor = 'Select Tractor';
      _selectedMachine = 'Select Machine';*/

      selectedTractors.clear();
      selectedMachines.clear();
      _tractorSearchController.clear();
      _machineSearchController.clear();
      showTractorDropdown = false;
      showMachineDropdown = false;

      // Clear spare parts
      for (var controllerMap in _sparePartsControllers) {
        controllerMap['part']?.dispose();
        controllerMap['value']?.dispose();
      }
      _sparePartsControllers.clear();

      // Clear selected categories and their values
      selectedCategories = {};
      for (var controller in controllers.values) {
        controller.clear();
      }

      _selectedSilageMaking = 'Select Method';
      _selectedLandQuality = 'Select Land Quality';
      _fuelConsumptionController.clear();
      _areaController.clear();
      _yieldController.clear();
     /* _majorMaintenanceController.clear();*/
      _HSD_Consuption_Controller.clear();
      _selectedSeedName = 'Select Seed Name';
      _startDate = null;
      _startTime = null;
      _endTime = null;

      // Clear selected categories and their values
      selectedCategories = {};
      for (var controller in controllers.values) {
        controller.clear();
      }

      // Reset dropdowns
      _updatePlots('Select Block');

      // Reset form validation
      _formKey.currentState?.reset();
    });
  }


  Future<void> _fetchMachineDetails() async {
    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}machine-names'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> machineData = responseData['data'];

          setState(() {
            _machineName = ['Select Machine'];
            _machineName.addAll(machineData.map((machine) => machine.toString()).toList());
            _filteredMachineNames = _machineName
                .where((machine) => machine != 'Select Machine')
                .toList();
          });
        } else {
          throw Exception('API returned false success status');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your internet')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }

  Future<void> _fetchTractorDetails() async {
    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String tractorToken = prefs.getString('auth_token') ?? '';

      if (tractorToken.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}tractors-names'),
        headers: {
          'Authorization': 'Bearer $tractorToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> tractorData = responseData['data'];

          setState(() {
            _tractorName = ['Select Tractor'];
            _tractorName.addAll(tractorData.map((tractor) => tractor.toString()).toList());
            _filteredTractorNames = _tractorName
                .where((tractor) => tractor != 'Select Tractor')
                .toList();
          });
        } else {
          throw Exception('API returned false success status');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your internet')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }

  Future<void> fetchCategories() async {
    print('📡 Starting fetchCategories API call...');
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      print('⚠️ Token not found in SharedPreferences');
      return;
    }

    print('✅ Token found: $token');

    try {
      final response = await http.post(
        Uri.parse('${Constanst().base_url}manpower/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('🔁 API call completed with status code: ${response.statusCode}');
      print('📦 Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'];

        // Clear existing data
        categoryMapping.clear();
        displayCategories.clear();

        // Define how API categories map to server parameters
        Map<String, String> apiToServerParam = {
          "Unskilled": "unskilled",
          "Semi Skilled 1": "semi_skilled_1",
          "Semi Skilled 2": "semi_skilled_2"
        };

        // Create mapping between display names and server parameter names
        for (var apiCategory in data) {
          String originalCategory = apiCategory.toString();
          String displayCategory = originalCategory;

          // Map to server parameter name
          String serverParam = apiToServerParam[originalCategory] ??
              originalCategory.toLowerCase().replaceAll(' ', '_');

          // Store the mapping (display name to server parameter)
          categoryMapping[displayCategory] = serverParam;
          displayCategories.add(displayCategory);

          // Initialize controllers and focus nodes with display category as key
          controllers[displayCategory] = TextEditingController();
          focusNodes[displayCategory] = FocusNode();
        }

        setState(() {
          categories = displayCategories.toList();
          isLoading = false;
        });

        print('Categories loaded: $categories');
        print('Category mapping: $categoryMapping');
      } else {
        print('Failed to fetch categories');
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    } on SocketException {
      print('Error fetching categories: SocketException');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your internet')),
      );
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }


void _updateFormBasedOnSeed(String seedName) {
  // Find the specific plot-seed combination
  final selectedEntry = _plots.firstWhere(
    (plot) => plot['plot_name'] == _selectedPlotName && plot['seed_name'] == seedName,
    orElse: () => {},
  );

  if (selectedEntry.isNotEmpty) {
    bool enableFields = selectedEntry['is_silage_making'] == 1;
    yieldMt = selectedEntry['yield_mt']?.toString() ?? '';

    print('Seed selected: $seedName');
    print('is_silage_making: ${selectedEntry['is_silage_making']}');
    print('Form fields will be: ${enableFields ? 'enabled' : 'disabled'}');
    print('total_yield silage: $yieldMt');

    setState(() {
      _selectedSeedName = seedName; // Set the selected seed name
      _formFieldsEnabled = enableFields; // Enable/disable form based on is_silage_making
      
      // REMOVE THIS LINE - Don't auto-fill the yield field
      // _yieldController.text = yieldMt;

      // If fields are disabled, reset form fields
      if (!_formFieldsEnabled) {
        _resetFormFieldsOnly();
        // REMOVE THIS LINE TOO - Don't keep the yield value when disabled
        // _yieldController.text = yieldMt;
      }
    });

    // Show a message to the user based on the silage_making status
    if (!enableFields) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silage making is not enabled for $seedName. Form fields are disabled.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}



}


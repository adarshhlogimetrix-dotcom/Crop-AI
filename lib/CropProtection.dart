import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Constants.dart';
import 'package:flutter/services.dart'; // Add this import for input formatters
import 'dashboard_screen.dart';

class Cropprotection extends StatefulWidget {
  const Cropprotection({super.key});

  @override
  State<Cropprotection> createState() => crop_protection();
}

class crop_protection extends State<Cropprotection> {
  // Form Key
  final _formKey = GlobalKey<FormState>();
  String _areaText = '';

  // Text Controllers
  final TextEditingController _fuelConsumptionController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
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
/*  String? _selectedTractor = 'Select Tractor';
  String? _selectedMachine = 'Select Machine';*/

  String? _selectedApplication = 'Select Method';
  final String? _selectedCompany = 'Select Company';

  final String? _selectedUOM= 'Select UOM';
  String? _selectedStageSource= 'Select Stage Source';
  String? _selectedManPowerRoll = 'Select ManPower';







  final String? _selectedIngredient = 'Select Ingredients';
  List<String> _chemicalNames = ['Select Ingredients'];
  Map<String, int> _chemicalIdMap = {};
  Set<String> selectedIngredients = <String>{};
  List<String> _filteredChemicalNames = [];
  bool showIngredientDropdown = false;
  final TextEditingController _ingredientSearchController = TextEditingController();
  Map<String, Map<String, dynamic>> selectedIngredientData = {};



  final String? _selectedLandQuality = 'Select Land Quality';

//  String? _selectedManPower = 'Select Man Power';

  // ID storage for API communication
  int? _selectedSiteId;
  int? _selectedBlockId;
  int? _selectedPlotId;
  double? _selectedArea;
/*

  // Date and Time Controllers
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
*/


  DateTime? _startDate = DateTime.now();
  TimeOfDay? _startTime = TimeOfDay.now();
  TimeOfDay? _endTime = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(hours: 4))
  );


  // API Data
  final List<Map<String, dynamic>> _sites = [];
  List<Map<String, dynamic>> _blocks = [];
  List<Map<String, dynamic>> _plots = [];

  // Lists for dropdown items
  final List<String> _siteNames = ['Select Site'];
  List<String> _blockNames = ['Select Block'];
  List<String> _plotNames = ['Select Plot'];
  final List<String> _areaOptions = ['Select Area'];
 // List<String> _tractorName = ['Select Tractor'];



//  List<String> _manPowerName = ['Select Man Power'];

  final List<String> _applicationMethodName = [
    'Select Method', 'Spray', 'Drip Irrigation', 'Drenching','Soil Application'
  ];
  final List<String> _CompanyMethodName = [
    'Select Company', 'Bayer', 'Syngenta', 'UPL','BASF'
  ];

  final List<String> _UomName = [
    'Select UOM','ltr', 'kg'
  ];

  final List<String> _StageSourceName = [
    'Select Stage Source',  'Pre-Emergence', 'Post-Emergence', 'Vegetative Stage', 'Flowering Stage'
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



  final String? _selectedTractor = 'Select Tractor';
  Set<String> selectedTractors = {};
  List<String> _tractorName = ['Select Tractor'];
  bool showTractorDropdown = false;
  final TextEditingController _tractorSearchController = TextEditingController();
  List<String> _filteredTractorNames = [];

  final String? _selectedMachine = 'Select Machine';
  Set<String> selectedMachines = {};
  List<String> _machineName = ['Select Machine'];
  bool showMachineDropdown = false;
  final TextEditingController _machineSearchController = TextEditingController();
  List<String> _filteredMachineNames = [];





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
    _fetchBlocksAndPlots();
    _machineName = ['Select Machine'];

    _fetchMachineDetails();
    _fetchTractorDetails();

    _fetchChemicalDetails();
    fetchCategories();
    initializeManpowerCategories();

    // Add listeners to focus nodes
    _levelingFocusNode.addListener(() {
      setState(() {});
    });

  }




  void initializeManpowerCategories() {
    categories = ['Unskilled', 'Semi Skilled 1', 'Semi Skilled 2'];
    // Initialize empty controllers and focus nodes maps
    controllers.clear();
    focusNodes.clear();
  }

 /* Future<void> _fetchBlocksAndPlots() async {
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
        Uri.parse('${Constanst().base_url}site-blocks-plots'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

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

            // Reset area text
            _areaText = '';
            _selectedArea = null;

            _isLoading = false;
          });
        } else {
          throw Exception('API returned false success status');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

// Update plots based on selected block
  void _updatePlots(String blockName) {
    // Check if "Select Block" is chosen
    if (blockName == 'Select Block') {
      setState(() {
        // Reset plot dropdown
        _plots = [];
        _plotNames = ['Select Plot'];
        _selectedPlotName = 'Select Plot';

        // Reset area field
        _areaText = '';
        _selectedArea = null;
        _selectedPlotId = null;
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
        _selectedBlockId = _blockNames.indexOf(blockName); // Store block ID as index

        // Reset subsequent selections
        _selectedPlotName = 'Select Plot';
        _selectedPlotId = null;
        _selectedArea = null;
        _areaText = ''; // Clear area text

        // Update plots for the selected block
        final List<dynamic> plotsData = selectedBlock['plots'];
        _plots = List<Map<String, dynamic>>.from(plotsData.map((plot) => {
          'plot_name': plot['plot_name'],
          'area': plot['area'],
        }));

        // Update plot names dropdown
        _plotNames = ['Select Plot'];
        _plotNames.addAll(_plots.map((plot) => plot['plot_name'].toString()).toList());
      });
    }
  }

// Update area based on selected plot
  void _updateAreaText(String plotName) {
    // Check if "Select Plot" is chosen
    if (plotName == 'Select Plot') {
      setState(() {
        _areaText = '';
        _selectedArea = null;
        _selectedPlotId = null;
      });
      return;
    }

    // Find selected plot
    final selectedPlot = _plots.firstWhere(
          (plot) => plot['plot_name'] == plotName,
      orElse: () => {},
    );

    if (selectedPlot.isNotEmpty) {
      setState(() {
        _selectedPlotId = _plotNames.indexOf(plotName); // Store plot ID as index
        _selectedArea = double.tryParse(selectedPlot['area'].toString());
        // Set the area text directly
        _areaText = '${selectedPlot['area']} ';
      });
    }
  }*/

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
        Uri.parse('${Constanst().base_url}site-blocks-plots'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> blocksData = responseData['data'];

          setState(() {
            // Reset arrays
            _blocks = [];
            _blockNames = ['Select Block'.tr()];

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
            _plotNames = ['Select Plot'.tr()];

            // Reset area text
            _areaText = '';
            _selectedArea = null;

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

// Update plots based on selected block
  void _updatePlots(String blockName) {
    // Check if "Select Block" is chosen
    if (blockName == 'Select Block'.tr()) {
      setState(() {
        // Reset plot dropdown
        _plots = [];
        _plotNames = ['Select Plot'.tr()];
        _selectedPlotName = 'Select Plot'.tr();

        // Reset area field
        _areaText = '';
        _selectedArea = null;
        _selectedPlotId = null;
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
        _selectedBlockId = _blockNames.indexOf(blockName); // Store block ID as index

        // Reset subsequent selections
        _selectedPlotName = 'Select Plot'.tr();
        _selectedPlotId = null;
        _selectedArea = null;
        _areaText = ''; // Clear area text

        // Update plots for the selected block
        final List<dynamic> plotsData = selectedBlock['plots'];
        _plots = List<Map<String, dynamic>>.from(plotsData.map((plot) => {
          'plot_name': plot['plot_name'],
          'area': plot['area'],
        }));

        // Update plot names dropdown
        _plotNames = ['Select Plot'.tr()];
        _plotNames.addAll(_plots.map((plot) => plot['plot_name'.tr()].toString()).toList());
      });
    }
  }

// Update area based on selected plot
  void _updateAreaText(String plotName) {
    // Check if "Select Plot" is chosen
    if (plotName == 'Select Plot'.tr()) {
      setState(() {
        _areaText = '';
        _selectedArea = null;
        _selectedPlotId = null;
      });
      return;
    }

    // Find selected plot
    final selectedPlot = _plots.firstWhere(
          (plot) => plot['plot_name'] == plotName,
      orElse: () => {},
    );

    if (selectedPlot.isNotEmpty) {
      setState(() {
        _selectedPlotId = _plotNames.indexOf(plotName); // Store plot ID as index
        _selectedArea = double.tryParse(selectedPlot['area'].toString());
        // Set the area text directly
        _areaText = '${selectedPlot['area']} ';
      });
    }
  }




  Widget _buildIngredientSelectionSection() {
    return FormField<Set<String>>(
      initialValue: selectedIngredients,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select at least one ingredient';
        }
        // Validate that all selected ingredients have dose, UOM, and company
        for (String ingredient in value) {
          if (selectedIngredientData[ingredient] == null ||
              selectedIngredientData[ingredient]!['dose']?.text?.isEmpty == true ||
              selectedIngredientData[ingredient]!['uom'] == 'Select UOM' ||
              selectedIngredientData[ingredient]!['company'] == 'Select Company') {
            return 'Please fill dose, UOM, and company for all selected ingredients';
          }
        }
        return null;
      },
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ingredient selection dropdown
            TextFormField(
              controller: _ingredientSearchController,
              readOnly: !showIngredientDropdown,
              onTap: () {
                setState(() {
                  showIngredientDropdown = true;
                  if (_ingredientSearchController.text.isNotEmpty) {
                    _filteredChemicalNames = _chemicalNames
                        .where((ingredient) =>
                    ingredient != 'Select Ingredients' &&
                        ingredient.toLowerCase().contains(_ingredientSearchController.text.toLowerCase()))
                        .toList();
                  } else {
                    _filteredChemicalNames = _chemicalNames
                        .where((ingredient) => ingredient != 'Select Ingredients')
                        .toList();
                  }
                });
              },
              onChanged: (value) {
                setState(() {
                  _filteredChemicalNames = _chemicalNames
                      .where((ingredient) =>
                  ingredient != 'Select Ingredients' &&
                      ingredient.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                labelText: 'Active Ingredients *',
                errorText: state.errorText,
                labelStyle: const TextStyle(
                  color: Color(0xFF6B8E23),
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
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: selectedIngredients.isEmpty ? 'Search or select ingredients' : selectedIngredients.join(', '),
                hintStyle: TextStyle(
                  color: selectedIngredients.isEmpty ? Colors.grey : Colors.black,
                  fontFamily: "Poppins",
                  fontSize: 14,
                ),
                prefixIcon: showIngredientDropdown ? const Icon(Icons.search, color: Color(0xFF6B8E23)) : null,
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      showIngredientDropdown = !showIngredientDropdown;
                      if (showIngredientDropdown && _ingredientSearchController.text.isNotEmpty) {
                        _filteredChemicalNames = _chemicalNames
                            .where((ingredient) =>
                        ingredient != 'Select Ingredients' &&
                            ingredient.toLowerCase().contains(_ingredientSearchController.text.toLowerCase()))
                            .toList();
                      } else if (showIngredientDropdown) {
                        _filteredChemicalNames = _chemicalNames
                            .where((ingredient) => ingredient != 'Select Ingredients')
                            .toList();
                      }
                    });
                  },
                  child: Icon(
                    showIngredientDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF6B8E23),
                  ),
                ),
              ),
            ),

            // Dropdown list
            if (showIngredientDropdown)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                margin: const EdgeInsets.only(top: 8.0),
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredChemicalNames.length,
                  itemBuilder: (context, index) {
                    final ingredient = _filteredChemicalNames[index];
                    return CheckboxListTile(
                      contentPadding: const EdgeInsets.only(left: 4),
                      title: Text(
                        ingredient,
                        style: const TextStyle(fontFamily: "Poppins"),
                      ),
                      value: selectedIngredients.contains(ingredient),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            selectedIngredients.add(ingredient);
                            // Initialize data for the selected ingredient
                            selectedIngredientData[ingredient] = {
                              'dose': TextEditingController(),
                              'uom': 'Select UOM',
                              'company': 'Select Company',
                              'id': _chemicalIdMap[ingredient] ?? 0, // Get the ID from the map
                            };
                          } else {
                            selectedIngredients.remove(ingredient);
                            // Clean up data for deselected ingredient
                            selectedIngredientData[ingredient]?['dose']?.dispose();
                            selectedIngredientData.remove(ingredient);
                          }
                          state.didChange(selectedIngredients);
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF6B8E23),
                    );
                  },
                ),
              ),

            // Dynamic dose, UOM, and company fields for selected ingredients
            if (selectedIngredients.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Ingredient Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B8E23),
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 10),
              ...selectedIngredients.map((ingredient) => _buildIngredientDetailCard(ingredient)),
            ],
          ],
        );
      },
    );
  }





  Widget _buildIngredientDetailCard(String ingredient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ingredient,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B8E23),
                fontFamily: "Poppins",
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal Row for Dose, UOM, and Company with equal spacing
            Row(
              children: [
                // Dose field
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: selectedIngredientData[ingredient]!['dose'],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: "Poppins",
                    ),
                    decoration: InputDecoration(
                      labelText: 'Dose *',
                      hintText: 'Enter',
                      labelStyle: const TextStyle(
                          color: Color(0xFF6B8E23),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.0,
                          fontFamily: "Poppins"
                      ),
                      hintStyle: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 10.0,
                          color: Colors.grey
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF6B8E23),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter dose';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // UOM dropdown
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: selectedIngredientData[ingredient]!['uom'],
                    isExpanded: true, // This prevents overflow
                    decoration: InputDecoration(
                      labelText: 'UOM *',
                      labelStyle: const TextStyle(
                          color: Color(0xFF6B8E23),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.0,
                          fontFamily: "Poppins"
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF6B8E23),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _UomName.map((String uom) {
                      return DropdownMenuItem<String>(
                        value: uom,
                        child: Text(
                          uom,
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedIngredientData[ingredient]!['uom'] = newValue!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value == 'Select UOM') {
                        return 'Select UOM';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Company dropdown
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: selectedIngredientData[ingredient]!['company'],
                    isExpanded: true, // This prevents overflow
                    decoration: InputDecoration(
                      labelText: 'Company *',
                      labelStyle: const TextStyle(
                          color: Color(0xFF6B8E23),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.0,
                          fontFamily: "Poppins"
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF6B8E23),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _CompanyMethodName.map((String company) {
                      return DropdownMenuItem<String>(
                        value: company,
                        child: Text(
                          company,
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedIngredientData[ingredient]!['company'] = newValue!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value == 'Select Company') {
                        return 'Select Company';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes to prevent memory leaks
    _fuelConsumptionController.dispose();
    _areaController.dispose();
    _doseController.dispose();
  /*  _majorMaintenanceController.dispose();*/
    _levelingFocusNode.dispose();
/*
    _majorMaintenanceFocusNode.dispose();
*/



    for (var controller in controllers.values) {
      controller.dispose();
    }
    for (var node in focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _closeAllDropdowns() {
    setState(() {
      showMachineDropdown = false;
      showTractorDropdown = false;
      showCheckboxes = false;
      showIngredientDropdown = false;

    });
  }



  Widget _buildMachineSelectionSection() {
    return FormField<Set<String>>(
      initialValue: selectedMachines,
      validator: (value) {
        // Machine selection is now optional - no validation required
        // You can remove this validator completely or keep it for other validations
        return null;
      },
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only one input field that acts as both the selection display and search field
            TextFormField(
              controller: _machineSearchController,
              readOnly: !showMachineDropdown,
              onTap: () {
                _closeAllDropdowns();
                setState(() {
                  showMachineDropdown = true;
                  if (_machineSearchController.text.isNotEmpty) {
                    // Keep the filtered list from previous search
                    _filteredMachineNames = _machineName
                        .where((machine) =>
                    machine != 'Select Machine' &&
                        machine.toLowerCase().contains(_machineSearchController.text.toLowerCase()))
                        .toList();
                  } else {
                    // Reset filtered list when opening dropdown without search text
                    _filteredMachineNames = _machineName
                        .where((machine) => machine != 'Select Machine')
                        .toList();
                  }
                });
              },
              onChanged: (value) {
                setState(() {
                  // Filter machine names based on search input
                  _filteredMachineNames = _machineName
                      .where((machine) =>
                  machine != 'Select Machine' &&
                      machine.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                labelText: 'Machine (Optional)', // Changed label text to indicate it's optional
                errorText: state.errorText,
                labelStyle: const TextStyle(
                  color: Color(0xFF6B8E23),
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
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: selectedMachines.isEmpty ? 'Search or select machine' : selectedMachines.join(', '),
                hintStyle: TextStyle(
                  color: selectedMachines.isEmpty ? Colors.grey : Colors.black,
                  fontFamily: "Poppins",
                  fontSize: 14,
                ),
                prefixIcon: showMachineDropdown ? const Icon(Icons.search, color: Color(0xFF6B8E23)) : null,
                suffixIcon: IconButton(
                  onPressed: showMachineDropdown? () {
                    // _closeAllDropdowns();
                    setState(() {
                      // Toggle dropdown when arrow is clicked
                      showMachineDropdown = !showMachineDropdown;

                      if (showMachineDropdown && _machineSearchController.text.isNotEmpty) {
                        // If dropdown is being opened, keep the filtered list
                        _filteredMachineNames = _machineName
                            .where((machine) =>
                        machine != 'Select Machine' &&
                            machine.toLowerCase().contains(_machineSearchController.text.toLowerCase()))
                            .toList();
                      } else if (showMachineDropdown) {
                        // Reset filtered list when opening dropdown without search
                        _filteredMachineNames = _machineName
                            .where((machine) => machine != 'Select Machine')
                            .toList();
                      } else {
                        // Clear search text when closing dropdown
                        _machineSearchController.clear();
                        // Reset filtered list to all machines
                        _filteredMachineNames = _machineName
                            .where((machine) => machine != 'Select Machine')
                            .toList();
                      }
                    });
                  }:null,
                  icon: Icon(
                    showMachineDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF6B8E23),
                  ),
                ),
              ),
            ),

            if (showMachineDropdown)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                margin: const EdgeInsets.only(top: 8.0),
                height: 200, // Fixed height for the dropdown list
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

        return null; // Always return null to make it optional
      },
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input field - label में भी * हटा दें optional के लिए
            TextFormField(
              controller: _tractorSearchController,
              readOnly: !showTractorDropdown,
              onTap: () {
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
              },
              onChanged: (value) {
                setState(() {
                  _filteredTractorNames = _tractorName
                      .where((tractor) =>
                  tractor != 'Select Tractor' &&
                      tractor.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                labelText: 'Tractor (Optional)', // * हटाया गया और Optional जोड़ा गया
                errorText: state.errorText,
                labelStyle: const TextStyle(
                  color: Color(0xFF6B8E23),
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
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: selectedTractors.isEmpty ? 'Search or select tractor' : selectedTractors.join(', '),
                hintStyle: TextStyle(
                  color: selectedTractors.isEmpty ? Colors.grey : Colors.black,
                  fontFamily: "Poppins",
                  fontSize: 14,
                ),
                prefixIcon: showTractorDropdown ? const Icon(Icons.search, color: Color(0xFF6B8E23)) : null,
                suffixIcon: IconButton(
                  onPressed: showTractorDropdown?() {
                    // _closeAllDropdowns();
                    setState(() {
                      showTractorDropdown = !showTractorDropdown;

                      if (showTractorDropdown && _tractorSearchController.text.isNotEmpty) {
                        _filteredTractorNames = _tractorName
                            .where((tractor) =>
                        tractor != 'Select Tractor' &&
                            tractor.toLowerCase().contains(_tractorSearchController.text.toLowerCase()))
                            .toList();
                      } else if (showTractorDropdown) {
                        _filteredTractorNames = _tractorName
                            .where((tractor) => tractor != 'Select Tractor')
                            .toList();
                      } else {
                        // Clear search text when closing dropdown
                        _tractorSearchController.clear();
                        // Reset filtered list to all tractors
                        _filteredTractorNames = _tractorName
                            .where((tractor) => tractor != 'Select Tractor')
                            .toList();
                      }
                    });
                  }:null,
                  icon: Icon(
                    showTractorDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF6B8E23),
                  ),
                ),
              ),
            ),

            if (showTractorDropdown)
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








  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
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

// Modified _selectTime method with initialTime set to current time or existing selection
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
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
    required TextEditingController controller,
    FocusNode? focusNode,
    bool isRequired = true,
    String? Function(String?)? customValidator,
    int? maxLength, // Add maxLength parameter
  }) {
    return TextFormField(
      onTap: (){
        setState(() {
          _closeAllDropdowns();
        });
      },
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLength: maxLength, // Set max length
      inputFormatters: maxLength != null
          ? [LengthLimitingTextInputFormatter(maxLength)]
          : null, // Add input formatter for length limiting
      validator: customValidator ?? (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter $labelText';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: labelText + (isRequired ? ' ' : ''),
        labelStyle: const TextStyle(
            color: Color(0xFF6B8E23),
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
            fontFamily: "Poppins"
        ),
        hintText: hintText ?? 'Enter $labelText',
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
          borderSide: const BorderSide(width: 1),
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
        counterText: "", // Hide the counter text that shows "0/4"
      ),
    );
  }



  Widget _buildCustomDropdown({
    required String labelText,
    required String? selectedValue,
    required List items,
    required Function(String?) onChanged,
  }) {
    final bool valueExists = selectedValue != null && items.contains(selectedValue);
    final String? safeValue = valueExists ? selectedValue : null;

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
        // Special case: Make Type of Man Power optional
        if (labelText == 'Type of Man Power' || labelText == 'Type of Man Power ') {
          return null; // No validation for Type of Man Power
        }

        if (value == null || value.startsWith('Select')) {
          return 'Please select $labelText'.tr();
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: labelText.tr() + (labelText == 'Type of Man Power' || labelText == 'Type of Man Power ' ? '' : ' *'),
        labelStyle: const TextStyle(
            color: Color(0xFF6B8E23),
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
        suffixIcon: const Icon(
          Icons.keyboard_arrow_down,
          color: Color(0xFF6B8E23),
        ),
      ),
      value: safeValue,
      items: items.map<DropdownMenuItem<String>>((name) {
        return DropdownMenuItem<String>(
          value: name,
          child: Text(
            name,
            style: TextStyle(
              color: name.startsWith('Select'.tr()) ? Colors.grey : Colors.black,
              fontFamily: "Poppins",
              fontSize: 14.0,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      icon: const SizedBox.shrink(), // Remove default dropdown icon
      dropdownColor: Colors.white,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: "Poppins",
      ),
      hint: Text(
        "Select ${labelText.split(' ')[0]}".tr(),
        style: const TextStyle(
          color: Colors.grey,
          fontFamily: "Poppins",
          fontSize: 14.0,
        ),
      ),
    );
  }






  Widget _buildManpowerSection() {
    return FormField<Set<String>>(
      initialValue: selectedCategories,
      validator: null,
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  showCheckboxes = !showCheckboxes;
                });
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Category of Man Power (Optional)',
                  errorText: state.errorText,
                  labelStyle: const TextStyle(
                    color: Color(0xFF6B8E23),
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
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: Icon(
                    showCheckboxes ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF6B8E23),
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

            if (showCheckboxes)
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
                          // Clear the controller value when unchecked
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

            if (selectedCategories.isNotEmpty)
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
                        child: TextFormField(
                          controller: controllers[category]!,
                          focusNode: focusNodes[category],
                          keyboardType: TextInputType.number,
                          maxLength: 3, // Added 3 digit limitation
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                            return null; // Hide the counter
                          },
                          validator: (value) {
                            // If category is selected then value is required
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
                          decoration: InputDecoration(
                            labelText: '$category *',
                            labelStyle: const TextStyle(
                                color: Color(0xFF6B8E23),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                                fontFamily: "Poppins"
                            ),
                            hintText: 'Enter $category',
                            hintStyle: const TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 12.0,
                                color: Colors.grey
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 15.0
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              borderSide: const BorderSide(width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              borderSide: const BorderSide(
                                color: Color(0xFF6B8E23),
                                width: 2,

                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
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
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          validator: (val) {
            if (isRequired && (value == null || value.toString().isEmpty)) {
              return 'Please select $labelText';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: labelText + (isRequired ? '*' : ''),
            labelStyle: const TextStyle(
              color: Color(0xFF6B8E23),
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
            fillColor: Colors.white,
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
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
            ),
            suffixIcon: Icon(icon, color: const Color(0xFF6B8E23)),
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
        ),
      ),
    );
  }


  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String token = prefs.getString('auth_token') ?? '';
        int? userId = prefs.getInt('user_id');
        if (token.isEmpty) {
          throw Exception('Authentication token not found');
        }
        if (userId == null) {
          throw Exception('User ID not found');
        }
        // Format date with null check
        String formattedDate = '';
        if (_startDate != null) {
          formattedDate = DateFormat('yyyy-MM-dd').format(_startDate!);
        }

        // Format times with null checks
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
        if (_startTime != null && _endTime != null && _startDate != null) {
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

          if (endDateTime.isBefore(startDateTime)) {
            endDateTime = endDateTime.add(const Duration(days: 1));
          }

          timeHrs = endDateTime.difference(startDateTime).inMinutes / 60.0;
        }

        // Get chemical IDs from selected ingredients with null checks
        List<Map<String, dynamic>> chemicalIds = [];
        for (String ingredient in selectedIngredients) {
          var ingredientData = selectedIngredientData[ingredient];
          if (ingredientData != null) {
            var doseController = ingredientData['dose'] as TextEditingController?;
            chemicalIds.add({
              'id': ingredientData['id'] ?? 0,
              'dose': double.tryParse(doseController?.text ?? '') ?? 0.0,
              'uom': ingredientData['uom'] == 'Select UOM' ? null : ingredientData['uom'],
              'company': ingredientData['company'] == 'Select Company' ? null : ingredientData['company'],
            });
          }
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
            if (index > 0) {
              tractorIds.add(index.toString());
            }
          }
        }



        // Define category mapping
        Map<String, String> categoryMapping = {
          "Unskilled": "unskilled",
          "Semi Skilled 1": "semi_skilled_1",
          "Semi Skilled 2": "semi_skilled_2"
        };

        // Collect manpower data - ONLY if categories are selected
        Map<String, dynamic> manpowerData = {};
        if (selectedCategories.isNotEmpty) {
          for (String displayCategory in selectedCategories) {
            String trimmedCategory = displayCategory.trim();

            if (controllers[trimmedCategory]?.text != null &&
                controllers[trimmedCategory]!.text.isNotEmpty) {
              String serverParam = categoryMapping[trimmedCategory] ??
                  trimmedCategory.toLowerCase().replaceAll(' ', '_');

              manpowerData[serverParam] = int.tryParse(controllers[trimmedCategory]!.text) ?? 0;
            }
          }
        }

        // Prepare data for API request
        final Map<String, dynamic> requestData = {
          'block_name': _selectedBlockName,
          'plot_name': _selectedPlotName,
          'area': _selectedArea,
          'chemical_ids': chemicalIds,
          'application_method': _selectedApplication == 'Select Method' ? null : _selectedApplication,
          'application_stage_source': _selectedStageSource == 'Select Stage Source' ? null : _selectedStageSource,
          'area_covered': _areaController.text,
          'start_time': startTimeStr,
          'end_time': endTimeStr,
          'date': formattedDate,
  //        'category': selectedCategories.toList(),
        //  'hsd_consumption': double.tryParse(_HSD_Consuption_Controller.text) ?? 0.0,
          'hsd_consumption': _HSD_Consuption_Controller.text.isEmpty ?
          null : (double.tryParse(_HSD_Consuption_Controller.text) ?? 0.0),
        //  'manpower_type': _selectedManPowerRoll == 'Select ManPower' ? null : _selectedManPowerRoll,

          'user_id': userId, // Now getting user_id from SharedPreferences
        };

        if (selectedCategories.isNotEmpty) {
          requestData['category'] = List<String>.from(selectedCategories.map((cat) => cat.trim()));
        }

        if (machineIds.isNotEmpty) {
          requestData['machine_ids'] = machineIds;
        }

        if (tractorIds.isNotEmpty) {
          requestData['tractor_ids'] = tractorIds;
        }

        if (_selectedManPowerRoll != null &&
            _selectedManPowerRoll != 'Select ManPower' &&
            !_selectedManPowerRoll!.startsWith('Select')) {
          requestData['manpower_type'] = _selectedManPowerRoll;
        }

        requestData.addAll(manpowerData);

        print("Request Data: ${json.encode(requestData)}");
        print("User ID being sent: $userId"); // Debug print
        final response = await http.post(
          Uri.parse('https://ccbfsolution.pmmsapp.com/api/crop-protection'),
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
          final responseData = json.decode(response.body);
          print("API Response: $responseData");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Details submitted successfully'),
              backgroundColor: Color(0xFF6B8E23),
              duration: Duration(seconds: 3),
            ),
          );

          _resetForm();
        } else {
          // Error handling - Parse error response
          try {
            final errorData = jsonDecode(response.body);
            String errorMessage = '';

            // Check for specific error types
            if (errorData.containsKey('error')) {
              String mainError = errorData['error'] ?? 'Failed to submit data';

              // Check for chemical stock error
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
                    'Crop Protection',
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

                  // Area Leveling TextField
                  _buildCustomTextField(
                    labelText: 'Area Covered',
                    hintText: 'Enter Area ',
                    controller: _areaController,
                    focusNode: _levelingFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true), // Number keyboard with decimal
                    maxLength: 5, // Limit to 3 digits
                  ),

                  const SizedBox(height: 20),


                  _buildMachineSelectionSection(),

                  const SizedBox(height: 20),


                  _buildTractorSelectionSection(),

                  const SizedBox(height: 20),





                  _buildCustomTextField(
                    labelText: 'HSD Consumption (Optional)',
                    hintText: 'Enter HSD Consumption',
                    controller: _HSD_Consuption_Controller,
                    focusNode: _HSD_FocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    maxLength: 3, // Limit to 3 digits
                    customValidator: (value) {
                      // Only validate if user has entered something
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                      }
                      // Return null means no validation error - field is optional
                      return null;
                    },
                  ),



                  const SizedBox(height: 20),





                  // Machine Dropdown
                  _buildCustomDropdown(
                    labelText: 'Application Method',
                    selectedValue: _selectedApplication,
                    items: _applicationMethodName,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedApplication = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildIngredientSelectionSection(),






                  const SizedBox(height: 20),

                  _buildCustomDropdown(
                    labelText: 'Application Stage Source',
                    selectedValue: _selectedStageSource,
                    items: _StageSourceName,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStageSource = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

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

                  // Submit Button
                 /* Container(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6B8E23),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ),
                  ),*/

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: SizedBox(
                      width: 100,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B8E23),
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
      // Reset dropdown selections
      _selectedBlockName = 'Select Block';
      _selectedPlotName = 'Select Plot';
      _selectedApplication = 'Select Method';
      _selectedStageSource = 'Select Stage Source';
      _selectedManPowerRoll = 'Select ManPower';

      selectedTractors.clear();
      _tractorSearchController.clear();
      showTractorDropdown = false;


      selectedMachines.clear();
      _machineSearchController.clear();
      showMachineDropdown = false;

      _HSD_Consuption_Controller.clear();

      _areaController.clear();

      // Reset date and time
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 4)));

      // Clear ingredient selections and data
      selectedIngredients.clear();
      _ingredientSearchController.clear();
      showIngredientDropdown = false;

      // Dispose all dynamic controllers and clear data - ADD NULL CHECKS
      for (String ingredient in selectedIngredientData.keys) {
        var ingredientData = selectedIngredientData[ingredient];
        if (ingredientData != null && ingredientData['dose'] != null) {
          (ingredientData['dose'] as TextEditingController).dispose();
        }
      }
      selectedIngredientData.clear();

      // Clear manpower selections
      selectedCategories.clear();

      // Dispose and clear manpower controllers - ADD NULL CHECKS
      for (var controller in controllers.values) {
        controller.dispose(); // Add null check
      }
      controllers.clear();

      // Clear focus nodes - ADD NULL CHECKS
      for (var focusNode in focusNodes.values) {
        focusNode.dispose(); // Add null check
      }
      focusNodes.clear();

      // Reset area text
      _areaText = '';
      _selectedArea = null;
    });
  }



/*
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
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading machine data: $e')),
      );
    }
  }
*/

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









/*
  Future<void> _fetchTractorDetails() async {
    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String tractor_token = prefs.getString('auth_token') ?? '';

      if (tractor_token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}tractors-names'),
        headers: {
          'Authorization': 'Bearer $tractor_token',
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
          });
        } else {
          throw Exception('API returned false success status');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tractor data: $e')),
      );
    }
  }
*/

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




/*
  Future<void> _fetchChemicalDetails() async {
    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('https://ccbfsolution.pmmsapp.com/api/crop-chemicals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> chemicalsData = responseData['data'];

          setState(() {
            // Reset collections
            _chemicalNames = ['Select Ingredients'];
            _chemicalIdMap = {};

            // Process each chemical in the response
            for (var chemical in chemicalsData) {
              String chemicalName = chemical['chemical_name'];
              int chemicalId = chemical['id'];

              // Add name to dropdown list
              _chemicalNames.add(chemicalName);

              // Store mapping of name to ID
              _chemicalIdMap[chemicalName] = chemicalId;
            }

            // Initialize filtered list
            _filteredChemicalNames = _chemicalNames
                .where((chemical) => chemical != 'Select Ingredients')
                .toList();
          });
        } else {
          throw Exception('API returned false success status');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chemical data: $e')),
      );
    }
  }
*/




  Future<void> _fetchChemicalDetails() async {
    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('https://ccbfsolution.pmmsapp.com/api/crop-chemicals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> chemicalsData = responseData['data'];

          setState(() {
            // Reset collections
            _chemicalNames = ['Select Ingredients'];
            _chemicalIdMap = {};

            // Process each chemical in the response
            for (var chemical in chemicalsData) {
              String chemicalName = chemical['chemical_name'];
              int chemicalId = chemical['id'];

              // Add name to dropdown list
              _chemicalNames.add(chemicalName);

              // Store mapping of name to ID
              _chemicalIdMap[chemicalName] = chemicalId;
            }

            // Initialize filtered list
            _filteredChemicalNames = _chemicalNames
                .where((chemical) => chemical != 'Select Ingredients')
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




/*
  Future<void> fetchCategories() async {
    print('📡 Starting fetchCategories API call...');
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      print('Token not found in SharedPreferences');
      return;
    }

    print(' Token found: $token');

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
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() => isLoading = false);
    }
  }
*/


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



}

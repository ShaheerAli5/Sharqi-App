import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/storage_service.dart';

class EmployeeRequestFormScreen extends StatefulWidget {
  const EmployeeRequestFormScreen({super.key});

  @override
  State<EmployeeRequestFormScreen> createState() =>
      _EmployeeRequestFormScreenState();
}

class _EmployeeRequestFormScreenState
    extends State<EmployeeRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields State
  String _selectedCompany = '';
  final TextEditingController _employeeNoController =
      TextEditingController();
  final TextEditingController _employeeNameController =
      TextEditingController();
  final TextEditingController _employeeEmailController =
      TextEditingController();
  final TextEditingController _employeePhoneController =
      TextEditingController();

  String _requestDateTime = '';
  late final TextEditingController _dateTimeController;
  String _selectedCategory = 'New/Renew Health Card';
  String _selectedWorkingLocation = 'Doha Main Office';
  final TextEditingController _descriptionController =
      TextEditingController();

  bool _isSubmitting = false;

  List<String> _companies = [];
  List<String> _workingLocations = [];
  List<String> _categories = [
    'New/Renew Health Card',
    'Passport Release',
    'Salary Certificate',
    'NOC Request',
    'Bank Account Update',
    'Other Request',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _requestDateTime =
        '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year} ${_formatTime(now)}';
    _dateTimeController = TextEditingController(text: _requestDateTime);

    final company = StorageService.getValue(StorageService.keyCompanyName);
    if (company.isNotEmpty) {
      _selectedCompany = company;
      _companies = [company];
    }

    final empNo = StorageService.getValue(StorageService.keyEmpNo);
    if (empNo.isNotEmpty) {
      _employeeNoController.text = empNo;
    }
    final fullName = StorageService.getValue(StorageService.keyFullName);
    if (fullName.isNotEmpty) {
      _employeeNameController.text = fullName;
    }
    final phone = StorageService.getValue(StorageService.keyPhone);
    if (phone.isNotEmpty) {
      _employeePhoneController.text = phone;
    }
    final email = StorageService.getValue(StorageService.keyEmail);
    if (email.isNotEmpty) {
      _employeeEmailController.text = email;
    }

    _fetchApiData();
  }

  Future<void> _fetchApiData() async {
    try {
      final compList = await AuthRepository().getCompanyList();
      final locList = await AttendanceRepository().getWorkLocationList();
      final catList =
          await AttendanceRepository().getEmployeeRequestCategories();

      if (mounted) {
        setState(() {
          if (compList.isNotEmpty) {
            _companies = compList.map((c) => c.name).toList();
            final savedCompany =
                StorageService.getValue(StorageService.keyCompanyName);
            if (savedCompany.isNotEmpty && _companies.contains(savedCompany)) {
              _selectedCompany = savedCompany;
            } else if (_companies.isNotEmpty) {
              _selectedCompany = _companies.first;
            }
          }
          if (locList.isNotEmpty) {
            _workingLocations = locList.map((l) => l.name).toList();
            if (_workingLocations.isNotEmpty) {
              _selectedWorkingLocation = _workingLocations.first;
            }
          }
          if (catList.isNotEmpty) {
            _categories = catList;
            if (_categories.isNotEmpty) {
              _selectedCategory = _categories.first;
            }
          }
        });
      }
    } catch (_) {}
  }

  String _formatTime(DateTime dt) {
    final hourOfPeriod = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final hour = hourOfPeriod.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _employeeNoController.dispose();
    _employeeNameController.dispose();
    _employeeEmailController.dispose();
    _employeePhoneController.dispose();
    _dateTimeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSelectionModal({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFBF6F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1310),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: options.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final isSelected = option == currentValue;
                            return ListTile(
                              title: Text(
                                option,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFF1A1310),
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                    )
                                  : null,
                              onTap: () {
                                onSelected(option);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        final month = pickedDate.month.toString().padLeft(2, '0');
        final day = pickedDate.day.toString().padLeft(2, '0');
        final year = pickedDate.year;

        final hourOfPeriod =
            pickedTime.hour % 12 == 0 ? 12 : pickedTime.hour % 12;
        final hour = hourOfPeriod.toString().padLeft(2, '0');
        final minute = pickedTime.minute.toString().padLeft(2, '0');
        final period = pickedTime.hour >= 12 ? 'PM' : 'AM';

        setState(() {
          _requestDateTime = '$month/$day/$year $hour:$minute $period';
          _dateTimeController.text = _requestDateTime;
        });
      }
    }
  }

  Future<void> _onConfirmDetails() async {
    if (_employeeNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Employee Number')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'company': _selectedCompany,
        'employee_number': _employeeNoController.text.trim(),
        'employee_name': _employeeNameController.text.trim(),
        'employee_email': _employeeEmailController.text.trim(),
        'employee_phone': _employeePhoneController.text.trim(),
        'request_datetime': _dateTimeController.text.trim(),
        'category': _selectedCategory,
        'working_location': _selectedWorkingLocation,
        'description': _descriptionController.text.trim(),
      };

      final response =
          await AttendanceRepository().submitEmployeeRequest(payload);

      if (mounted) {
        if (response['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${response['error']}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee request submitted successfully!'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF6F3),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // EMPLOYEE DETAILS Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionPill('EMPLOYEE DETAILS'),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'COMPANY',
                            child: _buildDropdownTile(
                              value: _selectedCompany.isNotEmpty
                                  ? _selectedCompany
                                  : 'Select Company',
                              onTap: () {
                                _showSelectionModal(
                                  title: 'Select Company',
                                  options: _companies,
                                  currentValue: _selectedCompany,
                                  onSelected: (val) {
                                    setState(() {
                                      _selectedCompany = val;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'EMPLOYEE NO.',
                            isRequired: true,
                            child: _buildInputField(
                              controller: _employeeNoController,
                              hintText: 'e.g. 20481',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'EMPLOYEE NAME',
                            child: _buildInputField(
                              controller: _employeeNameController,
                              hintText: 'Auto-filled from profile',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'EMPLOYEE EMAIL',
                            child: _buildInputField(
                              controller: _employeeEmailController,
                              hintText: 'Auto-filled from profile',
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'EMPLOYEE PHONE NO.',
                            child: _buildInputField(
                              controller: _employeePhoneController,
                              hintText: 'Auto-filled from profile',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // REQUEST DETAILS Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionPill('REQUEST DETAILS'),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'REQUEST DATE & TIME',
                            child: GestureDetector(
                              onTap: _selectDateTime,
                              child: AbsorbPointer(
                                child: _buildInputField(
                                  controller: _dateTimeController,
                                  hintText: 'MM/DD/YYYY HH:MM AM/PM',
                                  suffixIcon: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: Color(0xFFC6134B),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'REQUEST CATEGORY',
                            child: _buildDropdownTile(
                              value: _selectedCategory,
                              onTap: () {
                                _showSelectionModal(
                                  title: 'Select Request Category',
                                  options: _categories,
                                  currentValue: _selectedCategory,
                                  onSelected: (val) {
                                    setState(() {
                                      _selectedCategory = val;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'WORKING LOCATION',
                            child: _buildDropdownTile(
                              value: _selectedWorkingLocation,
                              onTap: () {
                                if (_workingLocations.isNotEmpty) {
                                  _showSelectionModal(
                                    title: 'Select Working Location',
                                    options: _workingLocations,
                                    currentValue: _selectedWorkingLocation,
                                    onSelected: (val) {
                                      setState(() {
                                        _selectedWorkingLocation = val;
                                      });
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'DESCRIPTION / COMMENTS',
                            child: TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                color: Color(0xFF1A1310),
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Enter detailed request description...',
                                hintStyle: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Color(0xFFAAAAAA),
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8DFE1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8DFE1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFC6134B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Confirm Details Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _onConfirmDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC6134B),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(26),
                                topRight: Radius.circular(26),
                                bottomRight: Radius.circular(26),
                                bottomLeft: Radius.circular(6),
                              ),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Confirm Details',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionPill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFECE8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B5D58),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildFieldBlock({
    required String label,
    bool isRequired = false,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1310),
                letterSpacing: 0.2,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFC6134B),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildDropdownTile({
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE8DFE1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1310),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFFC6134B),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        color: Color(0xFF1A1310),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: Color(0xFFAAAAAA),
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE8DFE1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE8DFE1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFC6134B),
          ),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.splashGradientStart,
            AppColors.splashGradientMiddle,
            AppColors.splashGradientEnd,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.fromLTRB(6, 1, 6, 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
                child: Center(
                  child: Text(
                    'EMPLOYEE REQUEST FORM',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.68,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/company_models.dart';
import '../../../../data/models/dropdown_item.dart';
import '../../../../data/models/work_location_item.dart';
import '../widgets/request_success_dialog.dart';
import '../widgets/self_service_otp_modal.dart';

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
  CompanyItem? _selectedCompany;
  final TextEditingController _employeeNoController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _employeeEmailController = TextEditingController();
  final TextEditingController _employeePhoneController = TextEditingController();

  String _requestDateTime = '';
  late final TextEditingController _dateTimeController;

  DropdownItem? _selectedCategory;
  WorkLocationItem? _selectedWorkingLocation;
  final TextEditingController _descriptionController = TextEditingController();

  List<CompanyItem> _companies = [];
  bool _isLoadingCompanies = false;
  String? _companyError;

  List<WorkLocationItem> _workingLocations = [];
  bool _isLoadingLocations = false;
  String? _locationError;

  List<DropdownItem> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _requestDateTime =
        '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year} ${_formatTime(now)}';
    _dateTimeController = TextEditingController(text: _requestDateTime);

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
    _fetchCompanies();
    _fetchWorkingLocations();
    _fetchCategories();
  }

  Future<void> _fetchCompanies() async {
    setState(() {
      _isLoadingCompanies = true;
      _companyError = null;
    });

    try {
      final compList = await AuthRepository().getCompanyList();
      if (mounted) {
        setState(() {
          _companies = compList;
          _isLoadingCompanies = false;
          final savedCompanyIdStr = StorageService.getValue(StorageService.keyCompanyId);
          final savedCompanyName = StorageService.getValue(StorageService.keyCompanyName);

          if (_companies.isNotEmpty) {
            final match = _companies.firstWhere(
              (c) =>
                  c.id.toString() == savedCompanyIdStr ||
                  c.name.toLowerCase() == savedCompanyName.toLowerCase(),
              orElse: () => _companies.first,
            );
            _selectedCompany = match;
          } else {
            _selectedCompany = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCompanies = false;
          _companyError = 'Failed to load companies: $e';
        });
      }
    }
  }

  Future<void> _fetchWorkingLocations() async {
    setState(() {
      _isLoadingLocations = true;
      _locationError = null;
    });

    try {
      final locList = await AttendanceRepository().getWorkLocationList();
      if (mounted) {
        setState(() {
          _workingLocations = locList;
          _isLoadingLocations = false;
          if (_workingLocations.isNotEmpty) {
            _selectedWorkingLocation = _workingLocations.first;
          } else {
            _selectedWorkingLocation = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
          _locationError = 'Failed to load work locations: $e';
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final catList =
          await AttendanceRepository().getEmployeeRequestCategories();
      if (mounted) {
        setState(() {
          _categories = catList;
          _isLoadingCategories = false;
          if (_categories.isNotEmpty) {
            _selectedCategory = _categories.first;
          } else {
            _selectedCategory = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _categoryError = 'Failed to load request categories: $e';
        });
      }
    }
  }

  String _formatTime(DateTime dt) {
    final hourOfPeriod = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final hour = hourOfPeriod.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Timer? _employeeLookupTimer;

  void _fetchEmployeeDetailsByNumber(String val) {
    _employeeLookupTimer?.cancel();
    final typedNo = val.trim();
    if (typedNo.isEmpty) return;

    final storedEmpNo = StorageService.getValue(StorageService.keyEmpNo);
    if (typedNo == storedEmpNo) {
      _employeeNameController.text = StorageService.getValue(StorageService.keyFullName);
      _employeeEmailController.text = StorageService.getValue(StorageService.keyEmail);
      _employeePhoneController.text = StorageService.getValue(StorageService.keyPhone);
      return;
    }

    _employeeLookupTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final dashData = await AttendanceRepository().getDashboardData(employeeNumber: typedNo);
        if (mounted) {
          setState(() {
            if (dashData.fullName.isNotEmpty) {
              _employeeNameController.text = dashData.fullName;
            }
            if (dashData.phone.isNotEmpty) {
              _employeePhoneController.text = dashData.phone;
            }
          });
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _employeeLookupTimer?.cancel();
    _employeeNoController.dispose();
    _employeeNameController.dispose();
    _employeeEmailController.dispose();
    _employeePhoneController.dispose();
    _dateTimeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSelectionModal<T>({
    required String title,
    required List<T> options,
    required T? currentValue,
    required String Function(T item) getDisplay,
    required ValueChanged<T> onSelected,
    bool isLoading = false,
    String? errorMessage,
    VoidCallback? onRetry,
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
                  child: isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : errorMessage != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      errorMessage,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        color: Color(0xFFC6134B),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (onRetry != null) ...[
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          onRetry();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                        ),
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          : options.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Text(
                                      'No options available',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        color: Color(0xFF888888),
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                    height: 1,
                                    color: AppColors.divider,
                                  ),
                                  itemBuilder: (context, index) {
                                    final option = options[index];
                                    final displayText = getDisplay(option);
                                    final isSelected = currentValue != null &&
                                        option == currentValue;
                                    return ListTile(
                                      title: Text(
                                        displayText,
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
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Company')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Request Category')),
      );
      return;
    }

    if (_selectedWorkingLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Working Location')),
      );
      return;
    }

    final empNo = _employeeNoController.text.trim();
    if (empNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Employee Number')),
      );
      return;
    }

    final companyId = (_selectedCompany?.id ?? StorageService.getValue(StorageService.keyCompanyId)).toString();
    final phone = _employeePhoneController.text.trim().isNotEmpty
        ? _employeePhoneController.text.trim()
        : StorageService.getValue(StorageService.keyPhone);

    // Open mandatory OTP Verification Modal before processing
    final result = await SelfServiceOtpModal.show(
      context: context,
      employeeNumber: empNo,
      companyId: companyId,
      phoneNumber: phone,
      requestTitle: 'Employee Request',
      onVerifyAndSubmit: () async {
        try {
          final payload = {
            'company': _selectedCompany?.name ?? '',
            'company_id': _selectedCompany?.id ?? companyId,
            'employee_number': empNo,
            'employee_name': _employeeNameController.text.trim(),
            'employee_email': _employeeEmailController.text.trim(),
            'employee_phone': phone,
            'request_datetime': _dateTimeController.text.trim(),
            'category': _selectedCategory?.name ?? '',
            'category_id': _selectedCategory?.id,
            'working_location': _selectedWorkingLocation?.name ?? '',
            'working_location_id': _selectedWorkingLocation?.id,
            'location_id': _selectedWorkingLocation?.id,
            'description': _descriptionController.text.trim(),
            'otp_verified': true,
          };

          return await AttendanceRepository().submitEmployeeRequest(payload);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Submission error: $e')),
            );
          }
          return null;
        }
      },
    );

    if (result != null && mounted) {
      if (result['error'] != null && result['error'].toString().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${result['error']}')),
        );
      } else {
        final refCode = (result['reference'] ??
                result['code'] ??
                result['name'] ??
                result['number'] ??
                '')
            .toString();

        Navigator.pop(context); // Close form screen

        RequestSuccessDialog.show(
          context: context,
          requestType: 'Employee',
          referenceCode: refCode,
          customMessage: result['message']?.toString(),
        );
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
                            isRequired: true,
                            child: _buildDropdownTile(
                              value: _selectedCompany?.name ?? 'Select Company',
                              isLoading: _isLoadingCompanies,
                              onTap: () {
                                _showSelectionModal<CompanyItem>(
                                  title: 'Select Company',
                                  options: _companies,
                                  currentValue: _selectedCompany,
                                  getDisplay: (c) => c.name,
                                  isLoading: _isLoadingCompanies,
                                  errorMessage: _companyError,
                                  onRetry: _fetchCompanies,
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
                              onChanged: _fetchEmployeeDetailsByNumber,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'EMPLOYEE NAME',
                            child: _buildInputField(
                              controller: _employeeNameController,
                              hintText: 'Auto-filled from profile',
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'EMPLOYEE EMAIL',
                            child: _buildInputField(
                              controller: _employeeEmailController,
                              hintText: 'Auto-filled from profile',
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'EMPLOYEE PHONE NO.',
                            child: _buildInputField(
                              controller: _employeePhoneController,
                              hintText: 'Auto-filled from profile',
                              keyboardType: TextInputType.phone,
                              readOnly: true,
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
                            isRequired: true,
                            child: _buildDropdownTile(
                              value: _selectedCategory?.name ?? 'Select Request Category',
                              isLoading: _isLoadingCategories,
                              onTap: () {
                                _showSelectionModal<DropdownItem>(
                                  title: 'Select Request Category',
                                  options: _categories,
                                  currentValue: _selectedCategory,
                                  getDisplay: (c) => c.name,
                                  isLoading: _isLoadingCategories,
                                  errorMessage: _categoryError,
                                  onRetry: _fetchCategories,
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
                            isRequired: true,
                            child: _buildDropdownTile(
                              value: _selectedWorkingLocation?.name ?? 'Select Working Location',
                              isLoading: _isLoadingLocations,
                              onTap: () {
                                _showSelectionModal<WorkLocationItem>(
                                  title: 'Select Working Location',
                                  options: _workingLocations,
                                  currentValue: _selectedWorkingLocation,
                                  getDisplay: (l) => l.name,
                                  isLoading: _isLoadingLocations,
                                  errorMessage: _locationError,
                                  onRetry: _fetchWorkingLocations,
                                  onSelected: (val) {
                                    setState(() {
                                      _selectedWorkingLocation = val;
                                    });
                                  },
                                );
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
                          onPressed: _onConfirmDetails,
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
                          child: const Row(
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
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isLoading ? const Color(0xFFF2ECE8) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE8DFE1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isLoading ? 'Loading options...' : value,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isLoading ? const Color(0xFF888888) : const Color(0xFF1A1310),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
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
    bool readOnly = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        color: readOnly ? const Color(0xFF555555) : const Color(0xFF1A1310),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: Color(0xFFAAAAAA),
          fontSize: 13,
        ),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF2ECE8) : Colors.white,
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
          borderSide: BorderSide(
            color: readOnly ? const Color(0xFFE8DFE1) : const Color(0xFFC6134B),
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

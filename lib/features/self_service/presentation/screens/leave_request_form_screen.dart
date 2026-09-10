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

class LeaveRequestFormScreen extends StatefulWidget {
  const LeaveRequestFormScreen({super.key});

  @override
  State<LeaveRequestFormScreen> createState() => _LeaveRequestFormScreenState();
}

class _LeaveRequestFormScreenState extends State<LeaveRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields State
  CompanyItem? _selectedCompany;
  final TextEditingController _employeeNoController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _employeeEmailController = TextEditingController();
  final TextEditingController _employeePhoneController = TextEditingController();
  final TextEditingController _qidController = TextEditingController();
  final TextEditingController _qidExpiryController = TextEditingController();

  DropdownItem? _selectedLeaveType;
  String? _lastLeaveDate;
  String? _lastReturnDate;
  String? _leaveFromDate;
  String? _leaveToDate;
  String? _lastWorkingDate;
  WorkLocationItem? _selectedDutyManager;
  bool _isDisclaimerAccepted = false;

  List<CompanyItem> _companies = [];
  bool _isLoadingCompanies = false;
  String? _companyError;

  List<WorkLocationItem> _dutyManagers = [];
  bool _isLoadingLocations = false;
  String? _locationError;

  List<DropdownItem> _leaveTypes = [];
  bool _isLoadingLeaveTypes = false;
  String? _leaveTypeError;

  @override
  void initState() {
    super.initState();

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
    final qid = StorageService.getValue(StorageService.keyQid);
    if (qid.isNotEmpty) {
      _qidController.text = qid;
    }
    final qidExpiry = StorageService.getValue(StorageService.keyQidExpiry);
    if (qidExpiry.isNotEmpty) {
      _qidExpiryController.text = qidExpiry;
    }

    _fetchApiData();
  }

  Future<void> _fetchApiData() async {
    _fetchCompanies();
    _fetchDutyManagers();
    _fetchLeaveTypes();
    _fetchDashboardData();
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

  Future<void> _fetchDutyManagers() async {
    setState(() {
      _isLoadingLocations = true;
      _locationError = null;
    });

    try {
      final locList = await AttendanceRepository().getWorkLocationList();
      if (mounted) {
        setState(() {
          _dutyManagers = locList;
          _isLoadingLocations = false;
          if (_dutyManagers.isNotEmpty) {
            _selectedDutyManager = _dutyManagers.first;
          } else {
            _selectedDutyManager = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
          _locationError = 'Failed to load duty managers / locations: $e';
        });
      }
    }
  }

  Future<void> _fetchLeaveTypes() async {
    setState(() {
      _isLoadingLeaveTypes = true;
      _leaveTypeError = null;
    });

    try {
      final leaveTypeList = await AttendanceRepository().getLeaveTypes();
      if (mounted) {
        setState(() {
          _leaveTypes = leaveTypeList;
          _isLoadingLeaveTypes = false;
          if (_leaveTypes.isNotEmpty) {
            _selectedLeaveType = _leaveTypes.first;
          } else {
            _selectedLeaveType = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLeaveTypes = false;
          _leaveTypeError = 'Failed to load leave types: $e';
        });
      }
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final dashData = await AttendanceRepository().getDashboardData();
      if (mounted) {
        setState(() {
          final qidVal = dashData.qidNumber.isNotEmpty
              ? dashData.qidNumber
              : StorageService.getValue(StorageService.keyQid);
          if (qidVal.isNotEmpty) {
            _qidController.text = qidVal;
          }
          final qidExpVal = dashData.qidExpiry.isNotEmpty
              ? dashData.qidExpiry
              : StorageService.getValue(StorageService.keyQidExpiry);
          if (qidExpVal.isNotEmpty) {
            _qidExpiryController.text = qidExpVal;
          }
        });
      }
    } catch (_) {}
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
      _qidController.text = StorageService.getValue(StorageService.keyQid);
      _qidExpiryController.text = StorageService.getValue(StorageService.keyQidExpiry);
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
            if (dashData.qidNumber.isNotEmpty) {
              _qidController.text = dashData.qidNumber;
            }
            if (dashData.qidExpiry.isNotEmpty) {
              _qidExpiryController.text = dashData.qidExpiry;
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
    _qidController.dispose();
    _qidExpiryController.dispose();
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

  Future<void> _selectDate(ValueChanged<String> onDateSelected) async {
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
      final month = pickedDate.month.toString().padLeft(2, '0');
      final day = pickedDate.day.toString().padLeft(2, '0');
      final year = pickedDate.year;
      onDateSelected('$year-$month-$day');
    }
  }

  Future<void> _onConfirmDetails() async {
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Company')),
      );
      return;
    }

    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Leave Type')),
      );
      return;
    }

    if (_selectedDutyManager == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Duty Manager / Location')),
      );
      return;
    }

    if (!_isDisclaimerAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the disclaimer before submitting'),
        ),
      );
      return;
    }

    if (_leaveFromDate == null || _leaveToDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Leave From and To dates')),
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
      requestTitle: 'Leave Request',
      onVerifyAndSubmit: () async {
        try {
          final payload = {
            'company': _selectedCompany?.name ?? '',
            'company_id': _selectedCompany?.id ?? companyId,
            'employee_number': empNo,
            'employee_name': _employeeNameController.text.trim(),
            'employee_email': _employeeEmailController.text.trim(),
            'employee_phone': phone,
            'qid_no': _qidController.text.trim(),
            'qid_expiry': _qidExpiryController.text.trim(),
            'leave_type': _selectedLeaveType?.name ?? '',
            'leave_type_id': _selectedLeaveType?.id,
            'last_leave_date': _lastLeaveDate ?? '',
            'last_return_date': _lastReturnDate ?? '',
            'leave_from_date': _leaveFromDate,
            'leave_to_date': _leaveToDate,
            'last_working_date': _lastWorkingDate ?? '',
            'duty_manager': _selectedDutyManager?.name ?? '',
            'duty_manager_id': _selectedDutyManager?.id,
            'location_id': _selectedDutyManager?.id,
            'disclaimer_confirmed': _isDisclaimerAccepted,
            'otp_verified': true,
          };

          return await AttendanceRepository().submitLeaveRequest(payload);
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
          requestType: 'Leave',
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
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'QID NO.',
                            child: _buildInputField(
                              controller: _qidController,
                              hintText: 'Auto-filled from profile',
                              keyboardType: TextInputType.number,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'QID EXPIRY DATE',
                            child: _buildInputField(
                              controller: _qidExpiryController,
                              hintText: 'Auto-filled from profile',
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // LEAVE DETAILS Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionPill('LEAVE DETAILS'),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'TYPE OF LEAVE',
                            isRequired: true,
                            child: _buildDropdownTile(
                              value: _selectedLeaveType?.name ?? 'Select Type Of Leave',
                              isLoading: _isLoadingLeaveTypes,
                              onTap: () {
                                _showSelectionModal<DropdownItem>(
                                  title: 'Select Type Of Leave',
                                  options: _leaveTypes,
                                  currentValue: _selectedLeaveType,
                                  getDisplay: (l) => l.name,
                                  isLoading: _isLoadingLeaveTypes,
                                  errorMessage: _leaveTypeError,
                                  onRetry: _fetchLeaveTypes,
                                  onSelected: (val) {
                                    setState(() {
                                      _selectedLeaveType = val;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'LAST LEAVE DATE',
                            child: _buildDateFieldTile(
                              value: _lastLeaveDate ?? 'Select Last Leave Date',
                              onTap: () {
                                _selectDate((d) {
                                  setState(() {
                                    _lastLeaveDate = d;
                                  });
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'LAST RETURN DATE',
                            child: _buildDateFieldTile(
                              value: _lastReturnDate ?? 'Select Last Return Date',
                              onTap: () {
                                _selectDate((d) {
                                  setState(() {
                                    _lastReturnDate = d;
                                  });
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'LEAVE FROM DATE',
                            isRequired: true,
                            child: _buildDateFieldTile(
                              value: _leaveFromDate ?? 'Select Leave From Date',
                              onTap: () {
                                _selectDate((d) {
                                  setState(() {
                                    _leaveFromDate = d;
                                  });
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'LEAVE TO DATE',
                            isRequired: true,
                            child: _buildDateFieldTile(
                              value: _leaveToDate ?? 'Select Leave To Date',
                              onTap: () {
                                _selectDate((d) {
                                  setState(() {
                                    _leaveToDate = d;
                                  });
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'LAST WORKING DATE',
                            child: _buildDateFieldTile(
                              value: _lastWorkingDate ?? 'Select Last Working Date',
                              onTap: () {
                                _selectDate((d) {
                                  setState(() {
                                    _lastWorkingDate = d;
                                  });
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'DUTY MANAGER / LOCATION',
                            isRequired: true,
                            child: _buildDropdownTile(
                              value: _selectedDutyManager?.name ?? 'Select Duty Manager / Location',
                              isLoading: _isLoadingLocations,
                              onTap: () {
                                _showSelectionModal<WorkLocationItem>(
                                  title: 'Select Duty Manager / Location',
                                  options: _dutyManagers,
                                  currentValue: _selectedDutyManager,
                                  getDisplay: (d) => d.name,
                                  isLoading: _isLoadingLocations,
                                  errorMessage: _locationError,
                                  onRetry: _fetchDutyManagers,
                                  onSelected: (val) {
                                    setState(() {
                                      _selectedDutyManager = val;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _isDisclaimerAccepted,
                                  activeColor: const Color(0xFFC6134B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _isDisclaimerAccepted = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'I hereby confirm that all information provided above is correct and accurate.',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1310),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildDateFieldTile({
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
              Icons.calendar_today_rounded,
              color: Color(0xFFC6134B),
              size: 18,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    'LEAVE REQUEST FORM',
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

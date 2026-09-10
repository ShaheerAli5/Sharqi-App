import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/company_models.dart';
import '../../../../data/models/dropdown_item.dart';
import '../widgets/request_success_dialog.dart';
import '../widgets/self_service_otp_modal.dart';

class SalarySlipScreen extends StatefulWidget {
  const SalarySlipScreen({super.key});

  @override
  State<SalarySlipScreen> createState() => _SalarySlipScreenState();
}

class _SalarySlipScreenState extends State<SalarySlipScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields State
  CompanyItem? _selectedCompany;
  final TextEditingController _employeeNoController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _employeeEmailController = TextEditingController();
  final TextEditingController _employeePhoneController = TextEditingController();
  final TextEditingController _qidController = TextEditingController();
  final TextEditingController _qidExpiryController = TextEditingController();

  DropdownItem? _selectedMonth;
  bool _isDisclaimerAccepted = false;

  List<CompanyItem> _companies = [];
  bool _isLoadingCompanies = false;
  String? _companyError;

  List<DropdownItem> _months = [];
  bool _isLoadingMonths = false;
  String? _monthError;

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
    _fetchMonths();
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

  Future<void> _fetchMonths() async {
    setState(() {
      _isLoadingMonths = true;
      _monthError = null;
    });

    try {
      // Month options must come from backend API. Since no backend endpoint is documented
      // for salary slip months in API reference, options list remains empty.
      if (mounted) {
        setState(() {
          _months = [];
          _selectedMonth = null;
          _isLoadingMonths = false;
          _monthError = 'Backend API required for salary slip months';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMonths = false;
          _monthError = 'Failed to load months: $e';
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

  Future<void> _onConfirmDetails() async {
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Company')),
      );
      return;
    }

    if (_selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Month')),
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
      requestTitle: 'Salary Slip Request',
      onVerifyAndSubmit: () async {
        try {
          final payload = {
            'company': _selectedCompany?.name ?? '',
            'company_id': _selectedCompany?.id ?? companyId,
            'employee_number': empNo,
            'employee_name': _employeeNameController.text.trim(),
            'employee_email': _employeeEmailController.text.trim(),
            'employee_phone': phone,
            'qid': _qidController.text.trim(),
            'qid_expiry': _qidExpiryController.text.trim(),
            'month': _selectedMonth?.name ?? '',
            'month_id': _selectedMonth?.id,
            'disclaimer_confirmed': _isDisclaimerAccepted,
            'otp_verified': true,
          };

          return await AttendanceRepository().submitSalarySlipRequest(payload);
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
          requestType: 'Salary Slip',
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
                padding: const EdgeInsets.all(20.0),
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
                            label: 'EMPLOYEE PHONE',
                            child: _buildInputField(
                              controller: _employeePhoneController,
                              hintText: 'Auto-filled from profile',
                              keyboardType: TextInputType.phone,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'QID',
                            child: _buildInputField(
                              controller: _qidController,
                              hintText: 'Auto-filled from profile',
                              keyboardType: TextInputType.number,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'QID EXPIRY',
                            child: _buildInputField(
                              controller: _qidExpiryController,
                              hintText: 'Auto-filled from profile',
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldBlock(
                            label: 'MONTH',
                            isRequired: true,
                            child: _buildDropdownTile(
                              value: _selectedMonth?.name ?? 'Select Month',
                              isLoading: _isLoadingMonths,
                              onTap: () {
                                _showSelectionModal<DropdownItem>(
                                  title: 'Select Month',
                                  options: _months,
                                  currentValue: _selectedMonth,
                                  getDisplay: (m) => m.name,
                                  isLoading: _isLoadingMonths,
                                  errorMessage: _monthError,
                                  onRetry: _fetchMonths,
                                  onSelected: (val) {
                                    setState(() {
                                      _selectedMonth = val;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Disclaimer Section
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isDisclaimerAccepted = !_isDisclaimerAccepted;
                              });
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isDisclaimerAccepted
                                          ? const Color(0xFFC6134B)
                                          : const Color(0xFFCCCCCC),
                                      width: 2,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: _isDisclaimerAccepted
                                      ? Center(
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFC6134B),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Disclaimer',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1310),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'I, the undersigned do hereby understand that as per the Qatar Labor Low, any absence immediately after the period of my leave above without legitimate cause for more than seven consecutive days or fifteen days in one year is tantamount to my termination of service as per the Qatar Labor Law of Article 61 section 9. Furthermore, the quarantine period in my home country for two weeks and/or the Qatar Government for another two more weeks, a total of almost 1 month, are included in my leave period above. In addition to this, I understand that upon my arrival in Qatar, I will able to return to work while completing the quarantine period, the reason why it is included in the leave period. Also, I understand and accept that the company shall book for my hotel quarantine in advance, and in case I will not be able to return to Qatar on the specified date above, I am authorizing the company to deduct from my salary the said equivalent amount of hotel quarantine from my end or service or to any other remunerations due me. Most importantly, upon my return to Qatar, I am obliged to complete and sign all the documents herein, otherwise, this signed leave application shall be considered as an authority for the company to directly deduct the said amount from my salary.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF555555),
                              height: 1.45,
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

                      const SizedBox(height: 16),
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
                color: Color(0xFF777777),
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
        height: 46,
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
                    'SALARY SLIP',
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

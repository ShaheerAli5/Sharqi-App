import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

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
  String _selectedCompany = 'Bike Riders';
  final TextEditingController _employeeNoController =
      TextEditingController(text: '20481');
  final TextEditingController _employeeNameController =
      TextEditingController();
  final TextEditingController _employeeEmailController =
      TextEditingController();
  final TextEditingController _employeePhoneController =
      TextEditingController();

  String _requestDateTime = '08/27/2026 11:35 AM';
  late final TextEditingController _dateTimeController;
  String _selectedCategory = 'New/Renew Health Card';
  final TextEditingController _incidentLocationController =
      TextEditingController();
  String _selectedWorkingLocation = 'Abu Sidra';
  final TextEditingController _descriptionController =
      TextEditingController();

  final List<String> _companies = [
    'Bike Riders',
    'Al Sharqi Holding',
    'Mr. VALET Parking',
    'Al Sharqi Logistics',
  ];

  final List<String> _categories = [
    'New/Renew Health Card',
    'Passport Release',
    'Salary Certificate',
    'NOC Request',
    'Bank Account Update',
    'Other Request',
  ];

  final List<String> _workingLocations = [
    'Abu Sidra',
    'Doha Main Office',
    'Rayyan Branch',
    'Wakra Site',
  ];

  @override
  void initState() {
    super.initState();
    _dateTimeController = TextEditingController(text: _requestDateTime);
  }

  @override
  void dispose() {
    _employeeNoController.dispose();
    _employeeNameController.dispose();
    _employeeEmailController.dispose();
    _employeePhoneController.dispose();
    _dateTimeController.dispose();
    _incidentLocationController.dispose();
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
                  child: ListView.separated(
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

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1310),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: Color(0xFF1A1310),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final month = date.month.toString().padLeft(2, '0');
        final day = date.day.toString().padLeft(2, '0');
        final year = date.year;
        final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
        final minute = time.minute.toString().padLeft(2, '0');
        final period = time.period == DayPeriod.am ? 'AM' : 'PM';

        setState(() {
          _requestDateTime = '$month/$day/$year $hour:$minute $period';
          _dateTimeController.text = _requestDateTime;
        });
      }
    }
  }

  void _onConfirmDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Employee request submitted successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.pop(context);
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
          // Header Bar with Burgundy Gradient
          _buildHeader(context),

          // div.body: Main Body Container (Fill 402px, Radius TL24 TR24, Padding 24px, Gap 24px, Color #FBF6F3)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF6F3), // Exact Hex: #FBF6F3
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24), // Exact Radius: 24px
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0), // Exact Padding: 24px
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Frame 40: EMPLOYEE DETAILS Section Frame
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionPill('EMPLOYEE DETAILS'),

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 1. COMPANY Dropdown
                          _buildFieldBlock(
                            label: 'COMPANY',
                            child: _buildDropdownTile(
                              value: _selectedCompany,
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

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 2. EMPLOYEE NO. *
                          _buildFieldBlock(
                            label: 'EMPLOYEE NO.',
                            isRequired: true,
                            child: _buildInputField(
                              controller: _employeeNoController,
                              hintText: 'e.g. 20481',
                              keyboardType: TextInputType.number,
                            ),
                          ),

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 3. EMPLOYEE NAME
                          _buildFieldBlock(
                            label: 'EMPLOYEE NAME',
                            child: _buildInputField(
                              controller: _employeeNameController,
                              hintText: 'Auto-filled from profile',
                            ),
                          ),

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 4. EMPLOYEE EMAIL
                          _buildFieldBlock(
                            label: 'EMPLOYEE EMAIL',
                            child: _buildInputField(
                              controller: _employeeEmailController,
                              hintText: 'Auto-filled from profile',
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 5. EMPLOYEE PHONE
                          _buildFieldBlock(
                            label: 'EMPLOYEE PHONE',
                            child: _buildInputField(
                              controller: _employeePhoneController,
                              hintText: 'e.g. 5012 3456',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24), // Exact Gap: 24px between Top Sections

                      // Frame 41: EMPLOYEE REQUEST DETAILS Section Frame
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionPill('EMPLOYEE REQUEST DETAILS'),

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 6. REQUEST DATETIME *
                          _buildFieldBlock(
                            label: 'REQUEST DATETIME',
                            isRequired: true,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    controller: _dateTimeController,
                                    hintText: '08/27/2026 11:35 AM',
                                    readOnly: true,
                                    onTap: _pickDateTime,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _pickDateTime,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAF7F5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE8DFE1),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_outlined,
                                      color: Color(0xFF1A1310),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 7. EMPLOYEE REQUEST CATEGORY Dropdown
                          _buildFieldBlock(
                            label: 'EMPLOYEE REQUEST CATEGORY',
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

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 8. INCIDENT LOCATION
                          _buildFieldBlock(
                            label: 'INCIDENT LOCATION',
                            child: _buildInputField(
                              controller: _incidentLocationController,
                              hintText: 'Where did this happen?',
                            ),
                          ),

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 9. WORKING LOCATION Dropdown
                          _buildFieldBlock(
                            label: 'WORKING LOCATION',
                            child: _buildDropdownTile(
                              value: _selectedWorkingLocation,
                              onTap: () {
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
                              },
                            ),
                          ),

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 10. ATTACHMENTS Box
                          _buildFieldBlock(
                            label: 'ATTACHMENTS',
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Select files to attach'),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDE8EE), // Soft pink
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC6134B),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.description_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Add Attachments',
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
                            ),
                          ),

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 11. DESCRIPTION
                          _buildFieldBlock(
                            label: 'DESCRIPTION',
                            child: SizedBox(
                              height: 100,
                              child: TextFormField(
                                controller: _descriptionController,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  color: Color(0xFF1A1310),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add any further details here...',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Color(0xFFA0A0A0),
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFFAF7F5),
                                  contentPadding: const EdgeInsets.all(12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8DFE1),
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24), // Exact Gap: 24px

                      // button.btn-primary: Confirm Details Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _onConfirmDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC6134B),
                            elevation: 0,
                            padding: const EdgeInsets.fromLTRB(6, 1, 6, 1),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(26),
                                topRight: Radius.circular(26),
                                bottomRight: Radius.circular(26),
                                bottomLeft: Radius.circular(6),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Confirm Details',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.16,
                                  height: 1.0,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
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
              // Back Button Container
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

              // Title Text: "EMPLOYEE REQUEST FORM"
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

  Widget _buildSectionPill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFECE8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1310),
          letterSpacing: 0.5,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLabel(label, isRequired: isRequired),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5E5855),
              letterSpacing: 0.2,
            ),
          ),
          if (isRequired) ...[
            const TextSpan(
              text: ' *',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC6134B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    String hintText = '',
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 44,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
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
            color: Color(0xFFA0A0A0),
            fontSize: 14,
          ),
          filled: true,
          fillColor: const Color(0xFFFAF7F5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE8DFE1),
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE8DFE1),
            width: 1.0,
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
}

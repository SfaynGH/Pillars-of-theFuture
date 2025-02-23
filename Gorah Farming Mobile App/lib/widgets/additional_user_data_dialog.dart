part of 'widgets.dart';

class AdditionalUserDetailsDialog extends StatefulWidget {
  final String uid;
  final String displayName;
  final String firstName;
  final String lastName;
  final String email;
  final String profileImage;
  final void Function(structs.User) onUserCreated;

  const AdditionalUserDetailsDialog({
    super.key,
    required this.uid,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profileImage,
    required this.onUserCreated,
  });

  @override
  State<AdditionalUserDetailsDialog> createState() => _AdditionalUserDetailsDialogState();
}

class _AdditionalUserDetailsDialogState extends State<AdditionalUserDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String _selectedGender = '';

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    // Pre-fill name if available from displayName
    if (widget.displayName.isNotEmpty) {
      final names = widget.displayName.split(' ');
      if (names.isNotEmpty) _firstNameController.text = names[0];
      if (names.length > 1) _lastNameController.text = names[1];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final newUser = structs.User(
        uid: widget.uid,
        displayName: widget.displayName,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: widget.email,
        phoneNumber: _phoneNumberController.text,
        birthdate: _selectedDate!,
        gender: _selectedGender,
        createdAt: DateTime.now(),
        profileImage: widget.profileImage,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set(newUser.toFirestore());

      widget.onUserCreated(newUser);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Complete Your Profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(_selectedDate == null
                      ? 'Select Birthdate'
                      : 'Birthdate: ${_selectedDate!.toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender.isEmpty ? null : _selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: _genderOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue ?? '';
                    });
                  },
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Complete Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
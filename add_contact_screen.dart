import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/core/widgets/custom_button.dart';
import 'package:integrated_accounting_system/core/widgets/custom_text_field.dart';
import 'package:integrated_accounting_system/domain/entities/contact.dart';
import 'package:integrated_accounting_system/presentation/providers/contacts_provider.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  final Contact? contact;

  const AddContactScreen({super.key, this.contact});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  ContactType _selectedType = ContactType.customer;
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _loadContactData();
    }
  }

  void _loadContactData() {
    final contact = widget.contact!;
    _selectedType = contact.type;
    _nameController.text = contact.name;
    _phoneController.text = contact.phone ?? '';
    _whatsappController.text = contact.whatsapp ?? '';
    _emailController.text = contact.email ?? '';
    _addressController.text = contact.address ?? '';
    _notesController.text = contact.notes ?? '';
    _imagePath = contact.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.contact != null;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل جهة اتصال' : 'إضافة جهة اتصال'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteContact,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة الملف الشخصي
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _imagePath != null
                          ? FileImage(File(_imagePath!))
                          : null,
                      child: _imagePath == null
                          ? Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0]
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _pickImage,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // نوع جهة الاتصال
              const Text(
                'نوع جهة الاتصال',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeCard(
                      'عميل',
                      ContactType.customer,
                      Icons.person,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeCard(
                      'مورد',
                      ContactType.supplier,
                      Icons.business,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // حقل الاسم
              CustomTextField(
                label: 'الاسم',
                hint: 'أدخل الاسم الكامل',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الاسم مطلوب';
                  }
                  if (value.trim().length < 2) {
                    return 'الاسم يجب أن يكون حرفين على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل رقم الهاتف
              CustomTextField(
                label: 'رقم الهاتف',
                hint: '05XXXXXXXX',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[0-9\-\+\s]{8,15}$').hasMatch(value)) {
                      return 'رقم الهاتف غير صحيح';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل واتساب
              CustomTextField(
                label: 'رقم واتساب',
                hint: '05XXXXXXXX',
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.whatsapp),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[0-9\-\+\s]{8,15}$').hasMatch(value)) {
                      return 'رقم واتساب غير صحيح';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل البريد الإلكتروني
              CustomTextField(
                label: 'البريد الإلكتروني',
                hint: 'example@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'البريد الإلكتروني غير صحيح';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل العنوان
              CustomTextField(
                label: 'العنوان',
                hint: 'أدخل العنوان',
                controller: _addressController,
                prefixIcon: const Icon(Icons.location_on),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // حقل الملاحظات
              CustomTextField(
                label: 'ملاحظات',
                hint: 'أدخل ملاحظات إضافية',
                controller: _notesController,
                prefixIcon: const Icon(Icons.note),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // زر الحفظ
              CustomButton(
                text: isEdit ? 'تحديث البيانات' : 'حفظ جهة الاتصال',
                onPressed: _saveContact,
                isLoading: _isLoading,
                icon: isEdit ? Icons.save : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(String label, ContactType type, IconData icon) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveContact() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
        final whatsapp = _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim();
        final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
        final address = _addressController.text.trim().isEmpty ? null : _addressController.text.trim();
        final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

        bool success;

        if (widget.contact != null) {
          // تحديث جهة اتصال موجودة
          final updatedContact = widget.contact!.copyWith(
            type: _selectedType,
            name: name,
            phone: phone,
            whatsapp: whatsapp,
            email: email,
            address: address,
            imagePath: _imagePath,
            notes: notes,
          );
          success = await ref.read(contactsProvider.notifier)
              .updateContact(updatedContact);
        } else {
          // إضافة جهة اتصال جديدة
          success = await ref.read(contactsProvider.notifier).createContact(
            type: _selectedType,
            name: name,
            phone: phone,
            whatsapp: whatsapp,
            email: email,
            address: address,
            imagePath: _imagePath,
            notes: notes,
          );
        }

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.contact != null
                    ? 'تم تحديث جهة الاتصال بنجاح'
                    : 'تم إضافة جهة الاتصال بنجاح',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _deleteContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف جهة اتصال'),
        content: Text('هل أنت متأكد من حذف "${widget.contact!.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(contactsProvider.notifier)
                  .deleteContact(widget.contact!.id);
              if (success && mounted) {
                Navigator.pop(context, true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
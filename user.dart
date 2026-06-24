class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? imagePath;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.imagePath,
    required this.createdAt,
  });

  // نسخ الكائن مع تغييرات
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // التحقق من تساوي كائنين
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // تمثيل الكائن كنص
  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email)';
  }
}
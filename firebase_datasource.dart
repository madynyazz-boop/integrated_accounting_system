import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseDataSource {
  // Firebase instances
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // المستخدم الحالي
  User? get currentUser => auth.currentUser;

  // تسجيل الدخول
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // إنشاء حساب جديد
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await auth.signOut();
  }

  // إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  // تحديث الملف الشخصي
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    await currentUser?.updateDisplayName(displayName);
    await currentUser?.updatePhotoURL(photoURL);
    await currentUser?.reload();
  }

  // حفظ بيانات المستخدم في Firestore
  Future<void> saveUserData(Map<String, dynamic> data) async {
    if (currentUser == null) return;
    await firestore.collection('users').doc(currentUser!.uid).set(data);
  }

  // جلب بيانات المستخدم من Firestore
  Future<DocumentSnapshot> getUserData() async {
    if (currentUser == null) throw Exception('No user logged in');
    return await firestore.collection('users').doc(currentUser!.uid).get();
  }

  // جلب جميع المعاملات
  Future<QuerySnapshot> getTransactions({String? userId}) async {
    String path = 'transactions';
    if (userId != null) {
      path = 'users/$userId/transactions';
    }
    return await firestore.collection(path).orderBy('date', descending: true).get();
  }

  // إضافة معاملة جديدة
  Future<void> addTransaction(Map<String, dynamic> data, {String? userId}) async {
    String path = 'transactions';
    if (userId != null) {
      path = 'users/$userId/transactions';
    }
    await firestore.collection(path).add(data);
  }

  // تحديث معاملة
  Future<void> updateTransaction(String id, Map<String, dynamic> data, {String? userId}) async {
    String path = 'transactions';
    if (userId != null) {
      path = 'users/$userId/transactions';
    }
    await firestore.collection(path).doc(id).update(data);
  }

  // حذف معاملة
  Future<void> deleteTransaction(String id, {String? userId}) async {
    String path = 'transactions';
    if (userId != null) {
      path = 'users/$userId/transactions';
    }
    await firestore.collection(path).doc(id).delete();
  }

  // رفع ملف إلى Firebase Storage
  Future<String> uploadFile(String path, String fileName, dynamic file) async {
    final ref = storage.ref().child('$path/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // حذف ملف من Firebase Storage
  Future<void> deleteFile(String path, String fileName) async {
    final ref = storage.ref().child('$path/$fileName');
    await ref.delete();
  }

  // مراقبة التغييرات في الوقت الحقيقي
  Stream<QuerySnapshot> listenToTransactions({String? userId}) {
    String path = 'transactions';
    if (userId != null) {
      path = 'users/$userId/transactions';
    }
    return firestore.collection(path).orderBy('date', descending: true).snapshots();
  }

  // التحقق من البريد الإلكتروني
  Future<void> verifyEmail() async {
    await currentUser?.sendEmailVerification();
  }

  // تحديث كلمة المرور
  Future<void> updatePassword(String newPassword) async {
    await currentUser?.updatePassword(newPassword);
  }
}
// import 'dart:async';
// import 'dart:convert' show json;
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:http/http.dart' as http;
// import 'package:supabase_flutter/supabase_flutter.dart' as su
//
//
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();
//   final su.SupabaseClient _supabase = su.Supabase.instance.client;
//
//   Future<User?> signInWithGoogle() async {
//     try {
//       // ► 1. Utilisation de l'instance existante
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) return null;
//
//       final GoogleSignInAuthentication googleAuth =
//       await googleUser.authentication;
//
//       // ► 2. Utilisation cohérente de l'instance Firebase
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       final UserCredential userCredential =
//       await _auth.signInWithCredential(credential);
//
//       if (userCredential.user != null) {
//         await _createUserInSupabase(userCredential.user!);
//       }
//
//       return userCredential.user;
//     } catch (e, s) {
//       print("Erreur Google SignIn: $e\n$s");
//       return null;
//     }
//   }
//
//   Future<void> signOut() async {
//     await _googleSignIn.signOut();
//     await _auth.signOut();
//   }
//
//   Future<bool> deleteUserAccountPermanently() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return false;
//
//       // ► 3. RÉAUTHENTIFICATION REQUISE (Firebase)
//       await user.reauthenticateWithCredential(GoogleAuthProvider.credential(
//         accessToken:
//         (await _googleSignIn.signInSilently())!.authentication.accessToken,
//         idToken: (await _googleSignIn.signInSilently())!.authentication.idToken,
//       ));
//
//       // ► 4. Suppression des dépendances dans Supabase (version optimisée)
//       await _supabase
//           .from('signalements')
//           .delete()
//           .match({'user_id': user.uid});
//       await _supabase.from('users').delete().match({'firebase_id': user.uid});
//
//       // ► 5. Suppression du compte Firebase
//       await user.delete();
//       await signOut();
//
//       return true;
//     } catch (e) {
//       print('Erreur suppression compte: $e');
//       return false;
//     }
//   }
//
//   Future<void> _createUserInSupabase(User firebaseUser) async {
//     // ► 6. Vérification optimisée avec .count()
//     final userExists = await _supabase
//         .from('users')
//         .select('*', const su.FetchOptions(count: su.CountOption.exact))
//         .eq('firebase_id', firebaseUser.uid);
//
//     if (userExists.count != null && userExists.count! > 0) return;
//
//     // ► 7. Insertion avec gestion d'erreur améliorée
//     final response = await _supabase.from('users').upsert({
//       'firebase_id': firebaseUser.uid,
//       'email': firebaseUser.email,
//       'full_name': firebaseUser.displayName,
//       'phone': firebaseUser.phoneNumber,
//       'created_at': DateTime.now().toIso8601String(),
//       'photo_url': firebaseUser.photoURL, // ► Stockage direct
//     });
//
//     if (response.error != null) {
//       throw Exception('Erreur Supabase: ${response.error!.message}');
//     }
//   }
// }
//
// class googleSignInProvider extends ChangeNotifier {
//   final googleSignIn = GoogleSignIn();
//
//   GoogleSignInAccount? _user;
//
//   GoogleSignInAccount get user => _user!;
//
//   @override
//   void dispose() {
//     googleLogin();
//     super.dispose();
//   }
//
//   Future googleLogin() async {
//     try {
//       final googleUser = await googleSignIn.signIn();
//       if (googleUser == null) return;
//       _user = googleUser;
//       final googleAuth = await googleUser.authentication;
//
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//       print(credential);
//       final userGoo =
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       print(userGoo);
//       checkIfDocExists(userGoo.user!.uid);
//       notifyListeners();
//     } catch (e) {
//       print(e.toString());
//     }
//   }
//   // Future googleLogin() async {
//   //   try {
//   //     final googleUser = await googleSignIn.signIn();
//   //     if (googleUser == null) return;
//   //     _user = googleUser;
//   //     final googleAuth = await googleUser.authentication;
//   //
//   //     final credential = GoogleAuthProvider.credential(
//   //       accessToken: googleAuth.accessToken,
//   //       idToken: googleAuth.idToken,
//   //     );
//   //     print(credential);
//   //
//   //     final userGoo =
//   //         await FirebaseAuth.instance.signInWithCredential(credential);
//   //     // final userGoo = FirebaseAuth.instance.currentUser;
//   //
//   //     checkIfDocExists(userGoo.user!.uid);
//   //     notifyListeners();
//   //   } catch (e) {
//   //     print(e.toString());
//   //   }
//   // }
//
//   // Future logouta() async {
//   //   await googleSignIn.disconnect();
//   //   await FirebaseAuth.instance.signOut();
//   // }
//   Future logouta() async {
//     await googleSignIn.disconnect();
//     await FirebaseAuth.instance.signOut();
//     _user = null;
//     notifyListeners();
//   }
// }
//
// Future<bool> checkIfDocExists(String uid) async {
//   try {
//     final userGoo = FirebaseAuth.instance.currentUser;
//     var collectionRef = FirebaseFirestore.instance.collection('Users');
//     var doc = await collectionRef.doc(uid).get();
//     print(doc.exists);
//     doc.exists ? updateUserDoc(userGoo!) : setUserDoc(userGoo!);
//     return doc.exists;
//   } catch (e) {
//     throw e;
//   }
// }
//
// Future setUserDoc(User userGoo) async {
//   CollectionReference userRef = FirebaseFirestore.instance.collection('Users');
//
//   String userID = userGoo.uid;
//   String? userEmail = userGoo.email;
//   String? userAvatar = userGoo.photoURL;
//   String? userDisplayName = userGoo.displayName;
//   //String? userPhone = userGoo.phoneNumber;
//   //int? phone = int.parse(userPhone!);
//   String? userRole = 'public';
//   bool userState = true;
//
//   userRef.doc(userGoo.uid).set({
//     'lastActive': Timestamp.now(),
//     'id': userID,
//     'phone': 0, // attention hna
//     'email': userEmail,
//     'avatar': userAvatar,
//     'timeline': userAvatar,
//     'createdAt': Timestamp.now(),
//     'displayName': userDisplayName,
//     'state': userState,
//     'role': userRole,
//     'plan': 'free',
//     'coins': 0.0,
//     'levelUser': 'begin',
//     'stars': 0.0,
//     'userItemsNbr': 0,
//   }, SetOptions(merge: true));
// }
//
// Future updateUserDoc(User userGoo) async {
//   CollectionReference userRef = FirebaseFirestore.instance.collection('Users');
//
//   userRef.doc(userGoo.uid).update(
//     {
//       'lastActive': Timestamp.now(),
//     },
//   );
// }
//

import 'package:flutter/material.dart';

// 🔑 Global Navigator Key (Pass this to your GoRouter config!)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// 💾 Preference Keys
const String kPrefHidePermissionDialog = 'hide_permission_dialog';
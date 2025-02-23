import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../controllers/user_controller.dart';
import '../screens/requests_pages/request_details.dart';
import 'package:gora_farming/structures/structs.dart' as structs;

import '../structures/structs.dart';
part 'additional_user_data_dialog.dart';
part 'welcome_message.dart';
part 'loading_screen.dart';
part 'snack_bar.dart';
part 'typing_indicator.dart';
part 'request_card.dart';
part 'comment/comment_list.dart';


Widget settingScreenItem(
    BuildContext context, {
      IconData? icon,
      String? imagePath,
      required String itemName,
      required page,
    }) {
  final theme = Theme.of(context);

  return ListTile(
    leading: SizedBox(
      width: 24,
      height: 24,
      child: icon != null
          ? Center(child: Icon(icon, color: theme.primaryColor, size: 22))
          : imagePath != null
          ? Center(child: Image.asset(imagePath, width: 20, height: 20))
          : null,
    ),
    title: Text(itemName, style: theme.textTheme.titleSmall),
    onTap: () {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => page)
      );
    },
  );
}


Widget buildTextField(
    BuildContext context, TextEditingController controller, String label,
    {bool obscureText = false, String? Function(String?)? validator}) {
  final theme = Theme.of(context);
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      fillColor: theme.inputDecorationTheme.fillColor,
      filled: true,
    ),
    style: theme.textTheme.titleSmall,
    obscureText: obscureText,
    validator: validator ??
            (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label";
          }
          return null;
        },
  );
}

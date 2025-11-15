import 'package:flutter/cupertino.dart';

class RoleBasedWidget extends StatelessWidget {
  final Widget child;
  final bool isVisible;

  const RoleBasedWidget({super.key, required this.child, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,
      child: child,
    );
  }
}
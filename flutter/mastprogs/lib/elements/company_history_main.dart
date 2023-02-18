import 'package:flutter/material.dart';

class CompanyBigCard extends StatelessWidget {
  final List<Widget> children;

  const CompanyBigCard({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1000,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          width: 1,
          color: Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            offset: const Offset(2, 2),
            blurRadius: 2.0,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 2.0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          for (Widget w in children) w,
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CommonEmptyView extends StatelessWidget {

  final String? text;

  const CommonEmptyView({Key? key, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child:
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 240),
            child: Image.asset(
              "assets/content_failed.png",
              package: "module_library",
              fit: BoxFit.contain,
            )
        ),
        const SizedBox(height: 18,),
        Text(text ?? ""),
      ],
    )
    );
  }

}
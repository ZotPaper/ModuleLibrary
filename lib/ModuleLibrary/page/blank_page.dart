import 'package:flutter/cupertino.dart';

class BlankPage extends StatefulWidget {
  const BlankPage({super.key});

  @override
  State<BlankPage> createState() => _BlankPageState();
}

class _BlankPageState extends State<BlankPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(child:
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 300),
              child: Image.asset(
                "assets/intro_zotpaper.webp",
                package: "module_library",
                fit: BoxFit.contain,
              )
          ),
          const SizedBox(height: 60,),
          const Text('暂无数据'),
        ],
      )
    );
  }
}

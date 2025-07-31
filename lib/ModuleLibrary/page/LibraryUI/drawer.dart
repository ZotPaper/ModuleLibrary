import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:module_library/LibZoteroStorage/entity/Collection.dart';

import '../../../routers.dart';
import '../../res/ResColor.dart';

typedef DrawerItemTapCallback = void Function(DrawerBtn DrawerBtn);

class CustomDrawer extends StatefulWidget {
  final DrawerItemTapCallback onItemTap;
  final List<Collection> collections;
  final Function onCollectionTap;

  const CustomDrawer({
    super.key,
    required this.onItemTap,
    required this.collections,
    required this.onCollectionTap,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

enum DrawerBtn { home, favourites, library, unfiled, publications, trash }

class _CustomDrawerState extends State<CustomDrawer>
    with TickerProviderStateMixin {
  String _selectDrawerTitle = '';
  bool _isCollectionsExpanded = true;
  late AnimationController _animationController;
  late AnimationController _headerAnimationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // 启动动画
    Future.delayed(const Duration(milliseconds: 100), () {
      _headerAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Widget pageDrawer(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildUserHeader(),
              Expanded(
                child: FadeTransition(
                  opacity: _animationController,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      const SizedBox(height: 8),
                      _buildSectionHeader('导航'),
                      ...firstGroup(),
                      const SizedBox(height: 16),
                      _buildCollectionsSection(),
                      const SizedBox(height: 16),
                      _buildSectionHeader('其他'),
                      ...thirdGroup(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeInOut,
      )),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ResColor.selectedTextColor,
              ResColor.selectedTextColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ResColor.selectedTextColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _jumpToAccountSetting,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    "assets/ic_round.png",
                    package: 'module_library',
                    width: 44,
                    height: 44,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ZotPaper",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "点击查看账户设置",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GestureDetector(
                  onTap: _jumpToSettings,
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCollectionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () {
              setState(() {
                _isCollectionsExpanded = !_isCollectionsExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    color: ResColor.selectedTextColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '我的集合 (${widget.collections.length})',
                      style: TextStyle(
                        color: ResColor.textMain,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isCollectionsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isCollectionsExpanded
                ? (widget.collections.length * 48.0).clamp(0, 240)
                : 0,
            child: _isCollectionsExpanded
                ? ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    physics: const ClampingScrollPhysics(),
                    itemCount: widget.collections.length,
                    itemBuilder: (context, index) {
                      final collection = widget.collections[index];
                      return _buildCollectionItem(collection, index);
                    },
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionItem(Collection collection, int index) {
    final isSelected = _selectDrawerTitle == collection.name;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 100 + (index * 50)),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? ResColor.selectedBgColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: ResColor.selectedTextColor.withOpacity(0.3))
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectDrawerTitle = collection.name;
          });
          widget.onCollectionTap(collection);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ResColor.selectedTextColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.folder,
                  size: 16,
                  color: isSelected
                      ? ResColor.selectedTextColor
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  collection.name,
                  style: TextStyle(
                    color: isSelected
                        ? ResColor.selectedTextColor
                        : ResColor.textMain,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> firstGroup() {
    return [
      _buildModernDrawerItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        text: "主页",
        onTap: () => widget.onItemTap(DrawerBtn.home),
      ),
      _buildModernDrawerItem(
        icon: Icons.star_border_outlined,
        selectedIcon: Icons.star,
        text: "收藏",
        onTap: () => widget.onItemTap(DrawerBtn.favourites),
      ),
      _buildModernDrawerItem(
        icon: Icons.local_library_outlined,
        selectedIcon: Icons.local_library,
        text: "我的文库",
        onTap: () => widget.onItemTap(DrawerBtn.library),
      ),
    ];
  }

  List<Widget> thirdGroup() {
    return [
      _buildModernDrawerItem(
        icon: Icons.description_outlined,
        selectedIcon: Icons.description,
        text: "未分类条目",
        onTap: () => widget.onItemTap(DrawerBtn.unfiled),
      ),
      _buildModernDrawerItem(
        icon: Icons.book_outlined,
        selectedIcon: Icons.book,
        text: "我的出版物",
        onTap: () => widget.onItemTap(DrawerBtn.publications),
      ),
      _buildModernDrawerItem(
        icon: Icons.delete_outline,
        selectedIcon: Icons.delete,
        text: "回收站",
        onTap: () => widget.onItemTap(DrawerBtn.trash),
      ),
    ];
  }

  Widget _buildModernDrawerItem({
    required IconData icon,
    required IconData selectedIcon,
    required String text,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectDrawerTitle == text;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectDrawerTitle = text;
            });
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? ResColor.selectedBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: ResColor.selectedTextColor.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    key: ValueKey(isSelected),
                    color: isSelected
                        ? ResColor.selectedTextColor
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isSelected
                          ? ResColor.selectedTextColor
                          : ResColor.textMain,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: ResColor.selectedTextColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return pageDrawer(context);
  }

  void _jumpToSettings() {
    MyRouter.instance.pushNamed(context, "settingsPage");
  }

  void _jumpToAccountSetting() {
    MyRouter.instance
        .pushNamed(context, "settingsPage", arguments: {"initTab": 'account'});
  }
}    
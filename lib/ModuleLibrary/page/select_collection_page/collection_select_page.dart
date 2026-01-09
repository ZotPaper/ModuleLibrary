import 'dart:collection';

import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:module_base/view/appbar/neat_appbar.dart';
import 'package:module_library/ModuleLibrary/viewmodels/zotero_database.dart';
import 'package:module_library/ModuleLibrary/res/ResColor.dart';
import 'package:module_library/ModuleLibrary/zotero_provider.dart';

import '../../../LibZoteroStorage/entity/Collection.dart';

class CollectionSelector extends StatefulWidget {

  List<String> initialSelected = [];
  final bool isMultiSelect;

  CollectionSelector({
    List<String>? parentCollections,
    this.isMultiSelect = true,
  }): initialSelected = parentCollections ?? [];

  @override
  _CollectionSelectorState createState() => _CollectionSelectorState();
}

class _CollectionSelectorState extends State<CollectionSelector>
    with TickerProviderStateMixin {
  final List<CollectionSelection> collections = [];
  final List<CollectionSelection> filteredCollections = [];
  final ZoteroDB zoteroDB = ZoteroProvider.getZoteroDB();
  final HashSet<String> selectedCollections = HashSet();
  final TextEditingController _searchController = TextEditingController();
  
  late AnimationController _animationController;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    for (var collectionKey in widget.initialSelected) {
      selectedCollections.add(collectionKey);
    }

    _initializeCollections();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeCollections() async {
    await Future.delayed(const Duration(milliseconds: 100)); // 模拟加载
    
    List<CollectionSelection> res = [];
    var topCollections = zoteroDB.collections.where((it) {
      return !it.hasParent();
    }).toList();
    
    recurseCollection(res, topCollections);

    setState(() {
      collections.addAll(res);
      filteredCollections.addAll(res);
      _isLoading = false;
    });
    
    _animationController.forward();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterCollections();
    });
  }

  void _filterCollections() {
    if (_searchQuery.isEmpty) {
      filteredCollections.clear();
      filteredCollections.addAll(collections);
    } else {
      filteredCollections.clear();
      _searchInCollections(collections, filteredCollections);
    }
  }

  void _searchInCollections(
      List<CollectionSelection> source, List<CollectionSelection> target) {
    for (var collection in source) {
      if (collection.collection.name.toLowerCase().contains(_searchQuery)) {
        target.add(collection);
      } else if (collection.children.isNotEmpty) {
        var childResults = <CollectionSelection>[];
        _searchInCollections(collection.children, childResults);
        if (childResults.isNotEmpty) {
          var parentCopy = CollectionSelection(
            collection: collection.collection,
            isSelected: collection.isSelected,
            isExpanded: true,
            children: childResults,
          );
          target.add(parentCopy);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return simpleAppBar(
      title: "选择集合",
      actions: [
        Container(
          child: TextButton(
            onPressed: _handleConfirm,
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 14),
              foregroundColor: ResColor.selectedTextColor,
            ),
            child: const Text('确定'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      // margin: const EdgeInsets.all(16),
      child: BrnSearchText(
        // focusNode: focusNode,
        controller: _searchController,
        // searchController: scontroller..isActionShow = true,
        onTextClear: () {
          return false;
        },
        autoFocus: false,
        onActionTap: () {
          // focusNode.unfocus();
        },
        onTextCommit: (text) {
          _onSearchChanged();
        },
        onTextChange: (text) {
          _onSearchChanged();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ResColor.selectedTextColor),
            ),
            const SizedBox(height: 16),
            Text(
              '加载集合中...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredCollections.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: filteredCollections.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            return _buildCollectionTree(filteredCollections[index], 0);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? '暂无集合' : '未找到匹配的集合',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? '请先同步您的集合数据' : '尝试使用其他关键词搜索',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionTree(CollectionSelection collection, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCollectionItem(collection, depth),
        if (collection.children.isNotEmpty && collection.isExpanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Column(
              children: collection.children
                  .map((child) => _buildCollectionTree(child, depth + 1))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCollectionItem(CollectionSelection collection, int depth) {
    final isSelected = collection.isSelected;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(
        left: (depth * 20.0),
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: isSelected ? ResColor.selectedBgColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? ResColor.selectedTextColor : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _handleCollectionTap(collection),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                if (collection.children.isNotEmpty)
                  GestureDetector(
                    onTap: () => _toggleExpanded(collection),
                    child: AnimatedRotation(
                      turns: collection.isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                Icon(
                  collection.children.isNotEmpty
                      ? (collection.isExpanded ? Icons.folder_open : Icons.folder)
                      : Icons.folder_outlined,
                  size: 20,
                  color: isSelected ? ResColor.selectedTextColor : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    collection.collection.name,
                    style: TextStyle(
                      color: isSelected ? ResColor.selectedTextColor : ResColor.textMain,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildSelectionIndicator(collection),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(CollectionSelection collection) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: collection.isSelected 
              ? ResColor.selectedTextColor 
              : Colors.grey.shade400,
          width: 2,
        ),
        color: collection.isSelected 
            ? ResColor.selectedTextColor 
            : Colors.transparent,
      ),
      child: collection.isSelected
          ? const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            )
          : null,
    );
  }

  void _toggleExpanded(CollectionSelection collection) {
    setState(() {
      collection.isExpanded = !collection.isExpanded;
    });
  }

  void _handleCollectionTap(CollectionSelection collection) {
    setState(() {
      changeCollectionChecked(collection, !collection.isSelected);
    });
  }

  void _handleConfirm() {
    Navigator.pop(context, selectedCollections.toList());
  }

  void recurseCollection(List<CollectionSelection> res, List<Collection>? value) {
    if (value == null || value.isEmpty) {
      return;
    }

    for (var child in value) {
      var sub = CollectionSelection(collection: child);

      // 默认选中的逻辑
      if (selectedCollections.contains(child.key)) {
        sub.isSelected = true;
      }

      recurseCollection(sub.children, child.subCollections);
      res.add(sub);
    }
  }

  void changeCollectionChecked(CollectionSelection collection, bool checked) {
    if (widget.isMultiSelect) {
      collection.isSelected = checked;
      if (checked) {
        if (!selectedCollections.contains(collection.collection.key)) {
          selectedCollections.add(collection.collection.key);
        }
      } else {
        selectedCollections.remove(collection.collection.key);
      }
    } else {
      uncheckAllCollections(collections);
      uncheckAllCollections(filteredCollections);
      collection.isSelected = checked;

      selectedCollections.clear();
      if (checked) {
        selectedCollections.add(collection.collection.key);
      }
    }
  }

  void uncheckAllCollections(List<CollectionSelection>? collections) {
    if (collections == null || collections.isEmpty) return;

    for (var it in collections) {
      it.isSelected = false;
      uncheckAllCollections(it.children);
    }

  }
}

class CollectionSelection {
  final Collection collection;
  bool isSelected;
  bool isExpanded;
  final List<CollectionSelection> children;

  CollectionSelection({
    required this.collection,
    this.isSelected = false,
    this.isExpanded = false,
    List<CollectionSelection>? children,
  }) : children = children ?? [];

  void setSelected(bool value) {
    isSelected = value;
  }

  void setExpanded(bool value) {
    isExpanded = value;
  }

}
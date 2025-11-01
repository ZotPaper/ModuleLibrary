import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bruno/bruno.dart';
import 'package:module_base/view/appbar/neat_appbar.dart';
import 'package:module_library/LibZoteroApi/Model/ZoteroSettingsResponse.dart';
import 'package:module_library/ModuleLibrary/utils/color_utils.dart';
import 'package:module_library/ModuleLibrary/utils/my_logger.dart';
import 'package:module_library/ModuleLibrary/viewmodels/zotero_database.dart';
import 'package:module_library/ModuleTagManager/item_tagmanager.dart';
import '../../LibZoteroStorage/entity/Item.dart';
import '../../LibZoteroStorage/entity/ItemTag.dart';
import '../../ModuleLibrary/utils/sheet_item_helper.dart';

class TagsManagerPage extends StatefulWidget {
  const TagsManagerPage({super.key});

  @override
  State<TagsManagerPage> createState() => _ItemDetailTagFragmentState();
}

class _ItemDetailTagFragmentState extends State<TagsManagerPage> {
  
  /// 加载状态管理
  bool _isLoading = true;
  String? _errorMessage;

  /// 优化后的数据结构
  Map<String, TagColor> _tagMap = {};
  List<TagColor> _displayTags = [];
  
  /// 样式标签和普通标签的分界索引
  int _styledTagsCount = 0;
  
  /// 搜索和过滤
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final focusNode = FocusNode();

  final TagManager _tagManager = TagManager();
  final ZoteroDB _zoteroDB = ZoteroDB();

  @override
  void initState() {
    super.initState();
    _loadTagsAsync();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 异步加载标签数据，避免阻塞UI
  Future<void> _loadTagsAsync() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 并行获取数据，提高加载速度
      final results = await Future.wait([
        _loadAllTagsFromDatabase(),
        _tagManager.getStyledTags(),
      ]);

      final Set<String> uniqueTags = results[0] as Set<String>;
      final List<TagColor> styledTags = results[1] as List<TagColor>;
      
      // 验证精选标签是否有重复
      final styledTagNames = styledTags.map((e) => e.name).toList();
      final uniqueStyledTagNames = styledTagNames.toSet();
      if (styledTagNames.length != uniqueStyledTagNames.length) {
        MyLogger.e("警告：精选标签数据源包含重复项！原始数量: ${styledTagNames.length}, 去重后: ${uniqueStyledTagNames.length}");
      } else {
        MyLogger.d("精选标签数据验证通过，无重复项，数量: ${styledTags.length}");
      }

      // 优化的标签合并算法
      await _mergeTagsEfficiently(uniqueTags, styledTags);

    } catch (e) {
      MyLogger.e("加载标签失败: $e");
      setState(() {
        _errorMessage = "加载标签失败: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 在后台线程加载数据库标签
  Future<Set<String>> _loadAllTagsFromDatabase() async {
    return await Future.microtask(() {
      final Set<String> uniqueTags = LinkedHashSet<String>();
      
      // 批量处理，避免单个forEach阻塞
      final allTags = _zoteroDB.itemTags;
      const batchSize = 1000;
      
      for (int i = 0; i < allTags.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, allTags.length);
        final batch = allTags.sublist(i, end);
        
        for (final tag in batch) {
          uniqueTags.add(tag.tag);
        }
        
        // 每处理一批数据后让出控制权
        if (i + batchSize < allTags.length) {
          return Future.delayed(Duration.zero).then((_) => uniqueTags);
        }
      }
      
      return uniqueTags;
    });
  }

  /// 高效的标签合并算法 O(n) 替代原来的 O(n²)，样式标签优先显示
  Future<void> _mergeTagsEfficiently(Set<String> uniqueTags, List<TagColor> styledTags) async {
    await Future.microtask(() {
      _tagMap.clear();
      _displayTags.clear();

      // 创建样式标签的Set，用于快速查找
      final styledTagNames = <String>{};
      
      // 首先添加样式标签到显示列表，保持原始顺序
      for (final styledTag in styledTags) {
        _tagMap[styledTag.name] = styledTag;
        _displayTags.add(styledTag);
        styledTagNames.add(styledTag.name);
      }

      // 收集未样式化的标签
      final unstyledTags = <TagColor>[];
      for (final tagName in uniqueTags) {
        if (!styledTagNames.contains(tagName)) {
          final unstyledTag = TagColor(name: tagName, color: '#4B5162');
          _tagMap[tagName] = unstyledTag;
          unstyledTags.add(unstyledTag);
        }
      }
      
      // 对未样式化的标签按名称排序
      unstyledTags.sort((a, b) => a.name.compareTo(b.name));
      
             // 将排序后的未样式化标签添加到显示列表后面
       _displayTags.addAll(unstyledTags);

        _displayTags.forEach((tag) {
        MyLogger.e("Moyaer=== _displayTags name: ${tag.name} color: ${tag.color}");
      });

       
       // 记录样式标签的数量，用于UI分组显示
       _styledTagsCount = styledTags.length;
       
       MyLogger.d("标签排序完成: ${styledTags.length} 个样式标签在前，${unstyledTags.length} 个普通标签在后");
    });
  }

  /// 搜索过滤 - 搜索时保持样式标签优先显示
  List<TagColor> get _filteredTags {
    if (_searchQuery.isEmpty) {
      return _displayTags;
    }
    
    final filtered = _displayTags.where((tag) => 
      tag.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
    
    // 搜索时也保持样式标签在前的顺序
    // 因为 _displayTags 已经是排序好的（样式标签在前），所以过滤后仍然保持这个顺序
    return filtered;
  }

  /// 刷新数据
  Future<void> _refreshTags() async {
    await _loadTagsAsync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: '标签管理',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTags,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          focusNode.unfocus();
        },
        child: _buildBody()
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载标签中...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_errorMessage!, 
                 style: const TextStyle(fontSize: 16),
                 textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshTags,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTags,
      child: Column(
        children: [
          _buildSearchBar(),
          _buildTagCounter(),
          Expanded(child: _buildTagsList()),
        ],
      ),
    );
  }

  /// 搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrnSearchText(
        focusNode: focusNode,
        controller: _searchController,
        // searchController: scontroller..isActionShow = true,
        onTextClear: () {
          return false;
        },
        autoFocus: false,
        onActionTap: () {
          // scontroller.isClearShow = false;
          // scontroller.isActionShow = false;
          focusNode.unfocus();
          // BrnToast.show('取消', context);
        },
        onTextCommit: (text) {
          _onSearchChanged(text);
          // _viewModel.setFilterText(text);
        },
        onTextChange: (text) {
          _onSearchChanged(text);
          // _viewModel.setFilterText(text);
          // BrnToast.show('输入内容 : $text', context);
        },
      ),
    );
  }

  /// 标签计数器
  Widget _buildTagCounter() {
    final filteredCount = _filteredTags.length;
    final totalCount = _displayTags.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            _searchQuery.isEmpty 
                ? '共 $totalCount 个标签'
                : '找到 $filteredCount 个标签 (共 $totalCount 个)',
            style: TextStyle(
              fontSize: 14, 
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          // _addTagButton(),
        ],
      ),
    );
  }

  /// 优化的标签列表 - 使用虚拟化处理大量标签
  Widget _buildTagsList() {
    final filteredTags = _filteredTags;
    
    if (filteredTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.label_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '暂无标签' : '未找到匹配的标签',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // 对于大量标签使用ListView.builder，小量标签使用Wrap
    if (filteredTags.length > 100) {
      return _buildVirtualizedTagList(filteredTags);
    } else {
      return _buildWrapTagList(filteredTags);
    }
  }

  /// 虚拟化标签列表 - 适用于大量标签，支持分组显示
  Widget _buildVirtualizedTagList(List<TagColor> tags) {
    const itemsPerRow = 3;
    
    // 构建分组的显示项列表（包含标题和标签行）
    final displayItems = <Widget>[];
    
    // 添加样式标签组
    if (_styledTagsCount > 0 && _searchQuery.isEmpty) {
      displayItems.add(_buildSectionHeader('精选标签', _styledTagsCount, Colors.blue.shade600));
      displayItems.add(const SizedBox(height: 8));
      
      final styledTags = tags.take(_styledTagsCount).toList();
      final styledRowCount = (styledTags.length / itemsPerRow).ceil();
      
      for (int rowIndex = 0; rowIndex < styledRowCount; rowIndex++) {
        final startIndex = rowIndex * itemsPerRow;
        final endIndex = (startIndex + itemsPerRow).clamp(0, styledTags.length);
        final rowTags = styledTags.sublist(startIndex, endIndex);
        
        displayItems.add(_buildTagRow(rowTags, itemsPerRow));
      }
      
      displayItems.add(const SizedBox(height: 16));
    }
    
    // 添加普通标签组
    final remainingTags = _searchQuery.isEmpty 
        ? tags.skip(_styledTagsCount).toList()
        : tags;
        
    if (remainingTags.isNotEmpty) {
      final sectionTitle = _searchQuery.isEmpty 
          ? '所有标签' 
          : '搜索结果';
      final sectionColor = _searchQuery.isEmpty 
          ? Colors.grey.shade600 
          : Colors.orange.shade600;
          
      displayItems.add(_buildSectionHeader(sectionTitle, remainingTags.length, sectionColor));
      displayItems.add(const SizedBox(height: 8));
      
      final remainingRowCount = (remainingTags.length / itemsPerRow).ceil();
      
      for (int rowIndex = 0; rowIndex < remainingRowCount; rowIndex++) {
        final startIndex = rowIndex * itemsPerRow;
        final endIndex = (startIndex + itemsPerRow).clamp(0, remainingTags.length);
        final rowTags = remainingTags.sublist(startIndex, endIndex);
        
        displayItems.add(_buildTagRow(rowTags, itemsPerRow));
      }
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        return displayItems[index];
      },
    );
  }

  /// 构建标签行
  Widget _buildTagRow(List<TagColor> rowTags, int itemsPerRow) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (int i = 0; i < itemsPerRow; i++)
            Expanded(
              child: i < rowTags.length
                  ? Padding(
                      padding: EdgeInsets.only(
                        right: i < itemsPerRow - 1 ? 8 : 0,
                      ),
                      child: _tagItem(rowTags[i]),
                    )
                  : const SizedBox(),
            ),
        ],
      ),
    );
  }

  /// Wrap布局标签列表 - 适用于少量标签，分组显示
  Widget _buildWrapTagList(List<TagColor> tags) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 显示样式标签
          if (_styledTagsCount > 0 && _searchQuery.isEmpty) ...[
            _buildSectionHeader('精选标签', _styledTagsCount, Colors.blue.shade600),
            const SizedBox(height: 8),
            _buildTagsWrap(tags.take(_styledTagsCount).toList()),
            const SizedBox(height: 16),
          ],
          
          // 显示普通标签
          if (tags.length > _styledTagsCount || _searchQuery.isNotEmpty) ...[
            if (_searchQuery.isEmpty)
              _buildSectionHeader('所有标签', tags.length - _styledTagsCount, Colors.grey.shade600)
            else
              _buildSectionHeader('搜索结果', tags.length, Colors.orange.shade600),
            const SizedBox(height: 8),
            _buildTagsWrap(_searchQuery.isEmpty 
                ? tags.skip(_styledTagsCount).toList()
                : tags),
          ],
        ],
      ),
    );
  }

  /// 构建标签区域标题
  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建标签Wrap布局
  Widget _buildTagsWrap(List<TagColor> tags) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.start,
      spacing: 8,
      runSpacing: 8,
      children: tags.map(_tagItem).toList(),
    );
  }

  /// 优化的标签项构建
  Widget _buildTagItem(TagColor tag) {
    Color tagColor;
    try {
      tagColor = ColorUtils.hexToColor(tag.color);
    } catch (e) {
      tagColor = const Color(0xFF4B5162);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTagTap(tag),
        onLongPress: () => _onTagLongPress(tag),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F2FA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tagColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tagColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tag.name,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 添加标签按钮
  Widget _addTagButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onAddTag,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, 
                   size: 18, 
                   color: Colors.blue.shade600),
              const SizedBox(width: 6),
              Text(
                "添加标签",
                style: TextStyle(
                  color: Colors.blue.shade600, 
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 搜索变化处理
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  /// 标签点击处理
  void _onTagTap(TagColor tag) {
    MyLogger.d("标签点击: ${tag.name}");
    // TODO: 实现标签详情或编辑功能
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('标签: ${tag.name}'),
    //     duration: const Duration(seconds: 1),
    //   ),
    // );
  }

  /// 标签长按处理
  void _onTagLongPress(TagColor tag) {
    MyLogger.d("标签长按: ${tag.name}");
    // TODO: 显示标签操作菜单
    _showTagContextMenu(tag);
  }

  /// 显示标签上下文菜单
  void _showTagContextMenu(TagColor tag) {

    List<ItemClickProxy> itemClickProxies = [];
    itemClickProxies.add(ItemClickProxy(
      title: "编辑标签",
      onClick: () {
        // _viewModel.viewItemOnline(context, item);
        // Navigator.pop(context);
        BrnToast.show("编辑标签, 功能待实现～", context);
        _editTag(tag);
      },
    ));

    itemClickProxies.add(ItemClickProxy(
      title: "更改颜色",
      onClick: () {
        // _viewModel.removeStar(item: item);
        // Navigator.pop(context);
        BrnToast.show("更改颜色, 功能待实现～", context);
        _changeTagColor(tag);
      },
    ));

    itemClickProxies.add(ItemClickProxy(
      title: "删除标签",
      desc: "所有引用该标签的条目将不再显示该标签",
      actionStyle: "alert",
      onClick: () {
        // _viewModel.removeStar(item: item);
        BrnToast.show("删除标签, 功能待实现～", context);
        // Navigator.pop(context);
        _deleteTag(tag);
      },
    ));

    List<BrnCommonActionSheetItem> itemActions = itemClickProxies.map((ele) {
      var actionStyle = BrnCommonActionSheetItemStyle.normal;
      if (ele.actionStyle != null && ele.actionStyle == "alert") {
        actionStyle = BrnCommonActionSheetItemStyle.alert;
      }
      return BrnCommonActionSheetItem(
        ele.title,
        desc: ele.desc,
        actionStyle: actionStyle,
      );
    }).toList();

    // 展示actionSheet
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (BuildContext bottomSheetContext) {
          return BrnCommonActionSheet(
            title: '标签: ${tag.name}',
            actions: itemActions,
            cancelTitle: "取消",
            clickCallBack: (int index, BrnCommonActionSheetItem actionEle) {
              itemClickProxies[index].onClick?.call();
            },
          );
        });
  }

  Widget _tagItem(TagColor tag) {
    Color? tagColor;
    try {
      tagColor = ColorUtils.hexToColor(tag.color);
    } catch (e) {
      tagColor = const Color(0xFF4B5162);
    }

    return InkWell(
      onTap: () => _onTagTap(tag),
      onLongPress: () => _onTagLongPress(tag),
      child: BrnTagCustom(
        tagText: tag.name,
        fontSize: 14,
        backgroundColor: const Color(0xFFF1F2FA),
        textColor: tagColor,
        textPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      ),
    );
  }


  /// 添加新标签
  void _onAddTag() {
    MyLogger.d("添加新标签");
    // TODO: 实现添加标签功能
    BrnToast.show("添加标签功能开发中...", context);
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text('添加标签功能开发中...'),
    //     duration: Duration(seconds: 2),
    //   ),
    // );
  }

  /// 编辑标签
  void _editTag(TagColor tag) {
    MyLogger.d("编辑标签: ${tag.name}");
    // TODO: 实现编辑标签功能
  }

  /// 更改标签颜色
  void _changeTagColor(TagColor tag) {
    MyLogger.d("更改标签颜色: ${tag.name}");
    // TODO: 实现颜色选择功能
  }

  /// 删除标签
  void _deleteTag(TagColor tag) {
    MyLogger.d("删除标签: ${tag.name}");
    // TODO: 实现删除标签功能
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除标签 "${tag.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 执行删除操作
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已删除标签: ${tag.name}')),
              );
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

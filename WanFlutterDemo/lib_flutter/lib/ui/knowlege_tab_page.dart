import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lib_flutter/api/api.dart';
import 'package:lib_flutter/cfg/wconstans.dart';
import 'package:lib_flutter/entity/article.dart';
import 'package:lib_flutter/entity/tree_item.dart';
import 'package:lib_flutter/util/custom_scrollcontroller.dart';
import 'package:lib_flutter/widget/article_item_view.dart';
import 'package:lib_flutter/widget/loading_view.dart';
import 'package:md2_tab_indicator/md2_tab_indicator.dart';

///知识体系sub
// ignore: must_be_immutable
class KnowledgeTabPage extends StatefulWidget {
  TreeItem treeItem;
  KnowledgeTabPage(this.treeItem);

  @override
  _KnowledgeTabPageState createState() {
    return _KnowledgeTabPageState();
  }
}

class _KnowledgeTabPageState extends State<KnowledgeTabPage>
    with SingleTickerProviderStateMixin {
  static const MethodChannel _methodChannel =
      MethodChannel(METHOD_CHANNEL_WEB_VIEW);
  var _scrollController;
  TabController _tabController;
  List<Widget> _tabWidgets = List();
  Map<int, List<Article>> _dataMap = new Map();
  Map<int, int> _dataPage = new Map();
  bool _startLoading = true;

  @override
  void initState() {
    _scrollController = new CustomScrollController(() {
      int index = _tabController.index;
      int id = widget.treeItem.children[index].id;
      int page = _dataPage[id];
      getArticle(page, id);
    });
    _tabController =
        TabController(length: widget.treeItem.children.length, vsync: this);
    widget.treeItem.children.forEach((treeItem) {
      _tabWidgets.add(Padding(
          padding: EdgeInsets.fromLTRB(2, 10, 2, 10),
          child: Text(treeItem.name)));
    });

    _tabController.addListener(() {
      int id = widget.treeItem.children[_tabController.index].id;
      if (_dataPage[id] == null && _dataMap[id] == null) {
        getArticle(0, id);
      }
      switch (_tabController.index) {
      }
    });
    super.initState();
    getArticle(0, widget.treeItem.children[0].id);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.treeItem.name),
      ),
      body: Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            TabBar(
              controller: _tabController,
              labelStyle: TextStyle(fontWeight: FontWeight.w700),
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Color(0xff1a73e8),
              unselectedLabelColor: Color(0xff5f6368),
              isScrollable: true,
              indicator: MD2Indicator(
                  indicatorHeight: 3,
                  indicatorColor: Color(0xff1a73e8),
                  indicatorSize: MD2IndicatorSize.normal),
              tabs: _tabWidgets,
            ),
            Expanded(
                child: Stack(
              alignment: AlignmentDirectional.center,
              children: <Widget>[
                TabBarView(
                    controller: _tabController,
                    children: widget.treeItem.children.map((treeItem) {
                      return RefreshIndicator(
                          onRefresh: () {
                            int index = _tabController.index;
                            int id = widget.treeItem.children[index].id;
                            _dataPage[id] = 0;
                            _dataMap[id].clear();
                            return getArticle(0, id);
                          },
                          child: ListView.separated(
                              controller: _scrollController,
                              itemBuilder: (BuildContext context, int index) {
                                return ArticleItemView(() {
                                  _methodChannel.invokeMethod("article_detail",
                                      _dataMap[treeItem.id][index].link);
                                }, _dataMap[treeItem.id][index]);
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) {
                                return Container(
                                    color: Colors.grey, height: 0.5);
                              },
                              itemCount: _dataMap[treeItem.id] == null
                                  ? 0
                                  : _dataMap[treeItem.id].length));
                    }).toList()),
                LoadingView(_startLoading),
              ],
            )),
          ],
        ),
      ),
    );
  }



  Future getArticle(int page, int id) {
    setState(() {
      _startLoading = true;
    });

    return ApiHelper.getArticleDataUnderTree(page, id).then((articleData) {
      setState(() {
        if (_dataMap[id] == null) {
          _dataMap[id] = articleData.datas;
        } else {
          _dataMap[id].addAll(articleData.datas);
        }
        _dataPage[id] = articleData.curPage;
        _startLoading = false;
      });
    });
  }
}

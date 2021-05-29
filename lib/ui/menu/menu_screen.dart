import 'package:flutter/material.dart';
import 'package:possystem/components/bottom_sheet_actions.dart';
import 'package:possystem/components/circular_loading.dart';
import 'package:possystem/components/empty_body.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/constants/icons.dart';
import 'package:possystem/localizations.dart';
import 'package:possystem/models/repository/menu_model.dart';
import 'package:possystem/ui/menu/widgets/catalog_list.dart';
import 'package:possystem/ui/menu/widgets/catalog_modal.dart';
import 'package:possystem/ui/menu/widgets/catalog_orderable_list.dart';
import 'package:provider/provider.dart';

class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuModel>();
    if (menu.isNotReady) return CircularLoading();

    return Scaffold(
      appBar: AppBar(
        title: Text('種類列表'),
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(KIcons.back)),
        actions: [
          IconButton(
            onPressed: () => showCircularBottomSheet(
              context,
              actions: _actions(context),
            ),
            icon: Icon(KIcons.more),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => CatalogModal())),
        tooltip: Local.of(context).t('menu.add_catalog'),
        child: Icon(KIcons.add),
      ),
      // When click android go back, it will avoid closing APP
      body: _body(context),
    );
  }

  Iterable<Widget> _actions(BuildContext context) {
    return <Widget>[
      ListTile(
        title: Text('排序產品種類'),
        leading: Icon(Icons.reorder_sharp),
        onTap: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) {
              final items = MenuModel.instance.catalogList;
              return CatalogOrderableList(items: items);
            },
          ),
        ),
      ),
    ];
  }

  Widget _body(BuildContext context) {
    // strictly equal to: Provider.of<MenuModel>(context)
    // context.read<T>() === Provider.of<T>(context, listen: false)
    final menu = context.watch<MenuModel>();

    if (menu.isEmpty) return Center(child: EmptyBody('menu.empty'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(kSpacing1),
          child: Text('共 ${menu.length} 項',
              style: Theme.of(context).textTheme.caption),
        ),
        Expanded(child: _catalogList(menu)),
      ],
    );
  }

  SingleChildScrollView _catalogList(MenuModel menu) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          // TODO: search bar
          // MenuSearchBar(),
          // get sorted catalogs
          CatalogList(menu.catalogList),
        ],
      ),
    );
  }
}

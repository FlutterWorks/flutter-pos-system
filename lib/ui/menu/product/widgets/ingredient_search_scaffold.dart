import 'package:flutter/material.dart';
import 'package:possystem/components/card_tile.dart';
import 'package:possystem/components/scaffold/search_scaffold.dart';
import 'package:possystem/models/stock/ingredient_model.dart';
import 'package:possystem/models/histories/search_history.dart';
import 'package:possystem/models/repository/stock_model.dart';

class IngredientSearchScaffold extends StatelessWidget {
  IngredientSearchScaffold({Key key, this.text}) : super(key: key);

  static final String tag = 'menu.poduct.ingredient.search';
  final String text;
  final scaffold = GlobalKey<SearchScaffoldState>();
  final histories = SearchHistory(SearchHistoryTypes.ingredient);

  @override
  Widget build(BuildContext context) {
    return SearchScaffold<IngredientModel>(
      key: scaffold,
      onChanged: (String text) async =>
          StockModel.instance.sortBySimilarity(text),
      itemBuilder: _itemBuilder,
      emptyBuilder: _emptyBuilder,
      initialBuilder: _initialBuilder,
      heroTag: IngredientSearchScaffold.tag,
      text: text,
      hintText: '成份名稱，起司',
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _itemBuilder(BuildContext context, dynamic ingredient) {
    return CardTile(
      title: Text(ingredient.name),
      onTap: () {
        histories.add(scaffold.currentState.searchBar.currentState.text);
        Navigator.of(context).pop<IngredientModel>(ingredient);
      },
    );
  }

  Widget _emptyBuilder(BuildContext context, String text) {
    return CardTile(
      title: Text('新增成份「$text」'),
      onTap: () {
        final ingredient = IngredientModel(name: text);
        StockModel.instance.updateIngredient(ingredient);
        Navigator.of(context).pop<IngredientModel>(ingredient);
      },
    );
  }

  Widget _initialBuilder(BuildContext context) {
    final history = histories.get(() => scaffold.currentState.updateView());
    if (history == null) return CircularProgressIndicator();

    return Column(
      children: [
        Text('搜尋紀錄', style: Theme.of(context).textTheme.caption),
        Expanded(
          child: ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return CardTile(
                title: Text(history.elementAt(index)),
                onTap: () => scaffold.currentState
                    .setSearchKeyword(history.elementAt(index)),
              );
            },
            itemCount: history.length,
          ),
        ),
      ],
    );
  }
}

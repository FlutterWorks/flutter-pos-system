import 'package:flutter/material.dart';
import 'package:possystem/components/dialog/confirm_dialog.dart';
import 'package:possystem/models/repository/order_repo.dart';
import 'package:possystem/models/repository/cart_model.dart';

class OrderActions extends StatelessWidget {
  const OrderActions({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ..._actions(context),
          ListTile(
            title: Text('取消'),
            leading: Icon(Icons.cancel_sharp),
            onTap: () => Navigator.of(context).pop(),
          ),
        ]),
      ),
    );
  }

  Iterable<Widget> _actions(BuildContext context) {
    if (CartModel.instance.isHistoryMode) {
      return [
        ListTile(
          title: Text('退出改單模式'),
          leading: Icon(Icons.assignment_return_sharp),
          onTap: () => Navigator.pop(context, OrderActionTypes.leave_pop),
        ),
      ];
    }

    return [
      ListTile(
        title: Text('顯示最後一次點餐'),
        leading: Icon(Icons.history_sharp),
        onTap: () => Navigator.pop(context, OrderActionTypes.pop),
      ),
      ListTile(
        title: Text('暫存本次點餐'),
        leading: Icon(Icons.file_download),
        onTap: () => Navigator.pop(context, OrderActionTypes.stash),
      ),
      ListTile(
        title: Text('顯示暫存餐點'),
        leading: Icon(Icons.file_upload),
        onTap: () => Navigator.pop(context, OrderActionTypes.pop_stash),
      ),
      ListTile(
        title: Text('離開點餐頁面'),
        leading: Icon(Icons.logout),
        onTap: () => Navigator.pop(context, OrderActionTypes.leave),
      ),
    ];
  }

  static Future<void> onAction(
    BuildContext context,
    OrderActionTypes action,
  ) async {
    switch (action) {
      case OrderActionTypes.leave_pop:
        return CartModel.instance.leaveHistoryMode();
      case OrderActionTypes.leave:
        return Navigator.of(context).pop();
      case OrderActionTypes.pop:
        if (!await showPopConfirm(context)) return;

        if (!await CartModel.instance.stash()) {
          showSnackbar(context, '暫存檔案的次數超過上限');
        }

        if (!await CartModel.instance.popHistory()) {
          showSnackbar(context, '找不到當日上一次的紀錄，可以去點單紀錄查詢更久的紀錄');
        }
        return;
      case OrderActionTypes.pop_stash:
        if (!await showPopConfirm(context)) return;

        final order = await OrderRepo.instance.popStash();
        if (order == null) {
          return showSnackbar(context, '目前沒有暫存的紀錄唷');
        }

        return CartModel.instance.updateProductions(order.parseToProduct());
      case OrderActionTypes.stash:
        if (!await CartModel.instance.stash()) {
          showSnackbar(context, '暫存檔案的次數超過上限');
        }
    }
  }

  static Future<bool> showPopConfirm(BuildContext context) async {
    if (CartModel.instance.isEmpty) return true;

    final result = await showDialog(
      context: context,
      builder: (_) => ConfirmDialog(title: '要暫存本次點餐並顯示舊的單嗎？'),
    );

    return result ?? false;
  }

  static void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

enum OrderActionTypes {
  pop,
  pop_stash,
  stash,
  leave,
  leave_pop,
}

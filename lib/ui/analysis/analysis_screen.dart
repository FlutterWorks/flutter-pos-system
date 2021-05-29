import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:possystem/components/circular_loading.dart';
import 'package:possystem/components/meta_block.dart';
import 'package:possystem/helper/util.dart';
import 'package:possystem/models/objects/order_object.dart';
import 'package:possystem/models/repository/order_repo.dart';
import 'package:possystem/providers/currency_provider.dart';
import 'package:possystem/providers/language_provider.dart';
import 'package:possystem/services/cache.dart';
import 'package:possystem/ui/analysis/order_modal.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

int _hashDate(DateTime e) => e.day + e.month * 100 + e.year * 10000;

int _hashMonth(DateTime e) => e.month + e.year * 100;

class AnalysisScreen extends StatefulWidget {
  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Locale _locale;

  final LinkedHashMap<DateTime, int> _orderCounts = LinkedHashMap(
    equals: isSameDay,
    hashCode: _hashDate,
  );
  final List<int> _loadedCounts = <int>[];

  List<OrderObject> _data;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  set calendarFormat(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
      Cache.instance.set<int>(Caches.analyze_calendar_format, format.index);
    });
  }

  set selectedDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _filter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            _calendar(),
            Expanded(child: _data == null ? CircularLoading() : _body(context))
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Cache.instance.get<int>(Caches.analyze_calendar_format).then((value) {
      if (value != null && _calendarFormat.index != value) {
        setState(() => _calendarFormat = CalendarFormat.values[value]);
      }
    });

    final language = context.watch<LanguageProvider>();
    _locale = language.locale;
  }

  @override
  void initState() {
    super.initState();
    _filter();
    _handlePageChange(_selectedDay);
  }

  Widget _badgeBuilder(BuildContext context, DateTime day, List value) {
    if (value.isEmpty) return null;

    return Positioned(
      right: 0,
      bottom: 0,
      child: Material(
        shape: CircleBorder(side: BorderSide.none),
        // TODO: add to themes
        color: Colors.cyan,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(value.length.toString()),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_data.isEmpty) {
      return Text('本日無點餐紀錄', style: Theme.of(context).textTheme.caption);
    }

    return ListView.builder(
      itemBuilder: (context, index) => _orderTile(_data[index]),
      itemCount: _data.length,
    );
  }

  Widget _calendar() {
    return TableCalendar<Null>(
      firstDay: DateTime(2021, 1),
      focusedDay: _focusedDay,
      selectedDayPredicate: (DateTime day) => isSameDay(day, _selectedDay),
      lastDay: DateTime.now(),
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.monday,
      locale: _locale.toString(),
      rangeSelectionMode: RangeSelectionMode.disabled,
      eventLoader: (DateTime day) {
        return List.filled(_orderCounts[day] ?? 0, null);
      },
      onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
        this.selectedDay = selectedDay;
      },
      onFormatChanged: (CalendarFormat selected) {
        if (_calendarFormat != selected) {
          calendarFormat = selected;
        }
      },
      onPageChanged: _handlePageChange,
      calendarBuilders: CalendarBuilders(markerBuilder: _badgeBuilder),
    );
  }

  void _filter() {
    final end =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day + 1);
    final start =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    setState(() => _data = null);

    OrderRepo.instance.getBetween(start, end).then((result) {
      setState(() {
        _data =
            result.map<OrderObject>((row) => OrderObject.build(row)).toList();
      });
    }).catchError((err) => print(err));
  }

  Future<void> _getCounts(DateTime day) async {
    final end = DateTime(day.year, day.month + 1);
    final start = DateTime(day.year, day.month);

    final result = await OrderRepo.instance.countByDay(start, end);

    setState(() {
      try {
        _orderCounts.addAll(<DateTime, int>{
          for (final row in result) Util.fromUTC(row['createdAt']): row['count']
        });
      } catch (e) {
        print(e);
      }
    });
  }

  Future<void> _handlePageChange(DateTime day) async {
    _focusedDay = day;
    if (!_loadedCounts.contains(_hashMonth(day))) {
      _loadedCounts.add(_hashMonth(day));
      await _getCounts(day);
    }
  }

  Widget _orderTile(OrderObject order) {
    final title = order.products.map<String>((e) {
      final count = e.count > 1 ? ' * ${e.count}' : '';
      return '${e.productName}$count';
    }).join(',');

    return ListTile(
      leading: Text('${order.createdAt.hour}:${order.createdAt.minute}'),
      title: Text(title),
      subtitle: MetaBlock.withString(context, [
        '總價：${CurrencyProvider.instance.numToString(order.totalPrice)}',
        '付額：${CurrencyProvider.instance.numToString(order.paid)}',
      ]),
      onTap: () {
        showDialog(context: context, builder: (_) => OrderModal(order: order));
      },
    );
  }
}

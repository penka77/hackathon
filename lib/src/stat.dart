import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

class StatScreen extends StatefulWidget {
  const StatScreen({super.key});

  @override
  State<StatScreen> createState() => _StatScreenState();
}

enum ChartType { pie, bar, radar }

class Receipt {
  final DateTime date;
  final String category;
  final double amount;

  Receipt(this.date, this.category, this.amount);

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      DateTime.parse(json['date']),
      json['category'],
      json['amount'].toDouble(),
    );
  }
}

class _StatScreenState extends State<StatScreen> {
  final Dio _dio = Dio();
  String _selectedPeriod = 'За неделю';
  ChartType _selectedChartType = ChartType.pie;
  final List<String> _periods = [
    'Сегодня',
    'За неделю',
    'Месяц',
    'За все время'
  ];

  List<Receipt> _receipts = [];
  bool _isLoading = true;
  String? _error;

  // Категории
  final List<String> _allCategories = [
    'Продукты',
    'Одежда',
    'Кафе',
    'Аптеки',
    'Красота',
    'Образование',
    'Спорт',
    'Электроника',
  ];

  // Выбранные категории (изначально все)
  Set<String> _selectedCategories = {};

  // Цвета для категорий
  final List<Color> _categoryColors = [
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.red.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.amber.shade400,
    Colors.indigo.shade400,
  ];

  // Основной цвет интерфейса
  final Color _primaryColor = const Color(0xFFDE3E1B);

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(_allCategories);
    _fetchReceipts();
  }

  Future<void> _fetchReceipts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _dio.get('http://localhost:8000/receipts');
      final List<dynamic> data = response.data;
      setState(() {
        _receipts = data.map((json) => Receipt.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки данных: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, double> _getCurrentData() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day + 1);

    switch (_selectedPeriod) {
      case 'Сегодня':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'За неделю':
        startDate = DateTime(now.year, now.month, now.day - 6);
        break;
      case 'Месяц':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'За все время':
      default:
        startDate = DateTime(0);
        break;
    }

    final filteredReceipts = _receipts.where((receipt) {
      return receipt.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          receipt.date.isBefore(endDate) &&
          _selectedCategories.contains(receipt.category);
    }).toList();

    final Map<String, double> result = {};
    for (var category in _selectedCategories) {
      result[category] = 0;
    }

    for (var receipt in filteredReceipts) {
      result[receipt.category] = (result[receipt.category] ?? 0) + receipt.amount;
    }

    return result;
  }

  Future<void> _showCategoryFilterDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Выберите категории'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Все категории'),
                      value: _selectedCategories.length == _allCategories.length,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            _selectedCategories = Set.from(_allCategories);
                          } else {
                            _selectedCategories.clear();
                          }
                        });
                        setState(() {});
                      },
                      activeColor: _primaryColor,
                      checkColor: Colors.white,
                    ),
                    const Divider(),
                    ..._allCategories.map((category) {
                      return CheckboxListTile(
                        title: Text(category),
                        value: _selectedCategories.contains(category),
                        onChanged: (bool? value) {
                          setStateDialog(() {
                            if (value == true) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                          setState(() {});
                        },
                        activeColor: _primaryColor,
                        checkColor: Colors.white,
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Закрыть',
                    style: TextStyle(color: _primaryColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildChartTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildChartTypeButton(ChartType.pie, Icons.pie_chart, 'Круговая'),
          _buildChartTypeButton(ChartType.bar, Icons.bar_chart, 'Гистограмма'),
          _buildChartTypeButton(ChartType.radar, Icons.star, 'Лепестковая'),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton(ChartType type, IconData icon, String label) {
    return GestureDetector(
      onTap: () => setState(() => _selectedChartType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: _selectedChartType == type
              ? _primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: _selectedChartType == type
                    ? _primaryColor
                    : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              color: _selectedChartType == type
                  ? _primaryColor
                  : Colors.grey,
              fontSize: 12,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChart(Map<String, double> data) {
    if (data.values.every((value) => value == 0)) {
      return const Center(child: Text('Нет данных за выбранный период'));
    }

    switch (_selectedChartType) {
      case ChartType.pie:
        return SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: _getPieChartSections(data),
              centerSpaceRadius: 80,
              sectionsSpace: 0,
            ),
          ),
        );
      case ChartType.bar:
        return SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              barGroups: _getBarChartGroups(data),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.keys.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            data.keys.elementAt(index),
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      case ChartType.radar:
        return SizedBox(
          height: 300,
          child: RadarChart(
            RadarChartData(
              dataSets: _getRadarDataSets(data),
              radarBackgroundColor: Colors.transparent,
              radarBorderData: const BorderSide(color: Colors.grey),
              titlePositionPercentageOffset: 0.2,
              titleTextStyle: const TextStyle(fontSize: 12),
              getTitle: (index, angle) {
                return RadarChartTitle(
                  text: _allCategories[index],
                  angle: angle,
                );
              },
              tickCount: 5,
              ticksTextStyle: const TextStyle(fontSize: 10),
              tickBorderData: const BorderSide(color: Colors.grey, width: 0.5),
              gridBorderData: const BorderSide(color: Colors.grey, width: 1),
            ),
          ),
        );
    }
  }

  List<PieChartSectionData> _getPieChartSections(Map<String, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    return data.entries.where((entry) => entry.value > 0).map((entry) {
      final index = _allCategories.indexOf(entry.key);
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        color: _categoryColors[index],
        value: entry.value,
        title: '$percentage%',
        radius: 24,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _getBarChartGroups(Map<String, double> data) {
    return data.entries.where((entry) => entry.value > 0).map((entry) {
      final index = _allCategories.indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: _categoryColors[index],
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  List<RadarDataSet> _getRadarDataSets(Map<String, double> data) {
    // Создаем список значений для всех категорий (даже тех, где значение 0)
    final values = _allCategories.map((category) {
      return data[category] ?? 0.0;
    }).toList();

    return [
      RadarDataSet(
        dataEntries: values.map((value) => RadarEntry(value: value)).toList(),
        borderColor: _primaryColor,
        fillColor: _primaryColor.withOpacity(0.2),
        entryRadius: 4,
        borderWidth: 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchReceipts,
                child: const Text('Повторить попытку'),
              ),
            ],
          ),
        ),
      );
    }

    final currentData = _getCurrentData();
    final filteredReceipts = _receipts.where((receipt) {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = DateTime(now.year, now.month, now.day + 1);

      switch (_selectedPeriod) {
        case 'Сегодня':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'За неделю':
          startDate = DateTime(now.year, now.month, now.day - 6);
          break;
        case 'Месяц':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'За все время':
        default:
          return _selectedCategories.contains(receipt.category);
      }

      return receipt.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          receipt.date.isBefore(endDate) &&
          _selectedCategories.contains(receipt.category);
    }).toList();

    final totalAmount = currentData.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 50,
                    width: 120,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Всего: ${totalAmount.toStringAsFixed(0)} руб.',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_alt),
                    onPressed: _showCategoryFilterDialog,
                    tooltip: 'Фильтр категорий',
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _buildChartTypeSelector(),
              _buildSelectedChart(currentData),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _periods.map((String period) {
                    return DropdownMenuItem<String>(
                      value: period,
                      child: Text(period),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedPeriod = newValue!);
                  },
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Последние чеки:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              filteredReceipts.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Нет чеков за выбранный период'),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredReceipts.length,
                itemBuilder: (context, index) {
                  final receipt = filteredReceipts[index];
                  final color = _categoryColors[_allCategories.indexOf(receipt.category)];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  receipt.category,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  DateFormat('dd.MM.yy').format(receipt.date),
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${receipt.amount.toStringAsFixed(0)} руб.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
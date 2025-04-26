import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class Offer {
  final String category;
  final String partner;
  final String offer;
  final String details;
  final DateTime validUntil;

  const Offer({
    required this.category,
    required this.partner,
    required this.offer,
    required this.details,
    required this.validUntil,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      category: json['category'],
      partner: json['partner'],
      offer: json['offer'],
      details: json['details'],
      validUntil: DateTime.parse(json['valid_until']),
    );
  }
}

final Map<String, Color> categoryColors = {
  'Электроника': const Color(0xFF7183CC),
  'Красота и уход': const Color(0xFFE46666),
  'Продукты': const Color(0xFF53CC77),
  'Кафе и рестораны': const Color(0xFFEFCD0D),
  'Путешествия': const Color(0xFF7FD3FD),
  'Одежда': const Color(0xFFF77CF9),
};

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final Dio _dio = Dio();
  List<Offer> _offers = [];
  bool _isLoading = true;
  String? _error;



  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  void _processOffers(List<dynamic> data) {
    final Map<String, Offer> uniqueOffers = {};

    for (var json in data) {
      final offer = Offer.fromJson(json);
      if (!uniqueOffers.containsKey(offer.category)) {
        uniqueOffers[offer.category] = offer;
      }
    }

    setState(() {
      _offers = uniqueOffers.values.toList();
      _isLoading = false;
    });
  }

  Future<void> _fetchOffers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _dio.get('http://localhost:8000/offers');
      _processOffers(response.data);
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки предложений: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 132,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Image.asset('assets/images/logo.png'),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchOffers,
              child: const Text('Повторить попытку'),
            ),
          ],
        ),
      );
    }

    if (_offers.isEmpty) {
      return const Center(child: Text('Нет доступных предложений'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RefreshIndicator(
        onRefresh: _fetchOffers,
        child: ListView(
          children: [
            ..._offers.map((offer) => _buildOfferBlock(offer, context)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferBlock(Offer offer, BuildContext context) {
    final color = categoryColors[offer.category] ?? Colors.grey[700]!;
    return InkWell(
      onTap: () {
        _showOfferDialog(context, offer);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              offer.category,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  offer.partner,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.offer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferDialog(BuildContext context, Offer offer) {
    bool isActivated = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(offer.partner),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Категория: ${offer.category}"),
                  const SizedBox(height: 8),
                  Text("Предложение: ${offer.offer}"),
                  const SizedBox(height: 16),
                  Text(offer.details),
                  const SizedBox(height: 8),
                  Text("Действует до: ${DateFormat('dd.MM.yyyy').format(offer.validUntil)}"),
                  if (isActivated)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        "Предложение активировано!",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE46666),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Закрыть"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFD8181),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isActivated
                      ? null
                      : () {
                    setState(() {
                      isActivated = true;
                    });
                    // Здесь можно добавить вызов API для активации предложения
                  },
                  child: const Text("Активировать"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
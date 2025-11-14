import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math';


class ChartData {
  ChartData(this.time, this.open, this.high, this.low, this.close);
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
}

class LiveMarketPage extends StatefulWidget {
  const LiveMarketPage({super.key});

  @override
  LiveMarketPageState createState() => LiveMarketPageState();
}

class LiveMarketPageState extends State<LiveMarketPage>
    with TickerProviderStateMixin {
  TabController? _tabController;
  late AnimationController _controller;

  List<dynamic> cryptoData = [];
  List<dynamic> stockData = [];
  bool isLoading = true;
  String errorMessage = '';
  final Map<String, bool> _expandedCards = {};
  final Map<String, bool> _favorites = {};
  String _searchQuery = '';


  final Set<String> _selectedItems = {};
  final Map<String, dynamic> _selectedItemData = {};

  final Color _positiveColor = const Color(0xFF00E676);
  final Color _negativeColor = const Color(0xFFFF5252);
  final Color _backgroundColor = const Color(0xFF0A0E21);
  final Color _cardColor = const Color(0xFF1D1F33);
  final Color _accentColor = const Color(0xFF03DAC6);

  final Map<String, IconData> _cryptoIcons = {
    'bitcoin': Icons.currency_bitcoin,
    'ethereum': Icons.currency_exchange,
    'ripple': Icons.account_balance,
    'litecoin': Icons.money,
    'cardano': Icons.credit_card,
    'polkadot': Icons.circle,
    'bitcoin-cash': Icons.currency_bitcoin,
    'stellar': Icons.star,
    'chainlink': Icons.link,
    'binancecoin': Icons.account_balance_wallet,
    'monero': Icons.security,
    'dogecoin': Icons.pets,
    'picoin': Icons.currency_exchange,
  };

  final Map<String, IconData> _stockIcons = {
    'XU100': Icons.show_chart,
    'GARAN': Icons.account_balance,
    'AKBNK': Icons.account_balance,
    'THYAO': Icons.airplanemode_active,
    'ASELS': Icons.security,
    'KOZAA': Icons.landscape,
    'SASA': Icons.factory,
    'EREGL': Icons.build,
    'KCHOL': Icons.business,
    'TCELL': Icons.signal_cellular_alt,
    'ISCTR': Icons.account_balance_wallet,
    'SISE': Icons.blur_on,
    'SAHOL': Icons.business_center,
    'PGSUS': Icons.airplanemode_on,
    'FROTO': Icons.directions_car,
    'PETKM': Icons.local_gas_station,
    'TUPRS': Icons.oil_barrel,
    'KOZAL': Icons.diamond,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);



    fetchMarketData();
  }

  Future<void> fetchMarketData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final cryptoResponse = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=false'),
      );

      if (cryptoResponse.statusCode == 200) {
        cryptoData = json.decode(cryptoResponse.body);
      } else {
        throw Exception('Failed to load crypto data.');
      }

      await Future.delayed(const Duration(seconds: 1));
      stockData = [
        {'symbol': 'XU100', 'name': 'BIST 100', 'price': 8543.67, 'change': 1.23, 'volume': 23456789, 'isCrypto': false},
        {'symbol': 'GARAN', 'name': 'Garanti Bankası', 'price': 45.80, 'change': -0.65, 'volume': 12345678, 'isCrypto': false},
        {'symbol': 'AKBNK', 'name': 'Akbank', 'price': 38.45, 'change': 0.89, 'volume': 9876543, 'isCrypto': false},
        {'symbol': 'THYAO', 'name': 'Türk Hava Yolları', 'price': 215.60, 'change': 2.34, 'volume': 5678901, 'isCrypto': false},
        {'symbol': 'ASELS', 'name': 'Aselsan', 'price': 132.75, 'change': -1.12, 'volume': 3456789, 'isCrypto': false},
        {'symbol': 'KOZAA', 'name': 'Koza Anadolu Metal', 'price': 178.90, 'change': 3.21, 'volume': 2345678, 'isCrypto': false},
        {'symbol': 'SASA', 'name': 'Sasa Polyester', 'price': 67.45, 'change': -2.11, 'volume': 3456789, 'isCrypto': false},
        {'symbol': 'EREGL', 'name': 'Ereğli Demir Çelik', 'price': 42.30, 'change': 0.75, 'volume': 4567890, 'isCrypto': false},
        {'symbol': 'KCHOL', 'name': 'Koç Holding', 'price': 125.80, 'change': 1.45, 'volume': 5678901, 'isCrypto': false},
        {'symbol': 'TCELL', 'name': 'Turkcell', 'price': 38.90, 'change': -0.35, 'volume': 6789012, 'isCrypto': false},
        {'symbol': 'ISCTR', 'name': 'İş Bankası', 'price': 22.50, 'change': 1.15, 'volume': 8765432, 'isCrypto': false},
        {'symbol': 'SISE', 'name': 'Şişecam', 'price': 48.10, 'change': 0.95, 'volume': 7654321, 'isCrypto': false},
        {'symbol': 'SAHOL', 'name': 'Sabancı Holding', 'price': 65.75, 'change': -0.78, 'volume': 6543210, 'isCrypto': false},
        {'symbol': 'PGSUS', 'name': 'Pegasus', 'price': 650.40, 'change': 2.80, 'volume': 5432109, 'isCrypto': false},
        {'symbol': 'FROTO', 'name': 'Ford Otosan', 'price': 980.50, 'change': 1.55, 'volume': 4321098, 'isCrypto': false},
        {'symbol': 'PETKM', 'name': 'Petkim', 'price': 15.60, 'change': -1.30, 'volume': 3210987, 'isCrypto': false},
        {'symbol': 'TUPRS', 'name': 'Tüpraş', 'price': 1450.00, 'change': 3.10, 'volume': 2109876, 'isCrypto': false},
        {'symbol': 'KOZAL', 'name': 'Koza Altın', 'price': 250.25, 'change': -0.90, 'volume': 1098765, 'isCrypto': false},
      ];

      final piCoinData = {
        'symbol': 'PI',
        'name': 'Pi Network',
        'current_price': 0.01567,
        'price_change_percentage_24h': 12.45,
        'total_volume': 1234567,
        'market_cap': 56789012,
        'id': 'picoin',
        'image': 'https://s2.coinmarketcap.com/static/img/coins/64x64/3336.png',
        'isCrypto': true,
      };
      cryptoData.add(piCoinData);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Piyasa verileri yüklenirken bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
      });
    }
  }

  String formatPrice(dynamic price, bool isCrypto) {
    double priceValue = price is int ? price.toDouble() : price;

    if (isCrypto) {

      if (priceValue > 1) {
        return '${NumberFormat("#,##0.00").format(priceValue)} USDT';
      } else {
        return '${NumberFormat("#,##0.000000").format(priceValue)} USDT';
      }
    } else {
      if (priceValue > 1) {
        return '${NumberFormat.currency(symbol: '₺', decimalDigits: 2).format(priceValue)}';
      } else {
        return '${NumberFormat.currency(symbol: '₺', decimalDigits: 2).format(priceValue)}';
      }
    }
  }

  String formatChange(dynamic change) {
    double changeValue = change is int ? change.toDouble() : change;
    return '${changeValue >= 0 ? '+' : ''}${changeValue.toStringAsFixed(2)}%';
  }

  Color getPriceColor(dynamic change) {
    double changeValue = change is int ? change.toDouble() : change;
    return changeValue >= 0 ? _positiveColor : _negativeColor;
  }

  IconData getTrendIcon(dynamic change) {
    double changeValue = change is int ? change.toDouble() : change;
    return changeValue >= 0 ? Icons.trending_up : Icons.trending_down;
  }

  Widget getAssetIcon(Map<String, dynamic> item, bool isCrypto) {
    if (isCrypto && item['image'] != null) {
      return Image.network(
        item['image'],
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) => Icon(
          _cryptoIcons[item['id']] ?? Icons.currency_exchange,
          color: _accentColor,
          size: 20,
        ),
      );
    } else {
      String symbol = isCrypto ? (item['symbol'] ?? '').toLowerCase() : item['symbol'];
      IconData iconData = isCrypto ? _cryptoIcons[item['id']] ?? Icons.currency_exchange : _stockIcons[symbol.toUpperCase()] ?? Icons.business;
      return Icon(
        iconData,
        color: _accentColor,
        size: 20,
      );
    }
  }



  void _toggleFavorite(String id) {
    setState(() {
      _favorites[id] = !(_favorites[id] ?? false);
    });
  }

  void _toggleSelection(Map<String, dynamic> item) {
    final String id = item.containsKey('id') ? item['id'] : item['symbol'];
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
        _selectedItemData.remove(id);
      } else {
        if (_selectedItems.length < 2) {
          _selectedItems.add(id);
          _selectedItemData[id] = item;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sadece iki hisse karşılaştırabilirsiniz.')),
          );
        }
      }
    });
  }

  List<dynamic> getFilteredData(List<dynamic> data, bool isCrypto) {
    if (_searchQuery.isEmpty) {
      List<dynamic> favorites = [];
      List<dynamic> others = [];
      for (var item in data) {
        final String id = isCrypto ? item['id'] : (item['id'] ?? item['symbol']);
        if (_favorites[id] ?? false) {
          favorites.add(item);
        } else {
          others.add(item);
        }
      }
      return favorites + others;
    }
    return data.where((item) {
      final String name = item['name']?.toString().toLowerCase() ?? '';
      final String symbol = isCrypto ? (item['symbol']?.toString().toLowerCase() ?? '') : (item['symbol']?.toString().toLowerCase() ?? '');
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || symbol.contains(query);
    }).toList();
  }

  void _navigateToChartPage(Map<String, dynamic> item, bool isCrypto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChartPage(item: item, isCrypto: isCrypto),
      ),
    );
  }

  Widget _buildMarketCardContent(Map<String, dynamic> item, bool isCrypto) {
    final String id = isCrypto ? item['id'] : (item['id'] ?? item['symbol']);
    final String name = item['name'] ?? '';
    final String symbol = isCrypto ? (item['symbol'] ?? '').toUpperCase() : item['symbol'];
    final dynamic price = isCrypto ? (item['current_price'] ?? 0) : (item['price'] ?? 0);
    final dynamic change = isCrypto ? (item['price_change_percentage_24h'] ?? 0) : (item['change'] ?? 0);
    final bool isExpanded = _expandedCards[id] ?? false;
    final bool isFavorite = _favorites[id] ?? false;
    final Widget iconWidget = getAssetIcon(item, isCrypto);
    final bool isSelected = _selectedItems.contains(id);

    return Card(
      color: _cardColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          width: 2.0,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToChartPage(item, isCrypto),
        onLongPress: () => _toggleSelection(item),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accentColor.withOpacity(0.2),
                          ),
                          child: Center(
                            child: iconWidget,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                symbol,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white70,
                    ),
                    onPressed: () => _toggleFavorite(id),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatPrice(price, isCrypto),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getPriceColor(change).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          getTrendIcon(change),
                          color: getPriceColor(change),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatChange(change),
                          style: TextStyle(
                            color: getPriceColor(change),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailItem('24h Volume',
                        isCrypto
                            ? '${NumberFormat.compact().format(item['total_volume'])}'
                            : '${NumberFormat.compact().format(item['volume'])}',
                        isCrypto
                    ),
                    _buildDetailItem('Market Cap',
                        isCrypto
                            ? '${NumberFormat.compact().format(item['market_cap'])}'
                            : '-',
                        isCrypto
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, bool isCrypto) {
    String formattedValue = value;
    if (title == '24h Volume' || title == 'Market Cap') {
      if (isCrypto) {
        formattedValue = '\$$value'; 
      } else {
        formattedValue = '₺$value'; 
      }
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedValue,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Arama...',
          hintStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(Icons.search, color: Colors.white70),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildContent(List<dynamic> data, bool isCrypto) {
    List<dynamic> sortedData = getFilteredData(data, isCrypto);

    if (sortedData.isEmpty) {
      return const Center(
        child: Text(
          'Arama kriterlerinize uygun piyasa verisi bulunamadı.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      itemCount: sortedData.length,
      itemBuilder: (context, index) {
        return _buildMarketCardContent(sortedData[index] as Map<String, dynamic>, isCrypto);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> displayedCryptoData = getFilteredData(cryptoData, true);
    final List<dynamic> displayedStockData = getFilteredData(stockData, false);

    if (isLoading || errorMessage.isNotEmpty || _tabController == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                ),
              if (errorMessage.isNotEmpty) ...[
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: fetchMarketData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Tekrar Dene'),
                ),
              ] else
                const Text(
                  'Piyasa verileri yükleniyor...',
                  style: TextStyle(color: Colors.white),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, color: _accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Canlı Piyasa Takibi',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              size: 18,
            ),
            color: _accentColor,
            onPressed: () {
              fetchMarketData();
            },
            tooltip: 'Verileri Yenile',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112.0),
          child: Column(
            children: [
              _buildSearchBar(),
              TabBar(
                controller: _tabController!,
                indicatorColor: _accentColor,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Hepsi'),
                  Tab(text: 'Kripto'),
                  Tab(text: 'Hisse'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF121212),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            TabBarView(
              controller: _tabController!,
              children: [
                ListView(
                  children: [
                    if (displayedCryptoData.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Kripto Paralar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...displayedCryptoData.map((item) => _buildMarketCardContent(item as Map<String, dynamic>, true)).toList(),
                    ],
                    if (displayedStockData.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Hisse Senetleri',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...displayedStockData.map((item) => _buildMarketCardContent(item as Map<String, dynamic>, false)).toList(),
                    ],
                  ],
                ),
                _buildContent(displayedCryptoData, true),
                _buildContent(displayedStockData, false),
              ],
            ),
            if (_selectedItems.isNotEmpty)
              Positioned(
                bottom: 20,
                right: 20,
                left: 20,
                child: FloatingActionButton.extended(
                  heroTag: 'compare_button',
                  onPressed: () {
                    if (_selectedItems.length >= 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComparePage(
                            stocksToCompare: _selectedItemData.values.toList().cast<Map<String, dynamic>>(),
                          ),
                        ),
                      ).then((_) {
                        setState(() {
                          _selectedItems.clear();
                          _selectedItemData.clear();
                        });
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Karşılaştırmak için en az 2 hisse seçin.')),
                      );
                    }
                  },
                  backgroundColor: _accentColor,
                  label: Text('Karşılaştır (${_selectedItems.length}/2)'),
                  icon: const Icon(Icons.compare_arrows, color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChartPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isCrypto;

  const ChartPage({super.key, required this.item, required this.isCrypto});

  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _timeFrames = ['15m', '1h', '4h', '1d'];
  final List<List<ChartData>> _chartData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _timeFrames.length, vsync: this);
    fetchChartData();
  }

  Future<void> fetchChartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      _chartData.clear();
      for (var i = 0; i < _timeFrames.length; i++) {
        _chartData.add(_generateFakeCandleData(i));
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Grafik verileri yüklenirken bir hata oluştu.';
      });
    }
  }

  List<ChartData> _generateFakeCandleData(int timeFrameIndex) {
    final List<ChartData> data = [];
    const int points = 50;
    double basePrice = widget.item['current_price'] ?? widget.item['price'] ?? 0;
    Random random = Random();

    double fluctuationFactor = 0.0;
    if (timeFrameIndex == 0) fluctuationFactor = 0.005; // 15m
    if (timeFrameIndex == 1) fluctuationFactor = 0.01; // 1h
    if (timeFrameIndex == 2) fluctuationFactor = 0.02; // 4h
    if (timeFrameIndex == 3) fluctuationFactor = 0.03; // 1d

    double lastClose = basePrice;
    DateTime currentTime = DateTime.now();

    for (int i = 0; i < points; i++) {
      double open = lastClose;
      double change = (random.nextDouble() - 0.5) * fluctuationFactor;
      double close = open * (1 + change);
      double high = max(open, close) + open * random.nextDouble() * fluctuationFactor * 0.5;
      double low = min(open, close) - open * random.nextDouble() * fluctuationFactor * 0.5;

      lastClose = close;
      data.add(ChartData(currentTime.subtract(Duration(minutes: (points - i) * 15)), open, high, low, close));
    }
    return data;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          widget.item['name'] ?? widget.item['symbol'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.white)),
      )
          : Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.isCrypto
                  ? '${NumberFormat("#,##0.00").format(widget.item['current_price'] ?? widget.item['price'])} USDT'
                  : '${NumberFormat.currency(symbol: '₺', decimalDigits: 2).format(widget.item['current_price'] ?? widget.item['price'])}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(widget.item['price_change_percentage_24h'] ?? widget.item['change']) >= 0 ? '+' : ''}${
                (widget.item['price_change_percentage_24h'] ?? widget.item['change'])?.toStringAsFixed(2)
            }%',
            style: TextStyle(
              color: (widget.item['price_change_percentage_24h'] ?? widget.item['change']) >= 0
                  ? const Color(0xFF00E676)
                  : const Color(0xFFFF5252),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF03DAC6),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: _timeFrames.map((e) => Tab(text: e)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _timeFrames.map((timeFrame) {

                int index = _timeFrames.indexOf(timeFrame);
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildCandleChart(_chartData[index]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandleChart(List<ChartData> data) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        majorGridLines: const MajorGridLines(width: 0),
        dateFormat: DateFormat.Hm(),
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat.simpleCurrency(decimalDigits: 2, name: widget.isCrypto ? 'USD' : '₺'),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      series: <CandleSeries>[
        CandleSeries<ChartData, DateTime>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.time,
          openValueMapper: (ChartData data, _) => data.open,
          highValueMapper: (ChartData data, _) => data.high,
          lowValueMapper: (ChartData data, _) => data.low,
          closeValueMapper: (ChartData data, _) => data.close,
          bullColor: const Color(0xFF00E676),
          bearColor: const Color(0xFFFF5252),
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }
}

// ComparePage for comparing two stocks
class ComparePage extends StatefulWidget {
  final List<Map<String, dynamic>> stocksToCompare;

  const ComparePage({super.key, required this.stocksToCompare});

  @override
  _ComparePageState createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  final List<List<ChartData>> _chartData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final Color _positiveColor = const Color(0xFF00E676);
  final Color _negativeColor = const Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    fetchComparisonData();
  }

  Future<void> fetchComparisonData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      _chartData.clear();
      for (var item in widget.stocksToCompare) {
        _chartData.add(_generateFakeCandleData(item));
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Karşılaştırma verileri yüklenirken bir hata oluştu.';
      });
    }
  }

  List<ChartData> _generateFakeCandleData(Map<String, dynamic> item) {
    final List<ChartData> data = [];
    const int points = 50;
    double basePrice = item['current_price'] ?? item['price'] ?? 0;
    Random random = Random();

    double fluctuationFactor = 0.0;
    if (item['isCrypto'] ?? false) {
      fluctuationFactor = 0.01;
    } else {
      fluctuationFactor = 0.02;
    }

    double lastClose = basePrice;
    DateTime currentTime = DateTime.now();

    for (int i = 0; i < points; i++) {
      double open = lastClose;
      double change = (random.nextDouble() - 0.5) * fluctuationFactor;
      double close = open * (1 + change);
      double high = max(open, close) + open * random.nextDouble() * fluctuationFactor * 0.5;
      double low = min(open, close) - open * random.nextDouble() * fluctuationFactor * 0.5;

      lastClose = close;
      data.add(ChartData(currentTime.subtract(Duration(minutes: (points - i) * 15)), open, high, low, close));
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text(
          'Hisse Karşılaştırması',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.white)),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.stocksToCompare.map((item) {
                final isCrypto = item.containsKey('isCrypto') ? item['isCrypto'] : false;
                return Expanded(
                  child: Card(
                    color: const Color(0xFF1D1F33),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text(
                            item['symbol'] ?? item['id'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCrypto
                                ? '${NumberFormat("#,##0.00").format(item['current_price'])} USDT'
                                : '${NumberFormat.currency(symbol: '₺', decimalDigits: 2).format(item['price'])}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(item['price_change_percentage_24h'] ?? item['change']) >= 0 ? '+' : ''}${
                                (item['price_change_percentage_24h'] ?? item['change'])?.toStringAsFixed(2)
                            }%',
                            style: TextStyle(
                              color: (item['price_change_percentage_24h'] ?? item['change']) >= 0
                                  ? _positiveColor
                                  : _negativeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                primaryXAxis: DateTimeAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  dateFormat: DateFormat.Hm(),
                ),
                primaryYAxis: const NumericAxis(
                  majorGridLines: MajorGridLines(width: 0),
                ),
                series: _chartData.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final List<ChartData> data = entry.value;
                  final String name = widget.stocksToCompare[index]['symbol'] ?? widget.stocksToCompare[index]['id'];

                  return CandleSeries<ChartData, DateTime>(
                    name: name,
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.time,
                    openValueMapper: (ChartData data, _) => data.open,
                    highValueMapper: (ChartData data, _) => data.high,
                    lowValueMapper: (ChartData data, _) => data.low,
                    closeValueMapper: (ChartData data, _) => data.close,
                    bullColor: index == 0 ? Colors.blueAccent : Colors.orangeAccent,
                    bearColor: index == 0 ? Colors.blueAccent.withOpacity(0.5) : Colors.orangeAccent.withOpacity(0.5),
                  );
                }).toList(),
                tooltipBehavior: TooltipBehavior(enable: true),
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  textStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../model/coin_gecko.dart';
import 'market_provider.dart';
import 'wallet_provider.dart';

enum TradeMode { buy, sell }

class TradeProvider extends ChangeNotifier {
  MarketProvider marketProvider;
  WalletProvider walletProvider;

  // Trading state
  TradeMode _currentMode = TradeMode.buy;
  String _selectedCoinId = '';
  String _selectedCoinSymbol = '';

  // Loading and error states
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  TradeProvider({
    required this.marketProvider,
    required this.walletProvider,
  }) {
    _initialize();
    marketProvider.addListener(_onMarketChanged);
    walletProvider.addListener(_onWalletChanged);
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    // Initialize trading
    await _initializeTrading();

    _isInitialized = true;
  }

  void _onMarketChanged() {
    final stillExists =
        marketProvider.allCoins.any((coin) => coin.id == _selectedCoinId);
    if (!stillExists) {
      if (marketProvider.allCoins.isNotEmpty) {
        selectCoin(marketProvider.allCoins.first);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    marketProvider.removeListener(_onMarketChanged);
    walletProvider.removeListener(_onWalletChanged);
    _isInitialized = false;
    super.dispose();
  }

  // Getters
  TradeMode get currentMode => _currentMode;
  String get selectedCoinId => _selectedCoinId;
  String get selectedCoinSymbol => _selectedCoinSymbol;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  double get idrBalance {
    final balance = walletProvider.getBalance('IDR');
    return balance;
  }

  double get cryptoBalance {
    final balance = walletProvider.getBalance(_selectedCoinSymbol);
    return balance;
  }

  // Get current price from market provider
  double get currentPrice {
    final selectedCoin = marketProvider.allCoins.firstWhere(
      (coin) => coin.id == _selectedCoinId,
      orElse: () => CoinGeckoMarketModel(
        id: '',
        symbol: '',
        name: '',
        image: '',
        currentPrice: 0,
      ),
    );
    return selectedCoin.currentPrice;
  }

  // Initialize trading
  Future<void> _initializeTrading() async {
    // Hanya set default jika belum ada pilihan
    if (_selectedCoinId.isEmpty && marketProvider.allCoins.isNotEmpty) {
      selectCoin(marketProvider.allCoins.first);
    }
  }

  // Select coin
  void selectCoin(CoinGeckoMarketModel coin) {
    _selectedCoinId = coin.id;
    _selectedCoinSymbol = coin.symbol.toUpperCase();
    notifyListeners();
  }

  // Switch trade mode
  void setTradeMode(TradeMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  // Calculate trade for percentage
  Map<String, double> calculateTradeForPercentage(double percentage) {
    if (currentPrice <= 0) {
      throw Exception('Current price is not available');
    }

    double calculatedAmount = 0;
    double calculatedTotal = 0;

    if (_currentMode == TradeMode.buy) {
      final double idrToSpend = idrBalance * percentage; // Using getter
      calculatedAmount = idrToSpend / currentPrice;
      calculatedTotal = idrToSpend;
    } else {
      final double cryptoToSell = cryptoBalance * percentage; // Using getter
      calculatedAmount = cryptoToSell;
      calculatedTotal = cryptoToSell * currentPrice;
    }
    return {
      'amount': calculatedAmount,
      'total': calculatedTotal,
    };
  }

  // Execute trade
  Future<void> executeTrade(double amount) async {
    _setLoading(true);
    try {
      if (amount <= 0 || currentPrice <= 0) {
        throw Exception('Invalid amount or price');
      }

      final totalIdr = (currentPrice * amount).round().toDouble();
      final selectedCoin = marketProvider.allCoins.firstWhere(
        (coin) => coin.id == _selectedCoinId,
      );

      await walletProvider.executeTrade(
        cryptoSymbol: _selectedCoinSymbol,
        cryptoAmount: amount,
        idrAmount: totalIdr,
        isBuy: _currentMode == TradeMode.buy,
        coinData: selectedCoin,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _onWalletChanged() {
    final idr = walletProvider.getBalance('IDR');
    final crypto = walletProvider.getBalance(_selectedCoinSymbol);
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/coinGecko.dart';

class WalletProvider extends ChangeNotifier {
  late Box _walletBox;
  String _username = '';
  Map<String, double> _balances = {};
  bool _isLoading = false;
  String? _error;

  void resetWallet() {
    _username = '';
    _balances.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get username => _username;

  // Get all balances
  Map<String, double> get balances => Map.unmodifiable(_balances);

  // Get balance for any asset (IDR or crypto)
  double getBalance(String symbol) {
    final balance = _balances[symbol.toUpperCase()] ?? 0.0;
    return balance;
  }

  // Constructor
  WalletProvider() {
    _initializeWallet();
  }

  // Initialize wallet
  Future<void> _initializeWallet() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString('username') ?? 'Guest';
      _walletBox = await Hive.openBox('wallet_$_username');
      await loadAllBalances();
    } catch (e) {
      _error = 'Failed to initialize wallet: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Refresh wallet data
  Future<void> refresh() async {
    await loadAllBalances();
  }

  // Load all balances
  Future<void> loadAllBalances() async {
    if (!_walletBox.isOpen) return;

    try {
      Map<String, double> oldBalances = Map.from(_balances);

      // Load IDR balance
      final idrAsset = _walletBox.get('IDR', defaultValue: {'amount': 0.0});
      _balances['IDR'] = (idrAsset['amount'] as num?)?.toDouble() ?? 0.0;

      // Load all crypto balances
      for (var key in _walletBox.keys) {
        if (key != 'IDR') {
          final asset = _walletBox.get(key, defaultValue: {'amount': 0.0});
          final amount = (asset['amount'] as num?)?.toDouble() ?? 0.0;
          if (amount > 0) {
            _balances[key.toString().toUpperCase()] = amount;
          }
        }
      }

      // Check if balances actually changed
      bool balancesChanged = false;
      _balances.forEach((key, value) {
        if (oldBalances[key] != value) {
          balancesChanged = true;
        }
      });

      if (balancesChanged) {
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load balances: $e';
      notifyListeners();
    }
  }

  // Deposit IDR
  Future<void> depositIDR(double amount) async {
    if (amount <= 0) {
      throw Exception('Deposit amount must be positive');
    }

    try {
      final currentBalance = getBalance('IDR');
      await updateBalance('IDR', currentBalance + amount);
      final newBalance = getBalance('IDR');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to deposit: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Withdraw IDR
  Future<void> withdrawIDR(double amount) async {
    if (amount <= 0) {
      throw Exception('Withdrawal amount must be positive');
    }

    final currentBalance = getBalance('IDR');
    if (currentBalance < amount) {
      throw Exception('Insufficient balance');
    }

    try {
      await updateBalance('IDR', currentBalance - amount);
    } catch (e) {
      _error = 'Failed to withdraw: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Update balance for an asset
  Future<void> updateBalance(String symbol, double newAmount,
      {CoinGeckoMarketModel? coinData, double? priceInIdr}) async {
    if (!_walletBox.isOpen) {
      throw Exception('Wallet is not initialized');
    }

    symbol = symbol.toUpperCase();
    try {
      if (newAmount < 0) {
        throw Exception('Balance cannot be negative');
      }

      // Get old balance for comparison
      final oldBalance = getBalance(symbol);

      Map<String, dynamic> assetData;
      if (symbol == 'IDR') {
        assetData = {
          'amount': newAmount,
          'name': 'Rupiah',
          'short_name': 'IDR',
          'image_url': '',
          'price_in_idr': 1.0,
        };
      } else {
        // For crypto assets
        if (coinData == null && newAmount > 0) {
          throw Exception('Coin data required for crypto assets');
        }

        assetData = {
          'id': coinData?.id ?? symbol.toLowerCase(),
          'amount': newAmount,
          'name': coinData?.name ?? symbol,
          'short_name': symbol,
          'image_url': coinData?.image ?? '',
          'price_in_idr': priceInIdr ?? coinData?.currentPrice ?? 0,
        };
      }

      if (newAmount <= 0) {
        await _walletBox.delete(symbol);
        _balances.remove(symbol);
      } else {
        await _walletBox.put(symbol, assetData);
        _balances[symbol] = newAmount;
      }

      // Get new balance to verify update
      final verifyBalance = getBalance(symbol);

      // Only notify if balance actually changed
      if (oldBalance != verifyBalance) {
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Execute a trade (update both balances)
  Future<void> executeTrade({
    required String cryptoSymbol,
    required double cryptoAmount,
    required double idrAmount,
    required bool isBuy,
    required CoinGeckoMarketModel coinData,
  }) async {
    cryptoSymbol = cryptoSymbol.toUpperCase();

    try {
      if (isBuy) {
        // Check IDR balance
        if (getBalance('IDR') < idrAmount) {
          throw Exception('Insufficient IDR balance');
        }

        // Update balances for buy
        await updateBalance('IDR', getBalance('IDR') - idrAmount);
        await updateBalance(
          cryptoSymbol,
          getBalance(cryptoSymbol) + cryptoAmount,
          coinData: coinData,
        );
      } else {
        // Check crypto balance
        if (getBalance(cryptoSymbol) < cryptoAmount) {
          throw Exception('Insufficient $cryptoSymbol balance');
        }

        // Update balances for sell
        await updateBalance('IDR', getBalance('IDR') + idrAmount);
        await updateBalance(
          cryptoSymbol,
          getBalance(cryptoSymbol) - cryptoAmount,
          coinData: coinData,
        );
      }

      // Catat ke history
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? 'Guest';
      final historyBox = await Hive.openBox('transaction_history_$username');
      await historyBox.add({
        'type': isBuy ? 'buy' : 'sell',
        'asset': cryptoSymbol,
        'amount': cryptoAmount,
        'price': coinData.currentPrice,
        'date': DateTime.now().toIso8601String(),
        'note': '',
      });
      notifyListeners(); // Notify after trade completion
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
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
}

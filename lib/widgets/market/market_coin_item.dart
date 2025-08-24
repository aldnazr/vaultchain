import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/coin_gecko.dart';
import '../../pages/coin_detail_page.dart';

class MarketCoinListItem extends StatelessWidget {
  final CoinGeckoMarketModel coin;
  final NumberFormat priceFormatter;
  final NumberFormat volumeFormatter;

  const MarketCoinListItem({
    super.key,
    required this.coin,
    required this.priceFormatter,
    required this.volumeFormatter,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    Color changeColor =
        (coin.priceChangePercentage24h ?? 0) >= 0 ? Colors.green : Colors.red;

    return Column(children: [
      InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoinDetailPage(
                coinId: coin.id,
                coinName: coin.name,
                coinSymbol: coin.symbol,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.symbol.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      coin.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3, // Ruang untuk % perubahan
                child: Text(
                  "${(coin.priceChangePercentage24h ?? 0).toStringAsFixed(2)}%",
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4, // Ruang untuk Harga & Volume
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceFormatter.format(coin.currentPrice),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Vol ${volumeFormatter.format(coin.totalVolume ?? 0)}",
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const Divider(height: 5, thickness: 0.7, indent: 12, endIndent: 12),
    ]);
  }
}

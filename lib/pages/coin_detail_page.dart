import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/providers/coin_detail_provider.dart';
import '../widgets/coin/coin_chart_widget.dart';

class CoinDetailPage extends StatelessWidget {
  final String coinId;
  final String? coinName;
  final String? coinSymbol;

  const CoinDetailPage({
    super.key,
    required this.coinId,
    this.coinName,
    this.coinSymbol,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat priceFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final NumberFormat percentageFormatter = NumberFormat("##0.0#", "en_US");
    final NumberFormat volumeFormatter = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 2,
    );
    final NumberFormat coinVolumeFormatter = NumberFormat.compactSimpleCurrency(
      locale: 'en_US',
      decimalDigits: 2,
    );

    return ChangeNotifierProvider(
      key: ValueKey(coinId),
      create: (_) => CoinDetailProvider(coinId: coinId),
      child: Consumer<CoinDetailProvider>(
        builder: (context, detailProvider, _) {
          final coinDetail = detailProvider.coinDetail;
          final chartSpots = detailProvider.chartSpots;
          final isLoading = detailProvider.isLoading;
          final error = detailProvider.error;

          // Semua data diambil dari coinDetail
          final price = coinDetail?.currentPriceIdr != null
              ? priceFormatter.format(coinDetail!.currentPriceIdr)
              : '-';
          final high24h = coinDetail?.high24hIdr != null
              ? priceFormatter.format(coinDetail!.high24hIdr!)
              : '-';
          final low24h = coinDetail?.low24hIdr != null
              ? priceFormatter.format(coinDetail!.low24hIdr!)
              : '-';
          final volume = coinDetail?.totalVolumeIdr != null
              ? "${volumeFormatter.format(coinDetail!.totalVolumeIdr!)}"
              : '-';
          final volumeBtc = coinDetail?.totalVolumeBtc != null
              ? "${coinVolumeFormatter.format(coinDetail!.totalVolumeBtc!)} ${coinDetail.symbol.toUpperCase()}"
              : '-';

          String appBarTitle = coinDetail?.name ?? coinName ?? coinId;
          if (coinDetail?.symbol != null) {
            appBarTitle =
                "${coinDetail!.name} (${coinDetail.symbol.toUpperCase()})";
          } else if (coinSymbol != null) {
            appBarTitle =
                "${coinName ?? coinId} (${coinSymbol!.toUpperCase()})";
          }
          Widget buildChart() {
            return CoinChartWidget();
          }

          Widget buildInfoRow(String label, String? value) {
            if (value == null || value.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          Widget buildDescription(String? descriptionHtml) {
            if (descriptionHtml == null || descriptionHtml.isEmpty) {
              return const SizedBox.shrink();
            }
            String plainTextDescription = descriptionHtml
                .replaceAll(RegExp(r'<[^>]*>'), ' ')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            int maxLength = 300;
            if (plainTextDescription.length > maxLength) {
              plainTextDescription =
                  "${plainTextDescription.substring(0, maxLength)}...";
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text("Deskripsi",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(),
                const SizedBox(height: 4),
                Text(
                  plainTextDescription.isNotEmpty
                      ? plainTextDescription
                      : "Tidak ada deskripsi.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(appBarTitle,
                  style:
                      const TextStyle(color: Color.fromARGB(255, 59, 160, 63))),
              backgroundColor: Colors.white,
              titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Color.fromARGB(255, 112, 190, 145),
                  ),
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Gagal memuat detail: $error",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text("Coba Lagi"),
                                onPressed: () =>
                                    detailProvider.fetchAll(force: true),
                              ),
                            ],
                          ),
                        ),
                      )
                    : coinDetail == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Data detail koin tidak ditemukan."),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Coba Lagi"),
                                  onPressed: () =>
                                      detailProvider.fetchAll(force: true),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                detailProvider.fetchAll(force: true),
                            child: ListView(
                              padding: const EdgeInsets.all(16.0),
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                          ),
                                          const SizedBox(height: 0),
                                          Text(
                                            price.replaceAll('Rp ', ''),
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${coinDetail.priceChangePercentage24h! >= 0 ? '+' : ''}${percentageFormatter.format(coinDetail.priceChangePercentage24h)}%",
                                            style: TextStyle(
                                              color: (coinDetail
                                                          .priceChangePercentage24h! >=
                                                      0)
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                              fontSize: 23,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 2),
                                          buildInfoRow(
                                            "High",
                                            high24h,
                                          ),
                                          buildInfoRow(
                                            "Low",
                                            low24h,
                                          ),
                                          buildInfoRow(
                                            "Vol (IDR)",
                                            volume,
                                          ),
                                          buildInfoRow(
                                            "Vol (${coinDetail.symbol.toUpperCase()})",
                                            volumeBtc,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                buildChart(),
                                const SizedBox(height: 24),
                                buildDescription(coinDetail.descriptionEn),
                                if (coinDetail.homepageUrl != null &&
                                    coinDetail.homepageUrl!.isNotEmpty)
                                  ...[],
                                const SizedBox(height: 40),
                                // Tombol Buy & Sell
                                Row(
                                    // ... (Tombol Buy/Sell Anda) ...
                                    ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
          );
        },
      ),
    );
  }
}

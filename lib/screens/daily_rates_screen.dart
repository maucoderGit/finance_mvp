import 'package:flutter/material.dart';

class DailyRatesScreen extends StatelessWidget {
  const DailyRatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                height: 4,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Text(
                      'Historical Rates',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1 USD =',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () {},
                              ),
                              const Column(
                                children: [
                                  Text(
                                    'June 10, 2024',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Today',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: null, // Disabled
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    _buildCurrencyTile(
                      context,
                      'EUR',
                      'Euro',
                      '0.93',
                      true,
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDw4dJIlwW4QYhGn95RAN1QLvrQgTujzcnjvh9jXgdH-VssNP3sEDWLZAcqW4JzvC_yjqWWvx7rV4lou2q42H1bo6C8-yltjHPJ7FTAnUUUtdjYXcYF0BdleTG1d6JycNRvJmavp0en95Lp-gvu5T1YmnIMoH5sZ3eFC0noW1yuWxDzITtwfXV5Q0104_geI6_oaf9Y6o88QkDE1WG4LgXZ04Dsfqg3D7UKlo5NM65UogiG7hjYPo0jjlg7c6fX-XCpVEonZ-aJYhQ',
                    ),
                    _buildCurrencyTile(
                      context,
                      'JPY',
                      'Japanese Yen',
                      '157.25',
                      false,
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBpxfbAdUp7t6GDlw6xICmOJe-IcnVDP2QvKpzFroXP-a48hJKL_WVqcBrMXx3-OhRpel98ddmk5_uqDlbCEhsyriehEzCBwvUP2NCpT7gq-2QspPXtfjhxk4v_cv4je9dymYYJC1MSke8YkQR0BIxQqQ885jpyMF30TgWUlOShsuJyq33fsoEsWRkGmmR7CwOEpbL2q5sRStUqwjShm7ehCLJO1YhnrYMpvYmrlTbTjjA1qXuM--zvmAkekZAdj6WaD1s97Qx_ygE',
                    ),
                    _buildCurrencyTile(
                      context,
                      'GBP',
                      'British Pound',
                      '0.79',
                      true,
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuB2HMXgJjOPUeO-TyOQbDFtiPowQXYExWwa2AKPTILP2oQkXEt4hXV-aLma0ttJG80IXd-2cMs5GZo9yiYCxjy3D56IZR80RA4q6ywR8iOAL6lnZUVwj52mmmm959T2MM2IrNpdShpieZvSVa7evmIopMI91fw2gNJ6VmtMnl1aiRpFxpUExX8tf8V8ODx0EsSJgVbskIIfAoKmpfpJKT901cra8FnrcI11YR7_MEm0BhZ1beZBRzt0x2J0RXMtNMkCdToat8g5aCI',
                    ),
                    _buildCurrencyTile(
                      context,
                      'CAD',
                      'Canadian Dollar',
                      '1.37',
                      false,
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuD4ivawU_M3nDz_IeamAmjJUXrGvocC8uglqcuLygUM-awyTtM3jq8uHoPekGFqv84diQwRnC40RbfpnNTYHJV_TKkp_F_bvjEeVu3HiyTrJdWEnb_u-k3O-LSKEU1o8rP2ftcPuNdEx69mPxft_9JgUBKMBdhFRInhbwLppD9_qofrqrtFMH-JrnX2U-NTzwpDNTAe756XBVghsGRq0iUKUSEIAnaiD9rvcHfVQ6Eyb1SbWbroFW5_14uBnQQ-kgbAqY0peN1tkxk',
                    ),
                    _buildCurrencyTile(
                      context,
                      'AUD',
                      'Australian Dollar',
                      '1.51',
                      true,
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBhkFTE1uu_kfh-2qJSJChORE2vs5l1jxlkXAyVh9KxVoto2QlreJKfOIMMZqKw39VCxVYP8xP7jRezlgUa_akauWJo3Ksv6KvyXXcSKyNz7P86oc0bcgl5xgHCqUpO7W6wK65pn6kS0OjeQSsZZ3EfonxfoR7B5c2TfFrQ-ZnKVdQlMVzg4vxStZYsgw9A3Tjo35GcgrPcpbcFnG02CXzKuFymZKbAZNsLYIcUF9aoi6I-YxwrTXGO4mfc2AcllgE-9tQ-0cETc8w',
                    ),
                    _buildCurrencyTile(
                      context,
                      'CHF',
                      'Swiss Franc',
                      '0.90',
                      false,
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCPp2cIkvkozGtbQqFGsHViQqiRolrzbAcaXF9h-uQ3bQRU-8T6ywSiT8-zG795FNwcX-VG0-dR3pb3xv_xJ9bapLuJvQNqfm8ySifspH3HxWgYXC7ZnUj9-jF-IChI4YsxYjRWr1DzwU0Kcy1OagJ9TYUmY0K1VNZRtiru0T5fcWbFq8ZsbDXa-GqGWyh7rXK269k_VMh8rLj3_Zc7iR3mF0sXM8pr8xY70COfR-78gne12gn0JhZfEo_wj8yrZfi7DEks2E8ZHHg',
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const Text(
                  'Rates are for informational purposes only.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyTile(
    BuildContext context,
    String code,
    String name,
    String rate,
    bool isTrendUp,
    String flagUrl,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(flagUrl),
      ),
      title: Text(code),
      subtitle: Text(name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rate,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Icon(
            isTrendUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: isTrendUp ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}

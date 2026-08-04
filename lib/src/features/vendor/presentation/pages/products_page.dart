// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/async_value_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/vendor_scaffold.dart';
import '../../../../core/widgets/vendor_page_intro.dart';
import '../../data/vendor_providers.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  String search = '';
  String status = 'all';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(vendorProductsProvider);
    return VendorScaffold(
      title: 'My Products',
      actions: [
        IconButton(
          tooltip: 'Import CSV',
          onPressed: () => _importCsv(context, ref),
          icon: const Icon(Icons.upload_file_rounded),
        ),
        IconButton(
          tooltip: 'Add Product',
          onPressed: () => _showProductForm(context, ref),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: products.whenUi(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          final filtered = items.where((p) {
            final matchesSearch = search.isEmpty ||
                (p['title'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(search.toLowerCase());
            final matchesStatus = status == 'all' || p['status'] == status;
            return matchesSearch && matchesStatus;
          }).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(vendorProductsProvider.future),
            child: ListView(
              padding: VendorLayout.pagePadding(context),
              children: [
                VendorPageIntro(
                  icon: Icons.inventory_2_rounded,
                  title: '${items.length} products in your catalog',
                  subtitle:
                      'Keep pricing, stock, media and approval status current.',
                  trailing: IconButton.filled(
                    tooltip: 'Add product',
                    onPressed: () => _showProductForm(context, ref),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            hintText: 'Search products...'),
                        onChanged: (v) => setState(() => search = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(
                            value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(
                            value: 'inactive', child: Text('Inactive')),
                        DropdownMenuItem(
                            value: 'pending_approval', child: Text('Pending')),
                      ],
                      onChanged: (v) => setState(() => status = v ?? 'all'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products found',
                      subtitle: 'Add your first product or clear filters.')
                else
                  ...filtered.map((p) => CatalogTile(
                        item: p,
                        fallbackIcon: Icons.inventory_2_rounded,
                        onView: () => _viewProduct(context, ref, p),
                        onEdit: () => _showProductForm(context, ref, item: p),
                        onDelete: () =>
                            _delete(context, ref, p['id'].toString()),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _viewProduct(
      BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    var product = item;
    try {
      product = await ref
          .read(vendorRepositoryProvider)
          .product(item['id'].toString());
    } catch (_) {
      // Keep the already loaded list data as a read-only fallback.
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .78,
        maxChildSize: .94,
        minChildSize: .5,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            const Text('Product details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const Text('Read-only catalog information',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            if ((product['image'] ?? product['thumbnail_image'])
                .toString()
                .isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  (product['image'] ?? product['thumbnail_image']).toString(),
                  height: 190,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 16),
            Text(product['title']?.toString() ?? 'Untitled product',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _ProductDetail(label: 'SKU', value: product['sku']),
              _ProductDetail(label: 'Status', value: product['status']),
              _ProductDetail(label: 'Price', value: product['price']),
              _ProductDetail(label: 'Discount', value: product['discount']),
              _ProductDetail(label: 'Tax', value: product['tax']),
              _ProductDetail(label: 'Stock', value: product['stock']),
              _ProductDetail(
                  label: 'Category', value: product['category_name']),
              _ProductDetail(
                  label: 'Product type', value: product['product_type']),
            ]),
            const SizedBox(height: 18),
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SelectableText(
              (product['long_description'] ??
                      product['short_description'] ??
                      product['description'] ??
                      'No description provided.')
                  .toString(),
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
            if (product['variations'] is List &&
                (product['variations'] as List).isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('Variations',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...(product['variations'] as List).map((variation) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(variation.toString()),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content:
            const Text('This removes the product from your vendor catalog.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(vendorRepositoryProvider).deleteProduct(id);
    ref.invalidate(vendorProductsProvider);
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    final vendorId = ref.read(vendorIdProvider);
    if (vendorId == null) return;
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true);
    if (result == null) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;
    final text = String.fromCharCodes(bytes);
    final lines =
        text.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 2) return;
    final headers =
        _csvSplit(lines.first).map((h) => h.trim().toLowerCase()).toList();
    var imported = 0;
    for (var i = 1; i < lines.length; i++) {
      final values = _csvSplit(lines[i]);
      final row = <String, String>{};
      for (var j = 0; j < headers.length; j++) {
        row[headers[j]] = j < values.length ? values[j].trim() : '';
      }
      final title = row['title'] ?? row['name'] ?? '';
      if (title.isEmpty) continue;
      await ref.read(vendorRepositoryProvider).upsertProduct(vendorId, {
        'title': title,
        'description': row['description'] ?? '',
        'short_description':
            row['short_description'] ?? row['description'] ?? '',
        'long_description': row['long_description'] ?? row['description'] ?? '',
        'price': row['price'] ?? '0',
        'tax': row['tax'] ?? '0',
        'discount': row['discount'] ?? '0',
        'stock': row['stock'] ?? '0',
        'sku': row['sku'],
        'emoji': row['emoji'],
        'image': row['image']?.isEmpty == true ? null : row['image'],
        'category_name': row['category'] ?? '',
        'status': 'draft',
      });
      imported++;
    }
    ref.invalidate(vendorProductsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$imported products imported')));
    }
  }

  List<String> _csvSplit(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        quoted = !quoted;
      } else if (c == ',' && !quoted) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(c);
      }
    }
    values.add(buffer.toString());
    return values;
  }
}

Future<void> _showProductForm(BuildContext context, WidgetRef ref,
    {Map<String, dynamic>? item}) async {
  final vendorId = ref.read(vendorIdProvider);
  if (vendorId == null || vendorId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vendor session is not ready. Please sign in again.'),
      ),
    );
    return;
  }
  final editingId = item?['id']?.toString();
  if (item != null && item['id'] != null) {
    try {
      item = await ref
          .read(vendorRepositoryProvider)
          .product(item['id'].toString());
    } catch (_) {
      // Keep the list row as an offline-safe edit fallback.
    }
  }
  if (!context.mounted) return;
  List<Map<String, dynamic>> categories = const [];
  try {
    categories = await ref
        .read(vendorRepositoryProvider)
        .registrationProductCategories();
  } catch (_) {
    // Saving remains available for an existing category if catalog refresh fails.
  }
  if (!context.mounted) return;
  final title = TextEditingController(text: item?['title']?.toString() ?? '');
  final sku = TextEditingController(text: item?['sku']?.toString() ?? '');
  final price = TextEditingController(text: item?['price']?.toString() ?? '');
  final tax = TextEditingController(text: item?['tax']?.toString() ?? '0');
  final discount =
      TextEditingController(text: item?['discount']?.toString() ?? '0');
  final stock = TextEditingController(text: item?['stock']?.toString() ?? '');
  final shortDescription =
      TextEditingController(text: item?['short_description']?.toString() ?? '');
  final longDescription =
      TextEditingController(text: item?['long_description']?.toString() ?? '');
  final image = TextEditingController(text: item?['image']?.toString() ?? '');
  final thumbnail =
      TextEditingController(text: item?['thumbnail_image']?.toString() ?? '');
  final banner =
      TextEditingController(text: item?['banner_image']?.toString() ?? '');
  final youtube =
      TextEditingController(text: item?['youtube_video_url']?.toString() ?? '');
  final category =
      TextEditingController(text: item?['category_id']?.toString() ?? '');
  final subcategory =
      TextEditingController(text: item?['subcategory_id']?.toString() ?? '');
  final parentItem =
      TextEditingController(text: item?['parent_item_id']?.toString() ?? '');
  final variations =
      TextEditingController(text: _variationText(item?['variations']));
  var productType = item?['product_type']?.toString() ?? 'simple';
  var status = item?['status']?.toString() ?? 'draft';
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.viewInsetsOf(sheetContext).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item == null ? 'Add Product' : 'Edit Product',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title *')),
            const SizedBox(height: 10),
            TextField(
                controller: sku,
                decoration: const InputDecoration(labelText: 'SKU *')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Price Rs. *'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock *'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: tax,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tax'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: discount,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Discount'))),
            ]),
            const SizedBox(height: 10),
            TextField(
                controller: shortDescription,
                decoration:
                    const InputDecoration(labelText: 'Short Description *')),
            const SizedBox(height: 10),
            TextField(
                controller: longDescription,
                minLines: 3,
                maxLines: 5,
                decoration:
                    const InputDecoration(labelText: 'Long Description *')),
            const SizedBox(height: 10),
            TextField(
                controller: image,
                decoration: const InputDecoration(labelText: 'Image URL')),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final url = await pickVendorImage(ref, vendorId, 'products');
                if (url != null) image.text = url;
              },
              icon: const Icon(Icons.image_rounded),
              label: const Text('Upload Product Image'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: categories.any(
                      (row) => row['id']?.toString() == category.text)
                  ? category.text
                  : null,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map((row) => DropdownMenuItem(
                        value: row['id']?.toString(),
                        child: Text(row['name']?.toString() ?? 'Category'),
                      ))
                  .toList(),
              onChanged: (value) => category.text = value ?? '',
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: thumbnail,
                      decoration:
                          const InputDecoration(labelText: 'Thumbnail URL'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: banner,
                      decoration:
                          const InputDecoration(labelText: 'Banner URL'))),
            ]),
            const SizedBox(height: 10),
            TextField(
                controller: youtube,
                keyboardType: TextInputType.url,
                decoration:
                    const InputDecoration(labelText: 'YouTube Video URL')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: productType,
              decoration: const InputDecoration(labelText: 'Product Type'),
              items: const [
                DropdownMenuItem(value: 'simple', child: Text('Simple')),
                DropdownMenuItem(value: 'variable', child: Text('Variable')),
                DropdownMenuItem(value: 'service', child: Text('Service')),
              ],
              onChanged: (v) => productType = v ?? productType,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: variations,
              minLines: 3,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Variation rows',
                helperText:
                    'Variable products: attributes; SKU; price; stock. Example: Color=Red, Size=M; RED-M; 499; 10',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => status = v ?? status,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty ||
                    sku.text.trim().isEmpty ||
                    price.text.trim().isEmpty ||
                    stock.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Title, SKU, price and stock are required.'),
                    ),
                  );
                  return;
                }
                final parsedPrice = double.tryParse(price.text.trim());
                final parsedStock = int.tryParse(stock.text.trim());
                if (parsedPrice == null ||
                    parsedPrice < 0 ||
                    parsedStock == null ||
                    parsedStock < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid price and stock quantity.'),
                    ),
                  );
                  return;
                }
                try {
                  await ref.read(vendorRepositoryProvider).upsertProduct(
                        vendorId,
                        {
                          'title': title.text.trim(),
                          'sku': sku.text.trim(),
                          'price': price.text.trim(),
                          'tax': tax.text.trim(),
                          'discount': discount.text.trim(),
                          'stock': stock.text.trim(),
                          'short_description': shortDescription.text.trim(),
                          'long_description': longDescription.text.trim(),
                          'description': longDescription.text.trim(),
                          'image': image.text.trim().isEmpty
                              ? null
                              : image.text.trim(),
                          'images': image.text.trim().isEmpty
                              ? <String>[]
                              : <String>[image.text.trim()],
                          'thumbnail_image': thumbnail.text.trim().isEmpty
                              ? null
                              : thumbnail.text.trim(),
                          'banner_image': banner.text.trim().isEmpty
                              ? null
                              : banner.text.trim(),
                          'youtube_video_url': youtube.text.trim(),
                          'category_id': category.text.trim().isEmpty
                              ? null
                              : category.text.trim(),
                          'subcategory_id': subcategory.text.trim().isEmpty
                              ? null
                              : subcategory.text.trim(),
                          'parent_item_id': parentItem.text.trim().isEmpty
                              ? null
                              : parentItem.text.trim(),
                          'product_type': productType,
                          'variations': productType == 'variable'
                              ? _parseVariationLines(variations.text)
                              : <Map<String, dynamic>>[],
                          'status': item == null ? 'pending_approval' : status,
                          'metadata': item?['metadata'],
                        },
                        id: editingId,
                      );
                  ref.invalidate(vendorProductsProvider);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(item == null
                            ? 'Product submitted for approval.'
                            : 'Product updated successfully.'),
                      ),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not save product: $error')),
                    );
                  }
                }
              },
              child:
                  Text(item == null ? 'Submit for Approval' : 'Update Product'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _variationText(Object? raw) {
  if (raw is! List) return '';
  return raw.whereType<Map>().map((row) {
    final attrs = row['attributes'] is Map
        ? Map<String, dynamic>.from(row['attributes'] as Map)
        : <String, dynamic>{};
    final attrText = attrs.entries
        .map((e) => e.key.toString() + '=' + e.value.toString())
        .join(', ');
    return attrText +
        '; ' +
        (row['sku'] ?? '').toString() +
        '; ' +
        (row['sellPrice'] ?? row['finalPrice'] ?? '').toString() +
        '; ' +
        (row['quantity'] ?? 0).toString();
  }).join('\n');
}

List<Map<String, dynamic>> _parseVariationLines(String raw) {
  final rows = <Map<String, dynamic>>[];
  for (final line in raw.split('\n')) {
    final parts = line.split(';').map((v) => v.trim()).toList();
    if (parts.isEmpty || parts.first.isEmpty) continue;
    final attributes = <String, String>{};
    for (final pair in parts.first.split(',')) {
      final index = pair.indexOf('=');
      if (index <= 0) continue;
      final key = pair.substring(0, index).trim();
      final value = pair.substring(index + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) attributes[key] = value;
    }
    if (attributes.isEmpty) continue;
    final price = parts.length > 2 ? double.tryParse(parts[2]) ?? 0 : 0;
    rows.add({
      'attributes': attributes,
      'sku': parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
      'sellPrice': price,
      'finalPrice': price,
      'discountAmount': 0,
      'quantity': parts.length > 3 ? int.tryParse(parts[3]) ?? 0 : 0,
      'isActive': true,
      'sortOrder': rows.length,
    });
  }
  return rows;
}

Future<String?> pickVendorImage(
    WidgetRef ref, String vendorId, String folder) async {
  final picked = await ImagePicker()
      .pickImage(source: ImageSource.gallery, imageQuality: 82);
  if (picked == null) return null;
  return ref.read(vendorRepositoryProvider).uploadVendorAsset(
        vendorId,
        File(picked.path),
        folder,
        picked.name,
        picked.mimeType ?? 'image/jpeg',
      );
}

class CatalogTile extends StatelessWidget {
  const CatalogTile(
      {required this.item,
      required this.fallbackIcon,
      required this.onView,
      required this.onEdit,
      required this.onDelete,
      super.key});
  final Map<String, dynamic> item;
  final IconData fallbackIcon;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.', decimalDigits: 0);
    final image = item['image']?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(10),
        onTap: onView,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 74,
                height: 74,
                color: AppColors.productSurface,
                child: image != null && image.isNotEmpty
                    ? Image.network(image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(fallbackIcon))
                    : Icon(fallbackIcon),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(item['title']?.toString() ?? 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                    StatusBadge(item['status']?.toString() ?? 'draft'),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    Text(currency.format(item['price'] ?? 0),
                        style: const TextStyle(
                            color: AppColors.brandDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.navySoft,
                          borderRadius: BorderRadius.circular(7)),
                      child: Text('Stock ${item['stock'] ?? 0}',
                          style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: Colors.white,
              onSelected: (v) {
                if (v == 'view') return onView();
                if (v == 'edit') return onEdit();
                onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'view', child: Text('View')),
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetail extends StatelessWidget {
  const _ProductDetail({required this.label, required this.value});
  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) => Container(
        width:
            ((MediaQuery.sizeOf(context).width - 70) / 2).clamp(118.0, 220.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 3),
          Text(value?.toString().isNotEmpty == true ? value.toString() : '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}

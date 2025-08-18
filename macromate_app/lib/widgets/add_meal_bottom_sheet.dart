import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/macro_provider.dart';
import '../providers/theme_provider.dart';

class AddMealBottomSheet extends StatefulWidget {
  const AddMealBottomSheet({super.key});

  @override
  State<AddMealBottomSheet> createState() => _AddMealBottomSheetState();
}

class _AddMealBottomSheetState extends State<AddMealBottomSheet> {
  final _foodController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void dispose() {
    _foodController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _addMealFromText() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final macroProvider = Provider.of<MacroProvider>(context, listen: false);
    final success = await macroProvider.addMacroEntry(
      _foodController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add meal: ${macroProvider.error}'),
            backgroundColor: Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).getErrorColor(context),
          ),
        );
      }
    }
  }

  Future<void> _addMealFromImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image == null) return;

      // If taken from camera, save to gallery in an album where supported
      if (source == ImageSource.camera) {
        try {
          if (await Gal.hasAccess(toAlbum: true) == false) {
            await Gal.requestAccess(toAlbum: true);
          }
          await Gal.putImage(image.path, album: 'MacroMate');
        } catch (_) {
          // Ignore failures to avoid blocking user flow
        }
      }

      setState(() => _isLoading = true);

      final imageBytes = await image.readAsBytes();
      final macroProvider = Provider.of<MacroProvider>(context, listen: false);

      final success = await macroProvider.addMacroEntryFromImage(
        imageBytes,
        _weightController.text.trim().isEmpty
            ? null
            : _weightController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal added from image successfully!'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to process image: ${macroProvider.error}'),
              backgroundColor: Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).getErrorColor(context),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).getErrorColor(context),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Add Meal',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Method selection buttons
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: 'Describe your food in text',
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _showTextInputDialog(),
                    icon: const Icon(Icons.text_fields, size: 18),
                    label: const FittedBox(child: Text('Text')),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: 'Scan a nutrition label photo',
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _showImageInputDialog(),
                    icon: const Icon(Icons.photo_camera, size: 18),
                    label: const FittedBox(child: Text('Label')),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: 'Scan a product barcode',
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _showBarcodeDialog(),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const FittedBox(child: Text('Barcode')),
                  ),
                ),
              ),
            ],
          ),

          if (_isLoading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            Text(
              'Processing...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showTextInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Describe Your Food'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _foodController,
            decoration: const InputDecoration(
              hintText: 'e.g., 100g chicken breast with rice',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please describe your food';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addMealFromText();
            },
            child: const Text('Add Meal'),
          ),
        ],
      ),
    );
  }

  void _showImageInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Nutrition Label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Take a photo of the nutrition label or select from your photos, and optionally specify the weight.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (optional)',
                hintText: 'e.g., 150g',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _addMealFromImage(ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _addMealFromImage(ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBarcodeDialog() {
    showDialog(
      context: context,
      builder: (context) => _BarcodeScanDialog(
        onResult: (barcode) {
          Navigator.of(context).pop();
          _showBarcodeWeightDialog(barcode);
        },
      ),
    );
  }

  void _showBarcodeWeightDialog(String barcode) {
    final weightController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barcode Weight'),
        content: TextField(
          controller: weightController,
          decoration: const InputDecoration(
            labelText: 'Weight in g (optional)',
            hintText: 'e.g., 150',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);
              final macroProvider = Provider.of<MacroProvider>(
                context,
                listen: false,
              );
              final success = await macroProvider.addMacroEntryFromBarcode(
                barcode,
                weightController.text.trim().isEmpty
                    ? null
                    : weightController.text.trim(),
              );
              setState(() => _isLoading = false);
              if (mounted) {
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meal added from barcode!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to add meal from barcode: \'${macroProvider.error}\'',
                      ),
                      backgroundColor: Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).getErrorColor(context),
                    ),
                  );
                }
              }
            },
            child: const Text('Add Meal'),
          ),
        ],
      ),
    );
  }
}

class _BarcodeScanDialog extends StatefulWidget {
  final Function(String barcode) onResult;
  const _BarcodeScanDialog({required this.onResult});

  @override
  State<_BarcodeScanDialog> createState() => _BarcodeScanDialogState();
}

class _BarcodeScanDialogState extends State<_BarcodeScanDialog> {
  String? _detected;
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan Barcode'),
      content: SizedBox(
        width: 300,
        height: 350,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Lazy import to avoid requiring camera permission until needed
                    FutureBuilder(
                      future: _loadScanner(),
                      builder: (ctx, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return snap.data as Widget; // MobileScanner widget
                      },
                    ),
                    if (_detected != null)
                      Container(
                        color: Colors.black.withOpacity(0.6),
                        alignment: Alignment.center,
                        child: Text(
                          'Detected: $_detected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _detected == null
                  ? 'Align the barcode within the frame'
                  : 'Press Confirm to proceed',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _detected == null || _processing
              ? null
              : () async {
                  setState(() => _processing = true);
                  final code = _detected!;
                  widget.onResult(code);
                },
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Future<Widget> _loadScanner() async {
    return MobileScanner(
      onDetect: (capture) {
        if (_detected != null) return;
        for (final barcode in capture.barcodes) {
          final raw = barcode.rawValue;
          if (raw != null && raw.length >= 6) {
            setState(() => _detected = raw);
            break;
          }
        }
      },
    );
  }
}

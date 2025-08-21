import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/macro_provider.dart';

class GeminiUsageGate extends StatefulWidget {
  final Widget child;
  final VoidCallback onGeminiAllowed;
  const GeminiUsageGate({
    super.key,
    required this.child,
    required this.onGeminiAllowed,
  });

  @override
  State<GeminiUsageGate> createState() => _GeminiUsageGateState();
}

class _GeminiUsageGateState extends State<GeminiUsageGate> {
  bool _showAdPrompt = false;
  bool _loadingAd = false;
  String? _adError;

  @override
  Widget build(BuildContext context) {
    return Consumer<MacroProvider>(
      builder: (context, macroProvider, child) {
        if (macroProvider.adFree || macroProvider.geminiUses < 3) {
          // Allow Gemini usage
          return widget.child;
        }
        return Center(
          child: _showAdPrompt
              ? _buildAdPrompt(context, macroProvider)
              : ElevatedButton(
                  onPressed: _loadingAd
                      ? null
                      : () async {
                          setState(() {
                            _loadingAd = true;
                            _adError = null;
                          });
                          macroProvider.loadRewardedAd(() {
                            setState(() {
                              _loadingAd = false;
                              _showAdPrompt = true;
                            });
                          });
                        },
                  child: _loadingAd
                      ? const CircularProgressIndicator()
                      : const Text('Watch Ad to get 10 more Gemini uses'),
                ),
        );
      },
      child: widget.child,
    );
  }

  Widget _buildAdPrompt(BuildContext context, MacroProvider macroProvider) {
    return AlertDialog(
      title: const Text('Gemini Usage Limit'),
      content: Text(
        _adError ?? 'Watch a rewarded ad to get 10 more Gemini uses.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _showAdPrompt = false;
            });
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: macroProvider.isRewardedAdLoaded
              ? () {
                  macroProvider.showRewardedAd(
                    onRewarded: () async {
                      await macroProvider.incrementGeminiUses(increment: 10);
                      setState(() {
                        _showAdPrompt = false;
                        _adError = null;
                      });
                      widget.onGeminiAllowed();
                    },
                    onClosed: () {
                      setState(() {
                        _showAdPrompt = false;
                      });
                    },
                    onFailed: () {
                      setState(() {
                        _adError = 'Failed to show ad. Please try again.';
                      });
                    },
                  );
                }
              : null,
          child: const Text('Show Ad'),
        ),
      ],
    );
  }
}

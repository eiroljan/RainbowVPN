import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows the card payment bottom sheet and returns `true` if payment was
/// confirmed (the caller should then proceed to subscribe), or `null`/`false`
/// if the user dismissed without paying.
Future<bool> showPaymentSheet(
  BuildContext context, {
  required double amount,
  required String planName,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSheet(amount: amount, planName: planName),
  );
  return result == true;
}

// ─────────────────────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final double amount;
  final String planName;

  const _PaymentSheet({required this.amount, required this.planName});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController     = TextEditingController();
  final _cvvController        = TextEditingController();

  final _cardNumberFocus  = FocusNode();
  final _cardHolderFocus  = FocusNode();
  final _expiryFocus      = FocusNode();
  final _cvvFocus         = FocusNode();

  bool _paying = false;
  bool _cvvObscure = true;
  _CardType _cardType = _CardType.unknown;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    _cardNumberController.addListener(_detectCardType);
  }

  @override
  void dispose() {
    _animController.dispose();
    _cardNumberController
      ..removeListener(_detectCardType)
      ..dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNumberFocus.dispose();
    _cardHolderFocus.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  // ── Card type detection ────────────────────────────────────────────────────

  void _detectCardType() {
    final raw = _cardNumberController.text.replaceAll(' ', '');
    _CardType type;
    if (raw.startsWith('4')) {
      type = _CardType.visa;
    } else if (raw.startsWith('5') || raw.startsWith('2')) {
      type = _CardType.mastercard;
    } else if (raw.startsWith('34') || raw.startsWith('37')) {
      type = _CardType.amex;
    } else {
      type = _CardType.unknown;
    }
    if (type != _cardType) setState(() => _cardType = type);
  }

  // ── Payment action ─────────────────────────────────────────────────────────

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _paying = true);
    // Simulate processing delay (replace with real gateway call later)
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _paying = false);
    Navigator.pop(context, true);
  }

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _validateCard(String? v) {
    final raw = (v ?? '').replaceAll(' ', '');
    if (raw.isEmpty) return 'Card number is required';
    if (raw.length < 13 || raw.length > 19) return 'Enter a valid card number';
    return null;
  }

  String? _validateHolder(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Cardholder name is required';
    return null;
  }

  String? _validateExpiry(String? v) {
    final raw = (v ?? '').trim();
    if (raw.length < 5) return 'Enter MM/YY';
    final parts = raw.split('/');
    if (parts.length != 2) return 'Enter MM/YY';
    final month = int.tryParse(parts[0]);
    final year  = int.tryParse(parts[1]);
    if (month == null || year == null) return 'Enter MM/YY';
    if (month < 1 || month > 12) return 'Invalid month';
    final now    = DateTime.now();
    final expiry = DateTime(2000 + year, month + 1);
    if (expiry.isBefore(now)) return 'Card has expired';
    return null;
  }

  String? _validateCvv(String? v) {
    final raw = (v ?? '').trim();
    if (raw.isEmpty) return 'CVV is required';
    final isAmex = _cardType == _CardType.amex;
    if (isAmex && raw.length != 4) return '4 digits for Amex';
    if (!isAmex && raw.length != 3) return '3 digits required';
    return null;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF181F5E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(24, 0, 24, mq.viewInsets.bottom + 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle ──
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5C3BFF), Color(0xFF3B20CC)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.credit_card_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Secure Payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.planName,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C77A).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF00C77A).withOpacity(0.4)),
                      ),
                      child: Text(
                        '\$${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF00E5A0),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Mini card preview ──
                _buildCardPreview(),

                const SizedBox(height: 24),

                // ── Form ──
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Card number
                      _buildField(
                        controller: _cardNumberController,
                        focusNode: _cardNumberFocus,
                        nextFocus: _cardHolderFocus,
                        label: 'Card Number',
                        hint: '1234 5678 9012 3456',
                        icon: Icons.credit_card_rounded,
                        suffixIcon: _cardTypeIcon(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CardNumberFormatter(),
                        ],
                        maxLength: 19,
                        validator: _validateCard,
                      ),
                      const SizedBox(height: 14),

                      // Cardholder name
                      _buildField(
                        controller: _cardHolderController,
                        focusNode: _cardHolderFocus,
                        nextFocus: _expiryFocus,
                        label: 'Cardholder Name',
                        hint: 'JOHN DOE',
                        icon: Icons.person_rounded,
                        keyboardType: TextInputType.name,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]')),
                          _UpperCaseFormatter(),
                        ],
                        validator: _validateHolder,
                      ),
                      const SizedBox(height: 14),

                      // Expiry + CVV row
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _expiryController,
                              focusNode: _expiryFocus,
                              nextFocus: _cvvFocus,
                              label: 'Expiry',
                              hint: 'MM/YY',
                              icon: Icons.calendar_today_rounded,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                _ExpiryFormatter(),
                              ],
                              maxLength: 5,
                              validator: _validateExpiry,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _cvvController,
                              focusNode: _cvvFocus,
                              label: 'CVV',
                              hint: _cardType == _CardType.amex
                                  ? '••••'
                                  : '•••',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _cvvObscure,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              maxLength:
                                  _cardType == _CardType.amex ? 4 : 3,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _cvvObscure = !_cvvObscure),
                                child: Icon(
                                  _cvvObscure
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                              ),
                              validator: _validateCvv,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Pay button ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _paying ? null : _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: _paying
                            ? const LinearGradient(colors: [
                                Color(0xFF2A3280),
                                Color(0xFF2A3280),
                              ])
                            : const LinearGradient(
                                colors: [
                                  Color(0xFF6A4FFF),
                                  Color(0xFF3B20CC),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _paying
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF5C3BFF)
                                      .withOpacity(0.45),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _paying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white70,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_rounded,
                                      color: Colors.white70, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pay \$${widget.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Security note ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.shield_rounded,
                        color: Colors.white38, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Secured with 256-bit SSL encryption',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Card preview ───────────────────────────────────────────────────────────

  Widget _buildCardPreview() {
    final rawNumber = _cardNumberController.text.replaceAll(' ', '');
    final displayNumber = _formatDisplayNumber(rawNumber);
    final holder = _cardHolderController.text.isEmpty
        ? 'YOUR NAME'
        : _cardHolderController.text;
    final expiry =
        _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 170,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _cardGradient(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _cardGradient().first.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: 40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card network logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.wifi_rounded,
                        color: Colors.white54, size: 22),
                    _cardNetworkWidget(),
                  ],
                ),

                const Spacer(),

                // Card number
                Text(
                  displayNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    fontFamily: 'monospace',
                  ),
                ),

                const SizedBox(height: 10),

                // Holder + Expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CARD HOLDER',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 9,
                                letterSpacing: 1)),
                        Text(
                          holder.length > 18
                              ? holder.substring(0, 18)
                              : holder,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('EXPIRES',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 9,
                                letterSpacing: 1)),
                        Text(
                          expiry,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayNumber(String raw) {
    final padded = raw.padRight(16, '•');
    final masked = padded.length > 16 ? padded.substring(0, 16) : padded;
    final groups = <String>[];
    for (var i = 0; i < 16; i += 4) {
      groups.add(masked.substring(i, (i + 4).clamp(0, 16)));
    }
    return groups.join('  ');
  }

  List<Color> _cardGradient() {
    switch (_cardType) {
      case _CardType.visa:
        return [const Color(0xFF1A237E), const Color(0xFF283593)];
      case _CardType.mastercard:
        return [const Color(0xFF880E4F), const Color(0xFFAD1457)];
      case _CardType.amex:
        return [const Color(0xFF004D40), const Color(0xFF00796B)];
      case _CardType.unknown:
        return [const Color(0xFF3B20CC), const Color(0xFF5C3BFF)];
    }
  }

  Widget _cardNetworkWidget() {
    switch (_cardType) {
      case _CardType.visa:
        return const Text(
          'VISA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            letterSpacing: 2,
          ),
        );
      case _CardType.mastercard:
        return Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.85),
              ),
            ),
            Transform.translate(
              offset: const Offset(-10, 0),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withOpacity(0.75),
                ),
              ),
            ),
          ],
        );
      case _CardType.amex:
        return const Text(
          'AMEX',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        );
      case _CardType.unknown:
        return const Icon(Icons.credit_card_rounded,
            color: Colors.white38, size: 26);
    }
  }

  Widget? _cardTypeIcon() {
    switch (_cardType) {
      case _CardType.visa:
        return const Text(
          'VISA',
          style: TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1,
          ),
        );
      case _CardType.mastercard:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.red),
            ),
            Transform.translate(
              offset: const Offset(-5, 0),
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.orange),
              ),
            ),
          ],
        );
      case _CardType.amex:
        return const Text(
          'AMEX',
          style: TextStyle(
            color: Color(0xFF004D40),
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1,
          ),
        );
      case _CardType.unknown:
        return null;
    }
  }

  // ── Generic field builder ──────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      maxLength: maxLength,
      validator: validator,
      textInputAction:
          nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFF8A6FFF),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        labelStyle:
            const TextStyle(color: Colors.white54, fontSize: 13),
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF7A5FFF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFF5C5C), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFF5C5C), width: 1.5),
        ),
        errorStyle:
            const TextStyle(color: Color(0xFFFF7C7C), fontSize: 11),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

enum _CardType { unknown, visa, mastercard, amex }

/// Formats card number as groups of 4 digits separated by spaces.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) text = text.substring(0, 16);

    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats expiry as MM/YY.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 4) text = text.substring(0, 4);

    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Converts input to upper case.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

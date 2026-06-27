import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyForm extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final IconData? prefixIcon;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const MyForm({
    super.key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  bool _showClearIcon = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller;

    _focusNode = widget.focusNode ?? FocusNode();

    _checkText();

    _controller.addListener(() {
      _capitalizeText();
      _checkText();
    });
  }

  @override
  void didUpdateWidget(MyForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_checkText);
      _controller = widget.controller;
      _checkText();
      _controller.addListener(() {
        _capitalizeText();
        _checkText();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkText);

    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  void _checkText() {
    final visible = _controller.text.isNotEmpty;

    if (visible != _showClearIcon) {
      setState(() {
        _showClearIcon = visible;
      });
    }
  }

  void _clearText() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _focusNode.requestFocus();
      },
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              /// BACKDROP BLUR
              IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: const SizedBox(),
                ),
              ),

              /// GLASS LAYER
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),

                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: .22),

                      Colors.white.withValues(alpha: .10),
                    ],
                  ),

                  border: Border.all(
                    color: Colors.white.withValues(alpha: .25),
                    width: 0.8,
                  ),

                  boxShadow: [
                    /// shadow luar
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),

                    /// glow putih
                    BoxShadow(
                      color: Colors.white.withValues(alpha: .08),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),

              /// TOP HIGHLIGHT
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 0,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: .28),

                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// TEXT FIELD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    /// SEARCH ICON
                    Padding(
                      padding: const EdgeInsets.only(left: 6, right: 5),
                      child: Icon(
                        widget.prefixIcon,
                        size: 28,
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ),

                    /// TEXT INPUT
                    Expanded(
                      child: TextField(
                        focusNode: _focusNode,
                        controller: _controller,
                        obscureText: widget.obscureText,
                        keyboardType: widget.keyboardType,
                        inputFormatters: widget.inputFormatters,

                        textAlignVertical: TextAlignVertical.center,

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),

                        cursorColor: Colors.white,

                        decoration: InputDecoration(
                          isDense: true,

                          border: InputBorder.none,

                          contentPadding: const EdgeInsets.only(right: 16),

                          hintText: widget.hintText,

                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: .65),
                            fontSize: 15,
                          ),

                          suffixIcon: _showClearIcon
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 0),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.white,
                                    ),
                                    onPressed: _clearText,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _capitalizeText() {
    if (_controller.text.isEmpty) return;

    final words = _controller.text.split(' ');

    final result = words
        .map((word) {
          if (word.isEmpty) return word;

          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');

    if (result != _controller.text) {
      _controller.value = TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
    }
  }
}

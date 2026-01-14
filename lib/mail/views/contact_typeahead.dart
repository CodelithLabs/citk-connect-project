// lib/mail/views/contact_typeahead.dart

import 'package:flutter/material.dart';

class ContactTypeAhead extends StatefulWidget {
  final TextEditingController controller;
  final Future<List<String>> Function(String) suggestionsCallback;
  final Function(String) onSuggestionSelected;
  final InputDecoration decoration;

  const ContactTypeAhead({
    super.key,
    required this.controller,
    required this.suggestionsCallback,
    required this.onSuggestionSelected,
    this.decoration = const InputDecoration(),
  });

  @override
  State<ContactTypeAhead> createState() => _ContactTypeAheadState();
}

class _ContactTypeAheadState extends State<ContactTypeAhead> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideOverlay();
      }
    });
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.controller.text.isEmpty) {
      _hideOverlay();
      return;
    }
    widget.suggestionsCallback(widget.controller.text).then((suggestions) {
      setState(() {
        _suggestions = suggestions;
        if (_suggestions.isNotEmpty) {
          _showOverlay();
        } else {
          _hideOverlay();
        }
      });
    });
  }

  void _showOverlay() {
    if (_overlayEntry == null) {
      final renderBox = context.findRenderObject() as RenderBox;
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: offset.dx,
          top: offset.dy + size.height,
          width: size.width,
          child: Material(
            elevation: 4.0,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_suggestions[index]),
                  onTap: () {
                    widget.onSuggestionSelected(_suggestions[index]);
                    _hideOverlay();
                  },
                );
              },
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: LayerLink(),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: widget.decoration,
      ),
    );
  }
}

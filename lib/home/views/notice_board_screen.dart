import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class NoticeBoardScreen extends ConsumerStatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  ConsumerState<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends ConsumerState<NoticeBoardScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Urgent',
    'Exams',
    'Holidays',
    'Events'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1115) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Notice Board",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 🏷️ Category Filter
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (val) =>
                      setState(() => _selectedCategory = category),
                  labelStyle: GoogleFonts.inter(
                    color: isSelected ? Colors.white : textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor:
                      isDark ? const Color(0xFF1A1F3A) : Colors.white,
                  selectedColor: const Color(0xFF4285F4),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                );
              },
            ),
          ),

          // 📋 Notice List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getNoticesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Something went wrong",
                          style: GoogleFonts.inter(color: Colors.grey)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text("No notices found",
                            style: GoogleFonts.inter(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildNoticeCard(data, isDark, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getNoticesStream() {
    Query query = FirebaseFirestore.instance
        .collection('notices')
        .orderBy('timestamp', descending: true);

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots();
  }

  Widget _buildNoticeCard(Map<String, dynamic> data, bool isDark, int index) {
    final isPinned = data['isPinned'] ?? false;
    final category = data['category'] ?? 'General';
    final timestamp =
        (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dateStr = DateFormat('MMM d, y • h:mm a').format(timestamp);

    Color categoryColor;
    switch (category) {
      case 'Urgent':
        categoryColor = Colors.redAccent;
        break;
      case 'Exams':
        categoryColor = Colors.orangeAccent;
        break;
      case 'Holidays':
        categoryColor = Colors.greenAccent;
        break;
      default:
        categoryColor = const Color(0xFF4285F4);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPinned
            ? Border.all(
                color: categoryColor.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ),
              if (isPinned)
                Icon(Icons.push_pin_rounded, size: 16, color: categoryColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['title'] ?? 'Untitled Notice',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['body'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }
}

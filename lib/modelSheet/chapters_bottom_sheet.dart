import 'package:Spicify/model/book_model.dart';
import 'package:flutter/material.dart';

class ChaptersBottomSheet extends StatelessWidget {
  bool _value = false;
  int val = -1;

  buildBottomsheet(BuildContext context, List<Chapter> chapters) {
    return showModalBottomSheet(
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      context: context,
      builder: (context) {
        // 🔥 FILTER ONLY AUDIO CHAPTERS
        final audioChapters =
            chapters.where((c) => c.chapterUrl.trim().isNotEmpty).toList();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              width: MediaQuery.of(context).size.width * 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chapters',
                          style: TextStyle(
                            color: Color(0xFFF5F5FA),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFFF5F5FA),
                          ),
                          padding: const EdgeInsets.all(0),
                        )
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white, thickness: 0.5),
                  const SizedBox(height: 15),

                  // Chapter List
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child:
                        NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overScroll) {
                        overScroll.disallowIndicator();
                        return true;
                      },
                      child: ListView(
                        children: [
                          ...List.generate(
                            audioChapters.length,
                            (index) => chapterItem(
                              context,
                              audioChapters[index],
                              index,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Chapter item builder
  Widget chapterItem(BuildContext context, Chapter item, int index) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, index),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 25),
        child: Text(
          item.chapterName,
          style: const TextStyle(
            color: Color(0xFFF5F5FA),
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

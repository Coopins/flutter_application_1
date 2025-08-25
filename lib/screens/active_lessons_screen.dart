import 'package:flutter/material.dart';

class ActiveLessonsScreen extends StatefulWidget {
  const ActiveLessonsScreen({Key? key}) : super(key: key);

  @override
  State<ActiveLessonsScreen> createState() => _ActiveLessonsScreenState();
}

class _ActiveLessonsScreenState extends State<ActiveLessonsScreen> {
  final List<String> lessons = [
    'Greetings & Introductions',
    'Family and the Home',
    'Food & Dining',
    'Shopping & Numbers',
    'Work & School',
    'Travel & Transportation',
    'Health & Emergencies',
  ];

  int? selectedLessonIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Active Lessons'),
        foregroundColor: Colors.white,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Lessons',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: lessons.length,
                  separatorBuilder:
                      (context, idx) => Divider(
                        color: Colors.white24,
                        thickness: 1,
                        indent: 12,
                        endIndent: 12,
                      ),
                  itemBuilder: (context, index) {
                    final isSelected = selectedLessonIndex == index;
                    return ListTile(
                      title: Text(
                        lessons[index],
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      tileColor: isSelected ? Colors.white : Colors.black,
                      selected: isSelected,
                      selectedTileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () {
                        setState(() {
                          selectedLessonIndex = index;
                        });
                        Navigator.pop(
                          context,
                        ); // Close the drawer after selection
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child:
            selectedLessonIndex == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.play_circle_outline,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Select a lesson to begin!',
                      style: TextStyle(color: Colors.white70, fontSize: 22),
                    ),
                  ],
                )
                : Text(
                  'Lesson: ${lessons[selectedLessonIndex!]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}

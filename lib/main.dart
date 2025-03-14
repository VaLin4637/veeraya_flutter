import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEFF9F0),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CollectionReference coursesRef = FirebaseFirestore.instance.collection('Courses');

  // แสดง dialog สำหรับการเพิ่มข้อมูลคอร์ส
  void _showAddCourseDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController teacherController = TextEditingController();
    String selectedCategory = "Mobile Development";
    List<String> categories = ["Mobile Development", "Web Development", "AI/ML", "Data Science"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Course"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Course Name"),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: "Category"),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  TextField(
                    controller: teacherController,
                    decoration: const InputDecoration(labelText: "Teacher"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && teacherController.text.isNotEmpty) {
                      try {
                        await coursesRef.add({
                          "name": nameController.text,
                          "category": selectedCategory,
                          "teacher": teacherController.text,
                          "created_at": FieldValue.serverTimestamp(),
                        });
                        print("✅ Added course");
                        Navigator.pop(context);
                      } catch (e) {
                        print("Error adding course: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error adding course")),
                        );
                      }
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // แก้ไขข้อมูลคอร์ส
  void _showEditCourseDialog(String docId, String name, String teacher, String category) {
    TextEditingController teacherController = TextEditingController(text: teacher);
    String selectedCategory = category;
    List<String> categories = ["Mobile Development", "Web Development", "AI/ML", "Data Science"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Course"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: "Category"),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  TextField(
                    controller: teacherController,
                    decoration: const InputDecoration(labelText: "Teacher"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (teacherController.text.isNotEmpty) {
                      try {
                        await coursesRef.doc(docId).update({
                          "category": selectedCategory,
                          "teacher": teacherController.text,
                        });
                        print("✅ Updated course");
                        Navigator.pop(context);
                      } catch (e) {
                        print("Error updating course: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error updating course")),
                        );
                      }
                    }
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ลบคอร์สจาก Firestore
  void _deleteCourse(String docId) async {
    try {
      await coursesRef.doc(docId).delete();
      print("✅ Deleted course");
    } catch (e) {
      print("Error deleting course: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting course")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course App"),
        backgroundColor: Colors.green[300],
      ),
      body: StreamBuilder(
        stream: coursesRef.orderBy("created_at", descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Courses Found"));
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var course = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(course['name'] ?? "Unknown Course"),
                  subtitle: Text("Category: ${course['category']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditCourseDialog(doc.id, course['name'], course['teacher'], course['category']);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCourse(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

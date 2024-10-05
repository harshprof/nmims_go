import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart'; // Import your main page

class SetupScreen extends StatelessWidget {
  final TextEditingController _subjectsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup Subjects')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _subjectsController,
              decoration: InputDecoration(labelText: 'Total number of subjects'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                int totalSubjects = int.parse(_subjectsController.text);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubjectDetailsScreen(totalSubjects: totalSubjects),
                  ),
                );
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectDetailsScreen extends StatefulWidget {
  final int totalSubjects;

  SubjectDetailsScreen({required this.totalSubjects});

  @override
  _SubjectDetailsScreenState createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  List<TextEditingController> _nameControllers = [];
  List<TextEditingController> _hoursControllers = [];
  List<TextEditingController> _attendanceControllers = [];
  List<bool> _practicalChecks = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.totalSubjects; i++) {
      _nameControllers.add(TextEditingController());
      _hoursControllers.add(TextEditingController());
      _attendanceControllers.add(TextEditingController());
      _practicalChecks.add(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Subject Details')),
      body: ListView.builder(
        itemCount: widget.totalSubjects,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameControllers[index],
                  decoration: InputDecoration(labelText: 'Subject Name'),
                ),
                TextField(
                  controller: _hoursControllers[index],
                  decoration: InputDecoration(labelText: 'Total Hours'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _attendanceControllers[index],
                  decoration: InputDecoration(labelText: 'Attendance to be maintained (%)'),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _practicalChecks[index],
                      onChanged: (bool? value) {
                        setState(() {
                          _practicalChecks[index] = value!;
                        });
                      },
                    ),
                    Text('Has Practical'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.done),
        onPressed: () async {
          for (int i = 0; i < widget.totalSubjects; i++) {
            await FirebaseFirestore.instance.collection('subjects').add({
              'name': _nameControllers[i].text,
              'total_hours': int.parse(_hoursControllers[i].text),
              'attendance': int.parse(_attendanceControllers[i].text),
              'has_practical': _practicalChecks[i],
              'lecture_attended': 0,
              'practical_attended': 0,
            });
          }
          // Mark setup as complete
          await FirebaseFirestore.instance.collection('users').doc('your_user_id').set({
            'isSetupComplete': true,
          }, SetOptions(merge: true));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        },
      ),
    );
  }
}

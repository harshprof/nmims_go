import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';

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
        onPressed: () {
          for (int i = 0; i < widget.totalSubjects; i++) {
            FirebaseFirestore.instance.collection('subjects').add({
              'name': _nameControllers[i].text,
              'total_hours': int.parse(_hoursControllers[i].text),
              'attendance': int.parse(_attendanceControllers[i].text),
              'has_practical': _practicalChecks[i],
              'lecture_attended': 0,
              'practical_attended': 0,
            });
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:toast/toast.dart';
import 'package:fluttertoast/fluttertoast.dart';


class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance Tracker')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return SubjectCard(doc: doc);
            }).toList(),
          );
        },
      ),
    );
  }
}

class SubjectCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  SubjectCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    int totalLectures = doc['total_hours'];
    int attendedLectures = doc['lecture_attended'];
    int practicalsAttended = doc['practical_attended'];
    double attendanceRequired = doc['attendance'] / 100;
    int lecturesToBeAttended = (totalLectures * attendanceRequired).round() - attendedLectures;
    int lecturesRemaining = totalLectures - attendedLectures;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${doc['name']}'),
            Text('Total Hours: ${doc['total_hours']}'),
            Text('Lectures Attended: $attendedLectures'),
            Text('Practicals Attended: $practicalsAttended'),
            Text('Lectures to be Attended: $lecturesToBeAttended'),
            Text('Lectures Remaining: $lecturesRemaining'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _updateAttendance(context, doc.id, 'lecture_attended', 1),
                  child: Text('Lecture Attended'),
                ),
                ElevatedButton(
                  onPressed: () => _updateAttendance(context, doc.id, 'practical_attended', 2),
                  child: Text('Practical Attended'),
                ),
                ElevatedButton(
                  onPressed: () => _updateAttendance(context, doc.id, 'lecture_attended', -1),
                  child: Text('Lecture Missed'),
                ),
                ElevatedButton(
                  onPressed: () => _updateAttendance(context, doc.id, 'practical_attended', -2),
                  child: Text('Practical Missed'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

void _updateAttendance(BuildContext context, String docId, String field, int increment) {
  FirebaseFirestore.instance.collection('subjects').doc(docId).update({
    field: FieldValue.increment(increment),
  }).then((_) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Attendance marked successfully")),
    );
  }).catchError((error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to mark attendance: ${error.toString()}")),
    );
  });
}

}



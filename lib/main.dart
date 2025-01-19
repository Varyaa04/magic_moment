import 'package:flutter/material.dart';

void main() {
  runApp(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Magic Moment',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w100,
                fontFamily: 'irishGrover',
                color: Colors.white
              ),
              textAlign: TextAlign.center,
            ),
            backgroundColor: const Color(0xbf310b46),
          ),
          body:  Container(
            decoration: BoxDecoration(
            gradient: LinearGradient(
            colors: [
              Color(0xbf310b46),
              Color(0xbf691fc1),
              Color(0xbf310b46),
            ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            ),
            // IconButton(
            //   onPressed: (){} ,
            //   icon: const Icon(Icons.image),
            // ),
          ),
        ),
      ),
  );
}

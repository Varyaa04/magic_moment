import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';


void main() {
  runApp(const startPage());
}

class startPage extends StatelessWidget {
  const startPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color.fromARGB(255, 246, 222, 255),
        body:  Center(
            child: Row(
              children: [
                Container(
                  alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
                      color: Color.fromARGB(255,235,183,183),
                      borderRadius: BorderRadius.all(
                          Radius.circular(20)
                      )
                  ),
                  margin: const EdgeInsets.all(10),
                  height: 100,
                  width: 100,
                  child: IconButton(
                    iconSize: 50,
                    icon: const Icon(FluentIcons.image_24_regular),
                    color: Color.fromARGB(255,30,30,30),
                    onPressed:(){
                    },
                  ),
                ),
                Container(
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255,235,183,183),
                        borderRadius: BorderRadius.all(
                            Radius.circular(20)
                        )
                    ),
                    margin: const EdgeInsets.only(left: 200),
                    height: 100,
                    width: 100,
                    child:IconButton(
                      iconSize: 50,
                      icon: const Icon(FluentIcons.layout_column_two_split_left_24_regular),
                      color: Color.fromARGB(255,30,30,30),
                      onPressed:(){

                      },
                    )
                )
              ],
            )
        ),
      ),
    );
  }
}
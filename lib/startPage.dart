import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'editPage.dart';
import 'themeWidjets/buildButtonIcon.dart';
import 'package:image_picker/image_picker.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 246, 222, 255),
              Color.fromARGB(255, 255, 200, 221),
              Color.fromARGB(255, 200, 222, 255),
            ],
          ),
        ),
        child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Magic Moment',
                    style: TextStyle(
                      fontSize: 32,
                      fontFamily: 'Oi-Regular',
                      color: Color.fromARGB(255, 96, 15, 91),
                      fontWeight: FontWeight.w300,
                      shadows: [
                        Shadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 80),
                        child: Text(
                          'Что Вы хотите создать:',
                          style: TextStyle(
                            fontFamily: 'RuslanDisplay-Regular',
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            color: Color.fromARGB(255, 96, 15, 91),
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 80, left: 80),
                        padding: const EdgeInsets.only(top: 20, bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(53, 96, 15, 91),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            width: 1,
                            color: const Color.fromARGB(100, 230, 168, 206),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButtonStart(
                              icon: FluentIcons.image_24_regular,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditPage(),
                                  ),
                                );
                              },
                              text: 'фото',
                            ),
                            const SizedBox(width: 50),
                            IconButtonStart(
                              icon: FluentIcons
                                  .layout_column_two_split_left_24_regular,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditPage(),
                                  ),
                                );
                              },
                              text: 'коллаж',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ])
        ),
      ),
    );
  }
}

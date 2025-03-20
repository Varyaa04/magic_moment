import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class EditPage extends StatelessWidget {
  final File? imageFile;

  const EditPage({super.key, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: Tooltip(
                  message: 'Назад',
                  child: IconButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    icon: const Icon(FluentIcons.arrow_left_16_filled),
                    color: Colors.black,
                    iconSize: 30,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: Tooltip(
                  message: 'Сохранить',
                  child: IconButton(
                    onPressed: (){
                    },
                    icon: const Icon(FluentIcons.save_copy_20_regular),
                    color: Colors.black,
                    iconSize: 30,
                  ),
                ),
              )
            ],
          )

        ],
        ),
    );
  }
}
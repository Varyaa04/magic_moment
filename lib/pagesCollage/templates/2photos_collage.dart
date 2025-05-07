import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

List<Widget> getTwoPhotosCollages(List<ImageProvider> images) {
  return [
    // Шаблон 1: Две фотографии одна над другой
    StaggeredGrid.count(
      crossAxisCount: 1,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        for (var i = 0; i < images.length; i++)
          StaggeredGridTile.extent(
            crossAxisCellCount: 1,
            mainAxisExtent: 200,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: images[i],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    ),

    // Шаблон 2: Две фотографии рядом
    StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        for (var i = 0; i < images.length; i++)
          StaggeredGridTile.extent(
            crossAxisCellCount: 1,
            mainAxisExtent: 200,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: images[i],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    ),

    // Шаблон 3: Большая и маленькая
    StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        StaggeredGridTile.extent(
          crossAxisCellCount: 2,
          mainAxisExtent: 400,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: images[0],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        StaggeredGridTile.extent(
          crossAxisCellCount: 1,
          mainAxisExtent: 200,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: images[1],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    ),

    // Шаблон 4: Диагональное расположение
    StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        StaggeredGridTile.extent(
          crossAxisCellCount: 1,
          mainAxisExtent: 200,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: images[0],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        StaggeredGridTile.extent(
          crossAxisCellCount: 1,
          mainAxisExtent: 200,
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: images[1],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    ),

    // Шаблон 5: Одна большая, вторая маленькая сбоку
    StaggeredGrid.count(
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        StaggeredGridTile.extent(
          crossAxisCellCount: 2,
          mainAxisExtent: 400,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: images[0],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        StaggeredGridTile.extent(
          crossAxisCellCount: 1,
          mainAxisExtent: 200,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: images[1],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    ),
  ];
}
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

List<Widget> getFourPhotosCollages(List<ImageProvider> images) {
  return [
    // Шаблон 1: 2x2 сетка
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

    // Шаблон 2: Одна большая и три маленькие
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
        for (var i = 1; i < images.length; i++)
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

    // Шаблон 3: Четыре в ряд
    StaggeredGrid.count(
      crossAxisCount: 4,
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

    // Шаблон 4: Две большие сверху, две маленькие снизу
    StaggeredGrid.count(
      crossAxisCount: 4,
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
          crossAxisCellCount: 2,
          mainAxisExtent: 400,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: images[1],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        for (var i = 2; i < images.length; i++)
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

    // Шаблон 5: Мозаика
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
        for (var i = 1; i < images.length; i++)
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
  ];
}
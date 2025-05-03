import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

List<Widget> getSixPhotosCollages(List<ImageProvider> images) {
  return [
    // Шаблон 1: 3x2 сетка
    StaggeredGrid.count(
      crossAxisCount: 3,
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

    // Шаблон 2: Две большие и четыре маленькие
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

    // Шаблон 3: Шесть в ряд
    StaggeredGrid.count(
      crossAxisCount: 6,
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

    // Шаблон 4: Мозаика
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

    // Шаблон 5: Сложная мозаика
    StaggeredGrid.count(
      crossAxisCount: 5,
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
  ];
}
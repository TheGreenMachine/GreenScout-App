import 'dart:math';

import 'package:flutter/material.dart';
import 'package:green_scout/utils/action_bar.dart';
import 'package:green_scout/utils/general_utils.dart';
import 'package:green_scout/widgets/circular_indicator_button.dart';
import 'package:green_scout/widgets/navigation_layout.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// A page dedicated to listing people that helped
/// contribute to the app or the team in some way.
/// 
/// It's essentially used as a page for showing
/// appreciation to those people by allowing others
/// to see their achievements. 
class HallOfFamePage extends StatefulWidget {
  const HallOfFamePage({super.key});

  @override
  State<HallOfFamePage> createState() => _HOFPage();
}

class HOFEntry {
  final String name;
  final String team;
  final List<String> titles;
  final String description;
  final String quote;
  final String imagePath;

  HOFEntry(this.name, this.team, this.titles, this.description, this.quote,
      this.imagePath);
}

/// The UI is pretty much copied wholesale from https://gist.githubusercontent.com/adarshchauhan095/f7ed128ad7c489a1ad1c4e66520db0c7/raw/c2106d190becd4159cbf66378726e01229a3ead2/main.dart
/// bcs i'm a bum - Tag
class _HOFPage extends State<HallOfFamePage> {
  @override
  void initState() {
    getShownItemsIndex();
    super.initState();
  }

  // If you can get this one down to size, please do include it
  /// 2024 Worlds pitcrew (Kaylie, William, Grayson, Elena, Venna, Aahill, Evelyn)
  /// Reason: We accidentally didn't assign anyone Blue 3 for an entire day, so they had to rescout like 60 matches in the time between getting to the pits and matches starting
  /// Reason I didn't put them in: I couldn't get the reasoning down suscinctly enough

  // If the following people maintain their level of scouting quality next year, induct them.
  /// Marcos L-N
  /// Luke M
  /// Vincent R
  /// Lydia F (wait till she chills a bit tho)
  ///
  /// John istg if you don't put yourself in here eventually
  ///
  /// - Tag

  List<HOFEntry> entries = [
    HOFEntry(
      "Nora B",
      "1816",
      ["2024 co-Mechanical Lead", "2024 Granite City Scouting MVP"],
      "Scouted 78 matches in GreenScout's first competition",
      '"She slayed sm" -Elena L, 2024',
      "assets/leaderboard/badges/st cloud mvp badge.png",
    ),
    HOFEntry(
      "Lukas",
      "7312",
      ["2024 Worlds Scouting MVP"],
      "Scouted over 300 matches",
      '"We tried to get him to come to dinner, but he wanted to keep scouting" -Akshi from 7312, 2024',
      "assets/hof/7312.png",
    ),
    HOFEntry(
      "Michael P",
      "1816",
      ["Frontend GOAT"],
      "Original Frontend developer for GreenScout",
      '"I took one look at him and knew he was cracked" -Nico L, 2024',
      "assets/hof/mike.png",
    ),
    HOFEntry(
      "Tag C",
      "1816",
      ["2024 CSP Lead"],
      "Original Backend developer for GreenScout",
      //This used to say "500+ commits, 100k+ lines of code" but i thought that sounded too braggy, same with "I thought it'd be bad when nico and keerthi left, but look at us, we've got 2000 autos" from venna @ duluth 2024
      //Feel free to change this one since i'm bad at talking about myself
      //-Tag
      '"I had to tell this man to eat his Jimmy Johns instead of coding" -Michael P, 2024', // Yeah, this might not be the best qoute, feel free to choose John - Michael.
      "assets/hof/tag.png",
    )
  ];

  final itemScrollController = ItemScrollController();

  final itemPositionsListener = ItemPositionsListener.create();

  List<int> shownItemsIndexOnScreen = [];

  int startIndex = 0;

  int endIndex = 0;

  void getShownItemsIndex() {
    itemPositionsListener.itemPositions.addListener(() {
      shownItemsIndexOnScreen = itemPositionsListener.itemPositions.value
          .where((element) {
            final isPreviousVisible = element.itemLeadingEdge >= 0;
            return isPreviousVisible;
          })
          .map((item) => item.index)
          .toList();

      startIndex = shownItemsIndexOnScreen.isEmpty
          ? 0
          : shownItemsIndexOnScreen.reduce(min);

      endIndex = shownItemsIndexOnScreen.isEmpty
          ? 0
          : shownItemsIndexOnScreen.reduce(max);
    });
  }

  void scrollToNext() async {
    if (shownItemsIndexOnScreen.isEmpty) {
      getShownItemsIndex();
    } else {
      if (endIndex < entries.length - 1) {
        await itemScrollController.scrollTo(
            index: endIndex + 1,
            alignment: 0,
            duration: const Duration(milliseconds: 200));
        return;
      } else {}
    }
  }

  void scrollToPrevious() async {
    if (shownItemsIndexOnScreen.isEmpty) {
      getShownItemsIndex();
    } else {
      if (startIndex > 0) {
        await itemScrollController.scrollTo(
            index: startIndex - 1,
            alignment: 0,
            duration: const Duration(milliseconds: 200));

        return;
      } else {}
    }
  }

  Widget buildInfoCardLayout(BuildContext context, HOFEntry entry) {
    final (width, widthPadding) = screenScaler(MediaQuery.of(context).size.width, 670, 0.5, 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widthPadding, vertical: 12),

      child: Center(child: Card(
        clipBehavior: Clip.antiAlias,
        
        child: SizedBox(
          width: width,

          child: Column(
            children: [
              Text(
                entry.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 52,
                ),
              ),

              Text(
                "Team ${entry.team}",
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const Padding(padding: EdgeInsets.all(4)),

              // Take every entry and then construct a widget for them.
              // After mapping them to a widget, unwrap the resulting list.
              ...entry.titles.map((title) {
                return Text(title);
              }),

              const Padding(padding: EdgeInsets.all(8)),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: widthPadding / 2),

                child: Text(
                  entry.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
              ),

              const Padding(padding: EdgeInsets.all(8)),

              Text(
                entry.quote,

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 18,
                ),
              ),

              const Padding(padding: EdgeInsets.all(16)),

              SizedBox(
                width: width > 670 ? (width / 3) : (width / 2),

                child: Image.asset(entry.imagePath, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: createDefaultActionBar(),
        title: const Text("Hall of Fame", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      drawer: const NavigationLayoutDrawer(),
      body: ListView(
        children: [
          SizedBox(
            height: 700,
            child: Stack(
              children: [
                ScrollablePositionedList.separated(
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionsListener,
                  itemCount: entries.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemBuilder: (context, index) => buildInfoCardLayout(context, entries[index]),
                  separatorBuilder: (context, index) => const SizedBox(
                    width: 10.0,
                  ),
                ),
                Opacity(
                    opacity: 0.5,
                    child: (Align(
                      alignment: Alignment.centerLeft,
                      child: CircularIndicatorButton(
                        isLeft: true,
                        onTap: () {
                          scrollToPrevious();
                        },
                      ),
                    ))),
                Opacity(
                    opacity: 0.5,
                    child: (Align(
                      alignment: Alignment.centerRight,
                      child: CircularIndicatorButton(
                        isLeft: false,
                        onTap: () {
                          scrollToNext();
                        },
                      ),
                    ))),
              ],
            ),
          )
        ],
      ),
    );
  }
}

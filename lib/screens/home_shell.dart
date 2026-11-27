import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chats.dart';
import 'explore.dart';
import 'my_trips.dart';
import 'profile.dart';
import 'rider_home.dart';

/// Main shell: bottom nav differs by mode; rider gets a centre
/// Create Ride action.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state});

  final AppState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final state = widget.state;
        final isRider = state.mode == 'rider';
        final pages = isRider
            ? <Widget>[
                RiderHomeScreen(state: state),
                MyTripsScreen(state: state),
                ChatsScreen(state: state),
                ProfileScreen(state: state),
              ]
            : <Widget>[
                ExploreScreen(state: state),
                MyTripsScreen(state: state),
                ChatsScreen(state: state),
                ProfileScreen(state: state),
              ];
        final titles = isRider
            ? ['Home', 'My Rides', 'Chats', 'Profile']
            : ['Explore', 'My Trips', 'Chats', 'Profile'];
        final clamped = _index.clamp(0, pages.length - 1);
        return Scaffold(
          appBar: AppBar(
            title: Text(titles[clamped]),
            actions: [
              // Quick mode toggle in the app bar.
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(isRider ? 'Rider' : 'Member'),
                  selected: true,
                  selectedColor: HopColors.sageSoft,
                  onSelected: (_) async {
                    final ok =
                        await state.setMode(isRider ? 'member' : 'rider');
                    if (context.mounted) {
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isRider
                                ? 'Switched to Member mode.'
                                : 'Switched to Rider mode.')));
                      } else {
                        showHopError(context, state.error);
                      }
                    }
                    setState(() => _index = 0);
                  },
                ),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: IndexedStack(index: clamped, children: pages),
            ),
          ),
          floatingActionButton: isRider
              ? FloatingActionButton.extended(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/create-ride'),
                  backgroundColor: HopColors.peachDeep,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('Create Ride',
                      style: TextStyle(color: Colors.white)),
                )
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: clamped,
            onTap: (i) => setState(() => _index = i),
            items: [
              BottomNavigationBarItem(
                  icon: Icon(isRider
                      ? Icons.home_rounded
                      : Icons.explore_rounded),
                  label: titles[0]),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.luggage_rounded),
                  label: titles[1]),
              BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded),
                      if (state.totalUnreadChats > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: HopColors.peachDeep,
                                shape: BoxShape.circle),
                            child: Text('${state.totalUnreadChats}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                  label: 'Chats'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}

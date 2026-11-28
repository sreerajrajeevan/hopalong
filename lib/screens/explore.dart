import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/ride_card.dart';

/// Member home (Explore tab): greeting, search, upcoming rides, feed.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime? _date;
  List<String> _fromSuggestions = [];
  List<String> _toSuggestions = [];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  List<Widget> get _filteredRides {
    final rides = widget.state.searchRides(
      from: _fromController.text.trim().isEmpty
          ? null
          : _fromController.text.trim(),
      to: _toController.text.trim().isEmpty ? null : _toController.text.trim(),
      date: _date,
    );
    return rides
        .map((ride) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: RideCard(
                ride: ride,
                state: widget.state,
                onTap: () => Navigator.of(context)
                    .pushNamed('/ride', arguments: ride.id),
              ),
            ))
        .toList();
  }

  Widget _locationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> suggestions,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: HopColors.sage),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: HopColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HopColors.line),
            ),
            child: Column(
              children: suggestions
                  .map((s) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.history_rounded,
                            size: 18, color: HopColors.inkSoft),
                        title: Text(s),
                        onTap: () {
                          controller.text = s;
                          onChanged(s);
                        },
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final user = state.currentUser;
    final upcoming = state.upcomingRidesForMe;
    final greeting = _greeting();
    final filteredRides = _filteredRides;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            HopAvatar(
                photoUrl: user?.avatarUrl ?? '',
                name: user?.fullName ?? 'Friend',
                radius: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$greeting,',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(user?.fullName.split(' ').first ?? 'friend',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/notifications'),
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, size: 26),
                  if (state.unreadNotificationCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: HopColors.peachDeep,
                            shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Where are you headed?',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                _locationField(
                  controller: _fromController,
                  label: 'From',
                  icon: Icons.trip_origin_rounded,
                  suggestions: _fromSuggestions,
                  onChanged: (v) => setState(() {
                    _fromSuggestions = locationSuggestions(
                        v, state.locationHistory);
                  }),
                ),
                const SizedBox(height: 14),
                _locationField(
                  controller: _toController,
                  label: 'To',
                  icon: Icons.place_rounded,
                  suggestions: _toSuggestions,
                  onChanged: (v) => setState(() {
                    _toSuggestions =
                        locationSuggestions(v, state.locationHistory);
                  }),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: clampPickerDate(_date),
                      firstDate: clampPickerDate(null),
                      lastDate: clampPickerDate(null)
                          .add(const Duration(days: 60)),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Travel date',
                        prefixIcon:
                            Icon(Icons.calendar_today_rounded)),
                    child: Row(
                      children: [
                        Text(_date == null
                            ? 'Any day'
                            : formatDate(_date!)),
                        const Spacer(),
                        if (_date != null)
                          InkWell(
                            onTap: () => setState(() => _date = null),
                            child: const Icon(Icons.clear_rounded, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Find a ride'),
                ),
              ],
            ),
          ),
        ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 28),
          const SectionTitle(title: 'Your upcoming rides'),
          const SizedBox(height: 16),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: upcoming.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final ride = upcoming[i];
                return InkWell(
                  onTap: () => Navigator.of(context)
                      .pushNamed('/ride', arguments: ride.id),
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: HopColors.sageSoft,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatDate(ride.travelDate),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: HopColors.sage)),
                        const SizedBox(height: 6),
                        Text('${ride.fromLocation} → ${ride.toLocation}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text(
                            '${formatTimeOfDay(ride.departureHour, ride.departureMinute)} · ${ride.seatsLeft} seats left',
                            style: const TextStyle(
                                fontSize: 12, color: HopColors.inkSoft)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 28),
        const SectionTitle(title: 'Rides near you'),
        const SizedBox(height: 16),
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.error != null)
          HopErrorState(
              message: state.error!, onRetry: () => state.refreshRides())
        else if (filteredRides.isEmpty)
          const HopEmptyState(
            icon: Icons.directions_car_outlined,
            title: 'No rides yet',
            subtitle:
                'No rides match that search. Try another place or day — or be the first to post one!',
          )
        else
          ...filteredRides,
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

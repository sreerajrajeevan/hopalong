import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

/// Create / edit a ride: form → preview → publish.
class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key, required this.state, this.existing});

  final AppState state;
  final Ride? existing;

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _model = TextEditingController();
  final _contribution = TextEditingController();
  final _pickup = TextEditingController();
  final _dropoff = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String _vehicle = 'car';
  int _seats = 3;
  bool _busy = false;
  bool _showPreview = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _from.text = e.fromLocation;
      _to.text = e.toLocation;
      _model.text = e.vehicleModel;
      _contribution.text =
          e.contribution == null ? '' : e.contribution!.toStringAsFixed(0);
      _pickup.text = e.pickupLandmark;
      _dropoff.text = e.dropoffLandmark;
      _notes.text = e.notes;
      _date = e.travelDate;
      _time = TimeOfDay(hour: e.departureHour, minute: e.departureMinute);
      _vehicle = e.vehicleType;
      _seats = e.totalSeats;
    }
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _model.dispose();
    _contribution.dispose();
    _pickup.dispose();
    _dropoff.dispose();
    _notes.dispose();
    super.dispose();
  }

  Ride _buildRide() {
    final user = widget.state.currentUser!;
    final existing = widget.existing;
    return Ride(
      id: existing?.id ?? const Uuid().v4(),
      hostId: user.id,
      fromLocation: _from.text.trim(),
      toLocation: _to.text.trim(),
      travelDate: DateTime(_date.year, _date.month, _date.day),
      departureHour: _time.hour,
      departureMinute: _time.minute,
      vehicleType: _vehicle,
      vehicleModel: _model.text.trim(),
      totalSeats: _seats,
      seatsLeft: existing?.seatsLeft ?? _seats,
      contribution: _contribution.text.trim().isEmpty
          ? null
          : double.tryParse(_contribution.text.trim()),
      pickupLandmark: _pickup.text.trim(),
      dropoffLandmark: _dropoff.text.trim(),
      notes: _notes.text.trim(),
      status: existing?.status ?? 'active',
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
  }

  Future<void> _publish() async {
    setState(() => _busy = true);
    final ride = _buildRide();
    try {
      if (_isEdit) {
        await widget.state.updateRide(ride);
      } else {
        await widget.state.createRide(ride);
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnimatedCheck(),
              const SizedBox(height: 16),
              Text(_isEdit ? 'Ride updated!' : 'Your ride is live!',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                _isEdit
                    ? 'Members on this ride have been notified.'
                    : 'It is now showing in the ride feed. Happy hopping!',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Lovely!'),
              ),
            ],
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not publish the ride. Try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit ride' : 'Create a ride')),
      body: _showPreview ? _previewBody() : _formBody(),
    );
  }

  Widget _formBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _from,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'From *',
                  prefixIcon: Icon(Icons.trip_origin_rounded)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Where are you starting?' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _to,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'To *', prefixIcon: Icon(Icons.place_rounded)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Where are you headed?' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Travel date',
                          prefixIcon:
                              Icon(Icons.calendar_today_rounded)),
                      child: Text(formatDate(_date)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                          context: context, initialTime: _time);
                      if (picked != null) setState(() => _time = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Departure time',
                          prefixIcon: Icon(Icons.schedule_rounded)),
                      child: Text(_time.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'car',
                    icon: Icon(Icons.directions_car_rounded),
                    label: Text('Car')),
                ButtonSegment(
                    value: 'bike',
                    icon: Icon(Icons.two_wheeler_rounded),
                    label: Text('Bike')),
              ],
              selected: {_vehicle},
              onSelectionChanged: (s) => setState(() => _vehicle = s.first),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _model,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: _vehicle == 'car'
                      ? 'Car model *'
                      : 'Bike model *',
                  prefixIcon: const Icon(Icons.directions_car_outlined)),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Which vehicle is it?'
                  : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _seats,
                    decoration: const InputDecoration(
                        labelText: 'Available seats',
                        prefixIcon: Icon(Icons.event_seat_rounded)),
                    items: List.generate(6, (i) => i + 1)
                        .map((n) => DropdownMenuItem(
                            value: n, child: Text('$n')))
                        .toList(),
                    onChanged: (v) => setState(() => _seats = v ?? 3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _contribution,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Contribution ₹ (optional)',
                        prefixIcon: Icon(Icons.currency_rupee_rounded)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'Enter a valid amount.';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pickup,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Pickup landmark',
                  prefixIcon: Icon(Icons.flag_rounded)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dropoff,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Drop-off landmark',
                  prefixIcon: Icon(Icons.flag_outlined)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                  labelText: 'Notes for passengers',
                  hintText: 'e.g. Leaving sharp at 9, one stop for chai…'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() => _showPreview = true);
                }
              },
              child: const Text('Preview ride'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewBody() {
    final ride = _buildRide();
    final user = widget.state.currentUser!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This is how your ride will look in the feed:',
            style: TextStyle(color: HopColors.inkSoft),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HopAvatar(
                          photoUrl: user.avatarUrl,
                          name: user.fullName,
                          radius: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            Text(
                                '${ageFromDob(user.dob)} · ${user.gender}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall),
                          ],
                        ),
                      ),
                      const RideStatusChip(status: RideStatus.available),
                    ],
                  ),
                  const SizedBox(height: 16),
                  JourneyGraphic(
                      from: ride.fromLocation, to: ride.toLocation),
                  const SizedBox(height: 14),
                  Text(
                      '${formatDate(ride.travelDate)} · ${formatTimeOfDay(ride.departureHour, ride.departureMinute)}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                      '${ride.vehicleType == 'car' ? 'Car' : 'Bike'} · ${ride.vehicleModel} · ${ride.totalSeats} seats · ${formatContribution(ride.contribution)}'),
                  if (ride.pickupLandmark.isNotEmpty)
                    Text('Pickup: ${ride.pickupLandmark}'),
                  if (ride.dropoffLandmark.isNotEmpty)
                    Text('Drop-off: ${ride.dropoffLandmark}'),
                  if (ride.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(ride.notes),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : _publish,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(_isEdit ? 'Save changes' : 'Publish ride'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => setState(() => _showPreview = false),
            child: const Text('Back to edit'),
          ),
        ],
      ),
    );
  }
}

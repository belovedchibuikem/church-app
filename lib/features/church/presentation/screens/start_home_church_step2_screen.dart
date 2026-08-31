import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/home_church_repository.dart';

class StartHomeChurchStep2Screen extends StatefulWidget {
  const StartHomeChurchStep2Screen({super.key});

  @override
  State<StartHomeChurchStep2Screen> createState() =>
      _StartHomeChurchStep2ScreenState();
}

class _StartHomeChurchStep2ScreenState
    extends State<StartHomeChurchStep2Screen> {
  static const _days = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const _times = <String>[
    '9:00 AM',
    '10:00 AM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
  ];

  static const _activities = <String>[
    'Main service',
    'Midweek service',
    'Prayer meeting',
    'Fellowship',
    'Bible study',
    'Gathering',
  ];

  static const _participants = <String>['10-20', '21-30', '31-50', '50+'];

  final Map<String, _DaySchedule> _schedules = {
    'Sun': const _DaySchedule(time: '9:00 AM', activity: 'Main service'),
  };
  String _participantsRange = '10-20';

  @override
  void initState() {
    super.initState();
    final draft = HomeChurchApplicationSession.draft;
    if (draft.meetingSchedules.isNotEmpty) {
      _schedules.clear();
      for (final row in draft.meetingSchedules) {
        final day = _shortDay(row['day']);
        final time = _displayTime(row['time']);
        final activity = row['activity'] ?? 'Gathering';
        if (day != null && time != null) {
          _schedules[day] = _DaySchedule(time: time, activity: activity);
        }
      }
    }
    if (draft.expectedParticipants != null) {
      final count = draft.expectedParticipants!;
      _participantsRange = count >= 50
          ? '50+'
          : count >= 31
              ? '31-50'
              : count >= 21
                  ? '21-30'
                  : '10-20';
    }
  }

  String? _shortDay(String? api) {
    return switch (api?.toLowerCase()) {
      'monday' => 'Mon',
      'tuesday' => 'Tue',
      'wednesday' => 'Wed',
      'thursday' => 'Thu',
      'friday' => 'Fri',
      'saturday' => 'Sat',
      'sunday' => 'Sun',
      _ => null,
    };
  }

  String? _displayTime(String? api) {
    if (api == null || api.isEmpty) return null;
    final parsed = meetingTimeApiValue(api);
    if (parsed == null) return api;
    final parts = parsed.split(':');
    if (parts.length < 2) return api;
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final meridiem = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return '$hour:$minute $meridiem';
  }

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.homeChurchStart);
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_schedules.containsKey(day)) {
        _schedules.remove(day);
      } else {
        _schedules[day] = _DaySchedule(
          time: day == 'Sun' ? '9:00 AM' : '6:00 PM',
          activity: switch (day) {
            'Sun' => 'Main service',
            'Wed' => 'Midweek service',
            'Fri' => 'Prayer meeting',
            'Sat' => 'Fellowship',
            _ => 'Gathering',
          },
        );
      }
    });
  }

  String _dayLabel(BuildContext context, String day) {
    return switch (day) {
      'Mon' => fhcT(context, 'homeChurch.dayMon', fallback: 'Mon'),
      'Tue' => fhcT(context, 'homeChurch.dayTue', fallback: 'Tue'),
      'Wed' => fhcT(context, 'homeChurch.dayWed', fallback: 'Wed'),
      'Thu' => fhcT(context, 'homeChurch.dayThu', fallback: 'Thu'),
      'Fri' => fhcT(context, 'homeChurch.dayFri', fallback: 'Fri'),
      'Sat' => fhcT(context, 'homeChurch.daySat', fallback: 'Sat'),
      'Sun' => fhcT(context, 'homeChurch.daySun', fallback: 'Sun'),
      _ => day,
    };
  }

  String _timeLabel(BuildContext context, String time) {
    return switch (time) {
      '9:00 AM' => fhcT(context, 'homeChurch.time9am', fallback: '9:00 AM'),
      '10:00 AM' => fhcT(context, 'homeChurch.time10am', fallback: '10:00 AM'),
      '5:00 PM' => fhcT(context, 'homeChurch.time5pm', fallback: '5:00 PM'),
      '6:00 PM' => fhcT(context, 'homeChurch.time6pm', fallback: '6:00 PM'),
      '7:00 PM' => fhcT(context, 'homeChurch.time7pm', fallback: '7:00 PM'),
      '8:00 PM' => fhcT(context, 'homeChurch.time8pm', fallback: '8:00 PM'),
      _ => time,
    };
  }

  String _participantsLabel(BuildContext context, String range) {
    return switch (range) {
      '10-20' => fhcT(
        context,
        'homeChurch.participants10to20',
        fallback: '10-20',
      ),
      '21-30' => fhcT(
        context,
        'homeChurch.participants21to30',
        fallback: '21-30',
      ),
      '31-50' => fhcT(
        context,
        'homeChurch.participants31to50',
        fallback: '31-50',
      ),
      '50+' => fhcT(
        context,
        'homeChurch.participants50plus',
        fallback: '50+',
      ),
      _ => range,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(title: '', onBack: _onBack),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 640;
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          fhcT(
                            context,
                            'homeChurch.startTitle',
                            fallback: 'Start a Church\nin Your Home',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            height: 1.18,
                            fontWeight: FontWeight.w700,
                            color: FhcColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _StepBanner(step: 2),
                        const SizedBox(height: 10),
                        const _StepProgress(step: 2),
                        SizedBox(height: compact ? 16 : 22),
                        FhcField(
                          label: fhcT(
                            context,
                            'homeChurch.homeAddress',
                            fallback: 'Home Address',
                          ),
                          hint: fhcT(
                            context,
                            'homeChurch.homeAddressHint',
                            fallback: 'Enter your home address',
                          ),
                          suffixIcon: Icons.location_on_outlined,
                          keyboardType: TextInputType.streetAddress,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        Text(
                          fhcT(
                            context,
                            'homeChurch.preferredMeetingDays',
                            fallback: 'Preferred Meeting Days',
                          ),
                          style: FhcTypography.label,
                        ),
                        const SizedBox(height: 8),
                        _DayChips(
                          days: _days,
                          selected: _schedules.keys.toSet(),
                          labelFor: (day) => _dayLabel(context, day),
                          onToggle: _toggleDay,
                        ),
                        if (_schedules.isNotEmpty) ...[
                          SizedBox(height: compact ? 12 : 16),
                          for (final day in _days)
                            if (_schedules.containsKey(day)) ...[
                              _ScheduleCard(
                                dayLabel: _dayLabel(context, day),
                                time: _schedules[day]!.time,
                                activity: _schedules[day]!.activity,
                                times: _times,
                                activities: _activities,
                                timeLabel: (time) => _timeLabel(context, time),
                                onTime: (value) => setState(() {
                                  _schedules[day] = _schedules[day]!.copyWith(
                                    time: value,
                                  );
                                }),
                                onActivity: (value) => setState(() {
                                  _schedules[day] = _schedules[day]!.copyWith(
                                    activity: value,
                                  );
                                }),
                              ),
                              const SizedBox(height: 10),
                            ],
                        ],
                        _DropdownField(
                          label: fhcT(
                            context,
                            'homeChurch.expectedParticipants',
                            fallback: 'Expected Participants',
                          ),
                          value: _participantsRange,
                          options: _participants,
                          optionLabel: (range) =>
                              _participantsLabel(context, range),
                          onChanged:
                              (value) =>
                                  setState(() => _participantsRange = value),
                        ),
                        SizedBox(height: compact ? 20 : 28),
                        FhcPrimaryButton(
                          label: fhcT(
                            context,
                            'common.continue',
                            fallback: 'Continue',
                          ),
                          onPressed: () {
                            if (_schedules.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    fhcT(
                                      context,
                                      'homeChurch.selectMeetingDay',
                                      fallback:
                                          'Select at least one meeting day.',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }
                            final draft = HomeChurchApplicationSession.draft;
                            final ordered = [
                              for (final day in _days)
                                if (_schedules.containsKey(day)) day,
                            ];
                            final primary = ordered.first;
                            draft.meetingDay = meetingDayApiValue(primary);
                            draft.meetingTime = meetingTimeApiValue(
                              _schedules[primary]!.time,
                            );
                            draft.meetingSchedules = [
                              for (final day in ordered)
                                {
                                  'day': meetingDayApiValue(day) ?? day,
                                  'time':
                                      meetingTimeApiValue(_schedules[day]!.time) ??
                                          '18:00',
                                  'activity': _schedules[day]!.activity,
                                },
                            ];
                            draft.expectedParticipants =
                                expectedParticipantsApiValue(
                              _participantsRange,
                            );
                            fhcPush(context, FhcRoutes.homeChurchStart3);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBanner extends StatelessWidget {
  const _StepBanner({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: FhcColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            fhcT(
              context,
              'homeChurch.stepOf',
              args: {'current': '$step', 'total': '4'},
              fallback: 'Step {current} of {total}',
            ),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: FhcColors.muted,
            ),
          ),
        ),
        const Expanded(child: Divider(color: FhcColors.border, height: 1)),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
              decoration: BoxDecoration(
                color: i < step ? FhcColors.green : FhcColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _DaySchedule {
  const _DaySchedule({required this.time, required this.activity});

  final String time;
  final String activity;

  _DaySchedule copyWith({String? time, String? activity}) {
    return _DaySchedule(
      time: time ?? this.time,
      activity: activity ?? this.activity,
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.dayLabel,
    required this.time,
    required this.activity,
    required this.times,
    required this.activities,
    required this.timeLabel,
    required this.onTime,
    required this.onActivity,
  });

  final String dayLabel;
  final String time;
  final String activity;
  final List<String> times;
  final List<String> activities;
  final String Function(String value) timeLabel;
  final ValueChanged<String> onTime;
  final ValueChanged<String> onActivity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FhcColors.white,
        borderRadius: BorderRadius.circular(FhcRadius.sm),
        border: Border.all(color: FhcColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dayLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _DropdownField(
              label: fhcT(
                context,
                'homeChurch.activity',
                fallback: 'Activity',
              ),
              value: activities.contains(activity) ? activity : activities.last,
              options: activities,
              optionLabel: (value) => value,
              onChanged: onActivity,
            ),
            const SizedBox(height: 8),
            _DropdownField(
              label: fhcT(
                context,
                'homeChurch.meetingTime',
                fallback: 'Meeting Time',
              ),
              value: times.contains(time) ? time : times.first,
              options: times,
              optionLabel: timeLabel,
              onChanged: onTime,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChips extends StatelessWidget {
  const _DayChips({
    required this.days,
    required this.selected,
    required this.labelFor,
    required this.onToggle,
  });

  final List<String> days;
  final Set<String> selected;
  final String Function(String day) labelFor;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _DayChip(
              label: labelFor(days[i]),
              selected: selected.contains(days[i]),
              onTap: () => onToggle(days[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? FhcColors.green : FhcColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FhcRadius.sm),
          side: BorderSide(
            color: selected ? FhcColors.green : FhcColors.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.sm),
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? FhcColors.white : FhcColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final String Function(String value) optionLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FhcTypography.label),
        const SizedBox(height: 7),
        DecoratedBox(
          decoration: BoxDecoration(
            color: FhcColors.white,
            borderRadius: radius,
            border: Border.all(color: FhcColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 22,
                color: FhcColors.muted,
              ),
              borderRadius: radius,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FhcColors.ink,
              ),
              items: [
                for (final option in options)
                  DropdownMenuItem<String>(
                    value: option,
                    child: Text(optionLabel(option)),
                  ),
              ],
              onChanged: (next) {
                if (next != null) onChanged(next);
              },
            ),
          ),
        ),
      ],
    );
  }
}

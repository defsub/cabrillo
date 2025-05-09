// Copyright 2025 defsub
//
// This file is part of Cabrillo.
//
// Cabrillo is free software: you can redistribute it and/or modify it under the
// terms of the GNU Affero General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// Cabrillo is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for
// more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Cabrillo.  If not, see <https://www.gnu.org/licenses/>.

import 'package:cabrillo/cabrillo.dart';
import 'package:cabrillo/date.dart';
import 'package:cabrillo/seen/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings.dart';

const _durationOptions = [
  Duration.zero,
  Duration(minutes: 5),
  Duration(minutes: 15),
  Duration(minutes: 30),
  Duration(minutes: 45),
  Duration(hours: 1),
  Duration(hours: 4),
  Duration(hours: 8),
  Duration(hours: Duration.hoursPerDay),
];

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(context.strings.settingsLabel)),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _switchTile(
                        seenIconData(true),
                        context.strings.settingAutoSeen,
                        state.settings.autoSeen,
                            (value) => context.settings.autoSeen = value,
                      ),
                      _switchTile(
                        Icons.numbers,
                        context.strings.settingShowCounts,
                        state.settings.showCounts,
                        (value) => context.settings.showCounts = value,
                      ),
                      _switchTile(
                        Icons.image_outlined,
                        context.strings.settingShowImages,
                        state.settings.showImages,
                        (value) => context.settings.showImages = value,
                      ),
                      _switchTile(
                        Icons.hourglass_bottom,
                        context.strings.settingShowReadingTime,
                        state.settings.showReadingTime,
                            (value) => context.settings.showReadingTime = value,
                      ),
                      ListTile(
                        leading: const Icon(Icons.timer_outlined),
                        title: Text(context.strings.settingPageDuration),
                        subtitle: _DurationField(state),
                      ),
                      ListTile(
                        leading: const Icon(Icons.numbers),
                        title: Text(context.strings.settingPageSize),
                        subtitle: _PageSizeField(state),
                      ),
                    ],
                  ),
                ),
                MinifluxSettings(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    // String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      // subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class MinifluxSettings extends StatelessWidget {
  const MinifluxSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsCubit>().state;
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.cloud),
            title: Text(context.strings.settingHost),
            subtitle: _HostField(state),
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: Text(context.strings.settingApiKey),
            subtitle: _TokenField(state),
          ),
        ],
      ),
    );
  }
}

class _PageSizeField extends StatefulWidget {
  final SettingsState state;

  const _PageSizeField(this.state);

  @override
  State createState() => _PageSizeFieldState();
}

class _PageSizeFieldState extends State<_PageSizeField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.number,
      onChanged: (value) {
        context.settings.pageSize = int.tryParse(value) ?? 0;
      },
      initialValue: '${widget.state.settings.pageSize}',
    );
  }
}

class _DurationField extends StatefulWidget {
  final SettingsState state;

  const _DurationField(this.state);

  @override
  State createState() => _DurationFieldState();
}

class _DurationFieldState extends State<_DurationField> {
  @override
  Widget build(BuildContext context) {
    final items =
        _durationOptions
            .map(
              (o) => DropdownMenuItem<Duration>(
                value: o,
                child: Text(inHoursMinutes(o)),
              ),
            )
            .toList();

    return DropdownButtonFormField<Duration>(
      items: items,
      value: context.settings.state.settings.pageDuration,
      onChanged: (value) {
        if (value != null) {
          context.settings.pageDuration = value;
        }
      },
    );
  }
}

class _HostField extends StatefulWidget {
  final SettingsState state;

  const _HostField(this.state);

  @override
  State createState() => _HostFieldState();
}

class _HostFieldState extends State<_HostField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: (value) {
        context.settings.host = value.trim();
      },
      initialValue: widget.state.settings.host,
    );
  }
}

class _TokenField extends StatefulWidget {
  final SettingsState state;

  const _TokenField(this.state);

  @override
  State createState() => _TokenFieldState();
}

class _TokenFieldState extends State<_TokenField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: _obscureText,
      onTap: () {
        setState(() {
          _obscureText = false;
        });
      },
      onTapOutside: (_) {
        setState(() {
          _obscureText = true;
        });
      },
      onChanged: (value) {
        context.settings.apiKey = value.trim();
      },
      initialValue: widget.state.settings.apiKey,
    );
  }
}

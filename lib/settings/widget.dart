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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings.dart';

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
                      // _switchTile(
                      //   Icons.cloud_outlined,
                      //   context.strings.settingStreamingTitle,
                      //   context.strings.settingStreamingSubtitle,
                      //   state.settings.allowMobileStreaming,
                      //   (value) {
                      //     context.settings.allowStreaming = value;
                      //   },
                      // ),
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
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
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

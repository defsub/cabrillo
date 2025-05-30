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

import 'package:cabrillo/app/context.dart';
import 'package:cabrillo/miniflux/miniflux.dart';
import 'package:cabrillo/widget/empty.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract mixin class ClientPageBuilder<T> {
  WidgetBuilder builder(BuildContext context, {T? value}) {
    return (context) => BlocProvider(
      create:
          (context) =>
              MinifluxCubit(context.clientRepository, context.seenRepository),
      child: BlocBuilder<MinifluxCubit, MinifluxState>(
        builder: (context, state) {
          if (state is MinifluxReady) {
            if (value != null) {
              return page(context, value);
            } else {
              load(context);
              // TODO upon first load ClientLoading is delayed so show some
              //  progress now
              return const Center(child: CircularProgressIndicator());
            }
          } else if (state is MinifluxLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MinifluxResult<T>) {
            return page(context, state.result);
          } else if (state is MinifluxError) {
            return errorPage(context, state);
          }
          return const EmptyWidget();
        },
      ),
    );
  }

  Widget page(BuildContext context, T state);

  Widget errorPage(BuildContext context, MinifluxError error) {
    if (error is MinifluxAuthError) {
      context.app.unauthenticated();
    }
    return Center(
      child: TextButton(
        child: Text('Try Again (${error.error})'),
        onPressed: () {
          reloadPage(context);
        },
      ),
    );
  }

  Future<void> reloadPage(BuildContext context) {
    return reload(context);
  }

  Future<void> load(BuildContext context, {Duration? ttl});

  Future<void> reload(BuildContext context) {
    return load(context, ttl: Duration.zero);
  }
}

abstract class ClientPage<T> extends StatelessWidget with ClientPageBuilder<T> {
  final T? value;

  ClientPage({super.key, this.value});

  @override
  Widget build(BuildContext context) {
    return builder(context, value: value)(context);
  }
}

abstract class NavigatorClientPage<T> extends ClientPage<T> {
  NavigatorClientPage({super.key, super.value});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: key,
      initialRoute: '/',
      // observers: [heroController()],
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
          builder: builder(context, value: value),
          settings: settings,
        );
      },
    );
  }
}

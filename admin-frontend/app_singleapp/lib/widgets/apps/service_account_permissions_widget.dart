import 'dart:ui';

import 'package:app_singleapp/api/client_api.dart';
import 'package:app_singleapp/widgets/common/FHFlatButton.dart';
import 'package:app_singleapp/widgets/common/fh_flat_button_transparent.dart';
import 'package:app_singleapp/widgets/common/fh_footer_button_bar.dart';
import 'package:app_singleapp/widgets/common/fh_info_card.dart';
import 'package:app_singleapp/widgets/common/fh_link.dart';
import 'package:bloc_provider/bloc_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logging/logging.dart';
import 'package:mrapi/api.dart';

import 'manage_app_bloc.dart';

final _log = Logger('ServiceAccountPermissionsWidget');

class ServiceAccountPermissionsWidget extends StatefulWidget {
  const ServiceAccountPermissionsWidget({Key key}) : super(key: key);

  @override
  _ServiceAccountPermissionState createState() =>
      _ServiceAccountPermissionState();
}

class _ServiceAccountPermissionState
    extends State<ServiceAccountPermissionsWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route =
        BlocProvider.of<ManagementRepositoryClientBloc>(context).currentRoute;

    if (route.params['service-account'] != null) {
      _log.fine(
          'Got route request for params ${route.params} so swapping service account');
      final bloc = BlocProvider.of<ManageAppBloc>(context);
      bloc.selectServiceAccount(route.params['service-account'][0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<ManageAppBloc>(context);
    final mrBloc = BlocProvider.of<ManagementRepositoryClientBloc>(context);
    return StreamBuilder<List<ServiceAccount>>(
        stream: bloc.serviceAccountsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data.isEmpty) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        Text(
                            "There are no 'service accounts' in the '${bloc.portfolio.name}' portfolio."),
                        Container(
                          padding: EdgeInsets.only(top: 20, bottom: 20),
                          child: FHLinkWidget(
                              text:
                                  'Manage service accounts for this portfolio?',
                              href: '/manage-service-accounts'),
                        )
                      ],
                    )),
              ],
            );
          }

          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 16.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service account',
                          style: Theme.of(context).textTheme.caption,
                        ),
                        serviceAccountDropdown(snapshot.data, bloc),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: FHInfoCardWidget(
                          message:
                              '''The 'Lock/Unlock' and 'Change value' permissions
are so you can change these states through the API's
e.g., when running tests. \n
We strongly recommend setting production environments
with only 'Read' permission for service accounts.'''),
                    ),
                  ],
                ),
                _ServiceAccountPermissionDetailWidget(bloc: bloc, mr: mrBloc)
              ]);
        });
  }

  Widget serviceAccountDropdown(
      List<ServiceAccount> serviceAccounts, ManageAppBloc bloc) {
    return Container(
      constraints: BoxConstraints(maxWidth: 250),
      child: StreamBuilder<String>(
          stream: bloc.currentServiceAccountIdStream,
          builder: (context, snapshot) {
            return InkWell(
              mouseCursor: SystemMouseCursors.click,
              child: DropdownButton(
                icon: Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 24,
                  ),
                ),
                isExpanded: true,
                isDense: true,
                items: serviceAccounts.map((ServiceAccount serviceAccount) {
                  return DropdownMenuItem<String>(
                      value: serviceAccount.id,
                      child: Text(
                        serviceAccount.name,
                        style: Theme.of(context).textTheme.bodyText2,
                        overflow: TextOverflow.ellipsis,
                      ));
                }).toList(),
                hint: Text(
                  'Select service account',
                  textAlign: TextAlign.end,
                ),
                onChanged: (value) {
                  setState(() {
                    bloc.selectServiceAccount(value);
                  });
                },
                value: snapshot.data,
              ),
            );
          }),
    );
  }
}

class _ServiceAccountPermissionDetailWidget extends StatefulWidget {
  final ManagementRepositoryClientBloc mr;
  final ManageAppBloc bloc;

  const _ServiceAccountPermissionDetailWidget({
    Key key,
    @required this.mr,
    @required this.bloc,
  })  : assert(mr != null),
        assert(bloc != null),
        super(key: key);

  @override
  _ServiceAccountPermissionDetailState createState() =>
      _ServiceAccountPermissionDetailState();
}

class _ServiceAccountPermissionDetailState
    extends State<_ServiceAccountPermissionDetailWidget> {
  Map<String, ServiceAccountPermission> newServiceAccountPermission = {};
  ServiceAccount currentServiceAccount;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ServiceAccount>(
        stream: widget.bloc.serviceAccountStream,
        builder: (context, saSnapshot) {
          if (!saSnapshot.hasData) {
            return Container();
          }

          return StreamBuilder<List<Environment>>(
              stream: widget.bloc.environmentsStream,
              builder: (context, envSnapshot) {
                if (!envSnapshot.hasData) {
                  return Container();
                }
                if (envSnapshot.data.isEmpty) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                          padding: EdgeInsets.all(20),
                          child: Text(
                              "You need to first create some 'Environments' for this application.")),
                    ],
                  );
                }

                if (currentServiceAccount == null ||
                    currentServiceAccount.id != saSnapshot.data.id) {
                  newServiceAccountPermission =
                      createMap(envSnapshot.data, saSnapshot.data);
                  currentServiceAccount = saSnapshot.data;
                }

                final rows = <TableRow>[];
                rows.add(getHeader());
                for (var env in envSnapshot.data) {
                  rows.add(TableRow(
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Theme.of(context).dividerColor))),
                      children: [
                        Container(
                            padding: EdgeInsets.fromLTRB(5, 15, 0, 0),
                            child: Text(env.name)),
                        getPermissionCheckbox(env.id, RoleType.READ),
                        getPermissionCheckbox(env.id, RoleType.LOCK),
                        getPermissionCheckbox(env.id, RoleType.UNLOCK),
                        getPermissionCheckbox(env.id, RoleType.CHANGE_VALUE),
                      ]));
                }

                Widget table = Table(children: rows);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                        padding: EdgeInsets.fromLTRB(0, 24, 0, 16),
                        child: Center(
                          child: Text(
                              'Set the service account access to features for each environment',
                              style: Theme.of(context)
                                  .textTheme
                                  .caption
                          ),
                        )),
                    table,
                    FHButtonBar(children: [
                      FHFlatButtonTransparent(
                        onPressed: () {
                          currentServiceAccount = null;
                          widget.bloc.selectServiceAccount(saSnapshot.data.id);
                        },
                        title: 'Cancel',
                        keepCase: true,
                      ),
                      FHFlatButton(
                          onPressed: () {
                            final newList = <ServiceAccountPermission>[];
                            newServiceAccountPermission.forEach((key, value) {
                              newList.add(value);
                            });
                            final newSa = saSnapshot.data;
                            newSa.permissions = newList;
                            widget.bloc
                                .updateServiceAccountPermissions(
                                    newSa.id, saSnapshot.data)
                                .then((serviceAccount) => widget.bloc.mrClient
                                    .addSnackbar(Text(
                                        "Service account '${serviceAccount?.name}' updated!")))
                                .catchError(widget.bloc.mrClient.dialogError);
                          },
                          title: 'Update'),
                    ]),
                  ],
                );
              });
        });
  }

  TableRow getHeader() {
    return TableRow(
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor))),
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(5, 0, 0, 15),
            child: Text(
              '',
            ),
          ),
          Center(
              child: Text(
            'Read',
            style: Theme.of(context).textTheme.subtitle2,
          )),
          Center(
              child: Text(
            'Lock',
            style: Theme.of(context).textTheme.subtitle2,
          )),
          Center(
              child: Text(
            'Unlock',
            style: Theme.of(context).textTheme.subtitle2,
          )),
          Center(
              child: Text(
            'Change value',
            style: Theme.of(context).textTheme.subtitle2,
          )),
        ]);
  }

  Checkbox getPermissionCheckbox(String envId, RoleType permissionType) {
    return Checkbox(
      value: newServiceAccountPermission[envId]
          .permissions
          .contains(permissionType),
      onChanged: (value) {
        setState(() {
          if (value) {
            newServiceAccountPermission[envId].permissions.add(permissionType);
          } else {
            newServiceAccountPermission[envId]
                .permissions
                .remove(permissionType);
          }
        });
      },
    );
  }

  Map<String, ServiceAccountPermission> createMap(
      List<Environment> environments, ServiceAccount serviceAccount) {
    final retMap = <String, ServiceAccountPermission>{};
    environments.forEach((environment) {
      final sap = serviceAccount.permissions
          .firstWhere((item) => item.environmentId == environment.id,
              orElse: () => ServiceAccountPermission()
                ..environmentId = environment.id
                ..permissions = <RoleType>[]);

      retMap[environment.id] = sap;
    });
    return retMap;
  }
}

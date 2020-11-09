import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mrapi/api.dart';

class DeviceAttributeStrategyDropdown extends StatefulWidget {
  final RolloutStrategyAttribute attribute;

  const DeviceAttributeStrategyDropdown({Key key, this.attribute}) : super(key: key);

  @override
  _DeviceAttributeStrategyDropdownState createState() => _DeviceAttributeStrategyDropdownState();
}

class _DeviceAttributeStrategyDropdownState extends State<DeviceAttributeStrategyDropdown> {
  StrategyAttributeDeviceName _strategyAttributeDeviceName;

  @override
  void initState() {
    if(widget.attribute.value != null) {
      _strategyAttributeDeviceName =
          StrategyAttributeDeviceNameTypeTransformer.fromJson(
              widget.attribute.value);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      child: Container(
        constraints: BoxConstraints(maxWidth: 250),
        child: DropdownButton(
          icon: Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 24,
            ),
          ),
          isExpanded: true,
          items: StrategyAttributeDeviceName.values
              .map((StrategyAttributeDeviceName dropDownStringItem) {
            return DropdownMenuItem<StrategyAttributeDeviceName>(
                value: dropDownStringItem,
                child: Text(
                    StrategyAttributeDeviceNameTypeTransformer.toJson(dropDownStringItem),
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyText2));
          }).toList(),

          hint: Text('Select device',
              style: Theme
                  .of(context)
                  .textTheme
                  .subtitle2),
          onChanged: (StrategyAttributeDeviceName value) {
            var readOnly = false; //TODO parametrise this if needed
            if (!readOnly) {
              setState(() {
                _strategyAttributeDeviceName = value;
                widget.attribute.value = value.name;
              });
            }
          },
          value: _strategyAttributeDeviceName,
        ),
      ),
    );
  }
}



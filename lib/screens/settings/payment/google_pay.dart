import 'package:flutter/material.dart';
import 'package:project_eureka_flutter/components/eureka_appbar.dart';
import 'package:project_eureka_flutter/screens/settings/payment/payment_confirmation.dart';

class GooglePay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EurekaAppBar(
        title: 'Google Pay',
        appBar: AppBar(),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PaymentConfirmation()),
            );
          },
          child: Text('Confirm'),
        ),
      ),
    );
  }
}

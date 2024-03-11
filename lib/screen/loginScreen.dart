import 'package:flutter/material.dart';
import 'package:task10_call/res/authenticate.dart';

void main() {
  runApp(loginScreen());
}

class loginScreen extends StatefulWidget {
  @override
  _loginScreenState createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {
  final Authentication authentication = Authentication();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _loginScreen(),
      ),
    );
  }

  Widget _loginScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/loginBG.jpg'),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center children vertically
          children: [
            const Text(
              'Lets start a video call',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 30,
            ),
            Image.asset(
              'images/videoCall.png',
              height: 300,
              width: 300,
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: () async {
                bool res = await authentication.signInGoogle(context);
                if (res) {
                  Navigator.pushNamed(context, '/home');
                }
              },
              child: const Text(
                'Sign in to your Google Account',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

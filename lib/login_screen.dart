import 'package:flutter/material.dart';
import 'package:rhos/home_screen.dart';
import 'package:rhos/widgets/custom_button.dart';
import 'package:rhos/widgets/login_field.dart';
import 'package:rhos/palette.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Image.asset('assets/images/rhos.jpg'), //Imagem RHOS
              SizedBox(height: 30),
              const Text(
                'Boas - Vindas',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                  color: Palette.textColor2,
                ),
              ),
              const Text(
                'Entre com seu usuário e senha',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Palette.textColor2,
                ),
              ),
              SizedBox(height: 50),
              LoginField(hintText: 'Usuário',
                  icon: Icons.person,
              ),
              SizedBox(height: 20),
              LoginField(
                hintText: 'Senha',
                isPasswordField: true,
                icon: Icons.lock,
              ),
              SizedBox(height: 70),
              CustomButton(
                  text: 'Entrar',
                  color: Palette.backgroundColor4,
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen(), // Ir para tela Home
                        ),
                    );
                  },
                  width: 360,
                  height: 70,
                fontSize: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

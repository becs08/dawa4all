import 'package:flutter/material.dart';

class InscriptionPage extends StatelessWidget {
  const InscriptionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'), // Image de fond
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Image(
                    image: AssetImage('assets/inscription.png'),
                    width: 200,
                    height: 150,
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 30.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 50), // Espace pour le logo
                          // Champ d'email ou nom d'utilisateur
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Nom d’utilisateur',
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.green,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          //Champ pour l'email
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Email',
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.green,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Champ de mot de passe
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Mot de passe',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.green,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          //Champ pour confirmation mdp
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Confirmer Mot de passe',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.green,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Logo positionné pour déborder
                    const Positioned(
                      top: -40,
                      left: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.green,
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          backgroundImage:
                          AssetImage('assets/logodawa4all.png'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green, width: 2),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 80,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/accueil');
                    },
                    child: const Text(
                      "S'INSCRIRE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Lien pour se connecter
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/connexion');
                  },
                  child: const Text(
                    'Vous avez déjà un compte ? Se connecter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Lien pour passer
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/accueil');
                  },
                  child: const Text(
                    'Passer pour le moment ➔',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

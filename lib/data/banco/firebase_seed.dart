import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:rh_os/data/servicos/firebase_auth_service.dart';

// Seed de dados para ambiente de desenvolvimento.
Future<void> executarFirebaseSeedSeNecessario() async {
  debugPrint('[FirebaseSeed] Verificando usuários no Firebase Auth...');

  final authService = FirebaseAuthService();

  final teste = await authService.login('admin@rhos.com', 'admin123');
  if (teste != null) {
    debugPrint('[FirebaseSeed] Usuários Auth já existem. Pulando seed Auth.');
    await authService.logout();
  } else {
    debugPrint('[FirebaseSeed] Criando usuários no Firebase Auth...');

    final usuarios = [
      ('admin@rhos.com', 'admin123'),
      ('recrutador@rhos.com', 'rec123'),
      ('jose.elias@gmail.com', 'cand123'),
      ('view@rhos.com', 'view123'),
    ];

    for (final (email, senha) in usuarios) {
      final resultado = await authService.criarUsuario(email, senha);
      if (resultado != null) {
        debugPrint(
            '[FirebaseSeed] Criado: $email (uid: ${resultado.user?.uid})');
      } else {
        debugPrint('[FirebaseSeed] Já existe ou falhou: $email');
      }
    }

    await authService.logout();
    debugPrint('[FirebaseSeed] Seed Auth concluído.');
  }

  // D3: vincula UIDs reais do Firebase Auth aos documentos de candidatos.
  await _vincularUidsCandidatos(authService);

  await _seedUsuarios();
  await _seedCandidatos();
  await _seedVagas();
}

// D3: Para cada candidato do seed, busca o uid real no Firebase Auth
// e atualiza o documento no Firestore caso ainda não tenha usuario_uid.
Future<void> _vincularUidsCandidatos(FirebaseAuthService authService) async {
  debugPrint('[Seed] Iniciando vinculação de UIDs aos candidatos...');

  final col = FirebaseFirestore.instance.collection('candidatos');

  // Mapa de email → credenciais de teste para candidatos do seed.
  final candidatosSeed = [
    ('jose.elias@gmail.com', 'cand123'),
  ];

  for (final (email, senha) in candidatosSeed) {
    try {
      // Busca documento do candidato por email.
      final snap = await col.where('email', isEqualTo: email).limit(1).get();
      if (snap.docs.isEmpty) {
        debugPrint('[Seed] Candidato não encontrado: $email');
        continue;
      }

      final doc = snap.docs.first;
      final uid = doc.data()['usuario_uid'] as String?;

      if (uid != null && uid.isNotEmpty) {
        debugPrint('[Seed] UID já preenchido para $email — pulando.');
        continue;
      }

      // Faz login temporário para obter o uid real.
      debugPrint('[Seed] Fazendo login temporário para obter uid: $email');
      final resultado = await authService.login(email, senha);
      if (resultado == null) {
        debugPrint('[Seed] Login falhou para $email — uid não vinculado.');
        continue;
      }

      final uidObtido = resultado.user?.uid;
      if (uidObtido == null || uidObtido.isEmpty) {
        debugPrint('[Seed] uid nulo após login: $email');
        await authService.logout();
        continue;
      }

      // Atualiza o documento com o uid real.
      await doc.reference.update({'usuario_uid': uidObtido});
      debugPrint('[Seed] uid vinculado: $email → $uidObtido');

      // Faz logout para não interferir na sessão do admin.
      await authService.logout();
    } catch (e) {
      debugPrint('[Seed] Erro ao vincular uid para $email: $e');
    }
  }

  debugPrint('[Seed] Vinculação de UIDs concluída.');
}

Future<void> _seedUsuarios() async {
  debugPrint('[FirebaseSeed] Verificando perfis de usuários no Firestore...');
  final db = FirebaseFirestore.instance;
  final col = db.collection('usuarios');
  final agora = DateTime.now().toIso8601String();

  final perfis = <Map<String, dynamic>>[
    {
      'uid': '5RIeYYHYnmQ8QOgYhL2iMV5Iku02',
      'nome': 'Administrador',
      'email': 'admin@rhos.com',
      'senha_hash': '',
      'perfil': 'admin',
      'ativo': true,
      'criado_em': agora,
    },
    {
      'uid': 'Yrsths23mWXivCxSGEC5fhZKmNH3',
      'nome': 'Recrutador',
      'email': 'recrutador@rhos.com',
      'senha_hash': '',
      'perfil': 'rh',
      'ativo': true,
      'criado_em': agora,
    },
    {
      'uid': 'NDjJxdtLIMWShKTEnhb6J5uNrik2',
      'nome': 'José Elias',
      'email': 'jose.elias@gmail.com',
      'senha_hash': '',
      'perfil': 'colaborador',
      'ativo': true,
      'criado_em': agora,
    },
    {
      'uid': '9FKB6lbpA3UIG95LEA1YUkF2cqw2',
      'nome': 'View User',
      'email': 'view@rhos.com',
      'senha_hash': '',
      'perfil': 'colaborador',
      'ativo': true,
      'criado_em': agora,
    },
  ];

  for (final dados in perfis) {
    final uid = dados['uid'] as String;
    final doc = await col.doc(uid).get();
    if (!doc.exists) {
      final sem = Map<String, dynamic>.from(dados)..remove('uid');
      await col.doc(uid).set(sem);
      debugPrint('[FirebaseSeed] Perfil criado: ${dados['email']}');
    } else {
      debugPrint('[FirebaseSeed] Perfil já existe: ${dados['email']}');
    }
  }

  debugPrint('[FirebaseSeed] Seed usuários concluído.');
}

Future<void> _seedCandidatos() async {
  debugPrint('[FirebaseSeed] Verificando candidatos no Firestore...');
  final col = FirebaseFirestore.instance.collection('candidatos');
  final agora = DateTime.now().toIso8601String();

  final candidatos = <Map<String, dynamic>>[
    {
      'email': 'joao@email.com',
      'nome': 'João Carlos Oliveira',
      'cpf': '123.456.789-09',
      'telefone': '(11) 91234-5678',
      'data_nascimento': '1992-05-14',
      'logradouro': 'Rua das Flores',
      'numero': '42',
      'complemento': 'Apto 3',
      'bairro': 'Jardim Paulista',
      'cidade': 'São Paulo',
      'estado': 'SP',
      'cep': '01310-100',
      'resumo':
          'Desenvolvedor mobile com 5 anos de experiência em Flutter e Android nativo.',
      'foto_path': null,
      'usuario_id': null,
      'criado_em': agora,
      'atualizado_em': agora,
    },
    {
      'email': 'ana.ferreira@email.com',
      'nome': 'Ana Paula Ferreira',
      'cpf': '987.654.321-00',
      'telefone': '(41) 99876-5432',
      'data_nascimento': '1988-11-30',
      'logradouro': 'Av. Batel',
      'numero': '1200',
      'complemento': null,
      'bairro': 'Batel',
      'cidade': 'Curitiba',
      'estado': 'PR',
      'cep': '80420-090',
      'resumo':
          'Analista de RH com especialização em recrutamento e desenvolvimento organizacional.',
      'foto_path': null,
      'usuario_id': null,
      'criado_em': agora,
      'atualizado_em': agora,
    },
  ];

  for (final dados in candidatos) {
    final email = dados['email'] as String;
    final existing = await col.where('email', isEqualTo: email).limit(1).get();
    if (existing.docs.isEmpty) {
      await col.add(dados);
      debugPrint('[FirebaseSeed] Candidato inserido: $email');
    } else {
      debugPrint('[FirebaseSeed] Candidato já existe: $email');
    }
  }

  debugPrint('[FirebaseSeed] Seed candidatos concluído.');
}

Future<void> _seedVagas() async {
  debugPrint('[FirebaseSeed] Verificando vagas no Firestore...');
  final col = FirebaseFirestore.instance.collection('vagas');
  final agora = DateTime.now().toIso8601String();

  final vagas = <Map<String, dynamic>>[
    {
      'titulo': 'Desenvolvedor Flutter Pleno',
      'descricao':
          'Vaga para desenvolvedor Flutter com experiência em Clean Architecture.',
      'habilidades': ['Flutter', 'Dart', 'Git', 'Clean Architecture'],
      'idiomas': ['Inglês'],
      'formacao': 'Graduação',
      'status': 'aberta',
      'criado_em': agora,
      'atualizado_em': agora,
    },
    {
      'titulo': 'Analista de RH',
      'descricao': 'Vaga para analista de RH com experiência em recrutamento.',
      'habilidades': ['Recrutamento', 'Entrevistas', 'Excel', 'Comunicação'],
      'status': 'aberta',
      'criado_em': agora,
      'atualizado_em': agora,
    },
  ];

  for (final dados in vagas) {
    final titulo = dados['titulo'] as String;
    final existing =
        await col.where('titulo', isEqualTo: titulo).limit(1).get();
    if (existing.docs.isEmpty) {
      await col.add(dados);
      debugPrint('[FirebaseSeed] Vaga inserida: $titulo');
    } else {
      debugPrint('[FirebaseSeed] Vaga já existe: $titulo');
    }
  }

  debugPrint('[FirebaseSeed] Seed vagas concluído.');
}

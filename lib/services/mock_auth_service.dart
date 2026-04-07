class UsuarioAutenticado {
  final String nomeCompleto;
  final String usuario;
  final String email;

  const UsuarioAutenticado({
    required this.nomeCompleto,
    required this.usuario,
    required this.email,
  });
}

class ResultadoAutenticacao {
  final bool sucesso;
  final String mensagem;
  final UsuarioAutenticado? usuario;

  const ResultadoAutenticacao({
    required this.sucesso,
    required this.mensagem,
    this.usuario,
  });
}

class _RegistroUsuarioMock {
  final String nomeCompleto;
  final String usuario;
  final String email;
  final String senha;

  const _RegistroUsuarioMock({
    required this.nomeCompleto,
    required this.usuario,
    required this.email,
    required this.senha,
  });

  UsuarioAutenticado paraUsuarioAutenticado() {
    return UsuarioAutenticado(
      nomeCompleto: nomeCompleto,
      usuario: usuario,
      email: email,
    );
  }
}

class ServicoAuthMock {
  ServicoAuthMock._();

  static final ServicoAuthMock instancia = ServicoAuthMock._();

  final List<_RegistroUsuarioMock> _usuarios = [
    const _RegistroUsuarioMock(
      nomeCompleto: 'Elias Pires',
      usuario: 'elias',
      email: 'elias@rhos.com',
      senha: '123456',
    ),
    const _RegistroUsuarioMock(
      nomeCompleto: 'Ana Silva',
      usuario: 'ana.silva',
      email: 'ana@rhos.com',
      senha: '123456',
    ),
  ];

  UsuarioAutenticado? _usuarioAtual;

  UsuarioAutenticado? get usuarioAtual => _usuarioAtual;

  Future<ResultadoAutenticacao> login({
    required String identificador,
    required String senha,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final identificadorNormalizado = identificador.trim().toLowerCase();
    final senhaInformada = senha.trim();

    for (final usuario in _usuarios) {
      final mesmoUsuario =
          usuario.usuario.toLowerCase() == identificadorNormalizado;
      final mesmoEmail =
          usuario.email.toLowerCase() == identificadorNormalizado;
      final mesmaSenha = usuario.senha == senhaInformada;

      if ((mesmoUsuario || mesmoEmail) && mesmaSenha) {
        final usuarioEncontrado = usuario.paraUsuarioAutenticado();
        _usuarioAtual = usuarioEncontrado;

        return ResultadoAutenticacao(
          sucesso: true,
          mensagem: 'Login realizado com sucesso.',
          usuario: usuarioEncontrado,
        );
      }
    }

    return const ResultadoAutenticacao(
      sucesso: false,
      mensagem: 'Usuário ou senha inválidos.',
    );
  }

  Future<ResultadoAutenticacao> cadastrar({
    required String nomeCompleto,
    required String usuario,
    required String email,
    required String senha,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final nomeNormalizado = nomeCompleto.trim();
    final usuarioNormalizado = usuario.trim();
    final emailNormalizado = email.trim();
    final senhaNormalizada = senha.trim();

    final usuarioJaExiste = _usuarios.any(
      (item) => item.usuario.toLowerCase() == usuarioNormalizado.toLowerCase(),
    );
    if (usuarioJaExiste) {
      return const ResultadoAutenticacao(
        sucesso: false,
        mensagem: 'Esse usuário já está em uso.',
      );
    }

    final emailJaExiste = _usuarios.any(
      (item) => item.email.toLowerCase() == emailNormalizado.toLowerCase(),
    );
    if (emailJaExiste) {
      return const ResultadoAutenticacao(
        sucesso: false,
        mensagem: 'Esse e-mail já está em uso.',
      );
    }

    final novoUsuario = _RegistroUsuarioMock(
      nomeCompleto: nomeNormalizado,
      usuario: usuarioNormalizado,
      email: emailNormalizado,
      senha: senhaNormalizada,
    );

    _usuarios.add(novoUsuario);

    return ResultadoAutenticacao(
      sucesso: true,
      mensagem: 'Cadastro realizado com sucesso.',
      usuario: novoUsuario.paraUsuarioAutenticado(),
    );
  }

  void sair() {
    _usuarioAtual = null;
  }
}
